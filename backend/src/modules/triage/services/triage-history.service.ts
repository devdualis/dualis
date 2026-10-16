import { Injectable, Inject, Optional, BadRequestException, NotFoundException } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { and, desc, gte, eq, sql } from 'drizzle-orm';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { symptomLogs } from '../../../database/schema';
import { EncryptionService } from '../../../common/encryption/encryption.service';
import {
  EmotionalDayDataDto,
  GetTriageHistoryQueryDto,
  JournalPatternDto,
  TriageHistoryResponseDto,
  TriageLogItemDto,
} from '../dto/triage-history.dto';
import { HIGH_REPORTED_INTENSITY } from '../constants/intensity-tier.constant';

const JOURNAL_PATTERN_WINDOW_DAYS = 10;
const JOURNAL_PATTERN_MIN_COUNT = 2;

const PHYSICAL_SYSTEM_KEYS = [
  'cabeca_pescoco',
  'cardiovascular_torax',
  'respiratorio',
  'gastrointestinal_abdomen',
  'coluna_dorsal',
  'membros_superiores_d',
  'membros_superiores_e',
  'membros_inferiores_d',
  'membros_inferiores_e',
  'neurologico',
  'geniturinario_pelvico',
  'dermatologico',
  'muscular_geral_sistemico',
  'endocrino_metabolico',
];

const EMOTIONAL_DIMENSION_KEYS = [
  'ansiosa_agitacao',
  'depressiva_desanimo',
  'estresse_burnout',
  'somatica',
  'sono',
  'cognitiva_foco',
  'autoestima',
];

