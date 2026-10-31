import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import {
  ConflictException,
  Injectable,
  NotFoundException,
  ValidationPipe,
  VersioningType,
} from '@nestjs/common';
import * as crypto from 'node:crypto';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../../src/app.module';
import {
  defaultPrimaryProfileId,
  familyAccessFor,
  stubProfileAccess,
  TEST_PROFILES,
} from './support/profile-access.stub';
import { AuthService } from '../../src/modules/auth/auth.service';
import { JournalService } from '../../src/modules/journal/journal.service';
import { buildJournalSummary } from '../../src/modules/journal/journal-summary';

/** In-memory stand-in keyed by profile, like the real service's profile filter. */
@Injectable()
class MockJournalService {
  entries: any[] = [];
  conditions: any[] = [];
  calls: Array<{ method: string; userId: string; profileId: string; acceptLanguage?: string }> = [];

  async createEntry(userId: string, profileId: string, dto: any) {
    this.calls.push({ method: 'createEntry', userId, profileId });
    const existing = this.entries.find((e) => e.clientId === dto.clientId);
    if (existing) {
      if (existing.profileId !== profileId) throw new ConflictException('clientId já utilizado.');
      return existing.dto;
    }
    const id = crypto.randomUUID();
    const dtoOut = {
      id,
      legacy: false,
      clientId: dto.clientId,
      recordedAt: dto.recordedAt,
      mood: dto.mood,
      triggers: dto.triggers,
      triggerNote: dto.triggerNote ?? null,
      note: dto.note ?? null,
      transitionVariantIds: dto.transitionVariantIds,
      items: dto.items.map((i: any) => ({
        id: crypto.randomUUID(),
        kind: i.kind,
        optionKey: i.optionKey ?? null,
        customLabel: i.customLabel ?? null,
        conditionId: i.conditionId ?? null,
        label: i.conditionId ? (this.conditions.find((c) => c.id === i.conditionId)?.label ?? null) : null,
        bodySide: i.bodySide ?? null,
        persistence: i.persistence ?? null,
        intensity: i.intensity,
      })),
      createdAt: new Date().toISOString(),
    };
    this.entries.push({ id, profileId, clientId: dto.clientId, dto: dtoOut });
    return dtoOut;
  }

  async listEntries(userId: string, profileId: string, _query: any, acceptLanguage?: string) {
    this.calls.push({ method: 'listEntries', userId, profileId, acceptLanguage });
    return { entries: this.entries.filter((e) => e.profileId === profileId).map((e) => e.dto).reverse() };
  }

  async deleteEntry(_userId: string, profileId: string, id: string) {
    const index = this.entries.findIndex((e) => e.id === id && e.profileId === profileId);
    if (index === -1) throw new NotFoundException('Registro não encontrado.');
    this.entries.splice(index, 1);
  }

  async summary(_userId: string, profileId: string, query: any) {
    const entries = this.entries
      .filter((e) => e.profileId === profileId)
      .map((e) => ({ recordedAt: new Date(e.dto.recordedAt), triggers: e.dto.triggers, items: e.dto.items }));
    return buildJournalSummary(entries, query.days ?? 30, query.tzOffset ?? 0);
  }

  async listConditions(_userId: string, profileId: string) {
    return {
      conditions: this.conditions
        .filter((c) => c.profileId === profileId && !c.archived)
        .map(({ id, label, createdAt }) => ({ id, label, createdAt })),
    };
  }

  async createCondition(_userId: string, profileId: string, label: string) {
    if (this.conditions.filter((c) => c.profileId === profileId && !c.archived).length >= 10) {
      throw new ConflictException('Limite de 10 condições ativas atingido.');
    }
    const condition = { id: crypto.randomUUID(), profileId, label: label.trim(), createdAt: new Date().toISOString(), archived: false };
    this.conditions.push(condition);
    return { id: condition.id, label: condition.label, createdAt: condition.createdAt };
  }

