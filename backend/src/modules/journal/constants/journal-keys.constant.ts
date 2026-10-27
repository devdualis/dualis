/**
 * Journal v2 keys (docs/bienestar/CONTRATO-JOURNAL-V2.md). Single source for the backend
 * validation; the mobile app mirrors these lists. Keys name what the person chose,
 * nothing else: no grouping and no meaning is attached to them.
 */

/** Emotional choices: time -> branch -> options. optionKey = `<time>.<branch>.<option>`. */
export const EMOTIONAL_TREE = {
  passado: {
    tristeza: ['culpa', 'saudade'],
    memoria: ['lembranca', 'magoa'],
  },
  presente: {
    energia: ['corpo', 'desligado'],
    sobrecarga: ['paciencia', 'aperto'],
  },
  futuro: {
    mente: ['antecipar', 'cobranca'],
    medo: ['julgamento', 'desanimo'],
  },
} as const;

/** Physical choices: region -> branch -> options. optionKey = `<region>.<branch>.<option>`. */
export const PHYSICAL_TREE = {
  cabeca: {
    pressao: ['temporas', 'latejando'],
    sentidos: ['garganta', 'olhos'],
  },
  peito: {
    respiracao: ['curta', 'tosse'],
    incomodo: ['batedeira', 'costelas'],
  },
  barriga: {
    queimacao: ['subindo', 'enjoo'],
    colica: ['gases', 'pontadas'],
  },
  costas: {
    rigidez: ['ombros', 'lombar'],
    fisgada: ['irradia', 'ao_mexer'],
  },
  membros: {
    cansaco: ['juntas', 'pesados'],
    formigamento: ['dormentes', 'choque'],
  },
} as const;

export type EmotionalTime = keyof typeof EMOTIONAL_TREE;
export type PhysicalRegion = keyof typeof PHYSICAL_TREE;

export const EMOTIONAL_TIMES = Object.keys(EMOTIONAL_TREE) as EmotionalTime[];
export const PHYSICAL_REGIONS = Object.keys(PHYSICAL_TREE) as PhysicalRegion[];

/** Suffix of the key used when the person writes their own item (`<time>.custom`, `<region>.custom`). */
export const CUSTOM_SUFFIX = 'custom';

function flatten(tree: Record<string, Record<string, readonly string[]>>): string[] {
  const keys: string[] = [];
  for (const [first, branches] of Object.entries(tree)) {
    for (const [branch, options] of Object.entries(branches)) {
      for (const option of options) keys.push(`${first}.${branch}.${option}`);
    }
    keys.push(`${first}.${CUSTOM_SUFFIX}`);
  }
  return keys;
}

/** Every accepted emotional optionKey, custom keys included. */
export const EMOTIONAL_OPTION_KEYS: readonly string[] = flatten(EMOTIONAL_TREE);
/** Every accepted physical optionKey, custom keys included. */
export const PHYSICAL_OPTION_KEYS: readonly string[] = flatten(PHYSICAL_TREE);

export const ITEM_KINDS = ['emotional', 'physical', 'condition'] as const;
export type JournalItemKind = (typeof ITEM_KINDS)[number];

export const BODY_SIDES = ['front', 'back'] as const;
export const PERSISTENCE_KEYS = ['hoje', 'dias_semanas', 'meses_anos'] as const;
export const MOOD_KEYS = ['bem', 'normal', 'nao_tao_bem'] as const;

export const TRIGGER_KEYS = [
  'trabalho',
  'familia',
  'sono',
  'alimentacao',
  'esforco',
  'queda',
  'medicamento',
  'clima',
  'nao_sei',
  'outro',
] as const;

/** Triggers offered only when the entry has a physical item. */
export const PHYSICAL_ONLY_TRIGGER_KEYS = ['alimentacao', 'esforco', 'queda', 'medicamento', 'clima'] as const;

export const INTENSITY_MIN = 1;
export const INTENSITY_MAX = 5;

export const JOURNAL_LIMITS = {
  maxItems: 12,
  customLabelMax: 40,
  conditionLabelMax: 40,
  triggerNoteMax: 60,
  noteMax: 2000,
  maxActiveConditions: 10,
  clientIdMax: 128,
  maxTransitionVariantIds: 30,
  transitionVariantIdMax: 64,
  defaultDays: 30,
  maxDays: 365,
} as const;

/** First segment of an optionKey: the time (emotional) or the region (physical). */
export function optionKeyRoot(optionKey: string): string {
  return optionKey.split('.')[0];
}

export function isCustomOptionKey(optionKey: string): boolean {
  return optionKey.split('.')[1] === CUSTOM_SUFFIX;
}