@Injectable()
export class TriageHistoryService {
  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
    @Optional() @Inject(EncryptionService)
    private readonly encryptionService?: EncryptionService,
  ) {}

  async getHistory(
    userId: string,
    profileId: string,
    query?: GetTriageHistoryQueryDto,
  ): Promise<TriageHistoryResponseDto> {
    if (!userId) {
      throw new BadRequestException('ID do usuário ausente para consulta de histórico.');
    }
    if (!profileId) {
      throw new BadRequestException('ID do perfil ausente para consulta de histórico.');
    }

    const windowDays = Math.min(Math.max(query?.days || 14, 1), 30);
    const cutoffDate = new Date(Date.now() - windowDays * 24 * 60 * 60 * 1000);

    const rows = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.current_user_id', ${userId}, true)`);
      return tx
        .select()
        .from(symptomLogs)
        .where(
          and(
            eq(symptomLogs.profileId, profileId),
            gte(symptomLogs.recordedAt, cutoffDate),
          ),
        )
        .orderBy(desc(symptomLogs.recordedAt));
    });

    const logs: TriageLogItemDto[] = rows.map((row) => {
      let parsedAnswers: any = null;
      if (row.stepAnswers) {
        let rawAnswers = row.stepAnswers;
        if (rawAnswers.startsWith('v1:') && this.encryptionService) {
          try {
            rawAnswers = this.encryptionService.decrypt(rawAnswers);
          } catch {
            // retain raw if decryption fails
          }
        }
        try {
          parsedAnswers = JSON.parse(rawAnswers);
        } catch {
          parsedAnswers = { raw: rawAnswers };
        }
      }

      let decryptedNarrative: string | null = null;
      if (row.encryptedNarrative) {
        let rawNarrative = row.encryptedNarrative;
        if (rawNarrative.startsWith('v1:') && this.encryptionService) {
          try {
            decryptedNarrative = this.encryptionService.decrypt(rawNarrative);
          } catch {
            decryptedNarrative = rawNarrative;
          }
        } else {
          decryptedNarrative = rawNarrative;
        }
      }

      let vertical: TriageLogItemDto['vertical'] = null;
      if (parsedAnswers && typeof parsedAnswers === 'object' && !Array.isArray(parsedAnswers)) {
        const { _entryVertical: entryVertical, ...visibleAnswers } = parsedAnswers;
        if (entryVertical === 'physical' || entryVertical === 'emotional') {
          vertical = entryVertical;
        }
        parsedAnswers = visibleAnswers;
      }
      // Legacy rows: organic primacy was only applied to emotional entries.
      if (!vertical && row.organicPrimacyApplied) {
        vertical = 'emotional';
      }

      return {
        id: row.id,
        intensity: row.intensity,
        anatomicalSystem: row.anatomicalSystem,
        emotionalDimension: row.emotionalDimension,
        vertical,
        narrative: decryptedNarrative,
        stepAnswers: parsedAnswers,
        recordedAt: row.recordedAt.toISOString(),
      };
    });

    const physicalSummary: Record<string, number> = {};
    for (const sys of PHYSICAL_SYSTEM_KEYS) {
      physicalSummary[sys] = 0;
    }

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const log = logs[i];
      if (row.anatomicalSystem) {
        const key = row.anatomicalSystem;
        const currentMax = physicalSummary[key] || 0;
        physicalSummary[key] = Math.max(currentMax, row.intensity);

        if (key === 'coluna_dor_dorsal' || key === 'coluna_dorsal') {
          physicalSummary['coluna_dorsal'] = Math.max(physicalSummary['coluna_dorsal'] || 0, row.intensity);
          physicalSummary['coluna_dor_dorsal'] = Math.max(physicalSummary['coluna_dor_dorsal'] || 0, row.intensity);
        }

        if (key === 'membros_superiores' || key.startsWith('membros_superiores')) {
          physicalSummary['membros_superiores'] = Math.max(physicalSummary['membros_superiores'] || 0, row.intensity);

          const answersStr = JSON.stringify(log?.stepAnswers || row.stepAnswers || '').toLowerCase();
          const isRight = answersStr.includes('direito') || key === 'membros_superiores_d';
          const isLeft = answersStr.includes('esquerdo') || key === 'membros_superiores_e';
          const isBilateral = answersStr.includes('bilateral');

          if (isBilateral || (isRight && isLeft) || (!isRight && !isLeft)) {
            // Both limbs
            physicalSummary['membros_superiores_d'] = Math.max(physicalSummary['membros_superiores_d'] || 0, row.intensity);
            physicalSummary['membros_superiores_e'] = Math.max(physicalSummary['membros_superiores_e'] || 0, row.intensity);
          } else if (isRight) {
            physicalSummary['membros_superiores_d'] = Math.max(physicalSummary['membros_superiores_d'] || 0, row.intensity);
          } else if (isLeft) {
            physicalSummary['membros_superiores_e'] = Math.max(physicalSummary['membros_superiores_e'] || 0, row.intensity);
          }
        }

        if (key === 'membros_inferiores' || key.startsWith('membros_inferiores')) {
          physicalSummary['membros_inferiores'] = Math.max(physicalSummary['membros_inferiores'] || 0, row.intensity);

          const answersStr = JSON.stringify(log?.stepAnswers || row.stepAnswers || '').toLowerCase();
          const isRightLeg = answersStr.includes('direito') || key === 'membros_inferiores_d';
          const isLeftLeg = answersStr.includes('esquerdo') || key === 'membros_inferiores_e';
          const isBilateralLeg = answersStr.includes('bilateral');

          if (isBilateralLeg || (isRightLeg && isLeftLeg) || (!isRightLeg && !isLeftLeg)) {
            // Both limbs
            physicalSummary['membros_inferiores_d'] = Math.max(physicalSummary['membros_inferiores_d'] || 0, row.intensity);
            physicalSummary['membros_inferiores_e'] = Math.max(physicalSummary['membros_inferiores_e'] || 0, row.intensity);
          } else if (isRightLeg) {
            physicalSummary['membros_inferiores_d'] = Math.max(physicalSummary['membros_inferiores_d'] || 0, row.intensity);
          } else if (isLeftLeg) {
            physicalSummary['membros_inferiores_e'] = Math.max(physicalSummary['membros_inferiores_e'] || 0, row.intensity);
          }
        }

        if (key === 'muscular_geral_sistemico') {
          physicalSummary['muscular_geral_sistemico'] = Math.max(physicalSummary['muscular_geral_sistemico'] || 0, row.intensity);
        }
      }
    }

    const emotionalSummary = this.buildEmotionalSummary(rows);
    const journalPatterns = this.findJournalPatterns(rows);

    return {
      logs,
      physicalSummary,
      emotionalSummary,
      journalPatterns,
    };
  }

  async deleteHistoryItem(
    userId: string,
    profileId: string,
    id: string,
  ): Promise<{ success: boolean; id: string }> {
    if (!userId) {
      throw new BadRequestException('ID do usuário ausente para exclusão de registro.');
    }
    if (!profileId) {
      throw new BadRequestException('ID do perfil ausente para exclusão de registro.');
    }
    if (!id) {
      throw new BadRequestException('ID do registro ausente.');
    }

    return this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.current_user_id', ${userId}, true)`);
      const [existing] = await tx
        .select()
        .from(symptomLogs)
        .where(
          and(
            eq(symptomLogs.id, id),
            eq(symptomLogs.profileId, profileId),
          ),
        );

      if (!existing) {
        throw new NotFoundException('Registro de histórico não encontrado.');
      }

      await tx
        .delete(symptomLogs)
        .where(
          and(
            eq(symptomLogs.id, id),
            eq(symptomLogs.profileId, profileId),
          ),
        );

      return { success: true, id };
    });
  }

  private buildEmotionalSummary(rows: Array<typeof symptomLogs.$inferSelect>): EmotionalDayDataDto[] {
    const result: EmotionalDayDataDto[] = [];
    const now = new Date();

    for (let i = 6; i >= 0; i--) {
      const dayDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      const dayString = dayDate.toISOString().slice(0, 10);

      const dimensions: Record<string, number> = {};
      for (const dim of EMOTIONAL_DIMENSION_KEYS) {
        dimensions[dim] = 0;
      }

      for (const row of rows) {
        if (!row.emotionalDimension) continue;
        const rowDay = row.recordedAt.toISOString().slice(0, 10);
        if (rowDay === dayString) {
          const dimKey = row.emotionalDimension;
          dimensions[dimKey] = Math.max(dimensions[dimKey] || 0, row.intensity);
        }
      }

      result.push({
        date: dayString,
        dimensions,
      });
    }

    return result;
  }

  /**
   * "Padrões nos seus registros": counts, per category, the entries the person logged
   * with high intensity (their own rating) in the last 10 days. Descriptive only.
   */
  private findJournalPatterns(
    rows: Array<typeof symptomLogs.$inferSelect>,
  ): JournalPatternDto[] {
    const windowStart = new Date(Date.now() - JOURNAL_PATTERN_WINDOW_DAYS * 24 * 60 * 60 * 1000);
    const counts = new Map<string, JournalPatternDto>();

    const count = (category: string | null, vertical: JournalPatternDto['vertical']) => {
      if (!category) return;
      const key = `${vertical}:${category}`;
      const pattern = counts.get(key) ?? { category, vertical, count: 0, windowDays: JOURNAL_PATTERN_WINDOW_DAYS };
      pattern.count += 1;
      counts.set(key, pattern);
    };

    for (const row of rows) {
      if (row.recordedAt < windowStart || row.intensity < HIGH_REPORTED_INTENSITY) continue;
      count(row.emotionalDimension, 'emotional');
      count(row.anatomicalSystem, 'physical');
    }

    const patterns = [...counts.values()].filter((p) => p.count >= JOURNAL_PATTERN_MIN_COUNT);
    // Emotional first, as before, so the app's ordering does not change.
    return [
      ...patterns.filter((p) => p.vertical === 'emotional'),
      ...patterns.filter((p) => p.vertical === 'physical'),
    ];
  }
}
