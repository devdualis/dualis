import { IsEnum, IsNotEmpty, IsObject, IsOptional, IsString } from 'class-validator';

export class SubmitTriageDto {
  @IsEnum(['physical', 'emotional'], {
    message: 'Vertical deve ser "physical" ou "emotional".',
  })
  @IsNotEmpty()
  vertical!: 'physical' | 'emotional';

  @IsObject()
  @IsNotEmpty()
  answers!: Record<number, string>;

  @IsString()
  @IsOptional()
  narrative?: string;

  @IsString()
  @IsOptional()
  clientSessionId?: string;

  @IsString()
  @IsOptional()
  language?: string;
}

export interface RecommendedArticleDto {
  id: string;
  title: string;
  category: string;
  author: string;
  authorRole: string;
  readTimeMinutes: number;
  summary: string;
  url: string;
}

/**
 * Summary of a journal entry. It describes what the person logged and never assesses it:
 * no care recommendation, urgency or medical concept (plan F4, contract 1).
 */
export interface TriageOutcomeResponseDto {
  id: string;
  vertical: 'physical' | 'emotional';
  /** Intensity the person reported themselves (0 = nothing to report, 1 to 5). Never computed. */
  intensityScore: number;
  primaryCategory: string;
  /** Plain-language name of the area of the body or mood the person picked. */
  categoryLabel: string;
  /** Plain-language description of what was logged (field name kept for app compatibility). */
  somaticMapping: string;
  recommendedArticles: RecommendedArticleDto[];
  recordedAt: string;
  secondaryCategoryLabel?: string;
  secondarySomaticMapping?: string;
  secondaryIntensityScore?: number;
  isCrossVerticalSomatic?: boolean;
  /** Static note shown when the entry mentions both body and emotions; same text for everyone. */
  crossVerticalContextNote?: string;
  aiMappedLayTerm?: string;
  aiSource?: 'gemini' | 'idiom_cache' | 'dictionary_fallback' | 'vector_match';
  aiConfidence?: number;
}
