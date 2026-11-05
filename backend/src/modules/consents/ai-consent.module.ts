import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { EncryptionModule } from '../../common/encryption/encryption.module';
import { AiConsentController } from './ai-consent.controller';
import { AiConsentService } from './ai-consent.service';

/** Account-level AI-processing consent (LGPD Art. 11, I), read by the journal suggestion routes. */
@Module({
  imports: [DatabaseModule, EncryptionModule],
  controllers: [AiConsentController],
  providers: [AiConsentService],
  exports: [AiConsentService],
})
export class AiConsentModule {}
