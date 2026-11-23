export interface SubscriptionStatus {
  isPremium: boolean;
  entitlementId: string;
  expiresAt: string | null;
  managementUrl: string | null;
  environment: 'sandbox' | 'production' | null;
  verifiedAt: string | null;
}

export const emptySubscription = (entitlementId: string): SubscriptionStatus => ({
  isPremium: false, entitlementId, expiresAt: null, managementUrl: null,
  environment: null, verifiedAt: null,
});

const object = (value: unknown): value is Record<string, any> =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

export function storeManagementUrl(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && !url.username && !url.password &&
      ['apps.apple.com', 'play.google.com'].includes(url.hostname) ? url.toString() : null;
  } catch { return null; }
}

/** Interpret trusted GET /subscribers state, never webhook/client assertions. */
export function revenueCatState(
  payload: unknown, entitlementId: string, allowSandbox: boolean, now = new Date(),
): SubscriptionStatus {
  const inactive = { ...emptySubscription(entitlementId), verifiedAt: now.toISOString() };
  if (!object(payload) || !object(payload.subscriber) || !object(payload.subscriber.entitlements)) {
    throw new Error('Invalid RevenueCat subscriber response');
  }
  const subscriber = payload.subscriber;
  const entitlement = subscriber.entitlements[entitlementId];
  if (!object(entitlement)) return inactive;
  const product = entitlement.product_identifier;
  if (typeof product !== 'string' || !product) return inactive;
  const subscription = object(subscriber.subscriptions) ? subscriber.subscriptions[product] : null;
  const purchases = object(subscriber.non_subscriptions) ? subscriber.non_subscriptions[product] : null;
  const transaction = object(subscription) ? subscription :
    Array.isArray(purchases) ? [...purchases].reverse().find((p: unknown) => object(p) && typeof p.is_sandbox === 'boolean') : null;
  // Unknown transaction environment cannot grant access, even in development.
  if (!object(transaction) || typeof transaction.is_sandbox !== 'boolean') return inactive;
  const environment = transaction.is_sandbox ? 'sandbox' : 'production';
  if (environment === 'sandbox' && !allowSandbox) return inactive;
  const expiration = entitlement.expires_date;
  if (expiration !== null && (typeof expiration !== 'string' || !Number.isFinite(Date.parse(expiration)))) return inactive;
  if (typeof entitlement.purchase_date !== 'string' || !Number.isFinite(Date.parse(entitlement.purchase_date))) return inactive;
  let expiresAt = expiration === null ? null : new Date(expiration);
  // RevenueCat continues access during a store-provided billing grace period.
  const grace = transaction.grace_period_expires_date;
  if (expiresAt && typeof grace === 'string' && Number.isFinite(Date.parse(grace)) && Date.parse(grace) > expiresAt.getTime()) {
    expiresAt = new Date(grace);
  }
  return {
    isPremium: !expiresAt || expiresAt.getTime() > now.getTime(), entitlementId,
    expiresAt: expiresAt?.toISOString() ?? null,
    managementUrl: storeManagementUrl(subscriber.management_url), environment,
    verifiedAt: now.toISOString(),
  };
}
