import { describe, it, expect, beforeEach, vi } from 'vitest';
import { SafetyEventsService } from '../../src/modules/safety/safety-events.service';

describe('SafetyEventsService Unit Tests', () => {
  let service: SafetyEventsService;
  let mockDatabaseService: any;
  let anonymousValues: any;
  let anonymousReturning: any;

  const dto = {
    action: 'call_started',
    channel: 'tel:192',
    clientTimestamp: '2026-10-15T12:00:00.000Z',
  } as const;

  beforeEach(() => {
    anonymousReturning = vi.fn();
    anonymousValues = vi.fn().mockReturnValue(
      Object.assign(Promise.resolve(undefined), { returning: anonymousReturning }),
    );
    mockDatabaseService = {
      db: { insert: vi.fn().mockReturnValue({ values: anonymousValues }) },
      withRls: vi.fn(),
    };
    service = new SafetyEventsService(mockDatabaseService);
  });

  const stubAuthenticatedInsert = () => {
    const values = vi.fn().mockReturnValue({
      returning: vi.fn().mockImplementation(async () => [
        { ...values.mock.calls[0][0], id: 'evt-1', createdAt: new Date() },
      ]),
    });
    mockDatabaseService.withRls.mockImplementation(async (_userId: string, callback: any) =>
      callback({ insert: vi.fn().mockReturnValue({ values }) }),
    );
    return values;
  };

  it('records anonymous events without RETURNING and with a server-generated id', async () => {
    const event = await service.recordSafetyEvent(dto, null);

    expect(mockDatabaseService.withRls).not.toHaveBeenCalled();
    // RETURNING would be checked against the SELECT policy and fail for anonymous sessions.
    expect(anonymousReturning).not.toHaveBeenCalled();

    const [inserted] = anonymousValues.mock.calls[0];
    expect(inserted).toMatchObject({ userId: null, profileId: null, action: 'call_started', channel: 'tel:192' });
    expect(inserted.id).toMatch(/^[0-9a-f-]{36}$/);
    expect(event.id).toBe(inserted.id);
    expect(event.profileId).toBeNull();
    expect(event.clientTimestamp).toEqual(new Date(dto.clientTimestamp));
  });

  it('records authenticated events under RLS on the active profile', async () => {
    const values = stubAuthenticatedInsert();

    const event = await service.recordSafetyEvent(dto, 'user-1', 'prof-dependent-1');

    expect(mockDatabaseService.withRls).toHaveBeenCalledWith('user-1', expect.any(Function));
    expect(values).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'user-1', profileId: 'prof-dependent-1' }),
    );
    expect(event.profileId).toBe('prof-dependent-1');
    expect(mockDatabaseService.db.insert).not.toHaveBeenCalled();
  });

  it('never files an anonymous event under a profile', async () => {
    await service.recordSafetyEvent(dto, null, 'prof-dependent-1');

    expect(anonymousValues.mock.calls[0][0].profileId).toBeNull();
  });

  it('stores no channel when none is sent', async () => {
    await service.recordSafetyEvent({ action: 'opened_resources', clientTimestamp: dto.clientTimestamp }, null);

    expect(anonymousValues.mock.calls[0][0].channel).toBeNull();
  });

  it('legacy emergency events keep only opened_resources, the old action as channel and the timestamp', async () => {
    const event = await service.recordLegacyEmergencyEvent(
      {
        triggerCategory: 'chestPainCritical',
        severityLevel: 5,
        sourceVertical: 'PHYSICAL',
        actionTaken: 'DIALED_192',
        clientTimestamp: dto.clientTimestamp,
      },
      null,
    );

    const [inserted] = anonymousValues.mock.calls[0];
    expect(Object.keys(inserted).sort()).toEqual(
      ['action', 'channel', 'clientTimestamp', 'createdAt', 'id', 'profileId', 'userId'],
    );
    expect(inserted).toMatchObject({ action: 'opened_resources', channel: 'DIALED_192' });
    expect(event).not.toHaveProperty('severityLevel');
    expect(event).not.toHaveProperty('triggerCategory');
  });
});
