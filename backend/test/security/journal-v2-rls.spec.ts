import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool, PoolClient } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import { readdirSync, readFileSync } from 'node:fs';
import { randomBytes, randomUUID } from 'node:crypto';
import { join } from 'node:path';
import * as dotenv from 'dotenv';
import * as schema from '../../src/database/schema';
import { DatabaseService } from '../../src/database/database.service';
import { EncryptionService } from '../../src/common/encryption/encryption.service';
import { JournalService } from '../../src/modules/journal/journal.service';
import { CreateJournalEntryDto } from '../../src/modules/journal/dto/journal.dto';

dotenv.config();

const MIGRATIONS_DIR = join(__dirname, '../../src/database/migrations');
const JOURNAL_MIGRATION = '0017_journal_v2.sql';
const AI_REMOVAL_MIGRATION = '0018_remove_ai_tagging.sql';
const CLIENT_ID_MIGRATION = '0019_journal_v2_profile_client_id.sql';
const APP_ROLE = 'dualis_journal_app';
const APP_PASSWORD = 'dualis_journal_app';

/**
 * Journal v2 tables under RLS, exercised through the real JournalService connected as a
 * LOGIN role without SUPERUSER or BYPASSRLS (like production), plus direct SQL checks.
 */
describe('Security Regression: 0017 journal v2 (journal_entries, journal_items, user_conditions RLS)', () => {
  let adminPool: Pool;
  let appPool: Pool;
  let service: JournalService;
  let isDbAvailable = false;

  const ownerA = '7a7a7a7a-0000-4000-8000-00000000000a'; // owns primaryA and the dependent
  const viewerB = '7b7b7b7b-0000-4000-8000-00000000000b'; // VIEW_ONLY on the dependent
  const coManagerC = '7c7c7c7c-0000-4000-8000-00000000000c'; // CO_MANAGE on the dependent
  const strangerD = '7d7d7d7d-0000-4000-8000-00000000000d'; // no relation
  const primaryA = 'a7a7a7a7-0000-4000-8000-0000000000a1';
  const dependentId = 'd7d7d7d7-0000-4000-8000-0000000000d7';
  const primaryD = 'a7a7a7a7-0000-4000-8000-0000000000d1';
  const legacyLogId = '7e7e7e7e-0000-4000-8000-000000000001';

  const entryDto = (overrides: Partial<CreateJournalEntryDto> = {}): CreateJournalEntryDto => ({
    clientId: `outbox-${randomUUID()}`,
    recordedAt: new Date().toISOString(),
    mood: 'nao_tao_bem',
    triggers: ['sono', 'esforco'],
    transitionVariantIds: ['futuro.intro.1'],
    note: 'Dia corrido no trabalho',
    triggerNote: 'mudança',
    items: [
      { kind: 'emotional', optionKey: 'futuro.mente.antecipar', persistence: 'dias_semanas', intensity: 3 },
      { kind: 'physical', optionKey: 'costas.custom', customLabel: 'nuca dura', bodySide: 'back', persistence: 'hoje', intensity: 4 },
    ],
    ...overrides,
  });

  beforeAll(async () => {
    // CRITICAL SAFETY GUARDRAIL: only TEST_DATABASE_URL on a local host, never DATABASE_URL.
    const rawTestUrl = process.env.TEST_DATABASE_URL;
    if (!rawTestUrl) {
      console.warn('[journal-v2-rls.spec.ts] SAFETY GUARD: TEST_DATABASE_URL not set. Skipping live database assertions.');
      return;
    }
    const isCloudOrProd = /supabase\.co|supabase\.com|aws-|pooler|rds\.amazonaws\.com|compute\.amazonaws\.com|prod/i.test(rawTestUrl);
    const isLocal = /localhost|127\.0\.0\.1|test/i.test(rawTestUrl);
    if (isCloudOrProd || !isLocal) {
      console.error('[journal-v2-rls.spec.ts] CRITICAL SAFETY TRIGGER: TEST_DATABASE_URL points to a remote/cloud host. Aborting.');
      return;
    }

    const isolatedUrl = new URL(rawTestUrl);
    const isolatedDb = `${isolatedUrl.pathname.slice(1) || 'postgres'}_journal_v2_rls`.replace(/"/g, '');
    isolatedUrl.pathname = `/${isolatedDb}`;

    const admin = new Pool({ connectionString: rawTestUrl, max: 1, connectionTimeoutMillis: 3000 });
    try {
      await admin.query(`DROP DATABASE IF EXISTS "${isolatedDb}" WITH (FORCE)`);
      await admin.query(`CREATE DATABASE "${isolatedDb}"`);
    } catch (err) {
      console.warn(`[journal-v2-rls.spec.ts] Live PostgreSQL not reachable: ${(err as Error).message}. Skipping.`);
      return;
    } finally {
      await admin.end().catch(() => {});
    }

    adminPool = new Pool({ connectionString: isolatedUrl.toString(), max: 3, connectionTimeoutMillis: 3000 });
    await adminPool.query(`
      CREATE EXTENSION IF NOT EXISTS vector;
      DO $$
      DECLARE r text;
      BEGIN
        FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role'] LOOP
          IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('CREATE ROLE %I NOLOGIN', r);
          END IF;
        END LOOP;
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${APP_ROLE}') THEN
          CREATE ROLE ${APP_ROLE} LOGIN NOSUPERUSER NOBYPASSRLS PASSWORD '${APP_PASSWORD}';
        END IF;
      END
      $$;
    `);

    const migrations = readdirSync(MIGRATIONS_DIR).filter((f) => /^\d{4}_.*\.sql$/.test(f)).sort();
    expect(migrations).toEqual(expect.arrayContaining([JOURNAL_MIGRATION, AI_REMOVAL_MIGRATION, CLIENT_ID_MIGRATION]));
    for (const file of migrations) {
      await adminPool.query(readFileSync(join(MIGRATIONS_DIR, file), 'utf8'));
    }
    // Idempotent: a second run must not fail.
    for (const file of [JOURNAL_MIGRATION, AI_REMOVAL_MIGRATION, CLIENT_ID_MIGRATION]) {
      await adminPool.query(readFileSync(join(MIGRATIONS_DIR, file), 'utf8'));
    }

    await adminPool.query(`
      GRANT USAGE ON SCHEMA public TO ${APP_ROLE}, authenticated;
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${APP_ROLE}, authenticated;
    `);

    await adminPool.query(
      `INSERT INTO users (id, name, email, password_hash, gender) VALUES
       ($1, 'Ana', 'journal-a@dualis.test', 'hash', 'feminino'),
       ($2, 'Bruno', 'journal-b@dualis.test', 'hash', 'masculino'),
       ($3, 'Carla', 'journal-c@dualis.test', 'hash', 'feminino'),
       ($4, 'Diego', 'journal-d@dualis.test', 'hash', 'masculino')`,
      [ownerA, viewerB, coManagerC, strangerD],
    );
    await adminPool.query(
      `INSERT INTO profiles (id, account_owner_id, profile_type, name) VALUES
       ($1, $3, 'primary', 'Ana'), ($2, $3, 'dependent_minor', 'Lucas'), ($4, $5, 'primary', 'Diego')`,
      [primaryA, dependentId, ownerA, primaryD, strangerD],
    );
    await adminPool.query(
      `INSERT INTO shared_access_grants
         (granter_user_id, target_profile_id, grantee_user_id, access_level, invite_code, status, expires_at, accepted_at)
       VALUES ($1, $2, $3, 'VIEW_ONLY', 'JRNV21', 'ACCEPTED', now() + interval '72 hours', now()),
              ($1, $2, $4, 'CO_MANAGE', 'JRNV22', 'ACCEPTED', now() + interval '72 hours', now())`,
      [ownerA, dependentId, viewerB, coManagerC],
    );
    await adminPool.query(
      `INSERT INTO symptom_logs (id, user_id, profile_id, intensity, anatomical_system, emotional_dimension, recorded_at)
       VALUES ($1, $2, $3, 4, 'cardiovascular_torax', NULL, now() - interval '2 days')`,
      [legacyLogId, ownerA, primaryA],
    );

    const appUrl = new URL(isolatedUrl.toString());
    appUrl.username = APP_ROLE;
    appUrl.password = APP_PASSWORD;
    appPool = new Pool({ connectionString: appUrl.toString(), max: 5, connectionTimeoutMillis: 3000 });
    const role = await appPool.query(
      `SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user`,
    );
    expect(role.rows[0]).toEqual({ rolsuper: false, rolbypassrls: false });

    const db = drizzle(appPool, { schema });
    const encryption = new EncryptionService({ get: () => randomBytes(32).toString('hex') } as any);
    service = new JournalService(new DatabaseService(db, appPool), encryption);
    isDbAvailable = true;
  });

  afterAll(async () => {
    if (appPool) await appPool.end().catch(() => {});
    if (adminPool) await adminPool.end().catch(() => {});
  });

  /** Runs fn as the non-superuser `authenticated` role; always rolls back. */
  async function asUser<T>(userId: string, fn: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await adminPool.connect();
    try {
      await client.query('BEGIN');
      await client.query('SET LOCAL ROLE authenticated');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userId]);
      return await fn(client);
    } finally {
      await client.query('ROLLBACK').catch(() => {});
      client.release();
    }
  }

  const RLS_VIOLATION = /row-level security/;

  it('creates the three tables with forced RLS', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const rows = (
      await adminPool.query(
        `SELECT relname, relrowsecurity, relforcerowsecurity FROM pg_class
         WHERE relname IN ('journal_entries', 'journal_items', 'user_conditions') ORDER BY relname`,
      )
    ).rows;
    expect(rows).toEqual([
      { relname: 'journal_entries', relrowsecurity: true, relforcerowsecurity: true },
      { relname: 'journal_items', relrowsecurity: true, relforcerowsecurity: true },
      { relname: 'user_conditions', relrowsecurity: true, relforcerowsecurity: true },
    ]);
  });

  it('owner stores an entry; free text is ciphertext at rest and plain text in the response', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const created = await service.createEntry(ownerA, primaryA, entryDto());
    expect(created).toMatchObject({ legacy: false, mood: 'nao_tao_bem', note: 'Dia corrido no trabalho', triggerNote: 'mudança' });
    expect(created.items.map((i) => i.customLabel)).toEqual([null, 'nuca dura']);

    const raw = await adminPool.query(`SELECT note, trigger_note FROM journal_entries WHERE id = $1`, [created.id]);
    expect(raw.rows[0].note).toMatch(/^v1:/);
    expect(raw.rows[0].trigger_note).toMatch(/^v1:/);
    const rawItem = await adminPool.query(`SELECT custom_label FROM journal_items WHERE entry_id = $1 AND custom_label IS NOT NULL`, [created.id]);
    expect(rawItem.rows[0].custom_label).toMatch(/^v1:/);
  });

  it('replaying a clientId on the same profile returns the stored entry; other profiles never collide', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const dto = entryDto();
    const first = await service.createEntry(ownerA, primaryA, dto);
    const again = await service.createEntry(ownerA, primaryA, dto);
    expect(again.id).toBe(first.id);
    expect(again).toEqual(first);
    const count = await adminPool.query(
      `SELECT count(*)::int AS n FROM journal_entries WHERE client_id = $1 AND profile_id = $2`,
      [dto.clientId, primaryA],
    );
    expect(count.rows[0].n).toBe(1);

    // clientId is unique per profile: the same id elsewhere is a new entry, never a conflict
    // and never someone else's entry.
    const onDependent = await service.createEntry(ownerA, dependentId, dto);
    expect(onDependent.id).not.toBe(first.id);
    const byStranger = await service.createEntry(strangerD, primaryD, dto);
    expect(byStranger.id).not.toBe(first.id);
    expect(byStranger.id).not.toBe(onDependent.id);
    const total = await adminPool.query(`SELECT count(*)::int AS n FROM journal_entries WHERE client_id = $1`, [dto.clientId]);
    expect(total.rows[0].n).toBe(3);

    // Concurrent retries of the same outbox record store one entry.
    const racing = entryDto();
    const results = await Promise.all([1, 2, 3].map(() => service.createEntry(ownerA, primaryA, racing)));
    expect(new Set(results.map((r) => r.id)).size).toBe(1);
  });

  it('symptom_knowledge is gone (0018) and client_id is unique per profile (0019)', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const table = await adminPool.query(`SELECT to_regclass('public.symptom_knowledge') AS t`);
    expect(table.rows[0].t).toBeNull();
    const constraints = await adminPool.query(
      `SELECT conname, pg_get_constraintdef(oid) AS def FROM pg_constraint
       WHERE conrelid = 'public.journal_entries'::regclass AND contype = 'u'`,
    );
    expect(constraints.rows).toEqual([
      { conname: 'journal_entries_profile_client_id_unique', def: 'UNIQUE (profile_id, client_id)' },
    ]);
  });

  it('history: owner sees new and legacy entries, newest first; stranger sees nothing', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const { entries } = await service.listEntries(ownerA, primaryA, { days: 30 }, 'pt-BR');
    expect(entries.length).toBeGreaterThanOrEqual(3);
    const legacy = entries.find((e) => e.id === legacyLogId);
    expect(legacy).toEqual({
      id: legacyLogId,
      legacy: true,
      recordedAt: expect.any(String),
      note: null,
      items: [{ kind: 'physical', legacyLabel: 'Peito', intensity: 4 }],
    });
    expect(entries.at(-1)!.id).toBe(legacyLogId);

    expect((await service.listEntries(strangerD, primaryA, {}, 'pt')).entries).toEqual([]);
  });

  it('dependent profile: CO_MANAGE writes, VIEW_ONLY reads only, stranger has no access', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const byCoManager = await service.createEntry(coManagerC, dependentId, entryDto());
    const author = await adminPool.query(`SELECT user_id FROM journal_entries WHERE id = $1`, [byCoManager.id]);
    expect(author.rows[0].user_id).toBe(coManagerC);

    const viewerList = await service.listEntries(viewerB, dependentId, {}, 'pt');
    expect(viewerList.entries.map((e) => e.id)).toContain(byCoManager.id);
    expect((viewerList.entries[0] as any).items.length).toBe(2);

    await expect(service.createEntry(viewerB, dependentId, entryDto())).rejects.toThrow(RLS_VIOLATION);
    await expect(service.deleteEntry(viewerB, dependentId, byCoManager.id)).rejects.toMatchObject({ status: 404 });
    await expect(service.createEntry(strangerD, dependentId, entryDto())).rejects.toThrow(RLS_VIOLATION);
    expect((await service.listEntries(strangerD, dependentId, {}, 'pt')).entries).toEqual([]);
  });

  it('items follow the parent entry: invisible to strangers, not writable by VIEW_ONLY', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const entry = await service.createEntry(ownerA, dependentId, entryDto());

    const strangerItems = await asUser(strangerD, (c) => c.query(`SELECT id FROM journal_items WHERE entry_id = $1`, [entry.id]));
    expect(strangerItems.rowCount).toBe(0);
    const viewerItems = await asUser(viewerB, (c) => c.query(`SELECT id FROM journal_items WHERE entry_id = $1`, [entry.id]));
    expect(viewerItems.rowCount).toBe(2);

    await asUser(viewerB, async (c) => {
      expect((await c.query(`DELETE FROM journal_items WHERE entry_id = $1`, [entry.id])).rowCount).toBe(0);
      expect((await c.query(`UPDATE journal_items SET intensity = 1 WHERE entry_id = $1`, [entry.id])).rowCount).toBe(0);
    });
    await expect(
      asUser(viewerB, (c) =>
        c.query(`INSERT INTO journal_items (entry_id, kind, option_key, persistence, intensity) VALUES ($1, 'emotional', 'passado.custom', 'hoje', 2)`, [entry.id]),
      ),
    ).rejects.toThrow(RLS_VIOLATION);
  });

  it('conditions: label encrypted, used in entries, archived softly, limited to 10, never cross-profile', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const condition = await service.createCondition(ownerA, primaryA, '  Enxaqueca ');
    expect(condition.label).toBe('Enxaqueca');
    const raw = await adminPool.query(`SELECT label FROM user_conditions WHERE id = $1`, [condition.id]);
    expect(raw.rows[0].label).toMatch(/^v1:/);

    const entry = await service.createEntry(
      ownerA,
      primaryA,
      entryDto({ triggers: [], items: [{ kind: 'condition', conditionId: condition.id, intensity: 3 }] }),
    );
    expect(entry.items[0]).toMatchObject({ kind: 'condition', conditionId: condition.id, label: 'Enxaqueca', intensity: 3 });

    // A condition of another profile can't be used, through the service or directly.
    await expect(
      service.createEntry(ownerA, dependentId, entryDto({ triggers: [], items: [{ kind: 'condition', conditionId: condition.id, intensity: 2 }] })),
    ).rejects.toMatchObject({ status: 400 });
    const dependentEntry = await service.createEntry(ownerA, dependentId, entryDto({ items: [] , triggers: [] }));
    await expect(
      asUser(ownerA, (c) =>
        c.query(`INSERT INTO journal_items (entry_id, kind, condition_id, intensity) VALUES ($1, 'condition', $2, 2)`, [dependentEntry.id, condition.id]),
      ),
    ).rejects.toThrow(RLS_VIOLATION);
    // UPDATE re-checks it too: a condition item can't be moved to another profile's condition.
    const dependentCondition = await service.createCondition(ownerA, dependentId, 'Rinite');
    await expect(
      asUser(ownerA, (c) =>
        c.query(`UPDATE journal_items SET condition_id = $2 WHERE entry_id = $1`, [entry.id, dependentCondition.id]),
      ),
    ).rejects.toThrow(RLS_VIOLATION);
    await asUser(ownerA, async (c) => {
      expect((await c.query(`UPDATE journal_items SET intensity = 4 WHERE entry_id = $1`, [entry.id])).rowCount).toBe(1);
    });
    await service.archiveCondition(ownerA, dependentId, dependentCondition.id);

    await service.archiveCondition(ownerA, primaryA, condition.id);
    expect((await service.listConditions(ownerA, primaryA)).conditions.map((c) => c.id)).not.toContain(condition.id);
    const history = await service.listEntries(ownerA, primaryA, {}, 'pt');
    const kept = history.entries.find((e) => e.id === entry.id) as any;
    expect(kept.items[0].label).toBe('Enxaqueca');
    await expect(service.archiveCondition(ownerA, primaryA, condition.id)).rejects.toMatchObject({ status: 404 });

    // Stranger and VIEW_ONLY cannot create conditions on the dependent; the limit holds.
    await expect(service.createCondition(strangerD, dependentId, 'Asma')).rejects.toThrow(RLS_VIOLATION);
    await expect(service.createCondition(viewerB, dependentId, 'Asma')).rejects.toThrow(RLS_VIOLATION);
    await Promise.all(Array.from({ length: 10 }, (_, i) => service.createCondition(coManagerC, dependentId, `C${i}`)));
    await expect(service.createCondition(ownerA, dependentId, 'C10')).rejects.toMatchObject({ status: 409 });
    expect((await service.listConditions(viewerB, dependentId)).conditions).toHaveLength(10);
    expect((await service.listConditions(strangerD, dependentId)).conditions).toEqual([]);
  });

  it('summary counts only keys of the active profile', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const summary = await service.summary(ownerA, dependentId, { days: 30 });
    expect(summary.byTime.futuro).toBeGreaterThan(0);
    expect(summary.byRegion.costas).toBeGreaterThan(0);
    expect(summary.byOptionKey['costas.custom']).toBeGreaterThan(0);
    expect(JSON.stringify(summary)).not.toMatch(/nuca dura|Dia corrido|Enxaqueca|C\d/);
    expect((await service.summary(strangerD, dependentId, {})).totalEntries).toBe(0);
  });

  it('delete: owner removes an entry (items cascade) and a legacy row; others get 404', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const entry = await service.createEntry(ownerA, primaryA, entryDto());
    await expect(service.deleteEntry(strangerD, primaryA, entry.id)).rejects.toMatchObject({ status: 404 });
    await service.deleteEntry(ownerA, primaryA, entry.id);
    const items = await adminPool.query(`SELECT count(*)::int AS n FROM journal_items WHERE entry_id = $1`, [entry.id]);
    expect(items.rows[0].n).toBe(0);

    await service.deleteEntry(ownerA, primaryA, legacyLogId);
    const legacy = await adminPool.query(`SELECT count(*)::int AS n FROM symptom_logs WHERE id = $1`, [legacyLogId]);
    expect(legacy.rows[0].n).toBe(0);
    await expect(service.deleteEntry(ownerA, primaryA, legacyLogId)).rejects.toMatchObject({ status: 404 });
  });

  it('check constraints reject out-of-contract values even without the API', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const entry = await service.createEntry(ownerA, primaryA, entryDto({ items: [], triggers: [] }));
    const insertItem = (sql: string) => asUser(ownerA, (c) => c.query(sql, [entry.id]));
    await expect(insertItem(`INSERT INTO journal_items (entry_id, kind, option_key, intensity) VALUES ($1, 'emotional', 'x', 6)`)).rejects.toThrow(/journal_items_intensity_check/);
    await expect(insertItem(`INSERT INTO journal_items (entry_id, kind, option_key, intensity) VALUES ($1, 'mental', 'x', 2)`)).rejects.toThrow(/journal_items_kind_check/);
    await expect(insertItem(`INSERT INTO journal_items (entry_id, kind, intensity) VALUES ($1, 'emotional', 2)`)).rejects.toThrow(/journal_items_shape_check/);
    await expect(insertItem(`INSERT INTO journal_items (entry_id, kind, option_key, body_side) VALUES ($1, 'physical', 'x', 'left')`)).rejects.toThrow(/journal_items_body_side_check/);
    await expect(
      asUser(ownerA, (c) =>
        c.query(`INSERT INTO journal_entries (user_id, profile_id, recorded_at, mood, client_id) VALUES ($1, $2, now(), 'otimo', $3)`, [ownerA, primaryA, randomUUID()]),
      ),
    ).rejects.toThrow(/journal_entries_mood_check/);
    // user_id must be the caller
    await expect(
      asUser(ownerA, (c) =>
        c.query(`INSERT INTO journal_entries (user_id, profile_id, recorded_at, mood, client_id) VALUES ($1, $2, now(), 'bem', $3)`, [coManagerC, primaryA, randomUUID()]),
      ),
    ).rejects.toThrow(RLS_VIOLATION);
  });

  it('deleting a profile cascades its entries, items and conditions', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const client = await adminPool.connect();
    try {
      await client.query('BEGIN');
      await client.query('DELETE FROM profiles WHERE id = $1', [dependentId]);
      const left = await client.query(
        `SELECT (SELECT count(*) FROM journal_entries WHERE profile_id = $1)::int AS entries,
                (SELECT count(*) FROM user_conditions WHERE profile_id = $1)::int AS conditions,
                (SELECT count(*) FROM journal_items i LEFT JOIN journal_entries e ON e.id = i.entry_id WHERE e.id IS NULL)::int AS orphans`,
        [dependentId],
      );
      expect(left.rows[0]).toEqual({ entries: 0, conditions: 0, orphans: 0 });
    } finally {
      await client.query('ROLLBACK').catch(() => {});
      client.release();
    }
  });
});
