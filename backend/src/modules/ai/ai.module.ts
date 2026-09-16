import { Module, forwardRef } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TriageModule } from '../triage/triage.module';
import { AiController } from './ai.controller';
import { AiTriageService } from './services/ai-triage.service';
import { IdiomDictionaryService } from './services/idiom-dictionary.service';
import { SymptomVectorService } from './services/symptom-vector.service';

@Module({
  imports: [ConfigModule, forwardRef(() => TriageModule)],
  controllers: [AiController],
  providers: [AiTriageService, IdiomDictionaryService, SymptomVectorService],
  exports: [AiTriageService, IdiomDictionaryService, SymptomVectorService],
})
export class AiModule {}
