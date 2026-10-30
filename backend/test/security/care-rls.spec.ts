import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import { readdirSync, readFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';
import { join } from 'node:path';
import * as dotenv from 'dotenv';
import * as schema from '../../src/database/schema';
import { DatabaseService } from '../../src/database/database.service';
import { EncryptionService } from '../../src/common/encryption/encryption.service';
import { CareService } from '../../src/modules/care/care.service';

dotenv.config();

const MIGRATIONS_DIR = join(__dirname, '../../src/database/migrations');
const CARE_MIGRATION = '0021_premium_care.sql';
const APP_ROLE = 'dualis_care_app';
const APP_PASSWORD = 'dualis_care_app';

/**
 * "Meus cuidados" tables (0021) under RLS, exercised through the real CareService
 * connected as a LOGIN role without SUPERUSER or BYPASSRLS (like production).
 */
describe('Security Regression: 0021 premium care (care_records, care_documents RLS)', () => {
  let adminPool: Pool;
  let appPool: Pool;
  let service: CareService;
  let reader: { read: () => Promise<unknown> };
  let readerResult: unknown = { values: [{ item: 'Colesterol total', value: '212', unit: 'mg/dL', reference: 'até 190' }] };
  let isDbAvailable = false;

  const ownerA = '8a8a8a8a-0000-4000-8000-00000000000a';
  const viewerB = '8b8b8b8b-0000-4000-8000-00000000000b';
  const coManagerC = '8c8c8c8c-0000-4000-8000-00000000000c';
  const strangerD = '8d8d8d8d-0000-4000-8000-00000000000d';
  const primaryA = 'a8a8a8a8-0000-4000-8000-0000000000a1';
  const dependentId = 'd8d8d8d8-0000-4000-8000-0000000000d8';
  const primaryD = 'a8a8a8a8-0000-4000-8000-0000000000d1';

  const medication = {
    name: 'Losartana', strength: '50 mg', times: ['08:00', '20:00'], weekdays: [], stockCount: 10, stockPerIntake: 1, stockWarnAt: 5, active: true,
  };

  beforeAll(async () => {
    // CRITICAL SAFETY GUARDRAIL: only TEST_DATABASE_URL on a local host, never DATABASE_URL.
    const rawTestUrl = process.env.TEST_DATABASE_URL;
    if (!rawTestUrl) {
      console.warn('[care-rls.spec.ts] SAFETY GUARD: TEST_DATABASE_URL not set. Skipping live database assertions.');
      return;
    }
    const isCloudOrProd = /supabase\.co|supabase\.com|aws-|pooler|rds\.amazonaws\.com|compute\.amazonaws\.com|prod/i.test(rawTestUrl);
    const isLocal = /localhost|127\.0\.0\.1|test/i.test(rawTestUrl);
    if (isCloudOrProd || !isLocal) {
      console.error('[care-rls.spec.ts] CRITICAL SAFETY TRIGGER: TEST_DATABASE_URL points to a remote/cloud host. Aborting.');
      return;
    }

    const isolatedUrl = new URL(rawTestUrl);
    const isolatedDb = `${isolatedUrl.pathname.slice(1) || 'postgres'}_care_rls`.replace(/"/g, '');
    isolatedUrl.pathname = `/${isolatedDb}`;

    const admin = new Pool({ connectionString: rawTestUrl, max: 1, connectionTimeoutMillis: 3000 });
    try {
      await admin.query(`DROP DATABASE IF EXISTS "${isolatedDb}" WITH (FORCE)`);
      await admin.query(`CREATE DATABASE "${isolatedDb}"`);
    } catch (err) {
      console.warn(`[care-rls.spec.ts] Live PostgreSQL not reachable: ${(err as Error).message}. Skipping.`);
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
    expect(migrations).toContain(CARE_MIGRATION);
    for (const file of migrations) {
      await adminPool.query(readFileSync(join(MIGRATIONS_DIR, file), 'utf8'));
    }
    // Idempotent: a second run must not fail.
    for (const file of [CARE_MIGRATION]) {
      await adminPool.query(readFileSync(join(MIGRATIONS_DIR, file), 'utf8'));
    }

    await adminPool.query(`
      GRANT USAGE ON SCHEMA public TO ${APP_ROLE}, authenticated;
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${APP_ROLE}, authenticated;
    `);

    await adminPool.query(
      `INSERT INTO users (id, name, email, password_hash, gender) VALUES
       ($1, 'Ana', 'care-a@dualis.test', 'hash', 'feminino'),
       ($2, 'Bruno', 'care-b@dualis.test', 'hash', 'masculino'),
       ($3, 'Carla', 'care-c@dualis.test', 'hash', 'feminino'),
       ($4, 'Diego', 'care-d@dualis.test', 'hash', 'masculino')`,
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
       VALUES ($1, $2, $3, 'VIEW_ONLY', 'CAREV1', 'ACCEPTED', now() + interval '72 hours', now()),
              ($1, $2, $4, 'CO_MANAGE', 'CAREV2', 'ACCEPTED', now() + interval '72 hours', now())`,
      [ownerA, dependentId, viewerB, coManagerC],
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
    reader = { read: async () => readerResult };
    service = new CareService(new DatabaseService(db, appPool), encryption, reader as any);
    isDbAvailable = true;
  });

  afterAll(async () => {
    if (appPool) await appPool.end().catch(() => {});
    if (adminPool) await adminPool.end().catch(() => {});
  });

  const RLS_VIOLATION = /row-level security/;

  it('creates both tables with forced RLS', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const rows = (
      await adminPool.query(
        `SELECT relname, relrowsecurity, relforcerowsecurity FROM pg_class
         WHERE relname IN ('care_documents', 'care_records') ORDER BY relname`,
      )
    ).rows;
    expect(rows).toEqual([
      { relname: 'care_documents', relrowsecurity: true, relforcerowsecurity: true },
      { relname: 'care_records', relrowsecurity: true, relforcerowsecurity: true },
    ]);
  });

  it('owner stores an allergy: ciphertext at rest, plain text in the response', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const created = await service.createRecord(ownerA, primaryA, {
      kind: 'allergy',
      data: { type: 'medication', name: 'Dipirona', reaction: 'manchas na pele', showOnProfile: true },
    });
    expect(created.data).toMatchObject({ name: 'Dipirona', reaction: 'manchas na pele' });
    const raw = (await adminPool.query(`SELECT data FROM care_records WHERE id = $1`, [created.id])).rows[0];
    expect(raw.data).toMatch(/^v1:/);
    expect(raw.data).not.toContain('Dipirona');
  });

  it('rejects fields outside the contract (no computed dose, no judgments)', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await expect(
      service.createRecord(ownerA, primaryA, { kind: 'medication', data: { ...medication, suggestedDose: '2x' } }),
    ).rejects.toThrow();
    await expect(
      service.createRecord(ownerA, primaryA, { kind: 'vaccine_dose', data: { doseLabel: 'Reforço', appliedOn: '21/10/2026' } }),
    ).rejects.toThrow();
  });

  it('dependent profile: CO_MANAGE writes, VIEW_ONLY reads only, stranger sees nothing', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const dose = await service.createRecord(coManagerC, dependentId, {
      kind: 'vaccine_dose',
      data: { vaccineKey: 'dt', doseLabel: 'Reforço', appliedOn: '2026-10-21', batch: 'DT2026A17' },
    });
    expect(dose.occursAt).toBe('2026-10-21T00:00:00.000Z');
    const seenByViewer = await service.listRecords(viewerB, dependentId, { kind: 'vaccine_dose' });
    expect(seenByViewer.map((r) => r.id)).toEqual([dose.id]);
    await expect(
      service.createRecord(viewerB, dependentId, { kind: 'allergy', data: { type: 'food', name: 'Camarão', showOnProfile: false } }),
    ).rejects.toThrow(RLS_VIOLATION);
    expect(await service.listRecords(strangerD, dependentId, { kind: 'vaccine_dose' })).toEqual([]);
    await expect(service.deleteRecord(strangerD, dependentId, dose.id)).rejects.toThrow('Record not found');
  });

  it('"Tomei" logs an intake and lowers the stock by the configured amount only', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const med = await service.createRecord(ownerA, primaryA, { kind: 'medication', data: medication });
    const taken = await service.logIntake(ownerA, primaryA, med.id, { scheduledFor: '2026-10-28T11:00:00.000Z', action: 'taken' });
    expect(taken.medication.data.stockCount).toBe(9);
    const skipped = await service.logIntake(ownerA, primaryA, med.id, { scheduledFor: '2026-10-28T23:00:00.000Z', action: 'skipped' });
    expect(skipped.medication.data.stockCount).toBe(9);
    const intakes = await service.listRecords(ownerA, primaryA, { kind: 'medication_intake', parentId: med.id });
    expect(intakes.map((i) => i.data.action)).toEqual(['skipped', 'taken']);
    await expect(
      service.logIntake(strangerD, primaryD, med.id, { scheduledFor: '2026-10-28T11:00:00.000Z', action: 'taken' }),
    ).rejects.toThrow('Record not found');
  });

  it('documents: file encrypted at rest, read into unconfirmed rows, saved only when every row is confirmed', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const pdf = Buffer.from('%PDF-1.4 fake lab report');
    const doc = await service.uploadDocument(ownerA, primaryA, { kind: 'lab', mime: 'application/pdf', fileBase64: pdf.toString('base64'), read: true });
    expect(doc.status).toBe('processing');
    const raw = (await adminPool.query(`SELECT file FROM care_documents WHERE id = $1`, [doc.id])).rows[0];
    expect(Buffer.compare(raw.file, pdf)).not.toBe(0);

    await service.readDocument(ownerA, doc.id, 'lab', 'application/pdf', pdf, {});
    const read = await service.getDocument(ownerA, primaryA, doc.id);
    expect(read.status).toBe('review');
    expect(read.data.values).toEqual([{ item: 'Colesterol total', value: '212', unit: 'mg/dL', reference: 'até 190', confirmed: false }]);

    const row = { item: 'Colesterol total', value: '212', unit: 'mg/dL', reference: 'até 190' };
    await expect(service.reviewDocument(ownerA, primaryA, doc.id, { values: [{ ...row, confirmed: false }] })).rejects.toThrow('confirmed');
    const saved = await service.reviewDocument(ownerA, primaryA, doc.id, { values: [{ ...row, confirmed: true }], labName: 'Fleury' });
    expect(saved.status).toBe('ready');

    const file = await service.getDocumentFile(ownerA, primaryA, doc.id);
    expect(file.file.equals(pdf)).toBe(true);
    expect(await service.listDocuments(strangerD, primaryA)).toEqual([]);
    await expect(service.getDocumentFile(viewerB, primaryA, doc.id)).rejects.toThrow('Document not found');
  });

  it('a failed reading marks the document failed without losing the file', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    reader.read = async () => { throw new Error('vision down'); };
    const img = Buffer.from('fake-jpeg');
    const doc = await service.uploadDocument(ownerA, primaryA, { kind: 'prescription', mime: 'image/jpeg', fileBase64: img.toString('base64'), read: true });
    await service.readDocument(ownerA, doc.id, 'prescription', 'image/jpeg', img, {});
    const after = await service.getDocument(ownerA, primaryA, doc.id);
    expect(after).toMatchObject({ status: 'failed', error: 'read_failed' });
    expect((await service.getDocumentFile(ownerA, primaryA, doc.id)).file.equals(img)).toBe(true);
  });

  it('the same file is stored once per profile and never read twice', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const pdf = Buffer.from('%PDF-1.4 same report uploaded twice');
    const upload = (profileId: string, read: boolean) =>
      service.uploadDocument(ownerA, profileId, { kind: read ? 'lab' : 'other', mime: 'application/pdf', fileBase64: pdf.toString('base64'), read });

    const first = await upload(primaryA, false);
    expect(first).toMatchObject({ status: 'archived' });
    expect(first.duplicate).toBeUndefined();
    // Asked again with reading: the archived copy is read in place, no second row.
    const reading = await upload(primaryA, true);
    expect(reading).toMatchObject({ id: first.id, kind: 'lab', status: 'processing' });
    const again = await upload(primaryA, true);
    expect(again).toMatchObject({ id: first.id, duplicate: true });
    // Another profile is another person: the same file is a new document there.
    const dependent = await upload(dependentId, false);
    expect(dependent.id).not.toBe(first.id);

    const rows = (await adminPool.query(`SELECT count(*)::int AS n FROM care_documents WHERE profile_id = $1 AND file_hmac IS NOT NULL AND id = $2`, [primaryA, first.id])).rows[0];
    expect(rows.n).toBe(1);
  });

  it('check constraints reject unknown kinds even without the API', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await expect(
      adminPool.query(`INSERT INTO care_records (user_id, profile_id, kind, data) VALUES ($1, $2, 'diagnosis', 'x')`, [ownerA, primaryA]),
    ).rejects.toThrow(/care_records_kind_check/);
  });
});
