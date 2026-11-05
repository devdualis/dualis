import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { Pool, PoolClient } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { randomBytes, randomUUID } from 'node:crypto';
import * as schema from '../../src/database/schema';
import { DatabaseService } from '../../src/database/database.service';
import { EncryptionService } from '../../src/common/encryption/encryption.service';
import { JournalService } from '../../src/modules/journal/journal.service';
import { CreateJournalEntryDto } from '../../src/modules/journal/dto/journal.dto';
import { dropTestDatabase } from '../support/drop-test-database';

// Preparation refuses non-local URLs and never loads a dotenv file.
const { prepareLocalDatabase } = require('../support/prepare-local-test-db.cjs');

const MIGRATION = join(__dirname, '../../src/database/migrations/0027_condition_readings.sql');

/**
 * 0027 condition_readings under RLS, through the real JournalService connected as the
 * runtime role (no SUPERUSER, no BYPASSRLS), plus direct SQL checks.
 */
describe.skipIf(!process.env.TEST_DATABASE_URL)('Condition readings: real runtime-role RLS and lifecycle', () => {
  let root: Pool;
  let admin: Pool;
  let appPool: Pool;
  let service: JournalService;
  let dbName: string;
  const [owner, viewer, manager, stranger] = Array.from({ length: 4 }, () => randomUUID());
  const [primary, dependent, foreign] = Array.from({ length: 3 }, () => randomUUID());

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
    } finally {
      client.release();
    }
  };

  const entry = (conditionId: string, readings: unknown[]): CreateJournalEntryDto =>
    ({
      clientId: `outbox-${randomUUID()}`,
      recordedAt: new Date().toISOString(),
      mood: 'bem',
      area: 'physical',
      triggers: [],
      transitionVariantIds: [],
      items: [{ kind: 'condition', conditionId, intensity: null, readings }],
    }) as any;
  const bp = (minutesAgo: number, systolic = 130) => ({
    kind: 'blood_pressure', measuredAt: new Date(Date.now() - minutesAgo * 60_000).toISOString(), systolic, diastolic: 85, pulse: 70,
  });

  beforeAll(async () => {
    const rawUrl = process.env.TEST_DATABASE_URL!;
    const url = new URL(rawUrl);
    if (!['127.0.0.1', 'localhost', '::1', '[::1]'].includes(url.hostname)) throw new Error('Local database required.');
    root = new Pool({ connectionString: rawUrl, max: 1 });
    dbName = `readings_v24_${randomUUID().replace(/-/g, '')}`;
    await root.query(`CREATE DATABASE "${dbName}"`);
    url.pathname = `/${dbName}`;
    await prepareLocalDatabase(url.toString());
    admin = new Pool({ connectionString: url.toString(), max: 2 });
    // Idempotent: a second run must not fail.
    await admin.query(readFileSync(MIGRATION, 'utf8'));
    url.username = 'dualis_app';
    url.password = 'dualis_local_test';
    appPool = new Pool({ connectionString: url.toString(), max: 3 });
    const encryption = new EncryptionService({ get: () => randomBytes(32).toString('hex') } as any);
    service = new JournalService(new DatabaseService(drizzle(appPool, { schema }), appPool), encryption);

    for (const id of [owner, viewer, manager, stranger]) {
      await admin.query("INSERT INTO users (id, name, email, password_hash, gender) VALUES ($1, 'Pessoa', $2, 'hash', 'unspecified')", [id, `${id}@readings.test`]);
    }
    await admin.query(
      `INSERT INTO profiles (id, account_owner_id, profile_type, name) VALUES
       ($1, $4, 'primary', 'Pessoa'), ($2, $4, 'dependent_minor', 'Dependente'), ($3, $5, 'primary', 'Outra pessoa')`,
      [primary, dependent, foreign, owner, stranger],
    );
    await admin.query(
      `INSERT INTO shared_access_grants
         (granter_user_id, target_profile_id, grantee_user_id, access_level, invite_code, status, expires_at, accepted_at, categories)
       VALUES ($1, $2, $3, 'VIEW_ONLY', 'RDGV23', 'ACCEPTED', now() + interval '72 hours', now(), ARRAY['physical_journal', 'conditions']::text[]),
              ($1, $2, $4, 'CO_MANAGE', 'RDGM23', 'ACCEPTED', now() + interval '72 hours', now(), ARRAY['physical_journal', 'conditions']::text[])`,
      [owner, dependent, viewer, manager],
    );
  });

  afterAll(async () => {
    await appPool?.end().catch(() => {});
    await admin?.end().catch(() => {});
    if (root) {
      await dropTestDatabase(root, dbName).catch(() => {});
      await root.end();
    }
  });

  it('table has ENABLE + FORCE RLS; runtime role has no bypass; tracking defaults to []', async () => {
    const role = await appPool.query('SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user');
    expect(role.rows[0]).toEqual({ rolsuper: false, rolbypassrls: false });
    const table = await admin.query("SELECT relrowsecurity, relforcerowsecurity FROM pg_class WHERE oid = 'condition_readings'::regclass");
    expect(table.rows[0]).toEqual({ relrowsecurity: true, relforcerowsecurity: true });
    const plain = await service.createCondition(owner, primary, 'Enxaqueca');
    expect(plain.tracking).toEqual([]);
    expect((await appPool.query('SELECT * FROM condition_readings')).rows).toEqual([]);
  });

  it('owner stores several readings; values are ciphertext at rest and plain in the response and history', async () => {
    const condition = await service.createCondition(owner, primary, 'Pressão', ['blood_pressure']);
    const saved = await service.createEntry(owner, primary, entry(condition.id, [bp(240, 121), bp(120, 125), bp(5, 130)]));
    expect(saved.items[0].readings.map((r: any) => r.systolic)).toEqual([121, 125, 130]);

    const raw = await admin.query('SELECT user_id, profile_id, kind, data FROM condition_readings WHERE condition_id = $1', [condition.id]);
    expect(raw.rowCount).toBe(3);
    for (const row of raw.rows) {
      expect(row).toMatchObject({ user_id: owner, profile_id: primary, kind: 'blood_pressure' });
      expect(row.data.startsWith('v1:')).toBe(true);
      expect(row.data).not.toMatch(/systolic|diastolic|[{}"]/);
    }

    const history = await service.listConditionReadings(owner, primary, condition.id, {});
    expect(history.map((r: any) => r.systolic)).toEqual([130, 125, 121]);
    const listed = (await service.listEntries(owner, primary, { days: 1 })).entries.find((e) => e.id === saved.id) as any;
    expect(listed.items[0].readings).toHaveLength(3);
  });

  it('replaying a clientId returns the same readings without storing them twice', async () => {
    const condition = await service.createCondition(owner, primary, 'Peso', ['weight']);
    const dto = entry(condition.id, [{ kind: 'weight', measuredAt: new Date().toISOString(), kg: 72.5 }]);
    const first = await service.createEntry(owner, primary, dto);
    const again = await service.createEntry(owner, primary, dto);
    expect(again.id).toBe(first.id);
    expect(again.items[0].readings).toEqual(first.items[0].readings);
    expect((await admin.query('SELECT count(*)::int AS n FROM condition_readings WHERE condition_id = $1', [condition.id])).rows[0].n).toBe(1);
  });

  it('PATCH tracking persists; archived conditions answer 404 but keep their history', async () => {
    const condition = await service.createCondition(owner, primary, 'Diabetes');
    const updated = await service.updateCondition(owner, primary, condition.id, { tracking: ['glucose', 'weight'] });
    expect(updated.tracking).toEqual(['glucose', 'weight']);
    expect((await service.listConditions(owner, primary)).conditions.find((c) => c.id === condition.id)?.tracking).toEqual(['glucose', 'weight']);
    await service.createEntry(owner, primary, entry(condition.id, [{ kind: 'glucose', measuredAt: new Date().toISOString(), mgdl: 98, moment: 'jejum' }]));
    await service.archiveCondition(owner, primary, condition.id);
    await expect(service.updateCondition(owner, primary, condition.id, { tracking: [] })).rejects.toMatchObject({ status: 404 });
    expect(await service.listConditionReadings(owner, primary, condition.id, {})).toHaveLength(1);
    await expect(
      asUser(owner, (c) => c.query("UPDATE user_conditions SET tracking = ARRAY['temperatura'] WHERE id = $1", [condition.id])),
    ).rejects.toThrow(/user_conditions_tracking_check/);
  });

  it('dependent: CO_MANAGE writes with caller as author; VIEW_ONLY reads only; stranger sees nothing', async () => {
    const condition = await service.createCondition(owner, dependent, 'Pressão', ['blood_pressure']);
    await service.createEntry(manager, dependent, entry(condition.id, [bp(1)]));
    expect((await admin.query('SELECT user_id FROM condition_readings WHERE condition_id = $1', [condition.id])).rows).toEqual([{ user_id: manager }]);
    expect(await service.listConditionReadings(viewer, dependent, condition.id, {})).toHaveLength(1);
    await expect(service.createEntry(viewer, dependent, entry(condition.id, [bp(1)]))).rejects.toThrow(/row-level security/);
    await expect(service.updateCondition(viewer, dependent, condition.id, { tracking: [] })).rejects.toMatchObject({ status: 404 });
    await expect(service.listConditionReadings(stranger, dependent, condition.id, {})).rejects.toMatchObject({ status: 404 });
    expect((await asUser(stranger, (c) => c.query('SELECT * FROM condition_readings'))).rows).toEqual([]);
    const changed = await asUser(viewer, (c) => c.query('DELETE FROM condition_readings WHERE condition_id = $1', [condition.id]));
    expect(changed.rowCount).toBe(0);
  });

  it('a reading cannot point at another profile\'s entry or condition, nor carry another author', async () => {
    const mine = await service.createCondition(owner, primary, 'Mine', ['weight']);
    const theirs = await service.createCondition(stranger, foreign, 'Theirs', ['weight']);
    const myEntry = await service.createEntry(owner, primary, entry(mine.id, [{ kind: 'weight', measuredAt: new Date().toISOString(), kg: 70 }]));
    const insert = (userId: string, profileId: string, entryId: string, conditionId: string) =>
      asUser(owner, (c) => c.query(
        `INSERT INTO condition_readings (user_id, profile_id, entry_id, condition_id, kind, measured_at, data)
         VALUES ($1, $2, $3, $4, 'weight', now(), 'v1:x')`, [userId, profileId, entryId, conditionId]));
    await expect(insert(owner, primary, myEntry.id, theirs.id)).rejects.toThrow(/row-level security/);
    await expect(insert(manager, primary, myEntry.id, mine.id)).rejects.toThrow(/row-level security/);
    const dependentCondition = await service.createCondition(owner, dependent, 'Dep', ['weight']);
    await expect(insert(owner, dependent, myEntry.id, dependentCondition.id)).rejects.toThrow(/row-level security/);
    await expect(
      asUser(owner, (c) => c.query('UPDATE condition_readings SET condition_id = $1 WHERE entry_id = $2', [dependentCondition.id, myEntry.id])),
    ).rejects.toThrow(/row-level security/);
    // The service checks the condition belongs to the active profile first.
    await expect(service.createEntry(owner, primary, entry(theirs.id, [{ kind: 'weight', measuredAt: new Date().toISOString(), kg: 70 }]))).rejects.toMatchObject({ status: 400 });
    await expect(insert(owner, primary, myEntry.id, mine.id).then(() => null)).resolves.toBeNull();
    await expect(
      asUser(owner, (c) => c.query(`INSERT INTO condition_readings (user_id, profile_id, entry_id, condition_id, kind, measured_at, data) VALUES ($1, $2, $3, $4, 'temperatura', now(), 'v1:x')`, [owner, primary, myEntry.id, mine.id])),
    ).rejects.toThrow(/condition_readings_kind_check/);
  });

  it('deleting an entry removes its readings; deleting an author keeps shared-profile readings; deleting the owner removes all', async () => {
    const condition = await service.createCondition(owner, primary, 'Apagar', ['blood_pressure']);
    const saved = await service.createEntry(owner, primary, entry(condition.id, [bp(1)]));
    await service.deleteEntry(owner, primary, saved.id);
    expect((await admin.query('SELECT count(*)::int AS n FROM condition_readings WHERE entry_id = $1', [saved.id])).rows[0].n).toBe(0);

    await asUser(manager, (c) => c.query('DELETE FROM users WHERE id = $1', [manager]));
    const kept = await admin.query('SELECT user_id FROM condition_readings WHERE profile_id = $1', [dependent]);
    expect(kept.rowCount).toBeGreaterThan(0);
    expect(kept.rows.every((r) => r.user_id === null)).toBe(true);

    await asUser(owner, (c) => c.query('DELETE FROM users WHERE id = $1', [owner]));
    expect((await admin.query('SELECT count(*)::int AS n FROM condition_readings WHERE profile_id = ANY($1::uuid[])', [[primary, dependent]])).rows[0].n).toBe(0);
  });
});
