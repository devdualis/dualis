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

    authService = new AuthService(
      mockDb,
      mockJwtService as unknown as JwtService,
      mockEncryptionService,
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

    it('exports complete user data package with decrypted narratives and parsed answers', async () => {
      let callCount = 0;
      mockTxSelect.mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return {
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockReturnValue({
                limit: vi.fn().mockResolvedValue([mockUser]),
              }),
            }),
          };
        }
        if (callCount === 2) {
          return {
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([
                {
                  id: 'consent-1',
                  disclaimerVersion: '2026.1',
                  acceptedAt: new Date('2026-01-01T10:00:00Z'),
                  ipAddressHash: 'hash123',
                  userAgent: 'Flutter/iOS',
                },
              ]),
            }),
          };
        }
        if (callCount === 3) {
          return {
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockResolvedValue([
                {
                  id: 'log-1',
                  intensity: 3,
                  anatomicalSystem: 'respiratorio',
                  emotionalDimension: null,
                  disposition: 'consulta_eletiva',
                  encryptedNarrative: 'narrativa_cifrada',
                  stepAnswers: JSON.stringify({ question1: 'tosse leve' }),
                  recordedAt: new Date('2026-01-05T14:00:00Z'),
                },
              ]),
            }),
          };
        }
        return {
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockResolvedValue([
              {
                id: 'emerg-1',
                triggerCategory: 'dor_toracica_critica',
                severityLevel: 5,
                sourceVertical: 'fisico',
                actionTaken: 'chamou_samu',
                reportedAt: new Date('2026-01-08T09:30:00Z'),
              },
            ]),
          }),
        };
      });

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
      expect(mockEncryptionService.decrypt).toHaveBeenCalledWith('narrativa_cifrada');
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
