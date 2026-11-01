import { IsDateString, IsInt, IsOptional, IsString, IsUUID, Max, MaxLength, Min } from 'class-validator';

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

  /**
   * Idempotency key made by the app and kept with the log on the device. Stored as the log's
   * id: sending the same log again (a retry after a lost answer) returns the saved log
   * instead of adding the water twice. Optional, so older app versions keep working.
   */
  @IsOptional()
  @IsUUID()
  clientId?: string;
}
