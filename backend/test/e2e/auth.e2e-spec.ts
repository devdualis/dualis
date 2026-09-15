import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import {
  VersioningType,
  ValidationPipe,
  BadRequestException,
  ConflictException,
  UnauthorizedException,
  Injectable,
  Inject,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as crypto from 'crypto';
import { AppModule } from '../../src/app.module';
import { AuthService } from '../../src/modules/auth/auth.service';
import { RegisterDto } from '../../src/modules/auth/dto/register.dto';
import { LoginDto } from '../../src/modules/auth/dto/login.dto';
import { hashPassword, verifyPassword } from '../../src/modules/auth/utils/password.util';
import { SanitizedUser } from '../../src/modules/auth/dto/auth-response.dto';

@Injectable()
class MockAuthService {
  private users: Array<{
    id: string;
    name: string;
    email: string;
    passwordHash: string;
    gender: string;
    dateOfBirth: string | null;
    picture: string | null;
    createdAt: Date;
    updatedAt: Date;
  }> = [];

  constructor(@Inject(JwtService) private readonly jwtService: JwtService) {}

  async register(
    dto: RegisterDto,
    _clientIp: string = '127.0.0.1',
    _userAgent: string = 'Unknown',
  ) {
    if (dto.lgpdConsent !== true) {
      throw new BadRequestException('Consentimento LGPD Art. 11 é obrigatório.');
    }

    const email = dto.email.toLowerCase().trim();
    if (this.users.some((u) => u.email === email)) {
      throw new ConflictException('E-mail já cadastrado.');
    }

    const newUserId = crypto.randomUUID();
    const passwordHash = await hashPassword(dto.password);
    const user = {
      id: newUserId,
      name: dto.name,
      email,
      passwordHash,
      gender: dto.gender,
      dateOfBirth: dto.dateOfBirth,
      picture: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    this.users.push(user);

    const sanitizedUser: SanitizedUser = {
      id: user.id,
      name: user.name,
      email: user.email,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      picture: user.picture,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };

    const tokens = this.generateTokens(user.id, user.email);
    return {
      ...tokens,
      user: sanitizedUser,
    };
  }

  async login(dto: LoginDto) {
    const email = dto.email.toLowerCase().trim();
    const user = this.users.find((u) => u.email === email);

    if (!user) {
      throw new UnauthorizedException('Credenciais inválidas.');
    }

    const isMatch = await verifyPassword(user.passwordHash, dto.password);
    if (!isMatch) {
      throw new UnauthorizedException('Credenciais inválidas.');
    }

    const sanitizedUser: SanitizedUser = {
      id: user.id,
      name: user.name,
      email: user.email,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      picture: user.picture,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };

    const tokens = this.generateTokens(user.id, user.email);
    return {
      ...tokens,
      user: sanitizedUser,
    };
  }

  async updateProfile(userId: string, dto: any): Promise<SanitizedUser> {
    const user = this.users.find((u) => u.id === userId);
    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado.');
    }
    if (dto.name !== undefined) user.name = dto.name;
    if (dto.dateOfBirth !== undefined) user.dateOfBirth = dto.dateOfBirth;
    if (dto.picture !== undefined) user.picture = dto.picture;
    if (dto.gender !== undefined) user.gender = dto.gender;
    user.updatedAt = new Date();

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      picture: user.picture,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  async changePassword(userId: string, dto: any): Promise<{ success: boolean; message: string }> {
    const user = this.users.find((u) => u.id === userId);
    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado.');
    }
    const isMatch = await verifyPassword(user.passwordHash, dto.currentPassword);
    if (!isMatch) {
      throw new UnauthorizedException('A senha atual fornecida está incorreta.');
    }
    user.passwordHash = await hashPassword(dto.newPassword);
    user.updatedAt = new Date();
    return { success: true, message: 'Senha alterada com sucesso.' };
  }

  async validateUserById(id: string): Promise<SanitizedUser | null> {
    const user = this.users.find((u) => u.id === id);
    if (!user) return null;

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      picture: user.picture,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  private generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };
    const accessToken = this.jwtService.sign(payload, { expiresIn: '15m' });
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });
    return { accessToken, refreshToken };
  }
}

