import 'reflect-metadata';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ConfigService } from '@nestjs/config';
import { GUARDS_METADATA } from '@nestjs/common/constants';
import { DatabaseService } from '../../src/database/database.service';
import { subscriptions, users } from '../../src/database/schema';
import { BillingService } from '../../src/modules/billing/billing.service';
import { BillingController } from '../../src/modules/billing/billing.controller';
import { ConditionPremiumGuard, PremiumGuard } from '../../src/modules/billing/premium.guard';
import { JwtAuthGuard } from '../../src/modules/auth/guards/jwt-auth.guard';
import { revenueCatState, storeManagementUrl } from '../../src/modules/billing/revenuecat-state';
import { CareController } from '../../src/modules/care/care.controller';
import { ProfilesController } from '../../src/modules/profiles/profiles.controller';

const A = '11111111-1111-4111-8111-111111111111';
const B = '22222222-2222-4222-8222-222222222222';
const now = new Date('2026-11-04T12:00:00Z');
const active = (overrides: Record<string, unknown> = {}, sandbox = false) => ({ subscriber: {
  entitlements: { premium: {
    product_identifier: 'premium_monthly', purchase_date: '2026-11-01T12:00:00Z',
    expires_date: '2026-12-01T12:00:00Z', ...overrides,
  } },
  subscriptions: { premium_monthly: { is_sandbox: sandbox } },
  management_url: 'https://play.google.com/store/account/subscriptions',
} });

describe('RevenueCat trusted entitlement interpretation', () => {
  it('grants current verified production subscriptions with localized-free store metadata', () => {
    expect(revenueCatState(active(), 'premium', false, now)).toMatchObject({
      isPremium: true, environment: 'production', expiresAt: '2026-12-01T12:00:00.000Z',
    });
  });
  it('keeps cancelled subscriptions active until expiry, then removes access', () => {
    const payload = active();
    Object.assign(payload.subscriber.subscriptions.premium_monthly, { unsubscribe_detected_at: now.toISOString() });
    expect(revenueCatState(payload, 'premium', false, now).isPremium).toBe(true);
    expect(revenueCatState(payload, 'premium', false, new Date('2026-12-02')).isPremium).toBe(false);
  });
  it('supports explicitly supplied billing grace periods', () => {
    const payload = active({ expires_date: '2026-11-03T00:00:00Z' });
    Object.assign(payload.subscriber.subscriptions.premium_monthly, { grace_period_expires_date: '2026-11-05T00:00:00Z' });
    expect(revenueCatState(payload, 'premium', false, now).isPremium).toBe(true);
  });
  it('rejects sandbox unless explicitly allowed, and unknown transaction environments', () => {
    expect(revenueCatState(active({}, true), 'premium', false, now).isPremium).toBe(false);
    expect(revenueCatState(active({}, true), 'premium', true, now).isPremium).toBe(true);
    const payload = active();
    delete (payload.subscriber.subscriptions.premium_monthly as any).is_sandbox;
    expect(revenueCatState(payload, 'premium', true, now).isPremium).toBe(false);
  });
  it.each([undefined, 'invalid', 123, ''])('rejects invalid expiration %s', (expires_date) => {
    expect(revenueCatState(active({ expires_date }), 'premium', true, now).isPremium).toBe(false);
  });
  it('supports a verified lifetime entitlement, but not an unidentified product', () => {
    expect(revenueCatState(active({ expires_date: null }), 'premium', false, now).isPremium).toBe(true);
    expect(revenueCatState(active({ product_identifier: 'unknown' }), 'premium', false, now).isPremium).toBe(false);
  });
  it('treats removed/refunded entitlements as inactive and malformed API responses as failures', () => {
    expect(revenueCatState({ subscriber: { entitlements: {} } }, 'premium', false, now).isPremium).toBe(false);
    expect(() => revenueCatState({ isPremium: true }, 'premium', false, now)).toThrow();
  });
  it.each(['https://example.com/pay', 'javascript:alert(1)', 'https://play.google.com.attacker.test/', 'http://apps.apple.com/x'])('rejects unsafe management URL %s', (url) => {
    expect(storeManagementUrl(url)).toBeNull();
  });
});

