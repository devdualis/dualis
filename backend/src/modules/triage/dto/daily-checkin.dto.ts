import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { RecommendedArticleDto } from './triage-outcome.dto';

export type TriggerStatusType = 'goodNormal' | 'soSo' | 'badSick';

export class SubmitDailyCheckInDto {
  @IsEnum(['goodNormal', 'soSo', 'badSick'], {
    message: 'emotionalStatus deve ser "goodNormal", "soSo" ou "badSick".',
  })
  @IsNotEmpty()
  emotionalStatus!: TriggerStatusType;

  @IsEnum(['goodNormal', 'soSo', 'badSick'], {
    message: 'physicalStatus deve ser "goodNormal", "soSo" ou "badSick".',
  })
  @IsNotEmpty()
  physicalStatus!: TriggerStatusType;

  @IsString()
  @IsOptional()
  naturalLanguageText?: string;

  @IsString()
  @IsOptional()
  language?: string;
}

/**
 * Quick check-in: stores only the state the person declared (good / so-so / bad).
 * No intensity is inferred and no care recommendation is produced (plan F4, B-02).
 */
export interface DailyCheckInResponseDto {
  id: string;
  emotionalStatus: TriggerStatusType;
  physicalStatus: TriggerStatusType;
  recordedAt: string;
  recommendedArticles?: RecommendedArticleDto[];
}
