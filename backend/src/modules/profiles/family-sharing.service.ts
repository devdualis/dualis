import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from "@nestjs/common";
import { and, eq, isNull, sql } from "drizzle-orm";
import { randomInt } from "node:crypto";
import { DatabaseService } from "../../database/database.service";
import { profiles } from "../../database/schema/profiles.schema";
import {
  AccessLevel,
  sharedAccessGrants,
} from "../../database/schema/shared-access-grants.schema";
import {
  AcceptedGrantResponseDto,
  InviteCreatedResponseDto,
  ListGrantsResponseDto,
  RevokeGrantResponseDto,
} from "./dto/grant-response.dto";

export const INVITE_CODE_CHARS = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";
export const INVITE_CODE_LENGTH = 6;
export const INVITE_TTL_HOURS = 72;
export const MAX_INVITE_COLLISION_RETRIES = 5;

/**
 * Generates an uppercase 6-character alphanumeric invite code using node:crypto,
 * excluding ambiguous characters 0, O, 1, and I.
 */
export function generateInviteCode(): string {
  let code = "";
  for (let i = 0; i < INVITE_CODE_LENGTH; i++) {
    code += INVITE_CODE_CHARS[randomInt(0, INVITE_CODE_CHARS.length)];
  }
  return code;
}

@Injectable()
export class FamilySharingService {
  constructor(
    @Inject(DatabaseService)
    private readonly databaseService: DatabaseService,
  ) {}

  private assertUserId(userId: string): void {
    if (!userId || typeof userId !== "string" || userId.trim().length === 0) {
      throw new BadRequestException(
        "A valid non-empty userId string is required.",
      );
    }
  }

  /**
   * Creates a family sharing invitation with a 72-hour TTL.
   * The caller must own the target profile (403 otherwise).
   * Retries on unique code violation up to 5 times.
   */
  async createInvite(
    userId: string,
    targetProfileId: string,
    accessLevel: AccessLevel,
  ): Promise<InviteCreatedResponseDto> {
    this.assertUserId(userId);

    if (!targetProfileId) {
      throw new BadRequestException("targetProfileId is required.");
    }

    return this.databaseService.withRls(userId, async (tx) => {
      const [targetProfile] = await tx
        .select()
        .from(profiles)
        .where(eq(profiles.id, targetProfileId));

      if (!targetProfile || targetProfile.accountOwnerId !== userId) {
        throw new ForbiddenException("You do not own this profile");
      }

      const expiresAt = new Date(
        Date.now() + INVITE_TTL_HOURS * 60 * 60 * 1000,
      );

      let grant: typeof sharedAccessGrants.$inferSelect | undefined;
      let attempts = 0;

      while (attempts < MAX_INVITE_COLLISION_RETRIES) {
        attempts++;
        const inviteCode = generateInviteCode();

        try {
          // Nested transaction = SAVEPOINT, so a unique violation does not abort the outer transaction.
          const [inserted] = await tx.transaction((sp) =>
            sp
              .insert(sharedAccessGrants)
              .values({
                granterUserId: userId,
                targetProfileId,
                accessLevel,
                inviteCode,
                status: "PENDING",
                expiresAt,
              })
              .returning(),
          );

          grant = inserted;
          break;
        } catch (err: any) {
          // PostgreSQL unique violation code 23505
          if (
            err?.code === "23505" &&
            attempts < MAX_INVITE_COLLISION_RETRIES
          ) {
            continue;
          }
          throw err;
        }
      }

      if (!grant) {
        throw new InternalServerErrorException(
          "Failed to generate a unique invite code",
        );
      }

      return {
        id: grant.id,
        inviteCode: grant.inviteCode,
        accessLevel: grant.accessLevel,
        targetProfileId: grant.targetProfileId,
        expiresAt: grant.expiresAt,
      };
    });
  }

  /**
   * Accepts a pending family sharing invitation via the SECURITY DEFINER SQL function
   * accept_shared_access_invite(p_invite_code).
   */
  async acceptInvite(
    userId: string,
    inviteCode: string,
  ): Promise<AcceptedGrantResponseDto> {
    this.assertUserId(userId);

    if (!inviteCode || typeof inviteCode !== "string") {
      throw new BadRequestException("Invite code is required");
    }

    const normalizedCode = inviteCode.trim().toUpperCase();
    if (!normalizedCode) {
      throw new BadRequestException("Invite code is required");
    }

    return this.databaseService.withRls(userId, async (tx) => {
      try {
        const result = await tx.execute(
          sql`SELECT * FROM accept_shared_access_invite(${normalizedCode})`,
        );

        const rows = (result as any).rows ?? result;
        if (!rows || !Array.isArray(rows) || rows.length === 0) {
          throw new NotFoundException("Invite not found or expired");
        }

        const row = rows[0];
        return {
          id: row.id,
          granterUserId: row.granter_user_id ?? row.granterUserId,
          targetProfileId: row.target_profile_id ?? row.targetProfileId,
          granteeUserId: row.grantee_user_id ?? row.granteeUserId,
          accessLevel: row.access_level ?? row.accessLevel,
          inviteCode: row.invite_code ?? row.inviteCode,
          status: row.status,
          expiresAt: row.expires_at ?? row.expiresAt,
          acceptedAt: row.accepted_at ?? row.acceptedAt,
          revokedAt: row.revoked_at ?? row.revokedAt,
          createdAt: row.created_at ?? row.createdAt,
        };
      } catch (err: any) {
        if (
          err instanceof NotFoundException ||
          err instanceof BadRequestException
        ) {
          throw err;
        }

        const message = err?.message || "";
        if (err?.code === "P0001" || message.includes("SELF_GRANT")) {
          throw new BadRequestException("Cannot share access with yourself");
        }

        throw err;
      }
    });
  }

