import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TriageOutcomeService } from '../../src/modules/triage/services/triage-outcome.service';
import { ArticlesCatalogService } from '../../src/modules/triage/services/articles-catalog.service';
import { AiTaggingService } from '../../src/modules/ai/services/ai-tagging.service';
import { IdiomDictionaryService } from '../../src/modules/ai/services/idiom-dictionary.service';
import type { EntryTagResult } from '../../src/modules/ai/dto/classify-symptom.dto';

describe('TriageOutcomeService Unit Tests', () => {
  let service: TriageOutcomeService;
  let mockDb: any;
  let mockEncryptionService: any;
  let articlesCatalog: ArticlesCatalogService;
  let aiTagging: AiTaggingService;

  beforeEach(() => {
    mockDb = {
      transaction: vi.fn().mockImplementation(async (callback) => {
        const tx = {
          execute: vi.fn().mockResolvedValue(true),
          insert: vi.fn().mockReturnValue({
            values: vi.fn().mockReturnValue({
              returning: vi.fn().mockResolvedValue([
                {
                  id: 'mock-symptom-id-123',
                  userId: 'user-uuid-1',
                  intensity: 3,
                  recordedAt: new Date('2026-09-14T10:00:00Z'),
                },
              ]),
            }),
          }),
        };
        return callback(tx);
      }),
    };

    mockEncryptionService = {
      encrypt: vi.fn().mockImplementation((text) => `encrypted:${text}`),
      decrypt: vi.fn().mockImplementation((text) => text.replace('encrypted:', '')),
    };

    articlesCatalog = new ArticlesCatalogService();
    aiTagging = new AiTaggingService(undefined, new IdiomDictionaryService());

    service = new TriageOutcomeService(
      mockDb,
      mockEncryptionService,
      articlesCatalog,
      articlesCatalog,
      aiTagging,
    );
  });

  it('1. files a physical entry under its area with the intensity the person reported', async () => {
    const outcome = await service.processOutcome('user-1', 'prof-user-1', {
      vertical: 'physical',
      answers: {
        1: 'cabeca',
        2: 'comecou_hoje',
        3: '4',
        4: 'exercicio_intenso',
      },
      narrative: 'Dor de cabeça forte após atividade',
    });

    expect(outcome.vertical).toBe('physical');
    expect(outcome.primaryCategory).toBe('cabeca_pescoco');
    expect(outcome.categoryLabel).toBe('Cabeça e pescoço');
    expect(outcome.intensityScore).toBe(4);
    expect(outcome.recommendedArticles.length).toBeGreaterThan(0);
    expect(outcome.recommendedArticles[0].category).toBe('cabeca_pescoco');
  });

  it('files the record under the active profile with the caller as author', async () => {
    const insertValues = vi.fn().mockReturnValue({
      returning: vi.fn().mockResolvedValue([
        { id: 'mock-symptom-id-123', intensity: 3, recordedAt: new Date('2026-09-14T10:00:00Z') },
      ]),
    });
    mockDb.transaction.mockImplementation(async (callback: any) =>
      callback({ execute: vi.fn().mockResolvedValue(true), insert: vi.fn().mockReturnValue({ values: insertValues }) }),
    );

    await service.processOutcome('user-1', 'prof-dependent-1', {
      vertical: 'physical',
      answers: { 1: 'cabeca', 2: 'comecou_hoje', 3: '2', 4: 'nenhum' },
    });
    await service.recordDailyCheckIn('user-1', 'prof-dependent-1', {
      emotionalStatus: 'goodNormal',
      physicalStatus: 'goodNormal',
    } as any);

    expect(insertValues).toHaveBeenCalledTimes(2);
    for (const [values] of insertValues.mock.calls) {
      expect(values).toMatchObject({ userId: 'user-1', profileId: 'prof-dependent-1' });
    }
  });

  it('rejects an outcome without an active profile', async () => {
    await expect(
      service.processOutcome('user-1', '', { vertical: 'physical', answers: { 1: 'cabeca' } }),
    ).rejects.toThrow('perfil');
  });

  it('2. files an emotional entry under its mood category', async () => {
    const outcome = await service.processOutcome('user-1', 'prof-user-1', {
      vertical: 'emotional',
      answers: {
        1: 'ansiedade',
        2: 'comecou_hoje',
        3: 'leve_controlavel',
        4: 'trabalho_estudos',
      },
    });

    expect(outcome.vertical).toBe('emotional');
    expect(outcome.primaryCategory).toBe('ansiosa_agitacao');
    expect(outcome.intensityScore).toBe(2);
    expect(outcome.recommendedArticles.some((a) => a.category === 'ansiosa_agitacao')).toBe(true);
  });

  it('3. no organic-primacy reasoning: an emotional entry mentioning the body gets no differential note (B-09)', async () => {
    const outcome = await service.processOutcome('user-1', 'prof-user-1', {
      vertical: 'emotional',
      answers: {
        1: 'ansiedade',
        2: 'alguns_dias',
        3: 'leve_controlavel',
      },
      narrative: 'Sinto muita ansiedade e dor muscular nas costas',
    });

    const body = JSON.stringify(outcome);
    expect(body).not.toMatch(/organicPrimacy|Primazia|orgânica|somatiza|descartar/i);
    expect(outcome.intensityScore).toBe(2);
  });

  it('4. the "emotions felt in the body" mood is just a category, with plain-language label', async () => {
    const outcome = await service.processOutcome('user-1', 'prof-user-1', {
      vertical: 'emotional',
      answers: {
        1: 'somatico',
        2: 'comecou_hoje',
        3: 'moderada',
      },
    });

    expect(outcome.primaryCategory).toBe('somatica');
    expect(outcome.categoryLabel).toBe('Emoções sentidas no corpo');
    expect(outcome.recommendedArticles.some((a) => a.category === 'somatica')).toBe(true);
  });

  it('5. keeps a reported 5 as-is, produces no care recommendation and encrypts the narrative', async () => {
    const outcome = await service.processOutcome('user-1', 'prof-user-1', {
      vertical: 'physical',
      answers: {
        1: 'costas',
        2: 'cronica',
        3: '5',
      },
      narrative: 'Dor lombar aguda incapacitante',
    });

    expect(outcome.intensityScore).toBe(5);
    expect(outcome).not.toHaveProperty('careDisposition');
    expect(mockEncryptionService.encrypt).toHaveBeenCalledWith('Dor lombar aguda incapacitante');
    expect(mockDb.transaction).toHaveBeenCalled();
  });

  it('6. recommends articles for both physical and emotional axes when a daily check-in flags both', async () => {
    const outcome = await service.recordDailyCheckIn('user-1', 'prof-user-1', {
      physicalStatus: 'badSick',
      emotionalStatus: 'badSick',
      naturalLanguageText: 'Dor nas costas e muito estresse essa semana',
    });

    expect(outcome.recommendedArticles).toBeDefined();
    expect(
      outcome.recommendedArticles!.some((a) => a.category === 'coluna_dor_dorsal'),
    ).toBe(true);
    expect(
      outcome.recommendedArticles!.some((a) => a.category === 'estresse_burnout'),
    ).toBe(true);
  });

  it('7. classifies daily check-in narratives into every one of the 12 physical dimensions with matching articles', async () => {
    const cases: Array<[string, string]> = [
      ['Estou com dor de cabeça e enxaqueca forte', 'cabeca_pescoco'],
      ['Sinto o coração disparado e batedeira no peito', 'cardiovascular_torax'],
      ['Estou com falta de ar e cansaço ao respirar', 'respiratorio'],
      ['Tenho azia e queimação no estômago', 'gastrointestinal_abdomen'],
      ['Estou com dor nas costas e dor na lombar', 'coluna_dor_dorsal'],
      ['Sinto dor no pulso e tendinite na mão', 'membros_superiores'],
      ['Torci o tornozelo e sinto dor no joelho', 'membros_inferiores'],
      ['Estou com tontura e labirintite', 'neurologico'],
      ['Sinto dor ao urinar e infecção de urina', 'geniturinario_pelvico'],
      ['Estou com coceira na pele e manchas vermelhas', 'dermatologico'],
      ['Meu corpo está quebrado, com fadiga física intensa', 'muscular_geral_sistemico'],
      ['Tenho sede excessiva e perdi muito peso sem motivo', 'endocrino_metabolico'],
    ];

    for (const [naturalLanguageText, expectedCategory] of cases) {
      const outcome = await service.recordDailyCheckIn('user-1', 'prof-user-1', {
        physicalStatus: 'badSick',
        emotionalStatus: 'goodNormal',
        naturalLanguageText,
      });

      expect(outcome.recommendedArticles!.length).toBeGreaterThan(0);
      expect(
        outcome.recommendedArticles!.every((a) => a.category === expectedCategory || a.category === 'geral'),
        `expected "${naturalLanguageText}" to classify as ${expectedCategory}, got ${outcome.recommendedArticles!.map((a) => a.category)}`,
      ).toBe(true);
      expect(outcome.recommendedArticles!.some((a) => a.category === expectedCategory)).toBe(true);
    }
  });

  it('8. classifies daily check-in narratives into every one of the 7 emotional dimensions with matching articles', async () => {
    const cases: Array<[string, string]> = [
      ['Estou com crise de pânico e hiperventilação', 'ansiosa_agitacao'],
      ['Sinto tristeza persistente e vontade de chorar', 'depressiva_desanimo'],
      ['Estou esgotado e sobrecarregado no trabalho', 'estresse_burnout'],
      ['Sinto um nó na garganta por nervoso e aperto no peito emocional', 'somatica'],
      ['Não durmo bem e tenho insônia todas as noites', 'sono'],
      ['Estou com névoa mental, mente lerda e sem foco', 'cognitiva_foco'],
      ['Sinto muita autocrítica severa e sensação de incapacidade', 'autoestima'],
    ];

    for (const [naturalLanguageText, expectedCategory] of cases) {
      const outcome = await service.recordDailyCheckIn('user-1', 'prof-user-1', {
        physicalStatus: 'goodNormal',
        emotionalStatus: 'badSick',
        naturalLanguageText,
      });

      expect(outcome.recommendedArticles!.length).toBeGreaterThan(0);
      expect(
        outcome.recommendedArticles!.every((a) => a.category === expectedCategory || a.category === 'geral'),
        `expected "${naturalLanguageText}" to classify as ${expectedCategory}, got ${outcome.recommendedArticles!.map((a) => a.category)}`,
      ).toBe(true);
      expect(outcome.recommendedArticles!.some((a) => a.category === expectedCategory)).toBe(true);
    }
  });

  it('9. tags a body mention in an emotional entry and shows the same static note to everyone', async () => {
    const outcome = await service.processOutcome('user-1', 'prof-user-1', {
      vertical: 'emotional',
      answers: {
        1: 'ansiedade',
        2: 'comecou_hoje',
        3: 'moderada',
      },
      narrative: 'dor de cabeça',
    });

    expect(outcome.vertical).toBe('emotional');
    expect(outcome.primaryCategory).toBe('ansiosa_agitacao');
    expect(outcome.categoryLabel).toBe('Ansiedade e agitação');
    expect(outcome.secondaryCategoryLabel).toBe('Cabeça e pescoço');
    expect(outcome.secondarySomaticMapping).toBe('Você registrou: Cabeça e pescoço.');
    expect(outcome.isCrossVerticalSomatic).toBe(true);
    expect(outcome.crossVerticalContextNote).toBe(
      'Você registrou sensações no corpo e nas emoções hoje. Se algum desconforto físico persistir ou piorar, converse com um profissional de saúde.',
    );
    expect(outcome.aiMappedLayTerm).toBe('dor de cabeça');
  });

  describe('D-01: user-reported intensity is the only intensity source', () => {
    const tags = (overrides: Partial<EntryTagResult>): EntryTagResult => ({
      isOffTopic: false,
      vertical: 'emotional',
      bodyAreaOrMood: 'stress_burnout',
      layTerm: 'estresse',
      confidence: 0.9,
      source: 'gemini',
      latencyMs: 120,
      ...overrides,
    });

    it('10. physical vertical: cross-vertical secondaryIntensityScore equals the user intensity, not the AI score', async () => {
      vi.spyOn(aiTagging, 'tagWithMetadata').mockResolvedValue(
        tags({ vertical: 'emotional', bodyAreaOrMood: 'stress_burnout' }),
      );

      const outcome = await service.processOutcome('user-1', 'prof-user-1', {
        vertical: 'physical',
        answers: { 1: 'cabeca', 2: 'comecou_hoje', 3: '2' },
        narrative: 'muito estresse no trabalho',
      });

      expect(outcome.intensityScore).toBe(2);
      expect(outcome.secondaryIntensityScore).toBe(2);
      expect(outcome.isCrossVerticalSomatic).toBe(true);
    });

    it('11. emotional vertical: cross-vertical secondaryIntensityScore equals the user intensity, not the AI score', async () => {
      vi.spyOn(aiTagging, 'tagWithMetadata').mockResolvedValue(
        tags({ vertical: 'physical', bodyAreaOrMood: 'head_neck' }),
      );

      const outcome = await service.processOutcome('user-1', 'prof-user-1', {
        vertical: 'emotional',
        answers: { 1: 'ansiedade', 2: 'comecou_hoje', 3: 'leve_controlavel' },
        narrative: 'dor de cabeça',
      });

      expect(outcome.intensityScore).toBe(2);
      expect(outcome.secondaryIntensityScore).toBe(2);
    });

    it('12. what the narrative says changes nothing in the summary: no urgency output', async () => {
      vi.spyOn(aiTagging, 'tagWithMetadata').mockResolvedValue(
        tags({ vertical: 'physical', bodyAreaOrMood: 'cardiovascular_chest' }),
      );

      const outcome = await service.processOutcome('user-1', 'prof-user-1', {
        vertical: 'physical',
        answers: { 1: 'peito', 2: 'comecou_hoje', 3: '2' },
        narrative: 'dor no peito forte',
      });

      expect(outcome.intensityScore).toBe(2);
      expect(outcome).not.toHaveProperty('careDisposition');
      expect(outcome).not.toHaveProperty('isEmergencyCandidate');
    });

    it('13. "feeling well" selection yields intensity 0 and a plain summary', async () => {
      const outcome = await service.processOutcome('user-1', 'prof-user-1', {
        vertical: 'physical',
        answers: { 0: 'normal' },
      });

      expect(outcome.intensityScore).toBe(0);
      expect(outcome.primaryCategory).toBe('normal');
      expect(outcome.categoryLabel).toBe('Sem desconforto registrado');
      expect(outcome.somaticMapping).toBe('Você registrou que está se sentindo bem.');
    });

    it('14. labels follow the requested language', async () => {
      const outcome = await service.processOutcome('user-1', 'prof-user-1', {
        vertical: 'physical',
        answers: { 1: 'membros_superiores', 2: 'comecou_hoje', 3: 'ombro_direito', 4: '3' },
        language: 'en',
      });

      expect(outcome.categoryLabel).toBe('Arms and hands (right shoulder)');
      expect(outcome.somaticMapping).toBe('You logged: Arms and hands (right shoulder).');
    });
  });

  describe('B-01/B-02: nothing assessed is written', () => {
    it('15b. stores the submitted vertical as _entryVertical in the encrypted answers', async () => {
      const insertValues = vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([{ id: 'id-1', intensity: 2, recordedAt: new Date() }]),
      });
      mockDb.transaction.mockImplementation(async (callback: any) =>
        callback({ execute: vi.fn().mockResolvedValue(true), insert: vi.fn().mockReturnValue({ values: insertValues }) }),
      );

      await service.processOutcome('user-1', 'prof-user-1', {
        vertical: 'emotional',
        answers: { 1: 'ansiedade', 2: 'comecou_hoje', 3: 'moderada' },
      });
      await service.recordDailyCheckIn('user-1', 'prof-user-1', {
        emotionalStatus: 'goodNormal',
        physicalStatus: 'soSo',
      });
      await service.recordDailyCheckIn('user-1', 'prof-user-1', {
        emotionalStatus: 'soSo',
        physicalStatus: 'soSo',
      });

      const stored = insertValues.mock.calls.map(([values]) =>
        JSON.parse(values.stepAnswers.replace('encrypted:', '')),
      );
      expect(stored[0]).toMatchObject({ 1: 'ansiedade', _entryVertical: 'emotional' });
      expect(stored[1]).toMatchObject({ _entryVertical: 'physical' });
      expect(stored[2]).not.toHaveProperty('_entryVertical');
    });

    it('15. the entry insert never writes disposition or organic_primacy_applied', async () => {
      const insertValues = vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([{ id: 'id-1', intensity: 4, recordedAt: new Date() }]),
      });
      mockDb.transaction.mockImplementation(async (callback: any) =>
        callback({ execute: vi.fn().mockResolvedValue(true), insert: vi.fn().mockReturnValue({ values: insertValues }) }),
      );

      await service.processOutcome('user-1', 'prof-user-1', {
        vertical: 'physical',
        answers: { 1: 'cabeca', 2: 'comecou_hoje', 3: '5' },
        narrative: 'dor de cabeça',
      });
      await service.recordDailyCheckIn('user-1', 'prof-user-1', {
        emotionalStatus: 'badSick',
        physicalStatus: 'badSick',
      });

      for (const [values] of insertValues.mock.calls) {
        expect(values).not.toHaveProperty('disposition');
        expect(values).not.toHaveProperty('organicPrimacyApplied');
      }
    });

    it('16. quick check-in stores only the declared state, with no inferred intensity or disposition', async () => {
      const insertValues = vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([{ id: 'id-2', intensity: 0, recordedAt: new Date() }]),
      });
      mockDb.transaction.mockImplementation(async (callback: any) =>
        callback({ execute: vi.fn().mockResolvedValue(true), insert: vi.fn().mockReturnValue({ values: insertValues }) }),
      );

      const result = await service.recordDailyCheckIn('user-1', 'prof-user-1', {
        emotionalStatus: 'badSick',
        physicalStatus: 'soSo',
      });

      const [values] = insertValues.mock.calls[0];
      expect(values.intensity).toBe(0);
      expect(JSON.parse(values.stepAnswers.replace('encrypted:', ''))).toMatchObject({
        type: 'daily_checkin',
        emotionalStatus: 'badSick',
        physicalStatus: 'soSo',
      });
      expect(result).not.toHaveProperty('disposition');
      expect(result).not.toHaveProperty('intensity');
      expect(result).toMatchObject({ emotionalStatus: 'badSick', physicalStatus: 'soSo' });
    });
  });
});
