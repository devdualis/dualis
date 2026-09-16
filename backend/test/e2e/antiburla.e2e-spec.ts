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
import { AntiburlaService } from '../../src/modules/triage/services/antiburla.service';
import { CheckAntiburlaDto, AntiburlaCheckResponseDto } from '../../src/modules/triage/dto/antiburla.dto';

@Injectable()
class MockAntiburlaService {
  async checkHistoricalConsistency(
    userId: string,
    dto: CheckAntiburlaDto,
  ): Promise<AntiburlaCheckResponseDto> {
    const isToday = dto.selectedPersistence.includes('hoje') || dto.selectedPersistence.includes('agora');
    const isDiscordant = dto.userGender === 'feminino' && (dto.narrative?.includes('testículo') || false);

    if (isDiscordant) {
      return {
        triggered: false,
        biologicalDiscordance: true,
        biologicalNotice: 'Observamos uma possível discordância anatômica com o seu perfil biológico.',
      };
    }

    if (isToday) {
      return {
        triggered: true,
        daysAgo: 3,
        previousRecordedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
        previousCategoryLabel: 'Coluna e Dor Dorsal',
        empatheticPrompt:
          'Notei aqui no seu histórico que você também sentiu esse desconforto há 3 dias. Você acha que essa sensação de hoje é algo completamente novo ou pode ser aquela mesma que acabou voltando?',
        biologicalDiscordance: false,
      };
    }

    return {
      triggered: false,
      biologicalDiscordance: false,
    };
  }
}

describe('Antiburla Historical Verification E2E Suite (ANTI-01, ANTI-02, ANTI-03, UC-01)', () => {
  let app: NestFastifyApplication;
  let jwtService: JwtService;
  let validAccessToken: string;
  const mockUserId = '77777777-7777-7777-7777-777777777777';

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(AntiburlaService)
      .useClass(MockAntiburlaService)
      .compile();

    jwtService = moduleRef.get<JwtService>(JwtService);
    validAccessToken = jwtService.sign(
      { sub: mockUserId, email: 'antiburla.patient@example.com', type: 'access' },
      { expiresIn: '15m' },
    );

    const authService = moduleRef.get<AuthService>(AuthService);
    if (authService) {
      authService.validateUserById = async (id: string) => ({
        id,
        name: 'Antiburla Patient',
        email: 'antiburla.patient@example.com',
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

  it('1. POST /v1/triage/antiburla-check without Bearer token returns 401 Unauthorized', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/antiburla-check',
      payload: {
        vertical: 'physical',
        category: 'coluna',
        selectedPersistence: 'comecou_hoje',
      },
    });

    expect(res.statusCode).toBe(401);
  });

  it('2. POST /v1/triage/antiburla-check with invalid payload returns 400 Bad Request', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/antiburla-check',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        vertical: 'invalid_vertical',
        category: 'coluna',
        selectedPersistence: 'comecou_hoje',
      },
    });

    expect(res.statusCode).toBe(400);
  });

  it('3. POST /v1/triage/antiburla-check returns triggered: true with UC-01 empathetic prompt', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/antiburla-check',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        vertical: 'physical',
        category: 'coluna',
        selectedPersistence: 'comecou_hoje',
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.triggered).toBe(true);
    expect(body.daysAgo).toBe(3);
    expect(body.empatheticPrompt).toContain('Notei aqui no seu histórico');
    expect(body.empatheticPrompt).toContain('aquela mesma que acabou voltando');
  });

  it('4. POST /v1/triage/antiburla-check flags biological discordance', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/antiburla-check',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        vertical: 'physical',
        category: 'geniturinario',
        selectedPersistence: 'comecou_hoje',
        userGender: 'feminino',
        narrative: 'Dor no testículo direito',
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.biologicalDiscordance).toBe(true);
    expect(body.biologicalNotice).toBeDefined();
    expect(body.biologicalNotice).toContain('discordância anatômica');
  });
});
