import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  VersioningType,
  ValidationPipe,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as crypto from 'node:crypto';
import { AppModule } from '../../src/app.module';
import { AuthService } from '../../src/modules/auth/auth.service';
import {
  ProfilesService,
  ageInYears,
  assertRelationshipFitsAge,
} from '../../src/modules/profiles/profiles.service';
import { FamilySharingService } from '../../src/modules/profiles/family-sharing.service';
import { CreateDependentDto } from '../../src/modules/profiles/dto/create-dependent.dto';
import { UpdateProfileDto } from '../../src/modules/profiles/dto/update-profile.dto';
import {
  ProfileAccessLevel,
  ProfileResponseDto,
} from '../../src/modules/profiles/dto/profile-response.dto';
import { ProfileType } from '../../src/database/schema/profiles.schema';
import {
  ADULT_RELATIONSHIPS,
  LgpdLegalBasis,
  RelationshipType,
} from '../../src/database/schema/legal-guardianships.schema';
import {
  AccessLevel,
  GrantRelationship,
  GrantStatus,
  SHARE_CATEGORIES,
  ShareCategory,
} from '../../src/database/schema/shared-access-grants.schema';
import { InviteScope, generateInviteCode as generateHandoverCode } from '../../src/modules/profiles/family-sharing.service';
import { UpdateGrantDto } from '../../src/modules/profiles/dto/update-grant.dto';

const USER_A = 'a0000000-0000-0000-0000-000000000001';
const USER_B = 'b0000000-0000-0000-0000-000000000002';
const INVITE_TTL_MS = 72 * 60 * 60 * 1000;
const INVITE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

type StoredProfile = {
  id: string;
  accountOwnerId: string;
  profileType: ProfileType;
  name: string;
  dateOfBirth: string | null;
  gender: string | null;
};

type StoredGrant = {
  id: string;
  granterUserId: string;
  targetProfileId: string;
  granteeUserId: string | null;
  accessLevel: AccessLevel;
  inviteCode: string;
  status: GrantStatus;
  expiresAt: Date;
  acceptedAt: Date | null;
  revokedAt: Date | null;
  relationship: GrantRelationship | null;
  categories: ShareCategory[];
  dependentShareConfirmedAt: Date | null;
};

type StoredGuardianship = {
  guardianUserId: string;
  relationshipType: RelationshipType;
  lgpdLegalBasis: LgpdLegalBasis;
};

const e2eStore = {
  profiles: new Map<string, StoredProfile>(),
  /** Open guardianship per dependent profile id. */
  guardianships: new Map<string, StoredGuardianship>(),
  grants: new Map<string, StoredGrant>(),
  /** Hand-over code per dependent profile id. */
  handoverCodes: new Map<string, { code: string; expiresAt: Date }>(),
  dependentCreates: 0,
};

function generateInviteCode(): string {
  const bytes = crypto.randomBytes(6);
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += INVITE_ALPHABET[bytes[i] % INVITE_ALPHABET.length];
  }
  return code;
}

function ensurePrimary(userId: string, name: string): StoredProfile {
  const existing = [...e2eStore.profiles.values()].find(
    (p) => p.accountOwnerId === userId && p.profileType === 'primary',
  );
  if (existing) return existing;

  const profile: StoredProfile = {
    id: crypto.randomUUID(),
    accountOwnerId: userId,
    profileType: 'primary',
    name,
    dateOfBirth: '1990-01-01',
    gender: 'masculino',
  };
  e2eStore.profiles.set(profile.id, profile);
  return profile;
}

function toProfileResponse(
  profile: StoredProfile,
  viewerId: string,
  accessLevel: ProfileAccessLevel,
): ProfileResponseDto {
  const ownership =
    profile.accountOwnerId !== viewerId
      ? 'shared'
      : profile.profileType === 'primary'
        ? 'own'
        : 'dependent';

  return {
    id: profile.id,
    name: profile.name,
    profileType: profile.profileType,
    dateOfBirth: profile.dateOfBirth,
    gender: profile.gender,
    ownership,
    accessLevel,
    ...categoriesFor(profile.id, viewerId, accessLevel),
    ...guardianshipFor(profile.id, viewerId),
    ...handoverFor(profile, viewerId),
  };
}

/** Same rule as ProfilesService (D3): the guardian of a parent/legal_guardian dependent aged 18+. */
function handoverFor(profile: StoredProfile, viewerId: string) {
  const g = e2eStore.guardianships.get(profile.id);
  const due =
    g !== undefined &&
    g.guardianUserId === viewerId &&
    (g.relationshipType === 'parent' || g.relationshipType === 'legal_guardian') &&
    profile.dateOfBirth !== null &&
    ageInYears(profile.dateOfBirth) >= 18;
  if (!due) return { handoverStatus: 'none' as const, handoverCodeExpiresAt: null };
  const code = e2eStore.handoverCodes.get(profile.id);
  return code
    ? { handoverStatus: 'code_active' as const, handoverCodeExpiresAt: code.expiresAt.toISOString() }
    : { handoverStatus: 'due' as const, handoverCodeExpiresAt: null };
}

