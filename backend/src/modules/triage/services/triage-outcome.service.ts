import { Injectable, Inject, Optional, BadRequestException, Logger } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { sql } from 'drizzle-orm';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { symptomLogs } from '../../../database/schema';
import { EncryptionService } from '../../../common/encryption/encryption.service';
import { Lang, Localized, resolveLang } from '../../../common/i18n/lang';
import { ArticlesCatalogService } from './articles-catalog.service';
import { ArticlesVectorService } from './articles-vector.service';
import { MEDICAL_ARTICLES_SEED } from '../data/medical-articles.seed';
import {
  RecommendedArticleDto,
  SubmitTriageDto,
  TriageOutcomeResponseDto,
} from '../dto/triage-outcome.dto';
import {
  SubmitDailyCheckInDto,
  DailyCheckInResponseDto,
} from '../dto/daily-checkin.dto';

type Vertical = 'physical' | 'emotional';

interface CategoryMapping {
  code: string;
  label: string;
  somaticNormalized: string;
}

// Plain-language names for each category code (plan R3: name the area or mood the
// person picked, never a condition or "system"). Codes are stable identifiers.
export const PHYSICAL_LABELS: Record<string, Localized> = {
  normal: { pt: 'Sem desconforto registrado', en: 'No discomfort logged', es: 'Sin molestias registradas' },
  cabeca_pescoco: { pt: 'Cabeça e pescoço', en: 'Head and neck', es: 'Cabeza y cuello' },
  cardiovascular_torax: { pt: 'Peito', en: 'Chest', es: 'Pecho' },
  respiratorio: { pt: 'Respiração', en: 'Breathing', es: 'Respiración' },
  gastrointestinal_abdomen: { pt: 'Barriga e estômago', en: 'Stomach and belly', es: 'Estómago y vientre' },
  coluna_dor_dorsal: { pt: 'Costas', en: 'Back', es: 'Espalda' },
  membros_superiores: { pt: 'Braços e mãos', en: 'Arms and hands', es: 'Brazos y manos' },
  membros_inferiores: { pt: 'Pernas e pés', en: 'Legs and feet', es: 'Piernas y pies' },
  neurologico: { pt: 'Tontura e equilíbrio', en: 'Dizziness and balance', es: 'Mareo y equilibrio' },
  geniturinario_pelvico: { pt: 'Baixo ventre e urina', en: 'Lower belly and urination', es: 'Bajo vientre y orina' },
  dermatologico: { pt: 'Pele', en: 'Skin', es: 'Piel' },
  muscular_geral_sistemico: { pt: 'Corpo todo', en: 'Whole body', es: 'Todo el cuerpo' },
  endocrino_metabolico: { pt: 'Energia e apetite', en: 'Energy and appetite', es: 'Energía y apetito' },
};

export const EMOTIONAL_LABELS: Record<string, Localized> = {
  normal: { pt: 'Bem emocionalmente', en: 'Feeling good emotionally', es: 'Bien emocionalmente' },
  ansiosa_agitacao: { pt: 'Ansiedade e agitação', en: 'Anxious and restless', es: 'Ansiedad e inquietud' },
  depressiva_desanimo: { pt: 'Pra baixo', en: 'Feeling down', es: 'Decaído(a)' },
  estresse_burnout: { pt: 'Estressado(a) ou esgotado(a)', en: 'Stressed or worn out', es: 'Estresado(a) o agotado(a)' },
  somatica: { pt: 'Emoções sentidas no corpo', en: 'Emotions felt in the body', es: 'Emociones sentidas en el cuerpo' },
  sono: { pt: 'Sono ruim', en: 'Poor sleep', es: 'Dormir mal' },
  cognitiva_foco: { pt: 'Cansaço mental e foco', en: 'Mental tiredness and focus', es: 'Cansancio mental y concentración' },
  autoestima: { pt: 'Autoestima', en: 'Self-esteem', es: 'Autoestima' },
};

