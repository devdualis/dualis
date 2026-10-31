import { AccessLevel, GrantStatus } from '../../../database/schema/shared-access-grants.schema';

export class InviteCreatedResponseDto {
  id!: string;
  inviteCode!: string;
  accessLevel!: AccessLevel;
  targetProfileId!: string;
  expiresAt!: Date | string;
}

export class AcceptedGrantResponseDto {
  id!: string;
  granterUserId!: string;
  targetProfileId!: string;
  granteeUserId!: string | null;
  accessLevel!: AccessLevel;
  inviteCode!: string;
  status!: GrantStatus;
  expiresAt!: Date | string;
  acceptedAt!: Date | string | null;
  revokedAt!: Date | string | null;
  createdAt!: Date | string;
}

export class RevokeGrantResponseDto {
  id!: string;
  status!: GrantStatus;
  revokedAt!: Date | string | null;
}

export class OutgoingGrantItemDto {
  id!: string;
  targetProfileId!: string;
  targetProfileName!: string;
  accessLevel!: AccessLevel;
  status!: GrantStatus;
  inviteCode!: string;
  granteeUserId!: string | null;
  /** Who accepted the invite, so the owner can check who has access. */
  granteeName!: string | null;
  granteeEmail!: string | null;
  expiresAt!: Date | string;
  acceptedAt!: Date | string | null;
  revokedAt!: Date | string | null;
  createdAt!: Date | string;
}

export class IncomingGrantItemDto {
  id!: string;
  granterUserId!: string;
  targetProfileId!: string;
  targetProfileName!: string;
  accessLevel!: AccessLevel;
  status!: GrantStatus;
  expiresAt!: Date | string;
  acceptedAt!: Date | string | null;
  createdAt!: Date | string;
}

export class ListGrantsResponseDto {
  outgoing!: OutgoingGrantItemDto[];
  incoming!: IncomingGrantItemDto[];
}
