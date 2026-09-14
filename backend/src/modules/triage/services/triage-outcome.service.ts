import { Injectable, Inject, BadRequestException } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { sql } from 'drizzle-orm';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { symptomLogs } from '../../../database/schema';
import { EncryptionService } from '../../../common/encryption/encryption.service';
import { ArticlesCatalogService } from './articles-catalog.service';
import {
  CareDisposition,
  SubmitTriageDto,
  TriageOutcomeResponseDto,
} from '../dto/triage-outcome.dto';

interface CategoryMapping {
  code: string;
  label: string;
  somaticNormalized: string;
}

@Injectable()
export class TriageOutcomeService {
  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
    @Inject(EncryptionService) private readonly encryptionService: EncryptionService,
    @Inject(ArticlesCatalogService)
    private readonly articlesCatalog: ArticlesCatalogService,
  ) {}

  private readonly physicalMappings: Record<string, CategoryMapping> = {
    cabeca: {
      code: 'cabeca_pescoco',
      label: 'Cabeça e Pescoço',
      somaticNormalized: 'Cefaleia / Desconforto crânio-cervical',
    },
    costas: {
      code: 'coluna_dor_dorsal',
      label: 'Coluna e Dor Dorsal',
      somaticNormalized: 'Dor lombar / Tensão paravertebral postural',
    },
    articulacoes: {
      code: 'membros_superiores_inferiores',
      label: 'Membros e Articulações',
      somaticNormalized: 'Artralgia / Desconforto musculoarticular periférico',
    },
    abdomen: {
      code: 'gastrointestinal_abdomen',
      label: 'Gastrointestinal e Abdômen',
      somaticNormalized: 'Desconforto epigástrico / Dispepsia funcional',
    },
    cardiovascular: {
      code: 'cardiovascular_torax',
      label: 'Cardiovascular e Tórax',
      somaticNormalized: 'Sensação de aperto torácico funcional / Palpitações',
    },
  };

  private readonly emotionalMappings: Record<string, CategoryMapping> = {
    ansiedade: {
      code: 'ansiosa_agitacao',
      label: 'Dimensão Ansiosa / Agitação',
      somaticNormalized: 'Ansiedade antecipatória / Tensão psicomotora',
    },
    tristeza: {
      code: 'depressiva_desanimo',
      label: 'Dimensão Depressiva / Desânimo',
      somaticNormalized: 'Desânimo transitório / Anedonia leve a moderada',
    },
    estresse: {
      code: 'estresse_burnout',
      label: 'Dimensão Estresse / Burnout',
      somaticNormalized: 'Sobrecarga de estresse cognitivo / Esgotamento funcional',
    },
    cansaco: {
      code: 'sono_cognitiva',
      label: 'Dimensão Sono e Cansaço Mental',
      somaticNormalized: 'Fadiga mental / Privação do descanso fisiológico',
    },
    somatico: {
      code: 'somatica',
      label: 'Dimensão Psicossomática',
      somaticNormalized: 'Manifestação somatizada de sobrecarga emocional (nó na garganta / aperto torácico)',
    },
  };

  async processOutcome(
    userId: string,
    dto: SubmitTriageDto,
  ): Promise<TriageOutcomeResponseDto> {
    if (!userId) {
      throw new BadRequestException('ID do usuário ausente para processamento do desfecho.');
    }

    const { vertical, answers, narrative } = dto;
    const step1 = answers[1]?.toLowerCase() || '';
    const step3 = answers[3] || '';

    // 1. Resolve Category Mapping (SOM-01)
    let mapping: CategoryMapping;
    if (vertical === 'physical') {
      mapping = this.physicalMappings[step1] || {
        code: 'geral',
        label: 'Avaliação Física Sistêmica',
        somaticNormalized: 'Desconforto corporal geral',
      };
    } else {
      mapping = this.emotionalMappings[step1] || {
        code: 'estresse_burnout',
        label: 'Dimensão Estresse e Bem-Estar Emocional',
        somaticNormalized: 'Sobrecarga emocional geral',
      };
    }

    // 2. Calculate Intensity Score (OUT-01)
    let intensityScore = 2; // default
    if (vertical === 'physical') {
      const numeric = parseInt(step3, 10);
      if (!isNaN(numeric) && numeric >= 1 && numeric <= 5) {
        intensityScore = numeric;
      }
    } else {
      if (step3.includes('muito_forte') || step3.includes('grave')) {
        intensityScore = 4;
      } else if (step3.includes('moderada')) {
        intensityScore = 3;
      } else if (step3.includes('leve')) {
        intensityScore = 2;
      }
    }

    // 3. Organic Primacy Protocol (SOM-02)
    // Physical symptoms reported in emotional triage trigger mandatory somatic safety evaluation
    let organicPrimacyApplied = false;
    let organicPrimacyNotice: string | undefined;

    const somaticKeywords = ['peito', 'coraç', 'ar', 'respir', 'garganta', 'estômago', 'nó', 'aperto'];
    const narrativeHasSomatic = narrative && somaticKeywords.some((kw) => narrative.toLowerCase().includes(kw));
    const isPsychosomaticDimension = step1 === 'somatico';

    if (vertical === 'emotional' && (narrativeHasSomatic || isPsychosomaticDimension)) {
      organicPrimacyApplied = true;
      organicPrimacyNotice =
        'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem que causas orgânicas sejam avaliadas presencialmente por um médico antes de atribuí-los unicamente ao estresse psicológico.';
    }

    // 4. Calculate Care Disposition (OUT-01)
    let careDisposition: CareDisposition;
    if (intensityScore <= 2) {
      careDisposition = 'auto_cuidado';
    } else if (intensityScore === 3) {
      careDisposition = 'consulta_rotina';
    } else if (intensityScore === 4) {
      careDisposition = 'pronto_atendimento';
    } else {
      careDisposition = 'emergencia';
    }

    // Organic Primacy guarantee: disposition cannot be downgraded to self-care if organic primacy triggered
    if (organicPrimacyApplied && careDisposition === 'auto_cuidado') {
      careDisposition = 'consulta_rotina';
    }

    // 5. Query Specialist Articles (REC-01)
    const recommendedArticles = this.articlesCatalog.getArticlesForCategory(mapping.code);

    // 5.1 Idempotency Check (SYNC-01)
    if (dto.clientSessionId) {
      const existing = await this.db.transaction(async (tx) => {
        await tx.execute(sql`SELECT set_config('app.current_user_id', ${userId}, true)`);
        return tx
          .select()
          .from(symptomLogs)
          .where(sql`${symptomLogs.userId} = ${userId}::uuid AND ${symptomLogs.clientSessionId} = ${dto.clientSessionId}`)
          .limit(1);
      });

      if (existing.length > 0) {
        const record = existing[0];
        return {
          id: record.id,
          vertical,
          intensityScore: record.intensity,
          careDisposition: (record.disposition as CareDisposition) || careDisposition,
          primaryCategory: mapping.code,
          categoryLabel: mapping.label,
          somaticMapping: mapping.somaticNormalized,
          organicPrimacyApplied: record.organicPrimacyApplied,
          organicPrimacyNotice,
          recommendedArticles,
          recordedAt: record.recordedAt.toISOString(),
        };
      }
    }

    // 6. Encrypt and Persist under RLS
    const encryptedNarrative = narrative ? this.encryptionService.encrypt(narrative) : null;
    const encryptedStepAnswers = this.encryptionService.encrypt(JSON.stringify(answers));

    const [savedRecord] = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.current_user_id', ${userId}, true)`);
      return tx
        .insert(symptomLogs)
        .values({
          userId,
          encryptedNarrative,
          intensity: intensityScore,
          anatomicalSystem: vertical === 'physical' ? mapping.code : null,
          emotionalDimension: vertical === 'emotional' ? mapping.code : null,
          disposition: careDisposition,
          organicPrimacyApplied,
          stepAnswers: encryptedStepAnswers,
          clientSessionId: dto.clientSessionId || null,
          recordedAt: new Date(),
        })
        .returning();
    });

    return {
      id: savedRecord.id,
      vertical,
      intensityScore,
      careDisposition,
      primaryCategory: mapping.code,
      categoryLabel: mapping.label,
      somaticMapping: mapping.somaticNormalized,
      organicPrimacyApplied,
      organicPrimacyNotice,
      recommendedArticles,
      recordedAt: savedRecord.recordedAt.toISOString(),
    };
  }
}
