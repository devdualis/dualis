import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { Body, Controller, Post } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { applyRouteBodyLimits, BodyLimit, DEFAULT_BODY_LIMIT } from '../../src/common/http/body-limit';

const MB = 1024 * 1024;

@Controller('limits')
class LimitsController {
  @Post('ordinary')
  ordinary(@Body() _body: unknown) {
    return { ok: true };
  }

  @Post('upload')
  @BodyLimit(3 * MB)
  upload(@Body() _body: unknown) {
    return { ok: true };
  }
}

describe('Request body limits (1 MB unless a route sets @BodyLimit)', () => {
  let app: NestFastifyApplication;

  beforeAll(async () => {
    const adapter = new FastifyAdapter({ bodyLimit: DEFAULT_BODY_LIMIT });
    applyRouteBodyLimits(adapter.getInstance());
    const moduleRef = await Test.createTestingModule({ controllers: [LimitsController] }).compile();
    app = moduleRef.createNestApplication<NestFastifyApplication>(adapter);
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app?.close();
  });

  const post = (url: string, bytes: number) =>
    app.inject({ method: 'POST', url, payload: { data: 'x'.repeat(bytes) } });

  it('rejects a 2 MB body on an ordinary route before the handler runs', async () => {
    expect((await post('/limits/ordinary', 2 * MB)).statusCode).toBe(413);
  });

  it('accepts a small body on an ordinary route', async () => {
    expect((await post('/limits/ordinary', 1000)).statusCode).toBe(201);
  });

  it('accepts a 2 MB body on a route that raises its limit', async () => {
    expect((await post('/limits/upload', 2 * MB)).statusCode).toBe(201);
  });

  it('still rejects a body over the raised limit', async () => {
    expect((await post('/limits/upload', 4 * MB)).statusCode).toBe(413);
  });
});
