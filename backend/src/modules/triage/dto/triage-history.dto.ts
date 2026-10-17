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
  /** Intensity the person reported (0 = not reported). */
  intensity: number;
  anatomicalSystem: string | null;
  emotionalDimension: string | null;
  /**
   * Vertical the person chose for the entry. Tells the primary axis when both
   * anatomicalSystem and emotionalDimension are set. null when unknown.
   */
  vertical: 'physical' | 'emotional' | null;
  narrative?: string | null;
  stepAnswers: Record<string, any> | null;
  recordedAt: string;
}

/**
 * Descriptive insight over the person's own entries ("Padrões nos seus registros"):
 * how many times a category was logged with high reported intensity in the window.
 * No clinical judgement; the app builds the localized text from these fields.
 */
export interface JournalPatternDto {
  category: string;
  vertical: 'physical' | 'emotional';
  count: number;
  windowDays: number;
}

export interface EmotionalDayDataDto {
  date: string;
  dimensions: Record<string, number>;
}

export interface TriageHistoryResponseDto {
  logs: TriageLogItemDto[];
  physicalSummary: Record<string, number>;
  emotionalSummary: EmotionalDayDataDto[];
  journalPatterns: JournalPatternDto[];
}