  async archiveCondition(_userId: string, profileId: string, id: string) {
    const condition = this.conditions.find((c) => c.id === id && c.profileId === profileId && !c.archived);
    if (!condition) throw new NotFoundException('Condição não encontrada.');
    condition.archived = true;
  }
}

describe('Journal v2 E2E (/v1/journal/entries, conditions, summary, /v1/house-ads)', () => {
  const mockUserId = 'b0000000-0000-0000-0000-0000000000a2';
  const primaryId = defaultPrimaryProfileId(mockUserId);
  let app: NestFastifyApplication;
  let validToken: string;
  let journal: MockJournalService;

  const entry = (overrides: Record<string, unknown> = {}) => ({
    clientId: `outbox-${crypto.randomUUID()}`,
    recordedAt: '2026-10-27T12:00:00.000Z',
    mood: 'nao_tao_bem',
    triggers: ['sono'],
    transitionVariantIds: ['futuro.intro.1'],
    items: [
      { kind: 'emotional', optionKey: 'futuro.mente.antecipar', persistence: 'dias_semanas', intensity: 3 },
      { kind: 'physical', optionKey: 'cabeca.pressao.temporas', bodySide: 'front', persistence: 'hoje', intensity: 2 },
    ],
    ...overrides,
  });

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(JournalService)
      .useClass(MockJournalService)
      .compile();

    stubProfileAccess(moduleRef, familyAccessFor(mockUserId));

    app = moduleRef.createNestApplication<NestFastifyApplication>(new FastifyAdapter());
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    journal = moduleRef.get(JournalService) as unknown as MockJournalService;
    validToken = moduleRef.get(JwtService).sign(
      { sub: mockUserId, email: 'journal-v2@dualis.com.br', type: 'access' },
      { expiresIn: '15m' },
    );
    const authService = moduleRef.get(AuthService);
    authService.validateUserById = async (id: string) =>
      ({ id, name: 'Journal', email: 'journal-v2@dualis.com.br', gender: 'unspecified', dateOfBirth: null, createdAt: new Date(), updatedAt: new Date() }) as any;
  });

  afterAll(async () => {
    if (app) await app.close();
  });

  const auth = (profileId?: string) => ({
    authorization: `Bearer ${validToken}`,
    ...(profileId ? { 'x-profile-id': profileId } : {}),
  });
  const post = (url: string, payload: unknown, profileId?: string) =>
    app.inject({ method: 'POST', url, headers: auth(profileId), payload: payload as any });
  const get = (url: string, headers: Record<string, string> = auth()) => app.inject({ method: 'GET', url, headers });

  it('1. every journal v2 route requires authentication', async () => {
    for (const [method, url] of [
      ['POST', '/v1/journal/entries'],
      ['GET', '/v1/journal/entries'],
      ['DELETE', `/v1/journal/entries/${crypto.randomUUID()}`],
      ['GET', '/v1/journal/summary'],
      ['GET', '/v1/journal/conditions'],
      ['POST', '/v1/journal/conditions'],
      ['DELETE', `/v1/journal/conditions/${crypto.randomUUID()}`],
    ] as const) {
      const res = await app.inject({ method, url, payload: method === 'POST' ? {} : undefined });
      expect(res.statusCode, `${method} ${url}`).toBe(401);
    }
  });

  it('2. POST /entries stores an entry on the primary profile (201) and replays the same clientId', async () => {
    const payload = entry({ note: 'Dia corrido', triggerNote: 'mudança' });
    const first = await post('/v1/journal/entries', payload);
    expect(first.statusCode).toBe(201);
    const body = JSON.parse(first.body);
    expect(body).toMatchObject({ legacy: false, clientId: payload.clientId, mood: 'nao_tao_bem', note: 'Dia corrido' });
    expect(body.items).toHaveLength(2);
    expect(journal.calls.at(-1)).toMatchObject({ userId: mockUserId, profileId: primaryId });

    const replay = await post('/v1/journal/entries', payload);
    expect(replay.statusCode).toBe(201);
    expect(JSON.parse(replay.body).id).toBe(body.id);
  });

  it('3. POST /entries rejects keys outside the contract and unknown fields (400)', async () => {
    const bad = [
      entry({ mood: 'pessimo' }),
      entry({ triggers: ['estresse'] }),
      entry({ items: [{ kind: 'emotional', optionKey: 'futuro.mente.panico', persistence: 'hoje', intensity: 3 }] }),
      entry({ items: [{ kind: 'physical', optionKey: 'cabeca.pressao.temporas', persistence: 'hoje', intensity: 3 }] }),
      entry({ items: [{ kind: 'emotional', optionKey: 'futuro.mente.antecipar', persistence: 'hoje', intensity: 6 }] }),
      entry({ items: [{ kind: 'emotional', optionKey: 'futuro.custom', persistence: 'hoje', intensity: 2 }] }),
      entry({ triggers: ['queda'], items: [{ kind: 'emotional', optionKey: 'futuro.mente.antecipar', persistence: 'hoje', intensity: 2 }] }),
      entry({ items: Array(13).fill({ kind: 'emotional', optionKey: 'futuro.mente.antecipar', persistence: 'hoje', intensity: 2 }) }),
      entry({ urgencyScore: 4 }),
      entry({ items: [{ kind: 'emotional', optionKey: 'futuro.mente.antecipar', persistence: 'hoje', intensity: 2, severity: 'x' }] }),
    ];
    for (const payload of bad) {
      const res = await post('/v1/journal/entries', payload);
      expect(res.statusCode, JSON.stringify(payload).slice(0, 120)).toBe(400);
    }
  });

  it('4. writes need write access: VIEW_ONLY is 403, CO_MANAGE and dependent are allowed, foreign is 403', async () => {
    expect((await post('/v1/journal/entries', entry(), TEST_PROFILES.sharedViewOnly)).statusCode).toBe(403);
    expect((await post('/v1/journal/entries', entry(), TEST_PROFILES.foreign)).statusCode).toBe(403);
    expect((await post('/v1/journal/entries', entry(), TEST_PROFILES.sharedCoManage)).statusCode).toBe(201);
    expect((await post('/v1/journal/entries', entry(), TEST_PROFILES.dependent)).statusCode).toBe(201);
    expect((await post('/v1/journal/conditions', { label: 'Asma' }, TEST_PROFILES.sharedViewOnly)).statusCode).toBe(403);
    // Reading a VIEW_ONLY profile is fine
    expect((await get('/v1/journal/entries', auth(TEST_PROFILES.sharedViewOnly))).statusCode).toBe(200);
  });

  it('5. GET /entries lists only the active profile, validates days and forwards Accept-Language', async () => {
    const res = await get('/v1/journal/entries?days=30', { ...auth(), 'accept-language': 'es-ES,es;q=0.9' });
    expect(res.statusCode).toBe(200);
    const { entries } = JSON.parse(res.body);
    expect(entries.length).toBeGreaterThan(0);
    expect(journal.calls.at(-1)).toMatchObject({ method: 'listEntries', profileId: primaryId, acceptLanguage: 'es-ES,es;q=0.9' });

    const dependent = JSON.parse((await get('/v1/journal/entries', auth(TEST_PROFILES.dependent))).body).entries;
    expect(dependent).toHaveLength(1);

    expect((await get('/v1/journal/entries?days=365')).statusCode).toBe(200);
    expect((await get('/v1/journal/entries?days=366')).statusCode).toBe(400);
    expect((await get('/v1/journal/entries?days=0')).statusCode).toBe(400);
  });

  it('6. DELETE /entries/:id returns 204, then 404; non-uuid is 400', async () => {
    const created = JSON.parse((await post('/v1/journal/entries', entry())).body);
    const del = () => app.inject({ method: 'DELETE', url: `/v1/journal/entries/${created.id}`, headers: auth() });
    expect((await del()).statusCode).toBe(204);
    expect((await del()).statusCode).toBe(404);
    expect((await app.inject({ method: 'DELETE', url: '/v1/journal/entries/abc', headers: auth() })).statusCode).toBe(400);
  });

  it('7. conditions: create (201), list, use in an entry, archive (204), limit of 10 active (409)', async () => {
    const res = await post('/v1/journal/conditions', { label: '  Enxaqueca ' });
    expect(res.statusCode).toBe(201);
    const condition = JSON.parse(res.body);
    expect(condition).toEqual({ id: expect.any(String), label: 'Enxaqueca', createdAt: expect.any(String) });

    expect((await post('/v1/journal/conditions', { label: '   ' })).statusCode).toBe(400);
    expect((await post('/v1/journal/conditions', { label: 'a'.repeat(41) })).statusCode).toBe(400);
    expect((await post('/v1/journal/conditions', { label: 'Asma', severity: 3 })).statusCode).toBe(400);

    const withCondition = await post(
      '/v1/journal/entries',
      entry({ triggers: [], items: [{ kind: 'condition', conditionId: condition.id, intensity: 3 }] }),
    );
    expect(withCondition.statusCode).toBe(201);
    expect(JSON.parse(withCondition.body).items[0]).toMatchObject({ kind: 'condition', label: 'Enxaqueca', intensity: 3 });

    const list = JSON.parse((await get('/v1/journal/conditions')).body);
    expect(list.conditions.map((c: any) => c.label)).toEqual(['Enxaqueca']);

    const archive = () => app.inject({ method: 'DELETE', url: `/v1/journal/conditions/${condition.id}`, headers: auth() });
    expect((await archive()).statusCode).toBe(204);
    expect((await archive()).statusCode).toBe(404);
    expect(JSON.parse((await get('/v1/journal/conditions')).body).conditions).toEqual([]);

    for (let i = 0; i < 10; i++) {
      expect((await post('/v1/journal/conditions', { label: `C${i}` }, TEST_PROFILES.dependent)).statusCode).toBe(201);
    }
    expect((await post('/v1/journal/conditions', { label: 'C10' }, TEST_PROFILES.dependent)).statusCode).toBe(409);
  });

  it('8. GET /summary returns counts only', async () => {
    const res = await get('/v1/journal/summary?days=30&tzOffset=-180');
    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(Object.keys(body).sort()).toEqual(
      ['byOptionKey', 'byRegion', 'byTime', 'byTrigger', 'cooccurrence', 'days', 'daysWithEntries', 'totalEntries'].sort(),
    );
    expect(body.byTime.futuro).toBeGreaterThan(0);
    expect(body.byRegion.cabeca).toBeGreaterThan(0);
    expect(JSON.stringify(body)).not.toMatch(/Dia corrido|mudança|Enxaqueca/);
    expect((await get('/v1/journal/summary?tzOffset=9999')).statusCode).toBe(400);
  });

  it('9. GET /v1/house-ads is public, static and localized by Accept-Language', async () => {
    const pt = await app.inject({ method: 'GET', url: '/v1/house-ads' });
    expect(pt.statusCode).toBe(200);
    const ptAds = JSON.parse(pt.body).ads;
    expect(ptAds.map((a: any) => a.brand)).toEqual(['Dualis Premium', 'ZOC', 'e-BEF']);

    const en = JSON.parse((await app.inject({ method: 'GET', url: '/v1/house-ads', headers: { 'accept-language': 'en-US' } })).body).ads;
    expect(en.map((a: any) => a.id)).toEqual(ptAds.map((a: any) => a.id));
    expect(en[0].body).not.toBe(ptAds[0].body);

    // Same list with or without a session: nothing about the person reaches it.
    const authed = JSON.parse((await app.inject({ method: 'GET', url: '/v1/house-ads', headers: auth() })).body).ads;
    expect(authed).toEqual(ptAds);
  });

  it('10. legacy /v1/journal and /v1/triage routes are still mounted', async () => {
    for (const prefix of ['journal', 'triage']) {
      const res = await app.inject({ method: 'GET', url: `/v1/${prefix}/history?days=500`, headers: auth() });
      expect(res.statusCode, prefix).toBe(400); // reached the legacy controller's validation (max 30)
    }
  });
});
