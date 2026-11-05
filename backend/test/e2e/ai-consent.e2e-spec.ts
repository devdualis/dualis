import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { ConflictException, Injectable, ValidationPipe, VersioningType } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../../src/app.module';
import { familyAccessFor, stubProfileAccess, TEST_PROFILES } from './support/profile-access.stub';
import { AuthService } from '../../src/modules/auth/auth.service';
import { GeminiService } from '../../src/common/ai/gemini.service';
import {
  AI_CONSENT_PURPOSE,
  AI_CONSENT_REQUIRED,
  AI_CONSENT_VERSION_MISMATCH,
  AI_PROCESSING_CONSENT_VERSION,
  AI_PROFILE_NOT_ALLOWED,
  AiConsentService,
  aiConsentRequiredError,
  aiProfileNotAllowedError,
} from '../../src/modules/consents/ai-consent.service';
import { ProfileContext } from '../../src/modules/profiles/profile-context';

/** In-memory stand-in: one status per user, the real exported error factories. */
@Injectable()
class MemoryAiConsentService {
  granted = new Map<string, string>();

  async status(userId: string) {
    const grantedAt = this.granted.get(userId) ?? null;
    return {
      purpose: AI_CONSENT_PURPOSE,
      granted: grantedAt !== null,
      version: grantedAt ? AI_PROCESSING_CONSENT_VERSION : null,
      currentVersion: AI_PROCESSING_CONSENT_VERSION,
      grantedAt,
    };
  }

  async grant(userId: string, version: string) {
    if (version !== AI_PROCESSING_CONSENT_VERSION) {
      throw new ConflictException({ statusCode: 409, error: 'Conflict', code: AI_CONSENT_VERSION_MISMATCH, message: 'Versão diferente.' });
    }
    if (!this.granted.has(userId)) this.granted.set(userId, new Date().toISOString());
    return this.status(userId);
  }

  async revoke(userId: string) {
    this.granted.delete(userId);
    return this.status(userId);
  }

  async assertAllowed(userId: string, profile: ProfileContext) {
    if (profile.accessLevel !== 'OWNER') throw aiProfileNotAllowedError();
    if (!this.granted.has(userId)) throw aiConsentRequiredError();
  }
}

