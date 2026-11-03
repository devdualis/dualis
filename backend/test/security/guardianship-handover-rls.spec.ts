import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool, PoolClient } from 'pg';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const MIGRATIONS_DIR = join(__dirname, '../../src/database/migrations');
const HANDOVER_MIGRATION = '0028_guardianship_consent_gaps.sql';
const APP_ROLE = 'dualis_handover_app';
const APP_PASSWORD = 'dualis_handover_app';
const HELPER_OWNER = 'dualis_helper_owner';
const SPEC = '[guardianship-handover-rls.spec.ts]';

/**
 * Wave 0 contract for PREM-06 (Phase 11.1, decision D3): at 18 a dependent profile is
 * handed over to the young adult's own account through a claim code. Ownership moves,
 * the guardianship is closed (kept for audit), grants on the profile are revoked and the
 * former guardian keeps no access. Also covers the legal basis backfill (A3) and the
 * relationship/legal basis CHECKs.
 *
 * Exercised through a LOGIN role without SUPERUSER or BYPASSRLS (like production).
 * Migrations are staged: everything before 0028, then legacy guardianships, then 0028 twice.
 *
 * Test names start with the tag of the 11.1-03 task whose SQL makes them pass
 * (03T1 claim columns, policies and function; 03T2 legal basis, relationship CHECK and
 * the recursion check). Cases run in order: the claim in case 8 is committed and the
 * cases after it build on it.
 */
