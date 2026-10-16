import { Injectable, Inject, BadRequestException } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { and, desc, gte, or, eq, sql } from 'drizzle-orm';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { symptomLogs } from '../../../database/schema';
import { CheckRecurrenceDto, RecurrenceCheckResponseDto } from '../dto/antiburla.dto';

/**
 * Journal consistency ("Isso já apareceu antes?"): finds the same category in the
 * profile's last 14 days so a "started today" entry can be logged as something that
 * came back. Formerly AntiburlaService; the old name stays exported as an alias.
 */
@Injectable()
export class RecurrenceCheckService {
  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
  ) {}

  async checkHistoricalConsistency(
    userId: string,
    profileId: string,
    dto: CheckRecurrenceDto,
  ): Promise<RecurrenceCheckResponseDto> {
    if (!userId) {
      throw new BadRequestException('ID do usuário ausente para verificação histórica.');
    }
    if (!profileId) {
      throw new BadRequestException('ID do perfil ausente para verificação histórica.');
    }

    const { vertical, category, selectedPersistence } = dto;

    // 14-day consistency check (ANTI-01, ANTI-02)
    // Only triggers if user states symptom started today / just now
    const isTodayPersistence =
      selectedPersistence === 'comecou_hoje' ||
      selectedPersistence === 'comecou_agora' ||
      selectedPersistence.includes('hoje') ||
      selectedPersistence.includes('agora');

    if (!isTodayPersistence) {
      return { triggered: false };
    }

    // 14-day rolling cutoff date
    const cutoffDate = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);

    // Query the active profile's past 14 days under RLS
    const pastLogs = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.current_user_id', ${userId}, true)`);
      return tx
        .select()
        .from(symptomLogs)
        .where(
          and(
            eq(symptomLogs.profileId, profileId),
            gte(symptomLogs.recordedAt, cutoffDate),
            or(
              eq(symptomLogs.anatomicalSystem, category),
              eq(symptomLogs.emotionalDimension, category),
            ),
          ),
        )
        .orderBy(desc(symptomLogs.recordedAt))
        .limit(1);
    });

    if (pastLogs.length === 0) {
      return { triggered: false };
    }

    const previousLog = pastLogs[0];
    const diffMs = Math.abs(Date.now() - previousLog.recordedAt.getTime());
    const daysAgo = Math.max(1, Math.round(diffMs / (1000 * 60 * 60 * 24)));

    const symptomTerm = vertical === 'physical' ? 'esse desconforto físico' : 'esse desânimo ou sensação';

    const empatheticPrompt =
      `Notei aqui no seu histórico que você também sentiu ${symptomTerm} há ${daysAgo} dia${daysAgo > 1 ? 's' : ''}. ` +
      `Você acha que essa sensação de hoje é algo completamente novo ou pode ser aquela mesma que acabou voltando?`;

    return {
      triggered: true,
      daysAgo,
      previousRecordedAt: previousLog.recordedAt.toISOString(),
      previousCategoryLabel: previousLog.anatomicalSystem || previousLog.emotionalDimension || category,
      empatheticPrompt,
    };
  }
}

/** @deprecated Old name; use RecurrenceCheckService. */
export { RecurrenceCheckService as AntiburlaService };