// Wizard answers, legacy keys and AI tag keys -> category code.
const PHYSICAL_ALIASES: Record<string, string> = {
  normal: 'normal',
  bem_normal: 'normal',
  cabeca: 'cabeca_pescoco',
  cabeca_pescoco: 'cabeca_pescoco',
  head_neck: 'cabeca_pescoco',
  cardiovascular: 'cardiovascular_torax',
  cardiovascular_torax: 'cardiovascular_torax',
  cardiovascular_chest: 'cardiovascular_torax',
  respiratorio: 'respiratorio',
  respiratory: 'respiratorio',
  abdomen: 'gastrointestinal_abdomen',
  abdomen_estomago: 'gastrointestinal_abdomen',
  gastrointestinal_abdomen: 'gastrointestinal_abdomen',
  gastrointestinal: 'gastrointestinal_abdomen',
  costas: 'coluna_dor_dorsal',
  costas_coluna: 'coluna_dor_dorsal',
  coluna: 'coluna_dor_dorsal',
  coluna_dor_dorsal: 'coluna_dor_dorsal',
  dor_lombar_costas: 'coluna_dor_dorsal',
  lombar: 'coluna_dor_dorsal',
  musculoskeletal_back: 'coluna_dor_dorsal',
  membros_superiores: 'membros_superiores',
  membros_inferiores: 'membros_inferiores',
  articulacoes: 'membros_superiores',
  musculoskeletal_joints: 'membros_superiores',
  neurologico: 'neurologico',
  neurological: 'neurologico',
  geniturinario_pelvico: 'geniturinario_pelvico',
  dermatologico: 'dermatologico',
  muscular_geral_sistemico: 'muscular_geral_sistemico',
  general_somatic: 'muscular_geral_sistemico',
  endocrino_metabolico: 'endocrino_metabolico',
};

const EMOTIONAL_ALIASES: Record<string, string> = {
  normal: 'normal',
  bem_normal: 'normal',
  ansiedade: 'ansiosa_agitacao',
  ansiedade_agitacao: 'ansiosa_agitacao',
  ansiosa_agitacao: 'ansiosa_agitacao',
  anxious_agitation: 'ansiosa_agitacao',
  tristeza: 'depressiva_desanimo',
  tristeza_desanimo: 'depressiva_desanimo',
  depressiva_desanimo: 'depressiva_desanimo',
  depressive_hopelessness: 'depressiva_desanimo',
  estresse: 'estresse_burnout',
  estresse_irritabilidade: 'estresse_burnout',
  estresse_burnout: 'estresse_burnout',
  stress_burnout: 'estresse_burnout',
  somatico: 'somatica',
  somatica: 'somatica',
  sono: 'sono',
  sono_cognitiva: 'sono',
  cansaco: 'sono',
  cansaco_mental: 'cognitiva_foco',
  cognitiva_foco: 'cognitiva_foco',
  emotional_general: 'cognitiva_foco',
  autoestima: 'autoestima',
};

