export interface ExportedProfileDto {
  id: string;
  name: string;
  email: string;
  gender: string;
  dateOfBirth: string | null;
  picture?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ExportedConsentDto {
  id: string;
  disclaimerVersion: string;
  acceptedAt: string;
  ipAddressHash: string;
  userAgent: string | null;
}

export interface ExportedSymptomLogDto {
  id: string;
  intensity: number;
  anatomicalSystem: string | null;
  emotionalDimension: string | null;
  /** Fields from the former assessment engine, no longer written (migration 0015). */
  legacy: ExportedLegacySymptomFieldsDto;
  decryptedNarrative: string | null;
  stepAnswers: any | null;
  recordedAt: string;
}

export interface ExportedLegacySymptomFieldsDto {
  disposition: string | null;
  organicPrimacyApplied: boolean;
}

/** Help resources opened or calls started (former emergency events, migrated by 0015). */
export interface ExportedSafetyResourceEventDto {
  id: string;
  action: string;
  channel: string | null;
  clientTimestamp: string;
  createdAt: string;
}

export interface ExportedWaterIntakeLogDto {
  id: string;
  amountMl: number;
  source: string;
  recordedAt: string;
}

/** One journal item: what the person chose (`optionKey`) or wrote (`customLabel`). */
export interface ExportedJournalItemDto {
  id: string;
  kind: string;
  optionKey: string | null;
  customLabel: string | null;
  conditionId: string | null;
  /** Name the person gave the condition, for `kind = condition`. */
  conditionLabel: string | null;
  bodySide: string | null;
  persistence: string | null;
  intensity: number | null;
}

export interface ExportedJournalEntryDto {
  id: string;
  clientId: string;
  recordedAt: string;
  mood: string;
  triggers: string[];
  triggerNote: string | null;
  note: string | null;
  createdAt: string;
  items: ExportedJournalItemDto[];
}

/** "Minhas condições", named by the person; archived ones included. */
export interface ExportedUserConditionDto {
  id: string;
  label: string | null;
  createdAt: string;
  archivedAt: string | null;
}

/**
 * "Meus cuidados" record as the person entered it: vaccine_dose, allergy, medication,
 * medication_intake or appointment. `data` holds the fields of that kind.
 */
export interface ExportedCareRecordDto {
  id: string;
  kind: string;
  /** For medication_intake: the medication it belongs to. */
  parentId: string | null;
  occursAt: string | null;
  data: Record<string, unknown> | null;
  createdAt: string;
  updatedAt: string;
}

/**
 * Exam, prescription or other document of "Meus cuidados": what was read and what the person
 * confirmed (`data`). The original file is not part of the export.
 */
export interface ExportedCareDocumentDto {
  id: string;
  kind: string;
  mime: string;
  sizeBytes: number;
  status: string;
  data: Record<string, unknown> | null;
  createdAt: string;
  updatedAt: string;
}

export interface ExportedDependentProfileDto {
  id: string;
  name: string;
  profileType: string;
  dateOfBirth: string | null;
  gender: string | null;
  createdAt: string;
}

/** Clinical data of one dependent profile owned by the exporting account. */
export interface ExportedDependentDataDto {
  profile: ExportedDependentProfileDto;
  symptomLogs: ExportedSymptomLogDto[];
  safetyResourceEvents: ExportedSafetyResourceEventDto[];
  waterIntakeLogs: ExportedWaterIntakeLogDto[];
  journalEntries: ExportedJournalEntryDto[];
  userConditions: ExportedUserConditionDto[];
  careRecords: ExportedCareRecordDto[];
  careDocuments: ExportedCareDocumentDto[];
}

export interface UserDataExportResponseDto {
  metadata: {
    exportDate: string;
    formatVersion: string;
    legalBasis: string;
    dataController: string;
    /** Explains the `legacy` block on symptom logs. */
    legacyFieldsNote: string;
    /** Says the original document files are not in the export and where to open them. */
    careDocumentsNote: string;
  };
  profile: ExportedProfileDto;
  consents: ExportedConsentDto[];
  symptomLogs: ExportedSymptomLogDto[];
  safetyResourceEvents: ExportedSafetyResourceEventDto[];
  waterIntakeLogs: ExportedWaterIntakeLogDto[];
  journalEntries: ExportedJournalEntryDto[];
  userConditions: ExportedUserConditionDto[];
  careRecords: ExportedCareRecordDto[];
  careDocuments: ExportedCareDocumentDto[];
  dependentProfiles: ExportedDependentDataDto[];
}
