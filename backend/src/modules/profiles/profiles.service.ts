import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { and, eq, isNull } from 'drizzle-orm';
import { DatabaseService, DrizzleTransaction } from '../../database/database.service';
import { profiles, ProfileType } from '../../database/schema/profiles.schema';
import {
  legalGuardianships,
  ADULT_RELATIONSHIPS,
  LgpdLegalBasis,
  RelationshipType,
} from '../../database/schema/legal-guardianships.schema';
import {
  sharedAccessGrants,
  AccessLevel,
  SHARE_CATEGORIES,
  ShareCategory,
} from '../../database/schema/shared-access-grants.schema';
import { users } from '../../database/schema/users.schema';
import { CreateDependentDto } from './dto/create-dependent.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ProfileAccessLevel, ProfileResponseDto } from './dto/profile-response.dto';

type ProfileRow = typeof profiles.$inferSelect;

const ADULT_AGE_YEARS = 18;

type ProfileAccess = {
  accessLevel: ProfileAccessLevel;
  readableCategories: ShareCategory[];
  writableCategories: ShareCategory[];
};

/** Open guardianship of the caller on an owned dependent, as returned to the app. */
type GuardianshipInfo = {
  relationshipType: RelationshipType;
  lgpdLegalBasis: LgpdLegalBasis;
};

const OWNER_ACCESS: ProfileAccess = {
  accessLevel: 'OWNER',
  readableCategories: [...SHARE_CATEGORIES],
  writableCategories: [...SHARE_CATEGORIES],
};

/**
 * Access from several grants on one profile, matching the RLS helpers (EXISTS across
 * grants): read = union of all grants' categories, write = union of CO_MANAGE grants'.
 * Null when there is no grant.
 */
function mergeGrants(grants: Array<{ accessLevel: AccessLevel; categories: ShareCategory[] | null }>): ProfileAccess | null {
  if (grants.length === 0) return null;
  const readable = new Set(grants.flatMap((g) => g.categories ?? []));
  const writable = new Set(grants.filter((g) => g.accessLevel === 'CO_MANAGE').flatMap((g) => g.categories ?? []));
  return {
    accessLevel: grants.some((g) => g.accessLevel === 'CO_MANAGE') ? 'CO_MANAGE' : 'VIEW_ONLY',
    readableCategories: SHARE_CATEGORIES.filter((c) => readable.has(c)),
    writableCategories: SHARE_CATEGORIES.filter((c) => writable.has(c)),
  };
}

/**
 * Full years between a YYYY-MM-DD birth date and the reference instant (UTC calendar).
 */
export function ageInYears(dateOfBirth: string, now: Date = new Date()): number {
  const [year, month, day] = dateOfBirth.slice(0, 10).split('-').map(Number);
  let age = now.getUTCFullYear() - year;
  const beforeBirthday =
    now.getUTCMonth() + 1 < month || (now.getUTCMonth() + 1 === month && now.getUTCDate() < day);
  if (beforeBirthday) age -= 1;
  return age;
}

@Injectable()
export class ProfilesService {
  constructor(
    @Inject(DatabaseService)
    private readonly databaseService: DatabaseService,
  ) {}

