import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpStatus,
  Inject,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import { and, eq, inArray, isNull, sql } from 'drizzle-orm';
import { EmailService } from '../../common/email/email.service';
import { HOUR_MS, RateLimiter } from '../../common/http/rate-limiter';
import { DatabaseService, DrizzleTransaction } from '../../database/database.service';
import { profiles, ProfileType } from '../../database/schema/profiles.schema';
import {
  legalGuardianships,
  ADULT_RELATIONSHIPS,
  MINOR_RELATIONSHIPS,
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
import {
  generateInviteCode,
  INVITE_TTL_HOURS,
  MAX_FAILED_INVITE_ACCEPTS,
  FAILED_INVITE_ACCEPT_WINDOW_MS,
  MAX_INVITE_COLLISION_RETRIES,
} from './family-sharing.service';
import { CreateDependentDto } from './dto/create-dependent.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { HandoverStatus, ProfileAccessLevel, ProfileResponseDto } from './dto/profile-response.dto';

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
  /** Expiry of the current hand-over code, if one was generated (D3). */
  handoverCodeExpiresAt?: Date | null;
};

/** Claim refusals raised by claim_dependent_profile (migration 0028) and their HTTP mapping. */
const CLAIM_REFUSALS = {
  CLAIM_BY_GUARDIAN: {
    status: HttpStatus.FORBIDDEN,
    message: 'Este código deve ser usado na conta da pessoa que completou 18 anos, não na conta de quem o gerou.',
  },
  CLAIM_NOT_ADULT: {
    status: HttpStatus.CONFLICT,
    message: 'O perfil só pode passar para a conta própria depois que a pessoa completar 18 anos.',
  },
  CLAIM_ACCOUNT_HAS_DATA: {
    status: HttpStatus.CONFLICT,
    message: 'Esta conta já tem registros. Use uma conta nova para receber o perfil.',
  },
} as const;

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

/**
 * D3: a minor's guardianship (parent / legal_guardian) whose dependent is now 18 or older
 * is due to be handed over to the person's own account.
 */
function isHandoverDue(dateOfBirth: string | null, relationshipType: RelationshipType, now: Date = new Date()): boolean {
  if (!dateOfBirth) return false;
  return (
    (MINOR_RELATIONSHIPS as readonly string[]).includes(relationshipType) &&
    ageInYears(dateOfBirth, now) >= ADULT_AGE_YEARS
  );
}

function profileTypeForAge(age: number): ProfileType {
  return age < ADULT_AGE_YEARS ? 'dependent_minor' : 'dependent_adult';
}

/**
 * Legal representation must match the dependent's age: minors are under poder familiar
 * (parent) or tutela (legal_guardian); adults under curatela (curator) or tomada de
 * decisão apoiada (supported_decision). Throws 400 otherwise.
 */
export function assertRelationshipFitsAge(relationshipType: RelationshipType, age: number): void {
  if (age >= ADULT_AGE_YEARS && !(ADULT_RELATIONSHIPS as readonly string[]).includes(relationshipType)) {
    throw new BadRequestException('Para maiores de 18 anos, escolha curatela ou tomada de decisão apoiada.');
  }
  if (age < ADULT_AGE_YEARS && !(MINOR_RELATIONSHIPS as readonly string[]).includes(relationshipType)) {
    throw new BadRequestException('Para menores de 18 anos, escolha poder familiar ou tutela.');
  }
}

@Injectable()
export class ProfilesService {
  /**
   * Claim attempts per account (memory of this instance, same limits as invite accept;
   * gap 10: Redis is not wired). Every attempt counts, so the sixth try in the window is
   * refused before it reaches the database, whatever the code.
   */
  private readonly claimLimiter = new RateLimiter();

  constructor(
    @Inject(DatabaseService)
    private readonly databaseService: DatabaseService,
    @Inject(EmailService)
    private readonly emailService: EmailService,
  ) {}

