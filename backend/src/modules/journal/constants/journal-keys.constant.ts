/**
 * Journal v2 keys (docs/bienestar/CONTRATO-JOURNAL-V2.md). Single source for the backend
 * validation; the mobile app mirrors these lists. Keys name what the person chose,
 * nothing else is attached to them.
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

/**
 * Physical choices: region -> branch -> options. optionKey = `<region>.<branch>.<option>`.
 * Which branches show on each side of the body map: PHYSICAL_SIDE_BRANCHES.
 */
export const PHYSICAL_TREE = {
  cabeca: {
    pressao: ['temporas', 'latejando'],
    sentidos: ['garganta', 'olhos'], // front only
    nuca: ['rigida', 'pontada'], // back only
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
  // Whole body: no side, bodySide is null.
  pele: {
    coceira: ['coceira', 'ardencia'],
    aparencia: ['vermelhidao', 'manchas'],
  },
  musculos: {
    tensao: ['rigidez', 'caibra'],
    cansaco: ['fraqueza', 'dolorido'],
  },
  hormonios: {
    temperatura: ['calorao', 'frio'],
    apetite: ['sede', 'fome'],
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
export type BodySide = (typeof BODY_SIDES)[number];

/** Regions picked for the whole body, without a side: their items have bodySide null. */
export const WHOLE_BODY_REGIONS: readonly PhysicalRegion[] = ['pele', 'musculos', 'hormonios'];

/** Region -> branches shown on each side of the body map. `<region>.custom` follows its region. */
export const PHYSICAL_SIDE_BRANCHES: Record<BodySide, Partial<Record<PhysicalRegion, readonly string[]>>> = {
  front: {
    cabeca: ['pressao', 'sentidos'],
    peito: Object.keys(PHYSICAL_TREE.peito),
    barriga: Object.keys(PHYSICAL_TREE.barriga),
    membros: Object.keys(PHYSICAL_TREE.membros),
  },
  back: {
    cabeca: ['pressao', 'nuca'],
    costas: Object.keys(PHYSICAL_TREE.costas),
    membros: Object.keys(PHYSICAL_TREE.membros),
  },
};

export function isWholeBodyOptionKey(optionKey: string): boolean {
  return (WHOLE_BODY_REGIONS as readonly string[]).includes(optionKeyRoot(optionKey));
}

/** True when the physical optionKey is shown on that side of the body map. */
export function isOptionKeyOnSide(optionKey: string, side: BodySide): boolean {
  const [region, branch] = optionKey.split('.');
  const branches = PHYSICAL_SIDE_BRANCHES[side][region as PhysicalRegion];
  if (!branches) return false;
  return branch === CUSTOM_SUFFIX || branches.includes(branch);
}

export const PERSISTENCE_KEYS = ['hoje', 'dias_semanas', 'meses_anos'] as const;
/** `normal` is only accepted from old app versions (entries without `area`). */
export const MOOD_KEYS = ['bem', 'normal', 'nao_tao_bem'] as const;
export const ENTRY_MOOD_KEYS = ['bem', 'nao_tao_bem'] as const;

/** Axis recorded by one entry (journal v2.1). Null on older entries. */
export const ENTRY_AREAS = ['emotional', 'physical'] as const;
export type EntryArea = (typeof ENTRY_AREAS)[number];

/** How a physical item feels, chosen by the person. Physical items only. */
export const SENSATION_KEYS = ['dor', 'incomodo'] as const;
export type SensationKey = (typeof SENSATION_KEYS)[number];

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
  customLabelMax: 80,
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

/** First two segments of an optionKey: `<time>.<branch>` or `<region>.<branch>`. */
export function optionKeyBranch(optionKey: string): string {
  return optionKey.split('.').slice(0, 2).join('.');
}

export function isCustomOptionKey(optionKey: string): boolean {
  return optionKey.split('.')[1] === CUSTOM_SUFFIX;
}
