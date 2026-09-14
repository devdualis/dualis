import {
  IsString,
  IsNotEmpty,
  IsInt,
  Min,
  Max,
  IsIn,
  IsISO8601,
  IsOptional,
} from 'class-validator';

export class CreateEmergencyEventDto {
  @IsString()
  @IsNotEmpty()
  triggerCategory: string;

  @IsInt()
  @Min(4)
  @Max(5)
  severityLevel: number;

  @IsIn(['PHYSICAL', 'EMOTIONAL'])
  sourceVertical: 'PHYSICAL' | 'EMOTIONAL';

  @IsISO8601()
  clientTimestamp: string;

  @IsOptional()
  @IsString()
  actionTaken?: string;
}
