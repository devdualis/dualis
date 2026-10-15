import { describe, it, expect, beforeEach, vi } from 'vitest';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException, BadRequestException } from '@nestjs/common';
import { AuthService } from '../../src/modules/auth/auth.service';
import * as passwordUtil from '../../src/modules/auth/utils/password.util';

describe('AuthService - LGPD Data Sovereignty & Account Deletion (SEC-03)', () => {
  let authService: AuthService;
  let mockDb: any;
  let mockJwtService: any;
  let mockEncryptionService: any;
  let mockTxExecute: any;
  let mockTxSelect: any;
  let mockTxDelete: any;

  const mockUserId = '88888888-8888-8888-8888-888888888888';
  const mockUser = {
    id: mockUserId,
    name: 'Maria Santos',
    email: 'maria.santos@exemplo.com.br',
    passwordHash: '$argon2id$v=19$m=65536,t=3,p=4$fakehash',
    gender: 'feminino',
    dateOfBirth: '1992-07-20',
    createdAt: new Date('2026-01-01T10:00:00Z'),
    updatedAt: new Date('2026-01-01T10:00:00Z'),
  };

  beforeEach(() => {
    mockTxExecute = vi.fn().mockResolvedValue(undefined);
    mockTxSelect = vi.fn();
    mockTxDelete = vi.fn().mockReturnValue({
      where: vi.fn().mockResolvedValue(undefined),
    });

    mockDb = {
      transaction: vi.fn().mockImplementation(async (callback) => {
        const mockTx = {
          execute: mockTxExecute,
          select: mockTxSelect,
          delete: mockTxDelete,
        };
        return callback(mockTx);
      }),
    };

    mockJwtService = {
      sign: vi.fn().mockReturnValue('mock-token'),
    };

    mockEncryptionService = {
      encrypt: vi.fn().mockReturnValue('encrypted-val'),
      decrypt: vi.fn().mockImplementation((val) => `decrypted:${val}`),
    };

    const mockEmailService = {
      generateVerificationCode: vi.fn().mockReturnValue('123456'),
      hashCode: vi.fn().mockReturnValue('mock-hash-123456'),
      verifyCodeHash: vi.fn().mockReturnValue(true),
      sendVerificationEmail: vi.fn().mockResolvedValue(undefined),
      getLastSentCode: vi.fn().mockReturnValue('123456'),
    };

    authService = new AuthService(
      mockDb,
      mockJwtService as unknown as JwtService,
      mockEncryptionService,
      mockEmailService as any,
    );
  });

  describe('exportUserData', () => {
    it('throws UnauthorizedException when user does not exist', async () => {
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([]),
          }),
        }),
      });

      await expect(authService.exportUserData(mockUserId)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    const primaryProfileId = '11111111-1111-1111-1111-111111111111';
    const dependentProfileId = '22222222-2222-2222-2222-222222222222';

    const mockSelectSequence = (results: any[]) => {
      let callCount = 0;
      mockTxSelect.mockImplementation(() => {
        const rows = results[callCount++] ?? [];
        // First query (users) ends with .limit(); the rest resolve at .where().
        if (callCount === 1) {
          return {
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockReturnValue({ limit: vi.fn().mockResolvedValue(rows) }),
            }),
          };
        }
        return {
          from: vi.fn().mockReturnValue({ where: vi.fn().mockResolvedValue(rows) }),
        };
      });
    };

    const consent = {
      id: 'consent-1',
      disclaimerVersion: '2026.1',
      acceptedAt: new Date('2026-01-01T10:00:00Z'),
      ipAddressHash: 'hash123',
      userAgent: 'Flutter/iOS',
    };

    const ownedProfiles = [
      {
        id: dependentProfileId,
        accountOwnerId: mockUserId,
        profileType: 'dependent_minor',
        name: 'Lucas Santos',
        dateOfBirth: '2018-03-10',
        gender: 'masculino',
        createdAt: new Date('2026-02-01T10:00:00Z'),
      },
      {
        id: primaryProfileId,
        accountOwnerId: mockUserId,
        profileType: 'primary',
        name: 'Maria Santos',
        dateOfBirth: '1992-07-20',
        gender: 'feminino',
        createdAt: new Date('2026-01-01T10:00:00Z'),
      },
    ];

    const symptomRow = (id: string, profileId: string) => ({
      id,
      userId: mockUserId,
      profileId,
      intensity: 3,
      anatomicalSystem: 'respiratorio',
      emotionalDimension: null,
      disposition: 'consulta_eletiva',
      encryptedNarrative: 'narrativa_cifrada',
      stepAnswers: JSON.stringify({ question1: 'tosse leve' }),
      recordedAt: new Date('2026-01-05T14:00:00Z'),
    });

    it('exports complete user data package with decrypted narratives and parsed answers', async () => {
      mockSelectSequence([
        [mockUser],
        [consent],
        ownedProfiles,
        [symptomRow('log-1', primaryProfileId)],
        [
          {
            id: 'emerg-1',
            profileId: primaryProfileId,
            triggerCategory: 'dor_toracica_critica',
            severityLevel: 5,
            sourceVertical: 'fisico',
            actionTaken: 'chamou_samu',
            reportedAt: new Date('2026-01-08T09:30:00Z'),
          },
        ],
        [],
      ]);

      const result = await authService.exportUserData(mockUserId);

      expect(result.metadata.legalBasis).toContain('LGPD Art. 18, V');
      expect(result.profile.id).toBe(mockUserId);
      expect(result.profile.email).toBe('maria.santos@exemplo.com.br');
      expect(result.consents).toHaveLength(1);
      expect(result.consents[0].disclaimerVersion).toBe('2026.1');
      expect(result.symptomLogs).toHaveLength(1);
      expect(result.symptomLogs[0].decryptedNarrative).toBe('decrypted:narrativa_cifrada');
      expect(result.symptomLogs[0].stepAnswers).toEqual({ question1: 'tosse leve' });
      expect(result.emergencyEvents).toHaveLength(1);
      expect(result.emergencyEvents[0].triggerCategory).toBe('dor_toracica_critica');
      expect(result.waterIntakeLogs).toEqual([]);
      expect(mockEncryptionService.decrypt).toHaveBeenCalledWith('narrativa_cifrada');
    });

    it('groups owned dependents clinical data per profile, apart from the primary profile', async () => {
      mockSelectSequence([
        [mockUser],
        [consent],
        ownedProfiles,
        [symptomRow('log-own', primaryProfileId), symptomRow('log-lucas', dependentProfileId)],
        [],
        [
          {
            id: 'water-lucas',
            profileId: dependentProfileId,
            amountMl: 200,
            source: 'manual',
            recordedAt: new Date('2026-02-02T08:00:00Z'),
          },
        ],
      ]);

      const result = await authService.exportUserData(mockUserId);

      expect(result.symptomLogs.map((l) => l.id)).toEqual(['log-own']);
      expect(result.waterIntakeLogs).toEqual([]);
      expect(result.dependentProfiles).toHaveLength(1);

      const lucas = result.dependentProfiles[0];
      expect(lucas.profile).toEqual({
        id: dependentProfileId,
        name: 'Lucas Santos',
        profileType: 'dependent_minor',
        dateOfBirth: '2018-03-10',
        gender: 'masculino',
        createdAt: '2026-02-01T10:00:00.000Z',
      });
      expect(lucas.symptomLogs.map((l) => l.id)).toEqual(['log-lucas']);
      expect(lucas.emergencyEvents).toEqual([]);
      expect(lucas.waterIntakeLogs).toEqual([
        { id: 'water-lucas', amountMl: 200, source: 'manual', recordedAt: '2026-02-02T08:00:00.000Z' },
      ]);
    });

    it('skips clinical queries when the account owns no profile yet', async () => {
      mockSelectSequence([[mockUser], [], []]);

      const result = await authService.exportUserData(mockUserId);

      expect(mockTxSelect).toHaveBeenCalledTimes(3);
      expect(result.symptomLogs).toEqual([]);
      expect(result.emergencyEvents).toEqual([]);
      expect(result.waterIntakeLogs).toEqual([]);
      expect(result.dependentProfiles).toEqual([]);
    });
  });

  describe('deleteUserAccount', () => {
    it('throws UnauthorizedException when user does not exist', async () => {
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([]),
          }),
        }),
      });

      await expect(
        authService.deleteUserAccount(mockUserId, { password: 'Password123!' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws BadRequestException when password confirmation does not match', async () => {
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([mockUser]),
          }),
        }),
      });

      vi.spyOn(passwordUtil, 'verifyPassword').mockResolvedValue(false);

      await expect(
        authService.deleteUserAccount(mockUserId, { password: 'WrongPassword!' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('deletes user record under RLS when password is valid', async () => {
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([mockUser]),
          }),
        }),
      });

      vi.spyOn(passwordUtil, 'verifyPassword').mockResolvedValue(true);

      const res = await authService.deleteUserAccount(mockUserId, {
        password: 'ValidPassword123!',
      });

      expect(res.success).toBe(true);
      expect(res.message).toContain('LGPD Art. 18, VI');
      expect(mockTxDelete).toHaveBeenCalled();
    });
  });
});
