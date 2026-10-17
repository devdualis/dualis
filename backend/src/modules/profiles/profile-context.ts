import {
  BadRequestException,
  CanActivate,
  createParamDecorator,
  ExecutionContext,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  SetMetadata,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { and, eq, sql } from 'drizzle-orm';
import { DatabaseService, DrizzleTransaction } from '../../database/database.service';
import { profiles } from '../../database/schema/profiles.schema';
import { users } from '../../database/schema/users.schema';

/** Optional request header selecting whose clinical data the request reads or writes. */
export const PROFILE_HEADER = 'x-profile-id';

export type ProfileAccessMode = 'read' | 'write';

export type ProfileContext = {
  profileId: string;
  accessLevel: 'OWNER' | 'CO_MANAGE' | 'VIEW_ONLY';
};

export interface ProfileAccessOptions {
  /**
   * Let unauthenticated requests through without a profile context (used behind
   * OptionalJwtAuthGuard, e.g. anonymous emergency events). A header without a user is still 401.
   */
  allowAnonymous?: boolean;
}

const PROFILE_ACCESS_KEY = 'profileAccess';

type ProfileAccessMetadata = ProfileAccessOptions & { mode: ProfileAccessMode };

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Access a handler needs on the active profile. Without it, ProfileContextGuard requires 'read'. */
export const ProfileAccess = (mode: ProfileAccessMode, options: ProfileAccessOptions = {}) =>
  SetMetadata(PROFILE_ACCESS_KEY, { mode, ...options } satisfies ProfileAccessMetadata);

/** The ProfileContext resolved by ProfileContextGuard (undefined only for allowed anonymous requests). */
export const ActiveProfile = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): ProfileContext | undefined =>
    ctx.switchToHttp().getRequest().profileContext,
);

/**
 * Resolves X-Profile-Id into req.profileContext. Use after JwtAuthGuard.
 * - No header: the caller's primary profile (created lazily), OWNER.
 * - Header: owner or ACCEPTED, non-revoked grantee, checked under RLS with the same
 *   SQL helpers the clinical table policies use. Anything else is 403.
 * - 'write' mode rejects VIEW_ONLY.
 */
@Injectable()
export class ProfileContextGuard implements CanActivate {
  constructor(
    @Inject(Reflector) private readonly reflector: Reflector,
    @Inject(DatabaseService) private readonly databaseService: DatabaseService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const metadata = this.reflector.getAllAndOverride<ProfileAccessMetadata | undefined>(
      PROFILE_ACCESS_KEY,
      [context.getHandler(), context.getClass()],
    );
    const mode: ProfileAccessMode = metadata?.mode ?? 'read';

    const request = context.switchToHttp().getRequest();
    const rawHeader = request.headers?.[PROFILE_HEADER];
    const userId: string | undefined = request.user?.id || request.user?.userId || request.user?.sub;

    if (!userId) {
      // Anonymous-allowed routes (emergency audit) must never fail: an expired
      // session that still sends X-Profile-Id is recorded as anonymous instead.
      if (metadata?.allowAnonymous) {
        return true;
      }
      throw new UnauthorizedException();
    }

    let requestedProfileId: string | undefined;
    if (rawHeader !== undefined) {
      if (typeof rawHeader !== 'string' || !UUID_PATTERN.test(rawHeader.trim())) {
        throw new BadRequestException(`Cabeçalho ${PROFILE_HEADER} inválido.`);
      }
      requestedProfileId = rawHeader.trim().toLowerCase();
    }

    const profileContext = await this.databaseService.withRls(userId, (tx) =>
      requestedProfileId
        ? this.resolveRequested(tx, requestedProfileId)
        : this.resolvePrimary(tx, userId),
    );

    if (mode === 'write' && profileContext.accessLevel === 'VIEW_ONLY') {
      throw new ForbiddenException('Acesso somente leitura a este perfil.');
    }

    request.profileContext = profileContext;
    return true;
  }

  private async resolveRequested(tx: DrizzleTransaction, profileId: string): Promise<ProfileContext> {
    const result = await tx.execute(sql`
      SELECT app_owns_profile(${profileId}::uuid) AS is_owner,
             app_has_profile_grant(${profileId}::uuid, false) AS can_read,
             app_has_profile_grant(${profileId}::uuid, true) AS can_co_manage
    `);
    const row = (result as unknown as { rows: Array<Record<string, boolean>> }).rows[0];

    if (row?.is_owner) return { profileId, accessLevel: 'OWNER' };
    if (row?.can_co_manage) return { profileId, accessLevel: 'CO_MANAGE' };
    if (row?.can_read) return { profileId, accessLevel: 'VIEW_ONLY' };
    // Same answer for unknown and foreign profiles: no enumeration.
    throw new ForbiddenException('Sem acesso a este perfil.');
  }

  private async resolvePrimary(tx: DrizzleTransaction, userId: string): Promise<ProfileContext> {
    const existing = await this.findPrimaryId(tx, userId);
    if (existing) return { profileId: existing, accessLevel: 'OWNER' };

    const [user] = await tx
      .select({ name: users.name, gender: users.gender, dateOfBirth: users.dateOfBirth })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);
    if (!user) {
      throw new NotFoundException('User not found.');
    }

    // A concurrent request may create it first: the partial unique index from
    // migration 0014 turns that into a no-op, and the re-read picks the winner.
    const [created] = await tx
      .insert(profiles)
      .values({
        accountOwnerId: userId,
        profileType: 'primary',
        name: user.name,
        gender: user.gender,
        dateOfBirth: user.dateOfBirth,
      })
      .onConflictDoNothing()
      .returning({ id: profiles.id });

    const profileId = created?.id ?? (await this.findPrimaryId(tx, userId));
    if (!profileId) {
      throw new NotFoundException('Primary profile not found.');
    }
    return { profileId, accessLevel: 'OWNER' };
  }

  private async findPrimaryId(tx: DrizzleTransaction, userId: string): Promise<string | undefined> {
    const [row] = await tx
      .select({ id: profiles.id })
      .from(profiles)
      .where(and(eq(profiles.accountOwnerId, userId), eq(profiles.profileType, 'primary')))
      .orderBy(profiles.createdAt)
      .limit(1);
    return row?.id;
  }
}
