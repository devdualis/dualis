import type { ConfigService } from '@nestjs/config';

/**
 * Secret that signs and verifies access and refresh tokens. There is no default:
 * this repository is public, so a fallback secret would let anyone sign a session.
 */
export function jwtSecret(config?: ConfigService): string {
  const secret = config?.get<string>('JWT_SECRET') || process.env.JWT_SECRET;
  if (!secret || secret.length < 32) {
    throw new Error('JWT_SECRET must be set to at least 32 characters.');
  }
  return secret;
}
