import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { Pool, PoolClient } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { randomBytes, randomUUID } from 'node:crypto';
import * as schema from '../../src/database/schema';
import { DatabaseService } from '../../src/database/database.service';
import { EncryptionService } from '../../src/common/encryption/encryption.service';
import {
  AI_CONSENT_PURPOSE,
  AI_CONSENT_REQUIRED,
  AI_CONSENT_VERSION_MISMATCH,
  AI_PROCESSING_CONSENT_VERSION,
  AI_PROFILE_NOT_ALLOWED,
  AiConsentService,
} from '../../src/modules/consents/ai-consent.service';
import { AiConsentController } from '../../src/modules/consents/ai-consent.controller';
import { SHARE_CATEGORIES } from '../../src/database/schema/shared-access-grants.schema';
import { ProfileContext } from '../../src/modules/profiles/profile-context';
import { dropTestDatabase } from '../support/drop-test-database';

// Preparation refuses non-local URLs and never loads a dotenv file.
const { prepareLocalDatabase } = require('../support/prepare-local-test-db.cjs');

const MIGRATION = join(__dirname, '../../src/database/migrations/0030_ai_processing_consents.sql');
const CLIENT_IP = '203.0.113.7';

const codeOf = (error: any) => error?.getResponse?.()?.code;

/**
 * 0030 user_ai_consents under RLS, through the real AiConsentController and AiConsentService
 * connected as the runtime role (no SUPERUSER, no BYPASSRLS), plus direct SQL checks.
 */
