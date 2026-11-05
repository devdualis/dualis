import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool, PoolClient } from 'pg';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { dropTestDatabase } from '../support/drop-test-database';

const MIGRATIONS_DIR = join(__dirname, '../../src/database/migrations');
const CATEGORY_MIGRATION = '0028_guardianship_consent_gaps.sql';
const APP_ROLE = 'dualis_share_cat_app';
const APP_PASSWORD = 'dualis_share_cat_app';
const HELPER_OWNER = 'dualis_helper_owner';
const SPEC = '[sharing-categories-rls.spec.ts]';

/**
 * Wave 0 contract for PREM-07 (Phase 11.1, decision D2): a sharing grant only opens the
 * data categories the owner picked. Enforced by PostgreSQL RLS, exercised through a LOGIN
 * role without SUPERUSER or BYPASSRLS (like production).
 *
 * Migrations are staged: everything before 0028, then legacy grants, then 0028 twice, so
 * the guarded backfill and the idempotency are both proven.
 *
 * Test names start with the tag of the 11.1-02 task whose SQL makes them pass
 * (02T1 categories and journal/conditions policies, 02T2 habits/care/safety policies,
 * 02T3 relationship, dependent confirmation, guard trigger and recursion check).
 */
describe('Security Regression: 0028 category-scoped sharing grants (PREM-07)', () => {
  let adminPool: Pool;
  let appPool: Pool;
  let baseUrl: string;
  let isolatedDb: string;
  let isDbAvailable = false;

  // Users
  const ownerA = '5a5a5a5a-0000-4000-8000-00000000000a'; // owns primaryA and the dependent
  const viewerB = '5b5b5b5b-0000-4000-8000-00000000000b'; // VIEW_ONLY {habits}
  const coManagerC = '5c5c5c5c-0000-4000-8000-00000000000c'; // CO_MANAGE {habits, physical_journal}
  const viewerE = '5e5e5e5e-0000-4000-8000-00000000000e'; // VIEW_ONLY {emotional_journal}
  const viewerF = '5f5f5f5f-0000-4000-8000-00000000000f'; // VIEW_ONLY {conditions, care}
  const legacyAcceptedUser = '5d5d5d5d-0000-4000-8000-000000000001';
  const legacyRevokedUser = '5d5d5d5d-0000-4000-8000-000000000003';
  const grantees = [viewerB, coManagerC, viewerE, viewerF];

  // Profiles
  const primaryA = 'a5a5a5a5-0000-4000-8000-0000000000a1';
  const dependentId = 'd5d5d5d5-0000-4000-8000-0000000000d5';

  // Legacy grants (seeded before 0028)
  const legacyAcceptedGrant = '6a6a6a6a-0000-4000-8000-000000000001';
  const legacyPendingGrant = '6a6a6a6a-0000-4000-8000-000000000002';
  const legacyRevokedGrant = '6a6a6a6a-0000-4000-8000-000000000003';
  // Grants created after 0028
  const grantB = '6b6b6b6b-0000-4000-8000-00000000000b';
  const grantC = '6c6c6c6c-0000-4000-8000-00000000000c';
  const grantE = '6e6e6e6e-0000-4000-8000-00000000000e';
  const grantF = '6f6f6f6f-0000-4000-8000-00000000000f';

  // Data rows on the dependent profile
  const physEntry = '7a000000-0000-4000-8000-000000000001';
  const emoEntry = '7a000000-0000-4000-8000-000000000002';
  const nullAreaEntry = '7a000000-0000-4000-8000-000000000003';
  const physItem = '7b000000-0000-4000-8000-000000000001';
  const emoItem = '7b000000-0000-4000-8000-000000000002';
  const nullAreaItem = '7b000000-0000-4000-8000-000000000003';
  const symptomPhysical = '7c000000-0000-4000-8000-000000000001'; // anatomical_system only
  const symptomEmotional = '7c000000-0000-4000-8000-000000000002'; // emotional_dimension only
  const symptomBoth = '7c000000-0000-4000-8000-000000000003';
  const symptomNeither = '7c000000-0000-4000-8000-000000000004';
  const conditionId = '7d000000-0000-4000-8000-000000000001';
  const readingId = '7d000000-0000-4000-8000-000000000002';
  const waterId = '7e000000-0000-4000-8000-000000000001';
  const habitsId = '7e000000-0000-4000-8000-000000000002';
  const careRecordId = '7f000000-0000-4000-8000-000000000001';
  const careDocumentId = '7f000000-0000-4000-8000-000000000002';
  const safetyEventId = '70000000-0000-4000-8000-000000000001';

  const ENTRY_IDS = [physEntry, emoEntry, nullAreaEntry];

  // Backfill evidence captured during the staged migration run.
  let backfill: Record<string, string[]> = {};
  let editedAfterSecondRun: string[] = [];

  const sorted = (values: string[]) => [...values].sort();
  const readMigration = (file: string) => readFileSync(join(MIGRATIONS_DIR, file), 'utf8');

  beforeAll(async () => {
    // CRITICAL SAFETY GUARDRAIL: only TEST_DATABASE_URL on a local host, never DATABASE_URL.
    const rawTestUrl = process.env.TEST_DATABASE_URL;
    if (!rawTestUrl) {
      console.warn(`${SPEC} SAFETY GUARD: TEST_DATABASE_URL not set. Skipping live database assertions.`);
      return;
    }
    const isCloudOrProd = /supabase\.co|supabase\.com|aws-|pooler|rds\.amazonaws\.com|compute\.amazonaws\.com|prod/i.test(rawTestUrl);
    const isLocal = /localhost|127\.0\.0\.1|test/i.test(rawTestUrl);
    if (isCloudOrProd || !isLocal) {
      console.error(`${SPEC} CRITICAL SAFETY TRIGGER: TEST_DATABASE_URL points to a remote/cloud host. Aborting.`);
      return;
    }

    baseUrl = rawTestUrl;
    const isolatedUrl = new URL(rawTestUrl);
    isolatedDb = `${isolatedUrl.pathname.slice(1) || 'postgres'}_sharing_categories_rls`.replace(/"/g, '');
    isolatedUrl.pathname = `/${isolatedDb}`;

    const admin = new Pool({ connectionString: rawTestUrl, max: 1, connectionTimeoutMillis: 3000 });
    try {
      await dropTestDatabase(admin, isolatedDb);
      await admin.query(`CREATE DATABASE "${isolatedDb}"`);
    } catch (err) {
      console.warn(`${SPEC} Live PostgreSQL not reachable: ${(err as Error).message}. Skipping live database assertions.`);
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
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dualis_app') THEN
          CREATE ROLE dualis_app LOGIN NOSUPERUSER NOBYPASSRLS PASSWORD 'dualis_local_test';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${APP_ROLE}') THEN
          CREATE ROLE ${APP_ROLE} LOGIN NOSUPERUSER NOBYPASSRLS PASSWORD '${APP_PASSWORD}';
        END IF;
      END
      $$;
    `);

    // Stage 1: every migration before 0028.
    const migrations = readdirSync(MIGRATIONS_DIR).filter((f) => /^\d{4}_.*\.sql$/.test(f)).sort();
    for (const file of migrations.filter((f) => f < '0028_')) {
      await adminPool.query(readMigration(file));
    }

    // Stage 2: legacy data created while sharing still meant "everything".
    await adminPool.query(
      `INSERT INTO users (id, name, email, password_hash, gender) VALUES
       ($1, 'Ana', 'share-cat-a@dualis.test', 'hash', 'feminino'),
       ($2, 'Bruno', 'share-cat-b@dualis.test', 'hash', 'masculino'),
       ($3, 'Carla', 'share-cat-c@dualis.test', 'hash', 'feminino'),
       ($4, 'Eva', 'share-cat-e@dualis.test', 'hash', 'feminino'),
       ($5, 'Fabio', 'share-cat-f@dualis.test', 'hash', 'masculino'),
       ($6, 'Lia', 'share-cat-l1@dualis.test', 'hash', 'feminino'),
       ($7, 'Rui', 'share-cat-l3@dualis.test', 'hash', 'masculino')`,
      [ownerA, viewerB, coManagerC, viewerE, viewerF, legacyAcceptedUser, legacyRevokedUser],
    );
    await adminPool.query(
      `INSERT INTO profiles (id, account_owner_id, profile_type, name, date_of_birth) VALUES
       ($1, $3, 'primary', 'Ana', '1985-04-02'),
       ($2, $3, 'dependent_minor', 'Lucas', current_date - interval '10 years')`,
      [primaryA, dependentId, ownerA],
    );
    await adminPool.query(
      `INSERT INTO shared_access_grants
         (id, granter_user_id, target_profile_id, grantee_user_id, access_level, invite_code, status, expires_at, accepted_at, revoked_at)
       VALUES ($1, $4, $5, $6, 'VIEW_ONLY', 'SCLEGACY01', 'ACCEPTED', now() + interval '72 hours', now(), NULL),
              ($2, $4, $5, NULL, 'CO_MANAGE', 'SCLEGACY02', 'PENDING', now() + interval '72 hours', NULL, NULL),
              ($3, $4, $5, $7, 'VIEW_ONLY', 'SCLEGACY03', 'REVOKED', now() + interval '72 hours', now(), now())`,
      [legacyAcceptedGrant, legacyPendingGrant, legacyRevokedGrant, ownerA, dependentId, legacyAcceptedUser, legacyRevokedUser],
    );

    // Stage 3: 0028, first run (the file must exist: ENOENT here is the Wave 0 red state).
    await adminPool.query(readMigration(CATEGORY_MIGRATION));
    const firstRun = await adminPool.query(
      `SELECT id, categories FROM shared_access_grants WHERE id = ANY($1::uuid[])`,
      [[legacyAcceptedGrant, legacyPendingGrant, legacyRevokedGrant]],
    );
    backfill = Object.fromEntries(firstRun.rows.map((r) => [r.id, r.categories as string[]]));

    // The owner narrows one legacy grant, then 0028 runs again: the edit must survive.
    const ownerEdit = await adminPool.connect();
    try {
      await ownerEdit.query('BEGIN');
      await ownerEdit.query(`SELECT set_config('app.current_user_id', $1, true)`, [ownerA]);
      await ownerEdit.query(`UPDATE shared_access_grants SET categories = ARRAY['habits']::text[] WHERE id = $1`, [legacyAcceptedGrant]);
      await ownerEdit.query('COMMIT');
    } catch (err) {
      await ownerEdit.query('ROLLBACK').catch(() => {});
      throw err;
    } finally {
      ownerEdit.release();
    }
    await adminPool.query(readMigration(CATEGORY_MIGRATION));
    editedAfterSecondRun = (
      await adminPool.query(`SELECT categories FROM shared_access_grants WHERE id = $1`, [legacyAcceptedGrant])
    ).rows[0].categories;

    await adminPool.query(`
      GRANT USAGE ON SCHEMA public TO ${APP_ROLE};
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${APP_ROLE};
    `);

    // Grants created after 0028, one per category scenario. Only 02T1 columns are used here.
    await adminPool.query(
      `INSERT INTO shared_access_grants
         (id, granter_user_id, target_profile_id, grantee_user_id, access_level, invite_code, status, expires_at, accepted_at, categories)
       VALUES ($1, $5, $6, $7, 'VIEW_ONLY', 'SCGRANTB01', 'ACCEPTED', now() + interval '72 hours', now(), ARRAY['habits']::text[]),
              ($2, $5, $6, $8, 'CO_MANAGE', 'SCGRANTC01', 'ACCEPTED', now() + interval '72 hours', now(), ARRAY['habits', 'physical_journal']::text[]),
              ($3, $5, $6, $9, 'VIEW_ONLY', 'SCGRANTE01', 'ACCEPTED', now() + interval '72 hours', now(), ARRAY['emotional_journal']::text[]),
              ($4, $5, $6, $10, 'VIEW_ONLY', 'SCGRANTF01', 'ACCEPTED', now() + interval '72 hours', now(), ARRAY['conditions', 'care']::text[])`,
      [grantB, grantC, grantE, grantF, ownerA, dependentId, viewerB, coManagerC, viewerE, viewerF],
    );

    // One row per data table on the dependent profile, authored by the owner.
    await adminPool.query(
      `INSERT INTO journal_entries (id, user_id, profile_id, recorded_at, mood, area, client_id) VALUES
       ($1, $4, $5, now() - interval '1 day', 'bem', 'physical', 'sc-phys'),
       ($2, $4, $5, now() - interval '1 day', 'normal', 'emotional', 'sc-emo'),
       ($3, $4, $5, now() - interval '1 day', 'nao_tao_bem', NULL, 'sc-null')`,
      [physEntry, emoEntry, nullAreaEntry, ownerA, dependentId],
    );
    await adminPool.query(
      `INSERT INTO journal_items (id, entry_id, kind, option_key, intensity) VALUES
       ($1, $4, 'physical', 'cabeca.nuca.rigida', 2),
       ($2, $5, 'emotional', 'futuro.mente.antecipar', 3),
       ($3, $6, 'emotional', 'passado.custom', 2)`,
      [physItem, emoItem, nullAreaItem, physEntry, emoEntry, nullAreaEntry],
    );
    await adminPool.query(
      `INSERT INTO symptom_logs (id, user_id, profile_id, intensity, anatomical_system, emotional_dimension) VALUES
       ($1, $5, $6, 3, 'respiratory', NULL),
       ($2, $5, $6, 3, NULL, 'ansiedade'),
       ($3, $5, $6, 3, 'respiratory', 'ansiedade'),
       ($4, $5, $6, 3, NULL, NULL)`,
      [symptomPhysical, symptomEmotional, symptomBoth, symptomNeither, ownerA, dependentId],
    );
    await adminPool.query(
      `INSERT INTO user_conditions (id, user_id, profile_id, label, tracking) VALUES ($1, $2, $3, 'Rinite', ARRAY['weight']::text[])`,
      [conditionId, ownerA, dependentId],
    );
    await adminPool.query(
      `INSERT INTO condition_readings (id, user_id, profile_id, entry_id, condition_id, kind, measured_at, data)
       VALUES ($1, $2, $3, $4, $5, 'weight', now(), 'v1:x')`,
      [readingId, ownerA, dependentId, physEntry, conditionId],
    );
    await adminPool.query(
      `INSERT INTO water_intake_logs (id, user_id, profile_id, amount_ml) VALUES ($1, $2, $3, 250)`,
      [waterId, ownerA, dependentId],
    );
    await adminPool.query(
      `INSERT INTO daily_habits (id, user_id, profile_id, day) VALUES ($1, $2, $3, current_date)`,
      [habitsId, ownerA, dependentId],
    );
    await adminPool.query(
      `INSERT INTO care_records (id, user_id, profile_id, kind, data) VALUES ($1, $2, $3, 'allergy', 'v1:x')`,
      [careRecordId, ownerA, dependentId],
    );
    await adminPool.query(
      `INSERT INTO care_documents (id, user_id, profile_id, kind, mime, size_bytes, file, status)
       VALUES ($1, $2, $3, 'lab', 'application/pdf', 1, '\\x00'::bytea, 'archived')`,
      [careDocumentId, ownerA, dependentId],
    );
    await adminPool.query(
      `INSERT INTO safety_resource_events (id, user_id, profile_id, action, channel, client_timestamp)
       VALUES ($1, $2, $3, 'call_started', 'tel:188', now())`,
      [safetyEventId, ownerA, dependentId],
    );

    const appUrl = new URL(isolatedUrl.toString());
    appUrl.username = APP_ROLE;
    appUrl.password = APP_PASSWORD;
    appPool = new Pool({ connectionString: appUrl.toString(), max: 4, connectionTimeoutMillis: 3000 });
    const role = await appPool.query(`SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user`);
    expect(role.rows[0]).toEqual({ rolsuper: false, rolbypassrls: false });

    isDbAvailable = true;
  });

  afterAll(async () => {
    if (appPool) await appPool.end().catch(() => {});
    if (adminPool) await adminPool.end().catch(() => {});
    if (baseUrl && isolatedDb) {
      const admin = new Pool({ connectionString: baseUrl, max: 1, connectionTimeoutMillis: 3000 });
      await dropTestDatabase(admin, isolatedDb).catch(() => {});
      await admin.end().catch(() => {});
    }
  });

  /** Runs fn through the NOSUPERUSER NOBYPASSRLS app role as userId; always rolls back. */
  async function asApp<T>(userId: string, fn: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await appPool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userId]);
      return await fn(client);
    } finally {
      await client.query('ROLLBACK').catch(() => {});
      client.release();
    }
  }

  /** Expects the promise to reject with the given SQLSTATE (and optional message). */
  async function expectSqlError(promise: Promise<unknown>, code: string, message?: RegExp) {
    const err = await promise.then(
      () => null,
      (e: { code?: string; message?: string }) => e,
    );
    expect(err, `expected SQLSTATE ${code}, but the statement succeeded`).not.toBeNull();
    expect(err?.code, err?.message).toBe(code);
    if (message) expect(err?.message).toMatch(message);
  }

  const ids = async (c: PoolClient, sql: string, params: unknown[]) =>
    sorted((await c.query(sql, params)).rows.map((r) => r.id as string));
  const entryIds = (c: PoolClient) =>
    ids(c, `SELECT id FROM journal_entries WHERE id = ANY($1::uuid[])`, [ENTRY_IDS]);
  const itemIds = (c: PoolClient) =>
    ids(c, `SELECT id FROM journal_items WHERE entry_id = ANY($1::uuid[])`, [ENTRY_IDS]);
  const symptomIds = (c: PoolClient) =>
    ids(c, `SELECT id FROM symptom_logs WHERE profile_id = $1`, [dependentId]);
  const countOn = async (c: PoolClient, table: string) =>
    (await c.query(`SELECT count(*)::int AS n FROM ${table} WHERE profile_id = $1`, [dependentId])).rows[0].n as number;

  const insertEntry = (c: PoolClient, userId: string, area: string | null, clientId: string) =>
    c.query(
      `INSERT INTO journal_entries (user_id, profile_id, recorded_at, mood, area, client_id)
       VALUES ($1, $2, now(), 'bem', $3, $4) RETURNING id`,
      [userId, dependentId, area, clientId],
    );

  // ---------------------------------------------------------------- 02T1

  it('02T1: VIEW_ONLY grantee with categories {habits} gets 0 rows from journal_entries', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(viewerB, async (c) => {
      expect(await countOn(c, 'journal_entries')).toBe(0);
    });
  });

  it('02T1: backfill gives ACCEPTED and PENDING legacy grants every category except emotional_journal, REVOKED gets {habits}, and an owner edit survives a second 0028 run', (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const expected = sorted(['habits', 'physical_journal', 'conditions', 'care']);
    expect(sorted(backfill[legacyAcceptedGrant])).toEqual(expected);
    expect(sorted(backfill[legacyPendingGrant])).toEqual(expected);
    expect(backfill[legacyRevokedGrant]).toEqual(['habits']);
    expect(editedAfterSecondRun).toEqual(['habits']);
  });

  it('02T1: VIEW_ONLY {habits} grantee reads 0 rows of journal, symptom and condition tables', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(viewerB, async (c) => {
      expect(await entryIds(c)).toEqual([]);
      expect(await itemIds(c)).toEqual([]);
      expect(await symptomIds(c)).toEqual([]);
      expect(await countOn(c, 'user_conditions')).toBe(0);
      expect(await countOn(c, 'condition_readings')).toBe(0);
    });
  });

  it('02T1: CO_MANAGE {habits, physical_journal} grantee sees only physical entries, items and physical symptom rows', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(coManagerC, async (c) => {
      // NULL area (pre-v2.1 entries) counts as emotional_journal.
      expect(await entryIds(c)).toEqual([physEntry]);
      expect(await itemIds(c)).toEqual([physItem]);
      // A1: emotional_dimension rows need emotional_journal; rows with neither column are physical.
      expect(await symptomIds(c)).toEqual(sorted([symptomPhysical, symptomNeither]));
      expect(await countOn(c, 'user_conditions')).toBe(0);
      expect(await countOn(c, 'condition_readings')).toBe(0);
    });
  });

  it('02T1: CO_MANAGE {habits, physical_journal} grantee writes physical entries only (42501 otherwise)', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(coManagerC, async (c) => {
      const res = await insertEntry(c, coManagerC, 'physical', 'sc-c-phys');
      expect(res.rowCount).toBe(1);
    });
    await asApp(coManagerC, async (c) => {
      await expectSqlError(insertEntry(c, coManagerC, 'emotional', 'sc-c-emo'), '42501');
    });
    await asApp(coManagerC, async (c) => {
      await expectSqlError(insertEntry(c, coManagerC, null, 'sc-c-null'), '42501');
    });
    // UPDATE re-checks the new row: moving its physical entry to the emotional area fails.
    await asApp(coManagerC, async (c) => {
      const created = await insertEntry(c, coManagerC, 'physical', 'sc-c-move');
      await expectSqlError(
        c.query(`UPDATE journal_entries SET area = 'emotional' WHERE id = $1`, [created.rows[0].id]),
        '42501',
      );
    });
  });

  it('02T1: VIEW_ONLY {emotional_journal} grantee sees emotional and NULL-area entries and emotional-only symptom rows', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(viewerE, async (c) => {
      expect(await entryIds(c)).toEqual(sorted([emoEntry, nullAreaEntry]));
      expect(await itemIds(c)).toEqual(sorted([emoItem, nullAreaItem]));
      // Both columns set needs both categories; physical-only and neither need physical_journal.
      expect(await symptomIds(c)).toEqual([symptomEmotional]);
    });
  });

  it('02T1: VIEW_ONLY {conditions, care} grantee sees conditions and readings but no journal rows', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(viewerF, async (c) => {
      expect(await countOn(c, 'user_conditions')).toBe(1);
      expect(await countOn(c, 'condition_readings')).toBe(1);
      expect(await entryIds(c)).toEqual([]);
      expect(await itemIds(c)).toEqual([]);
      expect(await symptomIds(c)).toEqual([]);
    });
  });

  it('02T1: 0013 helpers stay callable without overload ambiguity and the category helpers answer per category', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(ownerA, async (c) => {
      expect((await c.query(`SELECT app_can_read_profile($1) AS ok`, [dependentId])).rows[0].ok).toBe(true);
      expect((await c.query(`SELECT app_can_write_profile($1) AS ok`, [dependentId])).rows[0].ok).toBe(true);
      expect((await c.query(`SELECT app_has_profile_grant($1, true) AS ok`, [dependentId])).rows[0].ok).toBe(false);
      expect((await c.query(`SELECT app_has_profile_grant($1) AS ok`, [dependentId])).rows[0].ok).toBe(false);
      expect((await c.query(`SELECT app_can_read_profile_category($1, 'emotional_journal') AS ok`, [dependentId])).rows[0].ok).toBe(true);
    });
    await asApp(viewerB, async (c) => {
      expect((await c.query(`SELECT app_has_profile_grant($1, false) AS ok`, [dependentId])).rows[0].ok).toBe(true);
      expect((await c.query(`SELECT app_can_read_profile_category($1, 'habits') AS ok`, [dependentId])).rows[0].ok).toBe(true);
      expect((await c.query(`SELECT app_can_read_profile_category($1, 'care') AS ok`, [dependentId])).rows[0].ok).toBe(false);
      expect((await c.query(`SELECT app_can_write_profile_category($1, 'habits') AS ok`, [dependentId])).rows[0].ok).toBe(false);
    });
    await asApp(coManagerC, async (c) => {
      expect((await c.query(`SELECT app_has_profile_grant_category($1, 'physical_journal', true) AS ok`, [dependentId])).rows[0].ok).toBe(true);
      expect((await c.query(`SELECT app_has_profile_grant_category($1, 'emotional_journal', false) AS ok`, [dependentId])).rows[0].ok).toBe(false);
      expect((await c.query(`SELECT app_can_write_profile_category($1, 'physical_journal') AS ok`, [dependentId])).rows[0].ok).toBe(true);
    });
    await asApp(viewerB, async (c) => {
      const mapped = await c.query(
        `SELECT app_journal_area_category('physical') AS physical, app_journal_area_category('emotional') AS emotional,
                app_journal_area_category(NULL) AS legacy`,
      );
      expect(mapped.rows[0]).toEqual({ physical: 'physical_journal', emotional: 'emotional_journal', legacy: 'emotional_journal' });
    });
  });

  // ---------------------------------------------------------------- 02T2

  it('02T2: VIEW_ONLY {habits} grantee reads water and daily habits but no care rows', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(viewerB, async (c) => {
      expect(await countOn(c, 'water_intake_logs')).toBe(1);
      expect(await countOn(c, 'daily_habits')).toBe(1);
      expect(await countOn(c, 'care_records')).toBe(0);
      expect(await countOn(c, 'care_documents')).toBe(0);
    });
  });

  it('02T2: VIEW_ONLY {conditions, care} grantee reads care records and documents but no habits rows', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(viewerF, async (c) => {
      expect(await countOn(c, 'care_records')).toBe(1);
      expect(await countOn(c, 'care_documents')).toBe(1);
      expect(await countOn(c, 'water_intake_logs')).toBe(0);
      expect(await countOn(c, 'daily_habits')).toBe(0);
    });
  });

  it('02T2: safety resource events stay with the owner; no grantee reads them', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    for (const grantee of grantees) {
      await asApp(grantee, async (c) => {
        expect(await countOn(c, 'safety_resource_events')).toBe(0);
      });
    }
    await asApp(ownerA, async (c) => {
      expect(await countOn(c, 'safety_resource_events')).toBe(1);
    });
    // triage_emergency_events was folded into safety_resource_events and dropped by 0015.
    const legacy = await adminPool.query(`SELECT to_regclass('public.triage_emergency_events') AS t`);
    expect(legacy.rows[0].t).toBeNull();
  });

  it('02T2: the owner reads every seeded row of every table', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(ownerA, async (c) => {
      expect(await entryIds(c)).toEqual(sorted(ENTRY_IDS));
      expect(await itemIds(c)).toEqual(sorted([physItem, emoItem, nullAreaItem]));
      expect(await symptomIds(c)).toEqual(sorted([symptomPhysical, symptomEmotional, symptomBoth, symptomNeither]));
      for (const table of ['user_conditions', 'condition_readings', 'water_intake_logs', 'daily_habits', 'care_records', 'care_documents', 'safety_resource_events']) {
        expect(await countOn(c, table), table).toBe(1);
      }
    });
  });

  // ---------------------------------------------------------------- 02T3

  it('02T3: legacy grants keep relationship NULL; a grantee cannot change categories but can still revoke', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const legacy = await adminPool.query(
      `SELECT relationship FROM shared_access_grants WHERE id = ANY($1::uuid[])`,
      [[legacyAcceptedGrant, legacyPendingGrant, legacyRevokedGrant]],
    );
    expect(legacy.rows).toEqual([{ relationship: null }, { relationship: null }, { relationship: null }]);

    await asApp(coManagerC, async (c) => {
      await expectSqlError(
        c.query(`UPDATE shared_access_grants SET categories = ARRAY['habits', 'physical_journal', 'emotional_journal']::text[] WHERE id = $1`, [grantC]),
        'P0001',
        /GRANTEE_MAY_ONLY_REVOKE/,
      );
    });
    await asApp(coManagerC, async (c) => {
      await expectSqlError(
        c.query(`UPDATE shared_access_grants SET relationship = 'friend' WHERE id = $1`, [grantC]),
        'P0001',
        /GRANTEE_MAY_ONLY_REVOKE/,
      );
    });
    await asApp(coManagerC, async (c) => {
      const res = await c.query(`UPDATE shared_access_grants SET status = 'REVOKED', revoked_at = now() WHERE id = $1`, [grantC]);
      expect(res.rowCount).toBe(1);
    });
  });

  it('02T3: the granter edits categories of an ACCEPTED grant; a REVOKED grant is locked (GRANT_SCOPE_LOCKED)', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(ownerA, async (c) => {
      const res = await c.query(
        `UPDATE shared_access_grants SET categories = ARRAY['habits', 'care']::text[], dependent_share_confirmed_at = now() WHERE id = $1`,
        [grantB],
      );
      expect(res.rowCount).toBe(1);
    });
    await asApp(ownerA, async (c) => {
      await expectSqlError(
        c.query(`UPDATE shared_access_grants SET categories = ARRAY['habits', 'care']::text[] WHERE id = $1`, [legacyRevokedGrant]),
        'P0001',
        /GRANT_SCOPE_LOCKED/,
      );
    });
  });

  it('02T3: CHECK constraints reject unknown categories and relationships (23514)', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const insertOnPrimary = (c: PoolClient, code: string, categories: string[], relationship: string | null) =>
      c.query(
        `INSERT INTO shared_access_grants (granter_user_id, target_profile_id, access_level, invite_code, expires_at, categories, relationship)
         VALUES ($1, $2, 'VIEW_ONLY', $3, now() + interval '72 hours', $4::text[], $5)`,
        [ownerA, primaryA, code, categories, relationship],
      );
    await asApp(ownerA, async (c) => {
      await expectSqlError(insertOnPrimary(c, 'SCCHECK001', ['habits', 'safety'], 'friend'), '23514');
    });
    await asApp(ownerA, async (c) => {
      await expectSqlError(insertOnPrimary(c, 'SCCHECK002', ['habits'], 'boss'), '23514');
    });
    await asApp(ownerA, async (c) => {
      const res = await insertOnPrimary(c, 'SCCHECK003', ['habits'], 'caregiver');
      expect(res.rowCount).toBe(1);
    });
  });

  it('02T3: sharing a dependent requires dependent_share_confirmed_at; the primary profile does not (gap 9)', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const insertGrant = (c: PoolClient, code: string, profileId: string, confirmed: boolean) =>
      c.query(
        `INSERT INTO shared_access_grants
           (granter_user_id, target_profile_id, access_level, invite_code, expires_at, categories, relationship, dependent_share_confirmed_at)
         VALUES ($1, $2, 'VIEW_ONLY', $3, now() + interval '72 hours', ARRAY['habits']::text[], 'parent',
                 CASE WHEN $4::boolean THEN now() ELSE NULL END)`,
        [ownerA, profileId, code, confirmed],
      );
    await asApp(ownerA, async (c) => {
      await expectSqlError(insertGrant(c, 'SCCONFIRM1', dependentId, false), '42501');
    });
    await asApp(ownerA, async (c) => {
      expect((await insertGrant(c, 'SCCONFIRM2', dependentId, true)).rowCount).toBe(1);
    });
    await asApp(ownerA, async (c) => {
      expect((await insertGrant(c, 'SCCONFIRM3', primaryA, false)).rowCount).toBe(1);
    });
  });

  // Runs LAST: it changes function owners for the rest of the file.
  it('02T3: policies have no recursion (42P17) when every SECURITY DEFINER helper is owned by a NOSUPERUSER NOBYPASSRLS role', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

    const snapshot = async () => {
      const result: Record<string, number> = {};
      await asApp(viewerB, async (c) => {
        result.bProfiles = (await c.query(`SELECT count(*)::int AS n FROM profiles`)).rows[0].n;
        result.bWater = await countOn(c, 'water_intake_logs');
      });
      await asApp(coManagerC, async (c) => {
        result.cEntries = (await entryIds(c)).length;
        result.cItems = (await itemIds(c)).length;
      });
      await asApp(ownerA, async (c) => {
        result.aGrants = (await c.query(`SELECT count(*)::int AS n FROM shared_access_grants`)).rows[0].n;
        result.aProfiles = (await c.query(`SELECT count(*)::int AS n FROM profiles`)).rows[0].n;
      });
      return result;
    };

    const before = await snapshot();
    expect(before).toEqual({ bProfiles: 1, bWater: 1, cEntries: 1, cItems: 1, aGrants: 7, aProfiles: 2 });

    await adminPool.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${HELPER_OWNER}') THEN
          CREATE ROLE ${HELPER_OWNER} NOLOGIN NOSUPERUSER NOBYPASSRLS;
        END IF;
      END
      $$;
      GRANT USAGE ON SCHEMA public TO ${HELPER_OWNER};
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${HELPER_OWNER};
    `);
    const definers = await adminPool.query(
      `SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
       FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'public' AND p.prosecdef
         AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = p.oid AND d.deptype = 'e')`,
    );
    const names = definers.rows.map((r) => r.proname as string);
    expect(names).toEqual(expect.arrayContaining(['app_has_profile_grant', 'app_has_profile_grant_category', 'app_owns_profile', 'app_profile_type']));
    for (const fn of definers.rows) {
      await adminPool.query(`ALTER FUNCTION public.${fn.proname}(${fn.args}) OWNER TO ${HELPER_OWNER}`);
    }
    const owners = await adminPool.query(
      `SELECT DISTINCT r.rolname, r.rolsuper, r.rolbypassrls
       FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace JOIN pg_roles r ON r.oid = p.proowner
       WHERE n.nspname = 'public' AND p.prosecdef
         AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = p.oid AND d.deptype = 'e')`,
    );
    expect(owners.rows).toEqual([{ rolname: HELPER_OWNER, rolsuper: false, rolbypassrls: false }]);

    const after = await snapshot().catch((err: { code?: string; message?: string }) => {
      expect(err.code, `infinite recursion in policy: ${err.message}`).not.toBe('42P17');
      throw err;
    });
    expect(after).toEqual(before);
  });
});