  async getProfilesForUser(userId: string): Promise<ProfileResponseDto[]> {
    this.assertUserId(userId);

    const { list, notices } = await this.databaseService.withRls(userId, async (tx) => {
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
      const unnotifiedDue: string[] = [];
      if (dependents.length > 0) {
        const rows = await tx
          .select({
            id: legalGuardianships.id,
            dependentProfileId: legalGuardianships.dependentProfileId,
            relationshipType: legalGuardianships.relationshipType,
            lgpdLegalBasis: legalGuardianships.lgpdLegalBasis,
            handoverCodeExpiresAt: legalGuardianships.handoverCodeExpiresAt,
            handoverNotifiedAt: legalGuardianships.handoverNotifiedAt,
          })
          .from(legalGuardianships)
          .where(and(eq(legalGuardianships.guardianUserId, userId), isNull(legalGuardianships.closedAt)));
        const dependentById = new Map(dependents.map((p) => [p.id, p]));
        for (const row of rows) {
          guardianships.set(row.dependentProfileId, row);
          const dependent = dependentById.get(row.dependentProfileId);
          if (
            dependent &&
            !row.handoverNotifiedAt &&
            isHandoverDue(dependent.dateOfBirth ?? null, row.relationshipType)
          ) {
            unnotifiedDue.push(row.id);
          }
        }
      }

      // D3 notice, no scheduler: the first list that sees a due hand-over marks it.
      // UPDATE … WHERE handover_notified_at IS NULL RETURNING: of concurrent lists only one
      // gets the row back, so the guardian gets one email.
      const notices: Array<{ email: string; name: string; dependentFirstName: string }> = [];
      if (unnotifiedDue.length > 0) {
        const marked = await tx
          .update(legalGuardianships)
          .set({ handoverNotifiedAt: new Date() })
          .where(and(inArray(legalGuardianships.id, unnotifiedDue), isNull(legalGuardianships.handoverNotifiedAt)))
          .returning({ dependentProfileId: legalGuardianships.dependentProfileId });
        if (marked.length > 0) {
          const [guardian] = await tx
            .select({ email: users.email, name: users.name })
            .from(users)
            .where(eq(users.id, userId))
            .limit(1);
          if (guardian?.email) {
            for (const row of marked) {
              const dependent = dependents.find((p) => p.id === row.dependentProfileId);
              if (!dependent) continue;
              notices.push({
                email: guardian.email,
                name: guardian.name,
                dependentFirstName: dependent.name.trim().split(/\s+/)[0],
              });
            }
          }
        }
      }

      const list = [
        this.toResponse(primary, userId, OWNER_ACCESS),
        ...dependents.map((p) => this.toResponse(p, userId, OWNER_ACCESS, guardianships.get(p.id))),
        ...[...shared.values()].map((s) => this.toResponse(s.profile, userId, mergeGrants(s.grants)!)),
      ];
      return { list, notices };
    });

    // After commit only: a rolled-back mark sends nothing. deliver() never throws; the
    // list does not wait for the mail provider.
    for (const notice of notices) {
      void this.emailService
        .sendHandoverDueEmail(notice.email, notice.name, notice.dependentFirstName)
        .catch(() => undefined);
    }
    return list;
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
    assertRelationshipFitsAge(dto.relationshipType, age);
    const profileType = profileTypeForAge(age);
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

      const isOwner = profile.accountOwnerId === userId;
      const isDependent = profile.profileType !== 'primary';

      let access = OWNER_ACCESS;
      if (!isOwner) {
        const grantAccess = await this.getGrantAccess(tx, userId, profileId);
        if (grantAccess?.accessLevel !== 'CO_MANAGE') {
          throw new ForbiddenException('Sem permissão para editar este perfil.');
        }
        access = grantAccess;
      }

      const guardianship = isOwner && isDependent ? await this.findOpenGuardianship(tx, userId, profileId) : undefined;

      const changes: Partial<typeof profiles.$inferInsert> = {};
      if (dto.name !== undefined) changes.name = dto.name.trim();
      if (dto.dateOfBirth !== undefined) {
        const age = ageInYears(dto.dateOfBirth);
        if (Number.isNaN(age) || age < 0) {
          throw new BadRequestException('Data de nascimento inválida.');
        }
        if (isDependent) {
          // A8: a co-manager could otherwise push a minor to 18 and trigger the hand-over.
          if (!isOwner) {
            throw new ForbiddenException('Apenas quem cadastrou o perfil pode alterar a data de nascimento.');
          }
          if (guardianship) assertRelationshipFitsAge(guardianship.relationshipType, age);
          changes.profileType = profileTypeForAge(age);
        }
        changes.dateOfBirth = dto.dateOfBirth.slice(0, 10);
      }
      if (dto.gender !== undefined) changes.gender = dto.gender;

      if (Object.keys(changes).length === 0) {
        return this.toResponse(profile, userId, access, guardianship);
      }

      const [updated] = await tx
        .update(profiles)
        .set({ ...changes, updatedAt: new Date() })
        .where(eq(profiles.id, profileId))
        .returning();

      if (!updated) {
        throw new NotFoundException(`Profile with id ${profileId} not found.`);
      }

      return this.toResponse(updated, userId, access, guardianship);
    });
  }

  /**
   * The guardian re-confirms an adult dependent's consent under LGPD Art. 11, I (A3):
   * Phase 11 recorded every guardianship under Art. 14.
   */
  async confirmLegalBasis(userId: string, profileId: string, lgpdConsent: boolean): Promise<ProfileResponseDto> {
    this.assertUserId(userId);
    if (lgpdConsent !== true) {
      throw new BadRequestException('Consentimento LGPD é obrigatório.');
    }

    return this.databaseService.withRls(userId, async (tx) => {
      const profile = await this.findProfile(tx, profileId);
      const guardianship =
        profile.accountOwnerId === userId ? await this.findOpenGuardianship(tx, userId, profileId) : undefined;
      if (!guardianship) {
        throw new ForbiddenException('Apenas quem cadastrou o perfil pode confirmar a base legal.');
      }

      const age = profile.dateOfBirth ? ageInYears(profile.dateOfBirth) : Number.NaN;
      if (
        !(age >= ADULT_AGE_YEARS) ||
        !(ADULT_RELATIONSHIPS as readonly string[]).includes(guardianship.relationshipType)
      ) {
        throw new ConflictException(
          'A confirmação pelo Art. 11, I vale só para maiores de 18 anos com curatela ou tomada de decisão apoiada.',
        );
      }

      const [updated] = await tx
        .update(legalGuardianships)
        .set({ lgpdLegalBasis: 'lgpd_art_11_i', lgpdConsentRecordedAt: new Date() })
        .where(eq(legalGuardianships.id, guardianship.id))
        .returning({
          relationshipType: legalGuardianships.relationshipType,
          lgpdLegalBasis: legalGuardianships.lgpdLegalBasis,
          handoverCodeExpiresAt: legalGuardianships.handoverCodeExpiresAt,
        });
      if (!updated) {
        throw new NotFoundException(`Profile with id ${profileId} not found.`);
      }

      return this.toResponse(profile, userId, OWNER_ACCESS, updated);
    });
  }

  /**
   * D3: the guardian of a minor who turned 18 generates a hand-over code (A6: invite
   * alphabet and length, 72 h). Generating again replaces the code and its expiry.
   */
  async createHandoverCode(userId: string, profileId: string): Promise<{ claimCode: string; expiresAt: Date }> {
    this.assertUserId(userId);

    return this.databaseService.withRls(userId, async (tx) => {
      const [profile] = await tx.select().from(profiles).where(eq(profiles.id, profileId)).limit(1);
      if (!profile) {
        throw new ForbiddenException('Apenas quem cadastrou o perfil pode gerar o código de transferência.');
      }

      const guardianship =
        profile.accountOwnerId === userId && profile.profileType !== 'primary'
          ? await this.findOpenGuardianship(tx, userId, profileId)
          : undefined;
      if (!guardianship || !isHandoverDue(profile.dateOfBirth ?? null, guardianship.relationshipType)) {
        throw new ConflictException({
          statusCode: HttpStatus.CONFLICT,
          code: 'HANDOVER_NOT_DUE',
          message: 'O código de transferência fica disponível quando a pessoa completa 18 anos.',
        });
      }

      const expiresAt = new Date(Date.now() + INVITE_TTL_HOURS * HOUR_MS);
      for (let attempt = 1; attempt <= MAX_INVITE_COLLISION_RETRIES; attempt++) {
        const claimCode = generateInviteCode();
        try {
          // Nested transaction = SAVEPOINT, so a unique violation does not abort the outer transaction.
          const [updated] = await tx.transaction((sp) =>
            sp
              .update(legalGuardianships)
              .set({ handoverCode: claimCode, handoverCodeExpiresAt: expiresAt })
              .where(eq(legalGuardianships.id, guardianship.id))
              .returning({ id: legalGuardianships.id }),
          );
          if (!updated) {
            throw new NotFoundException(`Profile with id ${profileId} not found.`);
          }
          return { claimCode, expiresAt };
        } catch (err: any) {
          const uniqueViolation = err?.code === '23505' || err?.cause?.code === '23505';
          if (uniqueViolation && attempt < MAX_INVITE_COLLISION_RETRIES) continue;
          if (uniqueViolation) break;
          throw err;
        }
      }
      throw new InternalServerErrorException('Não foi possível gerar o código de transferência. Tente de novo.');
    });
  }

  /**
   * D3: the young adult, signed in to their own account, claims the profile through the
   * SECURITY DEFINER function claim_dependent_profile (migration 0028). The profile becomes
   * the caller's primary; the former guardian loses access. The code never reaches logs or
   * exception messages.
   */
  async claimProfile(userId: string, claimCode: string): Promise<ProfileResponseDto> {
    this.assertUserId(userId);
    const code = typeof claimCode === 'string' ? claimCode.trim().toUpperCase() : '';
    if (!code) {
      throw new BadRequestException('Informe o código de transferência.');
    }

    this.claimLimiter.hit(`claim:${userId}`, MAX_FAILED_INVITE_ACCEPTS, FAILED_INVITE_ACCEPT_WINDOW_MS);

    return this.databaseService.withRls(userId, async (tx) => {
      let claimedId: string | null = null;
      try {
        const result = await tx.execute(sql`SELECT claim_dependent_profile(${code}) AS profile_id`);
        const rows = ((result as any).rows ?? result) as Array<{ profile_id: string | null }>;
        claimedId = Array.isArray(rows) ? (rows[0]?.profile_id ?? null) : null;
      } catch (err: any) {
        throw this.mapClaimError(err);
      }

      if (!claimedId) {
        throw new NotFoundException({
          statusCode: HttpStatus.NOT_FOUND,
          code: 'CLAIM_INVALID_CODE',
          message: 'Código de transferência inválido ou expirado.',
        });
      }

      const profile = await this.findProfile(tx, claimedId);
      return this.toResponse(profile, userId, OWNER_ACCESS);
    });
  }

  /** Maps claim_dependent_profile refusals (SQLSTATE P0001) to HTTP errors with a `code`. */
  private mapClaimError(err: any): unknown {
    const message = `${err?.message ?? ''} ${err?.cause?.message ?? ''}`;
    for (const [code, refusal] of Object.entries(CLAIM_REFUSALS)) {
      if (message.includes(code)) {
        const body = { statusCode: refusal.status, code, message: refusal.message };
        return refusal.status === HttpStatus.FORBIDDEN ? new ForbiddenException(body) : new ConflictException(body);
      }
    }
    return err;
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

  /** The caller's open guardianship on a dependent, if any (RLS: guardian rows only). */
  private async findOpenGuardianship(
    tx: DrizzleTransaction,
    userId: string,
    profileId: string,
  ): Promise<(GuardianshipInfo & { id: string }) | undefined> {
    const [row] = await tx
      .select({
        id: legalGuardianships.id,
        relationshipType: legalGuardianships.relationshipType,
        lgpdLegalBasis: legalGuardianships.lgpdLegalBasis,
        handoverCodeExpiresAt: legalGuardianships.handoverCodeExpiresAt,
      })
      .from(legalGuardianships)
      .where(
        and(
          eq(legalGuardianships.dependentProfileId, profileId),
          eq(legalGuardianships.guardianUserId, userId),
          isNull(legalGuardianships.closedAt),
        ),
      )
      .limit(1);
    return row;
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

    // D3: a dependent's type always follows the date of birth, so a stored value never goes stale.
    const age = profile.dateOfBirth ? ageInYears(profile.dateOfBirth) : Number.NaN;
    const profileType =
      profile.profileType === 'primary' || Number.isNaN(age) ? profile.profileType : profileTypeForAge(age);

    return {
      id: profile.id,
      name: profile.name,
      profileType,
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
      ...this.handoverFor(profile, guardianship),
    };
  }

  /** D3 hand-over state of an owned dependent; 'none' without an open guardianship. */
  private handoverFor(
    profile: ProfileRow,
    guardianship?: GuardianshipInfo,
  ): { handoverStatus: HandoverStatus; handoverCodeExpiresAt: string | null } {
    if (!guardianship || !isHandoverDue(profile.dateOfBirth ?? null, guardianship.relationshipType)) {
      return { handoverStatus: 'none', handoverCodeExpiresAt: null };
    }
    const expiresAt = guardianship.handoverCodeExpiresAt ? new Date(guardianship.handoverCodeExpiresAt) : null;
    if (expiresAt && expiresAt.getTime() > Date.now()) {
      return { handoverStatus: 'code_active', handoverCodeExpiresAt: expiresAt.toISOString() };
    }
    return { handoverStatus: 'due', handoverCodeExpiresAt: null };
  }

  private assertUserId(userId: string): void {
    if (!userId) {
      throw new BadRequestException('User ID is required');
    }
  }
}