  async getProfilesForUser(userId: string): Promise<ProfileResponseDto[]> {
    this.assertUserId(userId);

    return this.databaseService.withRls(userId, async (tx) => {
      const owned = await tx.select().from(profiles).where(eq(profiles.accountOwnerId, userId));

      let primary = owned.find((p) => p.profileType === 'primary');
      if (!primary) {
        primary = await this.createPrimaryProfile(tx, userId);
      }

      const dependents = owned
        .filter((p) => p.profileType !== 'primary')
        .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());

      const sharedRows = await tx
        .select({
          profile: profiles,
          accessLevel: sharedAccessGrants.accessLevel,
          categories: sharedAccessGrants.categories,
        })
        .from(sharedAccessGrants)
        .innerJoin(profiles, eq(sharedAccessGrants.targetProfileId, profiles.id))
        .where(
          and(
            eq(sharedAccessGrants.granteeUserId, userId),
            eq(sharedAccessGrants.status, 'ACCEPTED'),
            isNull(sharedAccessGrants.revokedAt),
          ),
        );

      // Several grants may target the same profile: merge them (strongest level, category unions).
      const shared = new Map<string, { profile: ProfileRow; grants: typeof sharedRows }>();
      for (const row of sharedRows) {
        if (row.profile.accountOwnerId === userId) continue;
        const entry = shared.get(row.profile.id) ?? { profile: row.profile, grants: [] };
        entry.grants.push(row);
        shared.set(row.profile.id, entry);
      }

      const guardianships = new Map<string, GuardianshipInfo>();
      if (dependents.length > 0) {
        const rows = await tx
          .select({
            dependentProfileId: legalGuardianships.dependentProfileId,
            relationshipType: legalGuardianships.relationshipType,
            lgpdLegalBasis: legalGuardianships.lgpdLegalBasis,
          })
          .from(legalGuardianships)
          .where(and(eq(legalGuardianships.guardianUserId, userId), isNull(legalGuardianships.closedAt)));
        for (const row of rows) guardianships.set(row.dependentProfileId, row);
      }

      return [
        this.toResponse(primary, userId, OWNER_ACCESS),
        ...dependents.map((p) => this.toResponse(p, userId, OWNER_ACCESS, guardianships.get(p.id))),
        ...[...shared.values()].map((s) => this.toResponse(s.profile, userId, mergeGrants(s.grants)!)),
      ];
    });
  }

  async createDependent(userId: string, dto: CreateDependentDto): Promise<ProfileResponseDto> {
    this.assertUserId(userId);

    // Defense in depth: the DTO already enforces this, but the service must never
    // persist a dependent without explicit LGPD consent (Art. 14 or Art. 11, I).
    if (dto.lgpdConsent !== true) {
      throw new BadRequestException('Consentimento LGPD é obrigatório.');
    }

    const now = new Date();
    const age = ageInYears(dto.dateOfBirth, now);
    if (Number.isNaN(age) || age < 0) {
      throw new BadRequestException('Data de nascimento inválida.');
    }
    const profileType: ProfileType = age < ADULT_AGE_YEARS ? 'dependent_minor' : 'dependent_adult';
    // Minors: LGPD Art. 14. Adults (curatela, tomada de decisão apoiada): Art. 11, I.
    const lgpdLegalBasis: LgpdLegalBasis = age < ADULT_AGE_YEARS ? 'lgpd_art_14' : 'lgpd_art_11_i';

    return this.databaseService.withRls(userId, async (tx) => {
      const [profile] = await tx
        .insert(profiles)
        .values({
          accountOwnerId: userId,
          profileType,
          name: dto.name.trim(),
          dateOfBirth: dto.dateOfBirth.slice(0, 10),
          gender: dto.gender,
        })
        .returning();

      await tx.insert(legalGuardianships).values({
        guardianUserId: userId,
        dependentProfileId: profile.id,
        relationshipType: dto.relationshipType,
        lgpdConsentRecordedAt: now,
        lgpdLegalBasis,
        lgpdLegalBasisNotes: dto.lgpdLegalBasisNotes ?? null,
      });

      return this.toResponse(profile, userId, OWNER_ACCESS, {
        relationshipType: dto.relationshipType,
        lgpdLegalBasis,
      });
    });
  }

  async updateProfile(
    userId: string,
    profileId: string,
    dto: UpdateProfileDto,
  ): Promise<ProfileResponseDto> {
    this.assertUserId(userId);

    return this.databaseService.withRls(userId, async (tx) => {
      const profile = await this.findProfile(tx, profileId);

      let access = OWNER_ACCESS;
      if (profile.accountOwnerId !== userId) {
        const grantAccess = await this.getGrantAccess(tx, userId, profileId);
        if (grantAccess?.accessLevel !== 'CO_MANAGE') {
          throw new ForbiddenException('Sem permissão para editar este perfil.');
        }
        access = grantAccess;
      }

      const changes: Partial<typeof profiles.$inferInsert> = {};
      if (dto.name !== undefined) changes.name = dto.name.trim();
      if (dto.dateOfBirth !== undefined) {
        const age = ageInYears(dto.dateOfBirth);
        if (Number.isNaN(age) || age < 0) {
          throw new BadRequestException('Data de nascimento inválida.');
        }
        changes.dateOfBirth = dto.dateOfBirth.slice(0, 10);
      }
      if (dto.gender !== undefined) changes.gender = dto.gender;

      if (Object.keys(changes).length === 0) {
        return this.toResponse(profile, userId, access);
      }

      const [updated] = await tx
        .update(profiles)
        .set({ ...changes, updatedAt: new Date() })
        .where(eq(profiles.id, profileId))
        .returning();

      if (!updated) {
        throw new NotFoundException(`Profile with id ${profileId} not found.`);
      }

      return this.toResponse(updated, userId, access);
    });
  }

  async deleteProfile(userId: string, profileId: string): Promise<void> {
    this.assertUserId(userId);

    await this.databaseService.withRls(userId, async (tx) => {
      const profile = await this.findProfile(tx, profileId);

      if (profile.accountOwnerId !== userId) {
        throw new ForbiddenException('Somente o titular da conta pode excluir este perfil.');
      }
      if (profile.profileType === 'primary') {
        throw new BadRequestException('O perfil principal não pode ser excluído.');
      }

      // Guardianships and grants cascade via FK ON DELETE CASCADE.
      await tx
        .delete(profiles)
        .where(and(eq(profiles.id, profileId), eq(profiles.accountOwnerId, userId)));
    });
  }

  private async createPrimaryProfile(tx: DrizzleTransaction, userId: string): Promise<ProfileRow> {
    const [user] = await tx
      .select({ name: users.name, gender: users.gender, dateOfBirth: users.dateOfBirth })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundException('User not found.');
    }

    const [created] = await tx
      .insert(profiles)
      .values({
        accountOwnerId: userId,
        profileType: 'primary',
        name: user.name,
        gender: user.gender,
        dateOfBirth: user.dateOfBirth,
      })
      // Concurrent first requests (this list and ProfileContextGuard) may race to
      // create the primary profile; uq_profiles_primary_per_owner keeps one.
      .onConflictDoNothing()
      .returning();
    if (created) return created;

    const [existing] = await tx
      .select()
      .from(profiles)
      .where(and(eq(profiles.accountOwnerId, userId), eq(profiles.profileType, 'primary')))
      .limit(1);
    if (!existing) {
      throw new NotFoundException('Primary profile not found.');
    }
    return existing;
  }

  private async findProfile(tx: DrizzleTransaction, profileId: string): Promise<ProfileRow> {
    const [profile] = await tx.select().from(profiles).where(eq(profiles.id, profileId)).limit(1);
    if (!profile) {
      throw new NotFoundException(`Profile with id ${profileId} not found.`);
    }
    return profile;
  }

  private async getGrantAccess(
    tx: DrizzleTransaction,
    userId: string,
    profileId: string,
  ): Promise<ProfileAccess | null> {
    const grants = await tx
      .select({ accessLevel: sharedAccessGrants.accessLevel, categories: sharedAccessGrants.categories })
      .from(sharedAccessGrants)
      .where(
        and(
          eq(sharedAccessGrants.targetProfileId, profileId),
          eq(sharedAccessGrants.granteeUserId, userId),
          eq(sharedAccessGrants.status, 'ACCEPTED'),
          isNull(sharedAccessGrants.revokedAt),
        ),
      );

    return mergeGrants(grants);
  }

  private toResponse(
    profile: ProfileRow,
    userId: string,
    access: ProfileAccess,
    guardianship?: GuardianshipInfo,
  ): ProfileResponseDto {
    const ownership =
      profile.accountOwnerId !== userId
        ? 'shared'
        : profile.profileType === 'primary'
          ? 'own'
          : 'dependent';

    return {
      id: profile.id,
      name: profile.name,
      profileType: profile.profileType,
      dateOfBirth: profile.dateOfBirth ?? null,
      gender: profile.gender ?? null,
      ownership,
      accessLevel: access.accessLevel,
      readableCategories: access.readableCategories,
      writableCategories: access.writableCategories,
      relationshipType: guardianship?.relationshipType ?? null,
      lgpdLegalBasis: guardianship?.lgpdLegalBasis ?? null,
      legalBasisNeedsConfirmation:
        guardianship !== undefined &&
        (ADULT_RELATIONSHIPS as readonly string[]).includes(guardianship.relationshipType) &&
        guardianship.lgpdLegalBasis === 'lgpd_art_14',
    };
  }

  private assertUserId(userId: string): void {
    if (!userId) {
      throw new BadRequestException('User ID is required');
    }
  }
}
