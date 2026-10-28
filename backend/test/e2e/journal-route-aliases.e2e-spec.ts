import { describe, it, expect, beforeAll, afterAll, vi } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../../src/app.module';
import { AuthService } from '../../src/modules/auth/auth.service';
import { TriageOutcomeService } from '../../src/modules/triage/services/triage-outcome.service';
import { AntiburlaService } from '../../src/modules/triage/services/antiburla.service';
import { TriageHistoryService } from '../../src/modules/triage/services/triage-history.service';
import { defaultPrimaryProfileId, stubProfileAccess } from './support/profile-access.stub';

/**
 * Contract 4: every /v1/triage/* handler is also served under /v1/journal/*, the
 * antiburla check also as /v1/journal/recurrence-check. Old and new paths must reach the
 * same handler with the same rules. AI tagging was removed: its routes no longer exist.
 */
describe('Journal route aliases E2E', () => {
  let app: NestFastifyApplication;
  let token: string;
  const userId = '77777777-7777-4777-8777-777777777777';
  const entryId = '6a6a6a6a-0000-4000-8000-000000000001';

  const history = { getHistory: vi.fn(async () => ({ items: [], marker: 'history' })), deleteHistoryItem: vi.fn(async (_u: string, _p: string, id: string) => ({ success: true, id })) };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(TriageOutcomeService)
      .useValue({ processOutcome: vi.fn(), recordDailyCheckIn: vi.fn() })
      .overrideProvider(AntiburlaService)
      .useValue({ checkHistoricalConsistency: vi.fn() })
      .overrideProvider(TriageHistoryService)
      .useValue(history)
      .compile();

    stubProfileAccess(moduleRef);
    const authService = moduleRef.get<AuthService>(AuthService);
    authService.validateUserById = async (id: string) => ({ id, name: 'Alias Test', email: 'alias@dualis.test' }) as any;
    token = moduleRef.get<JwtService>(JwtService).sign({ sub: userId, email: 'alias@dualis.test', type: 'access' }, { expiresIn: '15m' });

    app = moduleRef.createNestApplication<NestFastifyApplication>(new FastifyAdapter());
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    if (app) await app.close();
  });

  const inject = (method: 'GET' | 'POST' | 'DELETE', url: string, payload?: object, auth = true) =>
    app.inject({ method, url, payload, headers: auth ? { authorization: `Bearer ${token}` } : {} });

  const postRoutes = [
    ['/v1/triage/outcome', '/v1/journal/outcome'],
    ['/v1/triage/daily-checkin', '/v1/journal/daily-checkin'],
    ['/v1/triage/antiburla-check', '/v1/journal/antiburla-check', '/v1/journal/recurrence-check'],
  ];

  it.each(postRoutes)('POST %s and its journal aliases exist, require auth and validate the body', async (...urls) => {
    for (const url of urls) {
      expect((await inject('POST', url, {}, false)).statusCode, url).toBe(401);
      expect((await inject('POST', url, {})).statusCode, url).toBe(400);
    }
  });

  it('GET history answers on both prefixes from the same handler', async () => {
    for (const url of ['/v1/triage/history', '/v1/journal/history']) {
      const res = await inject('GET', url);
      expect(res.statusCode, url).toBe(200);
      expect(JSON.parse(res.payload)).toEqual({ items: [], marker: 'history' });
    }
    expect(history.getHistory).toHaveBeenCalledTimes(2);
    expect(history.getHistory).toHaveBeenLastCalledWith(userId, defaultPrimaryProfileId(userId), expect.any(Object));
  });

  it('DELETE history/:id answers on both prefixes and validates the id', async () => {
    for (const prefix of ['/v1/triage', '/v1/journal']) {
      const res = await inject('DELETE', `${prefix}/history/${entryId}`);
      expect(res.statusCode, prefix).toBe(200);
      expect(JSON.parse(res.payload)).toEqual({ success: true, id: entryId });
      expect((await inject('DELETE', `${prefix}/history/not-a-uuid`)).statusCode, prefix).toBe(400);
    }
  });

  it('AI tagging routes are gone: /v1/ai/tag-entry and /v1/ai/classify-symptom answer 404', async () => {
    for (const url of ['/v1/ai/tag-entry', '/v1/ai/classify-symptom']) {
      expect((await inject('POST', url, { text: 'dor de cabeça' })).statusCode, url).toBe(404);
    }
  });
});
