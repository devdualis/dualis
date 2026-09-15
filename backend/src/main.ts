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

async function bootstrap() {
  const fastifyAdapter = new FastifyAdapter({
    logger: false, // Pino handles structured logging via nestjs-pino
    trustProxy: true, // Necessary for reverse proxies / GCP Cloud Run
    bodyLimit: 5242880, // 5MB payload limit for profile pictures
  });

  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    fastifyAdapter,
    { bufferLogs: true },
  );

  // Bind structured Pino logger
  app.useLogger(app.get(Logger));

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
}

bootstrap();
