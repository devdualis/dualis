import { describe, it, expect, vi, beforeEach } from 'vitest';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from '../../src/modules/auth/auth.service';
import { RegisterDto } from '../../src/modules/auth/dto/register.dto';
import { LoginDto } from '../../src/modules/auth/dto/login.dto';
import { UpdateProfileDto } from '../../src/modules/auth/dto/update-profile.dto';
import { ChangePasswordDto } from '../../src/modules/auth/dto/change-password.dto';
import { hashPassword } from '../../src/modules/auth/utils/password.util';

/**
 * Drizzle-style query mock: every chained call returns the same object and awaiting it yields
 * `result` (or rejects with it, when it is an Error). `calls` records the chain, e.g.
 * [['set', [{...}]], ['where', [...]]].
 */
function query(result: unknown) {
  const calls: Array<[string, unknown[]]> = [];
  const builder: any = new Proxy(
    {},
    {
      get(_target, prop) {
        if (prop === 'then') {
          const settled = result instanceof Error ? Promise.reject(result) : Promise.resolve(result);
          return (resolve: any, reject: any) => settled.then(resolve, reject);
        }
        if (prop === 'calls') return calls;
        return (...args: unknown[]) => {
          calls.push([String(prop), args]);
          return builder;
        };
      },
    },
  );
  return builder;
}

