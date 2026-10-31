import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import { JwtService } from '@nestjs/jwt';
import { readdirSync, readFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';
import { join } from 'node:path';
import * as schema from '../../src/database/schema';
import { EncryptionService } from '../../src/common/encryption/encryption.service';
import { EmailService } from '../../src/common/email/email.service';
import { AuthService } from '../../src/modules/auth/auth.service';

const MIGRATIONS_DIR = join(__dirname, '../../src/database/migrations');
const APP_ROLE = 'dualis_auth_app';
const APP_PASSWORD = 'dualis_auth_app';
const PASSWORD = 'SenhaForte123!';
/** Codes run from 100000 to 999999, so this one never matches. */
const WRONG_CODE = '000000';

/**
 * Verification and reset codes, and sessions, through the real AuthService connected as a
 * LOGIN role without SUPERUSER or BYPASSRLS: attempts are counted atomically, an account gets
 * at most 5 codes a day, a code works once, and a password reset ends existing sessions.
 */
describe('Security Regression: auth codes and sessions', () => {
  let adminPool: Pool;
  let appPool: Pool;
  let auth: AuthService;
  let email: EmailService;
  let isDbAvailable = false;

  beforeAll(async () => {
    // CRITICAL SAFETY GUARDRAIL: only TEST_DATABASE_URL on a local host, never DATABASE_URL.
    const rawTestUrl = process.env.TEST_DATABASE_URL;
    if (!rawTestUrl) {
      console.warn('[auth-codes.spec.ts] SAFETY GUARD: TEST_DATABASE_URL not set. Skipping live database assertions.');
      return;
    }
    const isCloudOrProd = /supabase\.co|supabase\.com|aws-|pooler|rds\.amazonaws\.com|compute\.amazonaws\.com|prod/i.test(rawTestUrl);
    const isLocal = /localhost|127\.0\.0\.1|test/i.test(rawTestUrl);
    if (isCloudOrProd || !isLocal) {
      console.error('[auth-codes.spec.ts] CRITICAL SAFETY TRIGGER: TEST_DATABASE_URL points to a remote/cloud host. Aborting.');
      return;
    }

    const isolatedUrl = new URL(rawTestUrl);
    const isolatedDb = `${isolatedUrl.pathname.slice(1) || 'postgres'}_auth_codes`.replace(/"/g, '');
    isolatedUrl.pathname = `/${isolatedDb}`;

    const admin = new Pool({ connectionString: rawTestUrl, max: 1, connectionTimeoutMillis: 3000 });
    try {
      await admin.query(`DROP DATABASE IF EXISTS "${isolatedDb}" WITH (FORCE)`);
      await admin.query(`CREATE DATABASE "${isolatedDb}"`);
    } catch (err) {
      console.warn(`[auth-codes.spec.ts] Live PostgreSQL not reachable: ${(err as Error).message}. Skipping.`);
      return;
    } finally {
      await admin.end().catch(() => {});
    }

    adminPool = new Pool({ connectionString: isolatedUrl.toString(), max: 3, connectionTimeoutMillis: 3000 });
    await adminPool.query(`
      CREATE EXTENSION IF NOT EXISTS vector;
      DO $$
      DECLARE r text;
      BEGIN
        FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role'] LOOP
          IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('CREATE ROLE %I NOLOGIN', r);
          END IF;
        END LOOP;
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${APP_ROLE}') THEN
          CREATE ROLE ${APP_ROLE} LOGIN NOSUPERUSER NOBYPASSRLS PASSWORD '${APP_PASSWORD}';
        END IF;
      END
      $$;
    `);
    const migrations = readdirSync(MIGRATIONS_DIR).filter((f) => /^\d{4}_.*\.sql$/.test(f)).sort();
    for (const file of migrations) {
      await adminPool.query(readFileSync(join(MIGRATIONS_DIR, file), 'utf8'));
    }
    await adminPool.query(`
      GRANT USAGE ON SCHEMA public TO ${APP_ROLE};
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${APP_ROLE};
    `);

    const appUrl = new URL(isolatedUrl.toString());
    appUrl.username = APP_ROLE;
    appUrl.password = APP_PASSWORD;
    appPool = new Pool({ connectionString: appUrl.toString(), max: 30, connectionTimeoutMillis: 5000 });
    const role = await appPool.query(`SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user`);
    expect(role.rows[0]).toEqual({ rolsuper: false, rolbypassrls: false });

    const encryption = new EncryptionService({ get: () => randomBytes(32).toString('hex') } as any);
    email = new EmailService({ get: () => undefined } as any); // no API key: codes stay in memory
    auth = new AuthService(
      drizzle(appPool, { schema }) as any,
      new JwtService({ secret: randomBytes(32).toString('hex') }),
      encryption,
      email,
    );
    isDbAvailable = true;
  });

  afterAll(async () => {
    if (appPool) await appPool.end().catch(() => {});
    if (adminPool) await adminPool.end().catch(() => {});
  });

  /** Signs up and confirms `address`, returning the first token pair. */
  const signUp = async (address: string) => {
    await auth.register({
      name: 'Ana Teste',
      email: address,
      password: PASSWORD,
      gender: 'feminino',
      dateOfBirth: '1990-01-01',
      lgpdConsent: true,
    });
    return auth.verifyEmail({ email: address, code: email.getLastSentCode(address)! });
  };

  /** Moves the account's codes back in time, as if `minutes` had passed. */
  const ageCodes = (table: string, address: string, minutes: number) =>
    adminPool.query(`UPDATE ${table} SET created_at = created_at - make_interval(mins => $2) WHERE email = $1`, [
      address,
      minutes,
    ]);

  it('signs up, confirms the email and signs in under row-level security', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const tokens = await signUp('ana-rls@dualis.test');
    expect(tokens.user.isEmailVerified).toBe(true);

    const login = await auth.login({ email: 'ana-rls@dualis.test', password: PASSWORD });
    expect(login.accessToken).toEqual(expect.any(String));

    const consent = await adminPool.query(`SELECT ip_address_hash FROM user_disclaimer_consents WHERE user_id = $1`, [
      tokens.user.id,
    ]);
    expect(consent.rows[0].ip_address_hash).toMatch(/^[0-9a-f]{64}$/);
  });

  it('counts parallel wrong guesses one by one and then refuses even the right code', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const address = 'ana-guess@dualis.test';
    await signUp(address);
    await auth.forgotPassword({ email: address });
    const code = email.getLastSentCode(address)!;

    const guesses = Array.from({ length: 20 }, () =>
      auth.resetPassword({ email: address, code: WRONG_CODE, newPassword: 'OutraSenha456!' }),
    );
    const results = await Promise.allSettled(guesses);
    expect(results.every((r) => r.status === 'rejected')).toBe(true);

    const attempts = await adminPool.query(`SELECT attempts FROM password_resets WHERE email = $1`, [address]);
    expect(attempts.rows).toEqual([{ attempts: 5 }]);
    await expect(auth.resetPassword({ email: address, code, newPassword: 'OutraSenha456!' })).rejects.toThrow(
      'Código inválido ou expirado',
    );
  });

  it('sends an account at most 5 codes a day, and none within a minute of the last', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const address = 'ana-cap@dualis.test';
    await signUp(address);

    await auth.forgotPassword({ email: address });
    await auth.forgotPassword({ email: address }); // within a minute: no new code
    expect((await adminPool.query(`SELECT 1 FROM password_resets WHERE email = $1`, [address])).rowCount).toBe(1);

    for (let i = 0; i < 6; i++) {
      await ageCodes('password_resets', address, 2);
      await auth.forgotPassword({ email: address });
    }
    expect((await adminPool.query(`SELECT 1 FROM password_resets WHERE email = $1`, [address])).rowCount).toBe(5);

    await ageCodes('password_resets', address, 24 * 60); // a day later the cap starts over
    await auth.forgotPassword({ email: address });
    expect((await adminPool.query(`SELECT 1 FROM password_resets WHERE email = $1`, [address])).rowCount).toBe(1);
  });

  it('lets a code work only once, even when sent twice at the same time', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const address = 'ana-once@dualis.test';
    await signUp(address);
    await auth.forgotPassword({ email: address });
    const code = email.getLastSentCode(address)!;

    const results = await Promise.allSettled([
      auth.resetPassword({ email: address, code, newPassword: 'OutraSenha456!' }),
      auth.resetPassword({ email: address, code, newPassword: 'TerceiraSenha789!' }),
    ]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
  });

  it('ends existing sessions when the password is reset', async (ctx) => {
    if (!isDbAvailable) return ctx.skip();
    const address = 'ana-session@dualis.test';
    const before = await signUp(address);
    const jwt = new JwtService({});
    const access = jwt.decode(before.accessToken) as { sub: string; sv: string };
    await expect(auth.validateUserById(access.sub, access.sv)).resolves.toEqual({ id: access.sub, email: address });
    await expect(auth.refreshTokens(before.refreshToken)).resolves.toHaveProperty('accessToken');

    await auth.forgotPassword({ email: address });
    await auth.resetPassword({ email: address, code: email.getLastSentCode(address)!, newPassword: 'OutraSenha456!' });

    await expect(auth.validateUserById(access.sub, access.sv)).resolves.toBeNull();
    await expect(auth.refreshTokens(before.refreshToken)).rejects.toThrow('Sessão encerrada');
    const after = await auth.login({ email: address, password: 'OutraSenha456!' });
    const fresh = jwt.decode(after.accessToken) as { sv: string };
    await expect(auth.validateUserById(access.sub, fresh.sv)).resolves.not.toBeNull();
  });
});
