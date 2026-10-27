import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../../src/app.module';
import { AuthService } from '../../src/modules/auth/auth.service';

describe('AI journal tagging E2E (POST /v1/ai/tag-entry, legacy /v1/ai/classify-symptom)', () => {
  let app: NestFastifyApplication;
  let jwtService: JwtService;
  let validToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(AuthService)
      .useValue({
        validateUserById: async (id: string) => ({
          id,
          name: 'Test User',
          email: 'test@dualis.com',
        }),
      })
      .compile();

    app = moduleFixture.createNestApplication<NestFastifyApplication>(
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

    jwtService = app.get<JwtService>(JwtService);
    validToken = jwtService.sign(
      { sub: 'usr-test-123456', email: 'test@dualis.com', type: 'access' },
      {
        secret:
          process.env.JWT_SECRET ||
          'dualis-secret-key-development-minimum-32-characters-secure',
      },
    );
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('1. Rejects unauthenticated request with 401 Unauthorized', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/ai/classify-symptom',
      payload: {
        text: 'Dor de cabeça e cansaço',
      },
    });

    expect(response.statusCode).toBe(401);
  });

  it('2. Rejects invalid or empty payload with 400 Bad Request', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/ai/classify-symptom',
      headers: {
        authorization: `Bearer ${validToken}`,
      },
      payload: {
        text: '',
      },
    });

    expect(response.statusCode).toBe(400);
  });

  const TAG_KEYS = ['bodyAreaOrMood', 'isOffTopic', 'layTerm', 'vertical'];

  it('3. Tags a physical entry with area and lay term only (200 OK)', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/ai/tag-entry',
      headers: {
        authorization: `Bearer ${validToken}`,
      },
      payload: {
        text: 'Estou sentindo uma forte dor no peito com pressão',
        language: 'pt',
      },
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.payload);
    expect(Object.keys(body).sort()).toEqual(TAG_KEYS);
    expect(body.vertical).toBe('physical');
    expect(body.isOffTopic).toBe(false);
    expect(body).not.toHaveProperty('mentionsSelfHarm');
  });

  it('4. Legacy path tags an emotional entry with the same contract (200 OK)', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/ai/classify-symptom',
      headers: {
        authorization: `Bearer ${validToken}`,
      },
      payload: {
        text: 'Muita tristeza, choro e desânimo persistente',
        language: 'pt',
      },
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.payload);
    expect(Object.keys(body).sort()).toEqual(TAG_KEYS);
    expect(body.vertical).toBe('emotional');
    expect(body).not.toHaveProperty('mentionsSelfHarm');
  });
});