describe('Security Regression: 0028 guardianship hand-over at 18 (PREM-06)', () => {
  let adminPool: Pool;
  let appPool: Pool;
  let baseUrl: string;
  let isolatedDb: string;
  let isDbAvailable = false;

  // Users
  const guardianG = '3a3a3a3a-0000-4000-8000-00000000000a';
  const granteeV = '3b3b3b3b-0000-4000-8000-00000000000b'; // ACCEPTED VIEW_ONLY {habits} on Y
  const claimerN = '3c3c3c3c-0000-4000-8000-00000000000c'; // primary profile without data
  const claimerP = '3d3d3d3d-0000-4000-8000-00000000000d'; // primary profile with one water row
  const strangerS = '3e3e3e3e-0000-4000-8000-00000000000e';
  const legacyGuardianL = '3f3f3f3f-0000-4000-8000-00000000000f';
  const guardianG2 = '3a3a3a3a-0000-4000-8000-0000000000a2';
  const granteeV2 = '3b3b3b3b-0000-4000-8000-0000000000b2';
  const claimerN2 = '3c3c3c3c-0000-4000-8000-0000000000c2';

  // Profiles
  const primaryG = '4a4a4a4a-0000-4000-8000-0000000000a1';
  const minorM = '4a4a4a4a-0000-4000-8000-0000000000a2'; // 17 years old
  const youngAdultY = '4a4a4a4a-0000-4000-8000-0000000000a3'; // 18 years and 1 day
  const adultZ = '4a4a4a4a-0000-4000-8000-0000000000a4'; // G's adult dependent without guardianship (CHECK cases)
  const primaryN = '4c4c4c4c-0000-4000-8000-0000000000c1';
  const primaryP = '4d4d4d4d-0000-4000-8000-0000000000d1';
  const primaryL = '4f4f4f4f-0000-4000-8000-0000000000f1';
  const legacyAdult = '4f4f4f4f-0000-4000-8000-0000000000f2'; // curator, before 0028
  const legacyMinor = '4f4f4f4f-0000-4000-8000-0000000000f3'; // parent, before 0028
  const primaryG2 = '4a4a4a4a-0000-4000-8000-0000000000b1';
  const youngAdultY2 = '4a4a4a4a-0000-4000-8000-0000000000b2';
  const primaryN2 = '4c4c4c4c-0000-4000-8000-0000000000c2';

  // Guardianships, grants and data rows
  const legacyAdultGuardianship = '5f5f5f5f-0000-4000-8000-000000000001';
  const legacyMinorGuardianship = '5f5f5f5f-0000-4000-8000-000000000002';
  const guardianshipM = '5a5a5a5a-0000-4000-8000-000000000001';
  const guardianshipY = '5a5a5a5a-0000-4000-8000-000000000002';
  const guardianshipY2 = '5a5a5a5a-0000-4000-8000-000000000003';
  const grantV = '6b6b6b6b-0000-4000-8000-000000000001';
  const grantV2 = '6b6b6b6b-0000-4000-8000-000000000002';
  const waterY = '7a7a7a7a-0000-4000-8000-000000000001';
  const entryY = '7a7a7a7a-0000-4000-8000-000000000002';
  const waterP = '7a7a7a7a-0000-4000-8000-000000000003';

  // Claim codes: 10 characters from the invite alphabet (no 0, 1, I, O).
  const CODE_Y = 'HNDY234567';
  const CODE_M = 'HNDM234567';
  const CODE_EXPIRED = 'HNDX234567';
  const CODE_Y2 = 'HNDZ234567';
  const CODE_UNKNOWN = 'ZZZZ999999';

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
    isolatedDb = `${isolatedUrl.pathname.slice(1) || 'postgres'}_guardianship_handover_rls`.replace(/"/g, '');
    isolatedUrl.pathname = `/${isolatedDb}`;

    const admin = new Pool({ connectionString: rawTestUrl, max: 1, connectionTimeoutMillis: 3000 });
    try {
      await admin.query(`DROP DATABASE IF EXISTS "${isolatedDb}" WITH (FORCE)`);
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

    // Stage 2: legacy guardianships recorded under the Art. 14 consent text, no legal basis column yet.
    await adminPool.query(
      `INSERT INTO users (id, name, email, password_hash, gender) VALUES ($1, 'Lia', 'handover-l@dualis.test', 'hash', 'feminino')`,
      [legacyGuardianL],
    );
    await adminPool.query(
      `INSERT INTO profiles (id, account_owner_id, profile_type, name, date_of_birth) VALUES
       ($1, $4, 'primary', 'Lia', '1970-01-01'),
       ($2, $4, 'dependent_adult', 'Rita', '1990-06-01'),
       ($3, $4, 'dependent_minor', 'Leo', current_date - interval '8 years')`,
      [primaryL, legacyAdult, legacyMinor, legacyGuardianL],
    );
    await adminPool.query(
      `INSERT INTO legal_guardianships (id, guardian_user_id, dependent_profile_id, relationship_type, lgpd_consent_recorded_at) VALUES
       ($1, $3, $4, 'curator', now() - interval '30 days'),
       ($2, $3, $5, 'parent', now() - interval '30 days')`,
      [legacyAdultGuardianship, legacyMinorGuardianship, legacyGuardianL, legacyAdult, legacyMinor],
    );

    // Stage 3: 0028 twice (the file must exist: ENOENT here is the Wave 0 red state).
    await adminPool.query(readMigration(HANDOVER_MIGRATION));
    await adminPool.query(readMigration(HANDOVER_MIGRATION));

    await adminPool.query(`
      GRANT USAGE ON SCHEMA public TO ${APP_ROLE};
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${APP_ROLE};
    `);

    // Fixture created after 0028.
    await adminPool.query(
      `INSERT INTO users (id, name, email, password_hash, gender) VALUES
       ($1, 'Gil', 'handover-g@dualis.test', 'hash', 'masculino'),
       ($2, 'Vera', 'handover-v@dualis.test', 'hash', 'feminino'),
       ($3, 'Nina', 'handover-n@dualis.test', 'hash', 'feminino'),
       ($4, 'Paulo', 'handover-p@dualis.test', 'hash', 'masculino'),
       ($5, 'Sara', 'handover-s@dualis.test', 'hash', 'feminino'),
       ($6, 'Gil Dois', 'handover-g2@dualis.test', 'hash', 'masculino'),
       ($7, 'Vera Dois', 'handover-v2@dualis.test', 'hash', 'feminino'),
       ($8, 'Nina Dois', 'handover-n2@dualis.test', 'hash', 'feminino')`,
      [guardianG, granteeV, claimerN, claimerP, strangerS, guardianG2, granteeV2, claimerN2],
    );
    await adminPool.query(
      `INSERT INTO profiles (id, account_owner_id, profile_type, name, date_of_birth) VALUES
       ($1, $5, 'primary', 'Gil', '1980-03-03'),
       ($2, $5, 'dependent_minor', 'Mia', current_date - interval '17 years'),
       ($3, $5, 'dependent_adult', 'Yara', current_date - interval '18 years' - interval '1 day'),
       ($4, $5, 'dependent_adult', 'Zeca', '1960-01-01'),
       ($6, $7, 'primary', 'Nina', NULL),
       ($8, $9, 'primary', 'Paulo', NULL),
       ($10, $13, 'primary', 'Gil Dois', '1979-05-05'),
       ($11, $13, 'dependent_adult', 'Yuri', current_date - interval '18 years' - interval '2 days'),
       ($12, $14, 'primary', 'Nina Dois', NULL)`,
      [
        primaryG, minorM, youngAdultY, adultZ, guardianG,
        primaryN, claimerN, primaryP, claimerP,
        primaryG2, youngAdultY2, primaryN2, guardianG2, claimerN2,
      ],
    );
    await adminPool.query(
      `INSERT INTO legal_guardianships (id, guardian_user_id, dependent_profile_id, relationship_type, lgpd_consent_recorded_at) VALUES
       ($1, $4, $5, 'parent', now() - interval '1 year'),
       ($2, $4, $6, 'parent', now() - interval '1 year'),
       ($3, $7, $8, 'parent', now() - interval '1 year')`,
      [guardianshipM, guardianshipY, guardianshipY2, guardianG, minorM, youngAdultY, guardianG2, youngAdultY2],
    );
    // Second fixture's code is opened up front; the recursion case claims it last.
    await adminPool.query(
      `UPDATE legal_guardianships SET handover_code = $1, handover_code_expires_at = now() + interval '72 hours' WHERE id = $2`,
      [CODE_Y2, guardianshipY2],
    );
    await adminPool.query(
      `INSERT INTO shared_access_grants
         (id, granter_user_id, target_profile_id, grantee_user_id, access_level, invite_code, status, expires_at, accepted_at)
       VALUES ($1, $3, $4, $5, 'VIEW_ONLY', 'HOGRANTV01', 'ACCEPTED', now() + interval '72 hours', now()),
              ($2, $6, $7, $8, 'VIEW_ONLY', 'HOGRANTV02', 'ACCEPTED', now() + interval '72 hours', now())`,
      [grantV, grantV2, guardianG, youngAdultY, granteeV, guardianG2, youngAdultY2, granteeV2],
    );
    await adminPool.query(
      `INSERT INTO water_intake_logs (id, user_id, profile_id, amount_ml) VALUES
       ($1, $3, $4, 250),
       ($2, $5, $6, 300)`,
      [waterY, waterP, guardianG, youngAdultY, claimerP, primaryP],
    );
    await adminPool.query(
      `INSERT INTO journal_entries (id, user_id, profile_id, recorded_at, mood, area, client_id)
       VALUES ($1, $2, $3, now() - interval '1 day', 'bem', 'physical', 'handover-y-1')`,
      [entryY, guardianG, youngAdultY],
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
      await admin.query(`DROP DATABASE IF EXISTS "${isolatedDb}" WITH (FORCE)`).catch(() => {});
      await admin.end().catch(() => {});
    }
  });

  /**
   * Runs fn through the NOSUPERUSER NOBYPASSRLS app role as userId. Rolls back unless
   * commit is true (and fn succeeded).
   */
  async function asApp<T>(userId: string, fn: (client: PoolClient) => Promise<T>, commit = false): Promise<T> {
    const client = await appPool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userId]);
      const result = await fn(client);
      if (commit) await client.query('COMMIT');
      return result;
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

  const claim = (c: PoolClient, code: string) =>
    c.query(`SELECT claim_dependent_profile($1) AS profile_id`, [code]).then((r) => r.rows[0].profile_id as string | null);
  const setCode = (c: PoolClient, guardianshipId: string, code: string) =>
    c.query(
      `UPDATE legal_guardianships SET handover_code = $1, handover_code_expires_at = now() + interval '72 hours' WHERE id = $2`,
      [code, guardianshipId],
    );
  const countWhere = async (c: PoolClient, table: string, column: string, value: string) =>
    (await c.query(`SELECT count(*)::int AS n FROM ${table} WHERE ${column} = $1`, [value])).rows[0].n as number;
  const ownerOf = async (profileId: string) =>
    (await adminPool.query(`SELECT account_owner_id FROM profiles WHERE id = $1`, [profileId])).rows[0]?.account_owner_id as string | undefined;

  // ---------------------------------------------------------------- 03T2: legal basis

  it('03T2: legacy guardianships carry lgpd_legal_basis lgpd_art_14 after 0028 (truthful backfill)', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const rows = await adminPool.query(
      `SELECT id, relationship_type, lgpd_legal_basis FROM legal_guardianships WHERE id = ANY($1::uuid[]) ORDER BY relationship_type`,
      [[legacyAdultGuardianship, legacyMinorGuardianship]],
    );
    expect(rows.rows).toEqual([
      { id: legacyAdultGuardianship, relationship_type: 'curator', lgpd_legal_basis: 'lgpd_art_14' },
      { id: legacyMinorGuardianship, relationship_type: 'parent', lgpd_legal_basis: 'lgpd_art_14' },
    ]);
  });

  it('03T2: CHECKs reject unknown relationship types and legal bases (23514); supported_decision is accepted', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const insertGuardianship = (c: PoolClient, relationship: string, basis: string) =>
      c.query(
        `INSERT INTO legal_guardianships (guardian_user_id, dependent_profile_id, relationship_type, lgpd_consent_recorded_at, lgpd_legal_basis)
         VALUES ($1, $2, $3, now(), $4)`,
        [guardianG, adultZ, relationship, basis],
      );
    await asApp(guardianG, async (c) => {
      await expectSqlError(insertGuardianship(c, 'boss', 'lgpd_art_11_i'), '23514');
    });
    await asApp(guardianG, async (c) => {
      expect((await insertGuardianship(c, 'supported_decision', 'lgpd_art_11_i')).rowCount).toBe(1);
    });
    await asApp(guardianG, async (c) => {
      await expectSqlError(insertGuardianship(c, 'curator', 'other'), '23514');
    });
  });

  // ---------------------------------------------------------------- 03T1: claim

  it('03T1: the guardian opens a 72-hour claim code on the young adult guardianship', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const updated = await asApp(guardianG, (c) => setCode(c, guardianshipY, CODE_Y), true);
    expect(updated.rowCount).toBe(1);
    const row = await adminPool.query(
      `SELECT handover_code, handover_code_expires_at > now() + interval '71 hours' AS fresh, closed_at
       FROM legal_guardianships WHERE id = $1`,
      [guardianshipY],
    );
    expect(row.rows[0]).toEqual({ handover_code: CODE_Y, fresh: true, closed_at: null });
  });

  it('03T1: the guardian cannot claim (CLAIM_BY_GUARDIAN)', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(guardianG, async (c) => {
      await expectSqlError(claim(c, CODE_Y), 'P0001', /CLAIM_BY_GUARDIAN/);
    });
    expect(await ownerOf(youngAdultY)).toBe(guardianG);
  });

  it('03T1: an under-18 profile cannot be claimed (CLAIM_NOT_ADULT)', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const updated = await asApp(guardianG, (c) => setCode(c, guardianshipM, CODE_M), true);
    expect(updated.rowCount).toBe(1);
    await asApp(claimerN, async (c) => {
      await expectSqlError(claim(c, CODE_M), 'P0001', /CLAIM_NOT_ADULT/);
    });
    expect(await ownerOf(minorM)).toBe(guardianG);
  });

  it('03T1: unknown and expired codes return NULL', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await adminPool.query(
      `UPDATE legal_guardianships SET handover_code = $1, handover_code_expires_at = now() - interval '1 hour' WHERE id = $2`,
      [CODE_EXPIRED, legacyAdultGuardianship],
    );
    await asApp(claimerN, async (c) => {
      expect(await claim(c, CODE_UNKNOWN)).toBeNull();
      expect(await claim(c, CODE_EXPIRED)).toBeNull();
    });
    expect(await ownerOf(legacyAdult)).toBe(legacyGuardianL);
  });

  it('03T1: an account whose primary profile has data cannot claim (CLAIM_ACCOUNT_HAS_DATA) and nothing changes', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(claimerP, async (c) => {
      await expectSqlError(claim(c, CODE_Y), 'P0001', /CLAIM_ACCOUNT_HAS_DATA/);
    });
    expect(await ownerOf(youngAdultY)).toBe(guardianG);
    expect(await ownerOf(primaryP)).toBe(claimerP);
    const guardianship = await adminPool.query(`SELECT closed_at FROM legal_guardianships WHERE id = $1`, [guardianshipY]);
    expect(guardianship.rows[0].closed_at).toBeNull();
  });

  it('03T1: a valid claim moves ownership, replaces the empty primary, closes the guardianship and revokes grants', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    // Lowercase and padded input is normalized like invite codes.
    const claimed = await asApp(claimerN, (c) => claim(c, `  ${CODE_Y.toLowerCase()} `), true);
    expect(claimed).toBe(youngAdultY);

    const profile = await adminPool.query(`SELECT account_owner_id, profile_type FROM profiles WHERE id = $1`, [youngAdultY]);
    expect(profile.rows[0]).toEqual({ account_owner_id: claimerN, profile_type: 'primary' });
    const formerPrimary = await adminPool.query(`SELECT count(*)::int AS n FROM profiles WHERE id = $1`, [primaryN]);
    expect(formerPrimary.rows[0].n).toBe(0);

    const guardianship = await adminPool.query(
      `SELECT closed_at IS NOT NULL AS closed, closed_reason, handed_over_to_user_id, guardian_user_id
       FROM legal_guardianships WHERE id = $1`,
      [guardianshipY],
    );
    expect(guardianship.rows[0]).toEqual({
      closed: true,
      closed_reason: 'handed_over',
      handed_over_to_user_id: claimerN,
      guardian_user_id: guardianG,
    });

    const grant = await adminPool.query(`SELECT status, revoked_at IS NOT NULL AS revoked FROM shared_access_grants WHERE id = $1`, [grantV]);
    expect(grant.rows[0]).toEqual({ status: 'REVOKED', revoked: true });
  });

  it('03T1: after the claim the former guardian and the grantee read nothing of the profile; the new owner reads its data', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    for (const outsider of [guardianG, granteeV]) {
      await asApp(outsider, async (c) => {
        expect(await countWhere(c, 'profiles', 'id', youngAdultY)).toBe(0);
        expect(await countWhere(c, 'water_intake_logs', 'profile_id', youngAdultY)).toBe(0);
        expect(await countWhere(c, 'journal_entries', 'profile_id', youngAdultY)).toBe(0);
      });
    }
    await asApp(claimerN, async (c) => {
      expect(await countWhere(c, 'profiles', 'id', youngAdultY)).toBe(1);
      expect(await countWhere(c, 'water_intake_logs', 'profile_id', youngAdultY)).toBe(1);
      expect(await countWhere(c, 'journal_entries', 'profile_id', youngAdultY)).toBe(1);
    });
  });

  it('03T1: a used code cannot be claimed again', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(strangerS, async (c) => {
      expect(await claim(c, CODE_Y)).toBeNull();
    });
    expect(await ownerOf(youngAdultY)).toBe(claimerN);
  });

  it('03T1: without the claim path nobody can move a profile to another owner', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const reassign = (c: PoolClient, newOwner: string) =>
      c.query(`UPDATE profiles SET account_owner_id = $1 WHERE id = $2`, [newOwner, minorM]);
    // The stranger sees no row to update, or is rejected outright.
    await asApp(strangerS, async (c) => {
      const outcome = await reassign(c, strangerS).then(
        (r) => ({ rowCount: r.rowCount, code: null as string | null }),
        (e: { code?: string }) => ({ rowCount: 0, code: e.code ?? null }),
      );
      expect(outcome.rowCount).toBe(0);
      expect([null, '42501']).toContain(outcome.code);
    });
    // The guardian owns the row but ownership is immutable outside a claim.
    await asApp(guardianG, async (c) => {
      const outcome = await reassign(c, strangerS).then(
        (r) => ({ rowCount: r.rowCount, code: null as string | null }),
        (e: { code?: string }) => ({ rowCount: 0, code: e.code ?? null }),
      );
      expect(outcome.rowCount).toBe(0);
      expect([null, '42501']).toContain(outcome.code);
    });
    expect(await ownerOf(minorM)).toBe(guardianG);
  });

  it('03T1: a live code set by hand with set_config does not let a session skip claim_dependent_profile', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    // CODE_M (opened on the 17-year-old in an earlier case) is still live and unexpired.
    const attempt = (p: Promise<{ rowCount: number | null }>) =>
      p.then(
        (r) => ({ rowCount: r.rowCount, code: null as string | null }),
        (e: { code?: string }) => ({ rowCount: 0, code: e.code ?? null }),
      );
    for (const actor of [strangerS, claimerN]) {
      await asApp(actor, async (c) => {
        await c.query(`SELECT set_config('app.claiming_code', $1, true)`, [CODE_M]);
        expect(await countWhere(c, 'profiles', 'id', minorM)).toBe(0);
        expect(await countWhere(c, 'legal_guardianships', 'id', guardianshipM)).toBe(0);
        const moved = await attempt(
          c.query(`UPDATE profiles SET account_owner_id = $1, profile_type = 'primary' WHERE id = $2`, [actor, minorM]),
        );
        expect(moved.rowCount).toBe(0);
        expect([null, '42501']).toContain(moved.code);
      });
      await asApp(actor, async (c) => {
        await c.query(`SELECT set_config('app.claiming_code', $1, true)`, [CODE_M]);
        const closed = await attempt(
          c.query(
            `UPDATE legal_guardianships SET closed_at = now(), closed_reason = 'handed_over', handed_over_to_user_id = $1 WHERE id = $2`,
            [actor, guardianshipM],
          ),
        );
        expect(closed.rowCount).toBe(0);
        expect([null, '42501']).toContain(closed.code);
      });
    }
    expect(await ownerOf(minorM)).toBe(guardianG);
    const guardianship = await adminPool.query(`SELECT closed_at FROM legal_guardianships WHERE id = $1`, [guardianshipM]);
    expect(guardianship.rows[0].closed_at).toBeNull();
  });

  it('03T1: the former guardian cannot delete the closed guardianship (audit trail)', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await asApp(guardianG, async (c) => {
      expect(await countWhere(c, 'legal_guardianships', 'id', guardianshipY)).toBe(1);
      const deleted = await c.query(`DELETE FROM legal_guardianships WHERE id = $1`, [guardianshipY]);
      expect(deleted.rowCount).toBe(0);
    });
    const kept = await adminPool.query(`SELECT count(*)::int AS n FROM legal_guardianships WHERE id = $1`, [guardianshipY]);
    expect(kept.rows[0].n).toBe(1);
  });

  it('03T1: re-running 0028 after a claim keeps the guardianship closed and the new owner in place', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    await adminPool.query(readMigration(HANDOVER_MIGRATION));
    const profile = await adminPool.query(`SELECT account_owner_id, profile_type FROM profiles WHERE id = $1`, [youngAdultY]);
    expect(profile.rows[0]).toEqual({ account_owner_id: claimerN, profile_type: 'primary' });
    const guardianship = await adminPool.query(
      `SELECT closed_at IS NOT NULL AS closed, closed_reason, handed_over_to_user_id FROM legal_guardianships WHERE id = $1`,
      [guardianshipY],
    );
    expect(guardianship.rows[0]).toEqual({ closed: true, closed_reason: 'handed_over', handed_over_to_user_id: claimerN });
  });

  // ---------------------------------------------------------------- 03T2: recursion

  // Runs LAST: it changes function owners for the rest of the file.
  it('03T2: the claim and the grantee profile listing have no recursion (42P17) when SECURITY DEFINER helpers are owned by a NOSUPERUSER NOBYPASSRLS role', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();

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
    expect(definers.rows.map((r) => r.proname)).toEqual(
      expect.arrayContaining(['claim_dependent_profile', 'accept_shared_access_invite', 'app_has_profile_grant', 'app_owns_profile']),
    );
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

    const noRecursion = (err: { code?: string; message?: string }) => {
      expect(err.code, `infinite recursion in policy: ${err.message}`).not.toBe('42P17');
      throw err;
    };

    // Before the claim the grantee still lists the shared profile (profiles_grantee_select path).
    const listedBefore = await asApp(granteeV2, (c) => countWhere(c, 'profiles', 'id', youngAdultY2)).catch(noRecursion);
    expect(listedBefore).toBe(1);

    const claimed = await asApp(claimerN2, (c) => claim(c, CODE_Y2), true).catch(noRecursion);
    expect(claimed).toBe(youngAdultY2);

    const listedAfter = await asApp(granteeV2, (c) => c.query(`SELECT id FROM profiles`)).catch(noRecursion);
    expect(listedAfter.rows).toEqual([]);
    const guardianView = await asApp(guardianG2, (c) => countWhere(c, 'profiles', 'id', youngAdultY2)).catch(noRecursion);
    expect(guardianView).toBe(0);

    const grant = await adminPool.query(`SELECT status FROM shared_access_grants WHERE id = $1`, [grantV2]);
    expect(grant.rows[0].status).toBe('REVOKED');
    expect(await ownerOf(youngAdultY2)).toBe(claimerN2);
    expect(await ownerOf(primaryN2)).toBeUndefined();
  });
});
