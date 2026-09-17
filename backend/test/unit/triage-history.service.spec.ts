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

    const result = await service.getHistory('usr-1', { days: 14 });

    expect(result.logs).toHaveLength(0);
    expect(result.physicalSummary.cabeca_pescoco).toBe(0);
    expect(result.emotionalSummary).toHaveLength(7);
    expect(result.criticalRecurrences).toHaveLength(0);
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

    const result = await service.getHistory('usr-1', { days: 14 });

    expect(result.logs).toHaveLength(3);
    expect(result.physicalSummary.cabeca_pescoco).toBe(4);
    expect(result.physicalSummary.coluna_dorsal).toBe(5);
    expect(result.physicalSummary.cardiovascular_torax).toBe(0);
    expect(result.logs[0].stepAnswers).toEqual({ causes: 'stress' });
  });

  it('3. detects critical recurrences when dimension intensity >= 4 on multiple days (DASH-04)', async () => {
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

    const result = await service.getHistory('usr-1', { days: 14 });

    expect(result.criticalRecurrences.length).toBeGreaterThan(0);
    const recurrence = result.criticalRecurrences[0];
    expect(recurrence.vertical).toBe('emotional');
    expect(recurrence.category).toBe('estresse_burnout');
    expect(recurrence.title).toContain('Foco de Atenção');
    expect(recurrence.intensity).toBe(4);
    expect(recurrence.frequencyCount).toBe(2);
    expect(recurrence.recommendedArticleTitle).toBeDefined();
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

    const result = await service.deleteHistoryItem('usr-1', 'log-delete-1');

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

    await expect(service.deleteHistoryItem('usr-1', 'non-existent-log')).rejects.toThrow(
      'Registro de histórico não encontrado.',
    );
  });
});
