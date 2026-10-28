import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsISO8601,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { CARE_DOCUMENT_KINDS, CARE_RECORD_KINDS, CareDocumentKind, CareRecordKind } from '../../database/schema/care.schema';

/**
 * Payloads of "Meus cuidados" (phases 12-14). Every field is what the person typed or
 * confirmed. There are no fields for doses calculated by the app, risk, conflicts or
 * judgments about values (docs/bienestar/PROPUESTA-CLIENTE-BIENESTAR.md §5).
 */

const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/;
const TIME_OF_DAY = /^([01]\d|2[0-3]):[0-5]\d$/;

export class VaccineDoseData {
  /** Key of the bundled official calendar entry, or absent for a private vaccine. */
  @IsOptional() @IsString() @MaxLength(60) vaccineKey?: string;
  @IsOptional() @IsString() @MaxLength(80) customName?: string;
  @IsString() @MinLength(1) @MaxLength(40) doseLabel!: string;
  @Matches(DATE_ONLY) appliedOn!: string;
  @IsOptional() @IsString() @MaxLength(40) batch?: string;
  @IsOptional() @IsString() @MaxLength(120) place?: string;
  /** Booster reminder date; the app fills it from the published calendar interval, the person can change it. */
  @IsOptional() @Matches(DATE_ONLY) boosterOn?: string;
  @IsOptional() @IsUUID() receiptDocumentId?: string;
  @IsOptional() @IsString() @MaxLength(500) note?: string;
}

export class AllergyData {
  @IsIn(['medication', 'food', 'other']) type!: 'medication' | 'food' | 'other';
  @IsString() @MinLength(1) @MaxLength(80) name!: string;
  /** The reaction in the person's own words. */
  @IsOptional() @IsString() @MaxLength(200) reaction?: string;
  @IsOptional() @Matches(DATE_ONLY) informedOn?: string;
  @IsBoolean() showOnProfile!: boolean;
}

export class MedicationData {
  @IsString() @MinLength(1) @MaxLength(120) name!: string;
  @IsOptional() @IsString() @MaxLength(40) strength?: string;
  @IsOptional() @IsString() @MaxLength(40) form?: string;
  /** Free text copied from the prescription, e.g. "1 comprimido". Never computed. */
  @IsOptional() @IsString() @MaxLength(80) amountPerIntake?: string;
  /** Prescription text as written, e.g. "1 comp. de 12/12h". Never turned into times by the app. */
  @IsOptional() @IsString() @MaxLength(300) instructions?: string;
  @IsArray() @ArrayMaxSize(12) @Matches(TIME_OF_DAY, { each: true }) times!: string[];
  /** ISO weekdays 1 (Monday) to 7; empty means every day. */
  @IsArray() @ArrayMaxSize(7) @IsInt({ each: true }) @Min(1, { each: true }) @Max(7, { each: true }) weekdays!: number[];
  @IsOptional() @Matches(DATE_ONLY) startOn?: string;
  @IsOptional() @Matches(DATE_ONLY) untilOn?: string;
  @IsOptional() @IsInt() @Min(0) @Max(100000) stockCount?: number;
  /** Units taken from the stock each time the person marks "Tomei" (default 1). */
  @IsOptional() @IsInt() @Min(1) @Max(100) stockPerIntake?: number;
  @IsOptional() @IsInt() @Min(0) @Max(100000) stockWarnAt?: number;
  @IsBoolean() active!: boolean;
  @IsOptional() @IsUUID() sourceDocumentId?: string;
}

export class AppointmentData {
  @IsISO8601({ strict: true }) startsAt!: string;
  @IsOptional() @IsString() @MaxLength(120) professional?: string;
  @IsOptional() @IsString() @MaxLength(80) specialty?: string;
  @IsOptional() @IsString() @MaxLength(160) place?: string;
  @IsOptional() @IsString() @MaxLength(1000) questions?: string;
  @IsOptional() @IsString() @MaxLength(2000) notes?: string;
  @IsIn(['none', '1d', '2h']) reminder!: 'none' | '1d' | '2h';
}

export class MedicationIntakeData {
  @IsISO8601({ strict: true }) scheduledFor!: string;
  @IsIn(['taken', 'snoozed', 'skipped']) action!: 'taken' | 'snoozed' | 'skipped';
}

