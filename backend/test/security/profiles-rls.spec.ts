import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { Pool, PoolClient } from 'pg';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import * as dotenv from 'dotenv';

dotenv.config();

const MIGRATION_PATH = join(
  __dirname,
  '../../src/database/migrations/0013_multi_profile_guardianship_sharing.sql',
);

describe('Security Regression: Multi-Profile & Family Sharing RLS (PERM-01 / PERM-02)', () => {
  let pool: Pool;
  let isDbAvailable = false;

  // Deterministic Test UUIDs (distinct from cross-tenant-rls.spec.ts)
  const userA_Id = '3a3a3a3a-0000-4000-8000-00000000000a';
  const userB_Id = '3b3b3b3b-0000-4000-8000-00000000000b';
  const userC_Id = '3c3c3c3c-0000-4000-8000-00000000000c';
  const dependentId = 'd1d1d1d1-0000-4000-8000-0000000000d1';

  beforeAll(async () => {
    // CRITICAL SAFETY GUARDRAIL:
    // NEVER fall back to DATABASE_URL. Must ONLY use TEST_DATABASE_URL pointing to local test DB.
    const rawTestUrl = process.env.TEST_DATABASE_URL;

    if (!rawTestUrl) {
      console.warn(
        '[profiles-rls.spec.ts] SAFETY GUARD: TEST_DATABASE_URL not set. Skipping live database assertions to protect production/dev databases.',
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
        `[profiles-rls.spec.ts] CRITICAL SAFETY TRIGGER: TEST_DATABASE_URL points to a remote/cloud host. Aborting all test database operations to prevent data loss!`,
      );
      return;
    }

    // Run in a sibling database on the same local server: other security specs
    // TRUNCATE users CASCADE in parallel, which would wipe this suite's rows mid-test.
    const isolatedUrl = new URL(rawTestUrl);
    const isolatedDb = `${isolatedUrl.pathname.slice(1) || 'postgres'}_profiles_rls`;
    isolatedUrl.pathname = `/${isolatedDb}`;

    const admin = new Pool({ connectionString: rawTestUrl, max: 1, connectionTimeoutMillis: 3000 });
    try {
      const exists = await admin.query('SELECT 1 FROM pg_database WHERE datname = $1', [isolatedDb]);
      if (exists.rowCount === 0) {
        await admin.query(`CREATE DATABASE "${isolatedDb.replace(/"/g, '')}"`);
      }
    } catch (err) {
      console.warn(
        `[profiles-rls.spec.ts] Live PostgreSQL instance not reachable or isolated DB unavailable: ${(err as Error).message}. Skipping live database assertions.`,
      );
      return;
    } finally {
      await admin.end().catch(() => {});
    }

    pool = new Pool({
      connectionString: isolatedUrl.toString(),
      max: 5,
      connectionTimeoutMillis: 3000,
    });

    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL DEFAULT 'Test User',
        email VARCHAR(255) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL DEFAULT 'hash',
        gender VARCHAR(50) NOT NULL DEFAULT 'unspecified',
        date_of_birth DATE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
          CREATE ROLE authenticated NOLOGIN;
        END IF;
      END
      $$;
    `);

    // Apply the real migration (idempotent) so the suite tests the shipped SQL.
    await pool.query(readFileSync(MIGRATION_PATH, 'utf8'));

    await pool.query(`
      GRANT USAGE ON SCHEMA public TO authenticated;
      GRANT SELECT, INSERT, UPDATE, DELETE ON profiles, legal_guardianships, shared_access_grants TO authenticated;
    `);

    isDbAvailable = true;
  });

  afterAll(async () => {
    if (pool) {
      if (isDbAvailable) {
        await pool.query('DELETE FROM users WHERE id = ANY($1::uuid[])', [[userA_Id, userB_Id, userC_Id]]).catch(() => {});
      }
      await pool.end().catch(() => {});
    }
  });

  beforeEach(async () => {
    if (!isDbAvailable) return;

    // Cascade removes this suite's profiles, guardianships and grants.
    await pool.query('DELETE FROM users WHERE id = ANY($1::uuid[])', [[userA_Id, userB_Id, userC_Id]]);
    await pool.query(
      `INSERT INTO users (id, name, email) VALUES
       ($1, 'Guardian A', 'profiles-rls-a@dualis.test'),
       ($2, 'Relative B', 'profiles-rls-b@dualis.test'),
       ($3, 'Stranger C', 'profiles-rls-c@dualis.test');`,
      [userA_Id, userB_Id, userC_Id],
    );
    await pool.query(
      `INSERT INTO profiles (id, account_owner_id, profile_type, name)
       VALUES ($1, $2, 'dependent_minor', 'Child of A');`,
      [dependentId, userA_Id],
    );
    await pool.query(
      `INSERT INTO legal_guardianships (guardian_user_id, dependent_profile_id, relationship_type, lgpd_consent_recorded_at)
       VALUES ($1, $2, 'parent', now());`,
      [userA_Id, dependentId],
    );
  });

  /** Runs fn as a non-owner role with app.current_user_id set; always rolls back on error. */
  async function asUser<T>(userId: string, fn: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('SET LOCAL ROLE authenticated');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userId]);
      const result = await fn(client);
      await client.query('COMMIT');
      return result;
    } catch (err) {
      await client.query('ROLLBACK').catch(() => {});
      throw err;
    } finally {
      client.release();
    }
  }

  async function createInvite(
    accessLevel: 'VIEW_ONLY' | 'CO_MANAGE',
    code: string,
    expiresAt = "now() + interval '72 hours'",
  ): Promise<string> {
    return asUser(userA_Id, async (c) => {
      const res = await c.query(
        `INSERT INTO shared_access_grants (granter_user_id, target_profile_id, access_level, invite_code, expires_at)
         VALUES ($1, $2, $3, $4, ${expiresAt}) RETURNING id`,
        [userA_Id, dependentId, accessLevel, code],
      );
      return res.rows[0].id as string;
    });
  }

  async function acceptAs(userId: string, code: string) {
    return asUser(userId, (c) => c.query('SELECT * FROM accept_shared_access_invite($1)', [code]));
  }

  async function visibleProfileIds(userId: string): Promise<string[]> {
    return asUser(userId, async (c) => (await c.query('SELECT id FROM profiles')).rows.map((r) => r.id));
  }

  it('Scenario 1: Owner A sees own dependent and guardianship; B sees neither', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    expect(await visibleProfileIds(userA_Id)).toEqual([dependentId]);
    expect(await visibleProfileIds(userB_Id)).toEqual([]);

    const guardianships = await asUser(userB_Id, (c) => c.query('SELECT * FROM legal_guardianships'));
    expect(guardianships.rows).toHaveLength(0);

    const update = await asUser(userB_Id, (c) =>
      c.query(`UPDATE profiles SET name = 'hijacked' WHERE id = $1`, [dependentId]),
    );
    expect(update.rowCount).toBe(0);
  });

  it('Scenario 2: B sees the dependent after accepting a valid invite', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await createInvite('VIEW_ONLY', 'ABC234');

    // Before accepting, B cannot see the PENDING grant nor the profile
    const pending = await asUser(userB_Id, (c) => c.query('SELECT * FROM shared_access_grants'));
    expect(pending.rows).toHaveLength(0);

    const accepted = await acceptAs(userB_Id, 'abc234'); // case-insensitive
    expect(accepted.rows).toHaveLength(1);
    expect(accepted.rows[0].status).toBe('ACCEPTED');
    expect(accepted.rows[0].grantee_user_id).toBe(userB_Id);
    expect(accepted.rows[0].accepted_at).not.toBeNull();

    expect(await visibleProfileIds(userB_Id)).toEqual([dependentId]);
    expect(await visibleProfileIds(userC_Id)).toEqual([]);

    // Code is single-use
    expect((await acceptAs(userC_Id, 'ABC234')).rows).toHaveLength(0);
  });

  it('Scenario 3: VIEW_ONLY grantee cannot UPDATE nor escalate its own access level', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    const grantId = await createInvite('VIEW_ONLY', 'VW2345');
    await acceptAs(userB_Id, 'VW2345');

    const update = await asUser(userB_Id, (c) =>
      c.query(`UPDATE profiles SET name = 'edited by B' WHERE id = $1`, [dependentId]),
    );
    expect(update.rowCount).toBe(0);

    await expect(
      asUser(userB_Id, (c) =>
        c.query(`UPDATE shared_access_grants SET access_level = 'CO_MANAGE' WHERE id = $1`, [grantId]),
      ),
    ).rejects.toThrow(/GRANTEE_MAY_ONLY_REVOKE/);

    const check = await pool.query('SELECT name FROM profiles WHERE id = $1', [dependentId]);
    expect(check.rows[0].name).toBe('Child of A');
  });

  it('Scenario 4: CO_MANAGE grantee can UPDATE but cannot DELETE or take ownership', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await createInvite('CO_MANAGE', 'CM2345');
    await acceptAs(userB_Id, 'CM2345');

    const update = await asUser(userB_Id, (c) =>
      c.query(`UPDATE profiles SET name = 'edited by B' WHERE id = $1`, [dependentId]),
    );
    expect(update.rowCount).toBe(1);

    const del = await asUser(userB_Id, (c) => c.query('DELETE FROM profiles WHERE id = $1', [dependentId]));
    expect(del.rowCount).toBe(0);

    await expect(
      asUser(userB_Id, (c) =>
        c.query('UPDATE profiles SET account_owner_id = $1 WHERE id = $2', [userB_Id, dependentId]),
      ),
    ).rejects.toThrow(/row-level security/);

    const check = await pool.query('SELECT name, account_owner_id FROM profiles WHERE id = $1', [dependentId]);
    expect(check.rows[0]).toEqual({ name: 'edited by B', account_owner_id: userA_Id });
  });

  it('Scenario 5: After revoke, B sees nothing and REVOKED is terminal', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    const grantId = await createInvite('CO_MANAGE', 'RV2345');
    await acceptAs(userB_Id, 'RV2345');
    expect(await visibleProfileIds(userB_Id)).toEqual([dependentId]);

    const revoke = await asUser(userA_Id, (c) =>
      c.query(`UPDATE shared_access_grants SET status = 'REVOKED', revoked_at = now() WHERE id = $1`, [grantId]),
    );
    expect(revoke.rowCount).toBe(1);

    expect(await visibleProfileIds(userB_Id)).toEqual([]);
    const update = await asUser(userB_Id, (c) =>
      c.query(`UPDATE profiles SET name = 'late edit' WHERE id = $1`, [dependentId]),
    );
    expect(update.rowCount).toBe(0);

    await expect(
      asUser(userB_Id, (c) => c.query(`UPDATE shared_access_grants SET status = 'ACCEPTED' WHERE id = $1`, [grantId])),
    ).rejects.toThrow(/GRANT_TERMINAL_STATUS/);
  });

  it('Scenario 6: Grantee can revoke their own access', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    const grantId = await createInvite('VIEW_ONLY', 'GR2345');
    await acceptAs(userB_Id, 'GR2345');

    const revoke = await asUser(userB_Id, (c) =>
      c.query(`UPDATE shared_access_grants SET status = 'REVOKED', revoked_at = now() WHERE id = $1`, [grantId]),
    );
    expect(revoke.rowCount).toBe(1);
    expect(await visibleProfileIds(userB_Id)).toEqual([]);
  });

  it('Scenario 7: Self-accept is rejected with SELF_GRANT', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await createInvite('VIEW_ONLY', 'SF2345');

    await expect(acceptAs(userA_Id, 'SF2345')).rejects.toMatchObject({ code: 'P0001', message: 'SELF_GRANT' });

    const grant = await pool.query(`SELECT status, grantee_user_id FROM shared_access_grants WHERE invite_code = 'SF2345'`);
    expect(grant.rows[0]).toEqual({ status: 'PENDING', grantee_user_id: null });
  });

  it('Scenario 8: Expired invite is rejected and marked EXPIRED', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await createInvite('CO_MANAGE', 'EX2345', "now() - interval '1 minute'");

    const res = await acceptAs(userB_Id, 'EX2345');
    expect(res.rows).toHaveLength(0);

    const grant = await pool.query(`SELECT status, grantee_user_id FROM shared_access_grants WHERE invite_code = 'EX2345'`);
    expect(grant.rows[0]).toEqual({ status: 'EXPIRED', grantee_user_id: null });
    expect(await visibleProfileIds(userB_Id)).toEqual([]);
  });

  it('Scenario 9: Only the owner can create grants for a profile', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    await expect(
      asUser(userB_Id, (c) =>
        c.query(
          `INSERT INTO shared_access_grants (granter_user_id, target_profile_id, access_level, invite_code, expires_at)
           VALUES ($1, $2, 'CO_MANAGE', 'HK2345', now() + interval '72 hours')`,
          [userB_Id, dependentId],
        ),
      ),
    ).rejects.toThrow(/row-level security/);
  });

  it('Scenario 10: Default deny without app.current_user_id', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('SET LOCAL ROLE authenticated');
      expect((await client.query('SELECT * FROM profiles')).rows).toHaveLength(0);
      expect((await client.query('SELECT * FROM legal_guardianships')).rows).toHaveLength(0);
      expect((await client.query('SELECT * FROM shared_access_grants')).rows).toHaveLength(0);
      await client.query('ROLLBACK');
    } finally {
      client.release();
    }
  });
});
