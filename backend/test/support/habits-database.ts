import { Pool, PoolClient } from 'pg';
import { randomUUID } from 'node:crypto';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from '../../src/database/schema';
import { DatabaseService } from '../../src/database/database.service';
import { HabitsService } from '../../src/modules/habits/habits.service';

// Preparation refuses non-local URLs and never loads a dotenv file.
const { prepareLocalDatabase } = require('./prepare-local-test-db.cjs');

export async function habitsDatabase() {
  const rawUrl = process.env.TEST_DATABASE_URL;
  if (!rawUrl) throw new Error('An explicit local TEST_DATABASE_URL is required.');
  const url = new URL(rawUrl);
  if (!['127.0.0.1', 'localhost', '::1', '[::1]'].includes(url.hostname)) throw new Error('Local database required.');
  const disconnects: Promise<void>[] = [];
  const track = (pool: Pool) => {
    pool.on('connect', (client) => {
      disconnects.push(new Promise<void>((resolve) => client.once('end', resolve)));
    });
    return pool;
  };
  const root = new Pool({ connectionString: rawUrl, max: 1 });
  const dbName = `habits_v22_${randomUUID().replace(/-/g, '')}`;
  await root.query(`CREATE DATABASE "${dbName}"`);
  url.pathname = `/${dbName}`;
  await prepareLocalDatabase(url.toString());
  const admin = track(new Pool({ connectionString: url.toString(), max: 2 }));
  url.username = 'dualis_app';
  url.password = 'dualis_local_test';
  const appPool = track(new Pool({ connectionString: url.toString(), max: 3 }));
  const db = drizzle(appPool, { schema });
  const database = new DatabaseService(db, appPool);
  const habits = new HabitsService(database);
  const [owner, viewer, manager, stranger] = Array.from({ length: 4 }, () => randomUUID());
  const [primary, dependent, foreign] = Array.from({ length: 3 }, () => randomUUID());
  for (const id of [owner, viewer, manager, stranger]) {
    await admin.query("INSERT INTO users (id, name, email, password_hash, gender) VALUES ($1, 'Pessoa', $2, 'hash', 'unspecified')", [id, `${id}@habits.test`]);
  }
  await admin.query(`INSERT INTO profiles (id, account_owner_id, profile_type, name) VALUES
    ($1, $4, 'primary', 'Pessoa'), ($2, $4, 'dependent_minor', 'Dependente'), ($3, $5, 'primary', 'Outra pessoa')`,
    [primary, dependent, foreign, owner, stranger]);
  await admin.query(`INSERT INTO shared_access_grants
    (granter_user_id, target_profile_id, grantee_user_id, access_level, invite_code, status, expires_at, accepted_at)
    VALUES ($1, $2, $3, 'VIEW_ONLY', 'HBTV22', 'ACCEPTED', now() + interval '72 hours', now()),
           ($1, $2, $4, 'CO_MANAGE', 'HBTM22', 'ACCEPTED', now() + interval '72 hours', now())`,
    [owner, dependent, viewer, manager]);
  const asUser = async <T>(userId: string, callback: (client: PoolClient) => Promise<T>): Promise<T> => {
    const client = await appPool.connect();
    try {
      await client.query('BEGIN');
      await client.query("SELECT set_config('app.current_user_id', $1, true)", [userId]);
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally { client.release(); }
  };
  return {
    admin, appPool, db, database, habits, owner, viewer, manager, stranger, primary, dependent, foreign, asUser,
    async close() {
      await appPool.end().catch(() => {});
      await admin.end();
      await Promise.all(disconnects);
      await root.query(`DROP DATABASE "${dbName}"`);
      await root.end();
    },
  };
}
