import { IsIn, IsInt, IsISO8601, IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * Body sent by published app versions to POST /v1/triage/emergency-event (legacy alias).
 * Every old field is still accepted so those versions never get a 400, but severity,
 * category and vertical are discarded: the event is stored as action='opened_resources'.
 */
export class LegacyEmergencyEventDto {
  @IsOptional()
  @IsString()
  triggerCategory?: string;

  @IsOptional()
  @IsInt()
  severityLevel?: number;

  @IsOptional()
  @IsIn(['PHYSICAL', 'EMOTIONAL'])
  sourceVertical?: 'PHYSICAL' | 'EMOTIONAL';

  @IsISO8601()
  clientTimestamp: string;

  /** Old free-text action (e.g. 'DIALED_192'); kept as the channel. */
  @IsOptional()
  @IsString()
  @MaxLength(64)
  actionTaken?: string;
}
