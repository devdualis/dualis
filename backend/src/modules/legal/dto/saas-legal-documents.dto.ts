export class LegalEntityDetailsDto {
  companyName: string;
  tradingName: string;
  taxId: string;
  country: string;
  registeredAddress: string;
  legalEmail: string;
  dpoEmail: string;
  supportEmail: string;
  operationalJurisdiction: string;
}

export class LegalSectionDto {
  sectionId: string;
  title: string;
  content: string;
  bullets?: string[];
}

export class TermsOfServiceResponseDto {
  version: string;
  effectiveDate: string;
  lastUpdated: string;
  language: string;
  legalEntity: LegalEntityDetailsDto;
  title: string;
  summary: string;
  sections: LegalSectionDto[];
}

export class PrivacyPolicyResponseDto {
  version: string;
  effectiveDate: string;
  lastUpdated: string;
  language: string;
  legalEntity: LegalEntityDetailsDto;
  title: string;
  summary: string;
  lgpdCompliance: {
    legalBases: string[];
    sensitiveDataArticle: string;
    dpoContact: string;
    rights: string[];
  };
  sections: LegalSectionDto[];
}

export class SecurityPolicyResponseDto {
  version: string;
  lastUpdated: string;
  language: string;
  encryptionInTransit: string;
  encryptionAtRest: string;
  passwordHashing: string;
  tenantIsolation: string;
  backupAndDisasterRecovery: string;
  incidentResponsePlan: {
    commitment: string;
    breachNotificationWindowHours: number;
    regulatoryNotificationBody: string;
  };
  sections: LegalSectionDto[];
}
