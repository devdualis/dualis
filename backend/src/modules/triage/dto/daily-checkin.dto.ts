import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export type TriggerStatusType = 'goodNormal' | 'soSo' | 'badSick';

export class SubmitDailyCheckInDto {
  @IsEnum(['goodNormal', 'soSo', 'badSick'], {
    message: 'emotionalStatus deve ser "goodNormal", "soSo" ou "badSick".',
  })
  @IsNotEmpty()
  emotionalStatus!: TriggerStatusType;

  @IsEnum(['goodNormal', 'soSo', 'badSick'], {
    message: 'physicalStatus deve ser "goodNormal", "soSo" ou "badSick".',
  })
  @IsNotEmpty()
  physicalStatus!: TriggerStatusType;

  @IsString()
  @IsOptional()
  naturalLanguageText?: string;
}

export interface DailyCheckInResponseDto {
  id: string;
  intensity: number;
  disposition: string;
  emotionalStatus: TriggerStatusType;
  physicalStatus: TriggerStatusType;
  recordedAt: string;
}
