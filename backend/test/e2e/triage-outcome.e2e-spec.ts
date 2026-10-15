import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { VersioningType, ValidationPipe, Injectable, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as crypto from 'crypto';
import { AppModule } from '../../src/app.module';
import {
  defaultPrimaryProfileId,
  familyAccessFor,
  stubProfileAccess,
  TEST_PROFILES,
} from './support/profile-access.stub';
import { AuthService } from '../../src/modules/auth/auth.service';
import { TriageOutcomeService } from '../../src/modules/triage/services/triage-outcome.service';
import { SubmitTriageDto, TriageOutcomeResponseDto } from '../../src/modules/triage/dto/triage-outcome.dto';

@Injectable()
class MockTriageOutcomeService {
  readonly calls: Array<{ method: string; userId: string; profileId: string }> = [];

  async recordDailyCheckIn(userId: string, profileId: string, _dto: unknown) {
    this.calls.push({ method: 'recordDailyCheckIn', userId, profileId });
    return { id: crypto.randomUUID(), recordedAt: new Date().toISOString() };
  }

  async processOutcome(
    userId: string,
    profileId: string,
    dto: SubmitTriageDto,
  ): Promise<TriageOutcomeResponseDto> {
    if (!userId) {
      throw new BadRequestException('ID do usuário ausente.');
    }
    this.calls.push({ method: 'processOutcome', userId, profileId });
    const isOrganic = dto.vertical === 'emotional' && (dto.narrative?.includes('peito') || false);
    return {
      id: crypto.randomUUID(),
      vertical: dto.vertical,
      intensityScore: dto.vertical === 'physical' ? 3 : 2,
      careDisposition: 'consulta_rotina',
      primaryCategory: dto.vertical === 'physical' ? 'coluna_dor_dorsal' : 'ansiosa_agitacao',
      categoryLabel: dto.vertical === 'physical' ? 'Coluna e Dor Dorsal' : 'Dimensão Ansiosa / Agitação',
      somaticMapping: 'Mapeamento somático normalizado',
      organicPrimacyApplied: isOrganic,
      organicPrimacyNotice: isOrganic
        ? 'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem que causas orgânicas sejam avaliadas.'
        : undefined,
      recommendedArticles: [
        {
          id: 'art-coluna-01',
          title: 'Ergonomia no Trabalho',
          category: 'coluna_dor_dorsal',
          author: 'Dr. Marcelo Mendes',
          authorRole: 'Ortopedista',
          readTimeMinutes: 5,
          summary: 'Guia postural',
          url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
        },
      ],
      recordedAt: new Date().toISOString(),
    };
  }
}

describe('Triage Outcome E2E Suite (SOM-01, SOM-02, OUT-01, REC-01)', () => {
  let app: NestFastifyApplication;
  let jwtService: JwtService;
  let validAccessToken: string;
  let outcomeService: MockTriageOutcomeService;
  const mockUserId = '88888888-8888-8888-8888-888888888888';

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(TriageOutcomeService)
      .useClass(MockTriageOutcomeService)
      .compile();

    stubProfileAccess(moduleRef, familyAccessFor(mockUserId));
    outcomeService = moduleRef.get(TriageOutcomeService) as unknown as MockTriageOutcomeService;

    jwtService = moduleRef.get<JwtService>(JwtService);
    validAccessToken = jwtService.sign(
      { sub: mockUserId, email: 'triage.patient@example.com', type: 'access' },
      { expiresIn: '15m' },
    );

    const authService = moduleRef.get<AuthService>(AuthService);
    if (authService) {
      authService.validateUserById = async (id: string) => ({
        id,
        name: 'Triage Patient',
        email: 'triage.patient@example.com',
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

  it('1. POST /v1/triage/outcome without Bearer token returns 401 Unauthorized', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/outcome',
      payload: {
        vertical: 'physical',
        answers: { 1: 'costas', 2: 'alguns_dias', 3: '3' },
      },
    });

    expect(res.statusCode).toBe(401);
  });

  it('2. POST /v1/triage/outcome with invalid payload returns 400 Bad Request', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/outcome',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        vertical: 'invalid_vertical',
        answers: {},
      },
    });

    expect(res.statusCode).toBe(400);
  });

  it('3. POST /v1/triage/outcome processes physical triage and returns disposition and specialist articles', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/outcome',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        vertical: 'physical',
        answers: {
          1: 'costas',
          2: 'comecou_hoje',
          3: '3',
          4: 'exercicio_intenso',
        },
        narrative: 'Dor lombar após esforço físico',
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body).toHaveProperty('id');
    expect(body.vertical).toBe('physical');
    expect(body.primaryCategory).toBe('coluna_dor_dorsal');
    expect(body.categoryLabel).toBe('Coluna e Dor Dorsal');
    expect(body.intensityScore).toBe(3);
    expect(body.careDisposition).toBe('consulta_rotina');
    expect(body.organicPrimacyApplied).toBe(false);
    expect(Array.isArray(body.recommendedArticles)).toBe(true);
    expect(body.recommendedArticles.length).toBeGreaterThan(0);
    expect(body.recommendedArticles[0].author).toContain('Dr. Marcelo Mendes');
  });

  it('4. POST /v1/triage/outcome triggers Organic Primacy on emotional triage with physical symptoms', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/outcome',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        vertical: 'emotional',
        answers: {
          1: 'ansiedade',
          2: 'comecou_hoje',
          3: 'leve_controlavel',
          4: 'trabalho_estudos',
        },
        narrative: 'Muita ansiedade com aperto no peito constante',
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.vertical).toBe('emotional');
    expect(body.organicPrimacyApplied).toBe(true);
    expect(body.organicPrimacyNotice).toBeDefined();
    expect(body.organicPrimacyNotice).toContain('Primazia Orgânica');
    expect(body.careDisposition).toBe('consulta_rotina');
  });

  const physicalPayload = {
    vertical: 'physical',
    answers: { 1: 'costas', 2: 'comecou_hoje', 3: '3', 4: 'exercicio_intenso' },
  };
  const checkInPayload = { emotionalStatus: 'soSo', physicalStatus: 'goodNormal' };
  const lastCall = () => outcomeService.calls[outcomeService.calls.length - 1];
  const post = (url: string, payload: object, profileId?: string) =>
    app.inject({
      method: 'POST',
      url,
      headers: {
        authorization: `Bearer ${validAccessToken}`,
        ...(profileId ? { 'x-profile-id': profileId } : {}),
      },
      payload,
    });

  it('5. POST /v1/triage/outcome without X-Profile-Id records on the primary profile', async () => {
    const res = await post('/v1/triage/outcome', physicalPayload);

    expect(res.statusCode).toBe(200);
    expect(lastCall()).toEqual({
      method: 'processOutcome',
      userId: mockUserId,
      profileId: defaultPrimaryProfileId(mockUserId),
    });
  });

  it('6. Outcome and daily check-in with a dependent X-Profile-Id land on the dependent', async () => {
    const outcome = await post('/v1/triage/outcome', physicalPayload, TEST_PROFILES.dependent);
    expect(outcome.statusCode).toBe(200);
    expect(lastCall()).toEqual({
      method: 'processOutcome',
      userId: mockUserId,
      profileId: TEST_PROFILES.dependent,
    });

    const checkIn = await post('/v1/triage/daily-checkin', checkInPayload, TEST_PROFILES.dependent);
    expect(checkIn.statusCode).toBe(200);
    expect(lastCall()).toEqual({
      method: 'recordDailyCheckIn',
      userId: mockUserId,
      profileId: TEST_PROFILES.dependent,
    });
  });

  it('7. CO_MANAGE grant can submit a triage for the shared profile', async () => {
    const res = await post('/v1/triage/outcome', physicalPayload, TEST_PROFILES.sharedCoManage);

    expect(res.statusCode).toBe(200);
    expect(lastCall().profileId).toBe(TEST_PROFILES.sharedCoManage);
  });

  it('8. VIEW_ONLY grant gets 403 on outcome and daily check-in, and nothing is recorded', async () => {
    const callsBefore = outcomeService.calls.length;

    const outcome = await post('/v1/triage/outcome', physicalPayload, TEST_PROFILES.sharedViewOnly);
    expect(outcome.statusCode).toBe(403);

    const checkIn = await post('/v1/triage/daily-checkin', checkInPayload, TEST_PROFILES.sharedViewOnly);
    expect(checkIn.statusCode).toBe(403);

    expect(outcomeService.calls.length).toBe(callsBefore);
  });

  it('9. X-Profile-Id the caller cannot reach returns 403', async () => {
    const res = await post('/v1/triage/outcome', physicalPayload, TEST_PROFILES.foreign);
    expect(res.statusCode).toBe(403);
  });
});
