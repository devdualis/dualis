import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class TagEntryDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(1000)
  text!: string;

  @IsOptional()
  @IsString()
  @IsIn(['pt', 'es', 'en'])
  language?: 'pt' | 'es' | 'en';
}

/** @deprecated Kept for `/v1/ai/classify-symptom`; use TagEntryDto. */
export { TagEntryDto as ClassifySymptomDto };

export type EntryVertical = 'physical' | 'emotional';

/**
 * Public response of `/v1/ai/tag-entry` (and the legacy `/v1/ai/classify-symptom`).
 * The AI only organises a journal entry: which area of the body or mood it mentions
 * and the lay term the person used. It never assesses severity or names a condition.
 */
export interface EntryTagResponseDto {
  /** True when the text is not about how the person feels (joke, spam, unrelated request). */
  isOffTopic: boolean;
  vertical: EntryVertical | null;
  /** Canonical area-of-body or mood key (see AiTaggingService), or null when unknown. */
  bodyAreaOrMood: string | null;
  /** Short lay term for what was written (e.g. "dor de cabeça"), or null when unknown. */
  layTerm: string | null;
  /** Content-safety flag: the text mentions wanting to hurt oneself or die. */
  mentionsSelfHarm: boolean;
}

export type EntryTagSource = 'gemini' | 'idiom_cache' | 'dictionary_fallback' | 'vector_match';

/** Internal result: the public tags plus how they were produced. */
export interface EntryTagResult extends EntryTagResponseDto {
  confidence: number;
  source: EntryTagSource;
  latencyMs: number;
}

/** @deprecated Old name of the tagging response; use EntryTagResponseDto. */
export type TriageClassificationResult = EntryTagResponseDto;
