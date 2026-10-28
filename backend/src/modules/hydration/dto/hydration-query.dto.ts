import { IsDateString, IsInt, IsOptional, Max, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class HydrationTodayQueryDto {
  @IsOptional()
  @IsDateString()
  date?: string;
}

export class HydrationHistoryQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(30)
  days?: number = 7;

  @IsOptional()
  @IsDateString()
  referenceDate?: string;

  /** Minutes east of UTC on the device (e.g. -180 for Brasília), used to group by local day. */
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(-720)
  @Max(840)
  tzOffset?: number;
}
