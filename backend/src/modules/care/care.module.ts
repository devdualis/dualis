import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { EncryptionModule } from '../../common/encryption/encryption.module';
import { AiCoreModule } from '../../common/ai/ai-core.module';
import { ProfilesModule } from '../profiles/profiles.module';
import { CareController } from './care.controller';
import { CareService } from './care.service';
import { DocumentReaderService } from './document-reader.service';

@Module({
  imports: [DatabaseModule, EncryptionModule, AiCoreModule, ProfilesModule],
  controllers: [CareController],
  providers: [CareService, DocumentReaderService],
  exports: [CareService],
})
export class CareModule {}
