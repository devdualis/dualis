import 'reflect-metadata';
import { describe, it, expect } from 'vitest';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { AppointmentData } from '../../src/modules/care/care.dto';

const errorsFor = (data: Record<string, unknown>) =>
  validateSync(plainToInstance(AppointmentData, data), { whitelist: true, forbidNonWhitelisted: true });

describe('AppointmentData', () => {
  const base = { startsAt: '2026-11-12T17:30:00.000Z', reminder: '1d' };

  it('accepts the point picked on the map', () => {
    expect(errorsFor({ ...base, place: 'Av. Paulista, 1578', placeLat: -23.5614, placeLng: -46.6559 })).toEqual([]);
  });

  it('rejects coordinates outside the globe', () => {
    expect(errorsFor({ ...base, placeLat: 91, placeLng: -46.6 }).map((e) => e.property)).toEqual(['placeLat']);
    expect(errorsFor({ ...base, placeLat: -23.5, placeLng: 181 }).map((e) => e.property)).toEqual(['placeLng']);
  });
});