describe('AI-processing consent E2E (/v1/consents/ai-processing, gate on /v1/journal/suggest-option)', () => {
  const mockUserId = 'b0000000-0000-0000-0000-0000000000c7';
  const gemini = {
    isAvailable: true,
    generateJson: vi.fn().mockResolvedValue({ optionKey: 'futuro.medo.desanimo' }),
  };
  let app: NestFastifyApplication;
  let consents: MemoryAiConsentService;
  let validToken: string;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(AiConsentService)
      .useClass(MemoryAiConsentService)
      .overrideProvider(GeminiService)
      .useValue(gemini)
      .compile();

    stubProfileAccess(moduleRef, familyAccessFor(mockUserId));

    app = moduleRef.createNestApplication<NestFastifyApplication>(new FastifyAdapter());
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    consents = moduleRef.get(AiConsentService) as unknown as MemoryAiConsentService;
    validToken = moduleRef.get(JwtService).sign(
      { sub: mockUserId, email: 'ai-consent@dualis.com.br', type: 'access' },
      { expiresIn: '15m' },
    );
    const authService = moduleRef.get(AuthService);
    authService.validateUserById = async (id: string) =>
      ({ id, name: 'Consent', email: 'ai-consent@dualis.com.br', gender: 'unspecified', dateOfBirth: null, createdAt: new Date(), updatedAt: new Date() }) as any;
  });

  afterAll(async () => {
    if (app) await app.close();
  });

  beforeEach(() => {
    gemini.generateJson.mockClear();
  });

  const auth = (profileId?: string) => ({
    authorization: `Bearer ${validToken}`,
    ...(profileId ? { 'x-profile-id': profileId } : {}),
  });
  const request = (method: 'GET' | 'POST' | 'DELETE', url: string, payload?: unknown, profileId?: string) =>
    app.inject({ method, url, headers: auth(profileId), ...(payload !== undefined ? { payload: payload as any } : {}) });
  const suggest = (payload: unknown, profileId?: string) => request('POST', '/v1/journal/suggest-option', payload, profileId);

  it('GET without a token answers 401', async () => {
    const res = await app.inject({ method: 'GET', url: '/v1/consents/ai-processing' });
    expect(res.statusCode).toBe(401);
  });

  it('reads, validates, grants and revokes the consent', async () => {
    const initial = await request('GET', '/v1/consents/ai-processing');
    expect(initial.statusCode, initial.body).toBe(200);
    expect(initial.json()).toMatchObject({ purpose: AI_CONSENT_PURPOSE, granted: false, currentVersion: '2026.1' });

    expect((await request('POST', '/v1/consents/ai-processing', {})).statusCode).toBe(400);
    expect((await request('POST', '/v1/consents/ai-processing', { version: AI_PROCESSING_CONSENT_VERSION, extra: true })).statusCode).toBe(400);

    const stale = await request('POST', '/v1/consents/ai-processing', { version: '2025.1' });
    expect(stale.statusCode).toBe(409);
    expect(stale.json().code).toBe(AI_CONSENT_VERSION_MISMATCH);

    const granted = await request('POST', '/v1/consents/ai-processing', { version: AI_PROCESSING_CONSENT_VERSION });
    expect(granted.statusCode, granted.body).toBe(200);
    expect(granted.json()).toMatchObject({ granted: true, version: AI_PROCESSING_CONSENT_VERSION });

    const revoked = await request('DELETE', '/v1/consents/ai-processing');
    expect(revoked.statusCode, revoked.body).toBe(200);
    expect(revoked.json()).toMatchObject({ granted: false });
  });

  it('suggest-option without consent answers 403 AI_CONSENT_REQUIRED and never calls the AI provider', async () => {
    consents.granted.clear();
    const res = await suggest({ text: 'ando sem ânimo com tudo', kind: 'emotional' });
    expect(res.statusCode, res.body).toBe(403);
    expect(res.json().code).toBe(AI_CONSENT_REQUIRED);
    expect(gemini.generateJson).not.toHaveBeenCalled();
  });

  it('suggest-option with consent answers 200 with the suggested option', async () => {
    await consents.grant(mockUserId, AI_PROCESSING_CONSENT_VERSION);
    const res = await suggest({ text: 'ando sem ânimo com tudo', kind: 'emotional' });
    expect(res.statusCode, res.body).toBe(200);
    expect(res.json()).toEqual({ optionKey: 'futuro.medo.desanimo' });
    expect(gemini.generateJson).toHaveBeenCalledTimes(1);

    // A dependent the holder manages is covered by the holder's consent.
    const dependent = await suggest({ text: 'ando sem ânimo com tudo', kind: 'emotional' }, TEST_PROFILES.dependent);
    expect(dependent.statusCode, dependent.body).toBe(200);
  });

  it('suggest-option on a profile shared by another account answers 403 AI_PROFILE_NOT_ALLOWED', async () => {
    await consents.grant(mockUserId, AI_PROCESSING_CONSENT_VERSION);
    const res = await suggest({ text: 'ando sem ânimo com tudo', kind: 'emotional' }, TEST_PROFILES.sharedCoManage);
    expect(res.statusCode, res.body).toBe(403);
    expect(res.json().code).toBe(AI_PROFILE_NOT_ALLOWED);
    expect(gemini.generateJson).not.toHaveBeenCalled();
  });

  it('an invalid body still answers 400 before the consent check', async () => {
    consents.granted.clear();
    const res = await suggest({ text: 'um dia bom', kind: 'positive' });
    expect(res.statusCode).toBe(400);
    expect(gemini.generateJson).not.toHaveBeenCalled();
  });
});
