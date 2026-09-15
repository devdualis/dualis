import {
  Injectable,
  Inject,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { eq, sql } from 'drizzle-orm';
import * as crypto from 'crypto';
import { DRIZZLE_DB } from '../../database/database.service';
import * as schema from '../../database/schema';
import {
  users,
  userDisclaimerConsents,
  symptomLogs,
  triageEmergencyEvents,
} from '../../database/schema';
import { EncryptionService } from '../../common/encryption/encryption.service';
import { hashPassword, verifyPassword } from './utils/password.util';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto, SanitizedUser } from './dto/auth-response.dto';
import { DeleteAccountDto } from './dto/delete-account.dto';
import { UserDataExportResponseDto } from './dto/export-data.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ChangePasswordDto } from './dto/change-password.dto';

@Injectable()
export class AuthService {
  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
    @Inject(JwtService) private readonly jwtService: JwtService,
    private readonly encryptionService: EncryptionService,
  ) {}

  async register(
    dto: RegisterDto,
    clientIp: string = '127.0.0.1',
    userAgent: string = 'Unknown',
  ): Promise<AuthResponseDto> {
    if (dto.lgpdConsent !== true) {
      throw new BadRequestException('Consentimento LGPD Art. 11 é obrigatório.');
    }

    const email = dto.email.toLowerCase().trim();

    const existing = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.is_auth_service', 'true', true)`);
      const [record] = await tx
        .select()
        .from(users)
        .where(eq(users.email, email))
        .limit(1);
      return record;
    });

    if (existing) {
      throw new ConflictException('E-mail já cadastrado.');
    }

    const newUserId = crypto.randomUUID();
    const passwordHash = await hashPassword(dto.password);
    const ipAddressHash = crypto.createHash('sha256').update(clientIp || '127.0.0.1').digest('hex');

    const created = await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${newUserId}, true)`,
      );

      const [insertedUser] = await tx
        .insert(users)
        .values({
          id: newUserId,
          name: dto.name,
          email,
          passwordHash,
          gender: dto.gender,
          dateOfBirth: dto.dateOfBirth,
        })
        .returning();

      await tx.insert(userDisclaimerConsents).values({
        userId: newUserId,
        disclaimerVersion: dto.disclaimerVersion || '2026.1',
        ipAddressHash,
        userAgent: userAgent || 'Unknown',
      });

      return insertedUser;
    });

    const sanitizedUser: SanitizedUser = {
      id: created.id,
      name: created.name,
      email: created.email,
      gender: created.gender,
      dateOfBirth: created.dateOfBirth,
      picture: created.picture || null,
      createdAt: created.createdAt,
      updatedAt: created.updatedAt,
    };

    const tokens = this.generateTokens(created.id, created.email);

    return {
      ...tokens,
      user: sanitizedUser,
    };
  }

  async login(dto: LoginDto): Promise<AuthResponseDto> {
    const email = dto.email.toLowerCase().trim();

    const user = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.is_auth_service', 'true', true)`);
      const [record] = await tx
        .select()
        .from(users)
        .where(eq(users.email, email))
        .limit(1);
      return record;
    });

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
      picture: user.picture || null,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };

    const tokens = this.generateTokens(user.id, user.email);

    return {
      ...tokens,
      user: sanitizedUser,
    };
  }

  async exportUserData(userId: string): Promise<UserDataExportResponseDto> {
    return this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${userId}, true)`,
      );

      const [userRecord] = await tx
        .select()
        .from(users)
        .where(eq(users.id, userId))
        .limit(1);

      if (!userRecord) {
        throw new UnauthorizedException('Usuário não encontrado.');
      }

      const consentRecords = await tx
        .select()
        .from(userDisclaimerConsents)
        .where(eq(userDisclaimerConsents.userId, userId));

      const symptomRecords = await tx
        .select()
        .from(symptomLogs)
        .where(eq(symptomLogs.userId, userId));

      const emergencyRecords = await tx
        .select()
        .from(triageEmergencyEvents)
        .where(eq(triageEmergencyEvents.userId, userId));

      return {
        metadata: {
          exportDate: new Date().toISOString(),
          formatVersion: '1.0',
          legalBasis: 'LGPD Art. 18, V (Portabilidade de Dados)',
          dataController: 'DualisCheckUp Saúde Digital Ltda.',
        },
        profile: {
          id: userRecord.id,
          name: userRecord.name,
          email: userRecord.email,
          gender: userRecord.gender,
          dateOfBirth: userRecord.dateOfBirth,
          picture: userRecord.picture || null,
          createdAt: userRecord.createdAt.toISOString(),
          updatedAt: userRecord.updatedAt.toISOString(),
        },
        consents: consentRecords.map((c) => ({
          id: c.id,
          disclaimerVersion: c.disclaimerVersion,
          acceptedAt: c.acceptedAt.toISOString(),
          ipAddressHash: c.ipAddressHash,
          userAgent: c.userAgent,
        })),
        symptomLogs: symptomRecords.map((s) => {
          let decryptedNarrative: string | null = null;
          if (s.encryptedNarrative) {
            try {
              decryptedNarrative = this.encryptionService.decrypt(s.encryptedNarrative);
            } catch {
              decryptedNarrative = null;
            }
          }
          let parsedAnswers: any = null;
          if (s.stepAnswers) {
            try {
              parsedAnswers = JSON.parse(s.stepAnswers);
            } catch {
              parsedAnswers = s.stepAnswers;
            }
          }
          return {
            id: s.id,
            intensity: s.intensity,
            anatomicalSystem: s.anatomicalSystem,
            emotionalDimension: s.emotionalDimension,
            disposition: s.disposition,
            decryptedNarrative,
            stepAnswers: parsedAnswers,
            recordedAt: s.recordedAt.toISOString(),
          };
        }),
        emergencyEvents: emergencyRecords.map((e) => ({
          id: e.id,
          triggerCategory: e.triggerCategory,
          severityLevel: e.severityLevel,
          sourceVertical: e.sourceVertical,
          actionTaken: e.actionTaken,
          reportedAt: e.reportedAt.toISOString(),
        })),
      };
    });
  }

  async deleteUserAccount(
    userId: string,
    dto: DeleteAccountDto,
  ): Promise<{ success: boolean; message: string }> {
    const user = await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${userId}, true)`,
      );
      const [record] = await tx
        .select()
        .from(users)
        .where(eq(users.id, userId))
        .limit(1);
      return record;
    });

    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado.');
    }

    const isMatch = await verifyPassword(user.passwordHash, dto.password);
    if (!isMatch) {
      throw new BadRequestException('Senha incorreta para confirmação de exclusão.');
    }

    await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${userId}, true)`,
      );
      await tx.delete(users).where(eq(users.id, userId));
    });

    return {
      success: true,
      message: 'Conta e registros de saúde excluídos permanentemente conforme LGPD Art. 18, VI.',
    };
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<SanitizedUser> {
    const updated = await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${userId}, true)`,
      );

      const updateData: Partial<typeof users.$inferInsert> = {
        updatedAt: new Date(),
      };
      if (dto.name !== undefined) updateData.name = dto.name;
      if (dto.dateOfBirth !== undefined) updateData.dateOfBirth = dto.dateOfBirth;
      if (dto.picture !== undefined) updateData.picture = dto.picture;
      if (dto.gender !== undefined) updateData.gender = dto.gender;

      const [record] = await tx
        .update(users)
        .set(updateData)
        .where(eq(users.id, userId))
        .returning();

      return record;
    });

    if (!updated) {
      throw new UnauthorizedException('Usuário não encontrado.');
    }

    return {
      id: updated.id,
      name: updated.name,
      email: updated.email,
      gender: updated.gender,
      dateOfBirth: updated.dateOfBirth,
      picture: updated.picture || null,
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
    };
  }

  async changePassword(
    userId: string,
    dto: ChangePasswordDto,
  ): Promise<{ success: boolean; message: string }> {
    const user = await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${userId}, true)`,
      );
      const [record] = await tx
        .select()
        .from(users)
        .where(eq(users.id, userId))
        .limit(1);
      return record;
    });

    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado.');
    }

    const isMatch = await verifyPassword(user.passwordHash, dto.currentPassword);
    if (!isMatch) {
      throw new UnauthorizedException('A senha atual fornecida está incorreta.');
    }

    const newPasswordHash = await hashPassword(dto.newPassword);

    await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${userId}, true)`,
      );
      await tx
        .update(users)
        .set({
          passwordHash: newPasswordHash,
          updatedAt: new Date(),
        })
        .where(eq(users.id, userId));
    });

    return {
      success: true,
      message: 'Senha alterada com sucesso.',
    };
  }

  async validateUserById(id: string): Promise<SanitizedUser | null> {
    const user = await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${id}, true)`,
      );
      const [record] = await tx
        .select()
        .from(users)
        .where(eq(users.id, id))
        .limit(1);
      return record;
    });

    if (!user) return null;

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      picture: user.picture || null,
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