describe.skipIf(!process.env.TEST_DATABASE_URL)('AI-processing consents: real runtime-role RLS and history', () => {
  let root: Pool;
  let admin: Pool;
  let appPool: Pool;
  let service: AiConsentService;
  let controller: AiConsentController;
  let dbName: string;
  const [userA, userB] = Array.from({ length: 2 }, () => randomUUID());

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

  const req = (userId: string) => ({
    user: { id: userId },
    ip: CLIENT_IP,
    headers: { 'user-agent': `DualisCheckUp/17 ${'x'.repeat(300)}` },
  });

  const rowsOf = async (userId: string) =>
    (await admin.query('SELECT * FROM user_ai_consents WHERE user_id = $1 ORDER BY granted_at, id', [userId])).rows;

  const profile = (accessLevel: ProfileContext['accessLevel']): ProfileContext => ({
    profileId: randomUUID(),
    accessLevel,
    readableCategories: [...SHARE_CATEGORIES],
    writableCategories: accessLevel === 'VIEW_ONLY' ? [] : [...SHARE_CATEGORIES],
  });

  beforeAll(async () => {
    const rawUrl = process.env.TEST_DATABASE_URL!;
    const url = new URL(rawUrl);
    if (!['127.0.0.1', 'localhost', '::1', '[::1]'].includes(url.hostname)) throw new Error('Local database required.');
    root = new Pool({ connectionString: rawUrl, max: 1 });
    dbName = `ai_consents_${randomUUID().replace(/-/g, '')}`;
    await root.query(`CREATE DATABASE "${dbName}"`);
    url.pathname = `/${dbName}`;
    await prepareLocalDatabase(url.toString());
    admin = new Pool({ connectionString: url.toString(), max: 2 });
    // The test preparation grants DELETE on every table; take it back so the checks below
    // see only what 0030 grants (no DELETE: rows leave through the users cascade).
    await admin.query('REVOKE DELETE ON user_ai_consents FROM dualis_app');
    url.username = 'dualis_app';
    url.password = 'dualis_local_test';
    appPool = new Pool({ connectionString: url.toString(), max: 3 });
    const encryption = new EncryptionService({ get: () => randomBytes(32).toString('hex') } as any);
    service = new AiConsentService(new DatabaseService(drizzle(appPool, { schema }), appPool), encryption);
    controller = new AiConsentController(service);

    for (const id of [userA, userB]) {
      await admin.query(
        "INSERT INTO users (id, name, email, password_hash, gender) VALUES ($1, 'Pessoa', $2, 'hash', 'unspecified')",
        [id, `${id}@ai-consents.test`],
      );
    }
  });

  afterAll(async () => {
    await appPool?.end().catch(() => {});
    await admin?.end().catch(() => {});
    if (root) {
      await dropTestDatabase(root, dbName).catch(() => {});
      await root.end();
    }
  });

  it('(a) replaying 0030 succeeds and grants the runtime role no DELETE', async () => {
    await admin.query(readFileSync(MIGRATION, 'utf8'));
    const privileges = await admin.query(
      `SELECT privilege, has_table_privilege('dualis_app', 'user_ai_consents', privilege) AS ok
         FROM unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE']) AS privilege`,
    );
    expect(Object.fromEntries(privileges.rows.map((r) => [r.privilege, r.ok]))).toEqual({
      SELECT: true,
      INSERT: true,
      UPDATE: true,
      DELETE: false,
    });
  });

  it('(b) table has ENABLE + FORCE RLS; runtime role has no bypass', async () => {
    const role = await appPool.query('SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user');
    expect(role.rows[0]).toEqual({ rolsuper: false, rolbypassrls: false });
    const table = await admin.query(
      "SELECT relrowsecurity, relforcerowsecurity FROM pg_class WHERE oid = 'user_ai_consents'::regclass",
    );
    expect(table.rows[0]).toEqual({ relrowsecurity: true, relforcerowsecurity: true });
  });

  it('(c) user A grants through the controller; wrong version is 409; a second grant keeps one active row', async () => {
    const before = await controller.status(req(userA));
    expect(before).toEqual({
      purpose: AI_CONSENT_PURPOSE,
      granted: false,
      version: null,
      currentVersion: AI_PROCESSING_CONSENT_VERSION,
      grantedAt: null,
    });

    const wrong = await controller.grant(req(userA), { version: '2025.9' }).catch((e) => e);
    expect(wrong.getStatus()).toBe(409);
    expect(codeOf(wrong)).toBe(AI_CONSENT_VERSION_MISMATCH);
    expect(await rowsOf(userA)).toHaveLength(0);

    const granted = await controller.grant(req(userA), { version: AI_PROCESSING_CONSENT_VERSION });
    expect(granted).toMatchObject({ granted: true, version: AI_PROCESSING_CONSENT_VERSION });
    expect(new Date(granted.grantedAt!).getTime()).not.toBeNaN();

    const [row] = await rowsOf(userA);
    expect(row.purpose).toBe(AI_CONSENT_PURPOSE);
    expect(row.ip_address_hash).toMatch(/^[0-9a-f]{64}$/);
    expect(row.ip_address_hash).not.toContain(CLIENT_IP);
    expect(row.user_agent).toHaveLength(255);
    expect(row.revoked_at).toBeNull();

    const again = await controller.grant(req(userA), { version: AI_PROCESSING_CONSENT_VERSION });
    expect(again.grantedAt).toBe(granted.grantedAt);
    const active = (await rowsOf(userA)).filter((r) => r.revoked_at === null);
    expect(active).toHaveLength(1);
    expect(await controller.status(req(userA))).toMatchObject({ granted: true });
  });

  it('(d) user B cannot see, insert for or update user A', async () => {
    expect(await controller.status(req(userB))).toMatchObject({ granted: false, version: null });

    const seen = await asUser(userB, (c) => c.query('SELECT * FROM user_ai_consents WHERE user_id = $1', [userA]));
    expect(seen.rowCount).toBe(0);
    const all = await asUser(userB, (c) => c.query('SELECT * FROM user_ai_consents'));
    expect(all.rowCount).toBe(0);

    await expect(
      asUser(userB, (c) =>
        c.query(
          `INSERT INTO user_ai_consents (user_id, purpose, consent_version, ip_address_hash)
           VALUES ($1, $2, $3, repeat('0', 64))`,
          [userA, AI_CONSENT_PURPOSE, AI_PROCESSING_CONSENT_VERSION],
        ),
      ),
    ).rejects.toThrow(/row-level security/);

    const updated = await asUser(userB, (c) =>
      c.query('UPDATE user_ai_consents SET revoked_at = now() WHERE user_id = $1', [userA]),
    );
    expect(updated.rowCount).toBe(0);
    expect((await rowsOf(userA)).filter((r) => r.revoked_at === null)).toHaveLength(1);

    // B's own revoke never reaches A's row either.
    await controller.revoke(req(userB));
    expect(await controller.status(req(userA))).toMatchObject({ granted: true });
  });

  it('(e) revoke keeps the row as history; a new grant adds a second row', async () => {
    const revoked = await controller.revoke(req(userA));
    expect(revoked).toMatchObject({ granted: false, version: null });
    expect(await controller.status(req(userA))).toMatchObject({ granted: false });

    const history = await rowsOf(userA);
    expect(history).toHaveLength(1);
    expect(history[0].revoked_at).not.toBeNull();

    await controller.grant(req(userA), { version: AI_PROCESSING_CONSENT_VERSION });
    const rows = await rowsOf(userA);
    expect(rows).toHaveLength(2);
    expect(rows.filter((r) => r.revoked_at === null)).toHaveLength(1);
  });

  it('(f) assertAllowed: OWNER with consent passes; after revoke AI_CONSENT_REQUIRED; shared profile AI_PROFILE_NOT_ALLOWED', async () => {
    await expect(service.assertAllowed(userA, profile('OWNER'))).resolves.toBeUndefined();

    const shared = await service.assertAllowed(userA, profile('CO_MANAGE')).catch((e) => e);
    expect(shared.getStatus()).toBe(403);
    expect(codeOf(shared)).toBe(AI_PROFILE_NOT_ALLOWED);

    await controller.revoke(req(userA));
    const missing = await service.assertAllowed(userA, profile('OWNER')).catch((e) => e);
    expect(missing.getStatus()).toBe(403);
    expect(codeOf(missing)).toBe(AI_CONSENT_REQUIRED);
  });

  it('(f2) a grant that races another one returns the row that won, never a unique violation', async () => {
    // The other request's insert is in flight (not committed): this grant sees no active
    // row, then its insert waits on the partial unique index until the other one commits.
    const other = await appPool.connect();
    try {
      await other.query('BEGIN');
      await other.query("SELECT set_config('app.current_user_id', $1, true)", [userB]);
      const won = await other.query(
        `INSERT INTO user_ai_consents (user_id, purpose, consent_version, ip_address_hash)
         VALUES ($1, $2, $3, repeat('0', 64)) RETURNING granted_at`,
        [userB, AI_CONSENT_PURPOSE, AI_PROCESSING_CONSENT_VERSION],
      );
      const pending = controller.grant(req(userB), { version: AI_PROCESSING_CONSENT_VERSION });
      await new Promise((resolve) => setTimeout(resolve, 300));
      await other.query('COMMIT');

      const result = await pending;
      expect(result).toMatchObject({ granted: true, version: AI_PROCESSING_CONSENT_VERSION });
      expect(result.grantedAt).toBe(new Date(won.rows[0].granted_at).toISOString());
    } finally {
      other.release();
    }
    expect((await rowsOf(userB)).filter((r) => r.revoked_at === null)).toHaveLength(1);

    // Many at once (double tap, retries): all succeed, one active row.
    const results = await Promise.all(
      Array.from({ length: 4 }, () => controller.grant(req(userB), { version: AI_PROCESSING_CONSENT_VERSION })),
    );
    for (const r of results) expect(r).toMatchObject({ granted: true });
    expect((await rowsOf(userB)).filter((r) => r.revoked_at === null)).toHaveLength(1);
  });

  it('(g) deleting user A removes their consent rows (cascade)', async () => {
    await controller.grant(req(userA), { version: AI_PROCESSING_CONSENT_VERSION });
    expect((await rowsOf(userA)).length).toBeGreaterThan(0);
    await asUser(userA, (c) => c.query('DELETE FROM users WHERE id = $1', [userA]));
    const left = await admin.query('SELECT count(*)::int AS n FROM user_ai_consents WHERE user_id = $1', [userA]);
    expect(left.rows[0].n).toBe(0);
  });
});
