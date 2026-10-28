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
  EMOTIONAL_OPTION_KEYS,
  INTENSITY_MAX,
  INTENSITY_MIN,
  ITEM_KINDS,
  JOURNAL_LIMITS,
  JournalItemKind,
  MOOD_KEYS,
  PERSISTENCE_KEYS,
  PHYSICAL_ONLY_TRIGGER_KEYS,
  PHYSICAL_OPTION_KEYS,
  TRIGGER_KEYS,
  isCustomOptionKey,
} from '../constants/journal-keys.constant';

const ALL_OPTION_KEYS = [...EMOTIONAL_OPTION_KEYS, ...PHYSICAL_OPTION_KEYS];

/** Returns why an item is inconsistent with its kind, or null when it is valid. */
export function journalItemShapeError(item: Partial<JournalItemInputDto>): string | null {
  const hasText = typeof item.customLabel === 'string' && item.customLabel.trim().length > 0;
  switch (item.kind) {
    case 'condition':
      if (!item.conditionId) return 'conditionId é obrigatório para itens de condição.';
      if (item.optionKey || item.customLabel !== undefined || item.bodySide) {
        return 'Itens de condição não aceitam optionKey, customLabel nem bodySide.';
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
      if (item.kind === 'physical' && !item.bodySide) return 'bodySide é obrigatório para itens físicos.';
      if (item.kind === 'emotional' && item.bodySide) return 'bodySide só é aceito em itens físicos.';
      return null;
    }
    default:
      return null; // reported by @IsIn on kind
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
  bodySide?: (typeof BODY_SIDES)[number];

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
