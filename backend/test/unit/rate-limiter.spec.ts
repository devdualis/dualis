import { describe, it, expect, vi, afterEach } from 'vitest';
import { HttpException, HttpStatus } from '@nestjs/common';
import { MINUTE_MS, RateLimiter } from '../../src/common/http/rate-limiter';

describe('RateLimiter', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  const statusOf = (fn: () => void): number | undefined => {
    try {
      fn();
      return undefined;
    } catch (err) {
      return (err as HttpException).getStatus();
    }
  };

  it('allows up to the limit in a window and answers 429 after that', () => {
    const limiter = new RateLimiter();
    for (let i = 0; i < 3; i++) limiter.hit('login:ip:203.0.113.7', 3, MINUTE_MS);

    expect(statusOf(() => limiter.hit('login:ip:203.0.113.7', 3, MINUTE_MS))).toBe(HttpStatus.TOO_MANY_REQUESTS);
  });

  it('counts each key on its own', () => {
    const limiter = new RateLimiter();
    limiter.hit('login:email:ana@example.com', 1, MINUTE_MS);

    expect(statusOf(() => limiter.hit('login:email:bruno@example.com', 1, MINUTE_MS))).toBeUndefined();
    expect(statusOf(() => limiter.hit('login:email:ana@example.com', 1, MINUTE_MS))).toBe(429);
  });

  it('starts a new window once the old one is over', () => {
    vi.useFakeTimers();
    const limiter = new RateLimiter();
    limiter.hit('reset-password:ip:203.0.113.7', 1, MINUTE_MS);
    expect(statusOf(() => limiter.hit('reset-password:ip:203.0.113.7', 1, MINUTE_MS))).toBe(429);

    vi.advanceTimersByTime(MINUTE_MS);

    expect(statusOf(() => limiter.hit('reset-password:ip:203.0.113.7', 1, MINUTE_MS))).toBeUndefined();
  });

  it('keeps at most 50,000 keys, dropping the oldest', () => {
    const limiter = new RateLimiter();
    limiter.hit('oldest', 1, MINUTE_MS);
    for (let i = 0; i < 50_000; i++) limiter.hit(`key-${i}`, 1, MINUTE_MS);

    expect((limiter as any).windows.size).toBe(50_000);
    expect(statusOf(() => limiter.hit('oldest', 1, MINUTE_MS))).toBeUndefined(); // forgotten: counts from zero
  });
});
