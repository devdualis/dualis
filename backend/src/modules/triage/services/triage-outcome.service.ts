import { Injectable, Inject, Optional, BadRequestException, Logger } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { sql } from 'drizzle-orm';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { symptomLogs } from '../../../database/schema';
import { EncryptionService } from '../../../common/encryption/encryption.service';
import { ArticlesCatalogService } from './articles-catalog.service';
import { ArticlesVectorService } from './articles-vector.service';
import { MEDICAL_ARTICLES_SEED } from '../data/medical-articles.seed';
import { AiTriageService } from '../../ai/services/ai-triage.service';
import { TriageClassificationResult } from '../../ai/dto/classify-symptom.dto';
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
  private readonly logger = new Logger(TriageOutcomeService.name);
  private readonly articlesVector?: ArticlesVectorService;
  private readonly articlesCatalog?: ArticlesCatalogService;

  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
    @Inject(EncryptionService) private readonly encryptionService: EncryptionService,
    @Optional() @Inject(ArticlesVectorService)
    articlesVector?: ArticlesVectorService | ArticlesCatalogService,
    @Optional() @Inject(ArticlesCatalogService)
    articlesCatalog?: ArticlesCatalogService,
    @Optional() @Inject(AiTriageService)
    private readonly aiTriage?: AiTriageService,
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
    // Subpartes detalhadas - Membros Superiores
    ombro_direito: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Ombro Direito)',
      somaticNormalized: 'Dor / Desconforto no ombro direito',
    },
    ombro_esquerdo: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Ombro Esquerdo)',
      somaticNormalized: 'Dor / Desconforto no ombro esquerdo',
    },
    braco_direito: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Braço Direito)',
      somaticNormalized: 'Dor muscular no braço direito',
    },
    braco_esquerdo: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Braço Esquerdo)',
      somaticNormalized: 'Dor muscular no braço esquerdo',
    },
    cotovelo_direito: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Cotovelo Direito)',
      somaticNormalized: 'Dor articular no cotovelo direito',
    },
    cotovelo_esquerdo: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Cotovelo Esquerdo)',
      somaticNormalized: 'Dor articular no cotovelo esquerdo',
    },
    antebraco_direito: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Antebraço Direito)',
      somaticNormalized: 'Dor muscular no antebraço direito',
    },
    antebraco_esquerdo: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Antebraço Esquerdo)',
      somaticNormalized: 'Dor muscular no antebraço esquerdo',
    },
    punho_direito: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Punho Direito)',
      somaticNormalized: 'Dor ou sobrecarga no punho direito',
    },
    punho_esquerdo: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Punho Esquerdo)',
      somaticNormalized: 'Dor ou sobrecarga no punho esquerdo',
    },
    mao_dedos_direito: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Mão e Dedos Direito)',
      somaticNormalized: 'Desconforto na mão ou dedos direitos',
    },
    mao_dedos_esquerdo: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Mão e Dedos Esquerdo)',
      somaticNormalized: 'Desconforto na mão ou dedos esquerdos',
    },
    membros_superiores_bilateral: {
      code: 'membros_superiores',
      label: 'Membros Superiores (Bilateral)',
      somaticNormalized: 'Dor musculoarticular em ambos os membros superiores',
    },
    membros_inferiores: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores D/E',
      somaticNormalized: 'Desconforto musculoarticular nos membros inferiores',
    },
    // Subpartes detalhadas - Membros Inferiores
    coxa_quadril_direito: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Coxa / Quadril Direito)',
      somaticNormalized: 'Dor musculoarticular no quadril ou coxa direita',
    },
    coxa_quadril_esquerdo: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Coxa / Quadril Esquerdo)',
      somaticNormalized: 'Dor musculoarticular no quadril ou coxa esquerda',
    },
    joelho_direito: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Joelho Direito)',
      somaticNormalized: 'Dor articular no joelho direito',
    },
    joelho_esquerdo: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Joelho Esquerdo)',
      somaticNormalized: 'Dor articular no joelho esquerdo',
    },
    canela_panturrilha_direito: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Canela / Panturrilha Direita)',
      somaticNormalized: 'Sobrecarga ou dor na panturrilha/canela direita',
    },
    canela_panturrilha_esquerdo: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Canela / Panturrilha Esquerda)',
      somaticNormalized: 'Sobrecarga ou dor na panturrilha/canela esquerda',
    },
    tornozelo_direito: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Tornozelo Direito)',
      somaticNormalized: 'Entorse ou dor no tornozelo direito',
    },
    tornozelo_esquerdo: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Tornozelo Esquerdo)',
      somaticNormalized: 'Entorse ou dor no tornozelo esquerdo',
    },
    pe_dedos_direito: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Pé / Dedos Direito)',
      somaticNormalized: 'Dor no pé ou dedos do pé direito',
    },
    pe_dedos_esquerdo: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Pé / Dedos Esquerdo)',
      somaticNormalized: 'Dor no pé ou dedos do pé esquerdo',
    },
    membros_inferiores_bilateral: {
      code: 'membros_inferiores',
      label: 'Membros Inferiores (Bilateral)',
      somaticNormalized: 'Sobrecarga ou dor musculoarticular em ambos os membros inferiores',
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

  private readonly categoryKeywords: Record<string, string[]> = MEDICAL_ARTICLES_SEED.reduce(
    (acc, article) => {
      if (article.category === 'geral') {
        return acc;
      }
      if (!acc[article.category]) {
        acc[article.category] = [];
      }
      acc[article.category].push(
        this.normalizeText(article.title),
        ...article.keywords.map((k) => this.normalizeText(k)),
      );
      return acc;
    },
    {} as Record<string, string[]>,
  );

  private normalizeText(text: string): string {
    return text
      .toLowerCase()
      .normalize('NFD')
      .replace(/[̀-ͯ]/g, '');
  }

  /**
   * Scores the free-text narrative against every real article category's keyword set
   * (sourced from the medical articles seed) so daily check-ins map to an actual
   * clinical dimension instead of a placeholder category with no matching content.
   */
  private classifyCategory(text: string, vertical: 'physical' | 'emotional'): string {
    const defaultCategory = vertical === 'physical' ? 'muscular_geral_sistemico' : 'estresse_burnout';
    const normalized = this.normalizeText(text || '');
    if (!normalized) {
      return defaultCategory;
    }

    const candidateCategories = [
      ...new Set(
        Object.values(vertical === 'physical' ? this.physicalMappings : this.emotionalMappings).map(
          (m) => m.code,
        ),
      ),
    ];

    let bestCategory = defaultCategory;
    let bestScore = 0;
    for (const category of candidateCategories) {
      const keywords = this.categoryKeywords[category] || [];
      let score = 0;
      for (const keyword of keywords) {
        if (keyword.length >= 3 && normalized.includes(keyword)) {
          score += 1;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    }

    return bestCategory;
  }

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
    const subPart = ((isZeroIndexed ? (answers[2] || answers['2']) : (answers[3] || answers['3'])) || '').toLowerCase();

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
      if (subPart && this.physicalMappings[subPart]) {
        mapping = {
          ...mapping,
          label: this.physicalMappings[subPart].label,
          somaticNormalized: this.physicalMappings[subPart].somaticNormalized,
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

    // Intensity extraction: handles step 3 (new 4-step wizard) or step 2 (legacy 3-step wizard)
    let intensityRaw = (answers[3] || answers['3'] || answers[2] || answers['2'] || '').toString();
    const ans3 = (answers[3] ?? answers['3'] ?? '').toString();
    const ans2 = (answers[2] ?? answers['2'] ?? '').toString();
    if (ans3 && (/^[1-5]$/.test(ans3.trim()) || ['leve_controlavel', 'moderada', 'muito_forte', 'grave', 'crise'].includes(ans3.toLowerCase().trim()))) {
      intensityRaw = ans3;
    } else if (ans2 && (/^[1-5]$/.test(ans2.trim()) || ['leve_controlavel', 'moderada', 'muito_forte', 'grave', 'crise'].includes(ans2.toLowerCase().trim()))) {
      intensityRaw = ans2;
    }

    let intensityScore = 2;
    if (vertical === 'physical') {
      const numeric = parseInt(intensityRaw, 10);
      if (!isNaN(numeric) && numeric >= 1 && numeric <= 5) {
        intensityScore = numeric;
      }
    } else {
      const lowerRaw = intensityRaw.toLowerCase();
      if (lowerRaw.includes('muito_forte') || lowerRaw.includes('grave') || lowerRaw.includes('crise') || lowerRaw === '4' || lowerRaw === '5') {
        intensityScore = 4;
      } else if (lowerRaw.includes('moderada') || lowerRaw === '3') {
        intensityScore = 3;
      } else if (lowerRaw.includes('leve') || lowerRaw === '1' || lowerRaw === '2') {
        intensityScore = 2;
      }
    }

    const userLang = (dto.language || 'pt').toLowerCase();

    let aiMappedLayTerm: string | undefined;
    let aiClinicalConcept: string | undefined;
    let aiSource: TriageOutcomeResponseDto['aiSource'];
    let aiConfidence: number | undefined;
    let classification: TriageClassificationResult | undefined;

    if (this.aiTriage && narrative && narrative.trim().length >= 2) {
      try {
        classification = await this.aiTriage.classify({ text: narrative, language: userLang as any });
        aiMappedLayTerm = classification.mappedLayTerm;
        aiClinicalConcept = classification.clinicalConcept;
        aiSource = classification.source;
        aiConfidence = classification.confidence;
      } catch (err) {
        this.logger.warn(`AI classification of narrative failed: ${(err as Error).message}`);
      }
    }

    let organicPrimacyApplied = false;
    let organicPrimacyNotice: string | undefined;
    let secondaryCategoryLabel: string | undefined;
    let secondarySomaticMapping: string | undefined;
    let secondaryIntensityScore: number | undefined;
    let isCrossVerticalSomatic = false;
    let crossVerticalContextNote: string | undefined;

    const somaticKeywords = ['peito', 'coraç', 'ar', 'respir', 'garganta', 'estômago', 'nó', 'aperto', 'cabeça', 'cabeca', 'dor'];
    const narrativeHasSomatic = narrative && somaticKeywords.some((kw) => narrative.toLowerCase().includes(kw));
    const isPsychosomaticDimension = step1 === 'somatico' || step1 === 'somatica';
    const narrativeIsPhysical = classification?.primaryVertical === 'physical';

    if (vertical === 'emotional') {
      if (narrativeIsPhysical || narrativeHasSomatic || isPsychosomaticDimension) {
        organicPrimacyApplied = true;
        organicPrimacyNotice =
          'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem que causas orgânicas sejam avaliadas presencialmente por um médico antes de atribuí-los unicamente ao estresse psicológico.';
      }

      if (narrativeIsPhysical && classification) {
        const physicalCategory = this.physicalMappings[classification.systemOrDimension];
        if (physicalCategory) {
          secondaryCategoryLabel = physicalCategory.label;
          secondarySomaticMapping = physicalCategory.somaticNormalized;
        } else {
          secondaryCategoryLabel = 'Avaliação Física';
          secondarySomaticMapping = 'Sintoma físico relatado';
        }
        secondaryIntensityScore = intensityScore;
        isCrossVerticalSomatic = true;
        if (userLang === 'es') {
          crossVerticalContextNote =
            'Manifestación física concurrente identificada en el relato. En cuadros de ansiedad y tensión psicomotora, las cefaleas y dolores musculares son frecuentes como somatización, pero requieren valoración médica para descartar causas orgánicas primarias.';
        } else if (userLang === 'en') {
          crossVerticalContextNote =
            'Concurrent physical symptom identified in narrative. In cases of anxiety and psychomotor tension, headaches and muscle tension are common somatic manifestations, but require medical evaluation to rule out primary organic causes.';
        } else {
          crossVerticalContextNote =
            'Manifestação física concorrente identificada no relato. Em quadros de ansiedade e tensão psicomotora, cefaleias e dores musculares são frequentes como somatização, mas exigem avaliação clínica para descartar causas orgânicas primárias.';
        }
      }
    } else if (vertical === 'physical') {
      const narrativeIsEmotional = classification?.primaryVertical === 'emotional';
      if (narrativeIsEmotional && classification) {
        const emotionalCategory = this.emotionalMappings[classification.systemOrDimension];
        if (emotionalCategory) {
          secondaryCategoryLabel = emotionalCategory.label;
          secondarySomaticMapping = emotionalCategory.somaticNormalized;
        } else {
          secondaryCategoryLabel = 'Dimensão Emocional';
          secondarySomaticMapping = 'Componente emocional relatado';
        }
        secondaryIntensityScore = intensityScore;
        isCrossVerticalSomatic = true;
        if (userLang === 'es') {
          crossVerticalContextNote =
            'Factor psicoemocional concurrente identificado en el relato que puede amplificar la percepción del malestar físico.';
        } else if (userLang === 'en') {
          crossVerticalContextNote =
            'Concurrent psycho-emotional factor identified in narrative that may amplify physical discomfort perception.';
        } else {
          crossVerticalContextNote =
            'Fator psicoemocional concorrente identificado no relato que pode amplificar a percepção de desconforto físico.';
        }
      }
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

    if (classification?.isEmergencyCandidate) {
      careDisposition = 'emergencia';
    }

    let recommendedArticles: RecommendedArticleDto[] = [];
    if (this.articlesVector) {
      recommendedArticles = await this.articlesVector.searchArticles({
        queryText: narrative,
        category: mapping.code,
        vertical,
        language: userLang,
      });
    } else if (this.articlesCatalog) {
      recommendedArticles = this.articlesCatalog.getArticlesForCategory(mapping.code, userLang);
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
          secondaryCategoryLabel,
          secondarySomaticMapping,
          secondaryIntensityScore,
          isCrossVerticalSomatic,
          crossVerticalContextNote,
          aiMappedLayTerm,
          aiClinicalConcept,
          aiSource,
          aiConfidence,
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
          anatomicalSystem: vertical === 'physical'
            ? mapping.code
            : (isCrossVerticalSomatic && classification ? classification.systemOrDimension : null),
          emotionalDimension: vertical === 'emotional'
            ? mapping.code
            : (isCrossVerticalSomatic && classification ? classification.systemOrDimension : null),
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
      secondaryCategoryLabel,
      secondarySomaticMapping,
      secondaryIntensityScore,
      isCrossVerticalSomatic,
      crossVerticalContextNote,
      aiMappedLayTerm,
      aiClinicalConcept,
      aiSource,
      aiConfidence,
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

    const narrative = dto.naturalLanguageText?.trim() || '';
    const physicalCategory =
      dto.physicalStatus !== 'goodNormal' ? this.classifyCategory(narrative, 'physical') : null;
    const emotionalCategory =
      dto.emotionalStatus !== 'goodNormal' ? this.classifyCategory(narrative, 'emotional') : null;

    const [savedRecord] = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.current_user_id', ${userId}, true)`);
      return tx
        .insert(symptomLogs)
        .values({
          userId,
          encryptedNarrative,
          intensity,
          anatomicalSystem: physicalCategory,
          emotionalDimension: emotionalCategory,
          disposition,
          organicPrimacyApplied: false,
          stepAnswers: encryptedStepAnswers,
          clientSessionId: null,
          recordedAt: new Date(),
        })
        .returning();
    });

    const userLang = (dto.language || 'pt').toLowerCase();
    let recommendedArticles: RecommendedArticleDto[] = [];
    if (this.articlesVector && narrative.length >= 2) {
      try {
        const searches: Promise<RecommendedArticleDto[]>[] = [];
        if (physicalCategory) {
          searches.push(
            this.articlesVector.searchArticles({
              queryText: narrative,
              category: physicalCategory,
              vertical: 'physical',
              language: userLang,
            }),
          );
        }
        if (emotionalCategory) {
          searches.push(
            this.articlesVector.searchArticles({
              queryText: narrative,
              category: emotionalCategory,
              vertical: 'emotional',
              language: userLang,
            }),
          );
        }

        const resultsPerVertical = await Promise.all(searches);
        const maxLen = Math.max(0, ...resultsPerVertical.map((r) => r.length));
        for (let i = 0; i < maxLen; i++) {
          for (const list of resultsPerVertical) {
            if (list[i]) recommendedArticles.push(list[i]);
          }
        }
      } catch (err) {
        this.logger.warn(`Vector search failed for daily check-in: ${(err as Error).message}`);
      }
    }

    if (recommendedArticles.length === 0 && this.articlesCatalog) {
      const catalogResultsPerVertical: RecommendedArticleDto[][] = [];

      if (physicalCategory) {
        catalogResultsPerVertical.push(this.articlesCatalog.getArticlesForCategory(physicalCategory, userLang));
      }
      if (emotionalCategory) {
        catalogResultsPerVertical.push(this.articlesCatalog.getArticlesForCategory(emotionalCategory, userLang));
      }

      const maxCatalogLen = Math.max(0, ...catalogResultsPerVertical.map((r) => r.length));
      for (let i = 0; i < maxCatalogLen; i++) {
        for (const list of catalogResultsPerVertical) {
          if (list[i]) recommendedArticles.push(list[i]);
        }
      }

      if (recommendedArticles.length === 0) {
        recommendedArticles.push(...this.articlesCatalog.getArticlesForCategory('geral', userLang));
      }
    }

    return {
      id: savedRecord.id,
      intensity,
      disposition,
      emotionalStatus: dto.emotionalStatus,
      physicalStatus: dto.physicalStatus,
      recordedAt: savedRecord.recordedAt.toISOString(),
      recommendedArticles: recommendedArticles.slice(0, 3),
    };
  }
}
