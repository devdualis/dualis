import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool, PoolClient } from 'pg';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import * as dotenv from 'dotenv';

dotenv.config();

const MIGRATIONS_DIR = join(__dirname, '../../src/database/migrations');
const WELLNESS_MIGRATION = '0015_wellness_repositioning.sql';

describe('Security Regression: 0015 wellness repositioning (safety_resource_events RLS + data migration)', () => {
  let pool: Pool;
  let isDbAvailable = false;

  // Deterministic Test UUIDs (distinct from the other security suites)
  const ownerA = '6a6a6a6a-0000-4000-8000-00000000000a'; // guardian, owns the dependent
  const viewerB = '6b6b6b6b-0000-4000-8000-00000000000b'; // VIEW_ONLY grantee
  const strangerD = '6d6d6d6d-0000-4000-8000-00000000000d'; // no relation
  const primaryA = 'a6a6a6a6-0000-4000-8000-0000000000a1';
  const dependentId = 'd6d6d6d6-0000-4000-8000-0000000000d6';

  const ownEventId = '7a7a7a7a-0000-4000-8000-000000000001';
  const dependentEventId = '7a7a7a7a-0000-4000-8000-000000000002';
  const anonymousEventId = '7a7a7a7a-0000-4000-8000-000000000003';
  const legacyLogId = '7a7a7a7a-0000-4000-8000-000000000004';
  const reportedAt = '2026-09-01T10:00:00.000Z';

  beforeAll(async () => {
    // CRITICAL SAFETY GUARDRAIL:
    // NEVER fall back to DATABASE_URL. Must ONLY use TEST_DATABASE_URL pointing to local test DB.
    const rawTestUrl = process.env.TEST_DATABASE_URL;

    if (!rawTestUrl) {
      console.warn(
        '[wellness-repositioning-rls.spec.ts] SAFETY GUARD: TEST_DATABASE_URL not set. Skipping live database assertions to protect production/dev databases.',
      );
      return;
    }

    const isCloudOrProd = /supabase\.co|supabase\.com|aws-|pooler|rds\.amazonaws\.com|compute\.amazonaws\.com|prod/i.test(
      rawTestUrl,
    );
    const isLocal = /localhost|127\.0\.0\.1|test/i.test(rawTestUrl);

    if (isCloudOrProd || !isLocal) {
      console.error(
        `[wellness-repositioning-rls.spec.ts] CRITICAL SAFETY TRIGGER: TEST_DATABASE_URL points to a remote/cloud host. Aborting all test database operations to prevent data loss!`,
      );
      return;
    }

    // Dedicated sibling database, rebuilt on every run: the 0000-0014 chain is applied
    // from scratch, legacy rows are seeded, then 0015 runs on top of them (twice).
    const isolatedUrl = new URL(rawTestUrl);
    const isolatedDb = `${isolatedUrl.pathname.slice(1) || 'postgres'}_wellness_rls`.replace(/"/g, '');
    isolatedUrl.pathname = `/${isolatedDb}`;

    const admin = new Pool({ connectionString: rawTestUrl, max: 1, connectionTimeoutMillis: 3000 });
    try {
      await admin.query(`DROP DATABASE IF EXISTS "${isolatedDb}" WITH (FORCE)`);
      await admin.query(`CREATE DATABASE "${isolatedDb}"`);
    } catch (err) {
      console.warn(
        `[wellness-repositioning-rls.spec.ts] Live PostgreSQL instance not reachable or isolated DB unavailable: ${(err as Error).message}. Skipping live database assertions.`,
      );
      return;
    } finally {
      await admin.end().catch(() => {});
    }

    pool = new Pool({ connectionString: isolatedUrl.toString(), max: 5, connectionTimeoutMillis: 3000 });

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
    expect(migrations).toContain(WELLNESS_MIGRATION);

    for (const file of migrations.filter((f) => f < WELLNESS_MIGRATION)) {
      await pool.query(readFileSync(join(MIGRATIONS_DIR, file), 'utf8'));
    }

    // Pre-0015 state: emergency events with severity/category, a symptom_knowledge row
    // with clinical columns, and a symptom log carrying the old disposition.
    await pool.query(
      `INSERT INTO users (id, name, email, password_hash, gender) VALUES
       ($1, 'Ana Guardian', 'wellness-rls-a@dualis.test', 'hash', 'feminino'),
       ($2, 'Bruno Viewer', 'wellness-rls-b@dualis.test', 'hash', 'masculino'),
       ($3, 'Diego Stranger', 'wellness-rls-d@dualis.test', 'hash', 'masculino')`,
      [ownerA, viewerB, strangerD],
    );
    await pool.query(
      `INSERT INTO profiles (id, account_owner_id, profile_type, name) VALUES
       ($1, $3, 'primary', 'Ana Guardian'), ($2, $3, 'dependent_minor', 'Lucas')`,
      [primaryA, dependentId, ownerA],
    );
    await pool.query(
      `INSERT INTO shared_access_grants
         (granter_user_id, target_profile_id, grantee_user_id, access_level, invite_code, status, expires_at, accepted_at)
       VALUES ($1, $2, $3, 'VIEW_ONLY', 'WELRV1', 'ACCEPTED', now() + interval '72 hours', now())`,
      [ownerA, dependentId, viewerB],
    );
    await pool.query(
      `INSERT INTO triage_emergency_events
         (id, user_id, profile_id, trigger_category, severity_level, source_vertical, action_taken, reported_at)
       VALUES
         ($1, $4, $5, 'chest_pain', 5, 'physical', 'DIALED_192', $7),
         ($2, $4, $6, 'seizure', 5, 'physical', NULL, $7),
         ($3, NULL, NULL, 'suicidal_ideation', 5, 'emotional', 'DIALED_188', $7)`,
      [ownEventId, dependentEventId, anonymousEventId, ownerA, primaryA, dependentId, reportedAt],
    );
    await pool.query(
      `INSERT INTO symptom_knowledge
         (input_text, vertical, system_or_dimension, urgency_score, mapped_lay_term, clinical_concept, is_emergency_candidate, confidence, source)
       VALUES ('dor de cabeça', 'physical', 'head_neck', 3, 'dor de cabeça', 'cefaleia', false, 0.9, 'seed'),
              ('texto livre de uma pessoa', 'physical', 'chest', 4, 'aperto', 'angina', true, 0.7, 'gemini')`,
    );
    await pool.query(
      `INSERT INTO symptom_logs (id, user_id, profile_id, intensity, disposition, organic_primacy_applied)
       VALUES ($1, $2, $3, 4, 'consulta_rotina', true)`,
      [legacyLogId, ownerA, primaryA],
    );

    // Apply 0015 twice: it must be idempotent.
    const wellness = readFileSync(join(MIGRATIONS_DIR, WELLNESS_MIGRATION), 'utf8');
    await pool.query(wellness);
    await pool.query(wellness);

    await pool.query(`
      GRANT USAGE ON SCHEMA public TO authenticated;
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
    `);

    isDbAvailable = true;
  });

  afterAll(async () => {
    if (pool) await pool.end().catch(() => {});
  });

  /** Runs fn as the non-superuser `authenticated` role; always rolls back. */
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

  const visibleIds = (userId: string) =>
    asUser(userId, async (c) =>
      (await c.query('SELECT id FROM safety_resource_events ORDER BY id')).rows.map((r) => r.id),
    );

  const insertEvent = (c: PoolClient, userId: string | null, profileId: string | null, action = 'opened_resources') =>
    c.query(
      `INSERT INTO safety_resource_events (user_id, profile_id, action, channel, client_timestamp)
       VALUES ($1, $2, $3, 'tel:192', now()) RETURNING id`,
      [userId, profileId, action],
    );

  const RLS_VIOLATION = /row-level security/;

  const columnsOf = async (table: string) =>
    (
      await pool.query(
        `SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1 ORDER BY column_name`,
        [table],
      )
    ).rows.map((r) => r.column_name);

  it('moves every legacy emergency event, including anonymous ones, and drops the old table', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    expect((await pool.query(`SELECT to_regclass('public.triage_emergency_events') AS t`)).rows[0].t).toBeNull();

    const rows = (
      await pool.query(
        `SELECT id, user_id, profile_id, action, channel, client_timestamp FROM safety_resource_events ORDER BY id`,
      )
    ).rows;
    expect(rows).toEqual([
      { id: ownEventId, user_id: ownerA, profile_id: primaryA, action: 'opened_resources', channel: 'DIALED_192', client_timestamp: new Date(reportedAt) },
      { id: dependentEventId, user_id: ownerA, profile_id: dependentId, action: 'opened_resources', channel: null, client_timestamp: new Date(reportedAt) },
      { id: anonymousEventId, user_id: null, profile_id: null, action: 'opened_resources', channel: 'DIALED_188', client_timestamp: new Date(reportedAt) },
    ]);
  });

  it('keeps only the minimal columns: no severity, category or vertical', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    expect(await columnsOf('safety_resource_events')).toEqual([
      'action',
      'channel',
      'client_timestamp',
      'created_at',
      'id',
      'profile_id',
      'user_id',
    ]);
  });

  it('drops the clinical columns of symptom_knowledge, removes Gemini-cached user text and keeps seed rows', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    const columns = await columnsOf('symptom_knowledge');
    for (const dropped of ['urgency_score', 'clinical_concept', 'is_emergency_candidate']) {
      expect(columns).not.toContain(dropped);
    }
    const kept = await pool.query(`SELECT mapped_lay_term, system_or_dimension FROM symptom_knowledge`);
    expect(kept.rows).toEqual([{ mapped_lay_term: 'dor de cabeça', system_or_dimension: 'head_neck' }]);
  });

  it('keeps symptom_logs legacy fields readable and marks them legacy', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    const comments = await pool.query(
      `SELECT a.attname, col_description(a.attrelid, a.attnum) AS comment
       FROM pg_attribute a WHERE a.attrelid = 'public.symptom_logs'::regclass
         AND a.attname IN ('disposition', 'organic_primacy_applied') ORDER BY a.attname`,
    );
    expect(comments.rows).toHaveLength(2);
    for (const row of comments.rows) expect(row.comment).toMatch(/^LEGACY \(0015\)/);

    // Still exportable by the owner under RLS
    const own = await asUser(ownerA, (c) =>
      c.query('SELECT disposition, organic_primacy_applied FROM symptom_logs WHERE id = $1', [legacyLogId]),
    );
    expect(own.rows).toEqual([{ disposition: 'consulta_rotina', organic_primacy_applied: true }]);
  });

  it('enforces RLS: owner sees own and dependent events, VIEW_ONLY sees the dependent only, stranger nothing', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    const rls = await pool.query(
      `SELECT relrowsecurity, relforcerowsecurity FROM pg_class WHERE oid = 'public.safety_resource_events'::regclass`,
    );
    expect(rls.rows[0]).toEqual({ relrowsecurity: true, relforcerowsecurity: true });

    expect(await visibleIds(ownerA)).toEqual([ownEventId, dependentEventId]);
    expect(await visibleIds(viewerB)).toEqual([dependentEventId]);
    expect(await visibleIds(strangerD)).toEqual([]);
  });

  it('read access is enough to record an event; VIEW_ONLY cannot update or delete', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await asUser(viewerB, async (c) => {
      const res = await insertEvent(c, viewerB, dependentId, 'call_started');
      expect(res.rowCount).toBe(1);
      expect((await c.query('DELETE FROM safety_resource_events WHERE id = $1', [dependentEventId])).rowCount).toBe(0);
      expect(
        (await c.query(`UPDATE safety_resource_events SET channel = 'x' WHERE id = $1`, [dependentEventId])).rowCount,
      ).toBe(0);
    });
    await asUser(ownerA, async (c) => {
      expect((await insertEvent(c, ownerA, dependentId)).rowCount).toBe(1);
    });
  });

  it('stranger cannot record events for the dependent, and user_id must be the caller', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await expect(asUser(strangerD, (c) => insertEvent(c, strangerD, dependentId))).rejects.toThrow(RLS_VIOLATION);
    await expect(asUser(viewerB, (c) => insertEvent(c, ownerA, dependentId))).rejects.toThrow(RLS_VIOLATION);
  });

  it('anonymous events never fail without RETURNING and need both user_id and profile_id NULL', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    // No RETURNING: it applies the SELECT policy, and anonymous rows are visible to nobody.
    await asUser(null, async (c) => {
      const res = await c.query(
        `INSERT INTO safety_resource_events (user_id, profile_id, action, client_timestamp)
         VALUES (NULL, NULL, 'opened_resources', now())`,
      );
      expect(res.rowCount).toBe(1);
    });
    await expect(asUser(null, (c) => insertEvent(c, null, null))).rejects.toThrow(RLS_VIOLATION);
    await expect(asUser(null, (c) => insertEvent(c, null, dependentId))).rejects.toThrow(RLS_VIOLATION);
    await expect(asUser(ownerA, (c) => insertEvent(c, ownerA, null))).rejects.toThrow(
      /safety_resource_events_profile_required|row-level security/,
    );
  });

  it('only accepts the two known actions', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await expect(asUser(ownerA, (c) => insertEvent(c, ownerA, primaryA, 'severity_5'))).rejects.toThrow(
      /safety_resource_events_action_check/,
    );
  });

  it('deleting a profile cascades its safety events', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('DELETE FROM profiles WHERE id = $1', [dependentId]);
      const left = await client.query('SELECT count(*)::int AS n FROM safety_resource_events WHERE profile_id = $1', [
        dependentId,
      ]);
      expect(left.rows[0].n).toBe(0);
    } finally {
      await client.query('ROLLBACK').catch(() => {});
      client.release();
    }
  });
});
