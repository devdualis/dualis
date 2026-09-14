import { Injectable, Inject, BadRequestException } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { and, desc, gte, or, eq, sql } from 'drizzle-orm';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { symptomLogs } from '../../../database/schema';
import { AntiburlaCheckResponseDto, CheckAntiburlaDto } from '../dto/antiburla.dto';

@Injectable()
export class AntiburlaService {
  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
  ) {}

  async checkHistoricalConsistency(
    userId: string,
    dto: CheckAntiburlaDto,
  ): Promise<AntiburlaCheckResponseDto> {
    if (!userId) {
      throw new BadRequestException('ID do usuário ausente para verificação histórica.');
    }

    const { vertical, category, selectedPersistence, userGender, narrative } = dto;

    // 1. Biological Boundary Check (ANTI-03)
    let biologicalDiscordance = false;
    let biologicalNotice: string | undefined;

    const lowerNarrative = (narrative || '').toLowerCase();
    const lowerCategory = (category || '').toLowerCase();

    if (userGender === 'feminino') {
      const maleTerms = ['testículo', 'testiculo', 'próstata', 'prostata', 'escrotal'];
      if (maleTerms.some((term) => lowerNarrative.includes(term) || lowerCategory.includes(term))) {
        biologicalDiscordance = true;
        biologicalNotice =
          'Observamos uma possível discordância anatômica com o seu perfil biológico. Redirecionando a avaliação para a região pélvica/abdominal.';
      }
    } else if (userGender === 'masculino') {
      const femaleTerms = ['útero', 'utero', 'ovário', 'ovario', 'vagina', 'menstrua'];
      if (femaleTerms.some((term) => lowerNarrative.includes(term) || lowerCategory.includes(term))) {
        biologicalDiscordance = true;
        biologicalNotice =
          'Observamos uma possível discordância anatômica com o seu perfil biológico. Redirecionando a avaliação para a região pélvica/inguinal.';
      }
    }

    // 2. Antiburla 14-Day Consistency Check (ANTI-01, ANTI-02)
    // Only triggers if user states symptom started today / just now
    const isTodayPersistence =
      selectedPersistence === 'comecou_hoje' ||
      selectedPersistence === 'comecou_agora' ||
      selectedPersistence.includes('hoje') ||
      selectedPersistence.includes('agora');

    if (!isTodayPersistence) {
      return {
        triggered: false,
        biologicalDiscordance,
        biologicalNotice,
      };
    }

    // 14-day rolling cutoff date
    const cutoffDate = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);

    // Query past 14 days under RLS
    const pastLogs = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.current_user_id', ${userId}, true)`);
      return tx
        .select()
        .from(symptomLogs)
        .where(
          and(
            eq(symptomLogs.userId, userId),
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
      return {
        triggered: false,
        biologicalDiscordance,
        biologicalNotice,
      };
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
      biologicalDiscordance,
      biologicalNotice,
    };
  }
}
