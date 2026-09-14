import { Injectable, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  MedicalDisclaimerResponseDto,
  RegulatoryCitationDto,
  EmergencyContactDto,
} from './dto/medical-disclaimer-response.dto';

export type SupportedLanguage = 'pt-BR' | 'es' | 'en';

@Injectable()
export class LegalService {
  private readonly defaultVersion = '2026.1';

  constructor(@Inject(ConfigService) private readonly configService: ConfigService) {}

  getMedicalDisclaimer(
    requestedLang?: string,
    acceptLanguageHeader?: string,
  ): MedicalDisclaimerResponseDto {
    const lang = this.resolveLanguage(requestedLang, acceptLanguageHeader);
    const version =
      this.configService.get<string>('DISCLAIMER_VERSION') || this.defaultVersion;

    switch (lang) {
      case 'es':
        return this.getSpanishDisclaimer(version);
      case 'en':
        return this.getEnglishDisclaimer(version);
      case 'pt-BR':
      default:
        return this.getPortugueseDisclaimer(version);
    }
  }

  private resolveLanguage(lang?: string, acceptHeader?: string): SupportedLanguage {
    const candidate = (lang || acceptHeader || '').toLowerCase();
    if (candidate.startsWith('es') || candidate.includes('spanish')) {
      return 'es';
    }
    if (candidate.startsWith('en') || candidate.includes('english')) {
      return 'en';
    }
    return 'pt-BR';
  }

  private getPortugueseDisclaimer(version: string): MedicalDisclaimerResponseDto {
    const citations: RegulatoryCitationDto[] = [
      {
        regulatoryBody: 'Anvisa',
        normativeAct: 'RDC nº 657/2022',
        summary:
          'Regulamenta Software como Dispositivo Médico (SaMD); a plataforma atua estritamente em monitoramento preventivo e estratificação de risco sem exercer diagnóstico autônomo.',
        url: 'https://www.in.gov.br/en/web/dou/-/resolucao-rdc-n-657-de-24-de-marco-de-2022-389025000',
      },
      {
        regulatoryBody: 'Conselho Federal de Medicina (CFM)',
        normativeAct: 'Resolução CFM nº 2.314/2022',
        summary:
          'Define e disciplina a telemedicina no Brasil; ratifica a necessidade de supervisão médica direta em decisões diagnósticas e terapêuticas.',
        url: 'https://sistemas.cfm.org.br/normas/visualizar/resolucoes/BR/2022/2314',
      },
    ];

    const emergencyContacts: EmergencyContactDto[] = [
      {
        name: 'SAMU',
        phone: '192',
        description: 'Serviço de Atendimento Móvel de Urgência para emergências clínicas graves.',
      },
      {
        name: 'Bombeiros',
        phone: '193',
        description: 'Corpo de Bombeiros para resgates, traumas e acidentes.',
      },
      {
        name: 'CVV',
        phone: '188',
        description: 'Centro de Valorização da Vida — apoio emocional e prevenção do suicídio 24h.',
      },
    ];

    return {
      version,
      language: 'pt-BR',
      disclaimerText:
        'O DualisCheckUp é uma plataforma móvel de auto-monitoramento preventivo e triagem de bem-estar físico e psico-emocional baseada em protocolos clínicos reconhecidos. O aplicativo NÃO realiza diagnósticos médicos, NÃO prescreve medicamentos ou tratamentos e NÃO substitui a consulta clínica presencial ou o aconselhamento de um médico devidamente registrado no Conselho Regional de Medicina (CRM). Todas as informações e estratificações de risco fornecidas possuem finalidade estritamente informativa e preventiva.',
      shortDisclaimer:
        'O DualisCheckUp oferece triagem preventiva e não substitui a avaliação de um profissional médico.',
      citations,
      emergencyContacts,
    };
  }

