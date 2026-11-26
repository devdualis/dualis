import { performance } from 'node:perf_hooks';
import { NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { VersioningType, ValidationPipe } from '@nestjs/common';
import { Logger } from 'nestjs-pino';
import fastifyHelmet from '@fastify/helmet';
import fastifyCors from '@fastify/cors';
import { AppModule } from './app.module';
import { applyRouteBodyLimits, DEFAULT_BODY_LIMIT } from './common/http/body-limit';

async function bootstrap() {
  // Cold-start timing. All milliseconds are measured from process start
  // (performance.timeOrigin). By the time bootstrap() runs, every import has
  // been required, so `modulesLoadedMs` covers Node boot plus module loading.
  const modulesLoadedMs = performance.now();
  const fastifyAdapter = new FastifyAdapter({
    logger: false, // Pino handles structured logging via nestjs-pino
    // Cloud Run's front end appends the caller's address to X-Forwarded-For. Trusting that one
    // hop makes req.ip that address; earlier entries are whatever the client sent.
    trustProxy: 1 as any,
    bodyLimit: DEFAULT_BODY_LIMIT, // 1MB; uploads raise it per route with @BodyLimit
  });
  applyRouteBodyLimits(fastifyAdapter.getInstance());

  // Fastify by default rejects empty bodies with Content-Type: application/json with HTTP 400.
  // Many mobile clients (Dio) set default headers: {'Content-Type': 'application/json'}.
  // Allow empty or whitespace-only bodies to gracefully parse as undefined for DELETE / GET.
  fastifyAdapter.useBodyParser(
    'application/json',
    false,
    {},
    (req: any, body: any, done: any) => {
      const str = body ? body.toString('utf8').trim() : '';
      if (!str) {
        done(null, undefined);
        return;
      }
      try {
        const json = JSON.parse(str);
        done(null, json);
      } catch (err: any) {
        err.statusCode = 400;
        done(err, undefined);
      }
    },
  );

  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    fastifyAdapter,
    { bufferLogs: true },
  );

  const nestCreatedMs = performance.now();

  // Bind structured Pino logger
  const logger = app.get(Logger);
  app.useLogger(logger);

  // Enable graceful shutdown to drain database pool connections cleanly
  app.enableShutdownHooks();

  // API Versioning: /v1/...
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Global Security Headers via Fastify Helmet
  await app.register(fastifyHelmet as any, {
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        scriptSrc: ["'self'"],
      },
    },
    strictTransportSecurity: {
      maxAge: 63072000, // 2 years in seconds (HSTS preload standard)
      includeSubDomains: true,
      preload: true,
    },
    frameguard: { action: 'deny' },
    noSniff: true,
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
  });

  // Strict CORS policy
  await app.register(fastifyCors as any, {
    origin: (origin: any, cb: any) => {
      const allowedOrigins = [
        /^https:\/\/.*\.dualischeckup\.com\.br$/,
        /^http:\/\/localhost:(3000|5173|8080)$/,
      ];
      if (!origin || allowedOrigins.some((pattern) => pattern.test(origin))) {
        cb(null, true);
      } else {
        cb(new Error('Blocked by CORS policy'), false);
      }
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    credentials: true,
  });

  // Global Validation Pipeline
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
  await app.listen(port, '0.0.0.0');

  const listeningMs = performance.now();
  logger.log(
    {
      msg: 'startup timing',
      processStart: new Date(performance.timeOrigin).toISOString(),
      nodeBootMs: Math.round(performance.nodeTiming.bootstrapComplete),
      modulesLoadedMs: Math.round(modulesLoadedMs),
      nestCreateMs: Math.round(nestCreatedMs - modulesLoadedMs),
      listenMs: Math.round(listeningMs - nestCreatedMs),
      totalMs: Math.round(listeningMs),
    },
    'Bootstrap',
  );
}

bootstrap();
