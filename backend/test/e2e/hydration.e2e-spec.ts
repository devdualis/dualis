import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { VersioningType, ValidationPipe, Injectable, NotFoundException } from '@nestjs/common';
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
import { HydrationService } from '../../src/modules/hydration/hydration.service';

type StoredWaterLog = {
  id: string;
  userId: string;
  profileId: string;
  amountMl: number;
  source: string;
  recordedAt: string;
  createdAt: string;
};

/** In-memory stand-in that keeps logs per profile, like the real service's profile filter. */
@Injectable()
class MockHydrationService {
  readonly logs: StoredWaterLog[] = [];

  async logWater(userId: string, profileId: string, dto: any) {
    const now = new Date().toISOString();
    const log = {
      id: crypto.randomUUID(),
      userId,
      profileId,
      amountMl: dto.amountMl,
      source: dto.source || 'manual',
      recordedAt: now,
      createdAt: now,
    };
    this.logs.push(log);
    return log;
  }

  async getTodayLogs(_userId: string, profileId: string, _dateStr?: string) {
    const logs = this.logs.filter((l) => l.profileId === profileId);
    return {
      todayTotalMl: logs.reduce((sum, l) => sum + l.amountMl, 0),
      logs,
    };
  }

  async getHistory(_userId: string, profileId: string, _days?: number) {
    const totalMl = this.logs
      .filter((l) => l.profileId === profileId)
      .reduce((sum, l) => sum + l.amountMl, 0);
    const today = new Date().toISOString().slice(0, 10);
    return {
      totals: { [today]: totalMl },
      days: [{ date: today, totalMl }],
    };
  }

  async deleteLog(_userId: string, profileId: string, id: string) {
    const index = this.logs.findIndex((l) => l.id === id && l.profileId === profileId);
    if (index === -1) {
      throw new NotFoundException(`Water intake log with id ${id} not found.`);
    }
    this.logs.splice(index, 1);
    return { success: true, id };
  }
}

describe('Hydration Endpoints E2E', () => {
  const mockUserId = 'b0000000-0000-0000-0000-000000000001';
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

    stubProfileAccess(moduleRef, familyAccessFor(mockUserId));

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
      { sub: mockUserId, email: 'patient@dualis.com.br', type: 'access' },
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

  const auth = (profileId?: string) => ({
    authorization: `Bearer ${validToken}`,
    ...(profileId ? { 'x-profile-id': profileId } : {}),
  });

  const todayFor = async (profileId?: string) => {
    const response = await app.inject({
      method: 'GET',
      url: '/v1/hydration/today',
      headers: auth(profileId),
    });
    expect(response.statusCode).toBe(200);
    return JSON.parse(response.body);
  };

  it('3. POST /v1/hydration/log without X-Profile-Id logs to the primary profile', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/hydration/log',
      headers: auth(),
      payload: { amountMl: 300, source: 'quick_chip' },
    });

    expect(response.statusCode).toBe(201);
    const body = JSON.parse(response.body);
    expect(body.amountMl).toBe(300);
    expect(body.source).toBe('quick_chip');
    expect(body.userId).toBe(mockUserId);
    expect(body.profileId).toBe(defaultPrimaryProfileId(mockUserId));
  });

  it('4. GET /v1/hydration/today returns only the active profile logs', async () => {
    const body = await todayFor();
    expect(body.todayTotalMl).toBe(300);
    expect(body.logs).toHaveLength(1);
  });

  it('5. GET /v1/hydration/history returns 7-day history', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/v1/hydration/history?days=7',
      headers: auth(),
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.totals).toBeDefined();
    expect(body.days[0].totalMl).toBe(300);
  });

  it('6. X-Profile-Id of an owned dependent logs there and not in the primary profile', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/hydration/log',
      headers: auth(TEST_PROFILES.dependent),
      payload: { amountMl: 200 },
    });

    expect(response.statusCode).toBe(201);
    const body = JSON.parse(response.body);
    // Author stays the caller, subject is the dependent.
    expect(body.userId).toBe(mockUserId);
    expect(body.profileId).toBe(TEST_PROFILES.dependent);

    expect((await todayFor(TEST_PROFILES.dependent)).todayTotalMl).toBe(200);
    expect((await todayFor()).todayTotalMl).toBe(300);
  });

  it('7. CO_MANAGE grant can log water on the shared profile', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/hydration/log',
      headers: auth(TEST_PROFILES.sharedCoManage),
      payload: { amountMl: 150 },
    });

    expect(response.statusCode).toBe(201);
    expect(JSON.parse(response.body).profileId).toBe(TEST_PROFILES.sharedCoManage);
  });

  it('8. VIEW_ONLY grant can read but cannot log or delete', async () => {
    const write = await app.inject({
      method: 'POST',
      url: '/v1/hydration/log',
      headers: auth(TEST_PROFILES.sharedViewOnly),
      payload: { amountMl: 250 },
    });
    expect(write.statusCode).toBe(403);

    const remove = await app.inject({
      method: 'DELETE',
      url: '/v1/hydration/log/a0000000-0000-0000-0000-000000000001',
      headers: auth(TEST_PROFILES.sharedViewOnly),
    });
    expect(remove.statusCode).toBe(403);

    expect((await todayFor(TEST_PROFILES.sharedViewOnly)).todayTotalMl).toBe(0);

    const history = await app.inject({
      method: 'GET',
      url: '/v1/hydration/history?days=7',
      headers: auth(TEST_PROFILES.sharedViewOnly),
    });
    expect(history.statusCode).toBe(200);
  });

  it('9. X-Profile-Id the caller cannot reach returns 403, malformed returns 400', async () => {
    const foreign = await app.inject({
      method: 'GET',
      url: '/v1/hydration/today',
      headers: auth(TEST_PROFILES.foreign),
    });
    expect(foreign.statusCode).toBe(403);

    const malformed = await app.inject({
      method: 'GET',
      url: '/v1/hydration/today',
      headers: auth('not-a-uuid'),
    });
    expect(malformed.statusCode).toBe(400);
  });

  it('10. DELETE /v1/hydration/log/:id only deletes within the active profile', async () => {
    const dependentLogId = (await todayFor(TEST_PROFILES.dependent)).logs[0].id;

    const fromPrimary = await app.inject({
      method: 'DELETE',
      url: `/v1/hydration/log/${dependentLogId}`,
      headers: auth(),
    });
    expect(fromPrimary.statusCode).toBe(404);

    const fromDependent = await app.inject({
      method: 'DELETE',
      url: `/v1/hydration/log/${dependentLogId}`,
      headers: auth(TEST_PROFILES.dependent),
    });
    expect(fromDependent.statusCode).toBe(200);
    expect(JSON.parse(fromDependent.body).success).toBe(true);
    expect((await todayFor(TEST_PROFILES.dependent)).todayTotalMl).toBe(0);
  });
});
