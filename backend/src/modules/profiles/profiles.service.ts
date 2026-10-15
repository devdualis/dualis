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
import { legalGuardianships } from '../../database/schema/legal-guardianships.schema';
import { sharedAccessGrants, AccessLevel } from '../../database/schema/shared-access-grants.schema';
import { users } from '../../database/schema/users.schema';
import { CreateDependentDto } from './dto/create-dependent.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ProfileAccessLevel, ProfileResponseDto } from './dto/profile-response.dto';

type ProfileRow = typeof profiles.$inferSelect;

const ADULT_AGE_YEARS = 18;

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
        .select({ profile: profiles, accessLevel: sharedAccessGrants.accessLevel })
        .from(sharedAccessGrants)
        .innerJoin(profiles, eq(sharedAccessGrants.targetProfileId, profiles.id))
        .where(
          and(
            eq(sharedAccessGrants.granteeUserId, userId),
            eq(sharedAccessGrants.status, 'ACCEPTED'),
            isNull(sharedAccessGrants.revokedAt),
          ),
        );

      // Several grants may target the same profile: keep the strongest access level.
      const shared = new Map<string, { profile: ProfileRow; accessLevel: AccessLevel }>();
      for (const row of sharedRows) {
        if (row.profile.accountOwnerId === userId) continue;
        const existing = shared.get(row.profile.id);
        if (!existing || row.accessLevel === 'CO_MANAGE') {
          shared.set(row.profile.id, row);
        }
      }

      return [
        this.toResponse(primary, userId, 'OWNER'),
        ...dependents.map((p) => this.toResponse(p, userId, 'OWNER')),
        ...[...shared.values()].map((s) => this.toResponse(s.profile, userId, s.accessLevel)),
      ];
    });
  }

  async createDependent(userId: string, dto: CreateDependentDto): Promise<ProfileResponseDto> {
    this.assertUserId(userId);

    // Defense in depth: the DTO already enforces this, but the service must never
    // persist a dependent without explicit LGPD Art. 14 consent.
    if (dto.lgpdConsent !== true) {
      throw new BadRequestException('Consentimento LGPD Art. 14 é obrigatório.');
    }

    const now = new Date();
    const age = ageInYears(dto.dateOfBirth, now);
    if (Number.isNaN(age) || age < 0) {
      throw new BadRequestException('Data de nascimento inválida.');
    }
    const profileType: ProfileType = age < ADULT_AGE_YEARS ? 'dependent_minor' : 'dependent_adult';

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
        lgpdLegalBasisNotes: dto.lgpdLegalBasisNotes ?? null,
      });

      return this.toResponse(profile, userId, 'OWNER');
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

      let accessLevel: ProfileAccessLevel = 'OWNER';
      if (profile.accountOwnerId !== userId) {
        const grantLevel = await this.getGrantAccessLevel(tx, userId, profileId);
        if (grantLevel !== 'CO_MANAGE') {
          throw new ForbiddenException('Sem permissão para editar este perfil.');
        }
        accessLevel = grantLevel;
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
      if (dto.avatarUrl !== undefined) changes.avatarUrl = dto.avatarUrl;

      if (Object.keys(changes).length === 0) {
        return this.toResponse(profile, userId, accessLevel);
      }

      const [updated] = await tx
        .update(profiles)
        .set({ ...changes, updatedAt: new Date() })
        .where(eq(profiles.id, profileId))
        .returning();

      if (!updated) {
        throw new NotFoundException(`Profile with id ${profileId} not found.`);
      }

      return this.toResponse(updated, userId, accessLevel);
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
      .returning();

    return created;
  }

  private async findProfile(tx: DrizzleTransaction, profileId: string): Promise<ProfileRow> {
    const [profile] = await tx.select().from(profiles).where(eq(profiles.id, profileId)).limit(1);
    if (!profile) {
      throw new NotFoundException(`Profile with id ${profileId} not found.`);
    }
    return profile;
  }

  private async getGrantAccessLevel(
    tx: DrizzleTransaction,
    userId: string,
    profileId: string,
  ): Promise<ProfileAccessLevel | null> {
    const grants = await tx
      .select({ accessLevel: sharedAccessGrants.accessLevel })
      .from(sharedAccessGrants)
      .where(
        and(
          eq(sharedAccessGrants.targetProfileId, profileId),
          eq(sharedAccessGrants.granteeUserId, userId),
          eq(sharedAccessGrants.status, 'ACCEPTED'),
          isNull(sharedAccessGrants.revokedAt),
        ),
      );

    if (grants.length === 0) return null;
    return grants.some((g) => g.accessLevel === 'CO_MANAGE') ? 'CO_MANAGE' : 'VIEW_ONLY';
  }

  private toResponse(
    profile: ProfileRow,
    userId: string,
    accessLevel: ProfileAccessLevel,
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
      avatarUrl: profile.avatarUrl ?? null,
      ownership,
      accessLevel,
    };
  }

  private assertUserId(userId: string): void {
    if (!userId) {
      throw new BadRequestException('User ID is required');
    }
  }
}
