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
import { HydrationService } from '../../src/modules/hydration/hydration.service';

@Injectable()
class MockHydrationService {
  async logWater(userId: string, dto: any) {
    return {
      id: 'a0000000-0000-0000-0000-000000000001',
      userId,
      amountMl: dto.amountMl,
      source: dto.source || 'manual',
      recordedAt: new Date().toISOString(),
      createdAt: new Date().toISOString(),
    };
  }

  async getTodayLogs(userId: string, dateStr?: string) {
    return {
      todayTotalMl: 500,
      logs: [
        {
          id: 'a0000000-0000-0000-0000-000000000001',
          userId,
          amountMl: 500,
          source: 'manual',
          recordedAt: new Date().toISOString(),
          createdAt: new Date().toISOString(),
        },
      ],
    };
  }

  async getHistory(userId: string, days?: number) {
    return {
      totals: { '2026-09-27': 500 },
      days: [{ date: '2026-09-27', totalMl: 500 }],
    };
  }

  async deleteLog(userId: string, id: string) {
    return { success: true, id };
  }
}

describe('Hydration Endpoints E2E', () => {
  let app: NestFastifyApplication;
  let jwtService: JwtService;
  let validToken: string;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(HydrationService)
      .useClass(MockHydrationService)
      .compile();

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

    jwtService = moduleRef.get<JwtService>(JwtService);
    validToken = jwtService.sign(
      { sub: 'b0000000-0000-0000-0000-000000000001', email: 'patient@dualis.com.br', type: 'access' },
      { expiresIn: '15m' },
    );

    const authService = moduleRef.get<AuthService>(AuthService);
    if (authService) {
      authService.validateUserById = async (id: string) => ({
        id,
        name: 'Hydration Patient',
        email: 'patient@dualis.com.br',
        gender: 'unspecified',
        dateOfBirth: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    }
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('1. POST /v1/hydration/log requires authentication', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/hydration/log',
      payload: { amountMl: 250 },
    });

    expect(response.statusCode).toBe(401);
  });

  it('2. POST /v1/hydration/log validates amountMl > 0', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/hydration/log',
      headers: { authorization: `Bearer ${validToken}` },
      payload: { amountMl: -50 },
    });

    expect(response.statusCode).toBe(400);
  });

  it('3. POST /v1/hydration/log successfully logs water intake', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/hydration/log',
      headers: { authorization: `Bearer ${validToken}` },
      payload: { amountMl: 300, source: 'quick_chip' },
    });

    expect(response.statusCode).toBe(201);
    const body = JSON.parse(response.body);
    expect(body.amountMl).toBe(300);
    expect(body.source).toBe('quick_chip');
  });

  it('4. GET /v1/hydration/today returns today logs', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/v1/hydration/today',
      headers: { authorization: `Bearer ${validToken}` },
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.todayTotalMl).toBe(500);
    expect(body.logs).toHaveLength(1);
  });

  it('5. GET /v1/hydration/history returns 7-day history', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/v1/hydration/history?days=7',
      headers: { authorization: `Bearer ${validToken}` },
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.totals).toBeDefined();
  });

  it('6. DELETE /v1/hydration/log/:id deletes entry', async () => {
    const response = await app.inject({
      method: 'DELETE',
      url: '/v1/hydration/log/a0000000-0000-0000-0000-000000000001',
      headers: { authorization: `Bearer ${validToken}` },
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.success).toBe(true);
  });
});
