import { describe, it, expect, beforeEach, vi } from 'vitest';
import { AntiburlaService, RecurrenceCheckService } from '../../src/modules/triage/services/antiburla.service';

describe('RecurrenceCheckService Unit Tests (ANTI-01, ANTI-02, UC-01)', () => {
  let service: RecurrenceCheckService;
  let mockDb: any;

  beforeEach(() => {
    mockDb = {
      transaction: vi.fn(),
    };
    service = new RecurrenceCheckService(mockDb);
  });

  it('1. triggers the recurrence check with UC-01 empathetic dialog when identical symptom logged 4 days ago', async () => {
    const fourDaysAgo = new Date(Date.now() - 4 * 24 * 60 * 60 * 1000);
    mockDb.transaction.mockImplementation(async (callback: any) => {
      const tx = {
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({
              orderBy: vi.fn().mockReturnValue({
                limit: vi.fn().mockResolvedValue([
                  {
                    id: 'log-1',
                    userId: 'usr-1',
                    recordedAt: fourDaysAgo,
                    anatomicalSystem: 'coluna_dor_dorsal',
                    emotionalDimension: null,
                  },
                ]),
              }),
            }),
          }),
        }),
      };
      return callback(tx);
    });

    const result = await service.checkHistoricalConsistency('usr-1', 'prof-usr-1', {
      vertical: 'physical',
      category: 'coluna_dor_dorsal',
      selectedPersistence: 'comecou_hoje',
    });

    expect(result.triggered).toBe(true);
    expect(result.daysAgo).toBe(4);
    expect(result.empatheticPrompt).toContain('Notei aqui no seu histórico');
    expect(result.empatheticPrompt).toContain('4 dias');
    expect(result.empatheticPrompt).toContain('completamente novo ou pode ser aquela mesma');
  });

  it('2. does NOT trigger the recurrence check when no logs exist in past 14 days', async () => {
    mockDb.transaction.mockImplementation(async (callback: any) => {
      const tx = {
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({
              orderBy: vi.fn().mockReturnValue({
                limit: vi.fn().mockResolvedValue([]),
              }),
            }),
          }),
        }),
      };
      return callback(tx);
    });

    const result = await service.checkHistoricalConsistency('usr-1', 'prof-usr-1', {
      vertical: 'physical',
      category: 'cabeca_pescoco',
      selectedPersistence: 'comecou_hoje',
    });

    expect(result.triggered).toBe(false);
  });

  it('3. does NOT trigger the recurrence check if user selects persistence other than today', async () => {
    const result = await service.checkHistoricalConsistency('usr-1', 'prof-usr-1', {
      vertical: 'emotional',
      category: 'ansiosa_agitacao',
      selectedPersistence: 'ha_alguns_dias',
    });

    expect(result.triggered).toBe(false);
    expect(mockDb.transaction).not.toHaveBeenCalled();
  });

  it('4. applies no rule based on biological sex (B-13): same result for any userGender', async () => {
    mockDb.transaction.mockImplementation(async (callback: any) => {
      const tx = {
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({
              orderBy: vi.fn().mockReturnValue({
                limit: vi.fn().mockResolvedValue([]),
              }),
            }),
          }),
        }),
      };
      return callback(tx);
    });

    const result = await service.checkHistoricalConsistency('usr-female-1', 'prof-usr-female-1', {
      vertical: 'physical',
      category: 'geniturinario',
      selectedPersistence: 'comecou_hoje',
      userGender: 'feminino',
      narrative: 'Dor aguda no testículo direito',
    });

    expect(result).toEqual({ triggered: false });
    expect(JSON.stringify(result)).not.toMatch(/biological|discord|anat[oô]mica/i);
  });

  it('5. keeps AntiburlaService as an alias of RecurrenceCheckService for existing routes', () => {
    expect(AntiburlaService).toBe(RecurrenceCheckService);
  });
});
