import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayUnique,
  ValidateIf,
  IsArray,
  IsIn,
  IsInt,
  IsISO8601,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  Validate,
  ValidateNested,
  ValidationArguments,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';
import {
  BODY_SIDES,
  COPING_KEYS,
  GLUCOSE_MOMENTS,
  GlucoseMoment,
  READING_INPUT_LIMITS,
  TRACKING_KINDS,
  TrackingKind,
  HELPER_KEYS,
  POSITIVE_OPTION_KEYS,
  BodySide,
  ACCEPTED_EMOTIONAL_OPTION_KEYS,
  ACCEPTED_PHYSICAL_OPTION_KEYS,
  ENTRY_AREAS,
  ENTRY_MOOD_KEYS,
  EntryArea,
  INTENSITY_MAX,
  INTENSITY_MIN,
  ITEM_KINDS,
  JOURNAL_LIMITS,
  JournalItemKind,
  MOOD_KEYS,
  PERSISTENCE_KEYS,
  PHYSICAL_ONLY_TRIGGER_KEYS,
  SENSATION_KEYS,
  SensationKey,
  TRIGGER_KEYS,
  isCustomOptionKey,
  isOptionKeyOnSide,
  isWholeBodyOptionKey,
} from '../constants/journal-keys.constant';

const ALL_OPTION_KEYS = [...ACCEPTED_EMOTIONAL_OPTION_KEYS, ...ACCEPTED_PHYSICAL_OPTION_KEYS, ...POSITIVE_OPTION_KEYS];

/** Returns why an item is inconsistent with its kind, or null when it is valid. */
export function journalItemShapeError(item: Partial<JournalItemInputDto>): string | null {
  const hasText = typeof item.customLabel === 'string' && item.customLabel.trim().length > 0;
  switch (item.kind) {
    case 'condition':
      if (!item.conditionId) return 'conditionId é obrigatório para itens de condição.';
      if (item.optionKey || item.customLabel !== undefined || item.bodySide || item.sensation) {
        return 'Itens de condição não aceitam optionKey, customLabel, bodySide nem sensation.';
      }
      if (item.intensity == null && !item.readings?.length) {
        return 'intensity é obrigatório em itens de condição sem readings.';
      }
      return null;
    case 'positive':
      if (item.readings !== undefined) return 'readings só é aceito em itens de condição.';
      if (!item.optionKey || !POSITIVE_OPTION_KEYS.includes(item.optionKey)) return 'optionKey inválido para positive.';
      if ([item.intensity, item.persistence, item.bodySide, item.sensation, item.conditionId].some((v) => v != null)) {
        return 'Itens positive não aceitam intensity, persistence, bodySide, sensation nem conditionId.';
      }
      if (isCustomOptionKey(item.optionKey) !== hasText) return 'customLabel é obrigatório com a chave custom e só é aceito com ela.';
      return null;
    case 'emotional':
    case 'physical': {
      const keys = item.kind === 'emotional' ? ACCEPTED_EMOTIONAL_OPTION_KEYS : ACCEPTED_PHYSICAL_OPTION_KEYS;
      if (!item.optionKey || !keys.includes(item.optionKey)) return `optionKey inválido para ${item.kind}.`;
      if (item.readings !== undefined) return 'readings só é aceito em itens de condição.';
      if (item.conditionId) return 'conditionId só é aceito em itens de condição.';
      if (!item.persistence) return 'persistence é obrigatório.';
      if (isCustomOptionKey(item.optionKey) !== hasText) {
        return 'customLabel é obrigatório com a chave custom e só é aceito com ela.';
      }
      if (item.kind === 'emotional') {
        if (item.bodySide) return 'bodySide só é aceito em itens físicos.';
        if (item.sensation) return 'sensation só é aceito em itens físicos.';
        return null;
      }
      if (isWholeBodyOptionKey(item.optionKey)) {
        if (item.bodySide) return 'Opções do corpo todo não aceitam bodySide.';
      } else if (!item.bodySide) {
        return 'bodySide é obrigatório para itens físicos.';
      }
      return null;
    }
    default:
      return null; // reported by @IsIn on kind
  }
}

