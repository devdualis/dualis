import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { EncryptionModule } from '../../common/encryption/encryption.module';
import { EmailModule } from '../../common/email/email.module';
import { StorageModule } from '../../common/storage/storage.module';
import { RateLimiter } from '../../common/http/rate-limiter';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './strategies/jwt.strategy';
import { jwtSecret } from './jwt-secret';

@Module({
  imports: [
    EncryptionModule,
    EmailModule,
    StorageModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: jwtSecret(configService),
        signOptions: {
          expiresIn: '15m',
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, RateLimiter],
  exports: [AuthService, JwtModule, PassportModule],
})
export class AuthModule {}