describe('AuthModule E2E Integration Suite (AUTH-01 & AUTH-02)', () => {
  let app: NestFastifyApplication;
  let validAccessToken: string;

  const validRegistrationPayload = {
    name: 'Carlos Alberto Silva',
    email: 'carlos.alberto@example.com',
    password: 'P@ssword123!',
    gender: 'masculino',
    dateOfBirth: '1990-05-15',
    lgpdConsent: true,
    disclaimerVersion: '2026.1',
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(AuthService)
      .useClass(MockAuthService)
      .compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );

    app.enableVersioning({
      type: VersioningType.URI,
      defaultVersion: '1',
    });

    // Enforce global validation pipeline matching production configuration
    app.useGlobalPipes(
      new ValidationPipe({
        transform: true,
        whitelist: true,
      }),
    );

    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('Scenario 1: POST /v1/auth/register with valid payload returns HTTP 201 and sanitized user', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/register',
      payload: validRegistrationPayload,
    });

    expect(res.statusCode).toBe(201);
    const body = JSON.parse(res.payload);
    expect(body).toHaveProperty('accessToken');
    expect(body).toHaveProperty('refreshToken');
    expect(body).toHaveProperty('user');
    expect(body.user).toHaveProperty('id');
    expect(body.user.name).toBe(validRegistrationPayload.name);
    expect(body.user.email).toBe(validRegistrationPayload.email);
    expect(body.user.gender).toBe(validRegistrationPayload.gender);
    expect(body.user.passwordHash).toBeUndefined();

    // Store token for Scenario 6
    validAccessToken = body.accessToken;
  });

  it('Scenario 2: POST /v1/auth/register with lgpdConsent: false returns HTTP 400 Bad Request', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/register',
      payload: {
        ...validRegistrationPayload,
        email: 'another.person@example.com',
        lgpdConsent: false,
      },
    });

    expect(res.statusCode).toBe(400);
    const body = JSON.parse(res.payload);
    expect(body.message).toBeDefined();
    const errorMsg = Array.isArray(body.message)
      ? body.message.join(' ')
      : body.message;
    expect(errorMsg).toContain('Consentimento LGPD Art. 11');
  });

  it('Scenario 3: POST /v1/auth/register with duplicate email returns HTTP 409 Conflict', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/register',
      payload: validRegistrationPayload,
    });

    expect(res.statusCode).toBe(409);
    const body = JSON.parse(res.payload);
    expect(body.message).toBe('E-mail já cadastrado.');
  });

  it('Scenario 4: POST /v1/auth/login with correct credentials returns HTTP 200 and valid JWT', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/login',
      payload: {
        email: validRegistrationPayload.email,
        password: validRegistrationPayload.password,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body).toHaveProperty('accessToken');
    expect(body).toHaveProperty('refreshToken');
    expect(body.user.email).toBe(validRegistrationPayload.email);
    expect(body.user.passwordHash).toBeUndefined();
  });

  it('Scenario 5: POST /v1/auth/login with invalid password returns HTTP 401 Unauthorized', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/login',
      payload: {
        email: validRegistrationPayload.email,
        password: 'IncorrectPassword999!',
      },
    });

    expect(res.statusCode).toBe(401);
    const body = JSON.parse(res.payload);
    expect(body.message).toBe('Credenciais inválidas.');
  });

  it('Scenario 6: GET /v1/auth/me with Bearer token returns HTTP 200 with profile; without token returns HTTP 401', async () => {
    // 1. Unauthenticated request without token
    const unauthRes = await app.inject({
      method: 'GET',
      url: '/v1/auth/me',
    });

    expect(unauthRes.statusCode).toBe(401);

    // 2. Authenticated request with Bearer token
    const authRes = await app.inject({
      method: 'GET',
      url: '/v1/auth/me',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
    });

    expect(authRes.statusCode).toBe(200);
    const body = JSON.parse(authRes.payload);
    expect(body.email).toBe(validRegistrationPayload.email);
    expect(body.name).toBe(validRegistrationPayload.name);
    expect(body.passwordHash).toBeUndefined();
  });

  it('Scenario 7: PATCH /v1/auth/profile with Bearer token updates name, dateOfBirth, picture and returns HTTP 200', async () => {
    const updatePayload = {
      name: 'Carlos Alberto Modificado',
      dateOfBirth: '1989-11-20',
      picture: 'avatar_clinical_teal_02',
    };

    const res = await app.inject({
      method: 'PATCH',
      url: '/v1/auth/profile',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: updatePayload,
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.name).toBe(updatePayload.name);
    expect(body.dateOfBirth).toBe(updatePayload.dateOfBirth);
    expect(body.picture).toBe(updatePayload.picture);
  });

  it('Scenario 8: POST /v1/auth/change-password with correct current password returns HTTP 200; with wrong password returns HTTP 401', async () => {
    const wrongRes = await app.inject({
      method: 'POST',
      url: '/v1/auth/change-password',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        currentPassword: 'WrongPassword999!',
        newPassword: 'BrandNewSecurePassword123!',
      },
    });

    expect(wrongRes.statusCode).toBe(401);

    const correctRes = await app.inject({
      method: 'POST',
      url: '/v1/auth/change-password',
      headers: {
        authorization: `Bearer ${validAccessToken}`,
      },
      payload: {
        currentPassword: validRegistrationPayload.password,
        newPassword: 'BrandNewSecurePassword123!',
      },
    });

    expect(correctRes.statusCode).toBe(200);
    const body = JSON.parse(correctRes.payload);
    expect(body.success).toBe(true);
  });
});
