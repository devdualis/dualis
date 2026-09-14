export class RegulatoryCitationDto {
  regulatoryBody: string;
  normativeAct: string;
  summary: string;
  url: string;
}

export class EmergencyContactDto {
  name: string;
  phone: string;
  description: string;
}

export class MedicalDisclaimerResponseDto {
  version: string;
  language: string;
  disclaimerText: string;
  shortDisclaimer: string;
  citations: RegulatoryCitationDto[];
  emergencyContacts: EmergencyContactDto[];
}
