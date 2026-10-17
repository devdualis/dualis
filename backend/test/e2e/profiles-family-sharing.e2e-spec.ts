import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import {
  BadRequestException,
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
import { ProfilesService } from '../../src/modules/profiles/profiles.service';
import { FamilySharingService } from '../../src/modules/profiles/family-sharing.service';
import { CreateDependentDto } from '../../src/modules/profiles/dto/create-dependent.dto';
import { UpdateProfileDto } from '../../src/modules/profiles/dto/update-profile.dto';
import {
  ProfileAccessLevel,
  ProfileResponseDto,
} from '../../src/modules/profiles/dto/profile-response.dto';
import { ProfileType } from '../../src/database/schema/profiles.schema';
import {
  AccessLevel,
  GrantStatus,
} from '../../src/database/schema/shared-access-grants.schema';

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
  avatarUrl: string | null;
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
};

const e2eStore = {
  profiles: new Map<string, StoredProfile>(),
  grants: new Map<string, StoredGrant>(),
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
    avatarUrl: null,
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
    avatarUrl: profile.avatarUrl,
    ownership,
    accessLevel,
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
      throw new BadRequestException('Consentimento LGPD Art. 14 é obrigatório.');
    }
    e2eStore.dependentCreates += 1;
    ensurePrimary(userId, 'Guardian A');

    const profile: StoredProfile = {
      id: crypto.randomUUID(),
      accountOwnerId: userId,
      profileType: 'dependent_minor',
      name: dto.name.trim(),
      dateOfBirth: dto.dateOfBirth.slice(0, 10),
      gender: dto.gender,
      avatarUrl: null,
    };
    e2eStore.profiles.set(profile.id, profile);
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
    if (dto.avatarUrl !== undefined) profile.avatarUrl = dto.avatarUrl;

    return toProfileResponse(profile, userId, accessLevel);
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
  ) {
    const profile = e2eStore.profiles.get(targetProfileId);
    if (!profile || profile.accountOwnerId !== userId) {
      throw new ForbiddenException('Perfil não encontrado ou sem permissão para compartilhar.');
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
    };
    e2eStore.grants.set(grant.id, grant);

    return {
      id: grant.id,
      targetProfileId: grant.targetProfileId,
      accessLevel: grant.accessLevel,
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

  const protectedRoutes: Array<{ method: 'GET' | 'POST' | 'PUT' | 'DELETE'; url: string }> = [
    { method: 'GET', url: '/v1/profiles' },
    { method: 'POST', url: '/v1/profiles/dependents' },
    { method: 'PUT', url: '/v1/profiles/c0000000-0000-0000-0000-000000000001' },
    { method: 'DELETE', url: '/v1/profiles/c0000000-0000-0000-0000-000000000001' },
    { method: 'POST', url: '/v1/family-sharing/invite' },
    { method: 'POST', url: '/v1/family-sharing/accept' },
    {
      method: 'POST',
      url: '/v1/family-sharing/revoke/d0000000-0000-0000-0000-000000000001',
    },
    { method: 'GET', url: '/v1/family-sharing/grants' },
  ];

  beforeAll(async () => {
    e2eStore.profiles.clear();
    e2eStore.grants.clear();
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
              ? { targetProfileId: 'c0000000-0000-0000-0000-000000000001', accessLevel: 'VIEW_ONLY' }
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
        payload: { targetProfileId: primaryProfileIdA, accessLevel: 'VIEW_ONLY' },
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
        payload: { targetProfileId: primaryProfileIdA, accessLevel: 'VIEW_ONLY' },
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
  });
});
