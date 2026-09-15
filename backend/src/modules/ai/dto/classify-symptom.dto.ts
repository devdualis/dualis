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
  confidence: number;
  source: 'gemini_flash' | 'idiom_cache' | 'dictionary_fallback' | 'vector_match';
  latencyMs: number;
}
