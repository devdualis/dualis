import { ArrayNotEmpty, ArrayUnique, IsArray, IsBoolean, IsIn, IsOptional } from 'class-validator';
import {
  GRANT_RELATIONSHIPS,
  GrantRelationship,
  SHARE_CATEGORIES,
  ShareCategory,
} from '../../../database/schema/shared-access-grants.schema';
import { CATEGORIES_MESSAGE, RELATIONSHIP_MESSAGE } from './create-invite.dto';

/**
 * Granter edit of a grant (PATCH /v1/family-sharing/grants/:id). At least one of
 * categories / relationship is required; the service answers 400 otherwise.
 */
export class UpdateGrantDto {
  @IsOptional()
  @IsArray({ message: CATEGORIES_MESSAGE })
  @ArrayNotEmpty({ message: CATEGORIES_MESSAGE })
  @ArrayUnique({ message: CATEGORIES_MESSAGE })
  @IsIn(SHARE_CATEGORIES, { each: true, message: CATEGORIES_MESSAGE })
  categories?: ShareCategory[];

  @IsOptional()
  @IsIn(GRANT_RELATIONSHIPS, { message: RELATIONSHIP_MESSAGE })
  relationship?: GrantRelationship;

  /** Required as true when categories change on a dependent profile's grant (gap 9). */
  @IsOptional()
  @IsBoolean()
  dependentShareConfirmed?: boolean;
}
