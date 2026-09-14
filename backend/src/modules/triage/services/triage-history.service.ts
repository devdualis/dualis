import { Injectable, Inject, BadRequestException } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { and, desc, gte, eq, sql } from 'drizzle-orm';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { symptomLogs } from '../../../database/schema';
import {
  CriticalRecurrenceDto,
  EmotionalDayDataDto,
  GetTriageHistoryQueryDto,
  TriageHistoryResponseDto,
  TriageLogItemDto,
} from '../dto/triage-history.dto';

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

const CATEGORY_LABELS: Record<string, string> = {
  cabeca_pescoco: 'Cabeça e Pescoço',
  cardiovascular_torax: 'Cardiovascular / Tórax',
  respiratorio: 'Respiratório',
  gastrointestinal_abdomen: 'Gastrointestinal / Abdômen',
  coluna_dorsal: 'Coluna e Dor Dorsal',
  membros_superiores_d: 'Membros Superiores (D)',
  membros_superiores_e: 'Membros Superiores (E)',
  membros_inferiores_d: 'Membros Inferiores (D)',
  membros_inferiores_e: 'Membros Inferiores (E)',
  neurologico: 'Neurológico',
  geniturinario_pelvico: 'Geniturinário / Pélvico',
  dermatologico: 'Dermatológico',
  ansiosa_agitacao: 'Ansiosa / Agitação',
  depressiva_desanimo: 'Depressiva / Desânimo',
  estresse_burnout: 'Estresse / Burnout',
  somatica: 'Somática (Psicossomática)',
  sono: 'Sono e Ritmo Circadiano',
  cognitiva_foco: 'Cognitiva / Foco',
  autoestima: 'Autoestima / Autoimagem',
};

const RECOMMENDED_ARTICLES: Record<string, { title: string; url: string }> = {
  estresse_burnout: {
    title: 'Manejo do Burnout e Técnicas de Descompressão Diária',
    url: 'https://dualis.app/artigos/burnout-manejo',
  },
  ansiosa_agitacao: {
    title: 'Protocolos de Respiração Diafragmática na Crise de Ansiedade',
    url: 'https://dualis.app/artigos/ansiedade-respiracao',
  },
  depressiva_desanimo: {
    title: 'Ativação Comportamental e Rotina Saudável',
    url: 'https://dualis.app/artigos/ativacao-comportamental',
  },
  sono: {
    title: 'Guia Completo de Higiene do Sono e Ritmo Circadiano',
    url: 'https://dualis.app/artigos/higiene-sono',
  },
  coluna_dorsal: {
    title: 'Postura Laboral e Exercícios Preventivos para a Coluna',
    url: 'https://dualis.app/artigos/coluna-postura',
  },
  default: {
    title: 'Guia de Prevenção e Autocuidado Consciente',
    url: 'https://dualis.app/artigos/prevencao-autocuidado',
  },
};

