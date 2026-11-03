import { ProfileType } from '../../../database/schema/profiles.schema';
import { ShareCategory } from '../../../database/schema/shared-access-grants.schema';

export type ProfileOwnership = 'own' | 'dependent' | 'shared';
export type ProfileAccessLevel = 'OWNER' | 'VIEW_ONLY' | 'CO_MANAGE';

export class ProfileResponseDto {
  id!: string;
  name!: string;
  profileType!: ProfileType;
  dateOfBirth!: string | null;
  gender!: string | null;
  ownership!: ProfileOwnership;
  accessLevel!: ProfileAccessLevel;
  /** Categories the caller may read on this profile, in SHARE_CATEGORIES order (all for owners). */
  readableCategories!: ShareCategory[];
  /** Categories the caller may write: owners all, grantees the union of their CO_MANAGE grants. */
  writableCategories!: ShareCategory[];
}
