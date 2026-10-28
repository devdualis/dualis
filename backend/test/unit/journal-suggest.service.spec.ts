import { describe, it, expect, vi } from 'vitest';
import {
  OPTION_TEXT_PT,
  catalogKeys,
  deidentify,
  JournalSuggestService,
} from '../../src/modules/journal/journal-suggest.service';

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

  it('every catalog chip has the text shown in the app', () => {
    for (const key of [...catalogKeys('emotional'), ...catalogKeys('physical')]) {
      expect(OPTION_TEXT_PT[key], key).toBeTruthy();
    }
  });

  it('removes names, e-mails, links, handles and long numbers', () => {
    expect(deidentify('meu nome é Ana Souza e estou exausta')).toBe('meu nome é [nome] e estou exausta');
    expect(deidentify('Falei com Pedro ontem e fiquei triste')).toBe('Falei com [nome] ontem e fiquei triste');
    expect(deidentify('liga 11 98765-4321 ou ana.b@mail.com')).toBe('liga [numero] ou [email]');
    expect(deidentify('cpf 123.456.789-00 www.site.com @ana_b')).toBe('cpf [numero] [link] [usuario]');
    expect(deidentify('Minha cabeça está pesada')).toBe('Minha cabeça está pesada');
    expect(deidentify('Ana disse que estou cansada')).toBe('[nome] disse que estou cansada');
    expect(deidentify('Hoje acordei mal. Sebastião brigou comigo')).toBe('Hoje acordei mal. [nome] brigou comigo');
    expect(deidentify('Rosa é minha cor favorita')).toBe('Rosa é minha cor favorita');
  });

  it('sends only the de-identified text, as its own content, never inside the instructions', async () => {
    const generateJson = vi.fn().mockResolvedValue({ optionKey: 'none' });
    const service = new JournalSuggestService({ isAvailable: true, generateJson } as any);
    await service.suggest('Sou a Maria, cpf 123.456.789-00, minha cabeça lateja', 'physical');

    const call = generateJson.mock.calls[0][0];
    expect(call.prompt).toBe('Sou a [nome], cpf [numero], minha cabeça lateja');
    expect(call.systemInstruction).not.toContain('Maria');
    expect(call.systemInstruction).not.toContain('minha cabeça');
    expect(call.systemInstruction).toContain('cabeca.pressao.latejando: Latejando');
    expect(call.schema.properties.optionKey.enum).toEqual([...catalogKeys('physical'), 'none']);
  });

  it('only offers the options of the branch on screen', async () => {
    expect(catalogKeys('emotional', 'futuro.mente')).toEqual(['futuro.mente.antecipar', 'futuro.mente.cobranca']);
    const generateJson = vi.fn().mockResolvedValue({ optionKey: 'futuro.medo.desanimo' });
    const service = new JournalSuggestService({ isAvailable: true, generateJson } as any);

    expect(await service.suggest('desanimada', 'emotional', 'futuro.mente')).toEqual({ optionKey: null });
    expect(generateJson.mock.calls[0][0].schema.properties.optionKey.enum).toEqual([
      'futuro.mente.antecipar',
      'futuro.mente.cobranca',
      'none',
    ]);

    generateJson.mockClear();
    expect(await service.suggest('dor', 'physical', 'nada.disso')).toEqual({ optionKey: null });
    expect(generateJson).not.toHaveBeenCalled();
  });
});
