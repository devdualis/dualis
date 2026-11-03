// Fresh local test database only. Never reads dotenv files.
const { Pool } = require('pg');
const { readdirSync, readFileSync } = require('node:fs');
const { join } = require('node:path');

async function prepareLocalDatabase(connectionString) {
  const url = new URL(connectionString);
  if (!['127.0.0.1', 'localhost', '::1', '[::1]'].includes(url.hostname)) {
    throw new Error('Only a local TEST_DATABASE_URL is allowed.');
  }
  const pool = new Pool({ connectionString, max: 1 });
  try {
    const existing = await pool.query("SELECT to_regclass('public.users') AS t");
    if (existing.rows[0].t) throw new Error('Use a fresh database; public.users already exists.');
    await pool.query(`
      CREATE EXTENSION IF NOT EXISTS vector;
      DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN CREATE ROLE anon NOLOGIN; END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN CREATE ROLE service_role NOLOGIN; END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dualis_app') THEN
          CREATE ROLE dualis_app LOGIN NOSUPERUSER NOBYPASSRLS PASSWORD 'dualis_local_test';
        END IF;
      END $$;
    `);
    const directory = join(__dirname, '../../src/database/migrations');
    const migrations = readdirSync(directory).filter((f) => /^\d{4}_.*\.sql$/.test(f)).sort();
    for (const file of migrations) await pool.query(readFileSync(join(directory, file), 'utf8'));
    // Idempotency check: 0026 must survive a second run. That replay recreates the daily_habits
    // policies without categories, so 0028 is replayed right after it to restore production order.
    await pool.query(readFileSync(join(directory, '0026_journal_v2_2_wellness.sql'), 'utf8'));
    await pool.query(readFileSync(join(directory, '0028_guardianship_consent_gaps.sql'), 'utf8'));
    const privilege = await pool.query("SELECT bool_and(has_table_privilege('dualis_app', 'daily_habits', privilege)) AS ok FROM unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE']) AS privilege");
    if (!privilege.rows[0].ok) throw new Error('Migration did not grant the runtime role habits access.');
    // Existing migrations do not provision runtime privileges on older tables.
    await pool.query('GRANT USAGE ON SCHEMA public TO dualis_app; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO dualis_app');
    console.log(`${migrations.length} migrations applied; 0026 and 0028 replays passed; dualis_app habits grant verified.`);
  } finally {
    await pool.end();
  }
}
module.exports = { prepareLocalDatabase };
if (require.main === module) {
  if (!process.env.TEST_DATABASE_URL) throw new Error('Set an explicit local TEST_DATABASE_URL.');
  prepareLocalDatabase(process.env.TEST_DATABASE_URL).catch((error) => { console.error(error); process.exitCode = 1; });
}