@Injectable()
export class TriageHistoryService {
  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
  ) {}

  async getHistory(
    userId: string,
    query?: GetTriageHistoryQueryDto,
  ): Promise<TriageHistoryResponseDto> {
    if (!userId) {
      throw new BadRequestException('ID do usuário ausente para consulta de histórico.');
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
            eq(symptomLogs.userId, userId),
            gte(symptomLogs.recordedAt, cutoffDate),
          ),
        )
        .orderBy(desc(symptomLogs.recordedAt));
    });

    const logs: TriageLogItemDto[] = rows.map((row) => {
      let parsedAnswers: any = null;
      if (row.stepAnswers) {
        try {
          parsedAnswers = JSON.parse(row.stepAnswers);
        } catch {
          parsedAnswers = { raw: row.stepAnswers };
        }
      }
      return {
        id: row.id,
        intensity: row.intensity,
        anatomicalSystem: row.anatomicalSystem,
        emotionalDimension: row.emotionalDimension,
        disposition: row.disposition,
        stepAnswers: parsedAnswers,
        recordedAt: row.recordedAt.toISOString(),
      };
    });

    const physicalSummary: Record<string, number> = {};
    for (const sys of PHYSICAL_SYSTEM_KEYS) {
      physicalSummary[sys] = 0;
    }

    for (const row of rows) {
      if (row.anatomicalSystem) {
        const key = row.anatomicalSystem;
        const currentMax = physicalSummary[key] || 0;
        physicalSummary[key] = Math.max(currentMax, row.intensity);
      }
    }

    const emotionalSummary = this.buildEmotionalSummary(rows);
    const criticalRecurrences = this.evaluateCriticalRecurrences(rows);

    return {
      logs,
      physicalSummary,
      emotionalSummary,
      criticalRecurrences,
    };
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

  private evaluateCriticalRecurrences(
    rows: Array<typeof symptomLogs.$inferSelect>,
  ): CriticalRecurrenceDto[] {
    const recurrences: CriticalRecurrenceDto[] = [];
    const tenDaysAgo = new Date(Date.now() - 10 * 24 * 60 * 60 * 1000);
    const recentRows = rows.filter((r) => r.recordedAt >= tenDaysAgo);

    const emotionalHighCounts: Record<string, { count: number; maxIntensity: number }> = {};
    for (const row of recentRows) {
      if (row.emotionalDimension && row.intensity >= 4) {
        const key = row.emotionalDimension;
        if (!emotionalHighCounts[key]) {
          emotionalHighCounts[key] = { count: 0, maxIntensity: row.intensity };
        }
        emotionalHighCounts[key].count += 1;
        emotionalHighCounts[key].maxIntensity = Math.max(
          emotionalHighCounts[key].maxIntensity,
          row.intensity,
        );
      }
    }

    for (const [key, data] of Object.entries(emotionalHighCounts)) {
      if (data.count >= 2) {
        const label = CATEGORY_LABELS[key] || key;
        const article = RECOMMENDED_ARTICLES[key] || RECOMMENDED_ARTICLES.default;
        recurrences.push({
          id: `recurrence-emotional-${key}`,
          vertical: 'emotional',
          category: key,
          categoryLabel: label,
          title: `Foco de Atenção: ${label}`,
          description: `Identificamos que a sua dimensão ${label} esteve em nível ${data.maxIntensity} em ${data.count} registros nos últimos 10 dias. Considerou ler nosso artigo preventivo?`,
          intensity: data.maxIntensity,
          frequencyCount: data.count,
          windowDays: 10,
          recommendedArticleTitle: article.title,
          recommendedArticleUrl: article.url,
        });
      }
    }

    const physicalHighCounts: Record<string, { count: number; maxIntensity: number }> = {};
    for (const row of recentRows) {
      if (row.anatomicalSystem && row.intensity >= 4) {
        const key = row.anatomicalSystem;
        if (!physicalHighCounts[key]) {
          physicalHighCounts[key] = { count: 0, maxIntensity: row.intensity };
        }
        physicalHighCounts[key].count += 1;
        physicalHighCounts[key].maxIntensity = Math.max(
          physicalHighCounts[key].maxIntensity,
          row.intensity,
        );
      }
    }

    for (const [key, data] of Object.entries(physicalHighCounts)) {
      if (data.count >= 2) {
        const label = CATEGORY_LABELS[key] || key;
        const article = RECOMMENDED_ARTICLES[key] || RECOMMENDED_ARTICLES.default;
        recurrences.push({
          id: `recurrence-physical-${key}`,
          vertical: 'physical',
          category: key,
          categoryLabel: label,
          title: `Foco de Atenção: ${label}`,
          description: `Identificamos que o sistema ${label} esteve com desconforto severo em ${data.count} registros nos últimos 10 dias. Considerou ler nosso artigo preventivo?`,
          intensity: data.maxIntensity,
          frequencyCount: data.count,
          windowDays: 10,
          recommendedArticleTitle: article.title,
          recommendedArticleUrl: article.url,
        });
      }
    }

    return recurrences;
  }
}
