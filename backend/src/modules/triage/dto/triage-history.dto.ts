import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class GetTriageHistoryQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(30)
  days?: number;
}

export interface TriageLogItemDto {
  id: string;
  intensity: number;
  anatomicalSystem: string | null;
  emotionalDimension: string | null;
  disposition: string | null;
  organicPrimacyApplied?: boolean;
  narrative?: string | null;
  stepAnswers: Record<string, any> | null;
  recordedAt: string;
}

export interface CriticalRecurrenceDto {
  id: string;
  vertical: 'physical' | 'emotional';
  category: string;
  categoryLabel: string;
  title: string;
  description: string;
  intensity: number;
  frequencyCount: number;
  windowDays: number;
  recommendedArticleTitle: string;
  recommendedArticleUrl: string;
}

export interface EmotionalDayDataDto {
  date: string;
  dimensions: Record<string, number>;
}

export interface TriageHistoryResponseDto {
  logs: TriageLogItemDto[];
  physicalSummary: Record<string, number>;
  emotionalSummary: EmotionalDayDataDto[];
  criticalRecurrences: CriticalRecurrenceDto[];
}
