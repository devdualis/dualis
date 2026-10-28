import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsISO8601,
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
  BodySide,
  EMOTIONAL_OPTION_KEYS,
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
  PHYSICAL_OPTION_KEYS,
  SENSATION_KEYS,
  SensationKey,
  TRIGGER_KEYS,
  isCustomOptionKey,
  isOptionKeyOnSide,
  isWholeBodyOptionKey,
} from '../constants/journal-keys.constant';

const ALL_OPTION_KEYS = [...EMOTIONAL_OPTION_KEYS, ...PHYSICAL_OPTION_KEYS];

/** Returns why an item is inconsistent with its kind, or null when it is valid. */
export function journalItemShapeError(item: Partial<JournalItemInputDto>): string | null {
  const hasText = typeof item.customLabel === 'string' && item.customLabel.trim().length > 0;
  switch (item.kind) {
    case 'condition':
      if (!item.conditionId) return 'conditionId é obrigatório para itens de condição.';
      if (item.optionKey || item.customLabel !== undefined || item.bodySide || item.sensation) {
        return 'Itens de condição não aceitam optionKey, customLabel, bodySide nem sensation.';
      }
      return null;
    case 'emotional':
    case 'physical': {
      const keys = item.kind === 'emotional' ? EMOTIONAL_OPTION_KEYS : PHYSICAL_OPTION_KEYS;
      if (!item.optionKey || !keys.includes(item.optionKey)) return `optionKey inválido para ${item.kind}.`;
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

/**
 * Entry-level rules of journal v2.1. Entries with `area` come from v2.1 apps: one axis per
 * entry, mood `bem` or `nao_tao_bem`, a sensation on every physical item and each sided
 * option on a side where the map shows it. Entries without `area` (older apps, queued
 * outbox records) keep the v2 rules.
 */
export function journalEntryShapeError(entry: Partial<CreateJournalEntryDto>): string | null {
  const items = Array.isArray(entry.items) ? entry.items : [];
  if (!entry.area) return null;
  if (!(ENTRY_MOOD_KEYS as readonly string[]).includes(entry.mood ?? '')) {
    return `mood deve ser ${ENTRY_MOOD_KEYS.join(' ou ')} quando o registro tem area.`;
  }
  for (const item of items) {
    if (!item) continue;
    const otherAxis = entry.area === 'emotional' ? 'physical' : 'emotional';
    if (item.kind === otherAxis) return `Um registro com area ${entry.area} não aceita itens ${otherAxis}.`;
    if (item.kind !== 'physical' || !item.optionKey) continue;
    if (!item.sensation) return 'sensation é obrigatório para itens físicos quando o registro tem area.';
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

  @IsInt()
  @Min(INTENSITY_MIN)
  @Max(INTENSITY_MAX)
  intensity!: number;
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
}

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
