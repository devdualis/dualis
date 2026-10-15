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
  disposition: string | null;
  decryptedNarrative: string | null;
  stepAnswers: any | null;
  recordedAt: string;
}

export interface ExportedEmergencyEventDto {
  id: string;
  triggerCategory: string;
  severityLevel: number;
  sourceVertical: string;
  actionTaken: string | null;
  reportedAt: string;
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
  emergencyEvents: ExportedEmergencyEventDto[];
  waterIntakeLogs: ExportedWaterIntakeLogDto[];
}

export interface UserDataExportResponseDto {
  metadata: {
    exportDate: string;
    formatVersion: string;
    legalBasis: string;
    dataController: string;
  };
  profile: ExportedProfileDto;
  consents: ExportedConsentDto[];
  symptomLogs: ExportedSymptomLogDto[];
  emergencyEvents: ExportedEmergencyEventDto[];
  waterIntakeLogs: ExportedWaterIntakeLogDto[];
  dependentProfiles: ExportedDependentDataDto[];
}
