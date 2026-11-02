import 'reflect-metadata';
import { describe, it, expect, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { getTableName } from 'drizzle-orm';
import {
  ConditionReadingsQueryDto,
  CreateConditionDto,
  CreateJournalEntryDto,
  UpdateConditionDto,
} from '../../src/modules/journal/dto/journal.dto';
import { READING_INPUT_LIMITS, TRACKING_KINDS } from '../../src/modules/journal/constants/journal-keys.constant';
import { JournalService } from '../../src/modules/journal/journal.service';

// Journal v2.4: readings on a tracked condition (CONTRATO-JOURNAL-V2.md, v2.4).

const RECORDED_AT = '2026-11-01T12:00:00.000Z';
const CONDITION_ID = '11111111-1111-4111-8111-111111111111';

const bp = { kind: 'blood_pressure', measuredAt: '2026-11-01T11:10:00.000Z', systolic: 130, diastolic: 85, pulse: 72 };
const glucose = { kind: 'glucose', measuredAt: '2026-11-01T11:12:00.000Z', mgdl: 98, moment: 'jejum' };
const weight = { kind: 'weight', measuredAt: '2026-11-01T11:15:00.000Z', kg: 72.5 };

const entryWith = (item: Record<string, unknown>, extra: Record<string, unknown> = {}) => ({
  clientId: 'outbox-r1',
  recordedAt: RECORDED_AT,
  mood: 'bem',
  area: 'physical',
  triggers: [],
  transitionVariantIds: [],
  items: [item],
  ...extra,
});
const conditionItem = (readings: unknown[], extra: Record<string, unknown> = {}) => ({
  kind: 'condition',
  conditionId: CONDITION_ID,
  intensity: null,
  readings,
  ...extra,
});

const flatten = (errors: any[]): string[] =>
  errors.flatMap((e) => [...Object.keys(e.constraints ?? {}), ...flatten(e.children ?? [])]);
const errorsOf = <T extends object>(cls: new () => T, payload: unknown) =>
  flatten(validateSync(plainToInstance(cls, payload) as object, { whitelist: true, forbidNonWhitelisted: true }));
const entryErrors = (payload: unknown) => errorsOf(CreateJournalEntryDto, payload);

describe('Readings input (typo limits only)', () => {
  it('accepts the three kinds on one condition item, with intensity null', () => {
    expect(entryErrors(entryWith(conditionItem([bp, glucose, weight])))).toEqual([]);
    expect(entryErrors(entryWith(conditionItem([{ ...bp, pulse: undefined }])))).toEqual([]);
    expect(entryErrors(entryWith(conditionItem([{ ...bp, pulse: null }])))).toEqual([]);
    expect(entryErrors(entryWith(conditionItem([{ ...weight, kg: 72 }])))).toEqual([]);
  });

  it('a condition item without readings still needs intensity; with readings intensity is optional', () => {
    expect(entryErrors(entryWith(conditionItem([])))).not.toEqual([]);
    expect(entryErrors(entryWith({ kind: 'condition', conditionId: CONDITION_ID }))).not.toEqual([]);
    expect(entryErrors(entryWith({ kind: 'condition', conditionId: CONDITION_ID, intensity: 3 }))).toEqual([]);
    expect(entryErrors(entryWith(conditionItem([bp], { intensity: 2 })))).toEqual([]);
    expect(entryErrors(entryWith(conditionItem([bp], { intensity: 9 })))).toContain('max');
  });

  it('readings are accepted only on condition items', () => {
    const physical = { kind: 'physical', optionKey: 'cabeca.pressao.temporas', bodySide: 'front', sensation: 'dor', persistence: 'hoje', intensity: 2, readings: [bp] };
    expect(entryErrors(entryWith(physical, { mood: 'nao_tao_bem' }))).toContain('journalItemShape');
    const emotional = { kind: 'emotional', optionKey: 'futuro.mente.antecipar', persistence: 'hoje', intensity: 2, readings: [] };
    expect(entryErrors(entryWith(emotional, { mood: 'nao_tao_bem', area: 'emotional' }))).toContain('journalItemShape');
  });

  it.each([
    ['systolic', { ...bp, systolic: READING_INPUT_LIMITS.systolic.min - 1 }],
    ['systolic', { ...bp, systolic: 1300 }],
    ['diastolic', { ...bp, diastolic: READING_INPUT_LIMITS.diastolic.max + 1 }],
    ['pulse', { ...bp, pulse: READING_INPUT_LIMITS.pulse.min - 1 }],
    ['mgdl', { ...glucose, mgdl: READING_INPUT_LIMITS.mgdl.max + 1 }],
    ['mgdl', { ...glucose, mgdl: 98.5 }],
    ['kg', { ...weight, kg: READING_INPUT_LIMITS.kg.min - 1 }],
    ['kg', { ...weight, kg: 72.555 }],
    ['kg', { ...weight, kg: '72,5' }],
    ['missing systolic', { kind: 'blood_pressure', measuredAt: bp.measuredAt, diastolic: 80 }],
    ['missing moment', { kind: 'glucose', measuredAt: glucose.measuredAt, mgdl: 98 }],
    ['unknown moment', { ...glucose, moment: 'tarde' }],
    ['unknown kind', { kind: 'temperature', measuredAt: bp.measuredAt }],
    ['bad time', { ...bp, measuredAt: 'ontem' }],
  ])('rejects a typing slip or wrong shape: %s', (_label, reading) => {
    expect(entryErrors(entryWith(conditionItem([reading])))).not.toEqual([]);
  });

  it('accepts the limits themselves', () => {
    const L = READING_INPUT_LIMITS;
    expect(entryErrors(entryWith(conditionItem([
      { ...bp, systolic: L.systolic.min, diastolic: L.diastolic.max, pulse: L.pulse.max },
      { ...glucose, mgdl: L.mgdl.min },
      { ...weight, kg: L.kg.max },
    ])))).toEqual([]);
  });

  it('rejects fields of another kind on a reading', () => {
    expect(entryErrors(entryWith(conditionItem([{ ...weight, mgdl: 98 }])))).toContain('conditionReadingShape');
    expect(entryErrors(entryWith(conditionItem([{ ...glucose, systolic: 120 }])))).toContain('conditionReadingShape');
    expect(entryErrors(entryWith(conditionItem([{ ...bp, label: 'alta' }])))).toContain('whitelistValidation');
  });

  it('measuredAt stays within 7 days before and 10 minutes after recordedAt', () => {
    const at = (offsetMs: number) => new Date(Date.parse(RECORDED_AT) + offsetMs).toISOString();
    const day = 24 * 60 * 60 * 1000;
    expect(entryErrors(entryWith(conditionItem([{ ...bp, measuredAt: at(-7 * day) }])))).toEqual([]);
    expect(entryErrors(entryWith(conditionItem([{ ...bp, measuredAt: at(10 * 60 * 1000) }])))).toEqual([]);
    expect(entryErrors(entryWith(conditionItem([{ ...bp, measuredAt: at(-7 * day - 1000) }])))).toContain('journalEntryShape');
    expect(entryErrors(entryWith(conditionItem([{ ...bp, measuredAt: at(11 * 60 * 1000) }])))).toContain('journalEntryShape');
  });

  it(`allows at most ${READING_INPUT_LIMITS.maxPerItem} readings per item`, () => {
    const many = (n: number) => Array.from({ length: n }, () => bp);
    expect(entryErrors(entryWith(conditionItem(many(READING_INPUT_LIMITS.maxPerItem))))).toEqual([]);
    expect(entryErrors(entryWith(conditionItem(many(READING_INPUT_LIMITS.maxPerItem + 1))))).toContain('arrayMaxSize');
  });

  it('condition tracking accepts only the three kinds, without repeats', () => {
    expect(errorsOf(CreateConditionDto, { label: 'Pressão', tracking: ['blood_pressure', 'weight'] })).toEqual([]);
    expect(errorsOf(CreateConditionDto, { label: 'Enxaqueca' })).toEqual([]);
    expect(errorsOf(CreateConditionDto, { label: 'X', tracking: ['temperature'] })).toContain('isIn');
    expect(errorsOf(UpdateConditionDto, { tracking: [...TRACKING_KINDS] })).toEqual([]);
    expect(errorsOf(UpdateConditionDto, { tracking: [] })).toEqual([]);
    expect(errorsOf(UpdateConditionDto, { label: 'Diabetes' })).toEqual([]);
    expect(errorsOf(UpdateConditionDto, { tracking: ['glucose', 'glucose'] })).toContain('arrayUnique');
    expect(errorsOf(UpdateConditionDto, { label: '   ' })).toContain('matches');
    expect(errorsOf(UpdateConditionDto, { tracking: ['weight'], archivedAt: 'x' })).toContain('whitelistValidation');
    expect(errorsOf(ConditionReadingsQueryDto, { days: '90' })).toEqual([]);
    expect(errorsOf(ConditionReadingsQueryDto, { days: '0' })).toContain('min');
  });
});

// In-memory stand-in for the Drizzle transaction: rows per table, inserts recorded.
function fakeDb(seed: Record<string, any[]> = {}) {
  const now = new Date('2026-11-01T12:00:01.000Z');
  const tables: Record<string, any[]> = { ...seed };
  const inserted: Record<string, any[]> = {};
  const updates: Array<{ table: string; set: any }> = [];
  let seq = 0;
  const chain = (rows: () => any[]) => {
    const query: any = {
      where: () => query,
      orderBy: () => query,
      limit: () => query,
      then: (resolve: any, reject: any) => Promise.resolve(rows()).then(resolve, reject),
    };
    return query;
  };
  const tx = {
    execute: vi.fn(async () => undefined),
    select: () => ({ from: (table: any) => chain(() => tables[getTableName(table)] ?? []) }),
    insert: (table: any) => ({
      values: (values: any) => {
        const name = getTableName(table);
        const rows = (Array.isArray(values) ? values : [values]).map((v) => ({ id: `${name}-${++seq}`, createdAt: now, ...v }));
        inserted[name] = [...(inserted[name] ?? []), ...rows];
        const result: any = { onConflictDoNothing: () => result, returning: async () => rows };
        return result;
      },
    }),
    update: (table: any) => ({
      set: (set: any) => ({
        where: () => ({
          returning: async () => {
            const name = getTableName(table);
            updates.push({ table: name, set });
            return (tables[name] ?? []).slice(0, 1).map((row) => ({ ...row, ...set }));
          },
        }),
      }),
    }),
  };
  const database = { withRls: vi.fn(async (_userId: string, cb: (t: any) => any) => cb(tx)) };
  const encryption = {
    encrypt: vi.fn((t: string) => `v1:${t}`),
    decrypt: vi.fn((t: string) => {
      if (t === 'v1:broken') throw new Error('unable to authenticate data');
      return t.slice(3);
    }),
  };
  const service = new JournalService(database as any, encryption as any);
  return { service, tables, inserted, updates, encryption };
}

const condition = { id: CONDITION_ID, userId: 'u1', profileId: 'p1', label: 'v1:Pressão', tracking: ['blood_pressure'], createdAt: new Date('2026-10-01T10:00:00Z'), archivedAt: null };

describe('JournalService readings', () => {
  it('stores each reading encrypted with its own time and returns it decrypted on the item', async () => {
    const f = fakeDb({ user_conditions: [condition] });
    const dto = entryWith(conditionItem([bp, { ...bp, measuredAt: '2026-11-01T08:00:00.000Z', pulse: undefined }, glucose])) as any;

    const entry = await f.service.createEntry('u1', 'p1', dto);

    const rows = f.inserted.condition_readings;
    expect(rows).toHaveLength(3);
    for (const row of rows) {
      expect(row).toMatchObject({ userId: 'u1', profileId: 'p1', entryId: entry.id, conditionId: CONDITION_ID });
      expect(row.measuredAt).toBeInstanceOf(Date);
      expect(row.data.startsWith('v1:')).toBe(true);
    }
    // Only the values are encrypted; kind and time stay in their own columns.
    expect(JSON.parse(rows[0].data.slice(3))).toEqual({ systolic: 130, diastolic: 85, pulse: 72 });
    expect(JSON.parse(rows[1].data.slice(3))).toEqual({ systolic: 130, diastolic: 85, pulse: null });
    expect(JSON.parse(rows[2].data.slice(3))).toEqual({ mgdl: 98, moment: 'jejum' });

    const item = entry.items[0];
    expect(item).toMatchObject({ kind: 'condition', conditionId: CONDITION_ID, label: 'Pressão', intensity: null });
    // Oldest first inside one item, each with an id.
    expect(item.readings.map((r) => r.measuredAt)).toEqual([
      '2026-11-01T08:00:00.000Z', '2026-11-01T11:10:00.000Z', '2026-11-01T11:12:00.000Z',
    ]);
    expect(item.readings[1]).toEqual({
      id: expect.any(String), entryId: entry.id, conditionId: CONDITION_ID, measuredAt: bp.measuredAt,
      kind: 'blood_pressure', systolic: 130, diastolic: 85, pulse: 72,
    });
    expect(item.readings[2]).toMatchObject({ kind: 'glucose', mgdl: 98, moment: 'jejum' });
    expect(JSON.stringify(entry)).not.toMatch(/v1:/);
  });

  it('an entry without readings inserts none', async () => {
    const f = fakeDb({ user_conditions: [condition] });
    await f.service.createEntry('u1', 'p1', entryWith({ kind: 'condition', conditionId: CONDITION_ID, intensity: 3 }) as any);
    expect(f.inserted.condition_readings).toBeUndefined();
  });

  it('replaying a clientId returns the stored readings and inserts nothing', async () => {
    const stored = {
      id: 'e1', userId: 'u1', profileId: 'p1', clientId: 'outbox-r1', recordedAt: new Date(RECORDED_AT), createdAt: new Date(RECORDED_AT),
      mood: 'bem', area: 'physical', coping: null, helpers: [], triggers: [], triggerNote: null, note: null, transitionVariantIds: [],
    };
    const f = fakeDb({
      journal_entries: [stored],
      journal_items: [{ id: 'i1', entryId: 'e1', kind: 'condition', optionKey: null, customLabel: null, conditionId: CONDITION_ID, bodySide: null, sensation: null, persistence: null, intensity: null }],
      condition_readings: [
        { id: 'r1', userId: 'u1', profileId: 'p1', entryId: 'e1', conditionId: CONDITION_ID, kind: 'weight', measuredAt: new Date(weight.measuredAt), data: 'v1:{"kg":72.5}', createdAt: new Date(RECORDED_AT) },
      ],
      user_conditions: [condition],
    });

    const replayed = await f.service.createEntry('u1', 'p1', entryWith(conditionItem([weight])) as any);

    expect(f.inserted).toEqual({});
    expect(replayed.items[0].readings).toEqual([
      { id: 'r1', entryId: 'e1', conditionId: CONDITION_ID, measuredAt: weight.measuredAt, kind: 'weight', kg: 72.5 },
    ]);
  });

  it('rejects a reading time out of the window before touching the database', async () => {
    const f = fakeDb({ user_conditions: [condition] });
    const late = entryWith(conditionItem([{ ...bp, measuredAt: '2026-11-01T13:00:00.000Z' }]));
    await expect(f.service.createEntry('u1', 'p1', late as any)).rejects.toMatchObject({ status: 400 });
    expect(f.inserted).toEqual({});
  });

  it('history lists one condition newest first, decrypted; unreadable rows are left out', async () => {
    const reading = (id: string, kind: string, measuredAt: string, data: string) => ({
      id, userId: 'u1', profileId: 'p1', entryId: 'e1', conditionId: CONDITION_ID, kind, measuredAt: new Date(measuredAt), data, createdAt: new Date(measuredAt),
    });
    const f = fakeDb({
      user_conditions: [condition],
      condition_readings: [
        reading('r2', 'blood_pressure', '2026-11-01T11:00:00Z', 'v1:{"systolic":128,"diastolic":82,"pulse":null}'),
        reading('r1', 'glucose', '2026-10-31T07:00:00Z', 'v1:{"mgdl":101,"moment":"pre_refeicao"}'),
        reading('r0', 'weight', '2026-10-30T07:00:00Z', 'v1:broken'),
      ],
    });

    const readings = await f.service.listConditionReadings('u1', 'p1', CONDITION_ID, { days: 90 });

    expect(readings).toEqual([
      { id: 'r2', entryId: 'e1', conditionId: CONDITION_ID, measuredAt: '2026-11-01T11:00:00.000Z', kind: 'blood_pressure', systolic: 128, diastolic: 82, pulse: null },
      { id: 'r1', entryId: 'e1', conditionId: CONDITION_ID, measuredAt: '2026-10-31T07:00:00.000Z', kind: 'glucose', mgdl: 101, moment: 'pre_refeicao' },
    ]);
  });

  it('history of a condition that is not on this profile answers 404', async () => {
    const f = fakeDb({ user_conditions: [] });
    await expect(f.service.listConditionReadings('u1', 'p1', CONDITION_ID, {})).rejects.toMatchObject({ status: 404 });
  });
});

describe('JournalService condition tracking', () => {
  it('createCondition stores tracking without repeats; default is none', async () => {
    const f = fakeDb({ user_conditions: [{ active: 0 }] }); // the count of active conditions
    const created = await f.service.createCondition('u1', 'p1', 'Diabetes', ['glucose', 'glucose', 'weight']);
    expect(f.inserted.user_conditions[0].tracking).toEqual(['glucose', 'weight']);
    expect(created.tracking).toEqual(['glucose', 'weight']);
    const plain = await f.service.createCondition('u1', 'p1', 'Enxaqueca');
    expect(plain.tracking).toEqual([]);
  });

  it('updateCondition changes tracking and label; the label is encrypted', async () => {
    const f = fakeDb({ user_conditions: [condition] });
    const updated = await f.service.updateCondition('u1', 'p1', CONDITION_ID, { tracking: ['blood_pressure', 'weight'], label: ' Pressão alta ' });
    expect(f.updates).toEqual([{ table: 'user_conditions', set: { label: 'v1:Pressão alta', tracking: ['blood_pressure', 'weight'] } }]);
    expect(updated).toEqual({ id: CONDITION_ID, label: 'Pressão alta', tracking: ['blood_pressure', 'weight'], createdAt: '2026-10-01T10:00:00.000Z' });
  });

  it('updateCondition with tracking [] turns readings off; an empty body returns the condition unchanged', async () => {
    const f = fakeDb({ user_conditions: [condition] });
    expect((await f.service.updateCondition('u1', 'p1', CONDITION_ID, { tracking: [] })).tracking).toEqual([]);
    expect(await f.service.updateCondition('u1', 'p1', CONDITION_ID, {})).toMatchObject({ tracking: ['blood_pressure'] });
  });

  it('updateCondition answers 404 for an archived or other-profile condition and 400 for a blank label', async () => {
    const f = fakeDb({ user_conditions: [] });
    await expect(f.service.updateCondition('u1', 'p1', CONDITION_ID, { tracking: ['weight'] })).rejects.toMatchObject({ status: 404 });
    await expect(f.service.updateCondition('u1', 'p1', CONDITION_ID, { label: '  ' })).rejects.toMatchObject({ status: 400 });
  });

  it('old condition rows without tracking read as []', () => {
    const service = new JournalService({} as any, { decrypt: (t: string) => t.slice(3) } as any) as any;
    expect(service.toConditionDto({ ...condition, tracking: null }).tracking).toEqual([]);
  });
});

describe('Readings never reach AI or the counts summary', () => {
  const SRC = join(__dirname, '../../src/modules/journal');
  it('the suggestion service does not touch readings or conditions', () => {
    const text = readFileSync(join(SRC, 'journal-suggest.service.ts'), 'utf8');
    expect(text).not.toMatch(/conditionReadings|condition_readings|readings|userConditions/);
  });
  it('the journal service never calls the suggestion service', () => {
    expect(readFileSync(join(SRC, 'journal.service.ts'), 'utf8')).not.toMatch(/JournalSuggest|suggest/i);
  });
  it('the counts summary does not read readings', () => {
    expect(readFileSync(join(SRC, 'journal-summary.ts'), 'utf8')).not.toMatch(/reading/i);
  });
});
