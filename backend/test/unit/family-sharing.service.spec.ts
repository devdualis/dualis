import { describe, it, expect, beforeEach, vi } from 'vitest';
import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import {
  FamilySharingService,
  generateInviteCode,
  INVITE_CODE_CHARS,
} from '../../src/modules/profiles/family-sharing.service';

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
    it('generates 6-character uppercase codes excluding ambiguous characters 0, O, 1, I', () => {
      const allowedCharsSet = new Set(INVITE_CODE_CHARS.split(''));

      // Run multiple iterations to verify stability
      for (let i = 0; i < 100; i++) {
        const code = generateInviteCode();
        expect(code).toHaveLength(6);
        expect(code).toMatch(/^[2-9A-HJ-NP-Z]{6}$/);

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

    it('creates an invite with 72h TTL and PENDING status when caller owns the profile', async () => {
      const mockProfile = {
        id: targetProfileId,
        accountOwnerId: userId,
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

      const result = await service.createInvite(userId, targetProfileId, 'VIEW_ONLY');

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
        service.createInvite(userId, targetProfileId, 'VIEW_ONLY'),
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
        service.createInvite(userId, targetProfileId, 'CO_MANAGE'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('retries on unique collision (23505) up to max attempts', async () => {
      const mockProfile = {
        id: targetProfileId,
        accountOwnerId: userId,
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

      const result = await service.createInvite(userId, targetProfileId, 'CO_MANAGE');
      expect(attempts).toBe(2);
      expect(result.id).toBe('grant-uuid-retry');
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
  });
});