/** Data class per record kind; intakes are created through the intake route only. */
export const CARE_DATA_CLASSES = {
  vaccine_dose: VaccineDoseData,
  allergy: AllergyData,
  medication: MedicationData,
  appointment: AppointmentData,
  medication_intake: MedicationIntakeData,
} satisfies Record<CareRecordKind, new () => object>;

export type EditableCareKind = Exclude<CareRecordKind, 'medication_intake'>;
export const EDITABLE_CARE_KINDS = CARE_RECORD_KINDS.filter((k) => k !== 'medication_intake') as EditableCareKind[];

export class CreateCareRecordDto {
  @IsIn(EDITABLE_CARE_KINDS) kind!: EditableCareKind;
  @IsObject() data!: Record<string, unknown>;
}

export class UpdateCareRecordDto {
  @IsObject() data!: Record<string, unknown>;
}

export class ListCareRecordsQueryDto {
  @IsIn(CARE_RECORD_KINDS) kind!: CareRecordKind;
  @IsOptional() @IsUUID() parentId?: string;
  @IsOptional() @IsISO8601() from?: string;
  @IsOptional() @IsISO8601() to?: string;
}

export class CreateIntakeDto extends MedicationIntakeData {}

export interface CareRecordResponse {
  id: string;
  kind: CareRecordKind;
  profileId: string;
  parentId: string | null;
  occursAt: string | null;
  data: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

// ---- Documents (exams, prescriptions, receipts) ----

export const MAX_DOCUMENT_BYTES = 10 * 1024 * 1024;
/** Formats Cloud Vision reads (HEIC is converted to JPEG on the phone). */
export const DOCUMENT_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'] as const;

export class UploadDocumentDto {
  @IsIn(CARE_DOCUMENT_KINDS) kind!: CareDocumentKind;
  @IsIn(DOCUMENT_MIME_TYPES) mime!: (typeof DOCUMENT_MIME_TYPES)[number];
  /** Base64 file content (≤ 10 MB decoded). */
  @IsString() @MinLength(8) @MaxLength(14_200_000) fileBase64!: string;
  /** false = only archive the file, no reading. */
  @IsBoolean() read!: boolean;
  @IsOptional() @IsString() @MaxLength(120) title?: string;
}

export class ExamValueDto {
  @IsString() @MinLength(1) @MaxLength(120) item!: string;
  /** Kept as printed (e.g. "1.250", "< 5", "Negativo"). */
  @IsString() @MinLength(1) @MaxLength(60) value!: string;
  @IsOptional() @IsString() @MaxLength(30) unit?: string;
  /** Reference interval exactly as printed by the lab. */
  @IsOptional() @IsString() @MaxLength(200) reference?: string;
  /** Every saved row must be confirmed by the person. */
  @IsBoolean() confirmed!: boolean;
}

export class PrescriptionFieldsDto {
  @IsString() @MinLength(1) @MaxLength(120) name!: string;
  @IsOptional() @IsString() @MaxLength(40) strength?: string;
  @IsOptional() @IsString() @MaxLength(300) instructions?: string;
}

export class ReviewDocumentDto {
  @IsOptional() @IsString() @MaxLength(120) title?: string;
  @IsOptional() @IsString() @MaxLength(120) labName?: string;
  @IsOptional() @Matches(DATE_ONLY) collectedOn?: string;
  @IsOptional() @IsArray() @ArrayMaxSize(200) @ValidateNested({ each: true }) @Type(() => ExamValueDto) values?: ExamValueDto[];
  @IsOptional() @IsArray() @ArrayMaxSize(20) @ValidateNested({ each: true }) @Type(() => PrescriptionFieldsDto) medications?: PrescriptionFieldsDto[];
  @IsOptional() @IsString() @MaxLength(2000) note?: string;
}

export class ListDocumentsQueryDto {
  @IsOptional() @IsIn(CARE_DOCUMENT_KINDS) kind?: CareDocumentKind;
}

/** What the reading step extracted, before the person confirms it. */
export interface DocumentReading {
  title?: string;
  labName?: string;
  collectedOn?: string;
  values?: Omit<ExamValueDto, 'confirmed'>[];
  medications?: PrescriptionFieldsDto[];
}

export interface DocumentData extends DocumentReading {
  note?: string;
  values?: ExamValueDto[];
}

export interface CareDocumentResponse {
  id: string;
  kind: CareDocumentKind;
  profileId: string;
  mime: string;
  sizeBytes: number;
  status: string;
  data: DocumentData;
  error: string | null;
  createdAt: string;
  updatedAt: string;
}
