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
}

export interface UserDataExportResponseDto {
  metadata: {
    exportDate: string;
    formatVersion: string;
    legalBasis: string;
    dataController: string;
    /** Explains the `legacy` block on symptom logs. */
    legacyFieldsNote: string;
  };
  profile: ExportedProfileDto;
  consents: ExportedConsentDto[];
  symptomLogs: ExportedSymptomLogDto[];
  safetyResourceEvents: ExportedSafetyResourceEventDto[];
  waterIntakeLogs: ExportedWaterIntakeLogDto[];
  dependentProfiles: ExportedDependentDataDto[];
}