  /**
   * Revokes an existing grant.
   * Caller must be either granter or grantee (404 otherwise, does not leak existence).
   * Operation is idempotent if already REVOKED.
   */
  async revokeGrant(
    userId: string,
    grantId: string,
  ): Promise<RevokeGrantResponseDto> {
    this.assertUserId(userId);

    if (!grantId) {
      throw new BadRequestException("grantId is required");
    }

    return this.databaseService.withRls(userId, async (tx) => {
      const [grant] = await tx
        .select()
        .from(sharedAccessGrants)
        .where(eq(sharedAccessGrants.id, grantId));

      if (!grant) {
        throw new NotFoundException("Grant not found");
      }

      if (grant.granterUserId !== userId && grant.granteeUserId !== userId) {
        throw new NotFoundException("Grant not found");
      }

      if (grant.status === "REVOKED") {
        return {
          id: grant.id,
          status: grant.status,
          revokedAt: grant.revokedAt,
        };
      }

      const now = new Date();
      const [updated] = await tx
        .update(sharedAccessGrants)
        .set({
          status: "REVOKED",
          revokedAt: now,
        })
        .where(eq(sharedAccessGrants.id, grantId))
        .returning();

      return {
        id: updated.id,
        status: updated.status,
        revokedAt: updated.revokedAt,
      };
    });
  }

  /**
   * Lists outgoing grants (created by user) and incoming grants (accepted by user).
   * - Outgoing PENDING past expiresAt are reported as EXPIRED.
   * - Incoming only lists active shares (status ACCEPTED and revokedAt is null).
   */
  async listGrants(userId: string): Promise<ListGrantsResponseDto> {
    this.assertUserId(userId);

    return this.databaseService.withRls(userId, async (tx) => {
      const now = new Date();

      const outgoingRows = await tx
        .select({
          grant: sharedAccessGrants,
          targetProfileName: profiles.name,
        })
        .from(sharedAccessGrants)
        .leftJoin(profiles, eq(sharedAccessGrants.targetProfileId, profiles.id))
        .where(eq(sharedAccessGrants.granterUserId, userId));

      const outgoing = outgoingRows.map(({ grant, targetProfileName }) => {
        let effectiveStatus = grant.status;
        if (effectiveStatus === "PENDING" && new Date(grant.expiresAt) <= now) {
          effectiveStatus = "EXPIRED";
        }

        return {
          id: grant.id,
          targetProfileId: grant.targetProfileId,
          targetProfileName: targetProfileName ?? "",
          accessLevel: grant.accessLevel,
          status: effectiveStatus,
          inviteCode: grant.inviteCode,
          granteeUserId: grant.granteeUserId,
          expiresAt: grant.expiresAt,
          acceptedAt: grant.acceptedAt,
          revokedAt: grant.revokedAt,
          createdAt: grant.createdAt,
        };
      });

      const incomingRows = await tx
        .select({
          grant: sharedAccessGrants,
          targetProfileName: profiles.name,
        })
        .from(sharedAccessGrants)
        .leftJoin(profiles, eq(sharedAccessGrants.targetProfileId, profiles.id))
        .where(
          and(
            eq(sharedAccessGrants.granteeUserId, userId),
            eq(sharedAccessGrants.status, "ACCEPTED"),
            isNull(sharedAccessGrants.revokedAt),
          ),
        );

      const incoming = incomingRows.map(({ grant, targetProfileName }) => ({
        id: grant.id,
        granterUserId: grant.granterUserId,
        targetProfileId: grant.targetProfileId,
        targetProfileName: targetProfileName ?? "",
        accessLevel: grant.accessLevel,
        status: grant.status,
        expiresAt: grant.expiresAt,
        acceptedAt: grant.acceptedAt,
        createdAt: grant.createdAt,
      }));

      return {
        outgoing,
        incoming,
      };
    });
  }
}