const READING_FIELDS: Record<TrackingKind, readonly string[]> = {
  blood_pressure: ['systolic', 'diastolic', 'pulse'],
  glucose: ['mgdl', 'moment'],
  weight: ['kg'],
};
const ALL_READING_FIELDS = Object.values(READING_FIELDS).flat();

/** Returns why a reading carries fields of another kind, or null when it is valid. */
export function conditionReadingShapeError(reading: Partial<ConditionReadingInputDto>): string | null {
  const own = READING_FIELDS[reading.kind as TrackingKind];
  if (!own) return null; // reported by @IsIn on kind
  const foreign = ALL_READING_FIELDS.filter((f) => !own.includes(f) && (reading as Record<string, unknown>)[f] !== undefined);
  return foreign.length ? `Leituras ${reading.kind} não aceitam ${foreign.join(', ')}.` : null;
}

/**
 * measuredAt must sit between maxDaysBeforeRecorded days before the entry's recordedAt and
 * maxMinutesAfterRecorded minutes after it. Only catches a wrong date; nothing else.
 */
function readingTimeError(items: Array<Partial<JournalItemInputDto>>, recordedAt?: string): string | null {
  const recorded = recordedAt ? Date.parse(recordedAt) : NaN;
  if (isNaN(recorded)) return null; // reported by @IsISO8601 on recordedAt
  const earliest = recorded - READING_INPUT_LIMITS.maxDaysBeforeRecorded * 24 * 60 * 60 * 1000;
  const latest = recorded + READING_INPUT_LIMITS.maxMinutesAfterRecorded * 60 * 1000;
  for (const item of items) {
    for (const reading of Array.isArray(item?.readings) ? item.readings : []) {
      const measured = typeof reading?.measuredAt === 'string' ? Date.parse(reading.measuredAt) : NaN;
      if (isNaN(measured)) continue; // reported by @IsISO8601 on measuredAt
      if (measured < earliest || measured > latest) {
        return `measuredAt deve ficar entre ${READING_INPUT_LIMITS.maxDaysBeforeRecorded} dias antes e ${READING_INPUT_LIMITS.maxMinutesAfterRecorded} minutos depois de recordedAt.`;
      }
    }
  }
  return null;
}

/**
 * Entry-level rules of journal v2.1. Entries with `area` come from v2.1+ apps: one axis per
 * entry, mood `bem` or `nao_tao_bem` and each sided option on a side where the map shows it.
 * `sensation` is optional: v2.1 to v2.4 apps send it, v2.5 apps do not. Entries without
 * `area` (older apps, queued outbox records) keep the v2 rules.
 */
export function journalEntryShapeError(entry: Partial<CreateJournalEntryDto>): string | null {
  const items = Array.isArray(entry.items) ? entry.items : [];
  const helpers = entry.helpers ?? [];
  if (entry.coping != null && !(COPING_KEYS as readonly string[]).includes(entry.coping)) return 'coping inválido.';
  if (!Array.isArray(helpers) || helpers.length > 6 || new Set(helpers).size !== helpers.length ||
      helpers.some((h) => !(HELPER_KEYS as readonly string[]).includes(h))) return 'helpers inválido.';
  if ((entry.coping != null || helpers.length > 0) && entry.mood !== 'nao_tao_bem') {
    return 'coping e helpers só são aceitos com mood nao_tao_bem.';
  }
  if (helpers.includes('nada_ainda') && helpers.length > 1) return 'nada_ainda não pode ser combinado.';
  const timeError = readingTimeError(items, entry.recordedAt);
  if (timeError) return timeError;
  if (items.some((i) => i?.kind === 'positive')) {
    if (entry.mood !== 'bem' || entry.area !== 'emotional') return 'Itens positive exigem mood bem e area emotional.';
    if (items.some((i) => i?.kind === 'emotional' || i?.kind === 'physical')) return 'Itens positive não podem ser misturados com emotional ou physical.';
    if (entry.triggers?.length || entry.coping != null || helpers.length) return 'Itens positive não aceitam triggers, coping nem helpers.';
  }
  if (!entry.area) return null;
  if (!(ENTRY_MOOD_KEYS as readonly string[]).includes(entry.mood ?? '')) {
    return `mood deve ser ${ENTRY_MOOD_KEYS.join(' ou ')} quando o registro tem area.`;
  }
  for (const item of items) {
    if (!item) continue;
    const otherAxis = entry.area === 'emotional' ? 'physical' : 'emotional';
    if (item.kind === otherAxis) return `Um registro com area ${entry.area} não aceita itens ${otherAxis}.`;
    if (item.kind !== 'physical' || !item.optionKey) continue;
    if (item.bodySide && !isOptionKeyOnSide(item.optionKey, item.bodySide)) {
      return `${item.optionKey} não fica no lado ${item.bodySide} do corpo.`;
    }
  }
  return null;
}

