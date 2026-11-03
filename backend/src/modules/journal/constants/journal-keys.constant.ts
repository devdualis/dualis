/**
 * Journal v2 keys (docs/bienestar/CONTRATO-JOURNAL-V2.md). Single source for the backend
 * validation; the mobile app mirrors these lists. Keys name what the person chose,
 * nothing else is attached to them.
 */

/** Emotional choices: time -> branch -> options. optionKey = `<time>.<branch>.<option>`. */
export const EMOTIONAL_TREE = {
  passado: {
    tristeza: ['culpa', 'saudade'],
    memoria: ['lembranca', 'magoa', 'vergonha'],
  },
  presente: {
    energia: ['corpo', 'desligado', 'concentracao'],
    sobrecarga: ['paciencia', 'aperto', 'muita_coisa', 'inquieto'],
  },
  futuro: {
    mente: ['antecipar', 'cobranca', 'indecisao'],
    medo: ['julgamento', 'desanimo', 'evitar'],
  },
} as const;

/**
 * Physical choices offered by the app: region -> branch -> options.
 * optionKey = `<region>.<branch>.<option>`. Since v2.5 no screen shows more than 2 branches.
 * Which branches show on each side of the body map: PHYSICAL_SIDE_BRANCHES.
 */
export const PHYSICAL_TREE = {
  cabeca: {
    pressao: ['temporas', 'latejando', 'tontura', 'mandibula'],
    sentidos: ['garganta', 'olhos', 'nariz', 'ouvido'], // front only
    nuca: ['rigida', 'pontada'], // back only
  },
  peito: {
    respiracao: ['curta', 'tosse'],
    incomodo: ['batedeira', 'costelas'],
  },
  barriga: {
    queimacao: ['subindo', 'enjoo'],
    colica: ['gases', 'pontadas', 'preso', 'solto', 'menstrual'],
  },
  // Pelvis and lower belly, front only (v2.3). Kept apart from barriga.
  pelve: {
    xixi_intima: ['ardencia', 'vontade', 'coceira', 'inchaco'],
    baixo_ventre: ['colica', 'peso', 'menstrual'],
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

/** Emotional optionKeys the app offers today, custom keys included. */
export const EMOTIONAL_OPTION_KEYS: readonly string[] = flatten(EMOTIONAL_TREE);
/** Physical optionKeys the app offers today, custom keys included. */
export const PHYSICAL_OPTION_KEYS: readonly string[] = flatten(PHYSICAL_TREE);

/**
 * Keys of app versions v2.2 to v2.4 that the app no longer offers (v2.5). Old entries and
 * offline outbox items still carry them, so they stay accepted. Kept apart from the trees
 * above so the AI suggestion catalog only offers current keys.
 */
export const LEGACY_EMOTIONAL_OPTION_KEYS: readonly string[] = ['presente.solidao.sozinho', 'presente.solidao.menos'];
export const LEGACY_PHYSICAL_OPTION_KEYS: readonly string[] = [
  'cabeca.rosto.tontura',
  'cabeca.rosto.nariz',
  'cabeca.rosto.ouvido',
  'cabeca.rosto.mandibula',
  'barriga.intestino.preso',
  'barriga.intestino.solto',
  'pelve.urina.ardencia',
  'pelve.urina.vontade',
  'pelve.urina.dificuldade',
  'pelve.urina.cor_odor',
  'pelve.intima.coceira',
  'pelve.intima.inchaco',
];

/** Every emotional optionKey the API accepts: offered and legacy. */
export const ACCEPTED_EMOTIONAL_OPTION_KEYS: readonly string[] = [...EMOTIONAL_OPTION_KEYS, ...LEGACY_EMOTIONAL_OPTION_KEYS];
/** Every physical optionKey the API accepts: offered and legacy. */
export const ACCEPTED_PHYSICAL_OPTION_KEYS: readonly string[] = [...PHYSICAL_OPTION_KEYS, ...LEGACY_PHYSICAL_OPTION_KEYS];

export const POSITIVE_TREE = {
  passado: { gratidao: ['alguem', 'algo'], orgulho: ['conquista', 'resolvi'] },
  presente: { calma: ['paz', 'descansado'], conexao: ['pessoas', 'foco'] },
  futuro: { animo: ['planos', 'esperanca'], confianca: ['confiante', 'preparado'] },
} as const;
export const POSITIVE_OPTION_KEYS: readonly string[] = flatten(POSITIVE_TREE);
export const COPING_KEYS = ['consegui', 'esperei', 'dificil'] as const;
export const EMOTIONAL_HELPER_KEYS = [
  'mexer_corpo',
  'conversar',
  'pausa',
  'lazer',
  'descansar',
  'nada_ainda',
] as const;
export const PHYSICAL_HELPER_KEYS = [
  'beber_agua',
  'remedio',
  'repouso',
  'compressa',
  'alimentacao_leve',
  'consulta_medica',
  'nada_ainda',
] as const;
export const HELPER_KEYS = [
  'mexer_corpo',
  'conversar',
  'pausa',
  'lazer',
  'descansar',
  'beber_agua',
  'remedio',
  'repouso',
  'compressa',
  'alimentacao_leve',
  'consulta_medica',
  'nada_ainda',
] as const;

export const ITEM_KINDS = ['emotional', 'physical', 'condition', 'positive'] as const;
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
    pelve: Object.keys(PHYSICAL_TREE.pelve),
    membros: Object.keys(PHYSICAL_TREE.membros),
  },
  back: {
    cabeca: ['pressao', 'nuca'],
    costas: Object.keys(PHYSICAL_TREE.costas),
    membros: Object.keys(PHYSICAL_TREE.membros),
  },
};

