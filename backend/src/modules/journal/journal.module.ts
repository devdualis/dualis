import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { EncryptionModule } from '../../common/encryption/encryption.module';
import { ProfilesModule } from '../profiles/profiles.module';
import { HouseAdsController, JournalController } from './journal.controller';
import { JournalService } from './journal.service';
import { JournalSuggestService } from './journal-suggest.service';

@Module({
  imports: [DatabaseModule, EncryptionModule, ProfilesModule],
  controllers: [JournalController, HouseAdsController],
  providers: [JournalService, JournalSuggestService],
  exports: [JournalService],
})
export class JournalModule {}
