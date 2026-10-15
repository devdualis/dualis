import { IsIn, IsNotEmpty, IsUUID } from 'class-validator';
import { ACCESS_LEVELS, AccessLevel } from '../../../database/schema/shared-access-grants.schema';

export class CreateInviteDto {
  @IsUUID('4', { message: 'targetProfileId must be a valid UUID v4' })
  @IsNotEmpty()
  targetProfileId!: string;

  @IsIn(ACCESS_LEVELS, {
    message: 'accessLevel must be VIEW_ONLY or CO_MANAGE',
  })
  @IsNotEmpty()
  accessLevel!: AccessLevel;
}
