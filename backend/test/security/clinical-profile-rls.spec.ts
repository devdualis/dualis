import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool, PoolClient } from 'pg';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import * as dotenv from 'dotenv';

dotenv.config();

const MIGRATIONS_DIR = join(__dirname, '../../src/database/migrations');
const PROFILE_SCOPED_MIGRATION = '0014_profile_scoped_clinical_data.sql';

describe('Security Regression: Profile-Scoped Clinical Data RLS (Phase 11 Wave 4)', () => {
  let pool: Pool;
  let isDbAvailable = false;

  // Deterministic Test UUIDs (distinct from the other security suites)
  const ownerA = '4a4a4a4a-0000-4000-8000-00000000000a'; // guardian, owns the dependent
  const viewerB = '4b4b4b4b-0000-4000-8000-00000000000b'; // VIEW_ONLY grantee
  const managerC = '4c4c4c4c-0000-4000-8000-00000000000c'; // CO_MANAGE grantee
  const strangerD = '4d4d4d4d-0000-4000-8000-00000000000d'; // no relation
  const revokedE = '4e4e4e4e-0000-4000-8000-00000000000e'; // grant revoked
  const dependentId = 'd4d4d4d4-0000-4000-8000-0000000000d4';

  const legacySymptomId = '5a5a5a5a-0000-4000-8000-000000000001';
  const legacyWaterId = '5a5a5a5a-0000-4000-8000-000000000002';
  const legacyEventId = '5a5a5a5a-0000-4000-8000-000000000003';
  const anonymousEventId = '5a5a5a5a-0000-4000-8000-000000000004';
  const dependentSymptomId = '5d5d5d5d-0000-4000-8000-000000000001';
  const dependentWaterId = '5d5d5d5d-0000-4000-8000-000000000002';
  const dependentEventId = '5d5d5d5d-0000-4000-8000-000000000003';

  let primaryA: string;

  beforeAll(async () => {
    // CRITICAL SAFETY GUARDRAIL:
    // NEVER fall back to DATABASE_URL. Must ONLY use TEST_DATABASE_URL pointing to local test DB.
    const rawTestUrl = process.env.TEST_DATABASE_URL;

    if (!rawTestUrl) {
      console.warn(
        '[clinical-profile-rls.spec.ts] SAFETY GUARD: TEST_DATABASE_URL not set. Skipping live database assertions to protect production/dev databases.',
      );
      return;
    }

    // Strict validation: Ban remote / cloud / production hosts
    const isCloudOrProd = /supabase\.co|supabase\.com|aws-|pooler|rds\.amazonaws\.com|compute\.amazonaws\.com|prod/i.test(
      rawTestUrl,
    );
    const isLocal = /localhost|127\.0\.0\.1|test/i.test(rawTestUrl);

    if (isCloudOrProd || !isLocal) {
      console.error(
        `[clinical-profile-rls.spec.ts] CRITICAL SAFETY TRIGGER: TEST_DATABASE_URL points to a remote/cloud host. Aborting all test database operations to prevent data loss!`,
      );
      return;
    }

    // Dedicated sibling database, rebuilt on every run: the full 0000-0014 chain is applied
    // from scratch, and 0014 runs on top of pre-existing clinical rows to prove the backfill.
    const isolatedUrl = new URL(rawTestUrl);
    const isolatedDb = `${isolatedUrl.pathname.slice(1) || 'postgres'}_clinical_profile_rls`.replace(/"/g, '');
    isolatedUrl.pathname = `/${isolatedDb}`;

    const admin = new Pool({ connectionString: rawTestUrl, max: 1, connectionTimeoutMillis: 3000 });
    try {
      await admin.query(`DROP DATABASE IF EXISTS "${isolatedDb}" WITH (FORCE)`);
      await admin.query(`CREATE DATABASE "${isolatedDb}"`);
    } catch (err) {
      console.warn(
        `[clinical-profile-rls.spec.ts] Live PostgreSQL instance not reachable or isolated DB unavailable: ${(err as Error).message}. Skipping live database assertions.`,
      );
      return;
    } finally {
      await admin.end().catch(() => {});
    }

    pool = new Pool({ connectionString: isolatedUrl.toString(), max: 5, connectionTimeoutMillis: 3000 });

    // Supabase-like prerequisites for the migration chain.
    await pool.query(`
      CREATE EXTENSION IF NOT EXISTS vector;
      DO $$
      DECLARE r text;
      BEGIN
        FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role'] LOOP
          IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('CREATE ROLE %I NOLOGIN', r);
          END IF;
        END LOOP;
      END
      $$;
    `);

    const migrations = readdirSync(MIGRATIONS_DIR)
      .filter((f) => /^\d{4}_.*\.sql$/.test(f))
      .sort();
    expect(migrations).toContain(PROFILE_SCOPED_MIGRATION);

    for (const file of migrations.filter((f) => f < PROFILE_SCOPED_MIGRATION)) {
      await pool.query(readFileSync(join(MIGRATIONS_DIR, file), 'utf8'));
    }

    // Pre-0014 state: clinical rows exist with user_id only, and no primary profile yet.
    await pool.query(
      `INSERT INTO users (id, name, email, password_hash, gender, date_of_birth) VALUES
       ($1, 'Ana Guardian', 'clinical-rls-a@dualis.test', 'hash', 'feminino', '1988-02-03'),
       ($2, 'Bruno Viewer', 'clinical-rls-b@dualis.test', 'hash', 'masculino', NULL),
       ($3, 'Carla Manager', 'clinical-rls-c@dualis.test', 'hash', 'feminino', NULL),
       ($4, 'Diego Stranger', 'clinical-rls-d@dualis.test', 'hash', 'masculino', NULL),
       ($5, 'Eva Revoked', 'clinical-rls-e@dualis.test', 'hash', 'feminino', NULL);`,
      [ownerA, viewerB, managerC, strangerD, revokedE],
    );
    await pool.query(
      `INSERT INTO symptom_logs (id, user_id, intensity, anatomical_system) VALUES ($1, $2, 3, 'respiratory');
       `,
      [legacySymptomId, ownerA],
    );
    await pool.query(`INSERT INTO water_intake_logs (id, user_id, amount_ml) VALUES ($1, $2, 250)`, [
      legacyWaterId,
      ownerA,
    ]);
    await pool.query(
      `INSERT INTO triage_emergency_events (id, user_id, trigger_category, severity_level, source_vertical, reported_at)
       VALUES ($1, $2, 'chest_pain', 5, 'physical', now()), ($3, NULL, 'suicidal_ideation', 5, 'emotional', now())`,
      [legacyEventId, ownerA, anonymousEventId],
    );

    // Apply 0014 twice: it must be idempotent.
    const profileScoped = readFileSync(join(MIGRATIONS_DIR, PROFILE_SCOPED_MIGRATION), 'utf8');
    await pool.query(profileScoped);
    await pool.query(profileScoped);

    await pool.query(`
      GRANT USAGE ON SCHEMA public TO authenticated;
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
    `);

    primaryA = (
      await pool.query(`SELECT id FROM profiles WHERE account_owner_id = $1 AND profile_type = 'primary'`, [ownerA])
    ).rows[0]?.id;

    // Fixture: A's dependent with one row per clinical table, plus grants for B, C and E.
    await pool.query(
      `INSERT INTO profiles (id, account_owner_id, profile_type, name) VALUES ($1, $2, 'dependent_minor', 'Lucas');
       `,
      [dependentId, ownerA],
    );
    await pool.query(
      `INSERT INTO symptom_logs (id, user_id, profile_id, intensity) VALUES ($1, $2, $3, 2)`,
      [dependentSymptomId, ownerA, dependentId],
    );
    await pool.query(
      `INSERT INTO water_intake_logs (id, user_id, profile_id, amount_ml) VALUES ($1, $2, $3, 200)`,
      [dependentWaterId, ownerA, dependentId],
    );
    await pool.query(
      `INSERT INTO triage_emergency_events (id, user_id, profile_id, trigger_category, severity_level, source_vertical, reported_at)
       VALUES ($1, $2, $3, 'seizure', 5, 'physical', now())`,
      [dependentEventId, ownerA, dependentId],
    );
    await pool.query(
      `INSERT INTO shared_access_grants
         (granter_user_id, target_profile_id, grantee_user_id, access_level, invite_code, status, expires_at, accepted_at, revoked_at)
       VALUES
         ($1, $2, $3, 'VIEW_ONLY', 'CLRVW2', 'ACCEPTED', now() + interval '72 hours', now(), NULL),
         ($1, $2, $4, 'CO_MANAGE', 'CLRCM2', 'ACCEPTED', now() + interval '72 hours', now(), NULL),
         ($1, $2, $5, 'VIEW_ONLY', 'CLRRV2', 'REVOKED', now() + interval '72 hours', now(), now())`,
      [ownerA, dependentId, viewerB, managerC, revokedE],
    );

    isDbAvailable = true;
  });

  afterAll(async () => {
    if (pool) await pool.end().catch(() => {});
  });

  /**
   * Runs fn as the non-superuser `authenticated` role with app.current_user_id set.
   * Always rolls back, so write probes never leak into other tests.
   */
  async function asUser<T>(userId: string | null, fn: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('SET LOCAL ROLE authenticated');
      if (userId) {
        await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userId]);
      }
      return await fn(client);
    } finally {
      await client.query('ROLLBACK').catch(() => {});
      client.release();
    }
  }

  async function visibleIds(userId: string, table: string): Promise<string[]> {
    return asUser(userId, async (c) =>
      (await c.query(`SELECT id FROM ${table} ORDER BY id`)).rows.map((r) => r.id),
    );
  }

  const insertSymptom = (c: PoolClient, userId: string, profileId: string) =>
    c.query(`INSERT INTO symptom_logs (user_id, profile_id, intensity) VALUES ($1, $2, 1) RETURNING id`, [
      userId,
      profileId,
    ]);
  const insertWater = (c: PoolClient, userId: string, profileId: string) =>
    c.query(`INSERT INTO water_intake_logs (user_id, profile_id, amount_ml) VALUES ($1, $2, 300) RETURNING id`, [
      userId,
      profileId,
    ]);
  const insertEvent = (c: PoolClient, userId: string | null, profileId: string | null) =>
    c.query(
      `INSERT INTO triage_emergency_events (user_id, profile_id, trigger_category, severity_level, source_vertical, reported_at)
       VALUES ($1, $2, 'chest_pain', 5, 'physical', now()) RETURNING id`,
      [userId, profileId],
    );

  const RLS_VIOLATION = /row-level security/;

  it('Backfill: legacy rows move to the author primary profile; anonymous events stay unassigned', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    expect(primaryA).toBeDefined();
    const primary = await pool.query('SELECT name, gender, date_of_birth FROM profiles WHERE id = $1', [primaryA]);
    expect(primary.rows[0].name).toBe('Ana Guardian');
    expect(primary.rows[0].gender).toBe('feminino');

    const rows = await pool.query(
      `SELECT 'symptom' AS t, profile_id FROM symptom_logs WHERE id = $1
       UNION ALL SELECT 'water', profile_id FROM water_intake_logs WHERE id = $2
       UNION ALL SELECT 'event', profile_id FROM triage_emergency_events WHERE id = $3`,
      [legacySymptomId, legacyWaterId, legacyEventId],
    );
    expect(rows.rows).toHaveLength(3);
    for (const r of rows.rows) expect(r.profile_id).toBe(primaryA);

    const anon = await pool.query('SELECT profile_id FROM triage_emergency_events WHERE id = $1', [anonymousEventId]);
    expect(anon.rows[0].profile_id).toBeNull();

    // Only users with clinical rows get a primary profile from the migration; re-running created no duplicate.
    const primaries = await pool.query(`SELECT account_owner_id FROM profiles WHERE profile_type = 'primary'`);
    expect(primaries.rows.map((r) => r.account_owner_id)).toEqual([ownerA]);

    const nullable = await pool.query(
      `SELECT table_name, is_nullable FROM information_schema.columns
       WHERE column_name = 'profile_id' AND table_name IN ('symptom_logs', 'water_intake_logs', 'triage_emergency_events')
       ORDER BY table_name`,
    );
    expect(nullable.rows).toEqual([
      { table_name: 'symptom_logs', is_nullable: 'NO' },
      { table_name: 'triage_emergency_events', is_nullable: 'YES' },
      { table_name: 'water_intake_logs', is_nullable: 'NO' },
    ]);

    // Owner still sees the backfilled rows through RLS
    expect(await visibleIds(ownerA, 'symptom_logs')).toEqual([legacySymptomId, dependentSymptomId]);
  });

  it('Owner reads and writes the dependent clinical data', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    expect(await visibleIds(ownerA, 'water_intake_logs')).toEqual([legacyWaterId, dependentWaterId]);
    expect(await visibleIds(ownerA, 'triage_emergency_events')).toEqual([legacyEventId, dependentEventId]);

    await asUser(ownerA, async (c) => {
      expect((await insertSymptom(c, ownerA, dependentId)).rowCount).toBe(1);
      expect((await insertWater(c, ownerA, dependentId)).rowCount).toBe(1);
      expect((await insertEvent(c, ownerA, dependentId)).rowCount).toBe(1);
      const upd = await c.query('UPDATE symptom_logs SET intensity = 4 WHERE id = $1', [dependentSymptomId]);
      expect(upd.rowCount).toBe(1);
      const del = await c.query('DELETE FROM water_intake_logs WHERE id = $1', [dependentWaterId]);
      expect(del.rowCount).toBe(1);
    });
  });

  it('VIEW_ONLY grantee reads the dependent data but cannot INSERT, UPDATE or DELETE it', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    // Sees the dependent only, never the owner's own primary profile data
    expect(await visibleIds(viewerB, 'symptom_logs')).toEqual([dependentSymptomId]);
    expect(await visibleIds(viewerB, 'water_intake_logs')).toEqual([dependentWaterId]);
    expect(await visibleIds(viewerB, 'triage_emergency_events')).toEqual([dependentEventId]);

    await expect(asUser(viewerB, (c) => insertSymptom(c, viewerB, dependentId))).rejects.toThrow(RLS_VIOLATION);
    await expect(asUser(viewerB, (c) => insertWater(c, viewerB, dependentId))).rejects.toThrow(RLS_VIOLATION);

    await asUser(viewerB, async (c) => {
      expect((await c.query('UPDATE symptom_logs SET intensity = 1 WHERE id = $1', [dependentSymptomId])).rowCount).toBe(0);
      expect((await c.query('UPDATE water_intake_logs SET amount_ml = 1 WHERE id = $1', [dependentWaterId])).rowCount).toBe(0);
      expect((await c.query('DELETE FROM symptom_logs WHERE id = $1', [dependentSymptomId])).rowCount).toBe(0);
      expect((await c.query('DELETE FROM water_intake_logs WHERE id = $1', [dependentWaterId])).rowCount).toBe(0);
      expect((await c.query('DELETE FROM triage_emergency_events WHERE id = $1', [dependentEventId])).rowCount).toBe(0);
    });

    const check = await pool.query('SELECT count(*)::int AS n FROM symptom_logs WHERE id = $1', [dependentSymptomId]);
    expect(check.rows[0].n).toBe(1);
  });

  it('VIEW_ONLY grantee can still record an emergency event for the dependent', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await asUser(viewerB, async (c) => {
      const res = await insertEvent(c, viewerB, dependentId);
      expect(res.rowCount).toBe(1);
      const seen = await c.query('SELECT user_id, profile_id FROM triage_emergency_events WHERE id = $1', [res.rows[0].id]);
      expect(seen.rows[0]).toEqual({ user_id: viewerB, profile_id: dependentId });
    });
  });

  it('CO_MANAGE grantee writes dependent data as the author', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await asUser(managerC, async (c) => {
      expect((await insertSymptom(c, managerC, dependentId)).rowCount).toBe(1);
      expect((await insertWater(c, managerC, dependentId)).rowCount).toBe(1);
      expect((await c.query('UPDATE water_intake_logs SET amount_ml = 500 WHERE id = $1', [dependentWaterId])).rowCount).toBe(1);
    });

    // ...but not into the owner's own primary profile
    await expect(asUser(managerC, (c) => insertSymptom(c, managerC, primaryA))).rejects.toThrow(RLS_VIOLATION);
  });

  it('Stranger sees nothing and cannot write or report events for the dependent', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    for (const table of ['symptom_logs', 'water_intake_logs', 'triage_emergency_events']) {
      expect(await visibleIds(strangerD, table)).toEqual([]);
    }
    await expect(asUser(strangerD, (c) => insertSymptom(c, strangerD, dependentId))).rejects.toThrow(RLS_VIOLATION);
    await expect(asUser(strangerD, (c) => insertEvent(c, strangerD, dependentId))).rejects.toThrow(RLS_VIOLATION);
    await asUser(strangerD, async (c) => {
      expect((await c.query('UPDATE symptom_logs SET intensity = 1 WHERE id = $1', [dependentSymptomId])).rowCount).toBe(0);
    });
  });

  it('Revoked grantee sees nothing and cannot report events for the dependent', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    for (const table of ['symptom_logs', 'water_intake_logs', 'triage_emergency_events']) {
      expect(await visibleIds(revokedE, table)).toEqual([]);
    }
    await expect(asUser(revokedE, (c) => insertEvent(c, revokedE, dependentId))).rejects.toThrow(RLS_VIOLATION);
  });

  it('user_id must equal the caller on insert, even for the owner', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await expect(asUser(ownerA, (c) => insertSymptom(c, managerC, dependentId))).rejects.toThrow(RLS_VIOLATION);
    await expect(asUser(ownerA, (c) => insertWater(c, managerC, dependentId))).rejects.toThrow(RLS_VIOLATION);
    await expect(asUser(viewerB, (c) => insertEvent(c, ownerA, dependentId))).rejects.toThrow(RLS_VIOLATION);
  });

  it('Anonymous emergency events need both user_id and profile_id NULL', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    // No RETURNING: it applies the SELECT policy, and anonymous rows are visible to nobody.
    await asUser(null, async (c) => {
      const res = await c.query(
        `INSERT INTO triage_emergency_events (user_id, profile_id, trigger_category, severity_level, source_vertical, reported_at)
         VALUES (NULL, NULL, 'chest_pain', 5, 'physical', now())`,
      );
      expect(res.rowCount).toBe(1);
    });
    await expect(asUser(null, (c) => insertEvent(c, null, null))).rejects.toThrow(RLS_VIOLATION);
    await expect(asUser(null, (c) => insertEvent(c, null, dependentId))).rejects.toThrow(RLS_VIOLATION);
    // An authenticated event without a profile violates the CHECK constraint
    await expect(asUser(ownerA, (c) => insertEvent(c, ownerA, null))).rejects.toThrow(
      /triage_emergency_events_profile_required|row-level security/,
    );
  });

  it('Deleting a profile cascades its clinical rows', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('DELETE FROM profiles WHERE id = $1', [dependentId]);
      const left = await client.query(
        `SELECT (SELECT count(*) FROM symptom_logs WHERE profile_id = $1)
              + (SELECT count(*) FROM water_intake_logs WHERE profile_id = $1)
              + (SELECT count(*) FROM triage_emergency_events WHERE profile_id = $1) AS n`,
        [dependentId],
      );
      expect(Number(left.rows[0].n)).toBe(0);
    } finally {
      await client.query('ROLLBACK').catch(() => {});
      client.release();
    }
  });
});