/** Same rule as ProfilesService: only the guardian sees relationship and basis. */
function guardianshipFor(profileId: string, viewerId: string) {
  const g = e2eStore.guardianships.get(profileId);
  if (!g || g.guardianUserId !== viewerId) {
    return { relationshipType: null, lgpdLegalBasis: null, legalBasisNeedsConfirmation: false };
  }
  return {
    relationshipType: g.relationshipType,
    lgpdLegalBasis: g.lgpdLegalBasis,
    legalBasisNeedsConfirmation:
      (ADULT_RELATIONSHIPS as readonly string[]).includes(g.relationshipType) && g.lgpdLegalBasis === 'lgpd_art_14',
  };
}

/** Same rule as ProfilesService: owners all; grantees read the union, write the CO_MANAGE union. */
function categoriesFor(profileId: string, viewerId: string, accessLevel: ProfileAccessLevel) {
  if (accessLevel === 'OWNER') {
    return { readableCategories: [...SHARE_CATEGORIES], writableCategories: [...SHARE_CATEGORIES] };
  }
  const grants = activeAcceptedGrantsForGrantee(viewerId).filter((g) => g.targetProfileId === profileId);
  const has = (list: StoredGrant[]) => (c: ShareCategory) => list.some((g) => g.categories.includes(c));
  return {
    readableCategories: SHARE_CATEGORIES.filter(has(grants)),
    writableCategories: SHARE_CATEGORIES.filter(has(grants.filter((g) => g.accessLevel === 'CO_MANAGE'))),
  };
}

function activeAcceptedGrantsForGrantee(granteeUserId: string): StoredGrant[] {
  return [...e2eStore.grants.values()].filter(
    (g) =>
      g.granteeUserId === granteeUserId &&
      g.status === 'ACCEPTED' &&
      g.revokedAt === null,
  );
}

function grantAccessForProfile(
  userId: string,
  profileId: string,
): ProfileAccessLevel | null {
  const grants = activeAcceptedGrantsForGrantee(userId).filter(
    (g) => g.targetProfileId === profileId,
  );
  if (grants.length === 0) return null;
  return grants.some((g) => g.accessLevel === 'CO_MANAGE') ? 'CO_MANAGE' : 'VIEW_ONLY';
}

@Injectable()
class E2EProfilesService {
  async getProfilesForUser(userId: string): Promise<ProfileResponseDto[]> {
    const displayName = userId === USER_A ? 'Guardian A' : 'Family B';
    const primary = ensurePrimary(userId, displayName);

    const owned = [...e2eStore.profiles.values()]
      .filter((p) => p.accountOwnerId === userId)
      .sort((a, b) => (a.profileType === 'primary' ? -1 : 1));

    const sharedByProfile = new Map<string, { profile: StoredProfile; level: AccessLevel }>();
    for (const grant of activeAcceptedGrantsForGrantee(userId)) {
      const profile = e2eStore.profiles.get(grant.targetProfileId);
      if (!profile || profile.accountOwnerId === userId) continue;
      const existing = sharedByProfile.get(profile.id);
      if (!existing || grant.accessLevel === 'CO_MANAGE') {
        sharedByProfile.set(profile.id, { profile, level: grant.accessLevel });
      }
    }

    const ownedResponses = owned.map((p) =>
      toProfileResponse(p, userId, 'OWNER'),
    );

    const sharedResponses = [...sharedByProfile.values()].map((s) =>
      toProfileResponse(s.profile, userId, s.level),
    );

    if (!ownedResponses.some((p) => p.id === primary.id)) {
      return [toProfileResponse(primary, userId, 'OWNER'), ...ownedResponses, ...sharedResponses];
    }

    return [...ownedResponses, ...sharedResponses];
  }

  async createDependent(userId: string, dto: CreateDependentDto): Promise<ProfileResponseDto> {
    if (dto.lgpdConsent !== true) {
      throw new BadRequestException('Consentimento LGPD é obrigatório.');
    }
    // Real age × relationship rule from ProfilesService.
    const age = ageInYears(dto.dateOfBirth);
    assertRelationshipFitsAge(dto.relationshipType, age);
    e2eStore.dependentCreates += 1;
    ensurePrimary(userId, 'Guardian A');

    const profile: StoredProfile = {
      id: crypto.randomUUID(),
      accountOwnerId: userId,
      profileType: age < 18 ? 'dependent_minor' : 'dependent_adult',
      name: dto.name.trim(),
      dateOfBirth: dto.dateOfBirth.slice(0, 10),
      gender: dto.gender,
    };
    e2eStore.profiles.set(profile.id, profile);
    e2eStore.guardianships.set(profile.id, {
      guardianUserId: userId,
      relationshipType: dto.relationshipType,
      lgpdLegalBasis: age < 18 ? 'lgpd_art_14' : 'lgpd_art_11_i',
    });
    return toProfileResponse(profile, userId, 'OWNER');
  }

