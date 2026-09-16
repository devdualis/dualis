import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TriageOutcomeService } from '../../src/modules/triage/services/triage-outcome.service';
import { ArticlesCatalogService } from '../../src/modules/triage/services/articles-catalog.service';

describe('TriageOutcomeService Unit Tests', () => {
  let service: TriageOutcomeService;
  let mockDb: any;
  let mockEncryptionService: any;
  let articlesCatalog: ArticlesCatalogService;

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

    service = new TriageOutcomeService(
      mockDb,
      mockEncryptionService,
      articlesCatalog,
    );
  });

  it('1. correctly normalizes physical symptoms into 12 systems and calculates intensity', async () => {
    const outcome = await service.processOutcome('user-1', {
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
    expect(outcome.categoryLabel).toBe('Cabeça e Pescoço');
    expect(outcome.intensityScore).toBe(4);
    expect(outcome.careDisposition).toBe('pronto_atendimento');
    expect(outcome.organicPrimacyApplied).toBe(false);
    expect(outcome.recommendedArticles.length).toBeGreaterThan(0);
    expect(outcome.recommendedArticles[0].category).toBe('cabeca_pescoco');
  });

  it('2. correctly normalizes psycho-emotional symptoms into 7 dimensions', async () => {
    const outcome = await service.processOutcome('user-1', {
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
    expect(outcome.careDisposition).toBe('auto_cuidado');
    expect(outcome.recommendedArticles.some((a) => a.category === 'ansiosa_agitacao')).toBe(true);
  });

  it('3. strictly enforces Organic Primacy when physical symptoms accompany emotional distress (SOM-02)', async () => {
    const outcome = await service.processOutcome('user-1', {
      vertical: 'emotional',
      answers: {
        1: 'ansiedade',
        2: 'alguns_dias',
        3: 'leve_controlavel',
      },
      narrative: 'Sinto muita ansiedade e um aperto no peito estranho',
    });

    expect(outcome.organicPrimacyApplied).toBe(true);
    expect(outcome.organicPrimacyNotice).toBeDefined();
    expect(outcome.organicPrimacyNotice).toContain('Primazia Orgânica');
    // Care disposition must not be downgraded to auto_cuidado when organic primacy is active
    expect(outcome.careDisposition).toBe('consulta_rotina');
  });

  it('4. triggers Organic Primacy when psychosomatic dimension is directly selected', async () => {
    const outcome = await service.processOutcome('user-1', {
      vertical: 'emotional',
      answers: {
        1: 'somatico',
        2: 'comecou_hoje',
        3: 'moderada',
      },
    });

    expect(outcome.organicPrimacyApplied).toBe(true);
    expect(outcome.primaryCategory).toBe('somatica');
    expect(outcome.recommendedArticles.some((a) => a.category === 'somatica')).toBe(true);
  });

  it('5. maps score 5 to emergencia disposition and encrypts narrative under RLS', async () => {
    const outcome = await service.processOutcome('user-1', {
      vertical: 'physical',
      answers: {
        1: 'costas',
        2: 'cronica',
        3: '5',
      },
      narrative: 'Dor lombar aguda incapacitante',
    });

    expect(outcome.intensityScore).toBe(5);
    expect(outcome.careDisposition).toBe('emergencia');
    expect(mockEncryptionService.encrypt).toHaveBeenCalledWith('Dor lombar aguda incapacitante');
    expect(mockDb.transaction).toHaveBeenCalled();
  });

  it('6. recommends articles for both physical and emotional axes when a daily check-in flags both', async () => {
    const outcome = await service.recordDailyCheckIn('user-1', {
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
      const outcome = await service.recordDailyCheckIn('user-1', {
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
      const outcome = await service.recordDailyCheckIn('user-1', {
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
});
