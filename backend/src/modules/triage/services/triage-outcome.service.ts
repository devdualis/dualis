import { Injectable, Inject, Optional, BadRequestException } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { sql } from 'drizzle-orm';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { symptomLogs } from '../../../database/schema';
import { EncryptionService } from '../../../common/encryption/encryption.service';
import { ArticlesCatalogService } from './articles-catalog.service';
import { ArticlesVectorService } from './articles-vector.service';
import {
  CareDisposition,
  RecommendedArticleDto,
  SubmitTriageDto,
  TriageOutcomeResponseDto,
} from '../dto/triage-outcome.dto';
import {
  SubmitDailyCheckInDto,
  DailyCheckInResponseDto,
} from '../dto/daily-checkin.dto';

interface CategoryMapping {
  code: string;
  label: string;
  somaticNormalized: string;
}

@Injectable()
export class TriageOutcomeService {
  private readonly articlesVector?: ArticlesVectorService;
  private readonly articlesCatalog?: ArticlesCatalogService;

  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
    @Inject(EncryptionService) private readonly encryptionService: EncryptionService,
    @Optional() @Inject(ArticlesVectorService)
    articlesVector?: ArticlesVectorService | ArticlesCatalogService,
    @Optional() @Inject(ArticlesCatalogService)
    articlesCatalog?: ArticlesCatalogService,
  ) {
    if (articlesVector && 'searchArticles' in articlesVector) {
      this.articlesVector = articlesVector as ArticlesVectorService;
      this.articlesCatalog = articlesCatalog;
    } else if (articlesVector && 'getArticlesForCategory' in articlesVector) {
      this.articlesCatalog = articlesVector as ArticlesCatalogService;
      this.articlesVector = undefined;
    } else {
      this.articlesVector = (articlesVector as unknown as ArticlesVectorService) ?? undefined;
      this.articlesCatalog = articlesCatalog;
    }
  }

  private readonly physicalMappings: Record<string, CategoryMapping> = {
    cabeca: {
      code: 'cabeca_pescoco',
      label: 'Cabeça e Pescoço',
      somaticNormalized: 'Cefaleia / Desconforto crânio-cervical',
    },
    cabeca_pescoco: {
      code: 'cabeca_pescoco',
      label: 'Cabeça e Pescoço',
      somaticNormalized: 'Cefaleia / Desconforto crânio-cervical',
    },
    head_neck: {
      code: 'cabeca_pescoco',
      label: 'Cabeça e Pescoço',
      somaticNormalized: 'Cefaleia / Desconforto crânio-cervical',
    },
    cardiovascular: {
      code: 'cardiovascular_torax',
      label: 'Cardiovascular e Tórax',
      somaticNormalized: 'Sensação de aperto torácico funcional / Palpitações',
    },
    cardiovascular_torax: {
      code: 'cardiovascular_torax',
      label: 'Cardiovascular e Tórax',
      somaticNormalized: 'Sensação de aperto torácico funcional / Palpitações',
    },
    cardiovascular_chest: {
      code: 'cardiovascular_torax',
      label: 'Cardiovascular e Tórax',
      somaticNormalized: 'Sensação de aperto torácico funcional / Palpitações',
    },
    respiratorio: {
      code: 'respiratorio',
      label: 'Sistema Respiratório',
      somaticNormalized: 'Desconforto respiratório / Dispneia funcional',
    },
    respiratory: {
      code: 'respiratorio',
      label: 'Sistema Respiratório',
      somaticNormalized: 'Desconforto respiratório / Dispneia funcional',
    },
    abdomen: {
      code: 'gastrointestinal_abdomen',
      label: 'Gastrointestinal e Abdômen',
      somaticNormalized: 'Desconforto epigástrico / Dispepsia funcional',
    },
    abdomen_estomago: {
      code: 'gastrointestinal_abdomen',
      label: 'Gastrointestinal e Abdômen',
      somaticNormalized: 'Desconforto epigástrico / Dispepsia funcional',
    },
    gastrointestinal_abdomen: {
      code: 'gastrointestinal_abdomen',
      label: 'Gastrointestinal e Abdômen',
      somaticNormalized: 'Desconforto epigástrico / Dispepsia funcional',
    },
    gastrointestinal: {
      code: 'gastrointestinal_abdomen',
      label: 'Gastrointestinal e Abdômen',
      somaticNormalized: 'Desconforto epigástrico / Dispepsia funcional',
    },
    costas: {
      code: 'coluna_dor_dorsal',
      label: 'Coluna e Dor Dorsal',
      somaticNormalized: 'Dor lombar / Tensão paravertebral postural',
    },
    costas_coluna: {
      code: 'coluna_dor_dorsal',
      label: 'Coluna e Dor Dorsal',
      somaticNormalized: 'Dor lombar / Tensão paravertebral postural',
    },
    coluna: {
      code: 'coluna_dor_dorsal',
      label: 'Coluna e Dor Dorsal',
      somaticNormalized: 'Dor lombar / Tensão paravertebral postural',
    },
    coluna_dor_dorsal: {
      code: 'coluna_dor_dorsal',
      label: 'Coluna e Dor Dorsal',
      somaticNormalized: 'Dor lombar / Tensão paravertebral postural',
    },
    dor_lombar_costas: {
      code: 'coluna_dor_dorsal',
      label: 'Coluna e Dor Dorsal',
      somaticNormalized: 'Dor lombar / Tensão paravertebral postural',
    },
    lombar: {
      code: 'coluna_dor_dorsal',
      label: 'Coluna e Dor Dorsal',
      somaticNormalized: 'Dor lombar / Tensão paravertebral postural',
    },
    musculoskeletal_back: {
      code: 'coluna_dor_dorsal',
      label: 'Coluna e Dor Dorsal',
      somaticNormalized: 'Dor lombar / Tensão paravertebral postural',
    },
    membros_superiores: {
      code: 'membros_superiores',
      label: 'Membros Superiores D/E',
      somaticNormalized: 'Desconforto musculoarticular nos membros superiores',
    },
    membros_inferiores: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores D/E',
      somaticNormalized: 'Desconforto musculoarticular nos membros inferiores',
    },
    articulacoes: {
      code: 'membros_superiores',
      label: 'Membros e Articulações',
      somaticNormalized: 'Artralgia / Desconforto musculoarticular periférico',
    },
    musculoskeletal_joints: {
      code: 'membros_superiores',
      label: 'Membros e Articulações',
      somaticNormalized: 'Artralgia / Desconforto musculoarticular periférico',
    },
    neurologico: {
      code: 'neurologico',
      label: 'Sistema Neurológico',
      somaticNormalized: 'Tontura / Instabilidade postural e equilíbrio',
    },
    neurological: {
      code: 'neurologico',
      label: 'Sistema Neurológico',
      somaticNormalized: 'Tontura / Instabilidade postural e equilíbrio',
    },
    geniturinario_pelvico: {
      code: 'geniturinario_pelvico',
      label: 'Geniturinário e Pélvico',
      somaticNormalized: 'Desconforto pélvico / Queixas urinárias funcionais',
    },
    dermatologico: {
      code: 'dermatologico',
      label: 'Sistema Dermatológico',
      somaticNormalized: 'Prurido cutâneo / Hipersensibilidade dermatológica',
    },
    muscular_geral_sistemico: {
      code: 'muscular_geral_sistemico',
      label: 'Sistema Muscular / Geral Sistêmico',
      somaticNormalized: 'Mialgia difusa / Sobrecarga fisiológica sistêmica',
    },
    general_somatic: {
      code: 'muscular_geral_sistemico',
      label: 'Sistema Muscular / Geral Sistêmico',
      somaticNormalized: 'Mialgia difusa / Sobrecarga fisiológica sistêmica',
    },
    endocrino_metabolico: {
      code: 'endocrino_metabolico',
      label: 'Endócrino e Metabólico',
      somaticNormalized: 'Oscilação metabólica / Desgaste energético',
    },
  };

  private readonly emotionalMappings: Record<string, CategoryMapping> = {
    ansiedade: {
      code: 'ansiosa_agitacao',
      label: 'Dimensão Ansiosa / Agitação',
      somaticNormalized: 'Ansiedade antecipatória / Tensão psicomotora',
    },
    ansiedade_agitacao: {
      code: 'ansiosa_agitacao',
      label: 'Dimensão Ansiosa / Agitação',
      somaticNormalized: 'Ansiedade antecipatória / Tensão psicomotora',
    },
    ansiosa_agitacao: {
      code: 'ansiosa_agitacao',
      label: 'Dimensão Ansiosa / Agitação',
      somaticNormalized: 'Ansiedade antecipatória / Tensão psicomotora',
    },
    anxious_agitation: {
      code: 'ansiosa_agitacao',
      label: 'Dimensão Ansiosa / Agitação',
      somaticNormalized: 'Ansiedade antecipatória / Tensão psicomotora',
    },
    tristeza: {
      code: 'depressiva_desanimo',
      label: 'Dimensão Depressiva / Desânimo',
      somaticNormalized: 'Desânimo transitório / Anedonia leve a moderada',
    },
    tristeza_desanimo: {
      code: 'depressiva_desanimo',
      label: 'Dimensão Depressiva / Desânimo',
      somaticNormalized: 'Desânimo transitório / Anedonia leve a moderada',
    },
    depressiva_desanimo: {
      code: 'depressiva_desanimo',
      label: 'Dimensão Depressiva / Desânimo',
      somaticNormalized: 'Desânimo transitório / Anedonia leve a moderada',
    },
    depressive_hopelessness: {
      code: 'depressiva_desanimo',
      label: 'Dimensão Depressiva / Desânimo',
      somaticNormalized: 'Desânimo transitório / Anedonia leve a moderada',
    },
    estresse: {
      code: 'estresse_burnout',
      label: 'Dimensão Estresse / Burnout',
      somaticNormalized: 'Sobrecarga de estresse cognitivo / Esgotamento funcional',
    },
    estresse_irritabilidade: {
      code: 'estresse_burnout',
      label: 'Dimensão Estresse / Burnout',
      somaticNormalized: 'Sobrecarga de estresse cognitivo / Esgotamento funcional',
    },
    estresse_burnout: {
      code: 'estresse_burnout',
      label: 'Dimensão Estresse / Burnout',
      somaticNormalized: 'Sobrecarga de estresse cognitivo / Esgotamento funcional',
    },
    stress_burnout: {
      code: 'estresse_burnout',
      label: 'Dimensão Estresse / Burnout',
      somaticNormalized: 'Sobrecarga de estresse cognitivo / Esgotamento funcional',
    },
    somatico: {
      code: 'somatica',
      label: 'Dimensão Somática (Psicossomática)',
      somaticNormalized: 'Manifestação somatizada de sobrecarga emocional (nó na garganta / aperto torácico)',
    },
    somatica: {
      code: 'somatica',
      label: 'Dimensão Somática (Psicossomática)',
      somaticNormalized: 'Manifestação somatizada de sobrecarga emocional (nó na garganta / aperto torácico)',
    },
    sono: {
      code: 'sono',
      label: 'Dimensão Sono / Ritmo Circadiano',
      somaticNormalized: 'Privação do descanso fisiológico / Sono não-reparador',
    },
    sono_cognitiva: {
      code: 'sono',
      label: 'Dimensão Sono / Ritmo Circadiano',
      somaticNormalized: 'Privação do descanso fisiológico / Sono não-reparador',
    },
    cansaco: {
      code: 'sono',
      label: 'Dimensão Sono / Ritmo Circadiano',
      somaticNormalized: 'Fadiga mental / Privação do descanso fisiológico',
    },
    cansaco_mental: {
      code: 'cognitiva_foco',
      label: 'Dimensão Cognitiva / Foco',
      somaticNormalized: 'Fadiga mental / Névoa cognitiva e dispersão atencional',
    },
    cognitiva_foco: {
      code: 'cognitiva_foco',
      label: 'Dimensão Cognitiva / Foco',
      somaticNormalized: 'Fadiga mental / Névoa cognitiva e dispersão atencional',
    },
    emotional_general: {
      code: 'cognitiva_foco',
      label: 'Dimensão Cognitiva / Foco',
      somaticNormalized: 'Fadiga mental / Névoa cognitiva e dispersão atencional',
    },
    autoestima: {
      code: 'autoestima',
      label: 'Dimensão Autoestima / Autoimagem',
      somaticNormalized: 'Autocrítica severa / Insegurança situacional',
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
    const isZeroIndexed = answers[0] !== undefined || answers['0'] !== undefined;
    const step1 = ((isZeroIndexed ? (answers[0] || answers['0']) : (answers[1] || answers['1'])) || '').toLowerCase();
    const step3 = (isZeroIndexed ? (answers[2] || answers['2']) : (answers[3] || answers['3'])) || '';

    let mapping: CategoryMapping | undefined;
    if (vertical === 'physical') {
      mapping = this.physicalMappings[step1] ||
        Object.entries(this.physicalMappings).find(([k]) => step1.includes(k) || k.includes(step1))?.[1];
      if (!mapping) {
        mapping = {
          code: 'muscular_geral_sistemico',
          label: 'Avaliação Física Sistêmica',
          somaticNormalized: 'Desconforto corporal geral',
        };
      }
    } else {
      mapping = this.emotionalMappings[step1] ||
        Object.entries(this.emotionalMappings).find(([k]) => step1.includes(k) || k.includes(step1))?.[1];
      if (!mapping) {
        mapping = {
          code: 'estresse_burnout',
          label: 'Dimensão Estresse e Bem-Estar Emocional',
          somaticNormalized: 'Sobrecarga emocional geral',
        };
      }
    }

    let intensityScore = 2;
    if (vertical === 'physical') {
      const numeric = parseInt(step3, 10);
      if (!isNaN(numeric) && numeric >= 1 && numeric <= 5) {
        intensityScore = numeric;
      }
    } else {
      const lower3 = step3.toLowerCase();
      if (lower3.includes('muito_forte') || lower3.includes('grave') || lower3.includes('crise') || lower3 === '4' || lower3 === '5') {
        intensityScore = 4;
      } else if (lower3.includes('moderada') || lower3 === '3') {
        intensityScore = 3;
      } else if (lower3.includes('leve') || lower3 === '1' || lower3 === '2') {
        intensityScore = 2;
      }
    }

    let organicPrimacyApplied = false;
    let organicPrimacyNotice: string | undefined;

    const somaticKeywords = ['peito', 'coraç', 'ar', 'respir', 'garganta', 'estômago', 'nó', 'aperto'];
    const narrativeHasSomatic = narrative && somaticKeywords.some((kw) => narrative.toLowerCase().includes(kw));
    const isPsychosomaticDimension = step1 === 'somatico' || step1 === 'somatica';

    if (vertical === 'emotional' && (narrativeHasSomatic || isPsychosomaticDimension)) {
      organicPrimacyApplied = true;
      organicPrimacyNotice =
        'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem que causas orgânicas sejam avaliadas presencialmente por um médico antes de atribuí-los unicamente ao estresse psicológico.';
    }

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

    if (organicPrimacyApplied && careDisposition === 'auto_cuidado') {
      careDisposition = 'consulta_rotina';
    }

    let recommendedArticles: RecommendedArticleDto[] = [];
    if (this.articlesVector) {
      recommendedArticles = await this.articlesVector.searchArticles({
        queryText: narrative,
        category: mapping.code,
        vertical,
      });
    } else if (this.articlesCatalog) {
      recommendedArticles = this.articlesCatalog.getArticlesForCategory(mapping.code);
    }

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

  async recordDailyCheckIn(
    userId: string,
    dto: SubmitDailyCheckInDto,
  ): Promise<DailyCheckInResponseDto> {
    if (!userId) {
      throw new BadRequestException('ID do usuário ausente para registro de check-in diário.');
    }

    let intensity = 1;
    let disposition: CareDisposition = 'auto_cuidado';
    if (dto.emotionalStatus === 'badSick' || dto.physicalStatus === 'badSick') {
      intensity = 4;
      disposition = 'pronto_atendimento';
    } else if (dto.emotionalStatus === 'soSo' || dto.physicalStatus === 'soSo') {
      intensity = 3;
      disposition = 'consulta_rotina';
    }

    const payload = {
      type: 'daily_checkin',
      emotionalStatus: dto.emotionalStatus,
      physicalStatus: dto.physicalStatus,
      naturalLanguageText: dto.naturalLanguageText || '',
    };

    const encryptedStepAnswers = this.encryptionService.encrypt(JSON.stringify(payload));
    const encryptedNarrative = dto.naturalLanguageText
      ? this.encryptionService.encrypt(dto.naturalLanguageText)
      : null;

    const [savedRecord] = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.current_user_id', ${userId}, true)`);
      return tx
        .insert(symptomLogs)
        .values({
          userId,
          encryptedNarrative,
          intensity,
          anatomicalSystem: dto.physicalStatus !== 'goodNormal' ? 'geral_fisico' : null,
          emotionalDimension: dto.emotionalStatus !== 'goodNormal' ? 'geral_emocional' : null,
          disposition,
          organicPrimacyApplied: false,
          stepAnswers: encryptedStepAnswers,
          clientSessionId: null,
          recordedAt: new Date(),
        })
        .returning();
    });

    return {
      id: savedRecord.id,
      intensity,
      disposition,
      emotionalStatus: dto.emotionalStatus,
      physicalStatus: dto.physicalStatus,
      recordedAt: savedRecord.recordedAt.toISOString(),
    };
  }
}
