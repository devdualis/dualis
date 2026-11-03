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
import { SHARE_CATEGORIES, ShareCategory } from '../../database/schema/shared-access-grants.schema';
import { users } from '../../database/schema/users.schema';

/** Optional request header selecting whose clinical data the request reads or writes. */
export const PROFILE_HEADER = 'x-profile-id';

export type ProfileAccessMode = 'read' | 'write';

export type ProfileContext = {
  profileId: string;
  accessLevel: 'OWNER' | 'CO_MANAGE' | 'VIEW_ONLY';
  /** Categories the caller may read on this profile, in SHARE_CATEGORIES order (all for OWNER). */
  readableCategories: ShareCategory[];
  /** Categories the caller may write on this profile, in SHARE_CATEGORIES order (all for OWNER). */
  writableCategories: ShareCategory[];
};

export const CATEGORY_NOT_SHARED_MESSAGE = 'Esta categoria não foi compartilhada com você.';

/** Category of a journal entry from its area; same rule as app_journal_area_category (0028). */
export function journalAreaCategory(area?: string | null): ShareCategory {
  return area === 'physical' ? 'physical_journal' : 'emotional_journal';
}

/**
 * 403 unless the caller may use the category in this mode. For handlers whose category
 * depends on the body (journal entries, option suggestions). RLS stays the authority.
 */
export function assertCategory(profile: ProfileContext, mode: ProfileAccessMode, category: ShareCategory): void {
  const allowed = mode === 'write' ? profile.writableCategories : profile.readableCategories;
  if (!allowed.includes(category)) {
    throw new ForbiddenException(CATEGORY_NOT_SHARED_MESSAGE);
  }
}

const ownerContext = (profileId: string): ProfileContext => ({
  profileId,
  accessLevel: 'OWNER',
  readableCategories: [...SHARE_CATEGORIES],
  writableCategories: [...SHARE_CATEGORIES],
});

export interface ProfileAccessOptions {
  /**
   * Let unauthenticated requests through without a profile context (used behind
   * OptionalJwtAuthGuard, e.g. anonymous emergency events). A header without a user is ignored.
   */
  allowAnonymous?: boolean;
  /**
   * Use X-Profile-Id only when the caller owns that profile (primary or dependent). A profile
   * shared by another account, revoked or unknown resolves to the caller's primary profile
   * instead of being used or refused. For records about the person holding the phone, not
   * the profile on screen (help-resource events).
   */
  ownProfilesOnly?: boolean;
  /**
   * Data category (or categories, all required) the route touches. A shared profile whose
   * grants do not open it in this mode gets 403 CATEGORY_NOT_SHARED_MESSAGE instead of the
   * empty result RLS would give. Leave unset for routes that mix categories.
   */
  category?: ShareCategory | ShareCategory[];
}

const PROFILE_ACCESS_KEY = 'profileAccess';

type ProfileAccessMetadata = ProfileAccessOptions & { mode: ProfileAccessMode };

/** SHARE_CATEGORIES (in order) present in a DB array; unknown values are dropped. */
function knownCategories(value: unknown): ShareCategory[] {
  const values = Array.isArray(value) ? value : [];
  return SHARE_CATEGORIES.filter((category) => values.includes(category));
}

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
 * - ownProfilesOnly: a header naming a profile the caller does not own falls back to
 *   the primary profile.
 * - 'write' mode rejects VIEW_ONLY.
 * - options.category must be readable (or writable, in 'write' mode) on the profile.
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

    const profileContext = await this.databaseService.withRls(userId, (tx) => {
      if (!requestedProfileId) return this.resolvePrimary(tx, userId);
      return metadata?.ownProfilesOnly
        ? this.resolveOwnedOrPrimary(tx, userId, requestedProfileId)
        : this.resolveRequested(tx, requestedProfileId);
    });

    if (mode === 'write' && profileContext.accessLevel === 'VIEW_ONLY') {
      throw new ForbiddenException('Acesso somente leitura a este perfil.');
    }

    if (metadata?.category !== undefined) {
      const categories = Array.isArray(metadata.category) ? metadata.category : [metadata.category];
      for (const category of categories) {
        assertCategory(profileContext, mode, category);
      }
    }

    request.profileContext = profileContext;
    return true;
  }

  private async resolveRequested(tx: DrizzleTransaction, profileId: string): Promise<ProfileContext> {
    const categories = sql`ARRAY[${sql.join(
      SHARE_CATEGORIES.map((category) => sql`${category}`),
      sql`, `,
    )}]::text[]`;
    const result = await tx.execute(sql`
      SELECT app_owns_profile(${profileId}::uuid) AS is_owner,
             app_has_profile_grant(${profileId}::uuid, false) AS can_read,
             app_has_profile_grant(${profileId}::uuid, true) AS can_co_manage,
             ARRAY(SELECT c FROM unnest(${categories}) AS c
                   WHERE app_can_read_profile_category(${profileId}::uuid, c)) AS readable,
             ARRAY(SELECT c FROM unnest(${categories}) AS c
                   WHERE app_can_write_profile_category(${profileId}::uuid, c)) AS writable
    `);
    const row = (result as unknown as { rows: Array<Record<string, unknown>> }).rows[0];

    if (row?.is_owner) return ownerContext(profileId);
    const accessLevel = row?.can_co_manage ? 'CO_MANAGE' : row?.can_read ? 'VIEW_ONLY' : undefined;
    // Same answer for unknown and foreign profiles: no enumeration.
    if (!accessLevel) throw new ForbiddenException('Sem acesso a este perfil.');
    return {
      profileId,
      accessLevel,
      readableCategories: knownCategories(row?.readable),
      writableCategories: knownCategories(row?.writable),
    };
  }

  private async resolveOwnedOrPrimary(
    tx: DrizzleTransaction,
    userId: string,
    profileId: string,
  ): Promise<ProfileContext> {
    const requested = await this.resolveRequested(tx, profileId).catch((err: unknown) => {
      if (err instanceof ForbiddenException) return undefined;
      throw err;
    });
    return requested?.accessLevel === 'OWNER' ? requested : this.resolvePrimary(tx, userId);
  }

  private async resolvePrimary(tx: DrizzleTransaction, userId: string): Promise<ProfileContext> {
    const existing = await this.findPrimaryId(tx, userId);
    if (existing) return ownerContext(existing);

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
    return ownerContext(profileId);
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