  async confirmLegalBasis(userId: string, profileId: string, lgpdConsent: boolean): Promise<ProfileResponseDto> {
    if (lgpdConsent !== true) throw new BadRequestException('Consentimento LGPD é obrigatório.');
    const profile = e2eStore.profiles.get(profileId);
    if (!profile) throw new NotFoundException(`Profile with id ${profileId} not found.`);
    const g = e2eStore.guardianships.get(profileId);
    if (profile.accountOwnerId !== userId || !g || g.guardianUserId !== userId) {
      throw new ForbiddenException('Apenas quem cadastrou o perfil pode confirmar a base legal.');
    }
    if (!(ADULT_RELATIONSHIPS as readonly string[]).includes(g.relationshipType)) {
      throw new ConflictException('A confirmação pelo Art. 11, I vale só para maiores de 18 anos.');
    }
    g.lgpdLegalBasis = 'lgpd_art_11_i';
    return toProfileResponse(profile, userId, 'OWNER');
  }

  async updateProfile(
    userId: string,
    profileId: string,
    dto: UpdateProfileDto,
  ): Promise<ProfileResponseDto> {
    const profile = e2eStore.profiles.get(profileId);
    if (!profile) {
      throw new NotFoundException(`Profile with id ${profileId} not found.`);
    }

    let accessLevel: ProfileAccessLevel = 'OWNER';
    if (profile.accountOwnerId !== userId) {
      const grantLevel = grantAccessForProfile(userId, profileId);
      if (grantLevel !== 'CO_MANAGE') {
        throw new ForbiddenException('Sem permissão para editar este perfil.');
      }
      accessLevel = grantLevel;
    }

    if (dto.name !== undefined) profile.name = dto.name.trim();
    if (dto.dateOfBirth !== undefined) profile.dateOfBirth = dto.dateOfBirth.slice(0, 10);
    if (dto.gender !== undefined) profile.gender = dto.gender;

    return toProfileResponse(profile, userId, accessLevel);
  }

  async createHandoverCode(userId: string, profileId: string) {
    const profile = e2eStore.profiles.get(profileId);
    const g = e2eStore.guardianships.get(profileId);
    if (!profile || profile.accountOwnerId !== userId || !g || g.guardianUserId !== userId) {
      throw new ConflictException({ statusCode: 409, code: 'HANDOVER_NOT_DUE', message: 'Ainda não.' });
    }
    if (!profile.dateOfBirth || ageInYears(profile.dateOfBirth) < 18) {
      throw new ConflictException({ statusCode: 409, code: 'HANDOVER_NOT_DUE', message: 'Ainda não.' });
    }
    const issued = { code: generateHandoverCode(), expiresAt: new Date(Date.now() + INVITE_TTL_MS) };
    e2eStore.handoverCodes.set(profileId, issued);
    return { claimCode: issued.code, expiresAt: issued.expiresAt };
  }

  async claimProfile(userId: string, claimCode: string): Promise<ProfileResponseDto> {
    const entry = [...e2eStore.handoverCodes.entries()].find(([, issued]) => issued.code === claimCode.toUpperCase());
    if (!entry) {
      throw new NotFoundException({ statusCode: 404, code: 'CLAIM_INVALID_CODE', message: 'Código inválido.' });
    }
    const profile = e2eStore.profiles.get(entry[0])!;
    if (profile.accountOwnerId === userId) {
      throw new ForbiddenException({ statusCode: 403, code: 'CLAIM_BY_GUARDIAN', message: 'Conta errada.' });
    }
    e2eStore.handoverCodes.delete(entry[0]);
    e2eStore.guardianships.delete(entry[0]);
    for (const [id, p] of e2eStore.profiles) {
      if (p.accountOwnerId === userId && p.profileType === 'primary') e2eStore.profiles.delete(id);
    }
    profile.accountOwnerId = userId;
    profile.profileType = 'primary';
    return toProfileResponse(profile, userId, 'OWNER');
  }

  async deleteProfile(userId: string, profileId: string): Promise<void> {
    const profile = e2eStore.profiles.get(profileId);
    if (!profile) {
      throw new NotFoundException(`Profile with id ${profileId} not found.`);
    }
    if (profile.accountOwnerId !== userId) {
      throw new ForbiddenException('Somente o titular da conta pode excluir este perfil.');
    }
    e2eStore.profiles.delete(profileId);
  }
}

