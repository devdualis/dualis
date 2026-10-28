import 'reflect-metadata';
import { describe, it, expect } from 'vitest';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import {
  CreateConditionDto,
  CreateJournalEntryDto,
  JournalDaysQueryDto,
} from '../../src/modules/journal/dto/journal.dto';
import {
  EMOTIONAL_OPTION_KEYS,
  ENTRY_AREAS,
  PHYSICAL_OPTION_KEYS,
  SENSATION_KEYS,
  isOptionKeyOnSide,
  isWholeBodyOptionKey,
} from '../../src/modules/journal/constants/journal-keys.constant';
import { buildJournalSummary, dayMarkers, localDay } from '../../src/modules/journal/journal-summary';
import { houseAdsFor } from '../../src/modules/journal/house-ads';

const baseEntry = {
  clientId: 'outbox-1',
  recordedAt: '2026-10-27T12:00:00.000Z',
  mood: 'nao_tao_bem',
  triggers: [],
  transitionVariantIds: ['passado.intro.2'],
  items: [{ kind: 'emotional', optionKey: 'futuro.mente.antecipar', persistence: 'hoje', intensity: 3 }],
};

const errorsOf = (payload: Record<string, unknown>) => {
  const dto = plainToInstance(CreateJournalEntryDto, payload);
  const flatten = (errors: any[]): string[] =>
    errors.flatMap((e) => [...Object.keys(e.constraints ?? {}), ...flatten(e.children ?? [])]);
  return flatten(validateSync(dto, { whitelist: true, forbidNonWhitelisted: true }));
};

const withItem = (item: Record<string, unknown>, extra: Record<string, unknown> = {}) =>
  errorsOf({ ...baseEntry, ...extra, items: [item] });

describe('Journal v2 keys', () => {
  it('match the contract tables: 12 emotional + 3 custom, 34 physical + 8 custom', () => {
    expect(EMOTIONAL_OPTION_KEYS).toHaveLength(15);
    expect(PHYSICAL_OPTION_KEYS).toHaveLength(42);
    expect(EMOTIONAL_OPTION_KEYS).toContain('passado.memoria.magoa');
    expect(EMOTIONAL_OPTION_KEYS).toContain('presente.custom');
    expect(PHYSICAL_OPTION_KEYS).toContain('costas.fisgada.ao_mexer');
    expect(PHYSICAL_OPTION_KEYS).toContain('membros.custom');
    for (const key of [
      'cabeca.nuca.rigida', 'cabeca.nuca.pontada',
      'pele.coceira.coceira', 'pele.coceira.ardencia', 'pele.aparencia.vermelhidao', 'pele.aparencia.manchas',
      'musculos.tensao.rigidez', 'musculos.tensao.caibra', 'musculos.cansaco.fraqueza', 'musculos.cansaco.dolorido',
      'hormonios.temperatura.calorao', 'hormonios.temperatura.frio', 'hormonios.apetite.sede', 'hormonios.apetite.fome',
      'pele.custom', 'musculos.custom', 'hormonios.custom',
    ]) {
      expect(PHYSICAL_OPTION_KEYS, key).toContain(key);
    }
    expect(SENSATION_KEYS).toEqual(['dor', 'incomodo']);
    expect(ENTRY_AREAS).toEqual(['emotional', 'physical']);
  });

  it('branch side rules: front, back and whole body', () => {
    expect(isOptionKeyOnSide('cabeca.sentidos.olhos', 'front')).toBe(true);
    expect(isOptionKeyOnSide('cabeca.sentidos.olhos', 'back')).toBe(false);
    expect(isOptionKeyOnSide('cabeca.nuca.rigida', 'back')).toBe(true);
    expect(isOptionKeyOnSide('cabeca.nuca.rigida', 'front')).toBe(false);
    expect(isOptionKeyOnSide('cabeca.pressao.temporas', 'back')).toBe(true);
    expect(isOptionKeyOnSide('costas.rigidez.lombar', 'front')).toBe(false);
    expect(isOptionKeyOnSide('peito.custom', 'back')).toBe(false);
    expect(isOptionKeyOnSide('membros.custom', 'back')).toBe(true);
    expect(isWholeBodyOptionKey('hormonios.apetite.sede')).toBe(true);
    expect(isWholeBodyOptionKey('cabeca.custom')).toBe(false);
  });
});

