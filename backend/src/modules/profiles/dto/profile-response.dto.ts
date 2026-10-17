import { ProfileType } from '../../../database/schema/profiles.schema';

export type ProfileOwnership = 'own' | 'dependent' | 'shared';
export type ProfileAccessLevel = 'OWNER' | 'VIEW_ONLY' | 'CO_MANAGE';

export class ProfileResponseDto {
  id!: string;
  name!: string;
  profileType!: ProfileType;
  dateOfBirth!: string | null;
  gender!: string | null;
  avatarUrl!: string | null;
  ownership!: ProfileOwnership;
  accessLevel!: ProfileAccessLevel;
}
