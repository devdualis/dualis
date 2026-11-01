import 'reflect-metadata';
import { describe, it, expect } from 'vitest';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { PutHabitDayDto, HabitDaysQueryDto } from '../../src/modules/habits/dto/habits.dto';
import { assertHabitDay, HabitsService } from '../../src/modules/habits/habits.service';

const errors = (payload: unknown) => validateSync(plainToInstance(PutHabitDayDto, payload), { whitelist: true, forbidNonWhitelisted: true });

describe('Daily habits contract', () => {
  it('accepts independent, nullable answers and empty full replacements', () => {
    for (const payload of [{}, { period: false }, { sleepHours: 'menos_5' }, { sleepQuality: 'mal', moved: false },
      { moved: true, movementMinutes: '30_60' }, { moved: null, movementMinutes: null, period: null }]) {
      expect(errors(payload)).toEqual([]);
    }
  });
  it.each([{ sleepQuality: 'otimo' }, { sleepHours: 8 }, { moved: 'false' }, { period: 1 }, { movementMinutes: '15_30' },
    { moved: null, movementMinutes: '15_30' }, { moved: false, movementMinutes: '15_30' }, { moved: true, movementMinutes: '90' }, { note: 'texto' }])('rejects invalid input %j', (payload) => {
    expect(errors(payload).length).toBeGreaterThan(0);
  });
  it('accepts only real calendar dates inside the inclusive UTC window', () => {
    const now = new Date('2026-10-31T23:59:59Z');
    for (const day of ['2025-10-31', '2026-10-31', '2026-11-01']) expect(() => assertHabitDay(day, now)).not.toThrow();
    for (const day of ['2025-10-30', '2026-11-02', '2026-02-29', '2026-02-30', '2026-13-01', '2026-1-01', '2026-10-31T12:00:00Z', '']) {
      expect(() => assertHabitDay(day, now), day).toThrow();
    }
    expect(() => assertHabitDay('2024-02-29', new Date('2024-03-01'))).not.toThrow();
  });
  it('query days must be an integer in 1..365', () => {
    for (const days of [1, 30, 365]) expect(validateSync(plainToInstance(HabitDaysQueryDto, { days }))).toEqual([]);
    for (const days of [0, 366, 1.5, 'abc']) expect(validateSync(plainToInstance(HabitDaysQueryDto, { days })).length).toBeGreaterThan(0);
  });
  it('service rejects invalid movement and missing profile before touching the database', async () => {
    const service = new HabitsService({} as any);
    const today = new Date().toISOString().slice(0, 10);
    await expect(service.putDay('user', 'profile', today, { movementMinutes: 'ate_15' })).rejects.toMatchObject({ status: 400 });
    await expect(service.listDays('user', '')).rejects.toMatchObject({ status: 400 });
    await expect(service.deleteDay('', 'profile', today)).rejects.toMatchObject({ status: 400 });
  });
});
