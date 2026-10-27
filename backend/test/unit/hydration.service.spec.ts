import { describe, it, expect, beforeEach, vi } from 'vitest';
import { HydrationService } from '../../src/modules/hydration/hydration.service';

describe('HydrationService Unit Tests', () => {
  let service: HydrationService;
  let mockDatabaseService: any;

  beforeEach(() => {
    mockDatabaseService = {
      withRls: vi.fn(),
    };
    service = new HydrationService(mockDatabaseService);
  });

  it('1. logs water intake successfully with RLS context', async () => {
    const mockCreated = {
      id: 'f87a0210-b96e-4402-a7d5-d0ff785cf08b',
      userId: 'usr-1',
      amountMl: 300,
      source: 'quick_chip',
      recordedAt: new Date('2026-09-27T10:00:00Z'),
      createdAt: new Date('2026-09-27T10:00:00Z'),
    };

    const insertValues = vi.fn().mockReturnValue({
      returning: vi.fn().mockResolvedValue([mockCreated]),
    });
    mockDatabaseService.withRls.mockImplementation(async (userId: string, callback: any) => {
      const tx = {
        insert: vi.fn().mockReturnValue({ values: insertValues }),
      };
      return callback(tx);
    });

    const result = await service.logWater('usr-1', 'prof-usr-1', {
      amountMl: 300,
      source: 'quick_chip',
      recordedAt: '2026-09-27T10:00:00Z',
    });

    expect(result.id).toBe(mockCreated.id);
    expect(result.amountMl).toBe(300);
    expect(result.source).toBe('quick_chip');
    expect(mockDatabaseService.withRls).toHaveBeenCalledWith('usr-1', expect.any(Function));
    // Author is the caller, subject is the active profile.
    expect(insertValues).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'usr-1', profileId: 'prof-usr-1' }),
    );
  });

  it('rejects calls without an active profile', async () => {
    await expect(service.getTodayLogs('usr-1', '')).rejects.toThrow('Profile ID is required');
    expect(mockDatabaseService.withRls).not.toHaveBeenCalled();
  });

  it('2. retrieves today logs and calculates todayTotalMl', async () => {
    const today = new Date();
    const mockLogs = [
      {
        id: 'log-1',
        userId: 'usr-1',
        amountMl: 250,
        source: 'manual',
        recordedAt: today,
        createdAt: today,
      },
      {
        id: 'log-2',
        userId: 'usr-1',
        amountMl: 500,
        source: 'quick_chip',
        recordedAt: today,
        createdAt: today,
      },
    ];

    mockDatabaseService.withRls.mockImplementation(async (userId: string, callback: any) => {
      const tx = {
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({
              orderBy: vi.fn().mockResolvedValue(mockLogs),
            }),
          }),
        }),
      };
      return callback(tx);
    });

    const result = await service.getTodayLogs('usr-1', 'prof-usr-1');

    expect(result.todayTotalMl).toBe(750);
    expect(result.logs).toHaveLength(2);
    expect(result.logs[0].amountMl).toBe(250);
    expect(result.logs[1].amountMl).toBe(500);
  });

  it('3. returns 7-day history totals with all days populated', async () => {
    const refDate = new Date('2026-09-27T12:00:00Z');
    const mockLogs = [
      {
        id: 'log-1',
        userId: 'usr-1',
        amountMl: 300,
        source: 'manual',
        recordedAt: new Date('2026-09-27T08:00:00Z'),
        createdAt: new Date('2026-09-27T08:00:00Z'),
      },
      {
        id: 'log-2',
        userId: 'usr-1',
        amountMl: 200,
        source: 'manual',
        recordedAt: new Date('2026-09-26T14:00:00Z'),
        createdAt: new Date('2026-09-26T14:00:00Z'),
      },
    ];

    mockDatabaseService.withRls.mockImplementation(async (userId: string, callback: any) => {
      const tx = {
        select: vi.fn().mockReturnValue({
          from: vi.fn().mockReturnValue({
            where: vi.fn().mockReturnValue({
              orderBy: vi.fn().mockResolvedValue(mockLogs),
            }),
          }),
        }),
      };
      return callback(tx);
    });

    const result = await service.getHistory('usr-1', 'prof-usr-1', 7, '2026-09-27T12:00:00Z');

    expect(Object.keys(result.totals)).toHaveLength(7);
    expect(result.totals['2026-09-27']).toBe(300);
    expect(result.totals['2026-09-26']).toBe(200);
    expect(result.totals['2026-09-25']).toBe(0);
  });

  it('3b. groups by the device day with tzOffset: 22:00 in Brasília stays on that day', async () => {
    const mockLogs = [
      { id: 'a', amountMl: 300, recordedAt: new Date('2026-10-28T01:00:00Z') }, // 27th, 22:00 BRT
      { id: 'b', amountMl: 200, recordedAt: new Date('2026-10-27T12:00:00Z') },
      { id: 'c', amountMl: 100, recordedAt: new Date('2026-10-26T02:30:00Z') }, // 25th, 23:30 BRT
    ];
    const where = vi.fn().mockReturnValue({ orderBy: vi.fn().mockResolvedValue(mockLogs) });
    mockDatabaseService.withRls.mockImplementation(async (_u: string, callback: any) =>
      callback({ select: vi.fn().mockReturnValue({ from: vi.fn().mockReturnValue({ where }) }) }),
    );

    // Wall-clock reference (no zone) is the device's own day.
    const result = await service.getHistory('usr-1', 'prof-usr-1', 3, '2026-10-27T23:00:00.000', -180);

    expect(result.days).toEqual([
      { date: '2026-10-25', totalMl: 100 },
      { date: '2026-10-26', totalMl: 0 },
      { date: '2026-10-27', totalMl: 500 },
    ]);
    // Same instant with a zone resolves to the same local day.
    const zoned = await service.getHistory('usr-1', 'prof-usr-1', 3, '2026-10-28T02:00:00Z', -180);
    expect(Object.keys(zoned.totals)).toEqual(['2026-10-25', '2026-10-26', '2026-10-27']);
  });

  it('4. deletes log by id and userId safely', async () => {
    mockDatabaseService.withRls.mockImplementation(async (userId: string, callback: any) => {
      const tx = {
        delete: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            returning: vi.fn().mockResolvedValue([{ id: 'log-1' }]),
          }),
        }),
      };
      return callback(tx);
    });

    const result = await service.deleteLog('usr-1', 'prof-usr-1', 'log-1');

    expect(result.success).toBe(true);
    expect(result.id).toBe('log-1');
  });
});
