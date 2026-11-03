import { ForbiddenException } from '@nestjs/common';
import { TestingModule } from '@nestjs/testing';
import { vi } from 'vitest';
import { DatabaseService } from '../../../src/database/database.service';
import { SHARE_CATEGORIES, ShareCategory } from '../../../src/database/schema/shared-access-grants.schema';
import {
  ProfileContext,
  ProfileContextGuard,
} from '../../../src/modules/profiles/profile-context';

export type StubAccessLevel = ProfileContext['accessLevel'];

/**
 * Per user: the primary profile id, the other profiles the user can reach and, optionally,
 * the categories each shared profile opens (default: all five). Like a single grant in the
 * database, a CO_MANAGE profile can write its categories and a VIEW_ONLY profile none.
 */
export type ProfileAccessStubConfig = Record<
  string,
  {
    primary: string;
    profiles?: Record<string, StubAccessLevel>;
    categories?: Record<string, ShareCategory[]>;
  }
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
    async (_tx: any, userId: string): Promise<ProfileContext> => ownerStub(primaryOf(userId)),
  );
  vi.spyOn(guardPrototype, 'resolveRequested').mockImplementation(
    async (tx: any, profileId: string): Promise<ProfileContext> => {
      const userId: string = tx.stubUserId;
      if (profileId === primaryOf(userId)) {
        return ownerStub(profileId);
      }
      const accessLevel = config[userId]?.profiles?.[profileId];
      if (!accessLevel) {
        throw new ForbiddenException('Sem acesso a este perfil.');
      }
      if (accessLevel === 'OWNER') return ownerStub(profileId);
      const readable = SHARE_CATEGORIES.filter(
        (category) => (config[userId]?.categories?.[profileId] ?? SHARE_CATEGORIES).includes(category),
      );
      return {
        profileId,
        accessLevel,
        readableCategories: readable,
        writableCategories: accessLevel === 'CO_MANAGE' ? [...readable] : [],
      };
    },
  );
}

function ownerStub(profileId: string): ProfileContext {
  return {
    profileId,
    accessLevel: 'OWNER',
    readableCategories: [...SHARE_CATEGORIES],
    writableCategories: [...SHARE_CATEGORIES],
  };
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
