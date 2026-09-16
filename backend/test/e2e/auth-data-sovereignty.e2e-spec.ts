import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import {
  VersioningType,
  ValidationPipe,
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../../src/app.module';
import { AuthService } from '../../src/modules/auth/auth.service';
import { DeleteAccountDto } from '../../src/modules/auth/dto/delete-account.dto';
import { UserDataExportResponseDto } from '../../src/modules/auth/dto/export-data.dto';
import { SanitizedUser } from '../../src/modules/auth/dto/auth-response.dto';

const testUserId = '77777777-7777-7777-7777-777777777777';
const testUserEmail = 'lgpd.user@exemplo.com.br';

@Injectable()
class MockAuthService {
  private validPassword = 'CorrectPassword123!';

  async validateUserById(id: string): Promise<SanitizedUser | null> {
    if (id !== testUserId) return null;
    return {
      id: testUserId,
      name: 'Carlos Oliveira',
      email: testUserEmail,
      gender: 'masculino',
      dateOfBirth: '1985-11-30',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    };
  }

  async exportUserData(userId: string): Promise<UserDataExportResponseDto> {
    if (userId !== testUserId) {
      throw new UnauthorizedException('Usuário não encontrado.');
    }
    return {
      metadata: {
        exportDate: new Date().toISOString(),
        formatVersion: '1.0',
        legalBasis: 'LGPD Art. 18, V (Portabilidade de Dados)',
        dataController: 'DualisCheckUp Saúde Digital Ltda.',
      },
      profile: {
        id: testUserId,
        name: 'Carlos Oliveira',
        email: testUserEmail,
        gender: 'masculino',
        dateOfBirth: '1985-11-30',
        createdAt: '2026-01-01T10:00:00.000Z',
        updatedAt: '2026-01-01T10:00:00.000Z',
      },
      consents: [
        {
          id: 'consent-e2e-1',
          disclaimerVersion: '2026.1',
          acceptedAt: '2026-01-01T10:00:00.000Z',
          ipAddressHash: 'hash999',
          userAgent: 'Flutter/macOS',
        },
      ],
      symptomLogs: [
        {
          id: 'symptom-e2e-1',
          intensity: 2,
          anatomicalSystem: 'respiratorio',
          emotionalDimension: null,
          disposition: 'autocuidado',
          decryptedNarrative: 'Leve desconforto respiratório matinal',
          stepAnswers: { questions: ['sintoma iniciado hoje'] },
          recordedAt: '2026-01-02T08:00:00.000Z',
        },
      ],
      emergencyEvents: [],
    };
  }

  async deleteUserAccount(
    userId: string,
    dto: DeleteAccountDto,
  ): Promise<{ success: boolean; message: string }> {
    if (userId !== testUserId) {
      throw new UnauthorizedException('Usuário não encontrado.');
    }
    if (dto.password !== this.validPassword) {
      throw new BadRequestException('Senha incorreta para confirmação de exclusão.');
    }
    return {
      success: true,
      message: 'Conta e registros de saúde excluídos permanentemente conforme LGPD Art. 18, VI.',
    };
  }
}

describe('Auth LGPD Data Sovereignty E2E (SEC-03)', () => {
  let app: NestFastifyApplication;
  let jwtService: JwtService;
  let validToken: string;

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

    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    jwtService = moduleRef.get<JwtService>(JwtService);
    validToken = jwtService.sign({ sub: testUserId, email: testUserEmail, type: 'access' });
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('GET /v1/auth/export-data', () => {
    it('rejects unauthenticated requests with 401', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/v1/auth/export-data',
      });

      expect(response.statusCode).toBe(401);
    });

    it('returns complete portable JSON data package with 200 for authenticated user', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/v1/auth/export-data',
        headers: {
          authorization: `Bearer ${validToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const data = JSON.parse(response.payload);
      expect(data.metadata.legalBasis).toContain('LGPD Art. 18, V');
      expect(data.profile.id).toBe(testUserId);
      expect(data.profile.email).toBe(testUserEmail);
      expect(data.consents).toHaveLength(1);
      expect(data.symptomLogs).toHaveLength(1);
      expect(data.symptomLogs[0].decryptedNarrative).toBe('Leve desconforto respiratório matinal');
      expect(data.emergencyEvents).toEqual([]);
    });
  });

  describe('DELETE /v1/auth/account', () => {
    it('rejects unauthenticated requests with 401', async () => {
      const response = await app.inject({
        method: 'DELETE',
        url: '/v1/auth/account',
        payload: { password: 'CorrectPassword123!' },
      });

      expect(response.statusCode).toBe(401);
    });

    it('rejects requests with missing or short password with 400', async () => {
      const response = await app.inject({
        method: 'DELETE',
        url: '/v1/auth/account',
        headers: {
          authorization: `Bearer ${validToken}`,
        },
        payload: { password: 'short' },
      });

      expect(response.statusCode).toBe(400);
    });

    it('rejects requests with incorrect password with 400', async () => {
      const response = await app.inject({
        method: 'DELETE',
        url: '/v1/auth/account',
        headers: {
          authorization: `Bearer ${validToken}`,
        },
        payload: { password: 'IncorrectPassword123!' },
      });

      expect(response.statusCode).toBe(400);
      const body = JSON.parse(response.payload);
      expect(body.message).toContain('Senha incorreta');
    });

    it('successfully eliminates user account with 200 and confirmation message', async () => {
      const response = await app.inject({
        method: 'DELETE',
        url: '/v1/auth/account',
        headers: {
          authorization: `Bearer ${validToken}`,
        },
        payload: { password: 'CorrectPassword123!' },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.payload);
      expect(body.success).toBe(true);
      expect(body.message).toContain('LGPD Art. 18, VI');
    });
  });
});
