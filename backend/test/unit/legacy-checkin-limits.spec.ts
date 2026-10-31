import 'reflect-metadata';
import { describe, it, expect, vi } from 'vitest';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { SubmitTriageDto } from '../../src/modules/triage/dto/triage-outcome.dto';
import { SubmitDailyCheckInDto } from '../../src/modules/triage/dto/daily-checkin.dto';
import { CheckRecurrenceDto } from '../../src/modules/triage/dto/antiburla.dto';
import {
  JournalSuggestService,
  SUGGEST_LIMITS,
  SuggestRateLimiter,
} from '../../src/modules/journal/journal-suggest.service';

const errorsOf = (cls: any, body: object) => validateSync(plainToInstance(cls, body) as object);

describe('Old check-in routes: text limits', () => {
  it('accepts a normal outcome and rejects a huge narrative or answers object', () => {
    const ok = { vertical: 'physical', answers: { 0: 'cabeca', 1: 'hoje', 2: '3' }, narrative: 'dor de cabeça' };
    expect(errorsOf(SubmitTriageDto, ok)).toHaveLength(0);
    expect(errorsOf(SubmitTriageDto, { ...ok, narrative: 'a'.repeat(2001) })).not.toHaveLength(0);
    const many = Object.fromEntries(Array.from({ length: 21 }, (_, i) => [i, 'x']));
    expect(errorsOf(SubmitTriageDto, { ...ok, answers: many })).not.toHaveLength(0);
    expect(errorsOf(SubmitTriageDto, { ...ok, answers: { 0: 'x'.repeat(201) } })).not.toHaveLength(0);
    expect(errorsOf(SubmitTriageDto, { ...ok, clientSessionId: 'c'.repeat(129) })).not.toHaveLength(0);
  });

  it('caps the daily check-in text and the recurrence fields', () => {
    const ok = { emotionalStatus: 'soSo', physicalStatus: 'goodNormal', naturalLanguageText: 'cansado' };
    expect(errorsOf(SubmitDailyCheckInDto, ok)).toHaveLength(0);
    expect(errorsOf(SubmitDailyCheckInDto, { ...ok, naturalLanguageText: 'a'.repeat(2001) })).not.toHaveLength(0);
    const rec = { vertical: 'physical', category: 'cabeca_pescoco', selectedPersistence: 'comecou_hoje' };
    expect(errorsOf(CheckRecurrenceDto, rec)).toHaveLength(0);
    expect(errorsOf(CheckRecurrenceDto, { ...rec, category: 'c'.repeat(65) })).not.toHaveLength(0);
  });
});

describe('AI suggestion: per-user cap', () => {
  it('allows the per-minute limit, then blocks until the minute passes', () => {
    let now = 0;
    const limiter = new SuggestRateLimiter(() => now);
    for (let i = 0; i < SUGGEST_LIMITS.perMinute; i++) expect(limiter.tryConsume('u1')).toBe(true);
    expect(limiter.tryConsume('u1')).toBe(false);
    expect(limiter.tryConsume('u2')).toBe(true);
    now += 60_000;
    expect(limiter.tryConsume('u1')).toBe(true);
  });

  it('stops at the daily limit', () => {
    let now = 0;
    const limiter = new SuggestRateLimiter(() => now);
    let allowed = 0;
    for (let i = 0; i < SUGGEST_LIMITS.perDay + 50; i++) {
      if (limiter.tryConsume('u1')) allowed++;
      now += 7_000;
    }
    expect(allowed).toBe(SUGGEST_LIMITS.perDay);
  });

  it('does not call Gemini once the user is over the limit', async () => {
    const generateJson = vi.fn().mockResolvedValue({ optionKey: 'futuro.medo.desanimo' });
    const service = new JournalSuggestService({ isAvailable: true, generateJson } as any);
    for (let i = 0; i < SUGGEST_LIMITS.perMinute; i++) {
      await service.suggest('desanimado', 'emotional', undefined, undefined, 'user-1');
    }
    expect(await service.suggest('desanimado', 'emotional', undefined, undefined, 'user-1')).toEqual({ optionKey: null });
    expect(generateJson).toHaveBeenCalledTimes(SUGGEST_LIMITS.perMinute);
  });
});
