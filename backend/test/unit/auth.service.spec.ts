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
      verifyAsync: vi.fn(),
    };

    const mockEncryptionService = {
      encrypt: vi.fn().mockReturnValue('encrypted-value'),
      decrypt: vi.fn().mockImplementation((val) => `decrypted-${val}`),
    };

    const mockEmailService = {
      generateVerificationCode: vi.fn().mockReturnValue('123456'),
      hashCode: vi.fn().mockReturnValue('mock-hash-123456'),
      verifyCodeHash: vi.fn().mockImplementation((code: string, hash: string) => code === '123456'),
      sendVerificationEmail: vi.fn().mockResolvedValue(undefined),
      getLastSentCode: vi.fn().mockReturnValue('123456'),
    };

    authService = new AuthService(
      mockDb,
      mockJwtService as unknown as JwtService,
      mockEncryptionService as any,
      mockEmailService as any,
    );
  });

  describe('Scenario 1: Happy Path Registration', () => {
    it('creates user, logs LGPD consent, generates OTP, dispatches verification email, and returns requiresVerification', async () => {
      // 1. Email check: no existing user
      const mockWhereLimit = vi.fn().mockReturnValue({
        limit: vi.fn().mockResolvedValue([]),
      });
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: mockWhereLimit,
        }),
      });

      // 2. Insert into users, userDisclaimerConsents, and emailVerifications
      const mockCreatedUser = {
        id: '123e4567-e89b-12d3-a456-426614174000',
        name: validRegisterDto.name,
        email: validRegisterDto.email.toLowerCase().trim(),
        gender: validRegisterDto.gender,
        dateOfBirth: validRegisterDto.dateOfBirth,
        picture: null,
        isEmailVerified: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const mockConsentValues = vi.fn().mockResolvedValue(undefined);
      const mockUserValues = vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([mockCreatedUser]),
      });
      const mockEmailVerifValues = vi.fn().mockResolvedValue(undefined);

      mockTxInsert.mockImplementation((table: any) => {
        if (mockTxInsert.mock.calls.length === 1) {
          return { values: mockUserValues };
        }
        if (mockTxInsert.mock.calls.length === 2) {
          return { values: mockConsentValues };
        }
        return { values: mockEmailVerifValues };
      });

      const result = await authService.register(
        validRegisterDto,
        '192.168.1.100',
        'DualisCheckUp-Flutter/1.0.0',
      );

      // Verify requiresVerification & user
      expect(result).toHaveProperty('requiresVerification', true);
      expect(result).toHaveProperty('email', validRegisterDto.email.toLowerCase().trim());
      expect(result).toHaveProperty('userId', mockCreatedUser.id);
      expect(result.user).toEqual(mockCreatedUser);
      expect((result.user as any).passwordHash).toBeUndefined();

      // Verify DB transaction calls
      expect(mockDb.transaction).toHaveBeenCalledTimes(3); // check uniqueness + creation + emailVerifications
      expect(mockTxInsert).toHaveBeenCalledTimes(3);
      expect(mockUserValues).toHaveBeenCalledWith(
        expect.objectContaining({
          name: validRegisterDto.name,
          email: validRegisterDto.email.toLowerCase().trim(),
          gender: validRegisterDto.gender,
          dateOfBirth: validRegisterDto.dateOfBirth,
          passwordHash: expect.stringMatching(/^\$argon2id\$/),
          isEmailVerified: false,
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

  describe('Scenario 8: Login with Unverified Email', () => {
    it('throws UnauthorizedException when isEmailVerified is false', async () => {
      const password = 'StrongPassword123!';
      const hashedPassword = await hashPassword(password);
      const userRecord = {
        id: '222e4567-e89b-12d3-a456-426614174001',
        name: 'Maria Santos',
        email: 'maria.unverified@example.com',
        passwordHash: hashedPassword,
        gender: 'feminino',
        dateOfBirth: '1992-08-25',
        isEmailVerified: false,
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

      await expect(
        authService.login({
          email: 'maria.unverified@example.com',
          password,
        }),
      ).rejects.toThrow('E-mail não verificado. Por favor, confirme seu e-mail antes de entrar.');
    });
  });

  describe('Scenario 9: Email Verification Flow', () => {
    it('verifies user email with valid 6-digit code and returns auth tokens', async () => {
      const email = 'patient@example.com';
      const userId = 'user-uuid-123';
      const verificationRecord = {
        id: 'verif-uuid-1',
        userId,
        email,
        codeHash: 'mock-hash-123456',
        attempts: 0,
        expiresAt: new Date(Date.now() + 15 * 60 * 1000),
        createdAt: new Date(),
      };

      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            orderBy: vi.fn().mockReturnValue({
              limit: vi.fn().mockResolvedValue([verificationRecord]),
            }),
          }),
        }),
      });

      const updatedUser = {
        id: userId,
        name: 'Patient Test',
        email,
        gender: 'masculino',
        dateOfBirth: '1990-01-01',
        picture: null,
        isEmailVerified: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      mockTxUpdate.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            returning: vi.fn().mockResolvedValue([updatedUser]),
          }),
        }),
      });

      mockTxDelete.mockReturnValue({
        where: vi.fn().mockResolvedValue(undefined),
      });

      const result = await authService.verifyEmail({ email, code: '123456' });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.isEmailVerified).toBe(true);
      expect(result.user.id).toBe(userId);
    });

    it('rejects verification when code is expired', async () => {
      const email = 'patient@example.com';
      const verificationRecord = {
        id: 'verif-uuid-1',
        userId: 'user-uuid-123',
        email,
        codeHash: 'mock-hash-123456',
        attempts: 0,
        expiresAt: new Date(Date.now() - 1000),
        createdAt: new Date(),
      };

      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            orderBy: vi.fn().mockReturnValue({
              limit: vi.fn().mockResolvedValue([verificationRecord]),
            }),
          }),
        }),
      });

      await expect(
        authService.verifyEmail({ email, code: '123456' }),
      ).rejects.toThrow('Código de verificação expirado. Solicite um novo código.');
    });

    it('rejects verification when code is incorrect and increments attempts', async () => {
      const email = 'patient@example.com';
      const verificationRecord = {
        id: 'verif-uuid-1',
        userId: 'user-uuid-123',
        email,
        codeHash: 'mock-hash-123456',
        attempts: 0,
        expiresAt: new Date(Date.now() + 15 * 60 * 1000),
        createdAt: new Date(),
      };

      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            orderBy: vi.fn().mockReturnValue({
              limit: vi.fn().mockResolvedValue([verificationRecord]),
            }),
          }),
        }),
      });

      const mockSet = vi.fn().mockReturnValue({
        where: vi.fn().mockResolvedValue(undefined),
      });
      mockTxUpdate.mockReturnValue({
        set: mockSet,
      });

      await expect(
        authService.verifyEmail({ email, code: '999999' }),
      ).rejects.toThrow('Código de verificação incorreto.');

      expect(mockSet).toHaveBeenCalledWith({ attempts: 1 });
    });
  });

  describe('Scenario 10: Token Refresh', () => {
    const userRecord = {
      id: '555e4567-e89b-12d3-a456-426614174004',
      name: 'Ana Souza',
      email: 'ana.souza@example.com',
      gender: 'feminino',
      dateOfBirth: '1990-01-01',
      picture: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    it('issues a new token pair when the refresh token is valid', async () => {
      mockJwtService.verifyAsync.mockResolvedValue({
        sub: userRecord.id,
        email: userRecord.email,
        type: 'refresh',
      });

      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([userRecord]),
          }),
        }),
      });

      const result = await authService.refreshTokens('valid-refresh-token');

      expect(mockJwtService.verifyAsync).toHaveBeenCalledWith('valid-refresh-token');
      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.id).toBe(userRecord.id);
      expect(mockJwtService.sign).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'access' }),
        { expiresIn: '15m' },
      );
      expect(mockJwtService.sign).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'refresh' }),
        { expiresIn: '7d' },
      );
    });

    it('throws UnauthorizedException when the token is expired or malformed', async () => {
      mockJwtService.verifyAsync.mockRejectedValue(new Error('jwt expired'));

      await expect(authService.refreshTokens('expired-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('throws UnauthorizedException when an access token is presented instead of a refresh token', async () => {
      mockJwtService.verifyAsync.mockResolvedValue({
        sub: userRecord.id,
        email: userRecord.email,
        type: 'access',
      });

      await expect(authService.refreshTokens('access-token-not-refresh')).rejects.toThrow(
        'Token de atualização inválido.',
      );
    });

    it('throws UnauthorizedException when the user no longer exists', async () => {
      mockJwtService.verifyAsync.mockResolvedValue({
        sub: 'deleted-user-id',
        email: 'ghost@example.com',
        type: 'refresh',
      });

      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([]),
          }),
        }),
      });

      await expect(authService.refreshTokens('valid-token-deleted-user')).rejects.toThrow(
        'Usuário não encontrado.',
      );
    });
  });
});
