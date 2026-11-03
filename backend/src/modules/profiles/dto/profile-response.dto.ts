import { ProfileType } from '../../../database/schema/profiles.schema';
import { LgpdLegalBasis, RelationshipType } from '../../../database/schema/legal-guardianships.schema';
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
  /** Relationship of the caller's open guardianship on an owned dependent; null otherwise. */
  relationshipType!: RelationshipType | null;
  /** LGPD article the guardian consented under (owned dependents only); null otherwise. */
  lgpdLegalBasis!: LgpdLegalBasis | null;
  /** True for an adult dependent still recorded under Art. 14: the guardian should re-confirm under Art. 11, I. */
  legalBasisNeedsConfirmation!: boolean;
}