describe('CreateJournalEntryDto v2.1: area, sensation and sides', () => {
  const physical = (item: Record<string, unknown>) => ({ kind: 'physical', persistence: 'hoje', intensity: 3, ...item });
  const v21 = (items: Record<string, unknown>[], extra: Record<string, unknown> = {}) =>
    errorsOf({ ...baseEntry, area: 'physical', items, ...extra });

  it('accepts a v2.1 physical entry with sided and whole-body items', () => {
    expect(
      v21([
        physical({ optionKey: 'cabeca.nuca.pontada', bodySide: 'back', sensation: 'dor' }),
        physical({ optionKey: 'cabeca.sentidos.olhos', bodySide: 'front', sensation: 'incomodo' }),
        physical({ optionKey: 'musculos.tensao.caibra', sensation: 'dor' }),
        physical({ optionKey: 'hormonios.custom', customLabel: 'calor à noite', sensation: 'incomodo' }),
        { kind: 'condition', conditionId: '11111111-1111-4111-8111-111111111111', intensity: 2 },
      ]),
    ).toEqual([]);
    expect(errorsOf({ ...baseEntry, area: 'emotional', mood: 'bem', items: [] })).toEqual([]);
  });

  it('area is emotional or physical; one axis per entry', () => {
    expect(errorsOf({ ...baseEntry, area: 'both' })).toContain('isIn');
    expect(errorsOf({ ...baseEntry, area: 'emotional' })).toEqual([]);
    expect(
      errorsOf({ ...baseEntry, area: 'emotional', items: [...baseEntry.items, physical({ optionKey: 'peito.respiracao.curta', bodySide: 'front', sensation: 'dor' })] }),
    ).toContain('journalEntryShape');
    expect(v21([baseEntry.items[0]])).toContain('journalEntryShape');
  });

  it('new entries use bem or nao_tao_bem; normal stays valid only without area', () => {
    expect(errorsOf({ ...baseEntry, mood: 'normal', items: [] })).toEqual([]);
    expect(errorsOf({ ...baseEntry, area: 'emotional', mood: 'normal', items: [] })).toContain('journalEntryShape');
  });

  it('sensation is required on physical items of v2.1 entries and only accepted on physical items', () => {
    expect(v21([physical({ optionKey: 'peito.respiracao.curta', bodySide: 'front' })])).toContain('journalEntryShape');
    expect(v21([physical({ optionKey: 'peito.respiracao.curta', bodySide: 'front', sensation: 'forte' })])).toContain('isIn');
    expect(
      withItem({ kind: 'emotional', optionKey: 'futuro.mente.antecipar', sensation: 'dor', persistence: 'hoje', intensity: 1 }),
    ).toContain('journalItemShape');
    expect(
      withItem({ kind: 'condition', conditionId: '11111111-1111-4111-8111-111111111111', sensation: 'dor', intensity: 1 }),
    ).toContain('journalItemShape');
  });

  it('old clients without area keep working (no sensation, any side for old keys)', () => {
    expect(withItem(physical({ optionKey: 'costas.rigidez.ombros', bodySide: 'front' }))).toEqual([]);
    expect(withItem(physical({ optionKey: 'cabeca.sentidos.garganta', bodySide: 'back' }))).toEqual([]);
  });

  it('v2.1 entries put each sided option on a side where the map shows it', () => {
    expect(v21([physical({ optionKey: 'cabeca.nuca.rigida', bodySide: 'front', sensation: 'dor' })])).toContain('journalEntryShape');
    expect(v21([physical({ optionKey: 'cabeca.sentidos.garganta', bodySide: 'back', sensation: 'dor' })])).toContain('journalEntryShape');
    expect(v21([physical({ optionKey: 'costas.custom', customLabel: 'x', bodySide: 'front', sensation: 'dor' })])).toContain('journalEntryShape');
    expect(v21([physical({ optionKey: 'peito.incomodo.batedeira', bodySide: 'back', sensation: 'dor' })])).toContain('journalEntryShape');
    expect(v21([physical({ optionKey: 'membros.cansaco.juntas', bodySide: 'back', sensation: 'dor' })])).toEqual([]);
  });

  it('whole-body options have no side; sided options still need one', () => {
    expect(v21([physical({ optionKey: 'pele.aparencia.manchas', bodySide: 'front', sensation: 'incomodo' })])).toContain('journalItemShape');
    expect(withItem(physical({ optionKey: 'pele.aparencia.manchas', bodySide: 'back' }))).toContain('journalItemShape');
    expect(v21([physical({ optionKey: 'cabeca.pressao.temporas', sensation: 'dor' })])).toContain('journalItemShape');
  });
});

