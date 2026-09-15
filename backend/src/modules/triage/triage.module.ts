import { Module, forwardRef } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { EncryptionModule } from '../../common/encryption/encryption.module';
import { AiModule } from '../ai/ai.module';
import { ArticlesCatalogService } from './services/articles-catalog.service';
import { ArticleEmbeddingService } from './services/article-embedding.service';
import { ArticlesVectorService } from './services/articles-vector.service';
import { TriageOutcomeService } from './services/triage-outcome.service';
import { AntiburlaService } from './services/antiburla.service';
import { TriageHistoryService } from './services/triage-history.service';
import { TriageController } from './triage.controller';

@Module({
  imports: [DatabaseModule, EncryptionModule, forwardRef(() => AiModule)],
  controllers: [TriageController],
  providers: [
    ArticlesCatalogService,
    ArticleEmbeddingService,
    ArticlesVectorService,
    TriageOutcomeService,
    AntiburlaService,
    TriageHistoryService,
  ],
  exports: [
    ArticlesCatalogService,
    ArticleEmbeddingService,
    ArticlesVectorService,
    TriageOutcomeService,
    AntiburlaService,
    TriageHistoryService,
  ],
})
export class TriageModule {}
