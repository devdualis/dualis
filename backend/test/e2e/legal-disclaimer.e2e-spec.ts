import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { VersioningType } from '@nestjs/common';
import fastifyHelmet from '@fastify/helmet';
import { AppModule } from '../../src/app.module';

describe('Legal & Regulatory Disclaimer Endpoint (DISC-01) & Security Headers', () => {
  let app: NestFastifyApplication;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );

    app.enableVersioning({
      type: VersioningType.URI,
      defaultVersion: '1',
    });

    await app.register(fastifyHelmet as any, {
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
        },
      },
      strictTransportSecurity: {
        maxAge: 63072000,
        includeSubDomains: true,
        preload: true,
      },
      frameguard: { action: 'deny' },
      noSniff: true,
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('GET /v1/legal/disclaimer (default) returns 200 with Brazilian Portuguese regulatory metadata', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/legal/disclaimer',
    });

    expect(res.statusCode).toBe(200);

    const body = JSON.parse(res.payload);
    expect(body).toHaveProperty('version');
    expect(body).toHaveProperty('language', 'pt-BR');
    expect(body).toHaveProperty('disclaimerText');
    expect(body.disclaimerText).toContain('NÃO realiza diagnósticos médicos');
    expect(body).toHaveProperty('shortDisclaimer');
    expect(body).toHaveProperty('citations');
    expect(body.citations.length).toBeGreaterThanOrEqual(2);
    expect(body).toHaveProperty('emergencyContacts');

    // Verify Brazilian Emergency Contacts
    const samu = body.emergencyContacts.find((c: any) => c.name === 'SAMU');
    expect(samu).toBeDefined();
    expect(samu.phone).toBe('192');

    const cvv = body.emergencyContacts.find((c: any) => c.name === 'CVV');
    expect(cvv).toBeDefined();
    expect(cvv.phone).toBe('188');
  });

  it('GET /v1/legal/disclaimer?lang=es returns 200 with Spanish localized disclaimer', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/legal/disclaimer?lang=es',
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body).toHaveProperty('language', 'es');
    expect(body.disclaimerText).toContain('NO realiza diagnósticos médicos');
    expect(body.shortDisclaimer).toContain('no reemplaza la evaluación médica profesional');
  });

  it('GET /v1/legal/disclaimer?lang=en returns 200 with English localized disclaimer', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/legal/disclaimer?lang=en',
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body).toHaveProperty('language', 'en');
    expect(body.disclaimerText).toContain('DOES NOT provide medical diagnoses');
    expect(body.shortDisclaimer).toContain('does not replace professional medical evaluation');
  });

  it('Response headers include strict HSTS, X-Frame-Options, and Content-Type-Options', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/legal/disclaimer',
    });

    expect(res.headers['strict-transport-security']).toBeDefined();
    expect(res.headers['strict-transport-security']).toContain('max-age=63072000');
    expect(res.headers['x-frame-options']).toBe('DENY');
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });
});
