import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TriageAuditService } from '../../src/modules/triage-audit/triage-audit.service';

describe('TriageAuditService Unit Tests', () => {
  let service: TriageAuditService;
  let mockDatabaseService: any;
  let anonymousValues: any;
  let anonymousReturning: any;

  const dto = {
    triggerCategory: 'chestPainCritical',
    severityLevel: 5,
    sourceVertical: 'PHYSICAL',
    actionTaken: 'DIALED_192',
    clientTimestamp: '2026-10-15T12:00:00.000Z',
  } as any;

  beforeEach(() => {
    anonymousReturning = vi.fn();
    anonymousValues = vi.fn().mockReturnValue(
      Object.assign(Promise.resolve(undefined), { returning: anonymousReturning }),
    );
    mockDatabaseService = {
      db: { insert: vi.fn().mockReturnValue({ values: anonymousValues }) },
      withRls: vi.fn(),
    };
    service = new TriageAuditService(mockDatabaseService);
  });

  it('records anonymous events without RETURNING and with a server-generated id', async () => {
    const event = await service.recordEmergencyEvent(dto, null);

    expect(mockDatabaseService.withRls).not.toHaveBeenCalled();
    // RETURNING would be checked against the SELECT policy and fail for anonymous sessions.
    expect(anonymousReturning).not.toHaveBeenCalled();

    const [inserted] = anonymousValues.mock.calls[0];
    expect(inserted).toMatchObject({ userId: null, profileId: null, severityLevel: 5 });
    expect(inserted.id).toMatch(/^[0-9a-f-]{36}$/);
    expect(event.id).toBe(inserted.id);
    expect(event.profileId).toBeNull();
    expect(event.reportedAt).toEqual(new Date(dto.clientTimestamp));
  });

  it('records authenticated events under RLS on the active profile', async () => {
    const values = vi.fn().mockReturnValue({
      returning: vi.fn().mockImplementation(async () => [
        { ...values.mock.calls[0][0], id: 'evt-1', createdAt: new Date() },
      ]),
    });
    mockDatabaseService.withRls.mockImplementation(async (_userId: string, callback: any) =>
      callback({ insert: vi.fn().mockReturnValue({ values }) }),
    );

    const event = await service.recordEmergencyEvent(dto, 'user-1', 'prof-dependent-1');

    expect(mockDatabaseService.withRls).toHaveBeenCalledWith('user-1', expect.any(Function));
    expect(values).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'user-1', profileId: 'prof-dependent-1' }),
    );
    expect(event.profileId).toBe('prof-dependent-1');
    expect(mockDatabaseService.db.insert).not.toHaveBeenCalled();
  });

  it('never files an anonymous event under a profile', async () => {
    await service.recordEmergencyEvent(dto, null, 'prof-dependent-1');

    expect(anonymousValues.mock.calls[0][0].profileId).toBeNull();
  });
});
