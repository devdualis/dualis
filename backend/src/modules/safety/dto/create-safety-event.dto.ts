import { IsIn, IsISO8601, IsOptional, IsString, MaxLength } from 'class-validator';
import { SAFETY_RESOURCE_ACTIONS, SafetyResourceAction } from '../../../database/schema/safety-resource-events.schema';

/** POST /v1/journal/safety-event: someone opened the help resources or started a call. */
export class CreateSafetyEventDto {
  @IsIn(SAFETY_RESOURCE_ACTIONS)
  action: SafetyResourceAction;

  /** Which resource, e.g. 'tel:192' or 'samu'. Free text, no health data. */
  @IsOptional()
  @IsString()
  @MaxLength(64)
  channel?: string;

  @IsISO8601()
  clientTimestamp: string;
}
