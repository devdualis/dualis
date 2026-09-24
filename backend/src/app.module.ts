import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { LoggerModule } from 'nestjs-pino';
import { DatabaseModule } from './database/database.module';
import { EncryptionModule } from './common/encryption/encryption.module';
import { AiCoreModule } from './common/ai/ai-core.module';
import { LegalModule } from './modules/legal/legal.module';
import { AuthModule } from './modules/auth/auth.module';
import { TriageAuditModule } from './modules/triage-audit/triage-audit.module';
import { AiModule } from './modules/ai/ai.module';
import { TriageModule } from './modules/triage/triage.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
        redact: ['req.headers.authorization', 'req.headers.cookie', 'body.password'],
        transport:
          process.env.NODE_ENV !== 'production'
            ? {
                target: 'pino-pretty',
                options: {
                  colorize: true,
                  singleLine: true,
                  translateTime: 'SYS:standard',
                  ignore: 'pid,hostname',
                },
              }
            : undefined,
        serializers: {
          req: (req: any) => ({
            id: req.id,
            method: req.method,
            url: req.url,
            query: req.query,
          }),
          res: (res: any) => ({
            statusCode: res.statusCode,
          }),
        },
        customSuccessMessage: (req: any, res: any) =>
          `${req.method} ${req.url} completed with ${res.statusCode}`,
        customErrorMessage: (req: any, res: any, error: any) =>
          `${req.method} ${req.url} failed with ${res.statusCode}: ${error?.message ?? 'error'}`,
      },
    }),
    DatabaseModule,
    EncryptionModule,
    AiCoreModule,
    LegalModule,
    AuthModule,
    TriageAuditModule,
    AiModule,
    TriageModule,
  ],
})
export class AppModule {}
