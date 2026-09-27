import { IsDateString, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class LogWaterDto {
  @IsInt()
  @Min(1)
  @Max(10000)
  amountMl!: number;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  source?: string;

  @IsOptional()
  @IsDateString()
  recordedAt?: string;
}
