import { Injectable, Inject, Optional, BadRequestException } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { and, desc, gte, eq, sql } from 'drizzle-orm';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { symptomLogs } from '../../../database/schema';
import { EncryptionService } from '../../../common/encryption/encryption.service';
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
  coluna_dor_dorsal: 'Coluna e Dor Dorsal',
  coluna_dor_lombar: 'Coluna e Dor Lombar',
  membros_superiores_d: 'Membros Superiores (D)',
  membros_superiores_e: 'Membros Superiores (E)',
  membros_inferiores_d: 'Membros Inferiores (D)',
  membros_inferiores_e: 'Membros Inferiores (E)',
  neurologico: 'Neurológico',
  geniturinario_pelvico: 'Geniturinário / Pélvico',
  dermatologico: 'Dermatológico',
  geral_fisico: 'Saúde Física Geral',
  ansiosa_agitacao: 'Ansiosa / Agitação',
  depressiva_desanimo: 'Depressiva / Desânimo',
  estresse_burnout: 'Estresse / Burnout',
  somatica: 'Somática (Psicossomática)',
  sono: 'Sono e Ritmo Circadiano',
  cognitiva_foco: 'Cognitiva / Foco',
  autoestima: 'Autoestima / Autoimagem',
  geral_emocional: 'Saúde Emocional Geral',
  geral: 'Saúde Geral e Bem-Estar',
};

const RECOMMENDED_ARTICLES: Record<string, { title: string; url: string }> = {
  estresse_burnout: {
    title: 'Manejo do Burnout e Técnicas de Descompressão Diária',
    url: 'https://drauziovarella.uol.com.br/psiquiatria/sindrome-de-burnout-esgotamento-profissional/',
  },
  ansiosa_agitacao: {
    title: 'Protocolos de Respiração e Manejo da Ansiedade',
    url: 'https://drauziovarella.uol.com.br/saude-mental/transtornos-de-ansiedade-nao-sao-todos-iguais-entenda-as-caracteristicas-de-cada-tipo/',
  },
  depressiva_desanimo: {
    title: 'Ativação Comportamental e Cuidados na Depressão',
    url: 'https://www.paho.org/pt/topicos/depressao',
  },
  somatica: {
    title: 'Conexão Mente e Corpo: Sintomas Psicossomáticos',
    url: 'https://drauziovarella.uol.com.br/psiquiatria/conexao-entre-mente-e-corpo-como-as-emocoes-afetam-a-saude/',
  },
  sono: {
    title: 'Guia Completo de Higiene do Sono e Ritmo Circadiano',
    url: 'https://drauziovarella.uol.com.br/neurologia/higiene-do-sono-conheca-11-dicas-para-dormir-melhor/',
  },
  cognitiva_foco: {
    title: 'Estímulo Cognitivo, Clareza Mental e Foco',
    url: 'https://drauziovarella.uol.com.br/neurologia/como-estimular-o-cerebro-no-dia-a-dia/',
  },
  autoestima: {
    title: 'Fortalecimento da Autoestima e Bem-Estar Psicológico',
    url: 'https://www.paho.org/pt/topicos/saude-mental',
  },
  geral_emocional: {
    title: 'Guia de Saúde Mental e Equilíbrio Emocional',
    url: 'https://www.paho.org/pt/topicos/saude-mental',
  },
  cabeca_pescoco: {
    title: 'Prevenção de Cefaleias Tensionais e Cuidados Cervicais',
    url: 'https://sbcefaleia.com.br/noticias.php?id=350',
  },
  cardiovascular_torax: {
    title: 'Saúde Cardiovascular e Reconhecimento de Sinais de Alerta',
    url: 'https://drauziovarella.uol.com.br/entrevistas-2/arritmia-cardiaca-entrevista/',
  },
  respiratorio: {
    title: 'Cuidados Respiratórios e Manejo de Falta de Ar',
    url: 'https://sbpt.org.br/portal/publico-geral/doencas/falta-de-ar/',
  },
  gastrointestinal_abdomen: {
    title: 'Saúde Digestiva e Prevenção do Refluxo Gastroesofágico',
    url: 'https://drauziovarella.uol.com.br/gastroenterologia/refluxo-saiba-o-que-e-os-sintomas-e-as-formas-de-tratamento/',
  },
  coluna_dorsal: {
    title: 'Postura Laboral e Exercícios Preventivos para a Coluna',
    url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
  },
  coluna_dor_dorsal: {
    title: 'Postura Laboral e Exercícios Preventivos para a Coluna',
    url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
  },
  coluna_dor_lombar: {
    title: 'Cuidados Posturais e Descompressão Lombar',
    url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
  },
  membros_superiores_d: {
    title: 'Prevenção de Tendinites e Sobrecarga em Braços e Ombros',
    url: 'https://drauziovarella.uol.com.br/podcasts/tendinite/',
  },
  membros_superiores_e: {
    title: 'Prevenção de Tendinites e Sobrecarga em Braços e Ombros',
    url: 'https://drauziovarella.uol.com.br/podcasts/tendinite/',
  },
  membros_inferiores_d: {
    title: 'Prevenção de Lesões Articulares e Entorses',
    url: 'https://sbot.org.br/entorse-de-tornozelo/',
  },
  membros_inferiores_e: {
    title: 'Prevenção de Lesões Articulares e Entorses',
    url: 'https://sbot.org.br/entorse-de-tornozelo/',
  },
  neurologico: {
    title: 'Prevenção e Cuidados com o Sistema Neurológico',
    url: 'https://drauziovarella.uol.com.br/neurologia/neuropatia-periferica-doenca-dos-nervos-exige-atencao-e-controle-das-causas/',
  },
  geniturinario_pelvico: {
    title: 'Saúde do Trato Urinário e Prevenção de Infecções',
    url: 'https://portaldaurologia.org.br/doencas/infeccao-urinaria/',
  },
  dermatologico: {
    title: 'Cuidados com a Barreira Cutânea e Alívio de Irritações',
    url: 'https://www.sbd.org.br/doencas/urticaria/',
  },
  geral_fisico: {
    title: 'Guia de Prevenção e Hábitos para a Saúde Integral',
    url: 'https://www.paho.org/pt/topicos/curso-vida-saudavel',
  },
  geral: {
    title: 'Guia de Prevenção e Autocuidado Consciente',
    url: 'https://www.paho.org/pt/topicos/curso-vida-saudavel',
  },
  default: {
    title: 'Guia de Prevenção e Autocuidado Consciente',
    url: 'https://www.paho.org/pt/topicos/curso-vida-saudavel',
  },
};

@Injectable()
export class TriageHistoryService {
  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
    @Optional() @Inject(EncryptionService)
    private readonly encryptionService?: EncryptionService,
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

      return {
        id: row.id,
        intensity: row.intensity,
        anatomicalSystem: row.anatomicalSystem,
        emotionalDimension: row.emotionalDimension,
        disposition: row.disposition,
        narrative: decryptedNarrative,
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
        if (key === 'coluna_dor_dorsal' || key === 'coluna_dorsal') {
          physicalSummary['coluna_dorsal'] = Math.max(physicalSummary['coluna_dorsal'] || 0, row.intensity);
          physicalSummary['coluna_dor_dorsal'] = Math.max(physicalSummary['coluna_dor_dorsal'] || 0, row.intensity);
        }
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