/** Sides of the legacy branches (v2.2 to v2.4), all front only. */
const LEGACY_SIDE_BRANCHES: Record<BodySide, Partial<Record<PhysicalRegion, readonly string[]>>> = {
  front: { cabeca: ['rosto'], barriga: ['intestino'], pelve: ['urina', 'intima'] },
  back: {},
};

export function isWholeBodyOptionKey(optionKey: string): boolean {
  return (WHOLE_BODY_REGIONS as readonly string[]).includes(optionKeyRoot(optionKey));
}

/** True when the physical optionKey is shown on that side of the body map. */
export function isOptionKeyOnSide(optionKey: string, side: BodySide): boolean {
  const [region, branch] = optionKey.split('.');
  const branches = PHYSICAL_SIDE_BRANCHES[side][region as PhysicalRegion];
  if (!branches) return false;
  const legacy = LEGACY_SIDE_BRANCHES[side][region as PhysicalRegion] ?? [];
  return branch === CUSTOM_SUFFIX || branches.includes(branch) || legacy.includes(branch);
}

export const PERSISTENCE_KEYS = ['hoje', 'dias_semanas', 'meses_anos'] as const;
/** `normal` is only accepted from old app versions (entries without `area`). */
export const MOOD_KEYS = ['bem', 'normal', 'nao_tao_bem'] as const;
export const ENTRY_MOOD_KEYS = ['bem', 'nao_tao_bem'] as const;

/** Axis recorded by one entry (journal v2.1). Null on older entries. */
export const ENTRY_AREAS = ['emotional', 'physical'] as const;
export type EntryArea = (typeof ENTRY_AREAS)[number];

/**
 * How a physical item felt, chosen by the person on app versions v2.1 to v2.4. Optional and
 * physical items only; the app stopped asking it in v2.5, old clients may still send it.
 */
export const SENSATION_KEYS = ['dor', 'incomodo'] as const;
export type SensationKey = (typeof SENSATION_KEYS)[number];

export const TRIGGER_KEYS = [
  'trabalho',
  'familia',
  'sono',
  'dinheiro',
  'telas',
  'ciclo',
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

/**
 * Readings a person can choose to note on one of their conditions (v2.4). Chosen by the
 * person, never derived from the condition label.
 */
export const TRACKING_KINDS = ['blood_pressure', 'glucose', 'weight'] as const;
export type TrackingKind = (typeof TRACKING_KINDS)[number];

/** When a glucose reading was taken, as the person says it. */
export const GLUCOSE_MOMENTS = ['jejum', 'pre_refeicao', 'pos_refeicao', 'dormir'] as const;
export type GlucoseMoment = (typeof GLUCOSE_MOMENTS)[number];

/**
 * Input limits for readings. Wide on purpose: they only catch typing slips (1300 for 130).
 * They are not shown as a band and say nothing about the value.
 */
export const READING_INPUT_LIMITS = {
  systolic: { min: 50, max: 300 },
  diastolic: { min: 30, max: 200 },
  pulse: { min: 30, max: 250 },
  mgdl: { min: 20, max: 1000 },
  kg: { min: 10, max: 500, decimals: 2 },
  maxPerItem: 10,
  /** measuredAt may be up to this many minutes after the entry's recordedAt (clock slips). */
  maxMinutesAfterRecorded: 10,
  /** measuredAt may be up to this many days before the entry's recordedAt. */
  maxDaysBeforeRecorded: 7,
  defaultHistoryDays: 90,
} as const;

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

export function optionKeyRoot(optionKey: string): string {
  return optionKey.split('.')[0];
}

export function optionKeyBranch(optionKey: string): string {
  const parts = optionKey.split('.');
  return `${parts[0]}.${parts[1]}`;
}

export function isCustomOptionKey(optionKey: string): boolean {
  return optionKey.endsWith(`.${CUSTOM_SUFFIX}`);
}
