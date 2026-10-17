import { ForbiddenException } from '@nestjs/common';
import { TestingModule } from '@nestjs/testing';
import { vi } from 'vitest';
import { DatabaseService } from '../../../src/database/database.service';
import {
  ProfileContext,
  ProfileContextGuard,
} from '../../../src/modules/profiles/profile-context';

export type StubAccessLevel = ProfileContext['accessLevel'];

/** Per user: the primary profile id and the other profiles the user can reach. */
export type ProfileAccessStubConfig = Record<
  string,
  { primary: string; profiles?: Record<string, StubAccessLevel> }
>;

/** Deterministic primary profile id for users not listed in the stub config. */
export function defaultPrimaryProfileId(userId: string): string {
  return `f${userId.slice(1)}`;
}

/**
 * Keeps ProfileContextGuard's real header parsing and access-mode checks, but
 * answers its database lookups from an in-memory map. E2E specs must never reach
 * the database configured in .env.
 */
export function stubProfileAccess(moduleRef: TestingModule, config: ProfileAccessStubConfig = {}) {
  const databaseService = moduleRef.get(DatabaseService, { strict: false });
  vi.spyOn(databaseService, 'withRls').mockImplementation(
    async (userId: string, callback: (tx: any) => Promise<any>) => callback({ stubUserId: userId }),
  );

  const primaryOf = (userId: string) => config[userId]?.primary ?? defaultPrimaryProfileId(userId);

  const guardPrototype = ProfileContextGuard.prototype as any;
  vi.spyOn(guardPrototype, 'resolvePrimary').mockImplementation(
    async (_tx: any, userId: string): Promise<ProfileContext> => ({
      profileId: primaryOf(userId),
      accessLevel: 'OWNER',
    }),
  );
  vi.spyOn(guardPrototype, 'resolveRequested').mockImplementation(
    async (tx: any, profileId: string): Promise<ProfileContext> => {
      const userId: string = tx.stubUserId;
      if (profileId === primaryOf(userId)) {
        return { profileId, accessLevel: 'OWNER' };
      }
      const accessLevel = config[userId]?.profiles?.[profileId];
      if (!accessLevel) {
        throw new ForbiddenException('Sem acesso a este perfil.');
      }
      return { profileId, accessLevel };
    },
  );
}

/** Profiles reachable by the e2e caller, one per access path. */
export const TEST_PROFILES = {
  dependent: 'd0000000-0000-4000-8000-000000000001',
  sharedCoManage: 'c0000000-0000-4000-8000-000000000001',
  sharedViewOnly: 'e0000000-0000-4000-8000-000000000001',
  foreign: 'a1111111-0000-4000-8000-000000000001',
} as const;

/** Standard stub config: the caller owns a dependent and holds one grant of each level. */
export function familyAccessFor(userId: string): ProfileAccessStubConfig {
  return {
    [userId]: {
      primary: defaultPrimaryProfileId(userId),
      profiles: {
        [TEST_PROFILES.dependent]: 'OWNER',
        [TEST_PROFILES.sharedCoManage]: 'CO_MANAGE',
        [TEST_PROFILES.sharedViewOnly]: 'VIEW_ONLY',
      },
    },
  };
}
