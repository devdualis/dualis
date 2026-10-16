import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TriageHistoryService } from '../../src/modules/triage/services/triage-history.service';

describe('TriageHistoryService Unit Tests (DASH-01, DASH-02, DASH-03, DASH-04, SEC-01)', () => {
  let service: TriageHistoryService;
  let mockDb: any;

  beforeEach(() => {
    mockDb = {
      transaction: vi.fn(),
    };
    service = new TriageHistoryService(mockDb);
  });

  it('1. returns empty summaries when no logs exist in past 14 days', async () => {
    mockDb.transaction.mockImplementation(async (callback: any) => {
      const tx = {
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({
              orderBy: vi.fn().mockResolvedValue([]),
            }),
          }),
        }),
      };
      return callback(tx);
    });

    const result = await service.getHistory('usr-1', 'prof-usr-1', { days: 14 });

    expect(result.logs).toHaveLength(0);
    expect(result.physicalSummary.cabeca_pescoco).toBe(0);
    expect(result.emotionalSummary).toHaveLength(7);
    expect(result.journalPatterns).toHaveLength(0);
  });

  it('2. aggregates physical max intensity per anatomical system (DASH-02)', async () => {
    const today = new Date();
    const mockRows = [
      {
        id: 'log-1',
        userId: 'usr-1',
        intensity: 4,
        anatomicalSystem: 'cabeca_pescoco',
        emotionalDimension: null,
        disposition: 'consulta_rotina',
        stepAnswers: '{"causes":"stress"}',
        recordedAt: today,
        createdAt: today,
        updatedAt: today,
      },
      {
        id: 'log-2',
        userId: 'usr-1',
        intensity: 2,
        anatomicalSystem: 'cabeca_pescoco',
        emotionalDimension: null,
        disposition: 'auto_cuidado',
        stepAnswers: null,
        recordedAt: new Date(today.getTime() - 24 * 3600 * 1000),
        createdAt: today,
        updatedAt: today,
      },
      {
        id: 'log-3',
        userId: 'usr-1',
        intensity: 5,
        anatomicalSystem: 'coluna_dorsal',
        emotionalDimension: null,
        disposition: 'pronto_atendimento',
        stepAnswers: '{"causes":"queda"}',
        recordedAt: new Date(today.getTime() - 48 * 3600 * 1000),
        createdAt: today,
        updatedAt: today,
      },
    ];

    mockDb.transaction.mockImplementation(async (callback: any) => {
      const tx = {
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({
              orderBy: vi.fn().mockResolvedValue(mockRows),
            }),
          }),
        }),
      };
      return callback(tx);
    });

    const result = await service.getHistory('usr-1', 'prof-usr-1', { days: 14 });

    expect(result.logs).toHaveLength(3);
    expect(result.physicalSummary.cabeca_pescoco).toBe(4);
    expect(result.physicalSummary.coluna_dorsal).toBe(5);
    expect(result.physicalSummary.cardiovascular_torax).toBe(0);
    expect(result.logs[0].stepAnswers).toEqual({ causes: 'stress' });
  });

  it('2c. exposes the entry vertical and strips _entryVertical from stepAnswers', async () => {
    const today = new Date();
    const base = { userId: 'usr-1', intensity: 3, recordedAt: today, createdAt: today, updatedAt: today };
    const mockRows = [
      {
        ...base,
        id: 'new-emotional',
        anatomicalSystem: 'cabeca_pescoco',
        emotionalDimension: 'ansiosa_agitacao',
        organicPrimacyApplied: false,
        stepAnswers: '{"1":"ansiedade","_entryVertical":"emotional"}',
      },
      {
        ...base,
        id: 'legacy-emotional',
        anatomicalSystem: 'cabeca_pescoco',
        emotionalDimension: 'ansiosa_agitacao',
        organicPrimacyApplied: true,
        stepAnswers: '{"1":"ansiedade"}',
      },
      {
        ...base,
        id: 'legacy-unknown',
        anatomicalSystem: 'cabeca_pescoco',
        emotionalDimension: null,
        organicPrimacyApplied: false,
        stepAnswers: null,
      },
    ];

    mockDb.transaction.mockImplementation(async (callback: any) =>
      callback({
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({ orderBy: vi.fn().mockResolvedValue(mockRows) }),
          }),
        }),
      }),
    );

    const result = await service.getHistory('usr-1', 'prof-usr-1', { days: 14 });

    expect(result.logs.map((l) => l.vertical)).toEqual(['emotional', 'emotional', null]);
    expect(result.logs[0].stepAnswers).toEqual({ 1: 'ansiedade' });
    expect(result.logs[0].stepAnswers).not.toHaveProperty('_entryVertical');
  });

  it('2b. aggregates upper and lower limbs with side discernment in physicalSummary', async () => {
    const today = new Date();
    const mockRows = [
      {
        id: 'log-arm-right',
        userId: 'usr-1',
        intensity: 3,
        anatomicalSystem: 'membros_superiores',
        emotionalDimension: null,
        disposition: 'consulta_rotina',
        stepAnswers: '{"0":"membros_superiores","1":"comecou_agora","2":"mao_dedos_direito","3":"3"}',
        recordedAt: today,
        createdAt: today,
        updatedAt: today,
      },
      {
        id: 'log-leg-left',
        userId: 'usr-1',
        intensity: 2,
        anatomicalSystem: 'membros_inferiores',
        emotionalDimension: null,
        disposition: 'auto_cuidado',
        stepAnswers: '{"0":"membros_inferiores","1":"comecou_agora","2":"joelho_esquerdo","3":"2"}',
        recordedAt: new Date(today.getTime() - 24 * 3600 * 1000),
        createdAt: today,
        updatedAt: today,
      },
    ];

    mockDb.transaction.mockImplementation(async (callback: any) => {
      const tx = {
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({
              orderBy: vi.fn().mockResolvedValue(mockRows),
            }),
          }),
        }),
      };
      return callback(tx);
    });

    const result = await service.getHistory('usr-1', 'prof-usr-1', { days: 14 });

    expect(result.physicalSummary.membros_superiores).toBe(3);
    expect(result.physicalSummary.membros_superiores_d).toBe(3);
    expect(result.physicalSummary.membros_superiores_e).toBe(0);
    expect(result.physicalSummary.membros_inferiores).toBe(2);
    expect(result.physicalSummary.membros_inferiores_e).toBe(2);
    expect(result.physicalSummary.membros_inferiores_d).toBe(0);
  });

  it('3. reports a descriptive journal pattern when a category was logged with high intensity twice (DASH-04)', async () => {
    const today = new Date();
    const mockRows = [
      {
        id: 'log-burnout-1',
        userId: 'usr-1',
        intensity: 4,
        anatomicalSystem: null,
        emotionalDimension: 'estresse_burnout',
        disposition: 'consulta_rotina',
        stepAnswers: '{"causes":"trabalho"}',
        recordedAt: today,
        createdAt: today,
        updatedAt: today,
      },
      {
        id: 'log-burnout-2',
        userId: 'usr-1',
        intensity: 4,
        anatomicalSystem: null,
        emotionalDimension: 'estresse_burnout',
        disposition: 'consulta_rotina',
        stepAnswers: '{"causes":"trabalho"}',
        recordedAt: new Date(today.getTime() - 2 * 24 * 3600 * 1000),
        createdAt: today,
        updatedAt: today,
      },
    ];

    mockDb.transaction.mockImplementation(async (callback: any) => {
      const tx = {
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({
              orderBy: vi.fn().mockResolvedValue(mockRows),
            }),
          }),
        }),
      };
      return callback(tx);
    });

    const result = await service.getHistory('usr-1', 'prof-usr-1', { days: 14 });

    expect(result.journalPatterns).toEqual([
      { category: 'estresse_burnout', vertical: 'emotional', count: 2, windowDays: 10 },
    ]);
    expect(result).not.toHaveProperty('criticalRecurrences');
    expect(result.logs[0]).not.toHaveProperty('disposition');
    expect(result.logs[0]).not.toHaveProperty('organicPrimacyApplied');
  });

  it('4. deletes existing history item and returns success (LGPD / User Data Discard)', async () => {
    const mockRow = {
      id: 'log-delete-1',
      userId: 'usr-1',
      intensity: 3,
    };

    const deleteMock = vi.fn().mockReturnValue({
      where: vi.fn().mockResolvedValue([{ id: 'log-delete-1' }]),
    });

    mockDb.transaction.mockImplementation(async (callback: any) => {
      const tx = {
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockResolvedValue([mockRow]),
          }),
        }),
        delete: deleteMock,
      };
      return callback(tx);
    });

    const result = await service.deleteHistoryItem('usr-1', 'prof-usr-1', 'log-delete-1');

    expect(result).toEqual({ success: true, id: 'log-delete-1' });
    expect(deleteMock).toHaveBeenCalled();
  });

  it('5. throws NotFoundException when deleting non-existent history item', async () => {
    mockDb.transaction.mockImplementation(async (callback: any) => {
      const tx = {
        execute: vi.fn().mockResolvedValue(true),
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockResolvedValue([]),
          }),
        }),
        delete: vi.fn(),
      };
      return callback(tx);
    });

    await expect(service.deleteHistoryItem('usr-1', 'prof-usr-1', 'non-existent-log')).rejects.toThrow(
      'Registro de histórico não encontrado.',
    );
  });
});
