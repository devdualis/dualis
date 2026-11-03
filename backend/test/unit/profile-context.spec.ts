import { describe, it, expect, vi } from 'vitest';
import {
  BadRequestException,
  ExecutionContext,
  ForbiddenException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import {
  assertCategory,
  journalAreaCategory,
  ProfileAccess,
  ProfileAccessMode,
  ProfileAccessOptions,
  ProfileContext,
  ProfileContextGuard,
  PROFILE_HEADER,
} from '../../src/modules/profiles/profile-context';
import { profiles } from '../../src/database/schema/profiles.schema';
import { SHARE_CATEGORIES } from '../../src/database/schema/shared-access-grants.schema';

const USER_ID = '11111111-1111-4111-8111-111111111111';
const PRIMARY_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const DEPENDENT_ID = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';

type AccessRow = {
  is_owner: boolean;
  can_read: boolean;
  can_co_manage: boolean;
  readable?: string[];
  writable?: string[];
};

const ALL = [...SHARE_CATEGORIES];
const NOT_SHARED = 'Esta categoria não foi compartilhada com você.';
const owner = (profileId: string): ProfileContext => ({
  profileId,
  accessLevel: 'OWNER',
  readableCategories: ALL,
  writableCategories: ALL,
});

/** Chainable Drizzle-like tx: awaiting a select/insert chain resolves the next queued result. */
function createTx(opts: { select?: unknown[][]; insert?: unknown[][]; access?: AccessRow } = {}) {
  const queues = { select: [...(opts.select ?? [])], insert: [...(opts.insert ?? [])] };
  const calls = { insertTables: [] as unknown[], insertValues: [] as unknown[], onConflict: 0 };

  const chain = (kind: keyof typeof queues) => {
    const c: any = {};
    for (const m of ['from', 'where', 'limit', 'orderBy', 'returning']) {
      c[m] = vi.fn(() => c);
    }
    c.values = vi.fn((v: unknown) => {
      calls.insertValues.push(v);
      return c;
    });
    c.onConflictDoNothing = vi.fn(() => {
      calls.onConflict += 1;
      return c;
    });
    c.then = (resolve: (v: unknown) => unknown, reject: (e: unknown) => unknown) =>
      Promise.resolve(queues[kind].shift() ?? []).then(resolve, reject);
    return c;
  };

  const tx = {
    select: vi.fn(() => chain('select')),
    insert: vi.fn((table: unknown) => {
      calls.insertTables.push(table);
      return chain('insert');
    }),
    execute: vi.fn(async () => ({ rows: opts.access ? [opts.access] : [] })),
  };
  return { tx, calls };
}

function setup(
  txOpts: Parameters<typeof createTx>[0],
  access?: { mode: ProfileAccessMode; options?: ProfileAccessOptions },
) {
  const { tx, calls } = createTx(txOpts);
  const databaseService = {
    withRls: vi.fn(async (userId: string, cb: (t: unknown) => unknown) => cb(tx)),
  };

  // Apply the real decorator to a handler so metadata matches production usage.
  class TestController {
    handler() {}
  }
  if (access) {
    ProfileAccess(access.mode, access.options)(
      TestController.prototype,
      'handler',
      Object.getOwnPropertyDescriptor(TestController.prototype, 'handler')!,
    );
  }

  const guard = new ProfileContextGuard(new Reflector(), databaseService as any);
  return { guard, tx, calls, databaseService, handler: TestController.prototype.handler, cls: TestController };
}

function contextFor(
  handler: () => void,
  cls: new () => unknown,
  request: { headers?: Record<string, unknown>; user?: Record<string, unknown> },
): { ctx: ExecutionContext; request: any } {
  const req: any = { headers: {}, ...request };
  const ctx = {
    getHandler: () => handler,
    getClass: () => cls,
    switchToHttp: () => ({ getRequest: () => req }),
  } as unknown as ExecutionContext;
  return { ctx, request: req };
}

const authed = (headers: Record<string, unknown> = {}) => ({ headers, user: { id: USER_ID } });

describe('ProfileContextGuard', () => {
  describe('without X-Profile-Id', () => {
    it('uses the existing primary profile as OWNER', async () => {
      const s = setup({ select: [[{ id: PRIMARY_ID }]] }, { mode: 'write' });
      const { ctx, request } = contextFor(s.handler, s.cls, authed());

      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
      expect(request.profileContext).toEqual(owner(PRIMARY_ID));
      expect(s.databaseService.withRls).toHaveBeenCalledWith(USER_ID, expect.any(Function));
      expect(s.tx.insert).not.toHaveBeenCalled();
    });

    it('creates the primary profile lazily from the user record', async () => {
      const s = setup({
        select: [[], [{ name: 'Ana Souza', gender: 'feminino', dateOfBirth: '1990-04-12' }]],
        insert: [[{ id: PRIMARY_ID }]],
      });
      const { ctx, request } = contextFor(s.handler, s.cls, authed());

      await s.guard.canActivate(ctx);
      expect(s.calls.insertTables[0]).toBe(profiles);
      expect(s.calls.insertValues[0]).toEqual({
        accountOwnerId: USER_ID,
        profileType: 'primary',
        name: 'Ana Souza',
        gender: 'feminino',
        dateOfBirth: '1990-04-12',
      });
      expect(s.calls.onConflict).toBe(1);
      expect(request.profileContext).toEqual(owner(PRIMARY_ID));
    });

    it('re-reads the primary profile when a concurrent request created it first', async () => {
      const s = setup({
        select: [[], [{ name: 'Ana', gender: 'f', dateOfBirth: null }], [{ id: PRIMARY_ID }]],
        insert: [[]],
      });
      const { ctx, request } = contextFor(s.handler, s.cls, authed());

      await s.guard.canActivate(ctx);
      expect(request.profileContext.profileId).toBe(PRIMARY_ID);
    });

    it('throws NotFound when the user record no longer exists', async () => {
      const s = setup({ select: [[], []] });
      const { ctx } = contextFor(s.handler, s.cls, authed());
      await expect(s.guard.canActivate(ctx)).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('with X-Profile-Id', () => {
    it('rejects a malformed header with 400 before touching the DB', async () => {
      const s = setup({});
      for (const bad of ['not-a-uuid', '', [DEPENDENT_ID, DEPENDENT_ID], `${DEPENDENT_ID}' OR 1=1`]) {
        const { ctx } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: bad }));
        await expect(s.guard.canActivate(ctx)).rejects.toBeInstanceOf(BadRequestException);
      }
      expect(s.databaseService.withRls).not.toHaveBeenCalled();
    });

    it('resolves OWNER for an owned dependent and normalizes the id', async () => {
      const s = setup({ access: { is_owner: true, can_read: false, can_co_manage: false } }, { mode: 'write' });
      const { ctx, request } = contextFor(
        s.handler,
        s.cls,
        authed({ [PROFILE_HEADER]: ` ${DEPENDENT_ID.toUpperCase()} ` }),
      );

      await s.guard.canActivate(ctx);
      expect(request.profileContext).toEqual(owner(DEPENDENT_ID));
      expect(s.tx.execute).toHaveBeenCalledTimes(1);
    });

    it('resolves CO_MANAGE and allows write', async () => {
      const s = setup({ access: { is_owner: false, can_read: true, can_co_manage: true } }, { mode: 'write' });
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
      expect(request.profileContext).toEqual({
        profileId: DEPENDENT_ID,
        accessLevel: 'CO_MANAGE',
        readableCategories: [],
        writableCategories: [],
      });
    });

    it('resolves VIEW_ONLY and allows read', async () => {
      const s = setup({ access: { is_owner: false, can_read: true, can_co_manage: false } }, { mode: 'read' });
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
      expect(request.profileContext).toMatchObject({ profileId: DEPENDENT_ID, accessLevel: 'VIEW_ONLY' });
    });

    it('rejects VIEW_ONLY with 403 in write mode', async () => {
      const s = setup({ access: { is_owner: false, can_read: true, can_co_manage: false } }, { mode: 'write' });
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

      await expect(s.guard.canActivate(ctx)).rejects.toBeInstanceOf(ForbiddenException);
      expect(request.profileContext).toBeUndefined();
    });

    it('defaults to read mode without @ProfileAccess', async () => {
      const s = setup({ access: { is_owner: false, can_read: true, can_co_manage: false } });
      const { ctx } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));
      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
    });

    it('rejects a profile with no access (stranger, revoked or unknown) with 403', async () => {
      const s = setup({ access: { is_owner: false, can_read: false, can_co_manage: false } });
      const { ctx } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));
      await expect(s.guard.canActivate(ctx)).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('ownProfilesOnly (help-resource events)', () => {
    const ownOnly = { mode: 'read' as const, options: { allowAnonymous: true, ownProfilesOnly: true } };

    it('keeps an owned dependent named in the header', async () => {
      const s = setup({ access: { is_owner: true, can_read: false, can_co_manage: false } }, ownOnly);
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

      await s.guard.canActivate(ctx);
      expect(request.profileContext).toEqual(owner(DEPENDENT_ID));
      expect(s.tx.select).not.toHaveBeenCalled();
    });

    it('falls back to the caller\'s primary profile for a profile shared by another account', async () => {
      for (const access of [
        { is_owner: false, can_read: true, can_co_manage: true },
        { is_owner: false, can_read: true, can_co_manage: false },
      ]) {
        const s = setup({ access, select: [[{ id: PRIMARY_ID }]] }, ownOnly);
        const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

        await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
        expect(request.profileContext).toEqual(owner(PRIMARY_ID));
      }
    });

    it('falls back to the primary profile instead of 403 for a profile the caller cannot reach', async () => {
      const s = setup(
        { access: { is_owner: false, can_read: false, can_co_manage: false }, select: [[{ id: PRIMARY_ID }]] },
        ownOnly,
      );
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
      expect(request.profileContext).toEqual(owner(PRIMARY_ID));
    });

    it('still rejects a malformed header with 400', async () => {
      const s = setup({}, ownOnly);
      const { ctx } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: 'not-a-uuid' }));
      await expect(s.guard.canActivate(ctx)).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('authentication', () => {
    it('throws 401 when no user is attached', async () => {
      const s = setup({}, { mode: 'read' });
      const { ctx } = contextFor(s.handler, s.cls, { headers: {} });
      await expect(s.guard.canActivate(ctx)).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('lets anonymous requests through without context when allowAnonymous is set', async () => {
      const s = setup({}, { mode: 'read', options: { allowAnonymous: true } });
      const { ctx, request } = contextFor(s.handler, s.cls, { headers: {} });

      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
      expect(request.profileContext).toBeUndefined();
      expect(s.databaseService.withRls).not.toHaveBeenCalled();
    });

    it('treats an anonymous request that names a profile as anonymous (no context)', async () => {
      const s = setup({}, { mode: 'read', options: { allowAnonymous: true } });
      const { ctx, request } = contextFor(s.handler, s.cls, { headers: { [PROFILE_HEADER]: DEPENDENT_ID } });
      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
      expect(request.profileContext).toBeUndefined();
    });
  });
  describe('categories (Phase 11.1, PREM-07)', () => {
    const grantee = (readable: string[], writable: string[], coManage = writable.length > 0): AccessRow => ({
      is_owner: false,
      can_read: true,
      can_co_manage: coManage,
      readable,
      writable,
    });

    it('gives an OWNER every category for reading and writing', async () => {
      const s = setup({ access: { is_owner: true, can_read: false, can_co_manage: false, readable: [], writable: [] } }, {
        mode: 'write',
        options: { category: ['habits', 'care', 'emotional_journal'] },
      });
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
      expect(request.profileContext).toEqual(owner(DEPENDENT_ID));
    });

    it('gives the primary profile (no header) every category', async () => {
      const s = setup({ select: [[{ id: PRIMARY_ID }]] }, { mode: 'write', options: { category: 'conditions' } });
      const { ctx, request } = contextFor(s.handler, s.cls, authed());
      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
      expect(request.profileContext).toEqual(owner(PRIMARY_ID));
    });

    it('resolves a grantee\'s categories in one statement, ordered as SHARE_CATEGORIES', async () => {
      const s = setup({ access: grantee(['care', 'habits', 'unknown'], ['habits']) }, { mode: 'read' });
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

      await s.guard.canActivate(ctx);
      expect(request.profileContext).toEqual({
        profileId: DEPENDENT_ID,
        accessLevel: 'CO_MANAGE',
        readableCategories: ['habits', 'care'],
        writableCategories: ['habits'],
      });
      expect(s.tx.execute).toHaveBeenCalledTimes(1);
    });

    it('allows reading a granted category', async () => {
      const s = setup({ access: grantee(['habits'], [], false) }, { mode: 'read', options: { category: 'habits' } });
      const { ctx } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));
      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
    });

    it('rejects writing a read-only granted category as VIEW_ONLY (403)', async () => {
      const s = setup({ access: grantee(['habits'], [], false) }, { mode: 'write', options: { category: 'habits' } });
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));
      await expect(s.guard.canActivate(ctx)).rejects.toThrow('Acesso somente leitura a este perfil.');
      expect(request.profileContext).toBeUndefined();
    });

    it('rejects reading a category that was not shared with 403 and a clear message', async () => {
      const s = setup({ access: grantee(['habits'], [], false) }, { mode: 'read', options: { category: 'care' } });
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

      const error = await s.guard.canActivate(ctx).catch((e: unknown) => e);
      expect(error).toBeInstanceOf(ForbiddenException);
      expect((error as Error).message).toBe(NOT_SHARED);
      expect(request.profileContext).toBeUndefined();
    });

    it('rejects a CO_MANAGE write on a category that is only readable (mixed grants)', async () => {
      const s = setup(
        { access: grantee(['habits', 'emotional_journal'], ['habits']) },
        { mode: 'write', options: { category: 'emotional_journal' } },
      );
      const { ctx } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));
      await expect(s.guard.canActivate(ctx)).rejects.toThrow(NOT_SHARED);
    });

    it('requires every category when given an array', async () => {
      const both = setup({ access: grantee(['habits', 'care'], [], false) }, {
        mode: 'read',
        options: { category: ['habits', 'care'] },
      });
      const okCtx = contextFor(both.handler, both.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));
      await expect(both.guard.canActivate(okCtx.ctx)).resolves.toBe(true);

      const partial = setup({ access: grantee(['habits'], [], false) }, {
        mode: 'read',
        options: { category: ['habits', 'care'] },
      });
      const badCtx = contextFor(partial.handler, partial.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));
      await expect(partial.guard.canActivate(badCtx.ctx)).rejects.toThrow(NOT_SHARED);
    });

    it('does not check categories on routes without one (mixed routes, RLS filters rows)', async () => {
      const s = setup({ access: grantee([], [], false) }, { mode: 'read' });
      const { ctx } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));
      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
    });

    it('maps journal areas like app_journal_area_category', () => {
      expect(journalAreaCategory('physical')).toBe('physical_journal');
      expect(journalAreaCategory('emotional')).toBe('emotional_journal');
      expect(journalAreaCategory(undefined)).toBe('emotional_journal');
      expect(journalAreaCategory(null)).toBe('emotional_journal');
    });

    it('assertCategory checks the mode-specific list', () => {
      const profile: ProfileContext = {
        profileId: DEPENDENT_ID,
        accessLevel: 'CO_MANAGE',
        readableCategories: ['habits', 'emotional_journal'],
        writableCategories: ['habits'],
      };
      expect(() => assertCategory(profile, 'read', 'emotional_journal')).not.toThrow();
      expect(() => assertCategory(profile, 'write', 'habits')).not.toThrow();
      expect(() => assertCategory(profile, 'write', 'emotional_journal')).toThrow(NOT_SHARED);
      expect(() => assertCategory(profile, 'read', 'care')).toThrow(ForbiddenException);
      expect(() => assertCategory(owner(PRIMARY_ID), 'write', 'care')).not.toThrow();
    });
  });
});