describe('CreateJournalEntryDto validation', () => {
  it('accepts a valid entry with emotional, physical, custom and condition items', () => {
    expect(
      errorsOf({
        ...baseEntry,
        triggers: ['sono', 'esforco', 'outro'],
        triggerNote: 'mudança de casa',
        note: 'Dia longo.',
        items: [
          { kind: 'emotional', optionKey: 'passado.tristeza.saudade', persistence: 'dias_semanas', intensity: 2 },
          { kind: 'emotional', optionKey: 'presente.custom', customLabel: 'sem paciência', persistence: 'hoje', intensity: 4 },
          { kind: 'physical', optionKey: 'cabeca.pressao.temporas', bodySide: 'front', persistence: 'hoje', intensity: 3 },
          { kind: 'physical', optionKey: 'costas.custom', customLabel: 'nuca dura', bodySide: 'back', persistence: 'meses_anos', intensity: 5 },
          { kind: 'condition', conditionId: '11111111-1111-4111-8111-111111111111', intensity: 2 },
        ],
      }),
    ).toEqual([]);
  });

  it('accepts an entry with no items (mood only)', () => {
    expect(errorsOf({ ...baseEntry, mood: 'bem', items: [] })).toEqual([]);
  });

  it('rejects keys outside the contract tables', () => {
    expect(withItem({ kind: 'emotional', optionKey: 'futuro.mente.panico', persistence: 'hoje', intensity: 3 })).toContain('isIn');
    expect(errorsOf({ ...baseEntry, mood: 'pessimo' })).toContain('isIn');
    expect(errorsOf({ ...baseEntry, triggers: ['estresse'] })).toContain('isIn');
    expect(withItem({ kind: 'mental', optionKey: 'futuro.mente.antecipar', persistence: 'hoje', intensity: 3 })).toContain('isIn');
    expect(withItem({ kind: 'emotional', optionKey: 'futuro.mente.antecipar', persistence: 'cronico', intensity: 3 })).toContain('isIn');
  });

  it('rejects unknown fields (no assessment can be smuggled in)', () => {
    expect(errorsOf({ ...baseEntry, urgencyScore: 5 })).toContain('whitelistValidation');
    expect(withItem({ ...baseEntry.items[0], careDisposition: 'x' })).toContain('whitelistValidation');
  });

  it('intensity is an integer from 1 to 5, always required on items', () => {
    for (const intensity of [0, 6, 2.5, undefined]) {
      expect(withItem({ kind: 'emotional', optionKey: 'futuro.mente.antecipar', persistence: 'hoje', intensity })).not.toEqual([]);
    }
  });

  it('enforces each kind shape', () => {
    // emotional key on a physical item
    expect(withItem({ kind: 'physical', optionKey: 'futuro.mente.antecipar', bodySide: 'front', persistence: 'hoje', intensity: 1 })).toContain('journalItemShape');
    // physical needs bodySide; emotional must not have it
    expect(withItem({ kind: 'physical', optionKey: 'cabeca.pressao.temporas', persistence: 'hoje', intensity: 1 })).toContain('journalItemShape');
    expect(withItem({ kind: 'emotional', optionKey: 'futuro.mente.antecipar', bodySide: 'front', persistence: 'hoje', intensity: 1 })).toContain('journalItemShape');
    // custom key needs customLabel, and customLabel only goes with a custom key
    expect(withItem({ kind: 'emotional', optionKey: 'futuro.custom', persistence: 'hoje', intensity: 1 })).toContain('journalItemShape');
    expect(withItem({ kind: 'emotional', optionKey: 'futuro.mente.antecipar', customLabel: 'x', persistence: 'hoje', intensity: 1 })).toContain('journalItemShape');
    // persistence required for emotional/physical
    expect(withItem({ kind: 'emotional', optionKey: 'futuro.mente.antecipar', intensity: 1 })).toContain('journalItemShape');
    // condition: conditionId required, no optionKey
    expect(withItem({ kind: 'condition', intensity: 1 })).toContain('journalItemShape');
    expect(withItem({ kind: 'condition', conditionId: '11111111-1111-4111-8111-111111111111', optionKey: 'futuro.custom', intensity: 1 })).toContain('journalItemShape');
  });

  it('limits: 12 items, customLabel 80, triggerNote 60', () => {
    const item = baseEntry.items[0];
    expect(errorsOf({ ...baseEntry, items: Array(12).fill(item) })).toEqual([]);
    expect(errorsOf({ ...baseEntry, items: Array(13).fill(item) })).toContain('arrayMaxSize');
    expect(withItem({ kind: 'emotional', optionKey: 'futuro.custom', customLabel: 'a'.repeat(81), persistence: 'hoje', intensity: 1 })).toContain('maxLength');
    expect(errorsOf({ ...baseEntry, triggerNote: 'a'.repeat(61) })).toContain('maxLength');
  });

  it('physical-only triggers need a physical item in the entry', () => {
    expect(errorsOf({ ...baseEntry, triggers: ['queda'] })).toContain('physicalOnlyTriggers');
    expect(
      errorsOf({
        ...baseEntry,
        triggers: ['queda'],
        items: [{ kind: 'physical', optionKey: 'membros.cansaco.juntas', bodySide: 'front', persistence: 'hoje', intensity: 2 }],
      }),
    ).toEqual([]);
    expect(errorsOf({ ...baseEntry, triggers: ['trabalho', 'nao_sei'] })).toEqual([]);
  });

  it('days query is 1..365, tzOffset -720..840; condition label is non-empty and at most 40 chars', () => {
    const q = (days: unknown) => validateSync(plainToInstance(JournalDaysQueryDto, { days }));
    expect(q('30')).toEqual([]);
    expect(q('365')).toEqual([]);
    expect(q('366')).not.toEqual([]);
    expect(q('0')).not.toEqual([]);
    const tz = (tzOffset: unknown) => validateSync(plainToInstance(JournalDaysQueryDto, { tzOffset }));
    for (const ok of ['-720', '-180', '0', '840']) expect(tz(ok), ok).toEqual([]);
    for (const bad of ['-721', '841', '1.5', 'abc']) expect(tz(bad), bad).not.toEqual([]);
    const c = (label: string) => validateSync(plainToInstance(CreateConditionDto, { label }));
    expect(c('Depressão')).toEqual([]);
    expect(c('   ')).not.toEqual([]);
    expect(c('a'.repeat(41))).not.toEqual([]);
  });
});

