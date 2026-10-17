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
  ProfileAccess,
  ProfileAccessMode,
  ProfileAccessOptions,
  ProfileContextGuard,
  PROFILE_HEADER,
} from '../../src/modules/profiles/profile-context';
import { profiles } from '../../src/database/schema/profiles.schema';

const USER_ID = '11111111-1111-4111-8111-111111111111';
const PRIMARY_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const DEPENDENT_ID = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';

type AccessRow = { is_owner: boolean; can_read: boolean; can_co_manage: boolean };

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
      expect(request.profileContext).toEqual({ profileId: PRIMARY_ID, accessLevel: 'OWNER' });
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
      expect(request.profileContext).toEqual({ profileId: PRIMARY_ID, accessLevel: 'OWNER' });
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
      expect(request.profileContext).toEqual({ profileId: DEPENDENT_ID, accessLevel: 'OWNER' });
      expect(s.tx.execute).toHaveBeenCalledTimes(1);
    });

    it('resolves CO_MANAGE and allows write', async () => {
      const s = setup({ access: { is_owner: false, can_read: true, can_co_manage: true } }, { mode: 'write' });
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
      expect(request.profileContext).toEqual({ profileId: DEPENDENT_ID, accessLevel: 'CO_MANAGE' });
    });

    it('resolves VIEW_ONLY and allows read', async () => {
      const s = setup({ access: { is_owner: false, can_read: true, can_co_manage: false } }, { mode: 'read' });
      const { ctx, request } = contextFor(s.handler, s.cls, authed({ [PROFILE_HEADER]: DEPENDENT_ID }));

      await expect(s.guard.canActivate(ctx)).resolves.toBe(true);
      expect(request.profileContext).toEqual({ profileId: DEPENDENT_ID, accessLevel: 'VIEW_ONLY' });
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
});