@ValidatorConstraint({ name: 'journalEntryShape', async: false })
class JournalEntryShapeConstraint implements ValidatorConstraintInterface {
  validate(_value: unknown, args: ValidationArguments): boolean {
    return journalEntryShapeError(args.object as CreateJournalEntryDto) === null;
  }
  defaultMessage(args: ValidationArguments): string {
    return journalEntryShapeError(args.object as CreateJournalEntryDto) ?? 'Registro inválido.';
  }
}

@ValidatorConstraint({ name: 'journalItemShape', async: false })
class JournalItemShapeConstraint implements ValidatorConstraintInterface {
  validate(_value: unknown, args: ValidationArguments): boolean {
    return journalItemShapeError(args.object as JournalItemInputDto) === null;
  }
  defaultMessage(args: ValidationArguments): string {
    return journalItemShapeError(args.object as JournalItemInputDto) ?? 'Item inválido.';
  }
}

@ValidatorConstraint({ name: 'conditionReadingShape', async: false })
class ConditionReadingShapeConstraint implements ValidatorConstraintInterface {
  validate(_value: unknown, args: ValidationArguments): boolean {
    return conditionReadingShapeError(args.object as ConditionReadingInputDto) === null;
  }
  defaultMessage(args: ValidationArguments): string {
    return conditionReadingShapeError(args.object as ConditionReadingInputDto) ?? 'Leitura inválida.';
  }
}

@ValidatorConstraint({ name: 'physicalOnlyTriggers', async: false })
class PhysicalOnlyTriggersConstraint implements ValidatorConstraintInterface {
  validate(triggers: unknown, args: ValidationArguments): boolean {
    if (!Array.isArray(triggers)) return true;
    const entry = args.object as CreateJournalEntryDto;
    const hasPhysical = Array.isArray(entry.items) && entry.items.some((i) => i?.kind === 'physical');
    return hasPhysical || !triggers.some((t) => (PHYSICAL_ONLY_TRIGGER_KEYS as readonly string[]).includes(t));
  }
  defaultMessage(): string {
    return `${PHYSICAL_ONLY_TRIGGER_KEYS.join(', ')} só são aceitos quando o registro tem um item físico.`;
  }
}

const isBloodPressure = (r: ConditionReadingInputDto) => r.kind === 'blood_pressure';

/**
 * One reading the person typed on a tracked condition, with its own time. Values are kept
 * as typed; limits only catch typing slips.
 */
export class ConditionReadingInputDto {
  @IsIn(TRACKING_KINDS)
  @Validate(ConditionReadingShapeConstraint)
  kind!: TrackingKind;

  @IsISO8601()
  measuredAt!: string;

  @ValidateIf(isBloodPressure)
  @IsInt()
  @Min(READING_INPUT_LIMITS.systolic.min)
  @Max(READING_INPUT_LIMITS.systolic.max)
  systolic?: number;

  @ValidateIf(isBloodPressure)
  @IsInt()
  @Min(READING_INPUT_LIMITS.diastolic.min)
  @Max(READING_INPUT_LIMITS.diastolic.max)
  diastolic?: number;

  @ValidateIf((r) => isBloodPressure(r) && r.pulse != null)
  @IsInt()
  @Min(READING_INPUT_LIMITS.pulse.min)
  @Max(READING_INPUT_LIMITS.pulse.max)
  pulse?: number | null;

  @ValidateIf((r) => r.kind === 'glucose')
  @IsInt()
  @Min(READING_INPUT_LIMITS.mgdl.min)
  @Max(READING_INPUT_LIMITS.mgdl.max)
  mgdl?: number;

  @ValidateIf((r) => r.kind === 'glucose')
  @IsIn(GLUCOSE_MOMENTS)
  moment?: GlucoseMoment;