// Detailed body sub-parts picked in the wizard (step 3).
const SUBPARTS: Record<string, { code: string; label: Localized }> = {
  ombro_direito: { code: 'membros_superiores', label: { pt: 'ombro direito', en: 'right shoulder', es: 'hombro derecho' } },
  ombro_esquerdo: { code: 'membros_superiores', label: { pt: 'ombro esquerdo', en: 'left shoulder', es: 'hombro izquierdo' } },
  braco_direito: { code: 'membros_superiores', label: { pt: 'braço direito', en: 'right arm', es: 'brazo derecho' } },
  braco_esquerdo: { code: 'membros_superiores', label: { pt: 'braço esquerdo', en: 'left arm', es: 'brazo izquierdo' } },
  cotovelo_direito: { code: 'membros_superiores', label: { pt: 'cotovelo direito', en: 'right elbow', es: 'codo derecho' } },
  cotovelo_esquerdo: { code: 'membros_superiores', label: { pt: 'cotovelo esquerdo', en: 'left elbow', es: 'codo izquierdo' } },
  antebraco_direito: { code: 'membros_superiores', label: { pt: 'antebraço direito', en: 'right forearm', es: 'antebrazo derecho' } },
  antebraco_esquerdo: { code: 'membros_superiores', label: { pt: 'antebraço esquerdo', en: 'left forearm', es: 'antebrazo izquierdo' } },
  punho_direito: { code: 'membros_superiores', label: { pt: 'punho direito', en: 'right wrist', es: 'muñeca derecha' } },
  punho_esquerdo: { code: 'membros_superiores', label: { pt: 'punho esquerdo', en: 'left wrist', es: 'muñeca izquierda' } },
  mao_dedos_direito: { code: 'membros_superiores', label: { pt: 'mão e dedos direitos', en: 'right hand and fingers', es: 'mano y dedos derechos' } },
  mao_dedos_esquerdo: { code: 'membros_superiores', label: { pt: 'mão e dedos esquerdos', en: 'left hand and fingers', es: 'mano y dedos izquierdos' } },
  membros_superiores_bilateral: { code: 'membros_superiores', label: { pt: 'os dois braços', en: 'both arms', es: 'ambos brazos' } },
  coxa_quadril_direito: { code: 'membros_inferiores', label: { pt: 'coxa ou quadril direito', en: 'right thigh or hip', es: 'muslo o cadera derecha' } },
  coxa_quadril_esquerdo: { code: 'membros_inferiores', label: { pt: 'coxa ou quadril esquerdo', en: 'left thigh or hip', es: 'muslo o cadera izquierda' } },
  joelho_direito: { code: 'membros_inferiores', label: { pt: 'joelho direito', en: 'right knee', es: 'rodilla derecha' } },
  joelho_esquerdo: { code: 'membros_inferiores', label: { pt: 'joelho esquerdo', en: 'left knee', es: 'rodilla izquierda' } },
  canela_panturrilha_direito: { code: 'membros_inferiores', label: { pt: 'canela ou panturrilha direita', en: 'right shin or calf', es: 'espinilla o pantorrilla derecha' } },
  canela_panturrilha_esquerdo: { code: 'membros_inferiores', label: { pt: 'canela ou panturrilha esquerda', en: 'left shin or calf', es: 'espinilla o pantorrilla izquierda' } },
  tornozelo_direito: { code: 'membros_inferiores', label: { pt: 'tornozelo direito', en: 'right ankle', es: 'tobillo derecho' } },
  tornozelo_esquerdo: { code: 'membros_inferiores', label: { pt: 'tornozelo esquerdo', en: 'left ankle', es: 'tobillo izquierdo' } },
  pe_dedos_direito: { code: 'membros_inferiores', label: { pt: 'pé direito', en: 'right foot', es: 'pie derecho' } },
  pe_dedos_esquerdo: { code: 'membros_inferiores', label: { pt: 'pé esquerdo', en: 'left foot', es: 'pie izquierdo' } },
  membros_inferiores_bilateral: { code: 'membros_inferiores', label: { pt: 'as duas pernas', en: 'both legs', es: 'ambas piernas' } },
};

const GENERIC_VERTICAL_LABELS: Record<Vertical, Localized> = {
  physical: { pt: 'Corpo', en: 'Body', es: 'Cuerpo' },
  emotional: { pt: 'Emoções', en: 'Emotions', es: 'Emociones' },
};

const FEELING_WELL: Localized = {
  pt: 'Você registrou que está se sentindo bem.',
  en: 'You logged that you are feeling well.',
  es: 'Registraste que te sientes bien.',
};

