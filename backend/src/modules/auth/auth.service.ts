import {
  Injectable,
  Inject,
  UnauthorizedException,
  BadRequestException,
  Logger,
  Optional,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { eq, sql, desc, inArray, and, lt } from 'drizzle-orm';
import * as crypto from 'crypto';
import { DRIZZLE_DB, DrizzleTransaction } from '../../database/database.service';
import * as schema from '../../database/schema';
import {
  users,
  userDisclaimerConsents,
  symptomLogs,
  safetyResourceEvents,
  waterIntakeLogs,
  profiles,
  journalEntries,
  journalItems,
  userConditions,
  emailVerifications,
  passwordResets,
} from '../../database/schema';
import { EncryptionService } from '../../common/encryption/encryption.service';
import { EmailService } from '../../common/email/email.service';
import { hashPassword, verifyPassword } from './utils/password.util';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import {
  AuthResponseDto,
  AuthenticatedUser,
  SanitizedUser,
  RegisterResponseDto,
} from './dto/auth-response.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { ResendVerificationDto } from './dto/resend-verification.dto';
import { DeleteAccountDto } from './dto/delete-account.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import {
  ExportedJournalEntryDto,
  ExportedSymptomLogDto,
  ExportedUserConditionDto,
  UserDataExportResponseDto,
} from './dto/export-data.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { StorageService } from '../../common/storage/storage.service';
import { JwtPayload } from './strategies/jwt.strategy';
import { LEGAL_DOCUMENTS_VERSION } from '../legal/legal.service';
import { isAllowedPicture } from './utils/picture.util';

/** Wrong guesses allowed per verification or password reset code. */
const MAX_CODE_ATTEMPTS = 5;
/** Codes of one kind an account can get per 24 hours: with 5 tries each, 25 guesses a day. */
const MAX_CODES_PER_DAY = 5;
const CODE_TTL_MS = 15 * 60 * 1000;
const CODE_COOLDOWN_MS = 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
/** Same message for every failure, so a reply never shows whether an email has an account. */
const INVALID_CODE_MESSAGE = 'Código inválido ou expirado. Solicite um novo código.';