  @ValidateIf((r) => r.kind === 'weight')
  @IsNumber({ allowNaN: false, allowInfinity: false, maxDecimalPlaces: READING_INPUT_LIMITS.kg.decimals })
  @Min(READING_INPUT_LIMITS.kg.min)
  @Max(READING_INPUT_LIMITS.kg.max)
  kg?: number;
}

export class JournalItemInputDto {
  @IsIn(ITEM_KINDS)
  @Validate(JournalItemShapeConstraint)
  kind!: JournalItemKind;

  @IsOptional()
  @IsIn(ALL_OPTION_KEYS)
  optionKey?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(JOURNAL_LIMITS.customLabelMax)
  customLabel?: string;

  @IsOptional()
  @IsUUID()
  conditionId?: string;

  @IsOptional()
  @IsIn(BODY_SIDES)
  bodySide?: BodySide;

  @IsOptional()
  @IsIn(SENSATION_KEYS)
  sensation?: SensationKey;

  @IsOptional()
  @IsIn(PERSISTENCE_KEYS)
  persistence?: (typeof PERSISTENCE_KEYS)[number];

  // Optional on positive items and on condition items that carry readings.
  @ValidateIf(
    (item) => item.intensity != null || !(item.kind === 'positive' || (item.kind === 'condition' && item.readings?.length)),
  )
  @IsInt()
  @Min(INTENSITY_MIN)
  @Max(INTENSITY_MAX)
  intensity?: number | null;

  /** Condition items only (v2.4). */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(READING_INPUT_LIMITS.maxPerItem)
  @ValidateNested({ each: true })
  @Type(() => ConditionReadingInputDto)
  readings?: ConditionReadingInputDto[];
}

export class CreateJournalEntryDto {
  @IsString()
  @MinLength(1)
  @MaxLength(JOURNAL_LIMITS.clientIdMax)
  clientId!: string;

  @IsISO8601()
  recordedAt!: string;

  @IsIn(MOOD_KEYS)
  mood!: (typeof MOOD_KEYS)[number];

  /** Axis of this entry (v2.1 apps). Absent on entries from older apps. */
  @IsOptional()
  @IsIn(ENTRY_AREAS)
  area?: EntryArea;

  @IsArray()
  @ArrayMaxSize(TRIGGER_KEYS.length)
  @IsIn(TRIGGER_KEYS, { each: true })
  @Validate(PhysicalOnlyTriggersConstraint)
  triggers!: string[];

  @IsOptional()
  @IsIn(COPING_KEYS)
  coping?: (typeof COPING_KEYS)[number] | null;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(6)
  @ArrayUnique()
  @IsIn(HELPER_KEYS, { each: true })
  helpers?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(JOURNAL_LIMITS.triggerNoteMax)
  triggerNote?: string;

  @IsOptional()
  @IsString()
  @MaxLength(JOURNAL_LIMITS.noteMax)
  note?: string;

  @IsArray()
  @ArrayMaxSize(JOURNAL_LIMITS.maxTransitionVariantIds)
  @IsString({ each: true })
  @MaxLength(JOURNAL_LIMITS.transitionVariantIdMax, { each: true })
  @Matches(/^[a-z0-9_.-]+$/i, { each: true })
  transitionVariantIds!: string[];

  @IsArray()
  @ArrayMaxSize(JOURNAL_LIMITS.maxItems)
  @ValidateNested({ each: true })
  @Type(() => JournalItemInputDto)
  @Validate(JournalEntryShapeConstraint)
  items!: JournalItemInputDto[];
}

export class JournalDaysQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(JOURNAL_LIMITS.maxDays)
  days?: number;

  /** Minutes east of UTC on the device (e.g. -180 for Brasília), used to count calendar days. */
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(-720)
  @Max(840)
  tzOffset?: number;
}

export class CreateConditionDto {
  @IsString()
  @Matches(/\S/, { message: 'label não pode ser vazio.' })
  @MaxLength(JOURNAL_LIMITS.conditionLabelMax)
  label!: string;

  /** Readings the person chose to note (v2.4). Default: none. */
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @ArrayMaxSize(TRACKING_KINDS.length)
  @IsIn(TRACKING_KINDS, { each: true })
  tracking?: TrackingKind[];
}

