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
import { TriageAuditService } from '../../src/modules/triage-audit/triage-audit.service';
import { CreateEmergencyEventDto } from '../../src/modules/triage-audit/dto/create-emergency-event.dto';
import { AuthService } from '../../src/modules/auth/auth.service';

@Injectable()
class MockTriageAuditService {
  public recordedEvents: Array<{
    id: string;
    triggerCategory: string;
    severityLevel: number;
    sourceVertical: 'PHYSICAL' | 'EMOTIONAL';
    actionTaken: string | null;
    reportedAt: Date;
    createdAt: Date;
    userId: string | null;
  }> = [];

  async recordEmergencyEvent(
    dto: CreateEmergencyEventDto,
    userId?: string | null,
  ) {
    const event = {
      id: crypto.randomUUID(),
      triggerCategory: dto.triggerCategory,
      severityLevel: dto.severityLevel,
      sourceVertical: dto.sourceVertical,
      actionTaken: dto.actionTaken ?? null,
      reportedAt: new Date(dto.clientTimestamp),
      createdAt: new Date(),
      userId: userId ?? null,
    };
    this.recordedEvents.push(event);
    return event;
  }
}

describe('Triage Emergency Audit E2E Suite (EMRG-01, EMRG-03, SEC-01)', () => {
  let app: NestFastifyApplication;
  let mockTriageAuditService: MockTriageAuditService;
  let jwtService: JwtService;
  let validAccessToken: string;
  const mockUserId = '99999999-9999-9999-9999-999999999999';

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(TriageAuditService)
      .useClass(MockTriageAuditService)
      .compile();

    mockTriageAuditService = moduleRef.get<MockTriageAuditService>(TriageAuditService);

    jwtService = moduleRef.get<JwtService>(JwtService);
    validAccessToken = jwtService.sign(
      { sub: mockUserId, email: 'patient@example.com' },
      { expiresIn: '15m' },
    );

    // Mock validateUserById on AuthService if called by JwtStrategy
    const authService = moduleRef.get<AuthService>(AuthService);
    if (authService) {
      authService.validateUserById = async (id: string) => ({
        id,
        name: 'Patient Test',
        email: 'patient@example.com',
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

  it('POST /v1/triage/emergency-event creates anonymous emergency event (201 Created)', async () => {
    const payload = {
      triggerCategory: 'chestPain',
      severityLevel: 5,
      sourceVertical: 'PHYSICAL',
      clientTimestamp: new Date().toISOString(),
      actionTaken: 'DIALED_192',
    };

    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/emergency-event',
      payload,
    });

    expect(res.statusCode).toBe(201);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
    expect(body.data).toHaveProperty('id');
    expect(body.data.triggerCategory).toBe('chestPain');
    expect(body.data.severityLevel).toBe(5);
    expect(body.data.sourceVertical).toBe('PHYSICAL');
    expect(body.data.actionTaken).toBe('DIALED_192');
  });

  it('POST /v1/triage/emergency-event with severityLevel < 4 returns 400 Bad Request', async () => {
    const invalidPayload = {
      triggerCategory: 'mildHeadache',
      severityLevel: 2, // Violates @Min(4)
      sourceVertical: 'PHYSICAL',
      clientTimestamp: new Date().toISOString(),
    };

    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/emergency-event',
      payload: invalidPayload,
    });

    expect(res.statusCode).toBe(400);
    const body = JSON.parse(res.payload);
    expect(body.message).toEqual(
      expect.arrayContaining([expect.stringContaining('severityLevel')]),
    );
  });

  it('POST /v1/triage/emergency-event with severityLevel > 5 returns 400 Bad Request', async () => {
    const invalidPayload = {
      triggerCategory: 'chestPain',
      severityLevel: 6, // Violates @Max(5)
      sourceVertical: 'PHYSICAL',
      clientTimestamp: new Date().toISOString(),
    };

    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/emergency-event',
      payload: invalidPayload,
    });

    expect(res.statusCode).toBe(400);
  });

  it('POST /v1/triage/emergency-event with invalid sourceVertical returns 400 Bad Request', async () => {
    const invalidPayload = {
      triggerCategory: 'chestPain',
      severityLevel: 4,
      sourceVertical: 'INVALID_VERTICAL',
      clientTimestamp: new Date().toISOString(),
    };

    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/emergency-event',
      payload: invalidPayload,
    });

    expect(res.statusCode).toBe(400);
    const body = JSON.parse(res.payload);
    expect(body.message).toEqual(
      expect.arrayContaining([expect.stringContaining('sourceVertical')]),
    );
  });

  it('POST /v1/triage/emergency-event with invalid timestamp returns 400 Bad Request', async () => {
    const invalidPayload = {
      triggerCategory: 'chestPain',
      severityLevel: 4,
      sourceVertical: 'PHYSICAL',
      clientTimestamp: 'not-a-valid-timestamp',
    };

    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/emergency-event',
      payload: invalidPayload,
    });

    expect(res.statusCode).toBe(400);
  });

  it('POST /v1/triage/emergency-event with Bearer token binds event to authenticated user', async () => {
    const payload = {
      triggerCategory: 'suicidalCrisis',
      severityLevel: 5,
      sourceVertical: 'EMOTIONAL',
      clientTimestamp: new Date().toISOString(),
      actionTaken: 'DIALED_188',
    };

    const res = await app.inject({
      method: 'POST',
      url: '/v1/triage/emergency-event',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload,
    });

    expect(res.statusCode).toBe(201);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);

    const recorded = mockTriageAuditService.recordedEvents.find(
      (e) => e.triggerCategory === 'suicidalCrisis',
    );
    expect(recorded).toBeDefined();
    expect(recorded?.userId).toBe(mockUserId);
  });
});
