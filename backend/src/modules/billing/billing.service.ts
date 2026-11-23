import {
  BadRequestException, ForbiddenException, Inject, Injectable,
  ServiceUnavailableException, UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, timingSafeEqual } from 'node:crypto';
import { eq, sql } from 'drizzle-orm';
import { DatabaseService } from '../../database/database.service';
import { MINUTE_MS, RateLimiter } from '../../common/http/rate-limiter';
import { subscriptions, users } from '../../database/schema';
import { emptySubscription, revenueCatState, SubscriptionStatus } from './revenuecat-state';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const CACHE_MS = 5 * 60_000;

@Injectable()
export class BillingService {
  private readonly limiter = new RateLimiter();
  constructor(
    @Inject(DatabaseService) private readonly database: DatabaseService,
    @Inject(ConfigService) private readonly config: ConfigService,
  ) {}

  private get entitlementId(): string {
    return this.config.get<string>('REVENUECAT_ENTITLEMENT_ID') || 'premium';
  }

  private allowSandbox(userId: string): boolean {
    if (this.config.get('NODE_ENV') !== 'production' && this.config.get('REVENUECAT_ALLOW_SANDBOX') === 'true') {
      return true;
    }
    // Store review/TestFlight/license testers use real platform SDK keys but
    // sandbox receipts. Only these exact server-designated accounts may use
    // sandbox access in production; malformed lists fail closed as a whole.
    const raw = this.config.get<string>('REVENUECAT_SANDBOX_USER_IDS') || '';
    if (!raw.trim()) return false;
    const ids = raw.split(',').map(id => id.trim().toLowerCase());
    return ids.every(id => UUID.test(id)) && ids.includes(userId.toLowerCase());
  }

  private get apiKey(): string | undefined {
    return this.config.get<string>('REVENUECAT_SECRET_API_KEY');
  }

  private status(row: typeof subscriptions.$inferSelect | undefined, userId: string): SubscriptionStatus {
    if (!row || row.entitlementId !== this.entitlementId) return emptySubscription(this.entitlementId);
    const fresh = Date.now() - row.verifiedAt.getTime() < CACHE_MS;
    const environment = row.environment === 'sandbox' || row.environment === 'production' ? row.environment : null;
    return {
      isPremium: row.isPremium && fresh && environment !== null &&
        (environment !== 'sandbox' || this.allowSandbox(userId)) &&
        (!row.expiresAt || row.expiresAt.getTime() > Date.now()),
      entitlementId: row.entitlementId, expiresAt: row.expiresAt?.toISOString() ?? null,
      managementUrl: row.managementUrl, environment, verifiedAt: row.verifiedAt.toISOString(),
    };
  }

  async getSubscription(userId: string): Promise<SubscriptionStatus> {
    if (!this.apiKey) return emptySubscription(this.entitlementId);
    return this.reconcile(userId, false);
  }

  async sync(userId: string): Promise<SubscriptionStatus> {
    this.limiter.hit(`billing:sync:${userId}`, 12, MINUTE_MS);
    return this.reconcile(userId, true);
  }

  async requirePremium(userId: string): Promise<void> {
    if (!(await this.getSubscription(userId)).isPremium) {
      throw new ForbiddenException({ code: 'PREMIUM_REQUIRED', message: 'Uma assinatura Premium ativa é necessária.' });
    }
  }

