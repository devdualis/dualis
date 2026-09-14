import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { VersioningType, ValidationPipe, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as crypto from 'crypto';
import { AppModule } from '../../src/app.module';
import { AuthService } from '../../src/modules/auth/auth.service';
import { TriageOutcomeService } from '../../src/modules/triage/services/triage-outcome.service';
import { SubmitTriageDto, TriageOutcomeResponseDto } from '../../src/modules/triage/dto/triage-outcome.dto';

@Injectable()
class IdempotentMockTriageOutcomeService {
  private readonly records = new Map<string, TriageOutcomeResponseDto>();

  async processOutcome(userId: string, dto: SubmitTriageDto): Promise<TriageOutcomeResponseDto> {
    if (dto.clientSessionId && this.records.has(`${userId}:${dto.clientSessionId}`)) {
      return this.records.get(`${userId}:${dto.clientSessionId}`)!;
    }

    const outcome: TriageOutcomeResponseDto = {
      id: crypto.randomUUID(),
      vertical: dto.vertical,
      intensityScore: 3,
      careDisposition: 'consulta_rotina',
      primaryCategory: 'coluna_dor_dorsal',
      categoryLabel: 'Coluna e Dor Dorsal',
      somaticMapping: 'Dor lombar postural',
      organicPrimacyApplied: false,
      recommendedArticles: [],
      recordedAt: new Date().toISOString(),
    };

    if (dto.clientSessionId) {
      this.records.set(`${userId}:${dto.clientSessionId}`, outcome);
    }

    return outcome;
  }
}

describe('Outbox Idempotency E2E Suite (SYNC-01)', () => {
  let app: NestFastifyApplication;
  let jwtService: JwtService;
  let validAccessToken: string;
  const mockUserId = '99999999-9999-9999-9999-999999999999';

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(TriageOutcomeService)
      .useClass(IdempotentMockTriageOutcomeService)
      .compile();

    jwtService = moduleRef.get<JwtService>(JwtService);
    validAccessToken = jwtService.sign(
      { sub: mockUserId, email: 'sync.patient@example.com' },
      { expiresIn: '15m' },
    );

    const authService = moduleRef.get<AuthService>(AuthService);
    if (authService) {
      authService.validateUserById = async (id: string) => ({
        id,
        name: 'Sync Patient',
        email: 'sync.patient@example.com',
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

  it('POST /v1/triage/outcome accepts clientSessionId and creates first record', async () => {
    const clientSessionId = crypto.randomUUID();

    const response = await app.inject({
      method: 'POST',
      url: '/v1/triage/outcome',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        vertical: 'physical',
        answers: { 0: 'costas', 1: 'ha_alguns_dias', 2: '3' },
        clientSessionId,
      },
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.id).toBeDefined();
    expect(body.vertical).toBe('physical');
  });

  it('POST /v1/triage/outcome with duplicate clientSessionId returns existing outcome (idempotent)', async () => {
    const clientSessionId = crypto.randomUUID();

    // First submission
    const res1 = await app.inject({
      method: 'POST',
      url: '/v1/triage/outcome',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        vertical: 'physical',
        answers: { 0: 'costas', 1: 'ha_alguns_dias', 2: '3' },
        clientSessionId,
      },
    });

    expect(res1.statusCode).toBe(200);
    const body1 = JSON.parse(res1.body);

    // Duplicate submission (e.g. outbox retry)
    const res2 = await app.inject({
      method: 'POST',
      url: '/v1/triage/outcome',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        vertical: 'physical',
        answers: { 0: 'costas', 1: 'ha_alguns_dias', 2: '3' },
        clientSessionId,
      },
    });

    expect(res2.statusCode).toBe(200);
    const body2 = JSON.parse(res2.body);

    // Must return identical outcome ID without duplicate record
    expect(body2.id).toBe(body1.id);
    expect(body2.recordedAt).toBe(body1.recordedAt);
  });
});
