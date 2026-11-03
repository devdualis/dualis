import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  NotFoundException,
} from '@nestjs/common';
import { SQL } from 'drizzle-orm';
import { PgDialect } from 'drizzle-orm/pg-core';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import {
  FamilySharingService,
  generateInviteCode,
  FAILED_INVITE_ACCEPT_WINDOW_MS,
  INVITE_CODE_CHARS,
  MAX_FAILED_INVITE_ACCEPTS,
} from '../../src/modules/profiles/family-sharing.service';
import { CreateInviteDto } from '../../src/modules/profiles/dto/create-invite.dto';
import { UpdateGrantDto } from '../../src/modules/profiles/dto/update-grant.dto';
import { profiles } from '../../src/database/schema/profiles.schema';
import { sharedAccessGrants } from '../../src/database/schema/shared-access-grants.schema';

describe('FamilySharingService Unit Tests', () => {
  let service: FamilySharingService;
  let mockDatabaseService: any;

  beforeEach(() => {
    mockDatabaseService = {
      withRls: vi.fn(),
    };
    service = new FamilySharingService(mockDatabaseService);
  });

  describe('Invite Code Generation', () => {
    it('generates 10-character uppercase codes excluding ambiguous characters 0, O, 1, I', () => {
      const allowedCharsSet = new Set(INVITE_CODE_CHARS.split(''));

      // Run multiple iterations to verify stability
      for (let i = 0; i < 100; i++) {
        const code = generateInviteCode();
        expect(code).toHaveLength(10);
        expect(code).toMatch(/^[2-9A-HJ-NP-Z]{10}$/);

        // Explicitly check forbidden ambiguous characters
        expect(code).not.toContain('0');
        expect(code).not.toContain('O');
        expect(code).not.toContain('1');
        expect(code).not.toContain('I');

        for (const char of code) {
          expect(allowedCharsSet.has(char)).toBe(true);
        }
      }
    });
  });

  describe('createInvite', () => {
    const userId = 'user-owner-uuid';
    const targetProfileId = 'profile-target-uuid';
    const scope = { relationship: 'sibling' as const, categories: ['habits' as const] };

    it('creates an invite with 72h TTL and PENDING status when caller owns the profile', async () => {
      const mockProfile = {
        id: targetProfileId,
        accountOwnerId: userId,
        profileType: 'primary',
        name: 'John Doe',
      };

      const now = Date.now();
      const mockCreatedGrant = {
        id: 'grant-uuid-1',
        granterUserId: userId,
        targetProfileId,
        accessLevel: 'VIEW_ONLY',
        inviteCode: 'ABC234',
        status: 'PENDING',
        expiresAt: new Date(now + 72 * 60 * 60 * 1000),
        createdAt: new Date(),
      };

      let insertedValues: any = null;

      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          transaction: vi.fn().mockImplementation((cb: any) => cb(tx)),
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([mockProfile]),
            }),
          }),
          insert: vi.fn().mockReturnValue({
            values: vi.fn().mockImplementation((val) => {
              insertedValues = val;
              return {
                returning: vi.fn().mockResolvedValue([mockCreatedGrant]),
              };
            }),
          }),
        };
        return callback(tx);
      });

      const result = await service.createInvite(userId, targetProfileId, 'VIEW_ONLY', scope);

      expect(mockDatabaseService.withRls).toHaveBeenCalledWith(userId, expect.any(Function));
      expect(result.id).toBe(mockCreatedGrant.id);
      expect(result.inviteCode).toBe('ABC234');
      expect(result.accessLevel).toBe('VIEW_ONLY');
      expect(result.targetProfileId).toBe(targetProfileId);

      // Verify 72-hour TTL
      expect(insertedValues).toBeDefined();
      expect(insertedValues.status).toBe('PENDING');
      const expectedExpiresAt = now + 72 * 60 * 60 * 1000;
      const actualExpiresAt = new Date(insertedValues.expiresAt).getTime();
      expect(Math.abs(actualExpiresAt - expectedExpiresAt)).toBeLessThan(5000);
    });

    it('throws ForbiddenException (403) when user does not own the target profile', async () => {
      const mockProfile = {
        id: targetProfileId,
        accountOwnerId: 'someone-else-uuid',
        name: 'Someone Else',
      };

      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([mockProfile]),
            }),
          }),
        };
        return callback(tx);
      });

      await expect(
        service.createInvite(userId, targetProfileId, 'VIEW_ONLY', scope),
      ).rejects.toThrow(ForbiddenException);
    });

    it('throws ForbiddenException (403) when target profile does not exist', async () => {
      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([]),
            }),
          }),
        };
        return callback(tx);
      });

      await expect(
        service.createInvite(userId, targetProfileId, 'CO_MANAGE', scope),
      ).rejects.toThrow(ForbiddenException);
    });

    it('retries on unique collision (23505) up to max attempts', async () => {
      const mockProfile = {
        id: targetProfileId,
        accountOwnerId: userId,
        profileType: 'primary',
        name: 'John Doe',
      };

      const mockCreatedGrant = {
        id: 'grant-uuid-retry',
        granterUserId: userId,
        targetProfileId,
        accessLevel: 'CO_MANAGE',
        inviteCode: 'XYZ892',
        status: 'PENDING',
        expiresAt: new Date(Date.now() + 72 * 60 * 60 * 1000),
      };

      let attempts = 0;
      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          transaction: vi.fn().mockImplementation((cb: any) => cb(tx)),
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([mockProfile]),
            }),
          }),
          insert: vi.fn().mockReturnValue({
            values: vi.fn().mockImplementation(() => {
              attempts++;
              if (attempts === 1) {
                const err: any = new Error('duplicate key value violates unique constraint');
                err.code = '23505';
                throw err;
              }
              return {
                returning: vi.fn().mockResolvedValue([mockCreatedGrant]),
              };
            }),
          }),
        };
        return callback(tx);
      });

      const result = await service.createInvite(userId, targetProfileId, 'CO_MANAGE', scope);
      expect(attempts).toBe(2);
      expect(result.id).toBe('grant-uuid-retry');
    });

    it('stores the relationship and categories and returns them', async () => {
      let insertedValues: any = null;
      mockDatabaseService.withRls.mockImplementation(async (_uid: string, callback: any) => {
        const tx = {
          transaction: vi.fn().mockImplementation((cb: any) => cb(tx)),
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([
                { id: targetProfileId, accountOwnerId: userId, profileType: 'primary' },
              ]),
            }),
          }),
          insert: vi.fn().mockReturnValue({
            values: vi.fn().mockImplementation((val) => {
              insertedValues = val;
              return {
                returning: vi.fn().mockResolvedValue([
                  {
                    id: 'grant-scope',
                    inviteCode: 'SCOPE23456',
                    accessLevel: 'VIEW_ONLY',
                    targetProfileId,
                    expiresAt: new Date(),
                    relationship: val.relationship,
                    categories: val.categories,
                  },
                ]),
              };
            }),
          }),
        };
        return callback(tx);
      });

      const result = await service.createInvite(userId, targetProfileId, 'VIEW_ONLY', {
        relationship: 'sibling',
        categories: ['habits', 'care'],
      });

      expect(insertedValues.relationship).toBe('sibling');
      expect(insertedValues.categories).toEqual(['habits', 'care']);
      expect(result.relationship).toBe('sibling');
      expect(result.categories).toEqual(['habits', 'care']);
    });
  });

  describe('CreateInviteDto validation', () => {
    const valid = {
      targetProfileId: 'c0a80121-7ac0-4e1c-9d3a-0e5f8a7b6c5d',
      accessLevel: 'VIEW_ONLY',
      relationship: 'sibling',
      categories: ['habits'],
    };
    const errorsFor = async (payload: Record<string, unknown>) =>
      (await validate(plainToInstance(CreateInviteDto, payload))).map((e) => e.property);

    it('accepts a relationship and a set of valid categories', async () => {
      expect(await errorsFor(valid)).toEqual([]);
      expect(await errorsFor({ ...valid, dependentShareConfirmed: true })).toEqual([]);
    });

    it.each([
      ['a missing relationship', { relationship: undefined }, 'relationship'],
      ['an unknown relationship', { relationship: 'boss' }, 'relationship'],
      ['missing categories', { categories: undefined }, 'categories'],
      ['empty categories', { categories: [] }, 'categories'],
      ['duplicate categories', { categories: ['habits', 'habits'] }, 'categories'],
      ['an unknown category', { categories: ['habits', 'safety'] }, 'categories'],
      ['a non-boolean confirmation', { dependentShareConfirmed: 'yes' }, 'dependentShareConfirmed'],
    ])('rejects %s', async (_label, patch, property) => {
      expect(await errorsFor({ ...valid, ...patch })).toContain(property);
    });
  });

  describe('UpdateGrantDto validation', () => {
    const errorsFor = async (payload: Record<string, unknown>) =>
      (await validate(plainToInstance(UpdateGrantDto, payload))).map((e) => e.property);

    it('accepts partial edits', async () => {
      expect(await errorsFor({ categories: ['care'] })).toEqual([]);
      expect(await errorsFor({ relationship: 'friend' })).toEqual([]);
      expect(await errorsFor({ categories: ['care'], dependentShareConfirmed: true })).toEqual([]);
    });

    it.each([
      ['empty categories', { categories: [] }, 'categories'],
      ['duplicate categories', { categories: ['care', 'care'] }, 'categories'],
      ['an unknown category', { categories: ['safety'] }, 'categories'],
      ['an unknown relationship', { relationship: 'boss' }, 'relationship'],
      ['a non-boolean confirmation', { categories: ['care'], dependentShareConfirmed: 1 }, 'dependentShareConfirmed'],
    ])('rejects %s', async (_label, payload, property) => {
      expect(await errorsFor(payload)).toContain(property);
    });
  });

  describe('dependent share confirmation (gap 9)', () => {
    const userId = 'user-owner-uuid';
    const targetProfileId = 'profile-dependent-uuid';

    const mockInvite = (profileType: string) => {
      const captured: { values?: any } = {};
      mockDatabaseService.withRls.mockImplementation(async (_uid: string, callback: any) => {
        const tx = {
          transaction: vi.fn().mockImplementation((cb: any) => cb(tx)),
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([
                { id: targetProfileId, accountOwnerId: userId, profileType },
              ]),
            }),
          }),
          insert: vi.fn().mockReturnValue({
            values: vi.fn().mockImplementation((val) => {
              captured.values = val;
              return {
                returning: vi.fn().mockResolvedValue([
                  { id: 'g', inviteCode: 'C', accessLevel: 'VIEW_ONLY', targetProfileId, ...val },
                ]),
              };
            }),
          }),
        };
        return callback(tx);
      });
      return captured;
    };

    it('refuses an invite for a dependent without dependentShareConfirmed true, before inserting', async () => {
      const captured = mockInvite('dependent_minor');
      const attempt = service.createInvite(userId, targetProfileId, 'VIEW_ONLY', {
        relationship: 'parent',
        categories: ['habits'],
      });
      await expect(attempt).rejects.toThrow(BadRequestException);
      await expect(
        service.createInvite(userId, targetProfileId, 'VIEW_ONLY', {
          relationship: 'parent',
          categories: ['habits'],
          dependentShareConfirmed: false,
        }),
      ).rejects.toThrow('Confirme o compartilhamento do perfil dependente.');
      expect(captured.values).toBeUndefined();
    });

    it('stores the confirmation time when the dependent share is confirmed', async () => {
      const captured = mockInvite('dependent_adult');
      const before = Date.now();
      await service.createInvite(userId, targetProfileId, 'VIEW_ONLY', {
        relationship: 'caregiver',
        categories: ['care'],
        dependentShareConfirmed: true,
      });
      expect(captured.values.dependentShareConfirmedAt).toBeInstanceOf(Date);
      expect(captured.values.dependentShareConfirmedAt.getTime()).toBeGreaterThanOrEqual(before);
    });

    it("ignores the flag on the caller's primary profile and leaves the column NULL", async () => {
      const captured = mockInvite('primary');
      await service.createInvite(userId, targetProfileId, 'VIEW_ONLY', {
        relationship: 'sibling',
        categories: ['habits'],
        dependentShareConfirmed: true,
      });
      expect(captured.values.dependentShareConfirmedAt ?? null).toBeNull();
    });
  });

  describe('updateGrant', () => {
    const granterId = 'user-granter-uuid';
    const grantId = 'grant-edit-uuid';
    const targetProfileId = 'profile-edit-uuid';

    const grantRow = (overrides: Record<string, unknown> = {}) => ({
      id: grantId,
      granterUserId: granterId,
      targetProfileId,
      granteeUserId: 'user-grantee-uuid',
      accessLevel: 'VIEW_ONLY',
      inviteCode: 'EDIT234567',
      status: 'ACCEPTED',
      expiresAt: new Date(Date.now() - 60_000),
      acceptedAt: new Date(),
      revokedAt: null,
      relationship: 'sibling',
      categories: ['habits'],
      dependentShareConfirmedAt: null,
      createdAt: new Date(),
      ...overrides,
    });

    const mockUpdate = (opts: {
      grant?: any;
      profileType?: string;
      updateError?: any;
    }) => {
      const captured: { set?: any; updates: number } = { updates: 0 };
      mockDatabaseService.withRls.mockImplementation(async (_uid: string, callback: any) => {
        const tx = {
          execute: vi.fn().mockResolvedValue({ rows: [] }),
          select: vi.fn().mockImplementation(() => ({
            from: vi.fn().mockImplementation((table: unknown) => ({
              where: vi.fn().mockImplementation(() => {
                if (table === sharedAccessGrants) return Promise.resolve(opts.grant ? [opts.grant] : []);
                if (table === profiles) {
                  return Promise.resolve([
                    { name: 'Lucas', profileType: opts.profileType ?? 'primary' },
                  ]);
                }
                return Promise.resolve([
                  { id: 'user-grantee-uuid', name: 'Maria Souza', email: 'maria@example.com' },
                ]);
              }),
            })),
          })),
          update: vi.fn().mockReturnValue({
            set: vi.fn().mockImplementation((values: any) => {
              captured.set = values;
              captured.updates++;
              return {
                where: vi.fn().mockReturnValue({
                  returning: vi.fn().mockImplementation(() =>
                    opts.updateError
                      ? Promise.reject(opts.updateError)
                      : Promise.resolve([{ ...opts.grant, ...values }]),
                  ),
                }),
              };
            }),
          }),
        };
        return callback(tx);
      });
      return captured;
    };

    it('lets the granter change the categories of an ACCEPTED grant and returns the outgoing item', async () => {
      const captured = mockUpdate({ grant: grantRow() });
      const result = await service.updateGrant(granterId, grantId, {
        categories: ['habits', 'emotional_journal'],
      });
      expect(captured.set.categories).toEqual(['habits', 'emotional_journal']);
      expect(captured.set.dependentShareConfirmedAt).toBeUndefined();
      expect(result).toMatchObject({
        id: grantId,
        targetProfileName: 'Lucas',
        relationship: 'sibling',
        categories: ['habits', 'emotional_journal'],
        status: 'ACCEPTED',
        granteeName: 'Maria Souza',
        granteeEmail: 'maria@example.com',
      });
    });

    it('changes the relationship alone', async () => {
      const captured = mockUpdate({ grant: grantRow({ relationship: null }) });
      const result = await service.updateGrant(granterId, grantId, { relationship: 'friend' });
      expect(captured.set).toEqual({ relationship: 'friend' });
      expect(result.relationship).toBe('friend');
    });

    it('requires at least one of categories or relationship (400)', async () => {
      const captured = mockUpdate({ grant: grantRow() });
      await expect(
        service.updateGrant(granterId, grantId, { dependentShareConfirmed: true }),
      ).rejects.toThrow(BadRequestException);
      expect(captured.updates).toBe(0);
    });

    it('on a dependent target requires dependentShareConfirmed true and refreshes the confirmation time', async () => {
      let captured = mockUpdate({ grant: grantRow(), profileType: 'dependent_minor' });
      await expect(
        service.updateGrant(granterId, grantId, { categories: ['care'] }),
      ).rejects.toThrow('Confirme o compartilhamento do perfil dependente.');
      expect(captured.updates).toBe(0);

      captured = mockUpdate({ grant: grantRow(), profileType: 'dependent_minor' });
      const before = Date.now();
      await service.updateGrant(granterId, grantId, {
        categories: ['care'],
        dependentShareConfirmed: true,
      });
      expect(captured.set.dependentShareConfirmedAt).toBeInstanceOf(Date);
      expect(captured.set.dependentShareConfirmedAt.getTime()).toBeGreaterThanOrEqual(before);
    });

    it('returns 404 when the grant is unknown or not visible', async () => {
      mockUpdate({ grant: undefined });
      await expect(
        service.updateGrant(granterId, grantId, { categories: ['habits'] }),
      ).rejects.toThrow(NotFoundException);
    });

    it('returns 403 when the caller is not the granter', async () => {
      const captured = mockUpdate({ grant: grantRow() });
      await expect(
        service.updateGrant('user-grantee-uuid', grantId, { categories: ['habits', 'care'] }),
      ).rejects.toThrow(ForbiddenException);
      expect(captured.updates).toBe(0);
    });

    it('returns 409 GRANT_SCOPE_LOCKED on a REVOKED grant', async () => {
      const captured = mockUpdate({ grant: grantRow({ status: 'REVOKED', revokedAt: new Date() }) });
      const error = await service
        .updateGrant(granterId, grantId, { categories: ['habits'] })
        .catch((e) => e);
      expect(error).toBeInstanceOf(ConflictException);
      expect(error.getResponse()).toMatchObject({ code: 'GRANT_SCOPE_LOCKED' });
      expect(captured.updates).toBe(0);
    });

    it('returns 409 GRANT_SCOPE_LOCKED on a PENDING invite past its expiry', async () => {
      mockUpdate({ grant: grantRow({ status: 'PENDING', granteeUserId: null, acceptedAt: null }) });
      await expect(
        service.updateGrant(granterId, grantId, { categories: ['habits'] }),
      ).rejects.toThrow(ConflictException);
    });

    it('maps the database trigger errors: GRANT_SCOPE_LOCKED to 409, GRANTEE_MAY_ONLY_REVOKE to 403', async () => {
      const dbError = (message: string) =>
        Object.assign(new Error('Failed query'), { cause: Object.assign(new Error(message), { code: 'P0001' }) });

      mockUpdate({ grant: grantRow(), updateError: dbError('GRANT_SCOPE_LOCKED') });
      const locked = await service
        .updateGrant(granterId, grantId, { categories: ['habits'] })
        .catch((e) => e);
      expect(locked).toBeInstanceOf(ConflictException);
      expect(locked.getResponse()).toMatchObject({ code: 'GRANT_SCOPE_LOCKED' });

      mockUpdate({ grant: grantRow(), updateError: Object.assign(new Error('GRANTEE_MAY_ONLY_REVOKE'), { code: 'P0001' }) });
      await expect(
        service.updateGrant(granterId, grantId, { categories: ['habits'] }),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('acceptInvite', () => {
    const granteeUserId = 'user-grantee-uuid';
    const inviteCode = 'abc234';

    it('normalizes code and returns accepted grant on happy path', async () => {
      const mockAcceptedRow = {
        id: 'grant-uuid-1',
        granter_user_id: 'user-granter-uuid',
        target_profile_id: 'profile-uuid-1',
        grantee_user_id: granteeUserId,
        access_level: 'VIEW_ONLY',
        invite_code: 'ABC234',
        status: 'ACCEPTED',
        expires_at: new Date('2026-10-18T12:00:00Z'),
        accepted_at: new Date('2026-10-15T12:00:00Z'),
        revoked_at: null,
        created_at: new Date('2026-10-15T10:00:00Z'),
      };

      let executedSql: any = null;
      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          execute: vi.fn().mockImplementation((query) => {
            executedSql = query;
            return Promise.resolve({ rows: [mockAcceptedRow] });
          }),
        };
        return callback(tx);
      });

      const result = await service.acceptInvite(granteeUserId, '  abc234  ');

      expect(mockDatabaseService.withRls).toHaveBeenCalledWith(granteeUserId, expect.any(Function));
      expect(result.id).toBe('grant-uuid-1');
      expect(result.status).toBe('ACCEPTED');
      expect(result.granterUserId).toBe('user-granter-uuid');
      expect(result.granteeUserId).toBe(granteeUserId);
      expect(result.accessLevel).toBe('VIEW_ONLY');
      expect(result.inviteCode).toBe('ABC234');
    });

    it('throws NotFoundException (404) when invite is not found or expired (no rows returned)', async () => {
      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          execute: vi.fn().mockResolvedValue({ rows: [] }),
        };
        return callback(tx);
      });

      await expect(service.acceptInvite(granteeUserId, inviteCode)).rejects.toThrow(
        new NotFoundException('Invite not found or expired'),
      );
    });

    it('throws BadRequestException (400) on SELF_GRANT SQL exception', async () => {
      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          execute: vi.fn().mockImplementation(() => {
            const err: any = new Error('SELF_GRANT: Cannot accept an invite to your own profile');
            err.code = 'P0001';
            throw err;
          }),
        };
        return callback(tx);
      });

      await expect(service.acceptInvite(granteeUserId, inviteCode)).rejects.toThrow(
        BadRequestException,
      );
      // The app shows a specific message for the caller's own code.
      await expect(service.acceptInvite(granteeUserId, inviteCode)).rejects.toMatchObject({
        response: { code: 'INVITE_OWN_PROFILE' },
      });
    });

    describe('failed-attempt cap', () => {
      const acceptedRow = {
        id: 'grant-uuid-1',
        granter_user_id: 'user-granter-uuid',
        target_profile_id: 'profile-uuid-1',
        grantee_user_id: granteeUserId,
        access_level: 'VIEW_ONLY',
        invite_code: 'ABC234DEF5',
        status: 'ACCEPTED',
        expires_at: new Date(),
        accepted_at: new Date(),
        revoked_at: null,
        created_at: new Date(),
      };

      const acceptReturns = (rows: unknown[]) =>
        mockDatabaseService.withRls.mockImplementation(async (_uid: string, callback: any) =>
          callback({ execute: vi.fn().mockResolvedValue({ rows }) }),
        );

      const failUntilCapped = async (userId = granteeUserId) => {
        for (let i = 0; i < MAX_FAILED_INVITE_ACCEPTS; i++) {
          await expect(service.acceptInvite(userId, inviteCode)).rejects.toThrow(NotFoundException);
        }
      };

      const statusOf = (err: unknown) => (err instanceof HttpException ? err.getStatus() : undefined);

      afterEach(() => {
        vi.useRealTimers();
      });

      it('answers 429 once the account used up its failed attempts, without querying again', async () => {
        acceptReturns([]);
        await failUntilCapped();
        mockDatabaseService.withRls.mockClear();

        const err = await service.acceptInvite(granteeUserId, inviteCode).catch((e) => e);

        expect(statusOf(err)).toBe(HttpStatus.TOO_MANY_REQUESTS);
        expect(mockDatabaseService.withRls).not.toHaveBeenCalled();
        // The cap is per account.
        await expect(service.acceptInvite('user-other-uuid', inviteCode)).rejects.toThrow(
          NotFoundException,
        );
      });

      it('counts parallel attempts before their lookups finish', async () => {
        acceptReturns([]);

        const results = await Promise.allSettled(
          Array.from({ length: MAX_FAILED_INVITE_ACCEPTS + 3 }, () =>
            service.acceptInvite(granteeUserId, inviteCode),
          ),
        );

        const tooMany = results.filter(
          (r) => r.status === 'rejected' && statusOf(r.reason) === HttpStatus.TOO_MANY_REQUESTS,
        );
        expect(tooMany).toHaveLength(3);
        expect(mockDatabaseService.withRls).toHaveBeenCalledTimes(MAX_FAILED_INVITE_ACCEPTS);
      });

      it('does not count successful accepts', async () => {
        acceptReturns([acceptedRow]);

        for (let i = 0; i < MAX_FAILED_INVITE_ACCEPTS + 2; i++) {
          await expect(service.acceptInvite(granteeUserId, inviteCode)).resolves.toMatchObject({
            status: 'ACCEPTED',
          });
        }
      });

      it('lets the account try again once the window has passed', async () => {
        vi.useFakeTimers();
        vi.setSystemTime(new Date('2026-10-30T12:00:00Z'));
        acceptReturns([]);
        await failUntilCapped();
        const blocked = await service.acceptInvite(granteeUserId, inviteCode).catch((e) => e);
        expect(statusOf(blocked)).toBe(HttpStatus.TOO_MANY_REQUESTS);

        vi.setSystemTime(Date.now() + FAILED_INVITE_ACCEPT_WINDOW_MS);

        await expect(service.acceptInvite(granteeUserId, inviteCode)).rejects.toThrow(
          NotFoundException,
        );
      });
    });
  });

  describe('revokeGrant', () => {
    const granterUserId = 'user-granter-uuid';
    const granteeUserId = 'user-grantee-uuid';
    const strangerUserId = 'user-stranger-uuid';
    const grantId = 'grant-uuid-1';

    it('allows granter to revoke grant and sets status REVOKED and revokedAt', async () => {
      const existingGrant = {
        id: grantId,
        granterUserId,
        granteeUserId,
        status: 'ACCEPTED',
        revokedAt: null,
      };

      const updatedGrant = {
        id: grantId,
        status: 'REVOKED',
        revokedAt: new Date(),
      };

      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([existingGrant]),
            }),
          }),
          update: vi.fn().mockReturnValue({
            set: vi.fn().mockReturnValue({
              where: vi.fn().mockReturnValue({
                returning: vi.fn().mockResolvedValue([updatedGrant]),
              }),
            }),
          }),
        };
        return callback(tx);
      });

      const result = await service.revokeGrant(granterUserId, grantId);

      expect(result.id).toBe(grantId);
      expect(result.status).toBe('REVOKED');
      expect(result.revokedAt).toBeDefined();
    });

    it('allows grantee to revoke grant', async () => {
      const existingGrant = {
        id: grantId,
        granterUserId,
        granteeUserId,
        status: 'ACCEPTED',
        revokedAt: null,
      };

      const updatedGrant = {
        id: grantId,
        status: 'REVOKED',
        revokedAt: new Date(),
      };

      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([existingGrant]),
            }),
          }),
          update: vi.fn().mockReturnValue({
            set: vi.fn().mockReturnValue({
              where: vi.fn().mockReturnValue({
                returning: vi.fn().mockResolvedValue([updatedGrant]),
              }),
            }),
          }),
        };
        return callback(tx);
      });

      const result = await service.revokeGrant(granteeUserId, grantId);

      expect(result.id).toBe(grantId);
      expect(result.status).toBe('REVOKED');
      expect(result.revokedAt).toBeDefined();
    });

    it('throws NotFoundException (404) when stranger tries to revoke grant', async () => {
      const existingGrant = {
        id: grantId,
        granterUserId,
        granteeUserId,
        status: 'ACCEPTED',
        revokedAt: null,
      };

      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([existingGrant]),
            }),
          }),
        };
        return callback(tx);
      });

      await expect(service.revokeGrant(strangerUserId, grantId)).rejects.toThrow(
        new NotFoundException('Grant not found'),
      );
    });

    it('is idempotent when grant is already REVOKED', async () => {
      const revokedAt = new Date('2026-10-15T09:00:00Z');
      const existingGrant = {
        id: grantId,
        granterUserId,
        granteeUserId,
        status: 'REVOKED',
        revokedAt,
      };

      const updateSpy = vi.fn();

      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        const tx = {
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([existingGrant]),
            }),
          }),
          update: updateSpy,
        };
        return callback(tx);
      });

      const result = await service.revokeGrant(granterUserId, grantId);

      expect(result.id).toBe(grantId);
      expect(result.status).toBe('REVOKED');
      expect(result.revokedAt).toEqual(revokedAt);
      expect(updateSpy).not.toHaveBeenCalled();
    });
  });

  describe('listGrants', () => {
    const userId = 'user-curr-uuid';

    it('reports outgoing PENDING grants past expiresAt as EXPIRED and includes targetProfileName', async () => {
      const past = new Date(Date.now() - 10 * 60 * 1000);
      const future = new Date(Date.now() + 24 * 60 * 60 * 1000);

      const mockOutgoingRows = [
        {
          grant: {
            id: 'grant-out-1',
            granterUserId: userId,
            targetProfileId: 'profile-1',
            accessLevel: 'VIEW_ONLY',
            status: 'PENDING',
            inviteCode: 'CODE01',
            granteeUserId: null,
            expiresAt: past, // Expired
            acceptedAt: null,
            revokedAt: null,
            createdAt: new Date(),
          },
          targetProfileName: 'Lucas Rincon',
        },
        {
          grant: {
            id: 'grant-out-2',
            granterUserId: userId,
            targetProfileId: 'profile-2',
            accessLevel: 'CO_MANAGE',
            status: 'PENDING',
            inviteCode: 'CODE02',
            granteeUserId: null,
            expiresAt: future, // Still valid
            acceptedAt: null,
            revokedAt: null,
            createdAt: new Date(),
          },
          targetProfileName: 'Mariana Rincon',
        },
      ];

      const mockIncomingRows = [
        {
          grant: {
            id: 'grant-in-1',
            granterUserId: 'other-user',
            targetProfileId: 'profile-3',
            accessLevel: 'VIEW_ONLY',
            status: 'ACCEPTED',
            expiresAt: past, // Expired TTL for invite, but active share!
            acceptedAt: new Date(),
            createdAt: new Date(),
          },
          targetProfileName: 'Helena Rincon',
        },
      ];

      mockDatabaseService.withRls.mockImplementation(async (uid: string, callback: any) => {
        let callCount = 0;
        const tx = {
          select: vi.fn().mockImplementation(() => ({
            from: vi.fn().mockReturnValue({
              leftJoin: vi.fn().mockReturnValue({
                where: vi.fn().mockImplementation(() => {
                  callCount++;
                  if (callCount === 1) {
                    return Promise.resolve(mockOutgoingRows);
                  }
                  return Promise.resolve(mockIncomingRows);
                }),
              }),
            }),
          })),
        };
        return callback(tx);
      });

      const result = await service.listGrants(userId);

      expect(result.outgoing).toHaveLength(2);
      expect(result.outgoing[0].id).toBe('grant-out-1');
      expect(result.outgoing[0].status).toBe('EXPIRED');
      expect(result.outgoing[0].targetProfileName).toBe('Lucas Rincon');

      expect(result.outgoing[1].id).toBe('grant-out-2');
      expect(result.outgoing[1].status).toBe('PENDING');
      expect(result.outgoing[1].targetProfileName).toBe('Mariana Rincon');

      // Verify coordinator correction: accepted grant stays active regardless of expiresAt
      expect(result.incoming).toHaveLength(1);
      expect(result.incoming[0].id).toBe('grant-in-1');
      expect(result.incoming[0].status).toBe('ACCEPTED');
      expect(result.incoming[0].targetProfileName).toBe('Helena Rincon');
    });

    it('returns relationship and categories on both lists, null for a legacy grant (A7)', async () => {
      const base = {
        granterUserId: userId,
        targetProfileId: 'profile-1',
        accessLevel: 'VIEW_ONLY',
        status: 'ACCEPTED',
        inviteCode: 'CODE03',
        granteeUserId: null,
        expiresAt: new Date(Date.now() + 60_000),
        acceptedAt: new Date(),
        revokedAt: null,
        createdAt: new Date(),
      };
      const outgoingRows = [
        {
          grant: { ...base, id: 'out-new', relationship: 'sibling', categories: ['habits', 'care'] },
          targetProfileName: 'Lucas',
        },
        {
          grant: { ...base, id: 'out-legacy', relationship: null, categories: ['habits'] },
          targetProfileName: 'Lucas',
        },
      ];
      const incomingRows = [
        {
          grant: {
            ...base,
            id: 'in-1',
            granterUserId: 'other-user',
            relationship: 'caregiver',
            categories: ['physical_journal'],
          },
          targetProfileName: 'Helena',
        },
      ];

      mockDatabaseService.withRls.mockImplementation(async (_uid: string, callback: any) => {
        let callCount = 0;
        const tx = {
          select: vi.fn().mockImplementation(() => ({
            from: vi.fn().mockReturnValue({
              leftJoin: vi.fn().mockReturnValue({
                where: vi.fn().mockImplementation(() =>
                  Promise.resolve(++callCount === 1 ? outgoingRows : incomingRows),
                ),
              }),
            }),
          })),
        };
        return callback(tx);
      });

      const result = await service.listGrants(userId);

      expect(result.outgoing[0]).toMatchObject({ relationship: 'sibling', categories: ['habits', 'care'] });
      expect(result.outgoing[1]).toMatchObject({ relationship: null, categories: ['habits'] });
      expect(result.incoming[0]).toMatchObject({
        relationship: 'caregiver',
        categories: ['physical_journal'],
      });
    });

    it('names who accepted each outgoing grant, looking up only those grantees', async () => {
      const grantRow = (id: string, status: string, granteeUserId: string | null) => ({
        grant: {
          id,
          granterUserId: userId,
          targetProfileId: 'profile-1',
          accessLevel: 'VIEW_ONLY',
          status,
          inviteCode: `${id.slice(-4).toUpperCase()}234567`,
          granteeUserId,
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
          acceptedAt: granteeUserId ? new Date() : null,
          revokedAt: null,
          createdAt: new Date(),
        },
        targetProfileName: 'Lucas Rincon',
      });
      const outgoingRows = [
        grantRow('grant-out-a', 'ACCEPTED', 'user-maria'),
        grantRow('grant-out-b', 'PENDING', null),
      ];

      const dialect = new PgDialect();
      const executed: string[] = [];
      let usersFilter: SQL | undefined;
      let joinedQueries = 0;
      mockDatabaseService.withRls.mockImplementation(async (_uid: string, callback: any) => {
        const tx = {
          execute: vi.fn().mockImplementation((query: SQL) => {
            executed.push(dialect.sqlToQuery(query).sql);
            return Promise.resolve({ rows: [] });
          }),
          select: vi.fn().mockImplementation(() => ({
            from: vi.fn().mockImplementation(() => ({
              leftJoin: vi.fn().mockReturnValue({
                where: vi.fn().mockImplementation(() => {
                  joinedQueries++;
                  return Promise.resolve(joinedQueries === 1 ? outgoingRows : []);
                }),
              }),
              where: vi.fn().mockImplementation((condition: SQL) => {
                usersFilter = condition;
                return Promise.resolve([
                  { id: 'user-maria', name: 'Maria Souza', email: 'maria@example.com' },
                ]);
              }),
            })),
          })),
        };
        return callback(tx);
      });

      const result = await service.listGrants(userId);

      expect(result.outgoing[0]).toMatchObject({
        id: 'grant-out-a',
        granteeName: 'Maria Souza',
        granteeEmail: 'maria@example.com',
      });
      expect(result.outgoing[1]).toMatchObject({
        id: 'grant-out-b',
        granteeName: null,
        granteeEmail: null,
      });
      expect(dialect.sqlToQuery(usersFilter!).params).toEqual(['user-maria']);
      // The users RLS bypass is on only around that lookup.
      expect(executed).toEqual([
        "SELECT set_config('app.is_auth_service', 'true', true)",
        "SELECT set_config('app.is_auth_service', '', true)",
      ]);
    });
  });
});
