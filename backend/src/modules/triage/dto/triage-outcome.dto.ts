import { IsEnum, IsNotEmpty, IsObject, IsOptional, IsString } from 'class-validator';

export type CareDisposition =
  | 'auto_cuidado'
  | 'consulta_rotina'
  | 'pronto_atendimento'
  | 'emergencia';

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

export interface TriageOutcomeResponseDto {
  id: string;
  vertical: 'physical' | 'emotional';
  intensityScore: number;
  careDisposition: CareDisposition;
  primaryCategory: string;
  categoryLabel: string;
  somaticMapping: string;
  organicPrimacyApplied: boolean;
  organicPrimacyNotice?: string;
  recommendedArticles: RecommendedArticleDto[];
  recordedAt: string;
}
