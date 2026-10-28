import { describe, it, expect, vi } from 'vitest';
import { TriageOutcomeService } from '../../src/modules/triage/services/triage-outcome.service';
import { TriageHistoryService } from '../../src/modules/triage/services/triage-history.service';
import { ArticlesCatalogService } from '../../src/modules/triage/services/articles-catalog.service';

// Plan §5 "Contrato de la API": no journal response may carry an assessment.
const BANNED_KEYS = [
  'careDisposition',
  'disposition',
  'urgencyScore',
  'clinicalConcept',
  'aiClinicalConcept',
  'isEmergencyCandidate',
  'isCritical',
  'organicPrimacyApplied',
  'organicPrimacyNotice',
  'criticalRecurrences',
];

function collectKeys(value: unknown, keys = new Set<string>()): Set<string> {
  if (Array.isArray(value)) {
    value.forEach((v) => collectKeys(v, keys));
  } else if (value && typeof value === 'object') {
    for (const [k, v] of Object.entries(value)) {
      keys.add(k);
      collectKeys(v, keys);
    }
  }
  return keys;
}

function expectNoAssessment(response: unknown) {
  const keys = [...collectKeys(response)];
  for (const banned of BANNED_KEYS) {
    expect(keys, `response must not contain "${banned}"`).not.toContain(banned);
  }
  expect(keys.some((k) => /organicPrimacy|urgency/i.test(k))).toBe(false);
  expect(JSON.stringify(response)).not.toMatch(
    /auto_cuidado|consulta_rotina|pronto_atendimento|emergencia|Primazia|Foco de Atenção/,
  );
}

function insertingDb(row: Record<string, unknown>) {
  return {
    transaction: vi.fn().mockImplementation(async (callback: any) =>
      callback({
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({ limit: vi.fn().mockResolvedValue([row]) }),
          }),
        }),
        insert: vi.fn().mockReturnValue({
          values: vi.fn().mockReturnValue({ returning: vi.fn().mockResolvedValue([row]) }),
        }),
      }),
    ),
  };
}

const encryption = {
  encrypt: (t: string) => `enc:${t}`,
  decrypt: (t: string) => t.replace('enc:', ''),
};

describe('Wellness API contract: outcome, check-in, history and tagging carry no assessment', () => {
  const legacyRow = {
    id: 'log-1',
    userId: 'user-1',
    profileId: 'prof-1',
    intensity: 5,
    anatomicalSystem: 'cardiovascular_torax',
    emotionalDimension: 'estresse_burnout',
    disposition: 'emergencia',
    organicPrimacyApplied: true,
    stepAnswers: null,
    encryptedNarrative: null,
    recordedAt: new Date(),
  };

  const outcomeService = () => {
    const catalog = new ArticlesCatalogService();
    return new TriageOutcomeService(
      insertingDb(legacyRow) as any,
      encryption as any,
      catalog,
      catalog,
    );
  };

  it('outcome (new entry, both verticals in the narrative)', async () => {
    const response = await outcomeService().processOutcome('user-1', 'prof-1', {
      vertical: 'emotional',
      answers: { 1: 'ansiedade', 2: 'comecou_hoje', 3: 'crise' },
      narrative: 'dor no peito e muita ansiedade',
    });
    expectNoAssessment(response);
    expect(response.intensityScore).toBe(4);
  });

  it('outcome (idempotent replay of a legacy row with disposition and organic primacy)', async () => {
    const response = await outcomeService().processOutcome('user-1', 'prof-1', {
      vertical: 'physical',
      answers: { 1: 'cardiovascular', 2: 'comecou_hoje', 3: '5' },
      clientSessionId: 'session-1',
    });
    expectNoAssessment(response);
  });

  it('daily check-in', async () => {
    const response = await outcomeService().recordDailyCheckIn('user-1', 'prof-1', {
      emotionalStatus: 'badSick',
      physicalStatus: 'badSick',
      naturalLanguageText: 'dor no peito',
    });
    expectNoAssessment(response);
    expect(response).not.toHaveProperty('intensity');
  });

  it('history (legacy rows still holding disposition and organic primacy)', async () => {
    const twoDaysAgo = new Date(Date.now() - 2 * 24 * 3600 * 1000);
    const rows = [legacyRow, { ...legacyRow, id: 'log-2', recordedAt: twoDaysAgo }];
    const db = {
      transaction: vi.fn().mockImplementation(async (callback: any) =>
        callback({
          execute: vi.fn().mockResolvedValue(true),
          select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockReturnValue({ orderBy: vi.fn().mockResolvedValue(rows) }),
            }),
          }),
        }),
      ),
    };

    const response = await new TriageHistoryService(db as any).getHistory('user-1', 'prof-1', { days: 14 });
    expectNoAssessment(response);
    expect(response.journalPatterns).toEqual([
      { category: 'estresse_burnout', vertical: 'emotional', count: 2, windowDays: 10 },
      { category: 'cardiovascular_torax', vertical: 'physical', count: 2, windowDays: 10 },
    ]);
  });
});