const LOGGED_PREFIX: Localized = { pt: 'Você registrou', en: 'You logged', es: 'Registraste' };

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

  private aliasesFor(vertical: Vertical): Record<string, string> {
    return vertical === 'physical' ? PHYSICAL_ALIASES : EMOTIONAL_ALIASES;
  }

  /** Resolves a wizard answer / AI key to its category code, if known. */
  private resolveCode(key: string, vertical: Vertical): string | undefined {
    if (vertical === 'physical' && SUBPARTS[key]) return SUBPARTS[key].code;
    return this.aliasesFor(vertical)[key];
  }

  private describe(code: string, vertical: Vertical, lang: Lang, subPartLabel?: string): CategoryMapping {
    const labels = vertical === 'physical' ? PHYSICAL_LABELS : EMOTIONAL_LABELS;
    const base = labels[code]?.[lang] ?? GENERIC_VERTICAL_LABELS[vertical][lang];
    const label = subPartLabel ? `${base} (${subPartLabel})` : base;
    return {
      code,
      label,
      somaticNormalized: code === 'normal' ? FEELING_WELL[lang] : `${LOGGED_PREFIX[lang]}: ${label}.`,
    };
  }

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
   * Scores the free-text narrative against every article category's keyword set
   * (sourced from the articles seed) so daily check-ins are filed under a category
   * that has matching reading content. Organises the entry only; nothing is assessed.
   */
  private classifyCategory(text: string, vertical: Vertical): string {
    const defaultCategory = vertical === 'physical' ? 'muscular_geral_sistemico' : 'estresse_burnout';
    const normalized = this.normalizeText(text || '');
    if (!normalized) {
      return defaultCategory;
    }

    const candidateCategories = [...new Set(Object.values(this.aliasesFor(vertical)))];

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

  /** Exact alias first, then the loose substring match the wizard has always relied on. */
  private resolveWizardCode(step1: string, vertical: Vertical): string | undefined {
    const exact = this.resolveCode(step1, vertical);
    if (exact) return exact;
    const keys = [
      ...Object.keys(this.aliasesFor(vertical)),
      ...(vertical === 'physical' ? Object.keys(SUBPARTS) : []),
    ];
    const fuzzy = keys.find((k) => step1.includes(k) || k.includes(step1));
    return fuzzy ? this.resolveCode(fuzzy, vertical) : undefined;
  }

  async processOutcome(
    userId: string,
    profileId: string,
    dto: SubmitTriageDto,
  ): Promise<TriageOutcomeResponseDto> {
    if (!userId) {
      throw new BadRequestException('ID do usuário ausente para processamento do registro.');
    }
    if (!profileId) {
      throw new BadRequestException('ID do perfil ausente para processamento do registro.');
    }

    const { vertical, answers, narrative } = dto;
    const lang = resolveLang(dto.language);
    const isZeroIndexed = answers[0] !== undefined || answers['0'] !== undefined;
    const step1 = ((isZeroIndexed ? (answers[0] || answers['0']) : (answers[1] || answers['1'])) || '').toLowerCase();
    const subPart = ((isZeroIndexed ? (answers[2] || answers['2']) : (answers[3] || answers['3'])) || '').toLowerCase();
    const isFeelingWell = step1 === 'normal' || step1 === 'bem_normal';

    const fallbackCode = vertical === 'physical' ? 'muscular_geral_sistemico' : 'estresse_burnout';
    const code = this.resolveWizardCode(step1, vertical) ?? fallbackCode;
    const subPartLabel = vertical === 'physical' && SUBPARTS[subPart] ? SUBPARTS[subPart].label[lang] : undefined;
    const mapping = this.describe(code, vertical, lang, subPartLabel);

    // Intensity is the person's own rating: step 3 (4-step wizard) or step 2 (legacy 3-step).
    let intensityRaw = (answers[3] || answers['3'] || answers[2] || answers['2'] || '').toString();
    const ans3 = (answers[3] ?? answers['3'] ?? '').toString();
    const ans2 = (answers[2] ?? answers['2'] ?? '').toString();
    const isIntensityAnswer = (v: string) =>
      /^[1-5]$/.test(v.trim()) || ['leve_controlavel', 'moderada', 'muito_forte', 'grave', 'crise'].includes(v.toLowerCase().trim());
    if (ans3 && isIntensityAnswer(ans3)) {
      intensityRaw = ans3;
    } else if (ans2 && isIntensityAnswer(ans2)) {
      intensityRaw = ans2;
    }

    let intensityScore = 2;
    if (isFeelingWell) {
      intensityScore = 0;
    } else if (vertical === 'physical') {
      const numeric = parseInt(intensityRaw, 10);
      if (!isNaN(numeric) && numeric >= 1 && numeric <= 5) {
        intensityScore = numeric;
      }
    } else {
      // Emotional wizard options are words on the same self-rated 1-5 scale.
      const lowerRaw = intensityRaw.toLowerCase();
      if (lowerRaw.includes('muito_forte') || lowerRaw.includes('grave') || lowerRaw.includes('crise') || lowerRaw === '4' || lowerRaw === '5') {
        intensityScore = 4;
      } else if (lowerRaw.includes('moderada') || lowerRaw === '3') {
        intensityScore = 3;
      } else if (lowerRaw.includes('leve') || lowerRaw === '1' || lowerRaw === '2') {
        intensityScore = 2;
      }
    }

    let recommendedArticles: RecommendedArticleDto[] = [];
    if (this.articlesVector) {
      recommendedArticles = await this.articlesVector.searchArticles({
        queryText: narrative,
        category: mapping.code,
        vertical,
        language: lang,
      });
    } else if (this.articlesCatalog) {
      recommendedArticles = this.articlesCatalog.getArticlesForCategory(mapping.code, lang);
    }

    const buildResponse = (id: string, intensity: number, recordedAt: Date): TriageOutcomeResponseDto => ({
      id,
      vertical,
      intensityScore: intensity,
      primaryCategory: mapping.code,
      categoryLabel: mapping.label,
      somaticMapping: mapping.somaticNormalized,
      recommendedArticles,
      recordedAt: recordedAt.toISOString(),
    });

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
        return buildResponse(record.id, record.intensity, record.recordedAt);
      }
    }

    const encryptedNarrative = narrative ? this.encryptionService.encrypt(narrative) : null;
    // _entryVertical keeps the submitted vertical so history can tell the primary axis of
    // a cross-tagged entry (stripped again by TriageHistoryService).
    const encryptedStepAnswers = this.encryptionService.encrypt(
      JSON.stringify({ ...answers, _entryVertical: vertical }),
    );

    // disposition and organic_primacy_applied are legacy columns (migration 0015): not written.
    const [savedRecord] = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.current_user_id', ${userId}, true)`);
      return tx
        .insert(symptomLogs)
        .values({
          userId,
          profileId,
          encryptedNarrative,
          intensity: intensityScore,
          anatomicalSystem: vertical === 'physical' ? mapping.code : null,
          emotionalDimension: vertical === 'emotional' ? mapping.code : null,
          stepAnswers: encryptedStepAnswers,
          clientSessionId: dto.clientSessionId || null,
          recordedAt: new Date(),
        })
        .returning();
    });

    return buildResponse(savedRecord.id, intensityScore, savedRecord.recordedAt);
  }

  async recordDailyCheckIn(
    userId: string,
    profileId: string,
    dto: SubmitDailyCheckInDto,
  ): Promise<DailyCheckInResponseDto> {
    if (!userId) {
      throw new BadRequestException('ID do usuário ausente para registro de check-in diário.');
    }
    if (!profileId) {
      throw new BadRequestException('ID do perfil ausente para registro de check-in diário.');
    }

    // Plan B-02: only the declared state (good / so-so / bad) is stored, inside the
    // encrypted payload. No intensity is inferred (0 = not reported) and no care
    // recommendation is produced.
    const narrative = dto.naturalLanguageText?.trim() || '';
    const physicalCategory =
      dto.physicalStatus !== 'goodNormal' ? this.classifyCategory(narrative, 'physical') : null;
    const emotionalCategory =
      dto.emotionalStatus !== 'goodNormal' ? this.classifyCategory(narrative, 'emotional') : null;

    // Only one side reported as not good: that side is the entry's vertical.
    const entryVertical: Vertical | undefined =
      physicalCategory && !emotionalCategory ? 'physical'
        : emotionalCategory && !physicalCategory ? 'emotional'
          : undefined;

    const payload = {
      type: 'daily_checkin',
      emotionalStatus: dto.emotionalStatus,
      physicalStatus: dto.physicalStatus,
      naturalLanguageText: dto.naturalLanguageText || '',
      ...(entryVertical ? { _entryVertical: entryVertical } : {}),
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
          profileId,
          encryptedNarrative,
          intensity: 0,
          anatomicalSystem: physicalCategory,
          emotionalDimension: emotionalCategory,
          stepAnswers: encryptedStepAnswers,
          clientSessionId: null,
          recordedAt: new Date(),
        })
        .returning();
    });

    const userLang = resolveLang(dto.language);
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
      emotionalStatus: dto.emotionalStatus,
      physicalStatus: dto.physicalStatus,
      recordedAt: savedRecord.recordedAt.toISOString(),
      recommendedArticles: recommendedArticles.slice(0, 3),
    };
  }
}