describe('buildJournalSummary', () => {
  const at = (iso: string) => new Date(iso);

  it('counts days per time, region, option key and trigger (a day counts once per key)', () => {
    const summary = buildJournalSummary(
      [
        {
          recordedAt: at('2026-10-20T12:00:00Z'),
          triggers: ['sono', 'sono'],
          items: [
            { kind: 'physical', optionKey: 'cabeca.pressao.temporas' },
            { kind: 'physical', optionKey: 'cabeca.sentidos.olhos' },
            { kind: 'emotional', optionKey: 'futuro.mente.antecipar' },
            { kind: 'condition', optionKey: null },
          ],
        },
        {
          recordedAt: at('2026-10-21T12:00:00Z'),
          triggers: ['trabalho'],
          items: [{ kind: 'emotional', optionKey: 'futuro.mente.antecipar' }],
        },
      ],
      30,
    );

    expect(summary.totalEntries).toBe(2);
    expect(summary.daysWithEntries).toBe(2);
    expect(summary.byTime).toEqual({ passado: 0, presente: 0, futuro: 2 });
    expect(summary.byRegion).toEqual({
      cabeca: 1, peito: 0, barriga: 0, costas: 0, membros: 0, pele: 0, musculos: 0, hormonios: 0,
    });
    expect(summary.byOptionKey).toEqual({
      'cabeca.pressao.temporas': 1,
      'cabeca.sentidos.olhos': 1,
      'futuro.mente.antecipar': 2,
    });
    expect(summary.byTrigger.sono).toBe(1);
    expect(summary.byTrigger.trabalho).toBe(1);
    expect(summary.byTrigger.clima).toBe(0);
  });

  it('cooccurrence: pairs seen on the same day on at least 2 days, counted in days', () => {
    const day = (d: number, items: any[], triggers: string[] = []) => ({
      recordedAt: at(`2026-10-${String(d).padStart(2, '0')}T15:00:00Z`),
      triggers,
      items,
    });
    const head = { kind: 'physical', optionKey: 'cabeca.pressao.temporas' };
    const mind = { kind: 'emotional', optionKey: 'futuro.mente.cobranca' };
    const summary = buildJournalSummary(
      [
        day(10, [head, mind], ['sono']),
        day(11, [head], ['sono']),
        { ...day(11, [mind]), recordedAt: at('2026-10-11T20:00:00Z') }, // same day, separate entry
        day(12, [mind]),
        day(13, [head], ['clima']),
      ],
      30,
    );

    expect(summary.cooccurrence).toEqual([
      { a: 'cabeca', b: 'futuro.mente', days: 2 },
      { a: 'cabeca', b: 'trigger:sono', days: 2 },
      { a: 'futuro.mente', b: 'trigger:sono', days: 2 },
    ]);
  });

  it('counts distinct local days, not entries: two entries with "Cabeça" on one day = 1 day', () => {
    const head = { kind: 'physical', optionKey: 'cabeca.pressao.temporas' };
    const mind = { kind: 'emotional', optionKey: 'futuro.mente.cobranca' };
    const summary = buildJournalSummary(
      [
        { recordedAt: at('2026-10-20T09:00:00Z'), triggers: ['sono'], items: [head, mind] },
        { recordedAt: at('2026-10-20T18:00:00Z'), triggers: ['sono'], items: [head, mind] },
        { recordedAt: at('2026-10-21T12:00:00Z'), triggers: ['sono'], items: [head] },
      ],
      30,
    );
    expect(summary.totalEntries).toBe(3);
    expect(summary.daysWithEntries).toBe(2);
    expect(summary.byRegion.cabeca).toBe(2);
    expect(summary.byTime.futuro).toBe(1);
    expect(summary.byOptionKey).toEqual({ 'cabeca.pressao.temporas': 2, 'futuro.mente.cobranca': 1 });
    expect(summary.byTrigger.sono).toBe(2);
  });

  it('local day: 22:00 in Brasília (01:00Z next day) counts on the Brasília day', () => {
    const head = { kind: 'physical', optionKey: 'cabeca.pressao.temporas' };
    const entries = [
      { recordedAt: at('2026-10-20T15:00:00Z'), triggers: [], items: [head] },
      { recordedAt: at('2026-10-21T01:00:00Z'), triggers: [], items: [head] }, // 22:00 on the 20th in BRT
    ];
    expect(buildJournalSummary(entries, 30, -180).byRegion.cabeca).toBe(1);
    expect(buildJournalSummary(entries, 30).byRegion.cabeca).toBe(2);
  });

  it('markers: region bare, emotional `<time>.<branch>` (bare time for written items), `trigger:<key>`', () => {
    expect(
      dayMarkers({
        recordedAt: at('2026-10-20T12:00:00Z'),
        triggers: ['sono', 'outro'],
        items: [
          { kind: 'physical', optionKey: 'cabeca.pressao.temporas' },
          { kind: 'physical', optionKey: 'costas.custom' },
          { kind: 'emotional', optionKey: 'futuro.mente.antecipar' },
          { kind: 'emotional', optionKey: 'passado.custom' },
          { kind: 'condition', optionKey: null },
        ],
      }).sort(),
    ).toEqual(['cabeca', 'costas', 'futuro.mente', 'passado', 'trigger:outro', 'trigger:sono']);
  });

  it('groups by the device day when tzOffset is given', () => {
    expect(localDay(at('2026-10-28T01:30:00Z'), -180)).toBe('2026-10-27');
    expect(localDay(at('2026-10-28T01:30:00Z'))).toBe('2026-10-28');
  });

  it('an empty window gives zeroed counts', () => {
    const summary = buildJournalSummary([], 30);
    expect(summary).toMatchObject({ totalEntries: 0, daysWithEntries: 0, byOptionKey: {}, cooccurrence: [] });
  });
});

describe('houseAdsFor', () => {
  it('returns the 4 demo ads in every language, same ids and order', () => {
    const ids = (lang: 'pt' | 'en' | 'es') => houseAdsFor(lang).ads.map((a) => a.id);
    expect(ids('pt')).toEqual(['dualis-premium', 'zoc', 'wgi', 'ubo']);
    expect(ids('en')).toEqual(ids('pt'));
    expect(ids('es')).toEqual(ids('pt'));
    expect(houseAdsFor('pt').ads.map((a) => a.brand)).toEqual(['Dualis Premium', 'ZOC', 'WGI', 'UBO']);
  });

  it('every ad has the contract fields and localized text', () => {
    for (const ad of houseAdsFor('es').ads) {
      expect(Object.keys(ad).sort()).toEqual(['assetKey', 'body', 'brand', 'id', 'title', 'url']);
      expect(ad.url).toMatch(/^https:\/\//);
    }
    expect(houseAdsFor('pt').ads[1].body).not.toBe(houseAdsFor('en').ads[1].body);
  });

  it('takes no input besides the language: identical for every person', () => {
    expect(houseAdsFor.length).toBe(1);
    expect(houseAdsFor('pt')).toEqual(houseAdsFor('pt'));
  });
});
