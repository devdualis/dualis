import { afterEach, describe, expect, it, vi } from 'vitest';
import { SHARE_CATEGORIES } from '../../src/database/schema/shared-access-grants.schema';
import {
  AI_CONSENT_PURPOSE,
  AI_CONSENT_REQUIRED,
  AI_CONSENT_VERSION_MISMATCH,
  AI_PROCESSING_CONSENT_VERSION,
  AI_PROFILE_NOT_ALLOWED,
  AiConsentService,
  AiConsentStatusDto,
} from '../../src/modules/consents/ai-consent.service';
import { ProfileContext } from '../../src/modules/profiles/profile-context';

const USER = '11111111-1111-4111-8111-111111111111';
const RAW_IP = '198.51.100.23';

/** Drizzle-like transaction: select chains resolve to `active`; insert records its values. */
function fakeTx(active: any[] = []) {
  const inserted: any[] = [];
  const tx = {
    select: () => ({ from: () => ({ where: () => ({ limit: async () => active }) }) }),
    update: vi.fn(() => ({ set: () => ({ where: async () => ({ rowCount: active.length }) }) })),
    insert: () => ({
      values: (values: any) => {
        inserted.push(values);
        return { returning: async () => [{ id: 'row-1', grantedAt: new Date('2026-11-05T12:00:00Z'), revokedAt: null, ...values }] };
      },
    }),
  };
  return { tx, inserted };
}

function build(active: any[] = []) {
  const { tx, inserted } = fakeTx(active);
  const database = { withRls: vi.fn(async (_userId: string, callback: (t: any) => Promise<any>) => callback(tx)) };
  const encryption = { hashIp: vi.fn((ip: string) => `hmac-of-${ip.length}`.padEnd(64, '0')) };
  const service = new AiConsentService(database as any, encryption as any);
  return { service, database, encryption, inserted, tx };
}

const profile = (accessLevel: ProfileContext['accessLevel']): ProfileContext => ({
  profileId: '22222222-2222-4222-8222-222222222222',
  accessLevel,
  readableCategories: [...SHARE_CATEGORIES],
  writableCategories: accessLevel === 'VIEW_ONLY' ? [] : [...SHARE_CATEGORIES],
});

const status = (granted: boolean): AiConsentStatusDto => ({
  purpose: AI_CONSENT_PURPOSE,
  granted,
  version: granted ? AI_PROCESSING_CONSENT_VERSION : null,
  currentVersion: AI_PROCESSING_CONSENT_VERSION,
  grantedAt: granted ? '2026-11-05T12:00:00.000Z' : null,
});

const codeOf = (error: any) => error?.getResponse?.()?.code;

describe('AiConsentService', () => {
  afterEach(() => {
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
  });

  it('grant with another version answers 409 AI_CONSENT_VERSION_MISMATCH before any query', async () => {
    const { service, database } = build();
    const error = await service.grant(USER, '2025.1', RAW_IP, 'ua').catch((e) => e);
    expect(error.getStatus()).toBe(409);
    expect(codeOf(error)).toBe(AI_CONSENT_VERSION_MISMATCH);
    expect(database.withRls).not.toHaveBeenCalled();
  });

  it('grant stores the HMAC of the IP from EncryptionService.hashIp, never the raw IP', async () => {
    const { service, encryption, inserted } = build();
    const result = await service.grant(USER, AI_PROCESSING_CONSENT_VERSION, RAW_IP, 'u'.repeat(400));
    expect(encryption.hashIp).toHaveBeenCalledWith(RAW_IP);
    expect(inserted).toHaveLength(1);
    expect(inserted[0].ipAddressHash).toBe(encryption.hashIp.mock.results[0].value);
    expect(JSON.stringify(inserted[0])).not.toContain(RAW_IP);
    expect(inserted[0].userAgent).toHaveLength(255);
    expect(inserted[0]).toMatchObject({ userId: USER, purpose: AI_CONSENT_PURPOSE, consentVersion: AI_PROCESSING_CONSENT_VERSION });
    expect(result).toMatchObject({ granted: true, version: AI_PROCESSING_CONSENT_VERSION });
  });

  it('grant is idempotent when the current version is already active', async () => {
    const { service, inserted, tx } = build([
      { id: 'row-0', consentVersion: AI_PROCESSING_CONSENT_VERSION, grantedAt: new Date('2026-11-01T00:00:00Z'), revokedAt: null },
    ]);
    const result = await service.grant(USER, AI_PROCESSING_CONSENT_VERSION, RAW_IP);
    expect(inserted).toHaveLength(0);
    expect(tx.update).not.toHaveBeenCalled();
    expect(result.grantedAt).toBe('2026-11-01T00:00:00.000Z');
  });

  it('an active row of an older version does not count and is closed on the next grant', async () => {
    const { service, inserted, tx } = build([{ id: 'row-0', consentVersion: '2025.1', grantedAt: new Date(), revokedAt: null }]);
    expect(await service.status(USER)).toMatchObject({ granted: false, version: '2025.1' });
    await service.grant(USER, AI_PROCESSING_CONSENT_VERSION, RAW_IP);
    expect(tx.update).toHaveBeenCalledTimes(1);
    expect(inserted).toHaveLength(1);
  });

  it('the consent version is a code constant: legal env overrides do not change it', async () => {
    vi.stubEnv('DISCLAIMER_VERSION', '9999.1');
    vi.stubEnv('PRIVACY_VERSION', '9999.2');
    vi.stubEnv('TERMS_VERSION', '9999.3');
    vi.resetModules();
    const fresh = await import('../../src/modules/consents/ai-consent.service');
    expect(fresh.AI_PROCESSING_CONSENT_VERSION).toBe('2026.1');
    expect(AI_PROCESSING_CONSENT_VERSION).toBe('2026.1');
  });

  it.each(['CO_MANAGE', 'VIEW_ONLY'] as const)('assertAllowed refuses a %s profile with AI_PROFILE_NOT_ALLOWED even with consent', async (level) => {
    const { service } = build();
    vi.spyOn(service, 'status').mockResolvedValue(status(true));
    const error = await service.assertAllowed(USER, profile(level)).catch((e) => e);
    expect(error.getStatus()).toBe(403);
    expect(codeOf(error)).toBe(AI_PROFILE_NOT_ALLOWED);
  });

  it('assertAllowed refuses an OWNER without consent with AI_CONSENT_REQUIRED', async () => {
    const { service } = build();
    vi.spyOn(service, 'status').mockResolvedValue(status(false));
    const error = await service.assertAllowed(USER, profile('OWNER')).catch((e) => e);
    expect(error.getStatus()).toBe(403);
    expect(codeOf(error)).toBe(AI_CONSENT_REQUIRED);
    expect(error.getResponse()).toMatchObject({ statusCode: 403, error: 'Forbidden' });
  });

  it('assertAllowed resolves for an OWNER with consent', async () => {
    const { service } = build();
    vi.spyOn(service, 'status').mockResolvedValue(status(true));
    await expect(service.assertAllowed(USER, profile('OWNER'))).resolves.toBeUndefined();
  });
});
