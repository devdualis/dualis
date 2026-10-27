import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { getTableConfig } from 'drizzle-orm/pg-core';
import { journalEntries, journalItems, userConditions } from '../../src/database/schema';
import { JournalService } from '../../src/modules/journal/journal.service';
import { buildJournalSummary } from '../../src/modules/journal/journal-summary';
import { houseAdsFor } from '../../src/modules/journal/house-ads';
import { BANNED_VOCABULARY, findBannedVocabulary } from '../../scripts/banned-vocabulary';

// Contract hard rules (CONTRATO-JOURNAL-V2.md): no field, column, constant or comment with
// grouping, assessment or disorder names in the journal v2 schema and API.
const CONTRACT_BANNED =
  /group|clinical|diagnos|symptom_structured|sphere|esfera|system|treatment|tratamento|urgency|severity|risk|careDisposition|isCritical|disposition|\bTAG\b|\bTOC\b|\bTEPT\b|bipolar|ciclotim|borderline|anedonia|radiculopatia|costocondrite|isquemia/i;

const SRC = join(__dirname, '../../src');
// Every journal v2 file except journal.service.ts, which reads the legacy symptom_logs
// columns by their existing names to return old rows as "registro anterior".
const CONTRACT_FILES = [
  'database/schema/journal.schema.ts',
  'database/migrations/0017_journal_v2.sql',
  'modules/journal/constants/journal-keys.constant.ts',
  'modules/journal/dto/journal.dto.ts',
  'modules/journal/journal-summary.ts',
  'modules/journal/house-ads.ts',
  'modules/journal/journal.module.ts',
];

function collectKeys(value: unknown, keys = new Set<string>()): Set<string> {
  if (Array.isArray(value)) value.forEach((v) => collectKeys(v, keys));
  else if (value && typeof value === 'object') {
    for (const [k, v] of Object.entries(value)) {
      keys.add(k);
      collectKeys(v, keys);
    }
  }
  return keys;
}

function expectCleanResponse(response: unknown) {
  for (const key of collectKeys(response)) {
    expect(key, `response key "${key}"`).not.toMatch(CONTRACT_BANNED);
  }
  expect(findBannedVocabulary(JSON.stringify(response))).toEqual([]);
}

const encryption = { encrypt: (t: string) => `v1:${t}`, decrypt: (t: string) => t.slice(3) };

describe('Journal v2 contract: no grouping, assessment or disorder names', () => {
  it('the three tables have only the contract columns', () => {
    const columns = (t: any) => getTableConfig(t).columns.map((c) => c.name).sort();
    expect(columns(journalEntries)).toEqual(
      ['client_id', 'created_at', 'id', 'mood', 'note', 'profile_id', 'recorded_at', 'transition_variant_ids', 'trigger_note', 'triggers', 'user_id'].sort(),
    );
    expect(columns(journalItems)).toEqual(
      ['body_side', 'condition_id', 'custom_label', 'entry_id', 'id', 'intensity', 'kind', 'option_key', 'persistence'].sort(),
    );
    expect(columns(userConditions)).toEqual(['archived_at', 'created_at', 'id', 'label', 'profile_id', 'user_id'].sort());
  });

  it.each(CONTRACT_FILES)('%s contains no banned identifier or word', (file) => {
    const text = readFileSync(join(SRC, file), 'utf8');
    expect(text.match(CONTRACT_BANNED)?.[0] ?? null).toBeNull();
    expect(findBannedVocabulary(text)).toEqual([]);
  });

  it('entry, legacy entry, condition and summary responses carry no banned key or word', () => {
    const service = new JournalService({} as any, encryption as any) as any;
    const now = new Date('2026-10-20T12:00:00.000Z');
    const entry = service.toEntryDto(
      {
        id: 'e1', userId: 'u1', profileId: 'p1', clientId: 'c1', recordedAt: now, createdAt: now,
        mood: 'nao_tao_bem', triggers: ['sono'], triggerNote: null, note: 'v1:dia corrido', transitionVariantIds: ['t1'],
      },
      [
        { id: 'i1', entryId: 'e1', kind: 'physical', optionKey: 'cabeca.pressao.temporas', customLabel: null, conditionId: null, bodySide: 'front', persistence: 'hoje', intensity: 3 },
        { id: 'i2', entryId: 'e1', kind: 'condition', optionKey: null, customLabel: null, conditionId: 'k1', bodySide: null, persistence: null, intensity: 2 },
      ],
      new Map([['k1', 'Enxaqueca']]),
    );
    expect(entry.items[1].label).toBe('Enxaqueca');
    expect(entry.note).toBe('dia corrido');
    expectCleanResponse(entry);

    const legacy = service.toLegacyDto(
      {
        id: 'l1', intensity: 4, anatomicalSystem: 'cardiovascular_torax', emotionalDimension: 'estresse_burnout',
        encryptedNarrative: null, recordedAt: now, disposition: 'emergencia', organicPrimacyApplied: true,
      },
      'pt',
    );
    expect(legacy).toEqual({
      id: 'l1',
      legacy: true,
      recordedAt: now.toISOString(),
      note: null,
      items: [
        { kind: 'emotional', legacyLabel: 'Estressado(a) ou esgotado(a)', intensity: 4 },
        { kind: 'physical', legacyLabel: 'Peito', intensity: 4 },
      ],
    });
    expectCleanResponse(legacy);

    expectCleanResponse(service.toConditionDto({ id: 'k1', label: 'v1:Diabetes', createdAt: now }));
    expectCleanResponse(
      buildJournalSummary([{ recordedAt: now, triggers: ['sono'], items: [{ kind: 'emotional', optionKey: 'futuro.mente.antecipar' }] }], 30),
    );
  });

  it.each(['pt', 'en', 'es'] as const)('house ads (%s) carry no banned word and no health promise', (lang) => {
    const ads = houseAdsFor(lang);
    expectCleanResponse(ads);
    expect(JSON.stringify(ads)).not.toMatch(/cura|trata|melhora sua sa[uú]de|cure|heal|treat|recomendado para voc[eê]/i);
  });
});

describe('Banned vocabulary list (strategy §15)', () => {
  it('includes every new term', () => {
    const found = (t: string) => findBannedVocabulary(t).length > 0;
    for (const term of [
      'transtorno', 'TAG', 'TOC', 'TEPT', 'bipolar', 'ciclotimia', 'borderline', 'grupo clínico',
      'sintoma estruturado', 'esfera', 'vertical de tratamento', 'anedonia', 'radiculopatia',
      'costocondrite', 'isquemia', '☠️',
    ]) {
      expect(found(`texto com ${term} aqui`), term).toBe(true);
    }
    expect(BANNED_VOCABULARY.length).toBeGreaterThan(20);
  });

  it('does not flag ordinary words that contain the acronyms', () => {
    expect(findBannedVocabulary('Vou tocar violão e etiquetar fotos, sem estoque de tagarelice')).toEqual([]);
  });
});
