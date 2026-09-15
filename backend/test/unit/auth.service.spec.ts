import { describe, it, expect, vi, beforeEach } from 'vitest';
import { BadRequestException, ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from '../../src/modules/auth/auth.service';
import { RegisterDto } from '../../src/modules/auth/dto/register.dto';
import { LoginDto } from '../../src/modules/auth/dto/login.dto';
import { UpdateProfileDto } from '../../src/modules/auth/dto/update-profile.dto';
import { ChangePasswordDto } from '../../src/modules/auth/dto/change-password.dto';
import { hashPassword } from '../../src/modules/auth/utils/password.util';

describe('AuthService Unit Tests (AUTH-01 & LGPD Art. 11)', () => {
  let authService: AuthService;
  let mockDb: any;
  let mockJwtService: any;
  let mockTxExecute: ReturnType<typeof vi.fn>;
  let mockTxSelect: ReturnType<typeof vi.fn>;
  let mockTxInsert: ReturnType<typeof vi.fn>;
  let mockTxUpdate: ReturnType<typeof vi.fn>;
  let mockTxDelete: ReturnType<typeof vi.fn>;

  const validRegisterDto: RegisterDto = {
    name: 'Carlos Oliveira',
    email: 'carlos.oliveira@example.com',
    password: 'SecurePassword123!',
    gender: 'masculino',
    dateOfBirth: '1988-04-12',
    lgpdConsent: true,
    disclaimerVersion: '2026.1',
  };

  beforeEach(() => {
    mockTxExecute = vi.fn().mockResolvedValue(undefined);
    mockTxSelect = vi.fn();
    mockTxInsert = vi.fn();
    mockTxUpdate = vi.fn();
    mockTxDelete = vi.fn();

    mockDb = {
      transaction: vi.fn().mockImplementation(async (callback) => {
        const mockTx = {
          execute: mockTxExecute,
          select: mockTxSelect,
          insert: mockTxInsert,
          update: mockTxUpdate,
          delete: mockTxDelete,
        };
        return callback(mockTx);
      }),
    };

    mockJwtService = {
      sign: vi.fn().mockImplementation((payload, options) => {
        return `mock-jwt-token-for-${payload.sub}-${options?.expiresIn}`;
      }),
    };

    const mockEncryptionService = {
      encrypt: vi.fn().mockReturnValue('encrypted-value'),
      decrypt: vi.fn().mockImplementation((val) => `decrypted-${val}`),
    };

    authService = new AuthService(
      mockDb,
      mockJwtService as unknown as JwtService,
      mockEncryptionService as any,
    );
  });

  describe('Scenario 1: Happy Path Registration', () => {
    it('creates user with Argon2id hash, atomically logs LGPD consent, and returns auth tokens', async () => {
      // 1. Email check: no existing user
      const mockWhereLimit = vi.fn().mockReturnValue({
        limit: vi.fn().mockResolvedValue([]),
      });
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: mockWhereLimit,
        }),
      });

      // 2. Insert into users and userDisclaimerConsents
      const mockCreatedUser = {
        id: '123e4567-e89b-12d3-a456-426614174000',
        name: validRegisterDto.name,
        email: validRegisterDto.email.toLowerCase().trim(),
        gender: validRegisterDto.gender,
        dateOfBirth: validRegisterDto.dateOfBirth,
        picture: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const mockConsentValues = vi.fn().mockResolvedValue(undefined);
      const mockUserValues = vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([mockCreatedUser]),
      });

      mockTxInsert.mockImplementation((table: any) => {
        // First call is users, second is userDisclaimerConsents
        if (mockTxInsert.mock.calls.length === 1) {
          return { values: mockUserValues };
        }
        return { values: mockConsentValues };
      });

      const result = await authService.register(
        validRegisterDto,
        '192.168.1.100',
        'DualisCheckUp-Flutter/1.0.0',
      );

      // Verify returned tokens & sanitized user
      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user).toEqual(mockCreatedUser);
      expect((result.user as any).passwordHash).toBeUndefined();

      // Verify DB transaction calls
      expect(mockDb.transaction).toHaveBeenCalledTimes(2); // check uniqueness + creation
      expect(mockTxExecute).toHaveBeenCalledWith(
        expect.objectContaining({
          queryChunks: expect.any(Array),
        }),
      );
      expect(mockTxInsert).toHaveBeenCalledTimes(2);
      expect(mockUserValues).toHaveBeenCalledWith(
        expect.objectContaining({
          name: validRegisterDto.name,
          email: validRegisterDto.email.toLowerCase().trim(),
          gender: validRegisterDto.gender,
          dateOfBirth: validRegisterDto.dateOfBirth,
          passwordHash: expect.stringMatching(/^\$argon2id\$/),
        }),
      );
      expect(mockConsentValues).toHaveBeenCalledWith(
        expect.objectContaining({
          disclaimerVersion: '2026.1',
          userAgent: 'DualisCheckUp-Flutter/1.0.0',
          ipAddressHash: expect.any(String),
        }),
      );
    });
  });

  describe('Scenario 2: Unconsented Registration', () => {
    it('throws BadRequestException when lgpdConsent is false', async () => {
      const unconsentedDto: RegisterDto = {
        ...validRegisterDto,
        lgpdConsent: false,
      };

      await expect(authService.register(unconsentedDto)).rejects.toThrow(BadRequestException);
      await expect(authService.register(unconsentedDto)).rejects.toThrow(
        'Consentimento LGPD Art. 11 é obrigatório.',
      );

      expect(mockDb.transaction).not.toHaveBeenCalled();
    });
  });

  describe('Scenario 3: Duplicate Email Registration', () => {
    it('throws ConflictException when email is already registered', async () => {
      // Existing user found
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([{ id: 'existing-id', email: validRegisterDto.email }]),
          }),
        }),
      });

      await expect(authService.register(validRegisterDto)).rejects.toThrow(ConflictException);
      await expect(authService.register(validRegisterDto)).rejects.toThrow('E-mail já cadastrado.');

      // Should not proceed to insertion
      expect(mockTxInsert).not.toHaveBeenCalled();
    });
  });

  describe('Scenario 4: Login with Valid Credentials', () => {
    it('verifies password against Argon2id hash and returns auth tokens', async () => {
      const password = 'StrongPassword123!';
      const hashedPassword = await hashPassword(password);
      const userRecord = {
        id: '222e4567-e89b-12d3-a456-426614174001',
        name: 'Maria Santos',
        email: 'maria.santos@example.com',
        passwordHash: hashedPassword,
        gender: 'feminino',
        dateOfBirth: '1992-08-25',
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([userRecord]),
          }),
        }),
      });

      const loginDto: LoginDto = {
        email: 'maria.santos@example.com',
        password,
      };

      const result = await authService.login(loginDto);

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.id).toBe(userRecord.id);
      expect(result.user.email).toBe(userRecord.email);
      expect((result.user as any).passwordHash).toBeUndefined();
    });
  });

  describe('Scenario 5: Login with Invalid Password', () => {
    it('throws UnauthorizedException when password does not match hash', async () => {
      const hashedPassword = await hashPassword('CorrectPassword123!');
      const userRecord = {
        id: '333e4567-e89b-12d3-a456-426614174002',
        name: 'Joao Silva',
        email: 'joao.silva@example.com',
        passwordHash: hashedPassword,
        gender: 'masculino',
        dateOfBirth: '1985-02-10',
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([userRecord]),
          }),
        }),
      });

      const loginDto: LoginDto = {
        email: 'joao.silva@example.com',
        password: 'WrongPassword!',
      };

      await expect(authService.login(loginDto)).rejects.toThrow(UnauthorizedException);
      await expect(authService.login(loginDto)).rejects.toThrow('Credenciais inválidas.');
    });

    it('throws UnauthorizedException when user email does not exist', async () => {
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([]),
          }),
        }),
      });

      const loginDto: LoginDto = {
        email: 'nonexistent@example.com',
        password: 'AnyPassword123!',
      };

      await expect(authService.login(loginDto)).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('Scenario 6: Update Profile', () => {
    it('updates user profile fields under RLS context and returns sanitized user', async () => {
      const userId = '444e4567-e89b-12d3-a456-426614174003';
      const updateDto: UpdateProfileDto = {
        name: 'Carlos Oliveira Atualizado',
        dateOfBirth: '1988-04-15',
        picture: 'avatar_clinical_teal_01',
      };

      const updatedRecord = {
        id: userId,
        name: updateDto.name!,
        email: 'carlos.oliveira@example.com',
        gender: 'masculino',
        dateOfBirth: updateDto.dateOfBirth!,
        picture: updateDto.picture!,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      mockTxUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            returning: vi.fn().mockResolvedValue([updatedRecord]),
          }),
        }),
      });

      const result = await authService.updateProfile(userId, updateDto);

      expect(result.id).toBe(userId);
      expect(result.name).toBe(updateDto.name);
      expect(result.dateOfBirth).toBe(updateDto.dateOfBirth);
      expect(result.picture).toBe(updateDto.picture);
      expect(mockTxExecute).toHaveBeenCalled();
    });

    it('throws UnauthorizedException when user to update is not found', async () => {
      const userId = 'nonexistent-user-id';
      const updateDto: UpdateProfileDto = { name: 'Novo Nome' };

      mockTxUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            returning: vi.fn().mockResolvedValue([]),
          }),
        }),
      });

      await expect(authService.updateProfile(userId, updateDto)).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });

  describe('Scenario 7: Change Password', () => {
    it('verifies current password, updates password hash and returns success', async () => {
      const userId = '555e4567-e89b-12d3-a456-426614174004';
      const currentPassword = 'OldPassword123!';
      const newPassword = 'NewSecurePassword456!';
      const currentHash = await hashPassword(currentPassword);

      const userRecord = {
        id: userId,
        email: 'carlos@example.com',
        passwordHash: currentHash,
      };

      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([userRecord]),
          }),
        }),
      });

      const mockSet = vi.fn().mockReturnValue({
        where: vi.fn().mockResolvedValue(undefined),
      });
      mockTxUpdate.mockReturnValue({
        set: mockSet,
      });

      const result = await authService.changePassword(userId, {
        currentPassword,
        newPassword,
      });

      expect(result.success).toBe(true);
      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          passwordHash: expect.stringMatching(/^\$argon2id\$/),
        }),
      );
    });

    it('throws UnauthorizedException when current password does not match', async () => {
      const userId = '555e4567-e89b-12d3-a456-426614174004';
      const currentHash = await hashPassword('CorrectCurrentPassword123!');

      const userRecord = {
        id: userId,
        email: 'carlos@example.com',
        passwordHash: currentHash,
      };

      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([userRecord]),
          }),
        }),
      });

      await expect(
        authService.changePassword(userId, {
          currentPassword: 'WrongCurrentPassword!',
          newPassword: 'NewSecurePassword456!',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });
});
