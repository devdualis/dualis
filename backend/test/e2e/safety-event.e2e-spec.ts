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
import {
  defaultPrimaryProfileId,
  familyAccessFor,
  stubProfileAccess,
  TEST_PROFILES,
} from './support/profile-access.stub';
import {
  SafetyEventRecord,
  SafetyEventsService,
} from '../../src/modules/safety/safety-events.service';
import { CreateSafetyEventDto } from '../../src/modules/safety/dto/create-safety-event.dto';
import { LegacyEmergencyEventDto } from '../../src/modules/safety/dto/legacy-emergency-event.dto';
import { AuthService } from '../../src/modules/auth/auth.service';

type RecordedEvent = SafetyEventRecord & { userId: string | null };

@Injectable()
class MockSafetyEventsService {
  public recordedEvents: RecordedEvent[] = [];

  async recordSafetyEvent(dto: CreateSafetyEventDto, userId?: string | null, profileId?: string | null) {
    const event: RecordedEvent = {
      id: crypto.randomUUID(),
      action: dto.action,
      channel: dto.channel ?? null,
      clientTimestamp: new Date(dto.clientTimestamp),
      createdAt: new Date(),
      userId: userId ?? null,
      profileId: profileId ?? null,
    };
    this.recordedEvents.push(event);
    const { userId: _userId, ...publicEvent } = event;
    return publicEvent;
  }

  async recordLegacyEmergencyEvent(dto: LegacyEmergencyEventDto, userId?: string | null, profileId?: string | null) {
    return this.recordSafetyEvent(
      { action: 'opened_resources', channel: dto.actionTaken, clientTimestamp: dto.clientTimestamp },
      userId,
      profileId,
    );
  }
}