@Injectable()
class E2EFamilySharingService {
  async createInvite(
    userId: string,
    targetProfileId: string,
    accessLevel: AccessLevel,
    scope: InviteScope,
  ) {
    const profile = e2eStore.profiles.get(targetProfileId);
    if (!profile || profile.accountOwnerId !== userId) {
      throw new ForbiddenException('Perfil não encontrado ou sem permissão para compartilhar.');
    }
    const isDependent = profile.profileType !== 'primary';
    if (isDependent && scope.dependentShareConfirmed !== true) {
      throw new BadRequestException('Confirme o compartilhamento do perfil dependente.');
    }

    const grant: StoredGrant = {
      id: crypto.randomUUID(),
      granterUserId: userId,
      targetProfileId,
      granteeUserId: null,
      accessLevel,
      inviteCode: generateInviteCode(),
      status: 'PENDING',
      expiresAt: new Date(Date.now() + INVITE_TTL_MS),
      acceptedAt: null,
      revokedAt: null,
      relationship: scope.relationship,
      categories: scope.categories,
      dependentShareConfirmedAt: isDependent ? new Date() : null,
    };
    e2eStore.grants.set(grant.id, grant);

    return {
      id: grant.id,
      targetProfileId: grant.targetProfileId,
      accessLevel: grant.accessLevel,
      relationship: grant.relationship,
      categories: grant.categories,
      inviteCode: grant.inviteCode,
      status: grant.status,
      expiresAt: grant.expiresAt.toISOString(),
    };
  }

  async acceptInvite(userId: string, inviteCode: string) {
    const grant = [...e2eStore.grants.values()].find(
      (g) => g.inviteCode === inviteCode.toUpperCase(),
    );
    if (!grant) {
      throw new NotFoundException('Convite não encontrado.');
    }
    if (grant.granterUserId === userId) {
      throw new BadRequestException('Não é possível aceitar o próprio convite.');
    }
    if (grant.status !== 'PENDING') {
      throw new BadRequestException('Convite não está pendente.');
    }
    if (grant.expiresAt.getTime() < Date.now()) {
      grant.status = 'EXPIRED';
      throw new BadRequestException('Convite expirado.');
    }

    grant.status = 'ACCEPTED';
    grant.granteeUserId = userId;
    grant.acceptedAt = new Date();

    return {
      id: grant.id,
      targetProfileId: grant.targetProfileId,
      accessLevel: grant.accessLevel,
      status: grant.status,
      acceptedAt: grant.acceptedAt.toISOString(),
    };
  }

  async revokeGrant(userId: string, grantId: string) {
    const grant = e2eStore.grants.get(grantId);
    if (!grant) {
      throw new NotFoundException('Compartilhamento não encontrado.');
    }
    if (grant.granterUserId !== userId && grant.granteeUserId !== userId) {
      throw new ForbiddenException('Sem permissão para revogar este compartilhamento.');
    }
    grant.status = 'REVOKED';
    grant.revokedAt = new Date();
    return { id: grant.id, status: grant.status, revokedAt: grant.revokedAt.toISOString() };
  }

  async updateGrant(userId: string, grantId: string, dto: UpdateGrantDto) {
    const grant = e2eStore.grants.get(grantId);
    if (!grant || (grant.granterUserId !== userId && grant.granteeUserId !== userId)) {
      throw new NotFoundException('Compartilhamento não encontrado.');
    }
    if (grant.granterUserId !== userId) {
      throw new ForbiddenException('Somente quem compartilhou pode alterar este compartilhamento.');
    }
    if (grant.status === 'REVOKED' || grant.status === 'EXPIRED') {
      throw new ConflictException({ statusCode: 409, code: 'GRANT_SCOPE_LOCKED', message: 'Encerrado.' });
    }
    if (dto.categories === undefined && dto.relationship === undefined) {
      throw new BadRequestException('Informe as categorias ou a relação que deseja alterar.');
    }
    if (dto.categories) grant.categories = dto.categories;
    if (dto.relationship) grant.relationship = dto.relationship;
    return { ...grant };
  }

  async listGrants(userId: string) {
    const outgoing = [...e2eStore.grants.values()].filter((g) => g.granterUserId === userId);
    const incoming = [...e2eStore.grants.values()].filter(
      (g) => g.granteeUserId === userId && g.status === 'ACCEPTED' && g.revokedAt === null,
    );
    return { outgoing, incoming };
  }
}

