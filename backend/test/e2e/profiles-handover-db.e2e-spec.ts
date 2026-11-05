import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { ConflictException, ForbiddenException, HttpException, NotFoundException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Pool } from 'pg';
import { randomUUID } from 'node:crypto';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from '../../src/database/schema';
import { DatabaseService } from '../../src/database/database.service';
import { ProfilesService } from '../../src/modules/profiles/profiles.service';
import { ProfileContextGuard } from '../../src/modules/profiles/profile-context';

// Preparation refuses non-local URLs and never loads a dotenv file.
const { prepareLocalDatabase } = require('../support/prepare-local-test-db.cjs');

/**
 * Hand-over at 18 (D3) through the real ProfilesService on a fresh local database, as the
 * runtime role without SUPERUSER or BYPASSRLS: one notice, code, claim, and no access left
 * for the former guardian.
 */
describe.skipIf(!process.env.TEST_DATABASE_URL)('Profile hand-over at 18 with real persistence (PREM-06, D3)', () => {
  let root: Pool;
  let admin: Pool;
  let appPool: Pool;
  let dbName: string;
  let service: ProfilesService;
  let guard: ProfileContextGuard;
  const email = { sendHandoverDueEmail: vi.fn().mockResolvedValue(undefined) };

  const guardian = randomUUID();
  const claimer = randomUUID();
  const [guardianPrimary, youngAdult, minor, claimerPrimary] = Array.from({ length: 4 }, () => randomUUID());
  const year = new Date().getUTCFullYear();
  let claimCode: string;

  const contextFor = (userId: string, profileId: string) =>
    ({
      // No @ProfileAccess metadata: a plain read with X-Profile-Id.
      getHandler: () => function handler() {},
      getClass: () => class Controller {},
      switchToHttp: () => ({
        getRequest: () => ({ user: { id: userId }, headers: { 'x-profile-id': profileId } }),
      }),
    }) as any;

  beforeAll(async () => {
    const rawUrl = process.env.TEST_DATABASE_URL!;
    const url = new URL(rawUrl);
    if (!['127.0.0.1', 'localhost', '::1', '[::1]'].includes(url.hostname)) throw new Error('Local database required.');
    root = new Pool({ connectionString: rawUrl, max: 1 });
    dbName = `handover_${randomUUID().replace(/-/g, '')}`;
    await root.query(`CREATE DATABASE "${dbName}"`);
    url.pathname = `/${dbName}`;
    await prepareLocalDatabase(url.toString());
    admin = new Pool({ connectionString: url.toString(), max: 2 });
    url.username = 'dualis_app';
    url.password = 'dualis_local_test';
    appPool = new Pool({ connectionString: url.toString(), max: 3 });
    const database = new DatabaseService(drizzle(appPool, { schema }), appPool);
    service = new ProfilesService(database, email as any);
    guard = new ProfileContextGuard(new Reflector(), database);

    for (const [id, name] of [
      [guardian, 'Ana Souza'],
      [claimer, 'Rafa Souza'],
    ]) {
      await admin.query(
        "INSERT INTO users (id, name, email, password_hash, gender) VALUES ($1, $2, $3, 'hash', 'unspecified')",
        [id, name, `${id}@handover.test`],
      );
    }
    await admin.query(
      `INSERT INTO profiles (id, account_owner_id, profile_type, name, date_of_birth) VALUES
        ($1, $5, 'primary', 'Ana Souza', '1980-03-03'),
        ($2, $5, 'dependent_minor', 'Rafa Souza', $7),
        ($3, $5, 'dependent_minor', 'Teo Souza', $8),
        ($4, $6, 'primary', 'Rafa Souza', $7)`,
      [guardianPrimary, youngAdult, minor, claimerPrimary, guardian, claimer, `${year - 19}-01-01`, `${year - 10}-01-01`],
    );
    await admin.query(
      `INSERT INTO legal_guardianships (guardian_user_id, dependent_profile_id, relationship_type, lgpd_consent_recorded_at)
       VALUES ($1, $2, 'parent', now()), ($1, $3, 'parent', now())`,
      [guardian, youngAdult, minor],
    );
  }, 60_000);

  afterAll(async () => {
    await appPool?.end().catch(() => {});
    await admin?.end().catch(() => {});
    if (root) {
      // pool.end() can resolve before the server has closed the backends; a FORCE
      // drop then kills a closing socket and pg raises it as an uncaught error.
      for (let i = 0; i < 50; i++) {
        const { rows } = await root.query(
          'SELECT count(*)::int AS n FROM pg_stat_activity WHERE datname = $1',
          [dbName],
        );
        if (rows[0].n === 0) break;
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
      await root.query(`DROP DATABASE IF EXISTS "${dbName}" WITH (FORCE)`);
      await root.end();
    }
  });

  it('shows the hand-over as due and emails the guardian once', async () => {
    const list = await service.getProfilesForUser(guardian);
    const byId = new Map(list.map((p) => [p.id, p]));
    expect(byId.get(youngAdult)).toMatchObject({ handoverStatus: 'due', handoverCodeExpiresAt: null });
    expect(byId.get(minor)).toMatchObject({ handoverStatus: 'none' });
    expect(email.sendHandoverDueEmail).toHaveBeenCalledTimes(1);
    expect(email.sendHandoverDueEmail).toHaveBeenCalledWith(`${guardian}@handover.test`, 'Ana Souza', 'Rafa');

    await service.getProfilesForUser(guardian);
    expect(email.sendHandoverDueEmail).toHaveBeenCalledTimes(1);
    const { rows } = await admin.query(
      'SELECT handover_notified_at FROM legal_guardianships WHERE dependent_profile_id = $1',
      [youngAdult],
    );
    expect(rows[0].handover_notified_at).toBeInstanceOf(Date);
  });

  it('issues a code only to the guardian and only for the aged-out dependent', async () => {
    await expect(service.createHandoverCode(guardian, minor)).rejects.toBeInstanceOf(ConflictException);
    await expect(service.createHandoverCode(claimer, youngAdult)).rejects.toBeInstanceOf(ForbiddenException);

    const first = await service.createHandoverCode(guardian, youngAdult);
    const second = await service.createHandoverCode(guardian, youngAdult);
    expect(second.claimCode).not.toBe(first.claimCode);
    claimCode = second.claimCode;

    const list = await service.getProfilesForUser(guardian);
    expect(list.find((p) => p.id === youngAdult)).toMatchObject({
      handoverStatus: 'code_active',
      handoverCodeExpiresAt: second.expiresAt.toISOString(),
    });
  });

  it('refuses the guardian and an unknown code', async () => {
    const byGuardian = await service.claimProfile(guardian, claimCode).catch((e) => e);
    expect(byGuardian).toBeInstanceOf(ForbiddenException);
    expect(byGuardian.getResponse()).toMatchObject({ code: 'CLAIM_BY_GUARDIAN' });

    const unknown = await service.claimProfile(claimer, 'ZZZZ999999').catch((e) => e);
    expect(unknown).toBeInstanceOf(NotFoundException);
    expect(unknown.getResponse()).toMatchObject({ code: 'CLAIM_INVALID_CODE' });
  });

  it('moves the profile to the young adult and leaves the former guardian without access', async () => {
    const claimed = await service.claimProfile(claimer, claimCode.toLowerCase());
    expect(claimed).toMatchObject({ id: youngAdult, ownership: 'own', profileType: 'primary', handoverStatus: 'none' });

    const claimerList = await service.getProfilesForUser(claimer);
    expect(claimerList.map((p) => [p.id, p.ownership])).toEqual([[youngAdult, 'own']]);

    const guardianList = await service.getProfilesForUser(guardian);
    expect(guardianList.some((p) => p.id === youngAdult)).toBe(false);
    await expect(guard.canActivate(contextFor(guardian, youngAdult))).rejects.toBeInstanceOf(ForbiddenException);
    await expect(guard.canActivate(contextFor(claimer, youngAdult))).resolves.toBe(true);

    const reuse = await service.claimProfile(claimer, claimCode).catch((e) => e);
    expect(reuse).toBeInstanceOf(HttpException);
    expect(reuse.getStatus()).toBe(404);
  });
});
