import { HttpException, HttpStatus, Injectable } from '@nestjs/common';

export const MINUTE_MS = 60 * 1000;
export const HOUR_MS = 60 * MINUTE_MS;

/** Most keys kept at once; the oldest are dropped first, so memory stays bounded. */
const MAX_KEYS = 50_000;

/**
 * Counts requests per key in fixed time windows, in memory. Each Cloud Run instance
 * counts on its own (production runs at most 2), which is enough to stop brute force
 * and email spam from a single client. Limits that must hold across instances (codes
 * per account) are enforced in the database instead.
 */
@Injectable()
export class RateLimiter {
  private readonly windows = new Map<string, { count: number; resetsAt: number }>();

  /** Counts one request for `key`; throws 429 once the key went over `limit` in the window. */
  hit(key: string, limit: number, windowMs: number): void {
    const now = Date.now();
    let window = this.windows.get(key);
    if (!window || window.resetsAt <= now) {
      this.windows.delete(key); // re-insert at the end: Map order is age order
      window = { count: 0, resetsAt: now + windowMs };
      this.windows.set(key, window);
      this.evictOldest();
    }
    window.count += 1;
    if (window.count > limit) {
      throw new HttpException(
        'Muitas tentativas em pouco tempo. Aguarde alguns minutos e tente de novo.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private evictOldest(): void {
    for (const key of this.windows.keys()) {
      if (this.windows.size <= MAX_KEYS) return;
      this.windows.delete(key);
    }
  }
}