describe('Profiles & Family Sharing E2E (PREM-06, PREM-07)', () => {
  let app: NestFastifyApplication;
  let jwtService: JwtService;
  let tokenA: string;
  let tokenB: string;
  let primaryProfileIdA: string;
  let dependentProfileId: string;
  let shareGrantId: string;
  let shareInviteCode: string;

  const dependentPayload = {
    name: 'Lucas Dependente',
    dateOfBirth: '2015-06-20',
    gender: 'masculino',
    relationshipType: 'parent',
    lgpdConsent: true,
  };

  const shareScope = { relationship: 'sibling', categories: ['habits'] };

  const protectedRoutes: Array<{ method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'; url: string }> = [
    { method: 'GET', url: '/v1/profiles' },
    { method: 'POST', url: '/v1/profiles/dependents' },
    { method: 'PUT', url: '/v1/profiles/c0000000-0000-0000-0000-000000000001' },
    { method: 'DELETE', url: '/v1/profiles/c0000000-0000-0000-0000-000000000001' },
    { method: 'POST', url: '/v1/profiles/c0000000-0000-0000-0000-000000000001/legal-basis-confirmation' },
    { method: 'POST', url: '/v1/profiles/c0000000-0000-0000-0000-000000000001/handover-code' },
    { method: 'POST', url: '/v1/profiles/claim' },
    { method: 'POST', url: '/v1/family-sharing/invite' },
    { method: 'POST', url: '/v1/family-sharing/accept' },
    {
      method: 'POST',
      url: '/v1/family-sharing/revoke/d0000000-0000-0000-0000-000000000001',
    },
    { method: 'GET', url: '/v1/family-sharing/grants' },
    { method: 'PATCH', url: '/v1/family-sharing/grants/d0000000-0000-0000-0000-000000000001' },
  ];

  beforeAll(async () => {
    e2eStore.profiles.clear();
    e2eStore.guardianships.clear();
    e2eStore.grants.clear();
    e2eStore.handoverCodes.clear();
    e2eStore.dependentCreates = 0;

    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(ProfilesService)
      .useClass(E2EProfilesService)
      .overrideProvider(FamilySharingService)
      .useClass(E2EFamilySharingService)
      .compile();

    jwtService = moduleRef.get<JwtService>(JwtService);
    tokenA = jwtService.sign(
      { sub: USER_A, email: 'guardian.a@dualis.com.br', type: 'access' },
      { expiresIn: '15m' },
    );
    tokenB = jwtService.sign(
      { sub: USER_B, email: 'family.b@dualis.com.br', type: 'access' },
      { expiresIn: '15m' },
    );

    const authService = moduleRef.get<AuthService>(AuthService);
    authService.validateUserById = async (id: string) => ({
      id,
      name: id === USER_A ? 'Guardian A' : 'Family B',
      email: id === USER_A ? 'guardian.a@dualis.com.br' : 'family.b@dualis.com.br',
      gender: 'masculino',
      dateOfBirth: '1990-01-01',
      picture: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    app = moduleRef.createNestApplication<NestFastifyApplication>(new FastifyAdapter());
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    if (app) await app.close();
  });

  it('returns 401 without JWT on every profiles and family-sharing route', async () => {
    for (const route of protectedRoutes) {
      const response = await app.inject({
        method: route.method,
        url: route.url,
        payload:
          route.method === 'POST' && route.url.includes('dependents')
            ? dependentPayload
            : route.method === 'POST' && route.url.includes('invite')
              ? { targetProfileId: 'c0000000-0000-0000-0000-000000000001', accessLevel: 'VIEW_ONLY', ...shareScope }
              : route.method === 'POST' && route.url.includes('accept')
                ? { inviteCode: 'ABC123' }
                : undefined,
      });
      expect(response.statusCode).toBe(401);
    }
  });

  describe.sequential('dependent registration and family sharing lifecycle', () => {
    it('rejects dependent creation when lgpdConsent is false and does not persist dependent', async () => {
      const beforeCreates = e2eStore.dependentCreates;

      const reject = await app.inject({
        method: 'POST',
        url: '/v1/profiles/dependents',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { ...dependentPayload, lgpdConsent: false },
      });
      expect(reject.statusCode).toBe(400);
      expect(e2eStore.dependentCreates).toBe(beforeCreates);

      const list = await app.inject({
        method: 'GET',
        url: '/v1/profiles',
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect(list.statusCode).toBe(200);
      const profiles = JSON.parse(list.payload) as ProfileResponseDto[];
      expect(profiles.some((p) => p.ownership === 'dependent')).toBe(false);
    });

    it('refuses a relationship that does not fit the age with 400 and persists nothing', async () => {
      const beforeCreates = e2eStore.dependentCreates;
      const year = new Date().getUTCFullYear();

      const adultParent = await app.inject({
        method: 'POST',
        url: '/v1/profiles/dependents',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { ...dependentPayload, dateOfBirth: `${year - 40}-01-01`, relationshipType: 'parent' },
      });
      expect(adultParent.statusCode).toBe(400);
      expect(JSON.parse(adultParent.payload).message).toBe(
        'Para maiores de 18 anos, escolha curatela ou tomada de decisão apoiada.',
      );

      const minorCurator = await app.inject({
        method: 'POST',
        url: '/v1/profiles/dependents',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { ...dependentPayload, dateOfBirth: `${year - 10}-01-01`, relationshipType: 'curator' },
      });
      expect(minorCurator.statusCode).toBe(400);
      expect(JSON.parse(minorCurator.payload).message).toBe('Para menores de 18 anos, escolha poder familiar ou tutela.');

      const unknown = await app.inject({
        method: 'POST',
        url: '/v1/profiles/dependents',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { ...dependentPayload, relationshipType: 'spouse' },
      });
      expect(unknown.statusCode).toBe(400);
      expect(JSON.parse(unknown.payload).message).toContain(
        'Tipo de vínculo deve ser parent, legal_guardian, curator ou supported_decision.',
      );
      expect(e2eStore.dependentCreates).toBe(beforeCreates);
    });

    it('creates dependent with consent and lists it with ownership dependent', async () => {
      const create = await app.inject({
        method: 'POST',
        url: '/v1/profiles/dependents',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: dependentPayload,
      });
      expect(create.statusCode).toBe(201);
      const created = JSON.parse(create.payload) as ProfileResponseDto;
      expect(created.ownership).toBe('dependent');
      dependentProfileId = created.id;

      const list = await app.inject({
        method: 'GET',
        url: '/v1/profiles',
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect(list.statusCode).toBe(200);
      const profiles = JSON.parse(list.payload) as ProfileResponseDto[];
      const dependent = profiles.find((p) => p.id === dependentProfileId);
      expect(dependent).toBeDefined();
      expect(dependent?.ownership).toBe('dependent');
    });

    it('invite → accept → grantee sees shared profile with accessLevel (expires_at ignored after accept)', async () => {
      const listA = await app.inject({
        method: 'GET',
        url: '/v1/profiles',
        headers: { authorization: `Bearer ${tokenA}` },
      });
      const profilesA = JSON.parse(listA.payload) as ProfileResponseDto[];
      const primary = profilesA.find((p) => p.ownership === 'own');
      expect(primary).toBeDefined();
      primaryProfileIdA = primary!.id;

      const invite = await app.inject({
        method: 'POST',
        url: '/v1/family-sharing/invite',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { targetProfileId: primaryProfileIdA, accessLevel: 'VIEW_ONLY', ...shareScope },
      });
      expect(invite.statusCode).toBe(201);
      const inviteBody = JSON.parse(invite.payload);
      shareGrantId = inviteBody.id;
      shareInviteCode = inviteBody.inviteCode;

      const accept = await app.inject({
        method: 'POST',
        url: '/v1/family-sharing/accept',
        headers: { authorization: `Bearer ${tokenB}` },
        payload: { inviteCode: shareInviteCode },
      });
      expect(accept.statusCode).toBe(200);

      const grant = e2eStore.grants.get(shareGrantId);
      expect(grant?.status).toBe('ACCEPTED');
      grant!.expiresAt = new Date(Date.now() - 60_000);

      const listB = await app.inject({
        method: 'GET',
        url: '/v1/profiles',
        headers: { authorization: `Bearer ${tokenB}` },
      });
      expect(listB.statusCode).toBe(200);
      const profilesB = JSON.parse(listB.payload) as ProfileResponseDto[];
      const shared = profilesB.find((p) => p.id === primaryProfileIdA);
      expect(shared).toBeDefined();
      expect(shared?.ownership).toBe('shared');
      expect(shared?.accessLevel).toBe('VIEW_ONLY');
    });

    it('revoke removes shared profile from grantee list in the same session', async () => {
      const revoke = await app.inject({
        method: 'POST',
        url: `/v1/family-sharing/revoke/${shareGrantId}`,
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect(revoke.statusCode).toBe(200);

      const listB = await app.inject({
        method: 'GET',
        url: '/v1/profiles',
        headers: { authorization: `Bearer ${tokenB}` },
      });
      expect(listB.statusCode).toBe(200);
      const profilesB = JSON.parse(listB.payload) as ProfileResponseDto[];
      expect(profilesB.some((p) => p.id === primaryProfileIdA)).toBe(false);
    });

    it('VIEW_ONLY grantee receives 403 on PUT /v1/profiles/:id', async () => {
      const reinvite = await app.inject({
        method: 'POST',
        url: '/v1/family-sharing/invite',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { targetProfileId: primaryProfileIdA, accessLevel: 'VIEW_ONLY', ...shareScope },
      });
      expect(reinvite.statusCode).toBe(201);
      const code = JSON.parse(reinvite.payload).inviteCode;

      await app.inject({
        method: 'POST',
        url: '/v1/family-sharing/accept',
        headers: { authorization: `Bearer ${tokenB}` },
        payload: { inviteCode: code },
      });

      const update = await app.inject({
        method: 'PUT',
        url: `/v1/profiles/${primaryProfileIdA}`,
        headers: { authorization: `Bearer ${tokenB}` },
        payload: { name: 'Tentativa de edição' },
      });
      expect(update.statusCode).toBe(403);
    });

    it('rejects an invite without a relationship or with an invalid category set (400)', async () => {
      const base = { targetProfileId: primaryProfileIdA, accessLevel: 'VIEW_ONLY' };
      for (const payload of [
        { ...base, categories: ['habits'] },
        { ...base, relationship: 'boss', categories: ['habits'] },
        { ...base, relationship: 'sibling', categories: [] },
        { ...base, relationship: 'sibling', categories: ['habits', 'habits'] },
        { ...base, relationship: 'sibling', categories: ['safety'] },
        { ...base, relationship: 'sibling' },
      ]) {
        const response = await app.inject({
          method: 'POST',
          url: '/v1/family-sharing/invite',
          headers: { authorization: `Bearer ${tokenA}` },
          payload,
        });
        expect(response.statusCode, JSON.stringify(payload)).toBe(400);
      }
    });

    it('creates an invite that opens only the emotional journal and lists it with its scope', async () => {
      const invite = await app.inject({
        method: 'POST',
        url: '/v1/family-sharing/invite',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: {
          targetProfileId: primaryProfileIdA,
          accessLevel: 'VIEW_ONLY',
          relationship: 'spouse_partner',
          categories: ['emotional_journal'],
        },
      });
      expect(invite.statusCode).toBe(201);
      const body = JSON.parse(invite.payload);
      expect(body).toMatchObject({ relationship: 'spouse_partner', categories: ['emotional_journal'] });

      const list = await app.inject({
        method: 'GET',
        url: '/v1/family-sharing/grants',
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect(list.statusCode).toBe(200);
      const outgoing = JSON.parse(list.payload).outgoing;
      expect(outgoing.find((g: any) => g.id === body.id)).toMatchObject({
        relationship: 'spouse_partner',
        categories: ['emotional_journal'],
      });
    });

    it('needs dependentShareConfirmed true to share a dependent profile', async () => {
      const payload = {
        targetProfileId: dependentProfileId,
        accessLevel: 'VIEW_ONLY',
        relationship: 'other_family',
        categories: ['habits'],
      };
      const refused = await app.inject({
        method: 'POST',
        url: '/v1/family-sharing/invite',
        headers: { authorization: `Bearer ${tokenA}` },
        payload,
      });
      expect(refused.statusCode).toBe(400);

      const confirmed = await app.inject({
        method: 'POST',
        url: '/v1/family-sharing/invite',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { ...payload, dependentShareConfirmed: true },
      });
      expect(confirmed.statusCode).toBe(201);
      const grant = e2eStore.grants.get(JSON.parse(confirmed.payload).id);
      expect(grant?.dependentShareConfirmedAt).toBeInstanceOf(Date);
    });

    it('PATCH /grants/:id lets the granter edit the categories and validates the body', async () => {
      const invite = await app.inject({
        method: 'POST',
        url: '/v1/family-sharing/invite',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { targetProfileId: primaryProfileIdA, accessLevel: 'CO_MANAGE', ...shareScope },
      });
      const { id, inviteCode } = JSON.parse(invite.payload);
      await app.inject({
        method: 'POST',
        url: '/v1/family-sharing/accept',
        headers: { authorization: `Bearer ${tokenB}` },
        payload: { inviteCode },
      });

      const empty = await app.inject({
        method: 'PATCH',
        url: `/v1/family-sharing/grants/${id}`,
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { categories: [] },
      });
      expect(empty.statusCode).toBe(400);

      const badId = await app.inject({
        method: 'PATCH',
        url: '/v1/family-sharing/grants/not-a-uuid',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { categories: ['habits'] },
      });
      expect(badId.statusCode).toBe(400);

      const edited = await app.inject({
        method: 'PATCH',
        url: `/v1/family-sharing/grants/${id}`,
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { categories: ['habits', 'care'], relationship: 'caregiver' },
      });
      expect(edited.statusCode).toBe(200);
      expect(JSON.parse(edited.payload)).toMatchObject({
        id,
        relationship: 'caregiver',
        categories: ['habits', 'care'],
      });

      const byGrantee = await app.inject({
        method: 'PATCH',
        url: `/v1/family-sharing/grants/${id}`,
        headers: { authorization: `Bearer ${tokenB}` },
        payload: { categories: ['habits', 'emotional_journal'] },
      });
      expect(byGrantee.statusCode).toBe(403);
      expect(e2eStore.grants.get(id)?.categories).toEqual(['habits', 'care']);
    });

    it('POST /profiles/:id/legal-basis-confirmation re-confirms an adult dependent under Art. 11, I', async () => {
      // Phase 11 dependent: curatela recorded under Art. 14 before 0028.
      const legacy: StoredProfile = {
        id: crypto.randomUUID(),
        accountOwnerId: USER_A,
        profileType: 'dependent_adult',
        name: 'Carlos Curatelado',
        dateOfBirth: '1960-03-01',
        gender: 'masculino',
      };
      e2eStore.profiles.set(legacy.id, legacy);
      e2eStore.guardianships.set(legacy.id, {
        guardianUserId: USER_A,
        relationshipType: 'curator',
        lgpdLegalBasis: 'lgpd_art_14',
      });
      const url = `/v1/profiles/${legacy.id}/legal-basis-confirmation`;

      const list = await app.inject({ method: 'GET', url: '/v1/profiles', headers: { authorization: `Bearer ${tokenA}` } });
      expect((JSON.parse(list.payload) as ProfileResponseDto[]).find((p) => p.id === legacy.id)).toMatchObject({
        relationshipType: 'curator',
        lgpdLegalBasis: 'lgpd_art_14',
        legalBasisNeedsConfirmation: true,
      });

      for (const payload of [{}, { lgpdConsent: false }, { lgpdConsent: true, extra: 1 }]) {
        const bad = await app.inject({ method: 'POST', url, headers: { authorization: `Bearer ${tokenA}` }, payload });
        expect(bad.statusCode).toBe(400);
      }
      const badId = await app.inject({
        method: 'POST',
        url: '/v1/profiles/not-a-uuid/legal-basis-confirmation',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { lgpdConsent: true },
      });
      expect(badId.statusCode).toBe(400);

      const byOther = await app.inject({
        method: 'POST',
        url,
        headers: { authorization: `Bearer ${tokenB}` },
        payload: { lgpdConsent: true },
      });
      expect(byOther.statusCode).toBe(403);

      const confirmed = await app.inject({
        method: 'POST',
        url,
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { lgpdConsent: true },
      });
      expect(confirmed.statusCode).toBe(200);
      expect(JSON.parse(confirmed.payload)).toMatchObject({
        id: legacy.id,
        lgpdLegalBasis: 'lgpd_art_11_i',
        legalBasisNeedsConfirmation: false,
      });

      const onMinor = await app.inject({
        method: 'POST',
        url: `/v1/profiles/${dependentProfileId}/legal-basis-confirmation`,
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { lgpdConsent: true },
      });
      expect(onMinor.statusCode).toBe(409);
    });

    it('validates the hand-over routes: empty claim code and non-UUID profile id answer 400', async () => {
      for (const payload of [{}, { claimCode: '' }, { claimCode: '   ' }, { claimCode: 'ABC' }, { claimCode: 'ABCDEFGH23', extra: 1 }]) {
        const response = await app.inject({
          method: 'POST',
          url: '/v1/profiles/claim',
          headers: { authorization: `Bearer ${tokenB}` },
          payload,
        });
        expect(response.statusCode).toBe(400);
      }

      const badId = await app.inject({
        method: 'POST',
        url: '/v1/profiles/not-a-uuid/handover-code',
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect(badId.statusCode).toBe(400);
    });

    it('hands an aged-out dependent over: code for the guardian, claim by the young adult, no access left for the guardian', async () => {
      const year = new Date().getUTCFullYear();
      const created = await app.inject({
        method: 'POST',
        url: '/v1/profiles/dependents',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { ...dependentPayload, name: 'Rafa Souza', dateOfBirth: `${year - 10}-01-01` },
      });
      expect(created.statusCode).toBe(201);
      const dependent = JSON.parse(created.payload) as ProfileResponseDto;

      const notDue = await app.inject({
        method: 'POST',
        url: `/v1/profiles/${dependent.id}/handover-code`,
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect(notDue.statusCode).toBe(409);
      expect(JSON.parse(notDue.payload).code).toBe('HANDOVER_NOT_DUE');

      // Time passes: the dependent turns 18.
      e2eStore.profiles.get(dependent.id)!.dateOfBirth = `${year - 19}-01-01`;
      const dueList = await app.inject({
        method: 'GET',
        url: '/v1/profiles',
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect((JSON.parse(dueList.payload) as ProfileResponseDto[]).find((p) => p.id === dependent.id)).toMatchObject({
        handoverStatus: 'due',
        handoverCodeExpiresAt: null,
      });

      const issued = await app.inject({
        method: 'POST',
        url: `/v1/profiles/${dependent.id}/handover-code`,
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect(issued.statusCode).toBe(201);
      const { claimCode, expiresAt } = JSON.parse(issued.payload);
      expect(typeof claimCode).toBe('string');
      expect(new Date(expiresAt).getTime()).toBeGreaterThan(Date.now());

      const byGuardian = await app.inject({
        method: 'POST',
        url: '/v1/profiles/claim',
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { claimCode },
      });
      expect(byGuardian.statusCode).toBe(403);
      expect(JSON.parse(byGuardian.payload).code).toBe('CLAIM_BY_GUARDIAN');

      const wrong = await app.inject({
        method: 'POST',
        url: '/v1/profiles/claim',
        headers: { authorization: `Bearer ${tokenB}` },
        payload: { claimCode: 'ZZZZZZZZZZ' },
      });
      expect(wrong.statusCode).toBe(404);
      expect(JSON.parse(wrong.payload).code).toBe('CLAIM_INVALID_CODE');

      const claimed = await app.inject({
        method: 'POST',
        url: '/v1/profiles/claim',
        headers: { authorization: `Bearer ${tokenB}` },
        payload: { claimCode },
      });
      expect(claimed.statusCode).toBe(200);
      expect(JSON.parse(claimed.payload)).toMatchObject({ id: dependent.id, ownership: 'own', profileType: 'primary' });

      const guardianList = await app.inject({
        method: 'GET',
        url: '/v1/profiles',
        headers: { authorization: `Bearer ${tokenA}` },
      });
      expect((JSON.parse(guardianList.payload) as ProfileResponseDto[]).some((p) => p.id === dependent.id)).toBe(false);
    });

    it('PATCH on a revoked grant answers 409 GRANT_SCOPE_LOCKED', async () => {
      const locked = await app.inject({
        method: 'PATCH',
        url: `/v1/family-sharing/grants/${shareGrantId}`,
        headers: { authorization: `Bearer ${tokenA}` },
        payload: { categories: ['habits'] },
      });
      expect(locked.statusCode).toBe(409);
      expect(JSON.parse(locked.payload).code).toBe('GRANT_SCOPE_LOCKED');
    });
  });
});
