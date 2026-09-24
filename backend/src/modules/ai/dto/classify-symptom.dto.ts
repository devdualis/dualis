import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class ClassifySymptomDto {
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

export interface TriageClassificationResult {
  primaryVertical: 'physical' | 'emotional';
  systemOrDimension: string;
  urgencyScore: number;
  mappedLayTerm: string;
  clinicalConcept: string;
  isEmergencyCandidate: boolean;
  /** True when the text does not actually describe a physical/emotional symptom
   * (off-topic, joke, spam, etc). Only ever set by the Gemini path — deterministic
   * matches (idiom dictionary, vector, cache) are by construction on-topic, and the
   * no-AI heuristic fallback cannot make this judgment, so both default to false. */
  isOffTopic?: boolean;
  confidence: number;
  source: 'gemini' | 'idiom_cache' | 'dictionary_fallback' | 'vector_match';
  latencyMs: number;
}