  private getSpanishDisclaimer(version: string): MedicalDisclaimerResponseDto {
    const citations: RegulatoryCitationDto[] = [
      {
        regulatoryBody: 'Anvisa / Normas Sanitarias Regionales',
        normativeAct: 'RDC nº 657/2022',
        summary:
          'Regulación de Software como Dispositivo Médico (SaMD); la plataforma actúa exclusivamente en monitoreo preventivo y estratificación de riesgo sin emitir diagnósticos autónomos.',
        url: 'https://www.in.gov.br/en/web/dou/-/resolucao-rdc-n-657-de-24-de-marco-de-2022-389025000',
      },
      {
        regulatoryBody: 'Consejo Federal de Medicina (CFM)',
        normativeAct: 'Resolución CFM nº 2.314/2022',
        summary:
          'Regula la telemedicina y exige supervisión médica presencial para decisiones de diagnóstico y prescripción.',
        url: 'https://sistemas.cfm.org.br/normas/visualizar/resolucoes/BR/2022/2314',
      },
    ];

    const emergencyContacts: EmergencyContactDto[] = [
      {
        name: 'SAMU / Urgencias Médicas',
        phone: '192',
        description: 'Servicio de Atención Médica de Urgencias para situaciones clínicas agudas (en otros países llame al 911).',
      },
      {
        name: 'Bomberos / Rescate',
        phone: '193',
        description: 'Cuerpo de bomberos y unidades de rescate y trauma.',
      },
      {
        name: 'CVV / Asistencia en Crisis',
        phone: '188',
        description: 'Línea de contención emocional y prevención del suicidio confidencial y gratuita.',
      },
    ];

    return {
      version,
      language: 'es',
      disclaimerText:
        'DualisCheckUp es una plataforma móvil de automonitoreo preventivo y triaje de bienestar físico y psicoemocional basada en protocolos clínicos reconocidos. La aplicación NO realiza diagnósticos médicos, NO prescribe medicamentos ni tratamientos y NO reemplaza la consulta clínica presencial ni el asesoramiento de un profesional médico matriculado. Toda la información y estratificaciones de riesgo tienen fines estrictamente informativos y preventivos.',
      shortDisclaimer:
        'DualisCheckUp ofrece triaje preventivo y no reemplaza la evaluación médica profesional.',
      citations,
      emergencyContacts,
    };
  }

  private getEnglishDisclaimer(version: string): MedicalDisclaimerResponseDto {
    const citations: RegulatoryCitationDto[] = [
      {
        regulatoryBody: 'Anvisa / International SaMD Standards',
        normativeAct: 'RDC 657/2022',
        summary:
          'Regulates Software as a Medical Device (SaMD); this platform operates strictly as an auxiliary preventive wellness and risk stratification tool without claiming autonomous diagnostic authority.',
        url: 'https://www.in.gov.br/en/web/dou/-/resolucao-rdc-n-657-de-24-de-marco-de-2022-389025000',
      },
      {
        regulatoryBody: 'Federal Council of Medicine (CFM)',
        normativeAct: 'Resolution CFM 2.314/2022',
        summary:
          'Defines telemedicine practice, affirming mandatory direct medical oversight for clinical diagnosis and drug prescribing.',
        url: 'https://sistemas.cfm.org.br/normas/visualizar/resolucoes/BR/2022/2314',
      },
    ];

    const emergencyContacts: EmergencyContactDto[] = [
      {
        name: 'SAMU / Emergency Medical Services',
        phone: '192',
        description: 'Emergency medical dispatch for acute life-threatening situations (or 911 internationally).',
      },
      {
        name: 'Fire & Rescue Services',
        phone: '193',
        description: 'Fire department emergency response and rescue.',
      },
      {
        name: 'CVV / Crisis Hotline',
        phone: '188',
        description: 'Confidential emotional support and suicide prevention lifeline (or 988 in the US/Canada).',
      },
    ];

    return {
      version,
      language: 'en',
      disclaimerText:
        'DualisCheckUp is a mobile preventive self-monitoring and health triage platform bridging physical and psycho-emotional well-being based on recognized clinical protocols. The application DOES NOT provide medical diagnoses, DOES NOT prescribe medications or treatments, and DOES NOT replace in-person clinical consultations or medical advice from a licensed physician. All insights and risk stratifications are strictly for informational and preventive triage purposes.',
      shortDisclaimer:
        'DualisCheckUp provides preventive triage and does not replace professional medical evaluation.',
      citations,
      emergencyContacts,
    };
  }
}
