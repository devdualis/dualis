import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { Pool } from 'pg';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const rawUrl = process.env.TEST_DATABASE_URL;
let local = false;
try {
  const url = new URL(rawUrl ?? '');
  local = ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname) && !/prod/i.test(url.pathname);
} catch { /* no test database supplied */ }

// Never use DATABASE_URL. This suite creates only its own disposable local DB.
describe.skipIf(!local)('Security: backend-only subscription persistence', () => {
  const databaseName = `dualis_billing_rls_${process.pid}`;
  const role = `billing_rls_backend_${process.pid}`;
  const A = '11111111-1111-4111-8111-111111111111';
  const B = '22222222-2222-4222-8222-222222222222';
  let admin: Pool;
  let pool: Pool;

  beforeAll(async () => {
    admin = new Pool({ connectionString: rawUrl, max: 1, connectionTimeoutMillis: 3000 });
    await admin.query(`CREATE DATABASE "${databaseName}"`);
    const url = new URL(rawUrl!); url.pathname = `/${databaseName}`;
    pool = new Pool({ connectionString: url.toString(), max: 1 });
    await pool.query(`CREATE ROLE "${role}" NOLOGIN NOSUPERUSER NOBYPASSRLS`);
    await pool.query(`DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF; END $$`);
    await pool.query('CREATE TABLE users (id uuid PRIMARY KEY)');
    await pool.query('INSERT INTO users(id) VALUES ($1), ($2)', [A, B]);
    await pool.query(readFileSync(join(__dirname, '../../src/database/migrations/0029_revenuecat_subscriptions.sql'), 'utf8'));
    await pool.query(`GRANT USAGE ON SCHEMA public TO "${role}", authenticated`);
    await pool.query(`GRANT SELECT, INSERT, UPDATE, DELETE ON subscriptions TO "${role}"`);
  });
  afterAll(async () => {
    await pool?.end();
    if (admin) {
      await admin.query(`DROP DATABASE IF EXISTS "${databaseName}" WITH (FORCE)`);
      await admin.query(`DROP ROLE IF EXISTS "${role}"`);
      await admin.end();
    }
  });

  async function asRole<T>(name: string, owner: string, fn: () => Promise<T>): Promise<T> {
    await pool.query('BEGIN');
    try {
      await pool.query(`SET LOCAL ROLE "${name}"`);
      await pool.query("SELECT set_config('app.current_user_id', $1, true)", [owner]);
      const result = await fn(); await pool.query('COMMIT'); return result;
    } catch (error) { await pool.query('ROLLBACK'); throw error; }
  }

  it('permits backend own-account persistence and hides it from other accounts', async () => {
    await asRole(role, A, () => pool.query('INSERT INTO subscriptions(user_id, entitlement_id, is_premium, environment, verified_at) VALUES ($1, $2, true, $3, now())', [A, 'premium', 'production']));
    expect((await asRole(role, A, () => pool.query('SELECT * FROM subscriptions'))).rowCount).toBe(1);
    expect((await asRole(role, B, () => pool.query('SELECT * FROM subscriptions'))).rowCount).toBe(0);
    await expect(asRole(role, B, () => pool.query('INSERT INTO subscriptions(user_id, entitlement_id, verified_at) VALUES ($1, $2, now())', [A, 'premium']))).rejects.toThrow();
  });

  it('prevents authenticated clients from granting themselves Premium even if table privileges are mistakenly added', async () => {
    await pool.query('GRANT SELECT, INSERT, UPDATE ON subscriptions TO authenticated');
    expect((await asRole('authenticated', A, () => pool.query('SELECT * FROM subscriptions'))).rowCount).toBe(0);
    await expect(asRole('authenticated', B, () => pool.query('INSERT INTO subscriptions(user_id, entitlement_id, is_premium, verified_at) VALUES ($1, $2, true, now())', [B, 'premium']))).rejects.toThrow();
  });
});
