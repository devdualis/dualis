import { ConflictException, ForbiddenException, Inject, Injectable } from '@nestjs/common';
import { and, eq, isNull, sql } from 'drizzle-orm';
import { DatabaseService, DrizzleTransaction } from '../../database/database.service';
import { userAiConsents } from '../../database/schema/ai-consents.schema';
import { EncryptionService } from '../../common/encryption/encryption.service';
import { ProfileContext } from '../profiles/profile-context';

/**
 * Version of the AI-processing consent text the app shows. A code constant on purpose:
 * it changes only with the text, never through the environment or the legal documents' version.
 */
export const AI_PROCESSING_CONSENT_VERSION = '2026.1';
export const AI_CONSENT_PURPOSE = 'journal_ai_suggestions';
export const AI_CONSENT_REQUIRED = 'AI_CONSENT_REQUIRED';
export const AI_PROFILE_NOT_ALLOWED = 'AI_PROFILE_NOT_ALLOWED';
export const AI_CONSENT_VERSION_MISMATCH = 'AI_CONSENT_VERSION_MISMATCH';

const USER_AGENT_MAX = 255;

export interface AiConsentStatusDto {
  purpose: string;
  granted: boolean;
  version: string | null;
  currentVersion: string;
  grantedAt: string | null;
}

export function aiConsentRequiredError(): ForbiddenException {
  return new ForbiddenException({
    statusCode: 403,
    error: 'Forbidden',
    code: AI_CONSENT_REQUIRED,
    message: 'Para usar as sugestões com IA, permita o envio do texto em Configurações.',
  });
}

export function aiProfileNotAllowedError(): ForbiddenException {
  return new ForbiddenException({
    statusCode: 403,
    error: 'Forbidden',
    code: AI_PROFILE_NOT_ALLOWED,
    message: 'As sugestões com IA funcionam só nos perfis que você administra.',
  });
}

function versionMismatchError(): ConflictException {
  return new ConflictException({
    statusCode: 409,
    error: 'Conflict',
    code: AI_CONSENT_VERSION_MISMATCH,
    message: 'O texto da permissão mudou. Abra Configurações para ver a versão atual.',
  });
}

type ConsentRow = typeof userAiConsents.$inferSelect;

/**
 * Account-level record of the person's permission to send journal text to the AI provider.
 * Every read and write runs under RLS as the signed-in user (user_ai_consents, 0030).
 */
@Injectable()
export class AiConsentService {
  constructor(
    @Inject(DatabaseService) private readonly databaseService: DatabaseService,
    @Inject(EncryptionService) private readonly encryptionService: EncryptionService,
  ) {}

  async status(userId: string): Promise<AiConsentStatusDto> {
    const active = await this.databaseService.withRls(userId, (tx) => this.findActive(tx, userId));
    return toStatus(active);
  }

  async grant(userId: string, version: string, clientIp?: string, userAgent?: string): Promise<AiConsentStatusDto> {
    if (version !== AI_PROCESSING_CONSENT_VERSION) throw versionMismatchError();

    const row = await this.databaseService.withRls(userId, async (tx) => {
      const active = await this.findActive(tx, userId);
      if (active?.consentVersion === AI_PROCESSING_CONSENT_VERSION) return active;
      if (active) {
        await tx.update(userAiConsents).set({ revokedAt: sql`now()` }).where(eq(userAiConsents.id, active.id));
      }
      // Two grants at once (a double tap, a retry) both see no active row. The partial
      // unique index lets only one insert land; the other one returns the row that did,
      // instead of failing with a unique violation (500).
      const [created] = await tx
        .insert(userAiConsents)
        .values({
          userId,
          purpose: AI_CONSENT_PURPOSE,
          consentVersion: AI_PROCESSING_CONSENT_VERSION,
          ipAddressHash: this.encryptionService.hashIp(clientIp || '127.0.0.1'),
          userAgent: userAgent ? userAgent.slice(0, USER_AGENT_MAX) : null,
        })
        .onConflictDoNothing({
          target: [userAiConsents.userId, userAiConsents.purpose],
          where: sql`revoked_at IS NULL`,
        })
        .returning();
      return created ?? (await this.findActive(tx, userId));
    });
    return toStatus(row);
  }

  async revoke(userId: string): Promise<AiConsentStatusDto> {
    await this.databaseService.withRls(userId, (tx) =>
      tx
        .update(userAiConsents)
        .set({ revokedAt: sql`now()` })
        .where(activeOf(userId)),
    );
    return toStatus(undefined);
  }

  /**
   * Throws unless the active profile belongs to the caller (own or a dependent they manage)
   * and the caller holds an active consent for the current version. Call before any text
   * leaves the backend.
   */
  async assertAllowed(userId: string, profile: ProfileContext): Promise<void> {
    if (profile?.accessLevel !== 'OWNER') throw aiProfileNotAllowedError();
    const current = await this.status(userId);
    if (!current.granted) throw aiConsentRequiredError();
  }

  private async findActive(tx: DrizzleTransaction, userId: string): Promise<ConsentRow | undefined> {
    const [row] = await tx.select().from(userAiConsents).where(activeOf(userId)).limit(1);
    return row;
  }
}

const activeOf = (userId: string) =>
  and(
    eq(userAiConsents.userId, userId),
    eq(userAiConsents.purpose, AI_CONSENT_PURPOSE),
    isNull(userAiConsents.revokedAt),
  );

function toStatus(row: ConsentRow | undefined): AiConsentStatusDto {
  const granted = row?.consentVersion === AI_PROCESSING_CONSENT_VERSION;
  return {
    purpose: AI_CONSENT_PURPOSE,
    granted,
    version: row?.consentVersion ?? null,
    currentVersion: AI_PROCESSING_CONSENT_VERSION,
    grantedAt: row?.grantedAt ? new Date(row.grantedAt).toISOString() : null,
  };
}
