import { Module, forwardRef } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TriageModule } from '../triage/triage.module';
import { AiController } from './ai.controller';
import { AiTaggingService } from './services/ai-tagging.service';
import { IdiomDictionaryService } from './services/idiom-dictionary.service';
import { SymptomVectorService } from './services/symptom-vector.service';

@Module({
  imports: [ConfigModule, forwardRef(() => TriageModule)],
  controllers: [AiController],
  providers: [AiTaggingService, IdiomDictionaryService, SymptomVectorService],
  exports: [AiTaggingService, IdiomDictionaryService, SymptomVectorService],
})
export class AiModule {}