describe('Safety resource events E2E (POST /v1/journal/safety-event + legacy /v1/triage/emergency-event)', () => {
  let app: NestFastifyApplication;
  let mockService: MockSafetyEventsService;
  let validAccessToken: string;
  let expiredAccessToken: string;
  const mockUserId = '99999999-9999-9999-9999-999999999999';

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(SafetyEventsService)
      .useClass(MockSafetyEventsService)
      .compile();

    stubProfileAccess(moduleRef, familyAccessFor(mockUserId));

    mockService = moduleRef.get<MockSafetyEventsService>(SafetyEventsService);

    const jwtService = moduleRef.get<JwtService>(JwtService);
    validAccessToken = jwtService.sign(
      { sub: mockUserId, email: 'person@example.com', type: 'access' },
      { expiresIn: '15m' },
    );
    expiredAccessToken = jwtService.sign(
      { sub: mockUserId, email: 'person@example.com', type: 'access' },
      { expiresIn: -60 },
    );

    const authService = moduleRef.get<AuthService>(AuthService);
    authService.validateUserById = async (id: string) => ({
      id,
      name: 'Person Test',
      email: 'person@example.com',
      gender: 'unspecified',
      dateOfBirth: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    app = moduleRef.createNestApplication<NestFastifyApplication>(new FastifyAdapter());
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));

    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    if (app) await app.close();
  });

  const safetyPayload = (channel: string, action = 'opened_resources') => ({
    action,
    channel,
    clientTimestamp: new Date().toISOString(),
  });
  const recordedFor = (channel: string) => mockService.recordedEvents.find((e) => e.channel === channel);
  const post = (url: string, payload: object, headers: Record<string, string> = {}) =>
    app.inject({ method: 'POST', url, payload, headers });

  describe('POST /v1/journal/safety-event', () => {
    it('anonymous request returns 201 with no user and no profile', async () => {
      const res = await post('/v1/journal/safety-event', safetyPayload('anonymous'));

      expect(res.statusCode).toBe(201);
      const body = JSON.parse(res.payload);
      expect(body.success).toBe(true);
      expect(body.data).toMatchObject({ action: 'opened_resources', channel: 'anonymous', profileId: null });
      expect(body.data).toHaveProperty('id');
      expect(recordedFor('anonymous')).toMatchObject({ userId: null, profileId: null });
    });

    it('authenticated request without X-Profile-Id is filed on the primary profile', async () => {
      const res = await post('/v1/journal/safety-event', safetyPayload('tel:192', 'call_started'), {
        authorization: `Bearer ${validAccessToken}`,
      });

      expect(res.statusCode).toBe(201);
      expect(recordedFor('tel:192')).toMatchObject({
        action: 'call_started',
        userId: mockUserId,
        profileId: defaultPrimaryProfileId(mockUserId),
      });
    });

    it('expired token (even with X-Profile-Id) is recorded as anonymous with 201', async () => {
      const res = await post('/v1/journal/safety-event', safetyPayload('expired'), {
        authorization: `Bearer ${expiredAccessToken}`,
        'x-profile-id': TEST_PROFILES.dependent,
      });

      expect(res.statusCode).toBe(201);
      expect(recordedFor('expired')).toMatchObject({ userId: null, profileId: null });
    });

    it('dependent X-Profile-Id files the event on the dependent', async () => {
      const res = await post('/v1/journal/safety-event', safetyPayload('dependent'), {
        authorization: `Bearer ${validAccessToken}`,
        'x-profile-id': TEST_PROFILES.dependent,
      });

      expect(res.statusCode).toBe(201);
      expect(recordedFor('dependent')?.profileId).toBe(TEST_PROFILES.dependent);
    });

    it('VIEW_ONLY grant still records (201): reaching help is never blocked by a permission level', async () => {
      const res = await post('/v1/journal/safety-event', safetyPayload('viewOnly'), {
        authorization: `Bearer ${validAccessToken}`,
        'x-profile-id': TEST_PROFILES.sharedViewOnly,
      });

      expect(res.statusCode).toBe(201);
      expect(recordedFor('viewOnly')).toMatchObject({ userId: mockUserId, profileId: TEST_PROFILES.sharedViewOnly });
    });

    it('profile the caller cannot reach returns 403', async () => {
      const res = await post('/v1/journal/safety-event', safetyPayload('foreign'), {
        authorization: `Bearer ${validAccessToken}`,
        'x-profile-id': TEST_PROFILES.foreign,
      });

      expect(res.statusCode).toBe(403);
      expect(recordedFor('foreign')).toBeUndefined();
    });

    it('rejects an unknown action, an invalid timestamp and health fields with 400', async () => {
      const ts = new Date().toISOString();
      expect((await post('/v1/journal/safety-event', { action: 'diagnosed', clientTimestamp: ts })).statusCode).toBe(400);
      expect((await post('/v1/journal/safety-event', { action: 'opened_resources', clientTimestamp: 'nope' })).statusCode).toBe(400);
      expect(
        (await post('/v1/journal/safety-event', { action: 'opened_resources', clientTimestamp: ts, severityLevel: 5 }))
          .statusCode,
      ).toBe(400);
    });
  });

  describe('POST /v1/triage/emergency-event (legacy alias)', () => {
    const legacyPayload = (actionTaken: string) => ({
      triggerCategory: 'chestPain',
      severityLevel: 5,
      sourceVertical: 'PHYSICAL',
      clientTimestamp: new Date().toISOString(),
      actionTaken,
    });

    it('accepts the old body (201) and stores only opened_resources, channel and timestamp', async () => {
      const res = await post('/v1/triage/emergency-event', legacyPayload('DIALED_192'));

      expect(res.statusCode).toBe(201);
      const body = JSON.parse(res.payload);
      expect(body.success).toBe(true);
      expect(body.data).toMatchObject({ action: 'opened_resources', channel: 'DIALED_192' });
      expect(body.data).not.toHaveProperty('severityLevel');
      expect(body.data).not.toHaveProperty('triggerCategory');
    });

    it('never rejects old severity values: they are discarded', async () => {
      const res = await post('/v1/triage/emergency-event', { ...legacyPayload('LEGACY_SEV2'), severityLevel: 2 });

      expect(res.statusCode).toBe(201);
      expect(recordedFor('LEGACY_SEV2')).toMatchObject({ action: 'opened_resources' });
    });

    it('binds an authenticated old-app event to the user and the active profile', async () => {
      const res = await post('/v1/triage/emergency-event', legacyPayload('LEGACY_AUTH'), {
        authorization: `Bearer ${validAccessToken}`,
        'x-profile-id': TEST_PROFILES.dependent,
      });

      expect(res.statusCode).toBe(201);
      expect(recordedFor('LEGACY_AUTH')).toMatchObject({ userId: mockUserId, profileId: TEST_PROFILES.dependent });
    });

    it('expired token is recorded as anonymous with 201', async () => {
      const res = await post('/v1/triage/emergency-event', legacyPayload('LEGACY_EXPIRED'), {
        authorization: `Bearer ${expiredAccessToken}`,
      });

      expect(res.statusCode).toBe(201);
      expect(recordedFor('LEGACY_EXPIRED')).toMatchObject({ userId: null, profileId: null });
    });

    it('invalid timestamp still returns 400', async () => {
      const res = await post('/v1/triage/emergency-event', { ...legacyPayload('LEGACY_BAD'), clientTimestamp: 'x' });

      expect(res.statusCode).toBe(400);
    });
  });
});