/** PATCH /v1/journal/conditions/:id. Absent fields stay as they are. */
export class UpdateConditionDto {
  @IsOptional()
  @IsString()
  @Matches(/\S/, { message: 'label não pode ser vazio.' })
  @MaxLength(JOURNAL_LIMITS.conditionLabelMax)
  label?: string;

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @ArrayMaxSize(TRACKING_KINDS.length)
  @IsIn(TRACKING_KINDS, { each: true })
  tracking?: TrackingKind[];
}

export class ConditionReadingsQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(JOURNAL_LIMITS.maxDays)
  days?: number;
}

export interface JournalItemDto {
  id: string;
  kind: JournalItemKind;
  optionKey: string | null;
  customLabel: string | null;
  conditionId: string | null;
  /** Condition name as the person wrote it (condition items only). */
  label: string | null;
  bodySide: string | null;
  /** `dor` | `incomodo` on physical items of v2.1 entries; null otherwise. */
  sensation: string | null;
  persistence: string | null;
  intensity: number | null;
  /** Readings on a condition item (v2.4), as typed; empty on every other item. */
  readings: ConditionReadingDto[];
}

/** A stored reading, decrypted. Only the fields of its kind are present. */
export type ConditionReadingDto = {
  id: string;
  entryId: string;
  conditionId: string;
  measuredAt: string;
} & (
  | { kind: 'blood_pressure'; systolic: number; diastolic: number; pulse: number | null }
  | { kind: 'glucose'; mgdl: number; moment: GlucoseMoment }
  | { kind: 'weight'; kg: number }
);

export interface LegacyJournalItemDto {
  kind: 'emotional' | 'physical';
  legacyLabel: string;
  intensity: number | null;
}

export interface JournalEntryDto {
  id: string;
  legacy: false;
  clientId: string;
  recordedAt: string;
  mood: string;
  /** `emotional` | `physical`; null on entries saved before v2.1. */
  area: string | null;
  triggers: string[];
  coping: string | null;
  helpers: string[];
  triggerNote: string | null;
  note: string | null;
  transitionVariantIds: string[];
  items: JournalItemDto[];
  createdAt: string;
}

/** A symptom_logs row from the previous journal, shown as "registro anterior". */
export interface LegacyJournalEntryDto {
  id: string;
  legacy: true;
  recordedAt: string;
  note: string | null;
  items: LegacyJournalItemDto[];
}

export interface JournalEntriesResponseDto {
  entries: Array<JournalEntryDto | LegacyJournalEntryDto>;
}

export interface UserConditionDto {
  id: string;
  label: string;
  /** Readings the person chose to note (v2.4); [] when none. */
  tracking: TrackingKind[];
  createdAt: string;
}

export interface UserConditionsResponseDto {
  conditions: UserConditionDto[];
}

/**
 * Counts only: no labels, no text, no interpretation. Every `by*` count and every
 * `cooccurrence.days` is a number of distinct local days (device day from `tzOffset`).
 */
export interface JournalSummaryDto {
  days: number;
  totalEntries: number;
  daysWithEntries: number;
  byTime: Record<string, number>;
  byRegion: Record<string, number>;
  byOptionKey: Record<string, number>;
  byTrigger: Record<string, number>;
  positive: { byTime: Record<string, number>; byOptionKey: Record<string, number> };
  byCoping: Record<string, number>;
  byHelper: Record<string, number>;
  cooccurrence: Array<{ a: string; b: string; days: number }>;
}

export class SuggestJournalOptionDto {
  @IsString()
  @MinLength(1)
  @MaxLength(JOURNAL_LIMITS.customLabelMax)
  text!: string;

  @IsIn(['emotional', 'physical'])
  kind!: 'emotional' | 'physical';

  /** Branch on screen (`futuro.mente`, `cabeca.pressao`): only its options are suggested. */
  @IsOptional()
  @IsString()
  @Matches(/^[a-z_]+\.[a-z_]+$/)
  branch?: string;

  /** Side on screen (physical only). Whole-body options are offered on both sides. */
  @IsOptional()
  @IsIn(BODY_SIDES)
  bodySide?: BodySide;
}

export class SuggestJournalOptionResponseDto {
  optionKey: string | null;
}
