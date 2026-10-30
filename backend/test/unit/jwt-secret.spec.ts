import { afterEach, describe, expect, it, vi } from 'vitest';
import { ConfigService } from '@nestjs/config';
import { jwtSecret } from '../../src/modules/auth/jwt-secret';

describe('jwtSecret (no public fallback secret)', () => {
  afterEach(() => vi.unstubAllEnvs());

  it('returns the configured secret', () => {
    const secret = 'a'.repeat(48);
    expect(jwtSecret(new ConfigService({ JWT_SECRET: secret }))).toBe(secret);
  });

  it('refuses to start without JWT_SECRET', () => {
    vi.stubEnv('JWT_SECRET', '');
    expect(() => jwtSecret(new ConfigService({}))).toThrow('JWT_SECRET');
  });

  it('refuses a secret shorter than 32 characters', () => {
    expect(() => jwtSecret(new ConfigService({ JWT_SECRET: 'short-secret' }))).toThrow('JWT_SECRET');
  });
});