describe('AuthService Unit Tests (AUTH-01 & LGPD Art. 11)', () => {
  let authService: AuthService;
  let mockDb: any;
  let mockJwtService: any;
  let mockEmailService: any;
  let mockEncryptionService: any;
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

  const codeRecord = (overrides: Record<string, unknown> = {}) => ({
    id: 'code-uuid-1',
    userId: 'user-uuid-123',
    email: 'patient@example.com',
    codeHash: 'mock-hash-123456',
    attempts: 0,
    expiresAt: new Date(Date.now() + 15 * 60 * 1000),
    createdAt: new Date(),
    ...overrides,
  });

  /** Payloads passed to jwtService.sign, by token type. */
  const signedPayload = (type: 'access' | 'refresh') =>
    mockJwtService.sign.mock.calls.map(([payload]: any[]) => payload).filter((p: any) => p.type === type).at(-1);

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

    mockEncryptionService = {
      encrypt: vi.fn().mockReturnValue('encrypted-value'),
      decrypt: vi.fn().mockImplementation((val) => `decrypted-${val}`),
      hashIp: vi.fn().mockImplementation((ip: string) => `hmac-of-${ip}`),
    };

    mockEmailService = {
      generateVerificationCode: vi.fn().mockReturnValue('123456'),
      hashCode: vi.fn().mockReturnValue('mock-hash-123456'),
      verifyCodeHash: vi.fn().mockImplementation((code: string, hash: string) => code === '123456'),
      sendVerificationEmail: vi.fn().mockResolvedValue(undefined),
      sendPasswordResetEmail: vi.fn().mockResolvedValue(undefined),
      sendAccountExistsEmail: vi.fn().mockResolvedValue(undefined),
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
    it('creates user, logs LGPD consent with a keyed IP hash, stores a code and emails it', async () => {
      const createdUser = {
        id: '123e4567-e89b-12d3-a456-426614174000',
        name: validRegisterDto.name,
        email: validRegisterDto.email,
        isEmailVerified: false,
      };
      const userInsert = query([createdUser]);
      const consentInsert = query(undefined);
      const codeInsert = query(undefined);
      mockTxSelect
        .mockReturnValueOnce(query([])) // email lookup: no account
        .mockReturnValueOnce(query([])); // codes sent in the last day
      mockTxInsert
        .mockReturnValueOnce(userInsert)
        .mockReturnValueOnce(consentInsert)
        .mockReturnValueOnce(codeInsert);
      mockTxDelete.mockReturnValue(query(undefined));

      const result = await authService.register(
        validRegisterDto,
        '192.168.1.100',
        'DualisCheckUp-Flutter/1.0.0',
      );

      expect(result).toEqual({
        requiresVerification: true,
        email: validRegisterDto.email,
        message: 'Enviamos as instruções para o seu e-mail.',
      });
      expect(userInsert.calls[0]).toEqual([
        'values',
        [
          expect.objectContaining({
            name: validRegisterDto.name,
            email: validRegisterDto.email,
            gender: validRegisterDto.gender,
            dateOfBirth: validRegisterDto.dateOfBirth,
            passwordHash: expect.stringMatching(/^\$argon2id\$/),
            isEmailVerified: false,
          }),
        ],
      ]);
      expect(consentInsert.calls[0]).toEqual([
        'values',
        [
          expect.objectContaining({
            disclaimerVersion: '2026.1',
            userAgent: 'DualisCheckUp-Flutter/1.0.0',
            ipAddressHash: 'hmac-of-192.168.1.100',
          }),
        ],
      ]);
      expect(mockEncryptionService.hashIp).toHaveBeenCalledWith('192.168.1.100');
      expect(codeInsert.calls[0][1][0]).toMatchObject({ userId: createdUser.id, codeHash: 'mock-hash-123456', attempts: 0 });
      expect(mockEmailService.sendVerificationEmail).toHaveBeenCalledWith(
        validRegisterDto.email,
        '123456',
        validRegisterDto.name,
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

  describe('Scenario 3: Registration with an Address That Has an Account', () => {
    it('answers exactly like a new sign-up and emails the owner instead of creating anything', async () => {
      mockTxSelect.mockReturnValue(query([{ id: 'existing-id', name: 'Carlos Oliveira', email: validRegisterDto.email }]));

      const result = await authService.register(validRegisterDto);

      expect(result).toEqual({
        requiresVerification: true,
        email: validRegisterDto.email,
        message: 'Enviamos as instruções para o seu e-mail.',
      });
      expect(mockTxInsert).not.toHaveBeenCalled();
      expect(mockEmailService.sendVerificationEmail).not.toHaveBeenCalled();
      expect(mockEmailService.sendAccountExistsEmail).toHaveBeenCalledWith(validRegisterDto.email, 'Carlos Oliveira');
    });

    it('answers the same when a parallel sign-up for the address wins the insert', async () => {
      mockTxSelect.mockReturnValue(query([]));
      mockTxInsert.mockReturnValue(query(Object.assign(new Error('duplicate key'), { code: '23505' })));

      const result = await authService.register(validRegisterDto);

      expect(result.requiresVerification).toBe(true);
      expect(mockEmailService.sendVerificationEmail).not.toHaveBeenCalled();
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

  describe('Scenario 5b: Login Timing for Unknown Emails', () => {
    it('checks the password against a dummy hash before answering, like for a real account', async () => {
      mockTxSelect.mockReturnValue(query([]));

      await expect(
        authService.login({ email: 'nonexistent@example.com', password: 'AnyPassword123!' }),
      ).rejects.toThrow('Credenciais inválidas.');

      // The Argon2 work ran: the dummy hash exists only once an unknown email was checked.
      await expect((authService as any).dummyPasswordHash).resolves.toMatch(/^\$argon2id\$/);
    });
  });

  describe('Scenario 6: Update Profile', () => {
    const userId = '444e4567-e89b-12d3-a456-426614174003';
    const updatedRecord = (picture: string | null) => ({
      id: userId,
      name: 'Carlos Oliveira Atualizado',
      email: 'carlos.oliveira@example.com',
      gender: 'masculino',
      dateOfBirth: '1988-04-15',
      picture,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    it('updates user profile fields under RLS context and returns sanitized user', async () => {
      const updateDto: UpdateProfileDto = {
        name: 'Carlos Oliveira Atualizado',
        dateOfBirth: '1988-04-15',
        picture: 'avatar_clinical_teal_01',
      };
      mockTxSelect.mockReturnValue(query([{ picture: null }]));
      const update = query([updatedRecord(updateDto.picture!)]);
      mockTxUpdate.mockReturnValue(update);

      const result = await authService.updateProfile(userId, updateDto);

      expect(result.id).toBe(userId);
      expect(result.name).toBe(updateDto.name);
      expect(result.dateOfBirth).toBe(updateDto.dateOfBirth);
      expect(result.picture).toBe(updateDto.picture);
      expect(update.calls[0][1][0]).toMatchObject({ picture: 'avatar_clinical_teal_01' });
      expect(mockTxExecute).toHaveBeenCalled();
    });

    it('rejects a new picture that is not a preset or a PNG, JPEG or WebP image', async () => {
      mockTxSelect.mockReturnValue(query([{ picture: null }]));

      await expect(
        authService.updateProfile(userId, { picture: 'https://tracker.example/pixel.png' }),
      ).rejects.toThrow(BadRequestException);
      expect(mockTxUpdate).not.toHaveBeenCalled();
    });

    it('keeps an unchanged picture as it is, even one from an older app version', async () => {
      const legacy = 'https://old-storage.example/avatars/user.png';
      mockTxSelect.mockReturnValue(query([{ picture: legacy }]));
      const update = query([updatedRecord(legacy)]);
      mockTxUpdate.mockReturnValue(update);

      const result = await authService.updateProfile(userId, { name: 'Carlos Oliveira Atualizado', picture: legacy });

      expect(result.picture).toBe(legacy);
      expect(update.calls[0][1][0]).not.toHaveProperty('picture');
    });

    it('throws UnauthorizedException when user to update is not found', async () => {
      mockTxUpdate.mockReturnValue(query([]));

      await expect(authService.updateProfile('nonexistent-user-id', { name: 'Novo Nome' })).rejects.toThrow(
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

  describe('Scenario 7b: Sessions End When the Password Changes', () => {
    const userId = '555e4567-e89b-12d3-a456-426614174004';

    it('gives the device that changed the password new tokens with a new session version', async () => {
      const currentHash = await hashPassword('OldPassword123!');
      const user = { id: userId, name: 'Carlos', email: 'carlos@example.com', passwordHash: currentHash };
      mockTxSelect.mockReturnValue(query([user]));
      mockTxUpdate.mockReturnValue(query(undefined));
      const before = await authService.validateUserById(userId, undefined);
      expect(before).toBeNull(); // tokens without a session version are refused

      mockJwtService.verifyAsync.mockResolvedValue(undefined);
      await authService.login({ email: user.email, password: 'OldPassword123!' }).catch(() => undefined);
      const oldVersion = signedPayload('access')?.sv;

      const result = await authService.changePassword(userId, {
        currentPassword: 'OldPassword123!',
        newPassword: 'NewSecurePassword456!',
      });
      const newVersion = signedPayload('access').sv;

      expect(result).toMatchObject({ success: true, accessToken: expect.any(String), refreshToken: expect.any(String) });
      expect(newVersion).toEqual(expect.any(String));
      expect(newVersion).not.toBe(oldVersion);
    });

    it('accepts an access token only while its session version matches the stored password', async () => {
      const passwordHash = await hashPassword('StrongPassword123!');
      const user = {
        id: userId,
        name: 'Maria',
        email: 'maria@example.com',
        passwordHash,
        isEmailVerified: true,
      };
      mockTxSelect.mockReturnValue(query([user]));
      await authService.login({ email: user.email, password: 'StrongPassword123!' });
      const sv = signedPayload('access').sv;

      mockTxSelect.mockReturnValue(query([{ id: userId, email: user.email, passwordHash }]));
      await expect(authService.validateUserById(userId, sv)).resolves.toEqual({ id: userId, email: user.email });

      const changedHash = await hashPassword('StrongPassword123!'); // same password, new salt
      mockTxSelect.mockReturnValue(query([{ id: userId, email: user.email, passwordHash: changedHash }]));
      await expect(authService.validateUserById(userId, sv)).resolves.toBeNull();
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

      const attempt = authService.login({
        email: 'maria.unverified@example.com',
        password,
      });
      await expect(attempt).rejects.toThrow('E-mail não verificado. Por favor, confirme seu e-mail antes de entrar.');
      await expect(attempt).rejects.toMatchObject({
        response: expect.objectContaining({ code: 'EMAIL_NOT_VERIFIED' }),
      });
    });
  });

  describe('Scenario 9: Email Verification Flow', () => {
    it('verifies user email with valid 6-digit code and returns auth tokens', async () => {
      const record = codeRecord();
      const updatedUser = {
        id: record.userId,
        name: 'Patient Test',
        email: record.email,
        passwordHash: '$argon2id$stored',
        gender: 'masculino',
        dateOfBirth: '1990-01-01',
        picture: null,
        isEmailVerified: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      mockTxSelect.mockReturnValue(query([record]));
      mockTxUpdate
        .mockReturnValueOnce(query([{ id: record.id }])) // attempt claimed
        .mockReturnValueOnce(query([updatedUser]));
      mockTxDelete.mockReturnValue(query([{ id: record.id }])); // code consumed

      const result = await authService.verifyEmail({ email: record.email, code: '123456' });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.isEmailVerified).toBe(true);
      expect(result.user.id).toBe(record.userId);
      expect(signedPayload('access').sv).toEqual(expect.any(String));
      // The users policy only accepts an update to the row of app.current_user_id.
      expect(JSON.stringify(mockTxExecute.mock.calls)).toContain(record.userId);
    });

    it('rejects an expired code with the generic message', async () => {
      mockTxSelect.mockReturnValue(query([codeRecord({ expiresAt: new Date(Date.now() - 1000) })]));

      await expect(
        authService.verifyEmail({ email: 'patient@example.com', code: '123456' }),
      ).rejects.toThrow('Código inválido ou expirado. Solicite um novo código.');
      expect(mockTxUpdate).not.toHaveBeenCalled();
    });

    it('spends an attempt before comparing, then rejects a wrong code', async () => {
      mockTxSelect.mockReturnValue(query([codeRecord()]));
      const claim = query([{ id: 'code-uuid-1' }]);
      mockTxUpdate.mockReturnValue(claim);

      await expect(
        authService.verifyEmail({ email: 'patient@example.com', code: '999999' }),
      ).rejects.toThrow('Código inválido ou expirado. Solicite um novo código.');
      expect(mockTxUpdate).toHaveBeenCalledTimes(1);
      expect(claim.calls.map(([name]: [string]) => name)).toEqual(['set', 'where', 'returning']);
    });

    it('rejects even the right code once its attempts are used up', async () => {
      mockTxSelect.mockReturnValue(query([codeRecord({ attempts: 5 })]));
      mockTxUpdate.mockReturnValue(query([])); // attempts < 5 no longer matches

      await expect(
        authService.verifyEmail({ email: 'patient@example.com', code: '123456' }),
      ).rejects.toThrow('Código inválido ou expirado. Solicite um novo código.');
    });

    it('rejects a code that a parallel request already used', async () => {
      mockTxSelect.mockReturnValue(query([codeRecord()]));
      mockTxUpdate.mockReturnValue(query([{ id: 'code-uuid-1' }]));
      mockTxDelete.mockReturnValue(query([])); // nothing left to consume

      await expect(
        authService.verifyEmail({ email: 'patient@example.com', code: '123456' }),
      ).rejects.toThrow('Código inválido ou expirado. Solicite um novo código.');
    });

    it('rejects an email without any code with the same message', async () => {
      mockTxSelect.mockReturnValue(query([]));

      await expect(
        authService.verifyEmail({ email: 'ghost@example.com', code: '123456' }),
      ).rejects.toThrow('Código inválido ou expirado. Solicite um novo código.');
    });
  });

  describe('Scenario 9a: Resend Verification', () => {
    it('answers the same for an already confirmed account and sends nothing', async () => {
      mockTxSelect.mockReturnValue(query([{ id: 'user-uuid-123', name: 'Ana', isEmailVerified: true }]));

      const result = await authService.resendVerification({ email: 'ana@example.com' });

      expect(result).toEqual({
        success: true,
        message: 'Se o e-mail estiver cadastrado e ainda não confirmado, enviamos um novo código.',
      });
      expect(mockEmailService.sendVerificationEmail).not.toHaveBeenCalled();
    });

    it('stores and sends a new code for an unconfirmed account', async () => {
      mockTxSelect
        .mockReturnValueOnce(query([{ id: 'user-uuid-123', name: 'Ana', isEmailVerified: false }]))
        .mockReturnValueOnce(query([{ createdAt: new Date(Date.now() - 5 * 60 * 1000) }]));
      mockTxDelete.mockReturnValue(query(undefined));
      mockTxInsert.mockReturnValue(query(undefined));

      await authService.resendVerification({ email: 'ana@example.com' });

      expect(mockTxInsert).toHaveBeenCalledTimes(1);
      expect(mockEmailService.sendVerificationEmail).toHaveBeenCalledWith('ana@example.com', '123456', 'Ana');
    });
  });

  describe('Scenario 9b: Forgot Password Flow', () => {
    const user = { id: 'user-uuid-123', name: 'Patient Test', email: 'patient@example.com' };

    it('returns generic success and sends reset email when user exists', async () => {
      mockTxSelect.mockReturnValueOnce(query([user])).mockReturnValueOnce(query([]));
      mockTxDelete.mockReturnValue(query(undefined));
      mockTxInsert.mockReturnValue(query(undefined));

      const result = await authService.forgotPassword({ email: user.email });

      expect(result.success).toBe(true);
      expect(result.message).toContain('Se o e-mail estiver cadastrado');
      expect(mockEmailService.sendPasswordResetEmail).toHaveBeenCalledWith(user.email, '123456', user.name);
    });

    it('answers the same, without a new code, when the last one is under a minute old', async () => {
      mockTxSelect.mockReturnValueOnce(query([user])).mockReturnValueOnce(query([{ createdAt: new Date() }]));
      mockTxDelete.mockReturnValue(query(undefined));

      const result = await authService.forgotPassword({ email: user.email });

      expect(result.message).toContain('Se o e-mail estiver cadastrado');
      expect(mockTxInsert).not.toHaveBeenCalled();
      expect(mockEmailService.sendPasswordResetEmail).not.toHaveBeenCalled();
    });

    it('answers the same, without a new code, once the account got 5 codes in a day', async () => {
      const hourAgo = () => ({ createdAt: new Date(Date.now() - 60 * 60 * 1000) });
      mockTxSelect
        .mockReturnValueOnce(query([user]))
        .mockReturnValueOnce(query([hourAgo(), hourAgo(), hourAgo(), hourAgo(), hourAgo()]));
      mockTxDelete.mockReturnValue(query(undefined));

      await authService.forgotPassword({ email: user.email });

      expect(mockTxInsert).not.toHaveBeenCalled();
      expect(mockEmailService.sendPasswordResetEmail).not.toHaveBeenCalled();
    });

    it('returns generic success without sending email when user does not exist', async () => {
      mockTxSelect.mockReturnValue(query([]));

      const result = await authService.forgotPassword({ email: 'ghost@example.com' });

      expect(result.success).toBe(true);
      expect(result.message).toContain('Se o e-mail estiver cadastrado');
      expect(mockEmailService.sendPasswordResetEmail).not.toHaveBeenCalled();
    });
  });

  describe('Scenario 9c: Reset Password Flow', () => {
    it('resets password with a valid code', async () => {
      const record = codeRecord();
      mockTxSelect.mockReturnValue(query([record]));
      const passwordUpdate = query(undefined);
      mockTxUpdate.mockReturnValueOnce(query([{ id: record.id }])).mockReturnValueOnce(passwordUpdate);
      mockTxDelete.mockReturnValue(query([{ id: record.id }]));

      const result = await authService.resetPassword({
        email: record.email,
        code: '123456',
        newPassword: 'NewSecurePass123!',
      });

      expect(result.success).toBe(true);
      expect(passwordUpdate.calls[0][1][0]).toMatchObject({ passwordHash: expect.stringMatching(/^\$argon2id\$/) });
    });

    it('rejects reset when code is expired', async () => {
      mockTxSelect.mockReturnValue(query([codeRecord({ expiresAt: new Date(Date.now() - 1000) })]));

      await expect(
        authService.resetPassword({ email: 'patient@example.com', code: '123456', newPassword: 'NewSecurePass123!' }),
      ).rejects.toThrow('Código inválido ou expirado. Solicite um novo código.');
    });

    it('rejects reset when code is incorrect, after spending an attempt', async () => {
      mockTxSelect.mockReturnValue(query([codeRecord()]));
      mockTxUpdate.mockReturnValue(query([{ id: 'code-uuid-1' }]));

      await expect(
        authService.resetPassword({ email: 'patient@example.com', code: '999999', newPassword: 'NewSecurePass123!' }),
      ).rejects.toThrow('Código inválido ou expirado. Solicite um novo código.');
      expect(mockTxUpdate).toHaveBeenCalledTimes(1);
    });
  });

  describe('Scenario 10: Token Refresh', () => {
    const userId = '555e4567-e89b-12d3-a456-426614174004';
    let passwordHash: string;
    const userRecord = () => ({
      id: userId,
      name: 'Ana Souza',
      email: 'ana.souza@example.com',
      passwordHash,
      gender: 'feminino',
      dateOfBirth: '1990-01-01',
      picture: null,
      isEmailVerified: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    beforeEach(async () => {
      passwordHash = await hashPassword('StrongPassword123!');
      mockTxSelect.mockReturnValue(query([userRecord()]));
      await authService.login({ email: 'ana.souza@example.com', password: 'StrongPassword123!' });
      mockJwtService.verifyAsync.mockResolvedValue(signedPayload('refresh'));
      mockJwtService.sign.mockClear();
    });

    it('issues a new token pair when the refresh token is valid', async () => {
      const result = await authService.refreshTokens('valid-refresh-token');

      expect(mockJwtService.verifyAsync).toHaveBeenCalledWith('valid-refresh-token');
      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.id).toBe(userId);
      expect((result.user as any).passwordHash).toBeUndefined();
      expect(mockJwtService.sign).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'access', sv: expect.any(String) }),
        { expiresIn: '15m' },
      );
      expect(mockJwtService.sign).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'refresh', sv: expect.any(String) }),
        { expiresIn: '7d' },
      );
    });

    it('refuses a refresh token issued before the password changed', async () => {
      passwordHash = await hashPassword('AnotherPassword456!');
      mockTxSelect.mockReturnValue(query([userRecord()]));

      await expect(authService.refreshTokens('stolen-refresh-token')).rejects.toThrow(
        'Sessão encerrada. Entre novamente.',
      );
      expect(mockJwtService.sign).not.toHaveBeenCalled();
    });

    it('throws UnauthorizedException when the token is expired or malformed', async () => {
      mockJwtService.verifyAsync.mockRejectedValue(new Error('jwt expired'));

      await expect(authService.refreshTokens('expired-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('throws UnauthorizedException when an access token is presented instead of a refresh token', async () => {
      mockJwtService.verifyAsync.mockResolvedValue({ ...signedPayload('refresh'), type: 'access' });

      await expect(authService.refreshTokens('access-token-not-refresh')).rejects.toThrow(
        'Token de atualização inválido.',
      );
    });

    it('throws UnauthorizedException when the user no longer exists', async () => {
      mockTxSelect.mockReturnValue(query([]));

      await expect(authService.refreshTokens('valid-token-deleted-user')).rejects.toThrow(
        'Sessão encerrada. Entre novamente.',
      );
    });
  });
});
