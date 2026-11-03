import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { EncryptionModule } from '../../common/encryption/encryption.module';
import { ProfilesModule } from '../profiles/profiles.module';
import { AntiburlaService } from './services/antiburla.service';
import { TriageHistoryService } from './services/triage-history.service';
import { TriageController } from './triage.controller';

@Module({
  imports: [DatabaseModule, EncryptionModule, ProfilesModule],
  controllers: [TriageController],
  providers: [
    AntiburlaService,
    TriageHistoryService,
  ],
  exports: [
    AntiburlaService,
    TriageHistoryService,
  ],
})
export class TriageModule {}
