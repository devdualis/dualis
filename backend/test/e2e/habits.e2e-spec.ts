import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { createHash } from 'node:crypto';
import { Test } from '@nestjs/testing';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../../src/app.module';
import { DATABASE_POOL } from '../../src/database/database.service';
import { AuthService } from '../../src/modules/auth/auth.service';
import { habitsDatabase } from '../support/habits-database';

describe.skipIf(!process.env.TEST_DATABASE_URL)('Daily habits HTTP with real local persistence and profile guards', () => {
  let app: NestFastifyApplication;
  let f: Awaited<ReturnType<typeof habitsDatabase>>;
  let jwt: JwtService;
  let auth: AuthService;
  const today = new Date().toISOString().slice(0, 10);
  const dayAgo = (n: number) => new Date(Date.now() - n * 86_400_000).toISOString().slice(0, 10);
  const headers = (userId: string, profileId?: string) => ({
    authorization: `Bearer ${jwt.sign({ sub: userId, sv: createHash('sha256').update('hash').digest('base64url').slice(0, 16), type: 'access' })}`,
    ...(profileId ? { 'x-profile-id': profileId } : {}),
  });
  beforeAll(async () => {
    f = await habitsDatabase();
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(DATABASE_POOL).useValue(f.appPool).compile();
    jwt = module.get(JwtService);
    auth = module.get(AuthService);
    app = module.createNestApplication<NestFastifyApplication>(new FastifyAdapter());
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });
  afterAll(async () => { if (app) await app.close(); if (f) await f.close(); });

  it('requires authentication and validates the active-profile header', async () => {
    expect((await app.inject({ method: 'GET', url: '/v1/habits' })).statusCode).toBe(401);
    expect((await app.inject({ method: 'GET', url: '/v1/habits', headers: headers(f.owner, 'invalid') })).statusCode).toBe(400);
    expect((await app.inject({ method: 'GET', url: '/v1/habits', headers: headers(f.owner, f.foreign) })).statusCode).toBe(403);
  });
  it('PUT fully replaces one daily row, defaults absent answers to null and preserves false', async () => {
    const put = (payload: object) => app.inject({ method: 'PUT', url: `/v1/habits/${today}`, headers: headers(f.owner), payload });
    const first = await put({ sleepQuality: 'bem', sleepHours: '7_8', moved: true, movementMinutes: '15_30', period: true });
    expect(first.statusCode, first.body).toBe(200);
    expect(first.json()).toMatchObject({ day: today, sleepQuality: 'bem', sleepHours: '7_8', moved: true, movementMinutes: '15_30', period: true });
    const replacement = await put({ moved: false, period: false });
    expect(replacement.statusCode, replacement.body).toBe(200);
    expect(replacement.json()).toEqual({ day: today, sleepQuality: null, sleepHours: null, moved: false, movementMinutes: null, period: false, updatedAt: expect.any(String) });
    const empty = await put({});
    expect(empty.json()).toMatchObject({ sleepQuality: null, sleepHours: null, moved: null, movementMinutes: null, period: null });
    expect((await f.admin.query('SELECT * FROM daily_habits WHERE profile_id = $1', [f.primary])).rowCount).toBe(1);
  });
  it('validates keys, types, movement rules, dates and history bounds over HTTP', async () => {
    for (const payload of [{ unknown: true }, { sleepQuality: 'otimo' }, { sleepHours: '8' }, { moved: 'true' }, { period: 1 },
      { movementMinutes: 'ate_15' }, { moved: false, movementMinutes: '30_60' }, { moved: null, movementMinutes: 'ate_15' }]) {
      const response = await app.inject({ method: 'PUT', url: `/v1/habits/${today}`, headers: headers(f.owner), payload });
      expect(response.statusCode, response.body).toBe(400);
    }
    for (const day of ['2026-02-30', '2026-1-01', 'bad', dayAgo(366), dayAgo(-2)]) {
      expect((await app.inject({ method: 'PUT', url: `/v1/habits/${day}`, headers: headers(f.owner), payload: {} })).statusCode).toBe(400);
    }
    for (const query of ['days=0', 'days=366', 'days=1.5', 'days=abc', 'unknown=x']) {
      expect((await app.inject({ method: 'GET', url: `/v1/habits?${query}`, headers: headers(f.owner) })).statusCode).toBe(400);
    }
    for (const day of [dayAgo(365), dayAgo(-1)]) {
      expect((await app.inject({ method: 'PUT', url: `/v1/habits/${day}`, headers: headers(f.owner), payload: {} })).statusCode).toBe(200);
    }
  });
  it('lists newest first in the requested window and isolates the selected profile', async () => {
    for (const n of [1, 29, 30]) await f.habits.putDay(f.owner, f.primary, dayAgo(n), { sleepQuality: 'regular' });
    const result = await app.inject({ method: 'GET', url: '/v1/habits?days=30', headers: headers(f.owner) });
    expect(result.statusCode).toBe(200);
    expect(result.json().days.map((d: any) => d.day)).toEqual([dayAgo(-1), today, dayAgo(1), dayAgo(29)]);
    expect((await app.inject({ method: 'GET', url: '/v1/habits', headers: headers(f.owner, f.dependent) })).json()).toEqual({ days: [] });
  });
  it('allows CO_MANAGE writes and VIEW_ONLY reads and blocks other access', async () => {
    const response = await app.inject({ method: 'PUT', url: `/v1/habits/${today}`, headers: headers(f.manager, f.dependent), payload: { period: true } });
    expect(response.statusCode, response.body).toBe(200);
    expect((await app.inject({ method: 'GET', url: '/v1/habits', headers: headers(f.viewer, f.dependent) })).json().days).toHaveLength(1);
    for (const method of ['PUT', 'DELETE'] as const) {
      const rejected = await app.inject({ method, url: `/v1/habits/${today}`, headers: headers(f.viewer, f.dependent), ...(method === 'PUT' ? { payload: {} } : {}) });
      expect(rejected.statusCode).toBe(403);
    }
    expect((await app.inject({ method: 'GET', url: '/v1/habits', headers: headers(f.stranger, f.dependent) })).statusCode).toBe(403);
  });
  it('returns 403 with a clear message when the grant does not include habits (Phase 11.1)', async () => {
    await f.admin.query("UPDATE shared_access_grants SET categories = ARRAY['care']::text[] WHERE grantee_user_id = $1", [f.manager]);
    try {
      for (const request of [
        { method: 'GET' as const, url: '/v1/habits' },
        { method: 'PUT' as const, url: `/v1/habits/${today}`, payload: { period: true } },
      ]) {
        const response = await app.inject({ ...request, headers: headers(f.manager, f.dependent) });
        expect(response.statusCode, response.body).toBe(403);
        expect(response.json().message).toBe('Esta categoria não foi compartilhada com você.');
      }
    } finally {
      await f.admin.query("UPDATE shared_access_grants SET categories = ARRAY['habits']::text[] WHERE grantee_user_id = $1", [f.manager]);
    }
  });
  it('exports only owned profiles habits, including records authored by a co-manager', async () => {
    await f.habits.putDay(f.stranger, f.foreign, today, { sleepQuality: 'mal' });
    const exported = await auth.exportUserData(f.owner);
    expect(exported.dailyHabits.map((d) => d.day)).toContain(today);
    expect(exported.dailyHabits.some((d) => d.sleepQuality === 'mal')).toBe(false);
    expect(exported.dependentProfiles[0].dailyHabits).toEqual([expect.objectContaining({ day: today, period: true })]);
    const managerExport = await auth.exportUserData(f.manager);
    expect(managerExport.dailyHabits).toEqual([]);
    expect(managerExport.dependentProfiles).toEqual([]);
  });
  it('DELETE returns 204, then 404; profile deletion cascades habits', async () => {
    const request = () => app.inject({ method: 'DELETE', url: `/v1/habits/${today}`, headers: headers(f.owner) });
    expect((await request()).statusCode).toBe(204);
    expect((await request()).statusCode).toBe(404);
    await f.asUser(f.owner, (c) => c.query('DELETE FROM profiles WHERE id = $1', [f.dependent]));
    expect((await f.admin.query('SELECT * FROM daily_habits WHERE profile_id = $1', [f.dependent])).rows).toEqual([]);
  });
});
