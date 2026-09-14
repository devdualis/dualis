import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AiController } from './ai.controller';
import { GeminiTriageService } from './services/gemini-triage.service';
import { IdiomDictionaryService } from './services/idiom-dictionary.service';

@Module({
  imports: [ConfigModule],
  controllers: [AiController],
  providers: [GeminiTriageService, IdiomDictionaryService],
  exports: [GeminiTriageService, IdiomDictionaryService],
})
export class AiModule {}