describe('Billing service', () => {
  let config: Record<string, string>;
  let rows: Map<string, any>;
  let accounts: Set<string>;
  let service: BillingService;
  let fetchMock: ReturnType<typeof vi.fn>;
  let lockCalls: unknown[];
  let writes: number;
  const scopes: string[] = [];

  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(now);
    rows = new Map(); accounts = new Set([A, B]); lockCalls = []; writes = 0; scopes.length = 0;
    config = { REVENUECAT_SECRET_API_KEY: 'sk_test_backend_only', REVENUECAT_WEBHOOK_AUTHORIZATION: 'Bearer webhook-secret', NODE_ENV: 'development' };
    fetchMock = vi.fn(async () => ({ ok: true, status: 200, json: async () => active() }));
    vi.stubGlobal('fetch', fetchMock);
    const locks = new Map<string, Promise<void>>();
    const database = { withRls: async (userId: string, callback: (tx: any) => Promise<unknown>) => {
      scopes.push(userId);
      let release: (() => void) | undefined;
      const tx = {
        execute: async (query: any) => {
          if (JSON.stringify(query).includes('pg_advisory_xact_lock')) {
            lockCalls.push(query);
            const previous = locks.get(userId) ?? Promise.resolve();
            const current = new Promise<void>(resolve => { release = resolve; });
            locks.set(userId, previous.then(() => current));
            await previous;
          }
        },
        select: () => ({ from: (table: unknown) => ({ where: () => ({ limit: async () =>
          table === users ? accounts.has(userId) ? [{ id: userId }] : [] : rows.has(userId) ? [rows.get(userId)] : [],
        }) }) }),
        insert: (table: unknown) => {
          expect(table).toBe(subscriptions);
          return { values: (value: unknown) => ({ onConflictDoUpdate: async () => { rows.set(userId, value); writes++; } }) };
        },
      };
      try { return await callback(tx); } finally { release?.(); }
    } };
    service = new BillingService(database as unknown as DatabaseService, { get: (key: string) => config[key] } as ConfigService);
  });
  afterEach(() => { vi.useRealTimers(); vi.unstubAllGlobals(); });

  it('uses authenticated own-account IDs in all API reads and persistence scopes', async () => {
    const controller = new BillingController(service);
    expect((await controller.sync({ user: { id: A }, body: { userId: B, isPremium: true }, headers: { 'x-profile-id': B } })).isPremium).toBe(true);
    expect(fetchMock.mock.calls[0][0]).toBe(`https://api.revenuecat.com/v1/subscribers/${A}`);
    expect(scopes).toEqual([A]); expect(rows.has(B)).toBe(false);
  });
  it('marks both user endpoints JWT guarded and leaves webhook authenticated separately', () => {
    expect(Reflect.getMetadata(GUARDS_METADATA, BillingController.prototype.status)).toContain(JwtAuthGuard);
    expect(Reflect.getMetadata(GUARDS_METADATA, BillingController.prototype.sync)).toContain(JwtAuthGuard);
    expect(Reflect.getMetadata(GUARDS_METADATA, BillingController.prototype.webhook)).toBeUndefined();
  });
  it('fails closed when configuration is missing', async () => {
    delete config.REVENUECAT_SECRET_API_KEY;
    expect((await service.getSubscription(A)).isPremium).toBe(false);
    await expect(service.sync(A)).rejects.toMatchObject({ status: 503 });
    await expect(service.requirePremium(A)).rejects.toMatchObject({ status: 403 });
    delete config.REVENUECAT_WEBHOOK_AUTHORIZATION;
    await expect(service.webhook(undefined, {})).rejects.toMatchObject({ status: 503 });
    expect(fetchMock).not.toHaveBeenCalled();
  });
  it('rejects unauthenticated/forged webhooks before any account lookup', async () => {
    for (const header of [undefined, '', 'Bearer wrong']) {
      await expect(service.webhook(header, { event: { id: 'e', type: 'RENEWAL', app_user_id: A } })).rejects.toMatchObject({ status: 401 });
    }
    expect(fetchMock).not.toHaveBeenCalled(); expect(scopes).toEqual([]);
  });
  it('allows the dashboard TEST webhook without granting access', async () => {
    expect(await service.webhook('Bearer webhook-secret', { event: { id: 'test', type: 'TEST' } })).toEqual({ received: true });
    expect(fetchMock).not.toHaveBeenCalled();
  });
  it('rejects malformed webhook events', async () => {
    await expect(service.webhook('Bearer webhook-secret', { event: { type: 'RENEWAL', app_user_id: A } })).rejects.toMatchObject({ status: 400 });
  });
  it('reconciles transfer source and destination, ignores anonymous IDs and revokes old access', async () => {
    await service.sync(A);
    fetchMock.mockImplementation(async (url: string) => ({ ok: true, status: 200, json: async () => url.endsWith(A) ? { subscriber: { entitlements: {} } } : active() }));
    await service.webhook('Bearer webhook-secret', { event: { id: 'transfer', type: 'TRANSFER', transferred_from: [A, '$RCAnonymousID:test'], transferred_to: [B] } });
    expect(rows.get(A).isPremium).toBe(false); expect(rows.get(B).isPremium).toBe(true);
  });
  it('duplicate/out-of-order events re-read authoritative state instead of applying old payloads', async () => {
    await service.sync(A);
    fetchMock.mockImplementation(async () => ({ ok: true, status: 200, json: async () => ({ subscriber: { entitlements: {} } }) }));
    const oldEvent = { event: { id: 'old', type: 'INITIAL_PURCHASE', app_user_id: A, expiration_at_ms: Date.now() + 9999999 } };
    await service.webhook('Bearer webhook-secret', oldEvent);
    await service.webhook('Bearer webhook-secret', oldEvent);
    expect(rows.get(A).isPremium).toBe(false); expect(fetchMock).toHaveBeenCalledTimes(3);
  });
  it('coalesces concurrent client syncs after acquiring the per-account transaction lock', async () => {
    const results = await Promise.all([service.sync(A), service.sync(A), service.sync(A)]);
    expect(results.every(result => result.isPremium)).toBe(true);
    expect(lockCalls).toHaveLength(3); expect(fetchMock).toHaveBeenCalledTimes(1); expect(writes).toBe(1);
  });
  it('does not cache inactive access across a successful purchase and immediate sync', async () => {
    fetchMock.mockResolvedValueOnce({ ok: true, status: 200, json: async () => ({ subscriber: { entitlements: {} } }) });
    expect((await service.sync(A)).isPremium).toBe(false);
    expect((await service.sync(A)).isPremium).toBe(true);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
  it('bounds explicit sync frequency even when the provider returns no entitlement', async () => {
    fetchMock.mockResolvedValue({ ok: true, status: 200, json: async () => ({ subscriber: { entitlements: {} } }) });
    for (let i = 0; i < 12; i++) await service.sync(A);
    await expect(service.sync(A)).rejects.toMatchObject({ status: 429 });
    expect(fetchMock).toHaveBeenCalledTimes(12);
  });
  it('requires Premium for new condition tracking/readings while preserving ordinary entries and tracking disable', async () => {
    const billing = { requirePremium: vi.fn().mockRejectedValue(new Error('premium required')) };
    const guard = new ConditionPremiumGuard(billing as any);
    const context = (body: unknown): any => ({ switchToHttp: () => ({ getRequest: () => ({ user: { id: A }, body }) }) });
    expect(await guard.canActivate(context({ label: 'Example' }))).toBe(true);
    expect(await guard.canActivate(context({ tracking: [], items: [{ kind: 'condition' }] }))).toBe(true);
    expect(billing.requirePremium).not.toHaveBeenCalled();
    await expect(guard.canActivate(context({ tracking: ['blood_pressure'] }))).rejects.toThrow('premium required');
    await expect(guard.canActivate(context({ items: [{ readings: [{ value: 120 }] }] }))).rejects.toThrow('premium required');
    expect(billing.requirePremium).toHaveBeenLastCalledWith(A);
  });
  it('rejects sandbox access in production even when explicitly enabled', async () => {
    config.NODE_ENV = 'production'; config.REVENUECAT_ALLOW_SANDBOX = 'true';
    fetchMock.mockImplementation(async () => ({ ok: true, status: 200, json: async () => active({}, true) }));
    expect((await service.sync(A)).isPremium).toBe(false);
  });
  it('permits sandbox in production only for explicitly allowlisted review accounts', async () => {
    config.NODE_ENV = 'production'; config.REVENUECAT_SANDBOX_USER_IDS = A;
    fetchMock.mockImplementation(async () => ({ ok: true, status: 200, json: async () => active({}, true) }));
    expect((await service.sync(A)).isPremium).toBe(true);
    expect((await service.sync(B)).isPremium).toBe(false);
  });
  it.each(['', '   ', '*', 'not-a-uuid', `${A},*`, `${A},invalid`, `${A},`])('rejects empty or malformed production sandbox allowlist %s', async (allowlist) => {
    config.NODE_ENV = 'production'; config.REVENUECAT_ALLOW_SANDBOX = 'true';
    config.REVENUECAT_SANDBOX_USER_IDS = allowlist;
    fetchMock.mockImplementation(async () => ({ ok: true, status: 200, json: async () => active({}, true) }));
    expect((await service.sync(A)).isPremium).toBe(false);
  });
  it('normalizes allowlisted UUID casing and surrounding whitespace', async () => {
    const id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'; accounts.add(id);
    config.NODE_ENV = 'production'; config.REVENUECAT_SANDBOX_USER_IDS = `  ${id.toUpperCase()} , ${B} `;
    fetchMock.mockImplementation(async () => ({ ok: true, status: 200, json: async () => active({}, true) }));
    expect((await service.sync(id.toUpperCase())).isPremium).toBe(true);
    expect(fetchMock.mock.calls[0][0]).toBe(`https://api.revenuecat.com/v1/subscribers/${id}`);
  });
  it('revokes cached sandbox access immediately when an account leaves the allowlist', async () => {
    config.NODE_ENV = 'production'; config.REVENUECAT_SANDBOX_USER_IDS = A;
    fetchMock.mockImplementation(async () => ({ ok: true, status: 200, json: async () => active({}, true) }));
    expect((await service.sync(A)).isPremium).toBe(true);
    config.REVENUECAT_SANDBOX_USER_IDS = B;
    expect((await service.getSubscription(A)).isPremium).toBe(false);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
  it('expires cached access and refuses stale state during an upstream failure', async () => {
    await service.sync(A);
    vi.setSystemTime(new Date(now.getTime() + 5 * 60_000 + 1));
    fetchMock.mockRejectedValue(new Error('upstream body with secret should not escape'));
    await expect(service.getSubscription(A)).rejects.toMatchObject({ status: 503 });
    await expect(service.requirePremium(A)).rejects.toMatchObject({ status: 503 });
  });
  it('returns retryable failure instead of acknowledging an unapplied webhook', async () => {
    fetchMock.mockRejectedValue(new Error('timeout'));
    await expect(service.webhook('Bearer webhook-secret', { event: { id: 'e', type: 'RENEWAL', app_user_id: A } })).rejects.toMatchObject({ status: 503 });
    expect(writes).toBe(0);
  });
  it('does not recreate deleted/unknown accounts from RevenueCat events', async () => {
    accounts.delete(A);
    await service.webhook('Bearer webhook-secret', { event: { id: 'e', type: 'RENEWAL', app_user_id: A } });
    expect(fetchMock).not.toHaveBeenCalled(); expect(writes).toBe(0);
  });
  it('treats RevenueCat 404 as no entitlement and rejects malformed successful responses', async () => {
    fetchMock.mockResolvedValue({ status: 404 });
    expect((await service.sync(A)).isPremium).toBe(false);
    vi.setSystemTime(new Date(now.getTime() + 6000));
    fetchMock.mockResolvedValue({ ok: true, status: 200, json: async () => ({ isPremium: true }) });
    await expect(service.sync(A)).rejects.toMatchObject({ status: 503 });
  });
  it('guards paid writes while leaving old-data reads/deletes and owner profile management accessible', () => {
    for (const key of ['create', 'update', 'upload', 'review', 'reprocess', 'logIntake']) {
      expect(Reflect.getMetadata(GUARDS_METADATA, (CareController.prototype as any)[key])).toContain(PremiumGuard);
    }
    for (const key of ['list', 'getDocument', 'getDocumentFile', 'remove', 'removeDocument']) {
      expect(Reflect.getMetadata(GUARDS_METADATA, (CareController.prototype as any)[key])).toBeUndefined();
    }
    expect(Reflect.getMetadata(GUARDS_METADATA, ProfilesController.prototype.createDependent)).toContain(PremiumGuard);
    expect(Reflect.getMetadata(GUARDS_METADATA, ProfilesController.prototype.updateProfile)).toBeUndefined();
  });
});
