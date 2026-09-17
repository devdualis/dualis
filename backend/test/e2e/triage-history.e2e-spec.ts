import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { VersioningType, ValidationPipe, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../../src/app.module';
import { AuthService } from '../../src/modules/auth/auth.service';
import { TriageHistoryService } from '../../src/modules/triage/services/triage-history.service';
import {
  GetTriageHistoryQueryDto,
  TriageHistoryResponseDto,
} from '../../src/modules/triage/dto/triage-history.dto';

@Injectable()
class MockTriageHistoryService {
  async getHistory(
    userId: string,
    query?: GetTriageHistoryQueryDto,
  ): Promise<TriageHistoryResponseDto> {
    return {
      logs: [
        {
          id: 'log-hist-1',
          intensity: 4,
          anatomicalSystem: 'coluna_dorsal',
          emotionalDimension: null,
          disposition: 'consulta_rotina',
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
      criticalRecurrences: [
        {
          id: 'recurrence-estresse',
          vertical: 'emotional',
          category: 'estresse_burnout',
          categoryLabel: 'Estresse / Burnout',
          title: 'Foco de Atenção: Estresse / Burnout',
          description: 'Identificamos que a sua dimensão Estresse / Burnout esteve em nível 4 em 6 dos últimos 10 dias.',
          intensity: 4,
          frequencyCount: 6,
          windowDays: 10,
          recommendedArticleTitle: 'Manejo do Burnout',
          recommendedArticleUrl: 'https://drauziovarella.uol.com.br/psiquiatria/sindrome-de-burnout-esgotamento-profissional/',
        },
      ],
    };
  }

  async deleteHistoryItem(
    userId: string,
    id: string,
  ): Promise<{ success: boolean; id: string }> {
    return { success: true, id };
  }
}

describe('Triage History E2E Suite (DASH-01, DASH-02, DASH-03, DASH-04, SEC-01)', () => {
  let app: NestFastifyApplication;
  let jwtService: JwtService;
  let validAccessToken: string;
  const mockUserId = '99999999-9999-9999-9999-999999999999';

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(TriageHistoryService)
      .useClass(MockTriageHistoryService)
      .compile();

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

    app = moduleRef.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
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
    expect(body.criticalRecurrences).toHaveLength(1);
    expect(body.criticalRecurrences[0].category).toBe('estresse_burnout');
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
});
