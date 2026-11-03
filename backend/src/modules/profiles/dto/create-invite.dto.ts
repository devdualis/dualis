import {
  ArrayNotEmpty,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsUUID,
} from 'class-validator';
import {
  ACCESS_LEVELS,
  AccessLevel,
  GRANT_RELATIONSHIPS,
  GrantRelationship,
  SHARE_CATEGORIES,
  ShareCategory,
} from '../../../database/schema/shared-access-grants.schema';

export const RELATIONSHIP_MESSAGE = 'Informe quem é a pessoa com quem você compartilha.';
export const CATEGORIES_MESSAGE = 'Escolha ao menos uma categoria de dados válida, sem repetir.';

export class CreateInviteDto {
  @IsUUID('4', { message: 'targetProfileId must be a valid UUID v4' })
  @IsNotEmpty()
  targetProfileId!: string;

  @IsIn(ACCESS_LEVELS, {
    message: 'accessLevel must be VIEW_ONLY or CO_MANAGE',
  })
  @IsNotEmpty()
  accessLevel!: AccessLevel;

  @IsIn(GRANT_RELATIONSHIPS, { message: RELATIONSHIP_MESSAGE })
  relationship!: GrantRelationship;

  /** The client preselects `habits` (D2); the API requires an explicit, non-empty set. */
  @IsArray({ message: CATEGORIES_MESSAGE })
  @ArrayNotEmpty({ message: CATEGORIES_MESSAGE })
  @ArrayUnique({ message: CATEGORIES_MESSAGE })
  @IsIn(SHARE_CATEGORIES, { each: true, message: CATEGORIES_MESSAGE })
  categories!: ShareCategory[];

  /** Required as true when the target is a dependent profile (gap 9); checked by the service. */
  @IsOptional()
  @IsBoolean()
  dependentShareConfirmed?: boolean;
}
