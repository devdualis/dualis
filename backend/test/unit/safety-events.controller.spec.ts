import { describe, it, expect, vi, beforeEach } from 'vitest';
import { HttpException, HttpStatus } from '@nestjs/common';
import { RateLimiter } from '../../src/common/http/rate-limiter';
import { SafetyEventsController } from '../../src/modules/safety/safety-events.controller';

describe('SafetyEventsController limits', () => {
  let controller: SafetyEventsController;
  let service: { recordSafetyEvent: ReturnType<typeof vi.fn>; recordLegacyEmergencyEvent: ReturnType<typeof vi.fn> };

  const dto = { action: 'opened_resources', clientTimestamp: '2026-10-31T12:00:00.000Z' } as any;
  const legacyDto = { clientTimestamp: '2026-10-31T12:00:00.000Z', actionTaken: 'DIALED_192' } as any;
  const anonymous = (ip: string) => ({ ip });
  const signedIn = (id: string) => ({ ip: '10.0.0.1', user: { id } });

  /** HTTP status of each of `count` calls: 201 when recorded, else the status thrown. */
  const statuses = async (count: number, call: () => Promise<unknown>) => {
    const result: number[] = [];
    for (let i = 0; i < count; i++) {
      try {
        await call();
        result.push(HttpStatus.CREATED);
      } catch (err) {
        result.push((err as HttpException).getStatus());
      }
    }
    return result;
  };

  beforeEach(() => {
    service = {
      recordSafetyEvent: vi.fn().mockResolvedValue({ id: 'evt' }),
      recordLegacyEmergencyEvent: vi.fn().mockResolvedValue({ id: 'evt' }),
    };
    controller = new SafetyEventsController(service as any, new RateLimiter());
  });

  it('takes 10 anonymous calls a minute per IP, then answers 429 without storing', async () => {
    const result = await statuses(11, () => controller.createSafetyEvent(dto, anonymous('203.0.113.7')));

    expect(result.slice(0, 10)).toEqual(Array(10).fill(HttpStatus.CREATED));
    expect(result[10]).toBe(HttpStatus.TOO_MANY_REQUESTS);
    expect(service.recordSafetyEvent).toHaveBeenCalledTimes(10);
  });

  it('caps anonymous calls at 30 a minute in total, whatever the IP', async () => {
    let n = 0;
    const result = await statuses(31, () => controller.createSafetyEvent(dto, anonymous(`198.51.100.${n++}`)));

    expect(result.slice(0, 30)).toEqual(Array(30).fill(HttpStatus.CREATED));
    expect(result[30]).toBe(HttpStatus.TOO_MANY_REQUESTS);
  });

  it('counts the legacy alias against the same limits', async () => {
    const ip = '203.0.113.8';
    await statuses(5, () => controller.createSafetyEvent(dto, anonymous(ip)));
    const result = await statuses(6, () => controller.createLegacyEmergencyEvent(legacyDto, anonymous(ip)));

    expect(result.slice(0, 5)).toEqual(Array(5).fill(HttpStatus.CREATED));
    expect(result[5]).toBe(HttpStatus.TOO_MANY_REQUESTS);
    expect(service.recordLegacyEmergencyEvent).toHaveBeenCalledTimes(5);
  });

  it('takes 30 calls a minute per signed-in account, apart from the anonymous budget', async () => {
    let n = 0;
    await statuses(31, () => controller.createSafetyEvent(dto, anonymous(`192.0.2.${n++}`)));

    const first = await statuses(31, () => controller.createSafetyEvent(dto, signedIn('user-1')));
    const other = await statuses(1, () => controller.createSafetyEvent(dto, signedIn('user-2')));

    expect(first.slice(0, 30)).toEqual(Array(30).fill(HttpStatus.CREATED));
    expect(first[30]).toBe(HttpStatus.TOO_MANY_REQUESTS);
    expect(other).toEqual([HttpStatus.CREATED]);
  });
});
