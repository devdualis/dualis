import { describe, it, expect, vi } from 'vitest';
import { catalogKeys, JournalSuggestService } from '../../src/modules/journal/journal-suggest.service';

describe('JournalSuggestService', () => {
  it('catalog keys are only everyday diary chips, never .custom', () => {
    const emotional = catalogKeys('emotional');
    const physical = catalogKeys('physical');
    expect(emotional).toContain('futuro.medo.desanimo');
    expect(physical).toContain('cabeca.pressao.temporas');
    expect([...emotional, ...physical].every((k) => !k.includes('custom'))).toBe(true);
    expect([...emotional, ...physical].join(' ')).not.toMatch(
      /depressiv|ansios|hopeless|cardiovascular|neurolog/i,
    );
  });

  it('returns null when Gemini is off', async () => {
    const service = new JournalSuggestService(undefined);
    expect(await service.suggest('estou muito chateado com a vida', 'emotional')).toEqual({
      optionKey: null,
    });
  });

  it('keeps a catalog key and drops anything else', async () => {
    const generateJson = vi.fn();
    const gemini = { isAvailable: true, generateJson } as any;
    const service = new JournalSuggestService(gemini);

    generateJson.mockResolvedValueOnce({ optionKey: 'futuro.medo.desanimo' });
    expect(await service.suggest('estou muito chateado com a vida', 'emotional')).toEqual({
      optionKey: 'futuro.medo.desanimo',
    });

    generateJson.mockResolvedValueOnce({ optionKey: 'depressive_hopelessness' });
    expect(await service.suggest('sem esperança', 'emotional')).toEqual({ optionKey: null });

    generateJson.mockResolvedValueOnce({ optionKey: 'none' });
    expect(await service.suggest('xyz', 'emotional')).toEqual({ optionKey: null });
  });
});
