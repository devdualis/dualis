import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CheckAntiburlaDto {
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

  @IsString()
  @IsOptional()
  userGender?: string;

  @IsString()
  @IsOptional()
  narrative?: string;
}

export interface AntiburlaCheckResponseDto {
  triggered: boolean;
  daysAgo?: number;
  previousRecordedAt?: string;
  previousCategoryLabel?: string;
  empatheticPrompt?: string;
  biologicalDiscordance?: boolean;
  biologicalNotice?: string;
}
