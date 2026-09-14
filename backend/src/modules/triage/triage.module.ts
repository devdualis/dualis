import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { EncryptionModule } from '../../common/encryption/encryption.module';
import { ArticlesCatalogService } from './services/articles-catalog.service';
import { TriageOutcomeService } from './services/triage-outcome.service';
import { AntiburlaService } from './services/antiburla.service';
import { TriageHistoryService } from './services/triage-history.service';
import { TriageController } from './triage.controller';

@Module({
  imports: [DatabaseModule, EncryptionModule],
  controllers: [TriageController],
  providers: [
    ArticlesCatalogService,
    TriageOutcomeService,
    AntiburlaService,
    TriageHistoryService,
  ],
  exports: [
    ArticlesCatalogService,
    TriageOutcomeService,
    AntiburlaService,
    TriageHistoryService,
  ],
})
export class TriageModule {}
