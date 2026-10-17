import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';

/**
 * Journal consistency check ("Isso já apareceu antes?"): when an entry says it started
 * today, look for the same category in the last 14 days so the person can mark it as
 * something that came back. Route paths stay /antiburla for app compatibility.
 */
export class CheckRecurrenceDto {
  @IsEnum(['physical', 'emotional'], {
    message: 'Vertical deve ser "physical" ou "emotional".',
  })
  @IsNotEmpty()
  vertical!: 'physical' | 'emotional';

  @IsString()
  @IsNotEmpty()
  category!: string;

  @IsString()
  @IsNotEmpty()
  selectedPersistence!: string;

  /** Accepted for old app versions and ignored: no rule depends on biological sex. */
  @IsString()
  @IsOptional()
  userGender?: string;

  @IsString()
  @IsOptional()
  narrative?: string;
}

export interface RecurrenceCheckResponseDto {
  triggered: boolean;
  daysAgo?: number;
  previousRecordedAt?: string;
  previousCategoryLabel?: string;
  empatheticPrompt?: string;
}

/** @deprecated Old names; use CheckRecurrenceDto / RecurrenceCheckResponseDto. */
export { CheckRecurrenceDto as CheckAntiburlaDto };
export type AntiburlaCheckResponseDto = RecurrenceCheckResponseDto;
