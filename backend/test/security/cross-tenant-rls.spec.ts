import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as dotenv from 'dotenv';

dotenv.config();

describe('Security Regression: PostgreSQL Cross-Tenant RLS Isolation (SEC-01)', () => {
  let pool: Pool;
  let db: ReturnType<typeof drizzle>;
  let isDbAvailable = false;

  // Deterministic Test UUIDs
  const userA_Id = '11111111-1111-1111-1111-111111111111';
  const userB_Id = '22222222-2222-2222-2222-222222222222';
  const userA_LogId = 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const userB_LogId = 'bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  beforeAll(async () => {
    const connectionString =
      process.env.TEST_DATABASE_URL ||
      process.env.DATABASE_URL ||
      'postgresql://postgres:postgres@localhost:5432/dualis_dev';

    pool = new Pool({
      connectionString,
      max: 5,
      connectionTimeoutMillis: 3000,
    });

    try {
      // Test basic connection
      await pool.query('SELECT 1');
      isDbAvailable = true;
      db = drizzle(pool);

      // Create schema tables if not exist for testing
      await pool.query(`
        CREATE TABLE IF NOT EXISTS users (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          email VARCHAR(255) NOT NULL UNIQUE,
          created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
        );

        CREATE TABLE IF NOT EXISTS symptom_logs (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          encrypted_narrative TEXT,
          intensity INTEGER NOT NULL,
          anatomical_system TEXT,
          emotional_dimension TEXT,
          recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
          created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
        );
      `);

      // Ensure RLS is active and forced on both tables
      await pool.query(`ALTER TABLE users ENABLE ROW LEVEL SECURITY;`);
      await pool.query(`ALTER TABLE users FORCE ROW LEVEL SECURITY;`);
      await pool.query(`ALTER TABLE symptom_logs ENABLE ROW LEVEL SECURITY;`);
      await pool.query(`ALTER TABLE symptom_logs FORCE ROW LEVEL SECURITY;`);

      // Apply policies
      await pool.query(`
        DROP POLICY IF EXISTS users_patient_isolation ON users;
        CREATE POLICY users_patient_isolation ON users
          FOR ALL
          USING (id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
          WITH CHECK (id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

        DROP POLICY IF EXISTS symptom_logs_patient_isolation ON symptom_logs;
        CREATE POLICY symptom_logs_patient_isolation ON symptom_logs
          FOR ALL
          USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
          WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);
      `);
    } catch (err) {
      console.warn(
        `[cross-tenant-rls.spec.ts] Live PostgreSQL instance not reachable: ${(err as Error).message}. Skipping live database assertions.`,
      );
      isDbAvailable = false;
    }
  });

  afterAll(async () => {
    if (pool) {
      await pool.end().catch(() => {});
    }
  });

  beforeEach(async () => {
    if (!isDbAvailable) return;

    // Reset and seed data
    await pool.query(`TRUNCATE TABLE symptom_logs, users CASCADE;`);

    // Insert test tenants
    await pool.query(
      `INSERT INTO users (id, email) VALUES ($1, $2), ($3, $4);`,
      [userA_Id, 'tenantA@dualis.com.br', userB_Id, 'tenantB@dualis.com.br'],
    );

    // Insert records directly for both tenants
    await pool.query(
      `INSERT INTO symptom_logs (id, user_id, encrypted_narrative, intensity) VALUES 
       ($1, $2, 'enc_narrative_A', 3),
       ($3, $4, 'enc_narrative_B', 5);`,
      [userA_LogId, userA_Id, userB_LogId, userB_Id],
    );
  });

  it('Scenario 1: User A can read their own logs under User A session context', async (ctx) => {
    if (!isDbAvailable) {
      ctx.skip();
      return;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);

      const res = await client.query('SELECT * FROM symptom_logs');
      expect(res.rows).toHaveLength(1);
      expect(res.rows[0].id).toBe(userA_LogId);
      expect(res.rows[0].user_id).toBe(userA_Id);

      await client.query('COMMIT');
    } finally {
      client.release();
    }
  });

  it('Scenario 2: User A attempting to query User B log returns EMPTY set (Cross-Tenant SELECT blocked)', async (ctx) => {
    if (!isDbAvailable) {
      ctx.skip();
      return;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);

      // User A explicitly queries for User B's log ID
      const res = await client.query('SELECT * FROM symptom_logs WHERE id = $1', [userB_LogId]);
      expect(res.rows).toHaveLength(0); // Engine RLS drops row silently

      // User A attempts WHERE user_id = userB_Id
      const resAll = await client.query('SELECT * FROM symptom_logs WHERE user_id = $1', [userB_Id]);
      expect(resAll.rows).toHaveLength(0);

      await client.query('COMMIT');
    } finally {
      client.release();
    }
  });

  it('Scenario 3: User A attempting to UPDATE User B log affects 0 rows (Cross-Tenant UPDATE blocked)', async (ctx) => {
    if (!isDbAvailable) {
      ctx.skip();
      return;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);

      const res = await client.query(
        'UPDATE symptom_logs SET intensity = 1 WHERE id = $1',
        [userB_LogId],
      );
      expect(res.rowCount).toBe(0);

      await client.query('COMMIT');
    } finally {
      client.release();
    }

    // Verify row was NOT modified
    const check = await pool.query('SELECT intensity FROM symptom_logs WHERE id = $1', [userB_LogId]);
    expect(check.rows[0].intensity).toBe(5);
  });

  it('Scenario 4: User A attempting to DELETE User B log affects 0 rows (Cross-Tenant DELETE blocked)', async (ctx) => {
    if (!isDbAvailable) {
      ctx.skip();
      return;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);

      const res = await client.query('DELETE FROM symptom_logs WHERE id = $1', [userB_LogId]);
      expect(res.rowCount).toBe(0);

      await client.query('COMMIT');
    } finally {
      client.release();
    }

    // Verify row still exists
    const check = await pool.query('SELECT id FROM symptom_logs WHERE id = $1', [userB_LogId]);
    expect(check.rows).toHaveLength(1);
  });

  it('Scenario 5: Default Deny — Unauthenticated query without set_config returns 0 rows', async (ctx) => {
    if (!isDbAvailable) {
      ctx.skip();
      return;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      // No set_config executed

      const res = await client.query('SELECT * FROM symptom_logs');
      expect(res.rows).toHaveLength(0);

      await client.query('COMMIT');
    } finally {
      client.release();
    }
  });

  it('Scenario 6: SQL Injection / Malicious WHERE bypass attempts are blocked by engine RLS', async (ctx) => {
    if (!isDbAvailable) {
      ctx.skip();
      return;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);

      // Malicious query attempting to bypass WHERE clause with OR '1'='1'
      const res = await client.query("SELECT * FROM symptom_logs WHERE '1'='1'");
      expect(res.rows).toHaveLength(1);
      expect(res.rows[0].user_id).toBe(userA_Id); // Cannot see User B's row

      await client.query('COMMIT');
    } finally {
      client.release();
    }
  });

  it('Scenario 7: Session settings do not bleed into recycled pooled connections', async (ctx) => {
    if (!isDbAvailable) {
      ctx.skip();
      return;
    }

    // Step 1: Client 1 uses connection and sets User A context
    const client1 = await pool.connect();
    await client1.query('BEGIN');
    await client1.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);
    await client1.query('COMMIT');
    client1.release();

    // Step 2: Client 2 acquires a connection from the same pool without setting context
    const client2 = await pool.connect();
    try {
      const res = await client2.query("SELECT current_setting('app.current_user_id', true) as uid");
      expect(res.rows[0].uid).toBeFalsy(); // Must be empty or null, NOT userA_Id
    } finally {
      client2.release();
    }
  });
});
