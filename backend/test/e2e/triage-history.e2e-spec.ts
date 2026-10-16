import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { VersioningType, ValidationPipe, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../../src/app.module';
import {
  defaultPrimaryProfileId,
  familyAccessFor,
  stubProfileAccess,
  TEST_PROFILES,
} from './support/profile-access.stub';
import { AuthService } from '../../src/modules/auth/auth.service';
import { TriageHistoryService } from '../../src/modules/triage/services/triage-history.service';
import {
  GetTriageHistoryQueryDto,
  TriageHistoryResponseDto,
} from '../../src/modules/triage/dto/triage-history.dto';

@Injectable()
class MockTriageHistoryService {
  readonly calls: Array<{ method: string; userId: string; profileId: string }> = [];

  async getHistory(
    userId: string,
    profileId: string,
    query?: GetTriageHistoryQueryDto,
  ): Promise<TriageHistoryResponseDto> {
    this.calls.push({ method: 'getHistory', userId, profileId });
    return {
      logs: [
        {
          id: 'log-hist-1',
          intensity: 4,
          anatomicalSystem: 'coluna_dorsal',
          emotionalDimension: null,
          vertical: 'physical',
          stepAnswers: { causes: 'esforço pesado' },
          recordedAt: new Date().toISOString(),
        },
      ],
      physicalSummary: {
        cabeca_pescoco: 0,
        cardiovascular_torax: 0,
        respiratorio: 0,
        gastrointestinal_abdomen: 0,
        coluna_dorsal: 4,
        membros_superiores_d: 0,
        membros_superiores_e: 0,
        membros_inferiores_d: 0,
        membros_inferiores_e: 0,
        neurologico: 0,
        geniturinario_pelvico: 0,
        dermatologico: 0,
      },
      emotionalSummary: [
        {
          date: '2026-09-14',
          dimensions: {
            ansiosa_agitacao: 2,
            depressiva_desanimo: 1,
            estresse_burnout: 4,
            somatica: 0,
            sono: 3,
            cognitiva_foco: 0,
            autoestima: 0,
          },
        },
      ],
      journalPatterns: [{ category: 'estresse_burnout', vertical: 'emotional', count: 6, windowDays: 10 }],
    };
  }

  async deleteHistoryItem(
    userId: string,
    profileId: string,
    id: string,
  ): Promise<{ success: boolean; id: string }> {
    this.calls.push({ method: 'deleteHistoryItem', userId, profileId });
    return { success: true, id };
  }
}

describe('Triage History E2E Suite (DASH-01, DASH-02, DASH-03, DASH-04, SEC-01)', () => {
  let app: NestFastifyApplication;
  let jwtService: JwtService;
  let validAccessToken: string;
  let historyService: MockTriageHistoryService;
  const mockUserId = '99999999-9999-9999-9999-999999999999';

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(TriageHistoryService)
      .useClass(MockTriageHistoryService)
      .compile();

    stubProfileAccess(moduleRef, familyAccessFor(mockUserId));
    historyService = moduleRef.get(TriageHistoryService) as unknown as MockTriageHistoryService;

    jwtService = moduleRef.get<JwtService>(JwtService);
    validAccessToken = jwtService.sign(
      { sub: mockUserId, email: 'history.patient@example.com', type: 'access' },
      { expiresIn: '15m' },
    );

    const authService = moduleRef.get<AuthService>(AuthService);
    if (authService) {
      authService.validateUserById = async (id: string) => ({
        id,
        name: 'History Patient',
        email: 'history.patient@example.com',
        gender: 'unspecified',
        dateOfBirth: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    }

    const fastifyAdapter = new FastifyAdapter();
    fastifyAdapter.useBodyParser('application/json', false, {}, (req: any, body: any, done: any) => {
      const str = body ? body.toString('utf8').trim() : '';
      if (!str) {
        done(null, undefined);
        return;
      }
      try {
        done(null, JSON.parse(str));
      } catch (err: any) {
        err.statusCode = 400;
        done(err, undefined);
      }
    });

    app = moduleRef.createNestApplication<NestFastifyApplication>(
      fastifyAdapter,
    );

    app.enableVersioning({
      type: VersioningType.URI,
      defaultVersion: '1',
    });

    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('1. GET /v1/triage/history without Bearer token returns 401 Unauthorized', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/triage/history',
    });

    expect(res.statusCode).toBe(401);
  });

  it('2. GET /v1/triage/history with valid token returns 200 with history payload', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/triage/history?days=14',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.logs).toHaveLength(1);
    expect(body.physicalSummary.coluna_dorsal).toBe(4);
    expect(body.emotionalSummary).toHaveLength(1);
    expect(body.journalPatterns).toEqual([
      { category: 'estresse_burnout', vertical: 'emotional', count: 6, windowDays: 10 },
    ]);
    expect(body).not.toHaveProperty('criticalRecurrences');
    expect(body.logs[0]).not.toHaveProperty('disposition');
  });

  it('3. GET /v1/triage/history with invalid days parameter returns 400 Bad Request', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/triage/history?days=100',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
    });

    expect(res.statusCode).toBe(400);
  });

  it('4. DELETE /v1/triage/history/:id without Bearer token returns 401 Unauthorized', async () => {
    const res = await app.inject({
      method: 'DELETE',
      url: '/v1/triage/history/11111111-1111-1111-1111-111111111111',
    });

    expect(res.statusCode).toBe(401);
  });

  it('5. DELETE /v1/triage/history/:id with invalid UUID returns 400 Bad Request', async () => {
    const res = await app.inject({
      method: 'DELETE',
      url: '/v1/triage/history/not-a-valid-uuid',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
    });

    expect(res.statusCode).toBe(400);
  });

  it('6. DELETE /v1/triage/history/:id with valid token and UUID returns 200 with success payload', async () => {
    const testId = '11111111-1111-1111-1111-111111111111';
    const res = await app.inject({
      method: 'DELETE',
      url: `/v1/triage/history/${testId}`,
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body).toEqual({ success: true, id: testId });
  });

  it('7. DELETE /v1/triage/history/:id with content-type: application/json and empty body returns 200', async () => {
    const testId = '22222222-2222-2222-2222-222222222222';
    const res = await app.inject({
      method: 'DELETE',
      url: `/v1/triage/history/${testId}`,
      headers: {
        authorization: `Bearer ${validAccessToken}`,
        'content-type': 'application/json',
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body).toEqual({ success: true, id: testId });
  });

  const lastCall = () => historyService.calls[historyService.calls.length - 1];

  it('8. GET /v1/triage/history without X-Profile-Id reads the primary profile', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/triage/history',
      headers: { authorization: `Bearer ${validAccessToken}` },
    });

    expect(res.statusCode).toBe(200);
    expect(lastCall()).toEqual({
      method: 'getHistory',
      userId: mockUserId,
      profileId: defaultPrimaryProfileId(mockUserId),
    });
  });

  it('9. GET /v1/triage/history with a dependent X-Profile-Id reads that profile', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/triage/history',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
        'x-profile-id': TEST_PROFILES.dependent,
      },
    });

    expect(res.statusCode).toBe(200);
    expect(lastCall().profileId).toBe(TEST_PROFILES.dependent);
  });

  it('10. VIEW_ONLY grant reads history (200) but cannot delete (403)', async () => {
    const read = await app.inject({
      method: 'GET',
      url: '/v1/triage/history',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
        'x-profile-id': TEST_PROFILES.sharedViewOnly,
      },
    });
    expect(read.statusCode).toBe(200);
    expect(lastCall().profileId).toBe(TEST_PROFILES.sharedViewOnly);

    const callsBefore = historyService.calls.length;
    const remove = await app.inject({
      method: 'DELETE',
      url: '/v1/triage/history/11111111-1111-1111-1111-111111111111',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
        'x-profile-id': TEST_PROFILES.sharedViewOnly,
      },
    });
    expect(remove.statusCode).toBe(403);
    expect(historyService.calls.length).toBe(callsBefore);
  });

  it('11. CO_MANAGE grant can delete on the shared profile', async () => {
    const res = await app.inject({
      method: 'DELETE',
      url: '/v1/triage/history/11111111-1111-1111-1111-111111111111',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
        'x-profile-id': TEST_PROFILES.sharedCoManage,
      },
    });

    expect(res.statusCode).toBe(200);
    expect(lastCall()).toMatchObject({
      method: 'deleteHistoryItem',
      profileId: TEST_PROFILES.sharedCoManage,
    });
  });

  it('12. X-Profile-Id the caller cannot reach returns 403', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/triage/history',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
        'x-profile-id': TEST_PROFILES.foreign,
      },
    });

    expect(res.statusCode).toBe(403);
  });
});