  private async subscriber(userId: string): Promise<unknown> {
    const apiKey = this.apiKey;
    if (!apiKey) throw new ServiceUnavailableException('Assinaturas indisponíveis.');
    this.limiter.hit(`billing:upstream:${userId}`, 30, MINUTE_MS);
    try {
      const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`, {
        headers: { Authorization: `Bearer ${apiKey}`, Accept: 'application/json' },
        signal: AbortSignal.timeout(4000),
      });
      if (response.status === 404) return { subscriber: { entitlements: {} } };
      if (!response.ok) throw new Error('RevenueCat unavailable');
      return await response.json();
    } catch {
      // No provider bodies, opaque account IDs or credentials in logs/errors.
      throw new ServiceUnavailableException('Não foi possível verificar a assinatura. Tente novamente.');
    }
  }

  private async reconcile(userId: string, force: boolean, webhook = false): Promise<SubscriptionStatus> {
    if (!UUID.test(userId)) throw new BadRequestException('Conta inválida.');
    userId = userId.toLowerCase(); // one database lock and RevenueCat identity per UUID
    if (!this.apiKey) throw new ServiceUnavailableException('Assinaturas indisponíveis.');
    return this.database.withRls(userId, async (tx) => {
      await tx.execute(sql`SET LOCAL lock_timeout = '5s'`);
      // Lock before fetching: a slower earlier request cannot overwrite newer
      // state, even with multiple backend instances. Released on rollback too.
      await tx.execute(sql`SELECT pg_advisory_xact_lock(hashtextextended(${`billing:${userId}`}, 0))`);
      const [user] = await tx.select({ id: users.id }).from(users).where(eq(users.id, userId)).limit(1);
      if (!user) return emptySubscription(this.entitlementId); // deleted/foreign RC identity
      const [existing] = await tx.select().from(subscriptions).where(eq(subscriptions.userId, userId)).limit(1);
      const age = existing ? Date.now() - existing.verifiedAt.getTime() : Infinity;
      // Coalesce active client syncs for five seconds, but never reuse an
      // inactive result after a purchase. Webhooks always re-read.
      if (!webhook && existing?.entitlementId === this.entitlementId &&
        age < (force ? (this.status(existing, userId).isPremium ? 5000 : 0) : CACHE_MS)) {
        return this.status(existing, userId);
      }
      let status: SubscriptionStatus;
      try {
        status = revenueCatState(await this.subscriber(userId), this.entitlementId, this.allowSandbox(userId));
      } catch {
        throw new ServiceUnavailableException('Não foi possível verificar a assinatura. Tente novamente.');
      }
      const values = {
        userId, entitlementId: status.entitlementId, isPremium: status.isPremium,
        expiresAt: status.expiresAt ? new Date(status.expiresAt) : null,
        environment: status.environment, managementUrl: status.managementUrl,
        verifiedAt: new Date(status.verifiedAt!),
      };
      await tx.insert(subscriptions).values(values).onConflictDoUpdate({ target: subscriptions.userId, set: values });
      return status;
    });
  }

  authenticateWebhook(authorization: unknown): void {
    const expected = this.config.get<string>('REVENUECAT_WEBHOOK_AUTHORIZATION');
    if (!expected) throw new ServiceUnavailableException('Webhooks indisponíveis.');
    if (typeof authorization !== 'string' || !timingSafeEqual(
      createHash('sha256').update(authorization).digest(), createHash('sha256').update(expected).digest(),
    )) throw new UnauthorizedException('Autorização inválida.');
  }

  async webhook(authorization: unknown, body: unknown): Promise<{ received: true }> {
    this.authenticateWebhook(authorization);
    const event = (body as any)?.event;
    if (!event || typeof event.id !== 'string' || typeof event.type !== 'string') {
      throw new BadRequestException('Evento inválido.');
    }
    if (event.type === 'TEST') return { received: true };
    const candidates: unknown[] = [event.app_user_id, event.original_app_user_id];
    for (const key of ['aliases', 'transferred_from', 'transferred_to']) {
      if (Array.isArray(event[key])) candidates.push(...event[key]);
    }
    const ids = [...new Set(candidates.filter((id): id is string => typeof id === 'string' && UUID.test(id)).map(id => id.toLowerCase()))];
    if (ids.length > 10) throw new BadRequestException('Muitas contas no evento.');
    // Failed reconciliation is never acknowledged; RevenueCat may retry.
    for (const id of ids) await this.reconcile(id, true, true);
    return { received: true };
  }
}
