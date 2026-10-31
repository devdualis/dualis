import {
  IsEnum,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  Validate,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';
import { JOURNAL_LIMITS } from '../../journal/constants/journal-keys.constant';

/** Old wizard answers: a few short values per step. Caps the free-form object. */
export const LEGACY_ANSWERS_MAX_KEYS = 20;
export const LEGACY_ANSWER_MAX_LENGTH = 200;

@ValidatorConstraint({ name: 'legacyAnswersShape', async: false })
class LegacyAnswersShapeConstraint implements ValidatorConstraintInterface {
  validate(value: unknown): boolean {
    if (!value || typeof value !== 'object' || Array.isArray(value)) return false;
    const entries = Object.entries(value as Record<string, unknown>);
    return (
      entries.length <= LEGACY_ANSWERS_MAX_KEYS &&
      entries.every(
        ([key, v]) =>
          key.length <= 16 &&
          (typeof v === 'string' || typeof v === 'number') &&
          String(v).length <= LEGACY_ANSWER_MAX_LENGTH,
      )
    );
  }
  defaultMessage(): string {
    return `answers aceita até ${LEGACY_ANSWERS_MAX_KEYS} respostas curtas (até ${LEGACY_ANSWER_MAX_LENGTH} caracteres).`;
  }
}

export class SubmitTriageDto {
  @IsEnum(['physical', 'emotional'], {
    message: 'Vertical deve ser "physical" ou "emotional".',
  })
  @IsNotEmpty()
  vertical!: 'physical' | 'emotional';

  @IsObject()
  @IsNotEmpty()
  @Validate(LegacyAnswersShapeConstraint)
  answers!: Record<number, string>;

  @IsString()
  @IsOptional()
  @MaxLength(JOURNAL_LIMITS.noteMax)
  narrative?: string;

  @IsString()
  @IsOptional()
  @MaxLength(JOURNAL_LIMITS.clientIdMax)
  clientSessionId?: string;

  @IsString()
  @IsOptional()
  @MaxLength(16)
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
}
