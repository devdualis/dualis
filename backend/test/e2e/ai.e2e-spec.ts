import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../../src/app.module';
import { AuthService } from '../../src/modules/auth/auth.service';

describe('AI Symptom Classification E2E (POST /v1/ai/classify-symptom)', () => {
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
      { sub: 'usr-test-123456', email: 'test@dualis.com' },
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

  it('3. Classifies physical chest pain emergency with 200 OK', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/ai/classify-symptom',
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
    expect(body.primaryVertical).toBe('physical');
    expect(body.systemOrDimension).toBe('cardiovascular_chest');
    expect(body.urgencyScore).toBe(5);
    expect(body.isEmergencyCandidate).toBe(true);
    expect(body.latencyMs).toBeDefined();
  });

  it('4. Classifies emotional distress with 200 OK', async () => {
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
    expect(body.primaryVertical).toBe('emotional');
    expect(body.systemOrDimension).toBe('depressive_hopelessness');
    expect(body.isEmergencyCandidate).toBe(false);
  });
});