type CodeTable = typeof emailVerifications | typeof passwordResets;
type CodeRecord = typeof emailVerifications.$inferSelect;
type UserRecord = typeof users.$inferSelect;

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  /** Hash of a random password: logins for unknown emails check against it and take as long. */
  private dummyPasswordHash?: Promise<string>;

  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
    @Inject(JwtService) private readonly jwtService: JwtService,
    private readonly encryptionService: EncryptionService,
    private readonly emailService: EmailService,
    @Optional() private readonly storageService?: StorageService,
  ) {}

  async register(
    dto: RegisterDto,
    clientIp: string = '127.0.0.1',
    userAgent: string = 'Unknown',
  ): Promise<RegisterResponseDto> {
    if (dto.lgpdConsent !== true) {
      throw new BadRequestException('Consentimento LGPD Art. 11 é obrigatório.');
    }

    const email = dto.email.toLowerCase().trim();
    // Same answer and the same work (one Argon2 hash) for a new or a registered address.
    // The owner of a registered one gets an email saying so instead of a code.
    const response: RegisterResponseDto = {
      requiresVerification: true,
      email,
      message: 'Enviamos as instruções para o seu e-mail.',
    };

    const existing = await this.findUserByEmail(email);
    const passwordHash = await hashPassword(dto.password);
    if (existing) {
      this.sendInBackground(this.emailService.sendAccountExistsEmail(email, existing.name));
      return response;
    }

    const newUserId = crypto.randomUUID();
    let created: UserRecord;
    try {
      created = await this.db.transaction(async (tx) => {
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
            isEmailVerified: false,
          })
          .returning();

        await tx.insert(userDisclaimerConsents).values({
          userId: newUserId,
          disclaimerVersion: dto.disclaimerVersion || LEGAL_DOCUMENTS_VERSION,
          ipAddressHash: this.encryptionService.hashIp(clientIp || '127.0.0.1'),
          userAgent: userAgent || 'Unknown',
        });

        return insertedUser;
      });
    } catch (err) {
      // A parallel sign-up for the same address won: answer as for a registered one.
      if (isUniqueViolation(err)) return response;
      throw err;
    }

    const code = this.emailService.generateVerificationCode();
    await this.issueCode(emailVerifications, created.id, email, this.emailService.hashCode(code));
    this.sendInBackground(this.emailService.sendVerificationEmail(email, code, created.name));

    return response;
  }

  async verifyEmail(dto: VerifyEmailDto): Promise<AuthResponseDto> {
    const record = await this.checkCode(
      emailVerifications,
      dto.email.toLowerCase().trim(),
      dto.code.trim(),
    );

    const updatedUser = await this.db.transaction(async (tx) => {
      await this.actAsAuthServiceFor(tx, record.userId);
      await this.consumeCode(tx, emailVerifications, record);
      const [u] = await tx
        .update(users)
        .set({
          isEmailVerified: true,
          emailVerifiedAt: new Date(),
          updatedAt: new Date(),
        })
        .where(eq(users.id, record.userId))
        .returning();
      return u;
    });

    return {
      ...this.generateTokens(updatedUser),
      user: { ...this.sanitize(updatedUser), isEmailVerified: updatedUser.isEmailVerified },
    };
  }

  async resendVerification(dto: ResendVerificationDto): Promise<{ success: boolean; message: string }> {
    const email = dto.email.toLowerCase().trim();
    const user = await this.findUserByEmail(email);

    // Unknown, already confirmed, too soon or over the daily cap: the answer is the same.
    if (user && !user.isEmailVerified) {
      const code = this.emailService.generateVerificationCode();
      if (await this.issueCode(emailVerifications, user.id, email, this.emailService.hashCode(code))) {
        this.sendInBackground(this.emailService.sendVerificationEmail(email, code, user.name));
      }
    }

    return {
      success: true,
      message: 'Se o e-mail estiver cadastrado e ainda não confirmado, enviamos um novo código.',
    };
  }

  async forgotPassword(dto: ForgotPasswordDto): Promise<{ success: boolean; message: string }> {
    const email = dto.email.toLowerCase().trim();
    const user = await this.findUserByEmail(email);

    // Unknown, too soon or over the daily cap: the answer is the same.
    if (user) {
      const code = this.emailService.generateVerificationCode();
      if (await this.issueCode(passwordResets, user.id, email, this.emailService.hashCode(code))) {
        this.sendInBackground(this.emailService.sendPasswordResetEmail(email, code, user.name));
      }
    }

    return { success: true, message: 'Se o e-mail estiver cadastrado, um código de redefinição foi enviado.' };
  }

  async resetPassword(dto: ResetPasswordDto): Promise<{ success: boolean; message: string }> {
    const record = await this.checkCode(
      passwordResets,
      dto.email.toLowerCase().trim(),
      dto.code.trim(),
    );
    const newPasswordHash = await hashPassword(dto.newPassword);

    // The new hash also changes the session version, so every existing session ends.
    await this.db.transaction(async (tx) => {
      await this.actAsAuthServiceFor(tx, record.userId);
      await this.consumeCode(tx, passwordResets, record);
      await tx
        .update(users)
        .set({
          passwordHash: newPasswordHash,
          updatedAt: new Date(),
        })
        .where(eq(users.id, record.userId));
    });

    return { success: true, message: 'Senha redefinida com sucesso. Você já pode entrar com a nova senha.' };
  }

  async login(dto: LoginDto): Promise<AuthResponseDto> {
    const email = dto.email.toLowerCase().trim();
    const user = await this.findUserByEmail(email);

    if (!user) {
      await this.verifyAgainstDummyHash(dto.password);
      throw new UnauthorizedException('Credenciais inválidas.');
    }

    const isMatch = await verifyPassword(user.passwordHash, dto.password);
    if (!isMatch) {
      throw new UnauthorizedException('Credenciais inválidas.');
    }

    if (user.isEmailVerified === false) {
      // `code` lets the app open the verification screen instead of a generic error.
      throw new UnauthorizedException({
        statusCode: 401,
        error: 'Unauthorized',
        code: 'EMAIL_NOT_VERIFIED',
        message: 'E-mail não verificado. Por favor, confirme seu e-mail antes de entrar.',
      });
    }

    return {
      ...this.generateTokens(user),
      user: this.sanitize(user),
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

      // Clinical data belongs to profiles. The export covers every profile this
      // account owns: the primary profile (top level) and its dependents (grouped).
      // Profiles shared with the caller by other accounts are not the caller's data.
      const ownedProfiles = await tx
        .select()
        .from(profiles)
        .where(eq(profiles.accountOwnerId, userId));
      const ownedProfileIds = ownedProfiles.map((p) => p.id);

      const symptomRecords = ownedProfileIds.length
        ? await tx
            .select()
            .from(symptomLogs)
            .where(inArray(symptomLogs.profileId, ownedProfileIds))
        : [];

      const safetyRecords = ownedProfileIds.length
        ? await tx
            .select()
            .from(safetyResourceEvents)
            .where(inArray(safetyResourceEvents.profileId, ownedProfileIds))
        : [];

      const waterRecords = ownedProfileIds.length
        ? await tx
            .select()
            .from(waterIntakeLogs)
            .where(inArray(waterIntakeLogs.profileId, ownedProfileIds))
        : [];

      // Journal v2 (entries with their items) and "Minhas condições", archived ones included.
      const journalEntryRecords = ownedProfileIds.length
        ? await tx
            .select()
            .from(journalEntries)
            .where(inArray(journalEntries.profileId, ownedProfileIds))
        : [];
      const journalItemRecords = journalEntryRecords.length
        ? await tx
            .select()
            .from(journalItems)
            .where(inArray(journalItems.entryId, journalEntryRecords.map((e) => e.id)))
        : [];
      const conditionRecords = ownedProfileIds.length
        ? await tx
            .select()
            .from(userConditions)
            .where(inArray(userConditions.profileId, ownedProfileIds))
        : [];
      const conditionLabels = new Map(conditionRecords.map((c) => [c.id, this.decryptForExport(c.label)]));

      const clinicalDataFor = (profileId: string | undefined) => ({
        symptomLogs: symptomRecords
          .filter((s) => s.profileId === profileId)
          .map((s) => this.toExportedSymptomLog(s)),
        safetyResourceEvents: safetyRecords
          .filter((e) => e.profileId === profileId)
          .map((e) => ({
            id: e.id,
            action: e.action,
            channel: e.channel,
            clientTimestamp: e.clientTimestamp.toISOString(),
            createdAt: e.createdAt.toISOString(),
          })),
        waterIntakeLogs: waterRecords
          .filter((w) => w.profileId === profileId)
          .map((w) => ({
            id: w.id,
            amountMl: w.amountMl,
            source: w.source,
            recordedAt: w.recordedAt.toISOString(),
          })),
        journalEntries: journalEntryRecords
          .filter((e) => e.profileId === profileId)
          .sort((a, b) => b.recordedAt.getTime() - a.recordedAt.getTime())
          .map((e) => this.toExportedJournalEntry(e, journalItemRecords, conditionLabels)),
        userConditions: conditionRecords
          .filter((c) => c.profileId === profileId)
          .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime())
          .map(
            (c): ExportedUserConditionDto => ({
              id: c.id,
              label: conditionLabels.get(c.id) ?? null,
              createdAt: c.createdAt.toISOString(),
              archivedAt: c.archivedAt?.toISOString() ?? null,
            }),
          ),
      });

      const primaryProfile = ownedProfiles.find((p) => p.profileType === 'primary');
      const dependentProfiles = ownedProfiles
        .filter((p) => p.profileType !== 'primary')
        .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());

      return {
        metadata: {
          exportDate: new Date().toISOString(),
          formatVersion: '1.3',
          legalBasis: 'LGPD Art. 18, V (Portabilidade de Dados)',
          dataController: 'WGI (Brothers Baum Ltda.)',
          legacyFieldsNote:
            'Os campos em "legacy" vêm de uma versão anterior do app e não são mais gravados. Estão incluídos apenas para que você tenha acesso ao seu histórico completo.',
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
        ...clinicalDataFor(primaryProfile?.id),
        dependentProfiles: dependentProfiles.map((p) => ({
          profile: {
            id: p.id,
            name: p.name,
            profileType: p.profileType,
            dateOfBirth: p.dateOfBirth ?? null,
            gender: p.gender ?? null,
            createdAt: p.createdAt.toISOString(),
          },
          ...clinicalDataFor(p.id),
        })),
      };
    });
  }

  private toExportedJournalEntry(
    e: typeof journalEntries.$inferSelect,
    items: Array<typeof journalItems.$inferSelect>,
    conditionLabels: Map<string, string | null>,
  ): ExportedJournalEntryDto {
    return {
      id: e.id,
      clientId: e.clientId,
      recordedAt: e.recordedAt.toISOString(),
      mood: e.mood,
      triggers: e.triggers,
      triggerNote: this.decryptForExport(e.triggerNote),
      note: this.decryptForExport(e.note),
      createdAt: e.createdAt.toISOString(),
      items: items
        .filter((i) => i.entryId === e.id)
        .map((i) => ({
          id: i.id,
          kind: i.kind,
          optionKey: i.optionKey,
          customLabel: this.decryptForExport(i.customLabel),
          conditionId: i.conditionId,
          conditionLabel: i.conditionId ? (conditionLabels.get(i.conditionId) ?? null) : null,
          bodySide: i.bodySide,
          persistence: i.persistence,
          intensity: i.intensity,
        })),
    };
  }

  /** Plain text of an encrypted column; null when empty or unreadable (never ciphertext). */
  private decryptForExport(value: string | null): string | null {
    if (!value) return null;
    if (!value.startsWith('v1:')) return value;
    try {
      return this.encryptionService.decrypt(value);
    } catch {
      return null;
    }
  }

  private toExportedSymptomLog(s: typeof symptomLogs.$inferSelect): ExportedSymptomLogDto {
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
      let rawAnswers = s.stepAnswers;
      if (rawAnswers.startsWith('v1:')) {
        try {
          rawAnswers = this.encryptionService.decrypt(rawAnswers);
        } catch {
          // keep the stored value if decryption fails
        }
      }
      try {
        parsedAnswers = JSON.parse(rawAnswers);
      } catch {
        parsedAnswers = rawAnswers;
      }
    }
    return {
      id: s.id,
      intensity: s.intensity,
      anatomicalSystem: s.anatomicalSystem,
      emotionalDimension: s.emotionalDimension,
      legacy: {
        disposition: s.disposition,
        organicPrimacyApplied: s.organicPrimacyApplied,
      },
      decryptedNarrative,
      stepAnswers: parsedAnswers,
      recordedAt: s.recordedAt.toISOString(),
    };
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
    let picture: string | undefined;
    if (dto.picture !== undefined) {
      const current = await this.db.transaction(async (tx) => {
        await tx.execute(
          sql`SELECT set_config('app.current_user_id', ${userId}, true)`,
        );
        const [record] = await tx
          .select({ picture: users.picture })
          .from(users)
          .where(eq(users.id, userId))
          .limit(1);
        return record;
      });
      // The app sends the current picture back with every save: only a new one is checked.
      if (dto.picture !== current?.picture) {
        if (!isAllowedPicture(dto.picture)) {
          throw new BadRequestException(
            'Foto de perfil inválida. Use uma imagem PNG, JPEG ou WebP de até 1,5 MB.',
          );
        }
        picture = this.storageService
          ? await this.storageService.processAvatarImage(userId, dto.picture)
          : dto.picture;
      }
    }

    const updated = await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${userId}, true)`,
      );

      const updateData: Partial<typeof users.$inferInsert> = {
        updatedAt: new Date(),
      };
      if (dto.name !== undefined) updateData.name = dto.name;
      if (dto.dateOfBirth !== undefined) updateData.dateOfBirth = dto.dateOfBirth;
      if (picture !== undefined) updateData.picture = picture;
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

    return this.sanitize(updated);
  }

  async changePassword(
    userId: string,
    dto: ChangePasswordDto,
  ): Promise<{ success: boolean; message: string; accessToken: string; refreshToken: string }> {
    const user = await this.findUserById(userId);

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

    // The new hash ends every other session; this device gets fresh tokens.
    return {
      success: true,
      message: 'Senha alterada com sucesso. As outras sessões foram encerradas.',
      ...this.generateTokens({ ...user, passwordHash: newPasswordHash }),
    };
  }

  /**
   * The user behind a token: null when the account is gone or the password changed after the
   * token was issued. Reads only the columns a request needs, not the picture.
   */
  async validateUserById(
    id: string,
    sessionVersion: string | undefined,
  ): Promise<AuthenticatedUser | null> {
    const user = await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${id}, true)`,
      );
      const [record] = await tx
        .select({ id: users.id, email: users.email, passwordHash: users.passwordHash })
        .from(users)
        .where(eq(users.id, id))
        .limit(1);
      return record;
    });

    if (!user || sessionVersion !== this.sessionVersion(user.passwordHash)) return null;
    return { id: user.id, email: user.email };
  }

  /** Full profile of the signed-in user, for `GET /auth/me`. */
  async getProfile(userId: string): Promise<SanitizedUser> {
    const user = await this.findUserById(userId);
    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado.');
    }
    return this.sanitize(user);
  }

  async refreshTokens(refreshToken: string): Promise<AuthResponseDto> {
    let payload: JwtPayload;
    try {
      payload = await this.jwtService.verifyAsync<JwtPayload>(refreshToken);
    } catch {
      throw new UnauthorizedException('Token de atualização inválido ou expirado.');
    }

    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Token de atualização inválido.');
    }

    const user = await this.findUserById(payload.sub);
    // Gone, or the password changed after this token was issued.
    if (!user || payload.sv !== this.sessionVersion(user.passwordHash)) {
      throw new UnauthorizedException('Sessão encerrada. Entre novamente.');
    }

    return { ...this.generateTokens(user), user: this.sanitize(user) };
  }

  /**
   * Short hash of the stored password hash, carried in every token as `sv`. A password change
   * or reset stores a new Argon2 hash (new salt), so tokens issued before it stop working.
   */
  private sessionVersion(passwordHash: string): string {
    return crypto.createHash('sha256').update(passwordHash).digest('base64url').slice(0, 16);
  }

  private generateTokens(user: { id: string; email: string; passwordHash: string }) {
    const sv = this.sessionVersion(user.passwordHash);
    const accessPayload: JwtPayload = { sub: user.id, email: user.email, type: 'access', sv };
    const refreshPayload: JwtPayload = { sub: user.id, email: user.email, type: 'refresh', sv };
    const accessToken = this.jwtService.sign(accessPayload, { expiresIn: '15m' });
    const refreshToken = this.jwtService.sign(refreshPayload, { expiresIn: '7d' });
    return { accessToken, refreshToken };
  }

  private sanitize(user: UserRecord): SanitizedUser {
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

  private async findUserById(id: string): Promise<UserRecord | undefined> {
    return this.db.transaction(async (tx) => {
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
  }

  private async findUserByEmail(email: string): Promise<UserRecord | undefined> {
    return this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.is_auth_service', 'true', true)`);
      const [record] = await tx
        .select()
        .from(users)
        .where(eq(users.email, email))
        .limit(1);
      return record;
    });
  }

  private async verifyAgainstDummyHash(password: string): Promise<void> {
    this.dummyPasswordHash ??= hashPassword(crypto.randomUUID());
    await verifyPassword(await this.dummyPasswordHash, password);
  }

  /** Emails go out after the reply, so reply times do not show which path ran. */
  private sendInBackground(sending: Promise<void>): void {
    sending.catch((err: Error) => this.logger.error(`Falha ao enviar e-mail: ${err.message}`));
  }

  /**
   * Context for the code flows: the lookup flag, plus the target user, because the users
   * policy only accepts an update to the row of `app.current_user_id`.
   */
  private async actAsAuthServiceFor(tx: DrizzleTransaction, userId: string): Promise<void> {
    await tx.execute(sql`SELECT set_config('app.is_auth_service', 'true', true)`);
    await tx.execute(sql`SELECT set_config('app.current_user_id', ${userId}, true)`);
  }

  /**
   * Stores a new code for the account, unless one was stored in the last minute or the account
   * already got MAX_CODES_PER_DAY in 24 hours. Earlier codes stay (only the newest is accepted)
   * so the cap holds. Returns whether a code was stored.
   */
  private async issueCode(
    table: CodeTable,
    userId: string,
    email: string,
    codeHash: string,
  ): Promise<boolean> {
    return this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.is_auth_service', 'true', true)`);
      // One issuer per account at a time, so parallel requests cannot pass the cap together.
      await tx.execute(sql`SELECT pg_advisory_xact_lock(hashtext(${userId}))`);
      await tx
        .delete(table)
        .where(and(eq(table.userId, userId), lt(table.createdAt, new Date(Date.now() - DAY_MS))));
      const recent = await tx
        .select({ createdAt: table.createdAt })
        .from(table)
        .where(eq(table.userId, userId))
        .orderBy(desc(table.createdAt));
      if (recent.length >= MAX_CODES_PER_DAY) return false;
      if (recent[0] && Date.now() - recent[0].createdAt.getTime() < CODE_COOLDOWN_MS) return false;

      await tx.insert(table).values({
        userId,
        email,
        codeHash,
        attempts: 0,
        expiresAt: new Date(Date.now() + CODE_TTL_MS),
      });
      return true;
    });
  }

  /**
   * Spends one attempt on the newest code sent to `email` and returns it when `code` matches.
   * The attempt is counted atomically before the comparison, so parallel guesses each use one.
   */
  private async checkCode(table: CodeTable, email: string, code: string): Promise<CodeRecord> {
    const record = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.is_auth_service', 'true', true)`);
      const [latest] = await tx
        .select()
        .from(table)
        .where(eq(table.email, email))
        .orderBy(desc(table.createdAt))
        .limit(1);
      if (!latest || latest.expiresAt.getTime() < Date.now()) return undefined;

      const [claimed] = await tx
        .update(table)
        .set({ attempts: sql`${table.attempts} + 1` })
        .where(and(eq(table.id, latest.id), lt(table.attempts, MAX_CODE_ATTEMPTS)))
        .returning({ id: table.id });
      return claimed ? latest : undefined;
    });

    if (!record || !this.emailService.verifyCodeHash(code, record.codeHash)) {
      throw new BadRequestException(INVALID_CODE_MESSAGE);
    }
    return record;
  }

  /** Deletes the account's codes; fails when a parallel request already used this one. */
  private async consumeCode(
    tx: DrizzleTransaction,
    table: CodeTable,
    record: CodeRecord,
  ): Promise<void> {
    const deleted = await tx
      .delete(table)
      .where(eq(table.userId, record.userId))
      .returning({ id: table.id });
    if (!deleted.some((row) => row.id === record.id)) {
      throw new BadRequestException(INVALID_CODE_MESSAGE);
    }
  }
}

/** Postgres unique violation, raw or wrapped by Drizzle. */
function isUniqueViolation(err: unknown): boolean {
  const e = err as { code?: string; cause?: { code?: string } } | undefined;
  return e?.code === '23505' || e?.cause?.code === '23505';
}
