import { describe, it, expect, beforeAll, afterAll, afterEach } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from '../../src/app.module';

describe('App config E2E (GET /v1/app/config)', () => {
  let app: NestFastifyApplication;
  let configService: ConfigService;
  let configured: string | undefined;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(ConfigService)
      .useValue({
        get: (key: string, fallback?: unknown) =>
          key === 'MIN_SUPPORTED_APP_VERSION' ? configured : (process.env[key] ?? fallback),
        getOrThrow: (key: string) => process.env[key],
      })
      .compile();
    configService = moduleRef.get(ConfigService);

    app = moduleRef.createNestApplication<NestFastifyApplication>(new FastifyAdapter());
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterEach(() => {
    configured = undefined;
  });

  afterAll(async () => {
    if (app) await app.close();
  });

  const getConfig = async () => {
    const res = await app.inject({ method: 'GET', url: '/v1/app/config' });
    return { status: res.statusCode, body: JSON.parse(res.payload) };
  };

  it('is public and defaults to 1.0.0', async () => {
    expect(configService).toBeDefined();
    expect(await getConfig()).toEqual({ status: 200, body: { minSupportedVersion: '1.0.0' } });
  });

  it('returns MIN_SUPPORTED_APP_VERSION when set', async () => {
    configured = ' 2.3.1 ';
    expect((await getConfig()).body).toEqual({ minSupportedVersion: '2.3.1' });
  });

  it('falls back to 1.0.0 for a malformed value', async () => {
    configured = 'latest';
    expect((await getConfig()).body).toEqual({ minSupportedVersion: '1.0.0' });
  });
});
