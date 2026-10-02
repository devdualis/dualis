import { Injectable, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  MedicalDisclaimerResponseDto,
  RegulatoryCitationDto,
  EmergencyContactDto,
} from './dto/medical-disclaimer-response.dto';
import {
  LegalEntityDetailsDto,
  TermsOfServiceResponseDto,
  PrivacyPolicyResponseDto,
  SecurityPolicyResponseDto,
} from './dto/saas-legal-documents.dto';

export type SupportedLanguage = 'pt-BR' | 'es' | 'en';

@Injectable()
export class LegalService {
  private readonly defaultVersion = '2026.1';

  constructor(@Inject(ConfigService) private readonly configService: ConfigService) {}

  public getLegalEntityDetails(): LegalEntityDetailsDto {
    return {
      companyName: 'DualisCheckUp Saúde e Tecnologia Ltda.',
      tradingName: 'DualisCheckUp',
      taxId: '48.291.834/0001-92',
      country: 'Brasil',
      registeredAddress: 'Av. Paulista, 1374 - Bela Vista, São Paulo - SP, CEP 01310-100',
      legalEmail: 'legal@dualischeckup.com',
      dpoEmail: 'dpo@dualischeckup.com',
      supportEmail: 'suporte@dualischeckup.com',
      operationalJurisdiction: 'Comarca de São Paulo, Estado de São Paulo, Brasil (Foro Eleito)',
    };
  }

  public getTermsOfService(
    requestedLang?: string,
    acceptLanguageHeader?: string,
  ): TermsOfServiceResponseDto {
    const lang = this.resolveLanguage(requestedLang, acceptLanguageHeader);
    const version = this.configService.get<string>('TERMS_VERSION') || this.defaultVersion;
    const entity = this.getLegalEntityDetails();
    const effectiveDate = '2026-01-01';
    const lastUpdated = '2026-10-01';

    if (lang === 'es') {
      return {
        version,
        effectiveDate,
        lastUpdated,
        language: 'es',
        legalEntity: entity,
        title: 'Términos y Condiciones de Uso del SaaS DualisCheckUp',
        summary:
          'Contrato de prestación de servicios de software para monitoreo preventivo de salud y triaje clínico inteligente.',
        sections: [
          {
            sectionId: '1-acceptance',
            title: '1. Aceptación de los Términos y Capacidad Legal',
            content:
              'Al crear una cuenta o utilizar la plataforma DualisCheckUp, usted acepta vincularse legalmente a estos Términos de Uso. Debe tener al menos 18 años o la mayoría de edad legal en su jurisdicción para suscribirse.',
          },
          {
            sectionId: '2-nature-of-service',
            title: '2. Naturaleza del Servicio y Descargo de Responsabilidad Médica',
            content:
              'DualisCheckUp es un Software como Servicio (SaaS) destinado exclusivamente al automonitoreo preventivo y triaje de bienestar somático y psicoemocional.',
            bullets: [
              'No es un dispositivo de diagnóstico médico autónomo (Anvisa RDC nº 657/2022).',
              'No prescribe medicamentos ni tratamientos clínicos (Res. CFM nº 2.314/2022).',
              'En situaciones de emergencia médica o riesgo vital, debe llamar inmediatamente al 192 (SAMU), 193 o a los servicios de urgencias locales.',
            ],
          },
          {
            sectionId: '3-subscriptions-billing-refunds',
            title: '3. Suscripciones, Facturación, Cancelaciones y Reembolsos',
            content:
              'El acceso a funcionalidades avanzadas se realiza mediante suscripciones periódicas procesadas por pasarelas externas certificadas (PCI-DSS Nivel 1).',
            bullets: [
              'Puede cancelar su suscripción en cualquier momento desde la configuración de su cuenta sin penalizaciones.',
              'De conformidad con las normas de protección al consumidor, los usuarios tienen derecho a retracto y reembolso total dentro de los 7 (siete) días posteriores a la primera contratación.',
              'La cancelación impedirá la renovación en el período subsiguiente, manteniendo el acceso hasta el fin del ciclo pagado.',
            ],
          },
          {
            sectionId: '4-intellectual-property',
            title: '4. Propiedad Intelectual',
            content:
              'Todos los modelos de clasificación clínica, algoritmos heurísticos, código fuente, interfaces y marcas registradas son propiedad exclusiva de DualisCheckUp Saúde e Tecnologia Ltda. Queda prohibida la ingeniería inversa, extracción de datos o uso no autorizado.',
          },
          {
            sectionId: '5-suspension-termination',
            title: '5. Suspensión y Cancelación de Cuenta por Mal Uso',
            content:
              'Nos reservamos el derecho de suspender o revocar el acceso a cuentas que incurran en fraude, intentos de vulneración de seguridad o uso malintencionado que comprometa la integridad de la plataforma o de otros usuarios.',
          },
          {
            sectionId: '6-jurisdiction',
            title: '6. Ley Aplicable y Jurisdicción',
            content:
              'Estos términos se rigen por las leyes de la República Federativa de Brasil. Cualquier disputa será resuelta prioritariamente ante los fueros de la Comarca de São Paulo - SP.',
          },
        ],
      };
    }

    if (lang === 'en') {
      return {
        version,
        effectiveDate,
        lastUpdated,
        language: 'en',
        legalEntity: entity,
        title: 'DualisCheckUp SaaS Terms of Service',
        summary:
          'Software-as-a-Service customer contract for preventive health self-monitoring and intelligent clinical triage.',
        sections: [
          {
            sectionId: '1-acceptance',
            title: '1. Acceptance of Terms & Legal Capacity',
            content:
              'By creating an account or accessing DualisCheckUp, you agree to be bound by these Terms. You must be at least 18 years of age or the legal age of majority in your jurisdiction to register.',
          },
          {
            sectionId: '2-nature-of-service',
            title: '2. Nature of the Service & Medical Disclaimer',
            content:
              'DualisCheckUp provides preventive health wellness tracking and risk stratification tools. It is not an autonomous diagnostic medical device under Anvisa RDC 657/2022 or international SaMD regulations. Always seek direct medical care for acute emergencies.',
          },
          {
            sectionId: '3-subscriptions-billing-refunds',
            title: '3. Subscriptions, Billing, Cancellations & Refunds',
            content:
              'Subscriptions are billed on a recurring basis via certified PCI-DSS Level 1 payment processors. Users can cancel at any time with no lock-in fees. A 7-day unconditional refund window applies to all initial subscription charges.',
          },
          {
            sectionId: '4-intellectual-property',
            title: '4. Intellectual Property Rights',
            content:
              'All clinical models, software architecture, UI components, and proprietary trademarks are owned exclusively by DualisCheckUp. Reverse engineering, data scraping, or unauthorized exploitation is strictly prohibited.',
          },
          {
            sectionId: '5-suspension-termination',
            title: '5. Account Suspension & Abuse Protection',
            content:
              'We reserve the right to suspend or terminate accounts engaging in security violations, credential stuffing, or harmful use that damages the service infrastructure.',
          },
          {
            sectionId: '6-jurisdiction',
            title: '6. Governing Law & Dispute Resolution',
            content:
              'These terms are governed by the laws of Brazil and applicable international consumer standards. Forum selection is the Judicial District of São Paulo, SP, Brazil.',
          },
        ],
      };
    }

    // Default: Portuguese (pt-BR)
    return {
      version,
      effectiveDate,
      lastUpdated,
      language: 'pt-BR',
      legalEntity: entity,
      title: 'Termos e Condições de Uso do SaaS DualisCheckUp',
      summary:
        'Contrato de prestação de serviços de software em nuvem para automonitoramento preventivo de saúde e triagem clínica inteligente.',
      sections: [
        {
          sectionId: '1-aceitacao',
          title: '1. Aceitação dos Termos e Capacidade Civil',
          content:
            'Ao criar uma conta ou utilizar o aplicativo DualisCheckUp, o Usuário declara ter capacidade civil plena (maior de 18 anos) e concorda expressamente com as disposições deste Contrato de Prestação de Serviços de Software.',
        },
        {
          sectionId: '2-natureza-e-isencao-medica',
          title: '2. Natureza da Plataforma e Limitação de Responsabilidade Clínica',
          content:
            'O DualisCheckUp atua como ferramenta auxiliar de bem-estar e estratificação de risco preventivo nos termos da RDC Anvisa nº 657/2022.',
          bullets: [
            'O serviço NÃO substitui a avaliação presencial de um médico com CRM ativo.',
            'O software NÃO realiza diagnósticos nosológicos definitivos e NÃO prescreve fármacos.',
            'Em sintomas agudos de intensidade crítica (Nível 4 ou 5), o aplicativo aciona a tela de emergência com discagem direta ao SAMU (192).',
          ],
        },
        {
          sectionId: '3-pagamentos-cancelamento-reembolso',
          title: '3. Planos, Cobrança, Cancelamento e Política de Reembolso',
          content:
            'O acesso a recursos avançados de histórico longitudinal é disponibilizado mediante planos de assinatura intermediados por processadores de pagamento seguros homologados PCI-DSS.',
          bullets: [
            'O Usuário pode cancelar sua assinatura a qualquer momento através do aplicativo, sem multas rescisórias.',
            'Direito de Arrependimento: Em conformidade com o Art. 49 do Código de Defesa do Consumidor (CDC), o Usuário pode solicitar reembolso integral no prazo de até 7 (sete) dias após a primeira contratação.',
            'A solicitação de cancelamento interrompe cobranças futuras e mantém o acesso ativo até o encerramento do ciclo mensal já quitado.',
          ],
        },
        {
          sectionId: '4-propriedade-intelectual',
          title: '4. Propriedade Intelectual e Licença de Uso',
          content:
            'A DualisCheckUp Saúde e Tecnologia Ltda. é titular exclusiva de todos os direitos autorais, patentes, segredos comerciais, marcas e algoritmos de triagem da plataforma. É vedada a engenharia reversa, cópia ou comercialização não autorizada.',
        },
        {
          sectionId: '5-suspensao-e-rescisao',
          title: '5. Suspensão de Acesso por Violação de Segurança',
          content:
            'A administração do sistema reserva-se o direito de suspender cautelarmente contas que tentem violar o isolamento multitenant, executar varreduras automatizadas ou submeter conteúdo malicioso.',
        },
        {
          sectionId: '6-foro',
          title: '6. Legislação Aplicável e Foro de Eleição',
          content:
            'Estes Termos são regidos pela legislação brasileira (Lei nº 12.965/2014 - Marco Civil da Internet e Lei nº 13.709/2018 - LGPD). Fica eleito o Foro da Comarca de São Paulo/SP para dirimir quaisquer controvérsias.',
        },
      ],
    };
  }

  public getPrivacyPolicy(
    requestedLang?: string,
    acceptLanguageHeader?: string,
  ): PrivacyPolicyResponseDto {
    const lang = this.resolveLanguage(requestedLang, acceptLanguageHeader);
    const version = this.configService.get<string>('PRIVACY_VERSION') || this.defaultVersion;
    const entity = this.getLegalEntityDetails();
    const effectiveDate = '2026-01-01';
    const lastUpdated = '2026-10-01';

    const rights = [
      'Confirmação da existência de tratamento e acesso aos dados.',
      'Portabilidade dos dados em formato interoperável (JSON estruturado via Central de Privacidade).',
      'Correção de dados incompletos, inexatos ou desatualizados.',
      'Eliminação imediata e irrevogável dos dados pessoais e sensíveis.',
      'Revogação do consentimento a qualquer momento com encerramento de sessão.',
    ];

    if (lang === 'es') {
      return {
        version,
        effectiveDate,
        lastUpdated,
        language: 'es',
        legalEntity: entity,
        title: 'Política de Privacidad y Protección de Datos de DualisCheckUp',
        summary:
          'Normas de recolección, tratamiento, almacenamiento seguro y eliminación de datos personales y sensibles de salud.',
        lgpdCompliance: {
          legalBases: [
            'Consentimiento explícito del titular (LGPD Art. 11, I / GDPR Art. 9)',
            'Tutela de la salud y prevención (LGPD Art. 7, VIII)',
            'Cumplimiento de obligación legal y regulatoria (LGPD Art. 7, II)',
          ],
          sensitiveDataArticle: 'LGPD Art. 11 (Datos Personales Sensibles de Salud)',
          dpoContact: entity.dpoEmail,
          rights,
        },
        sections: [
          {
            sectionId: '1-data-collected',
            title: '1. Datos que Recolectamos',
            content:
              'Recolectamos únicamente la información necesaria para el funcionamiento preventivo de la aplicación:',
            bullets: [
              'Datos de registro: Nombre, correo electrónico, fecha de nacimiento, sexo biológico.',
              'Datos sensibles de salud: Registros de síntomas físicos y psicoemocionales, consumo de agua, métricas de bienestar.',
              'Datos técnicos de seguridad: Dirección IP anonimizada, registros de auditoría de acceso, versión del dispositivo.',
            ],
          },
          {
            sectionId: '2-purposes',
            title: '2. Finalidad del Tratamiento',
            content:
              'Toda la información es tratada para proporcionar la estratificación de riesgo, alertas de hidratación y seguimiento longitudinal. Nunca vendemos datos de salud a terceros o aseguradoras.',
          },
          {
            sectionId: '3-third-parties',
            title: '3. Compartición con Terceros y Pasarelas de Pago',
            content:
              'Los pagos son procesados de forma segura mediante procesadores certificados (PCI-DSS) como Stripe. DualisCheckUp jamás almacena números de tarjeta de crédito en sus servidores.',
          },
          {
            sectionId: '4-retention-and-deletion',
            title: '4. Período de Retención y Derecho de Eliminación',
            content:
              'Sus datos se conservan mientras su cuenta permanezca activa. El usuario puede solicitar la eliminación total y permanente en cualquier momento desde la Central de Privacidad.',
          },
          {
            sectionId: '5-communications',
            title: '5. Comunicaciones y Desuscripción (Opt-Out)',
            content:
              'Solo enviamos notificaciones operativas obligatorias. Las comunicaciones informativas o de bienestar cuentan con un botón de desuscripción y un selector de preferencias en la app.',
          },
        ],
      };
    }

    if (lang === 'en') {
      return {
        version,
        effectiveDate,
        lastUpdated,
        language: 'en',
        legalEntity: entity,
        title: 'DualisCheckUp Privacy Policy & Data Protection',
        summary:
          'Governance policy for collecting, processing, securing, and deleting personal and sensitive health data.',
        lgpdCompliance: {
          legalBases: [
            'Explicit consent of the data subject (LGPD Art. 11 / GDPR Art. 9)',
            'Health protection and wellness tracking (LGPD Art. 7, VIII)',
            'Compliance with legal and regulatory obligations (LGPD Art. 7, II)',
          ],
          sensitiveDataArticle: 'LGPD Art. 11 (Sensitive Health Data)',
          dpoContact: entity.dpoEmail,
          rights,
        },
        sections: [
          {
            sectionId: '1-data-collected',
            title: '1. Information We Collect',
            content:
              'We collect only what is necessary to personalize your preventive health triage experience:',
            bullets: [
              'Account info: Name, email address, date of birth, biological sex.',
              'Sensitive health data: Symptom check-ins, emotional markers, water intake records.',
              'Security logs: Anonymized IP addresses, session telemetry, audit hashes.',
            ],
          },
          {
            sectionId: '2-purposes',
            title: '2. Purpose of Data Processing',
            content:
              'Data is used solely for symptom triage, hydration alerts, and longitudinal self-care tracking. We strictly forbid the commercial sale or sharing of health data with advertising networks or insurance brokers.',
          },
          {
            sectionId: '3-payment-security',
            title: '3. Payments & Zero Cardholder Storage',
            content:
              'All subscription payments are tokenized through PCI-DSS Level 1 compliant gateways (e.g. Stripe). DualisCheckUp servers never receive, store, or process raw credit card numbers.',
          },
          {
            sectionId: '4-rights-and-deletion',
            title: '4. Data Subject Rights & Deletion',
            content:
              'Users hold the complete right to export their clinical history as JSON or trigger permanent irreversible deletion directly within the Privacy Center.',
          },
          {
            sectionId: '5-communications-optout',
            title: '5. Communications & Instant Opt-Out',
            content:
              'Educational tips and notification preferences can be toggled on or off at any moment with a single tap in the application settings.',
          },
        ],
      };
    }

    // Default: Portuguese (pt-BR)
    return {
      version,
      effectiveDate,
      lastUpdated,
      language: 'pt-BR',
      legalEntity: entity,
      title: 'Política de Privacidade e Proteção de Dados (LGPD)',
      summary:
        'Diretrizes de coleta, tratamento, segurança criptográfica e exclusão de dados pessoais sensíveis de saúde da plataforma DualisCheckUp.',
      lgpdCompliance: {
        legalBases: [
          'Consentimento expresso e inequívoco do Titular (LGPD Art. 11, I)',
          'Tutela da saúde em procedimento realizado por serviços de saúde e bem-estar (LGPD Art. 7º, VIII e Art. 11, II, "f")',
          'Cumprimento de obrigação legal ou regulatória (LGPD Art. 7º, II)',
        ],
        sensitiveDataArticle: 'Artigo 11 da Lei Federal nº 13.709/2018 (Dados Sensíveis de Saúde)',
        dpoContact: entity.dpoEmail,
        rights,
      },
      sections: [
        {
          sectionId: '1-dados-coletados',
          title: '1. Quais Dados Coletamos',
          content:
            'Coletamos estritamente os dados necessários para a personalização clínica e segurança do Usuário:',
          bullets: [
            'Dados Cadastrais: Nome completo, endereço de e-mail autenticado, data de nascimento e sexo biológico.',
            'Dados Sensíveis de Saúde: Histórico de sintomas físicos (12 sistemas) e psicoemocionais (7 dimensões), registros de hidratação e desfechos de triagem.',
            'Dados de Acesso e Metadados: Endereço IP mascarado, registros cronológicos de login, hashes imutáveis antiburla.',
          ],
        },
        {
          sectionId: '2-finalidade-tratamento',
          title: '2. Finalidade e Não Comercialização',
          content:
            'Os dados sensíveis de saúde são utilizados com a finalidade exclusiva de processar a estratificação preventiva e alimentar o prontuário pessoal do Usuário. É expressamente PROIBIDA a venda, comercialização ou compartilhamento de dados médicos com seguradoras, anunciantes ou terceiros não autorizados.',
        },
        {
          sectionId: '3-pagamentos-e-pci',
          title: '3. Arquitetura de Pagamentos e Proteção PCI-DSS',
          content:
            'As transações financeiras para planos pagos são processadas diretamente por intermediadores de pagamento homologados PCI-DSS Nivel 1 (ex: Stripe / Asaas). Os servidores da DualisCheckUp NUNCA tocam, visualizam ou armazenam números de cartão de crédito ou códigos de segurança (CVV).',
        },
        {
          sectionId: '4-direitos-titular-lgpd',
          title: '4. Direitos do Titular e Exclusão Imediata (Art. 18 da LGPD)',
          content:
            'O Usuário possui controle autônomo sobre seus dados diretamente na Central de Privacidade do aplicativo:',
          bullets: [
            'Exportação Completa: Download de todos os registros clínicos em formato padronizado JSON.',
            'Exclusão Permanente: Opção de apagar a conta e todos os dados associados mediante confirmação com senha, resultando na eliminação criptográfica irreversível dos bancos de dados.',
          ],
        },
        {
          sectionId: '5-comunicacoes-e-opt-out',
          title: '5. Comunicações, Notificações e Mecanismo de Opt-Out',
          content:
            'As mensagens de rotina (lembretes de água e dicas preventivas) exigem consentimento prévio e podem ser ativadas ou desativadas a qualquer instante na tela de Configurações, garantindo liberdade total de descontinuidade de mensagens informativas.',
        },
      ],
    };
  }

  public getSecurityPolicy(
    requestedLang?: string,
    acceptLanguageHeader?: string,
  ): SecurityPolicyResponseDto {
    const lang = this.resolveLanguage(requestedLang, acceptLanguageHeader);
    const version = this.configService.get<string>('SECURITY_VERSION') || this.defaultVersion;

    return {
      version,
      lastUpdated: '2026-10-01',
      language: lang,
      encryptionInTransit: 'TLS 1.3 obrigatório com HSTS (HTTP Strict Transport Security)',
      encryptionAtRest: 'Criptografia AES-256 no banco de dados e armazenamento em nuvem',
      passwordHashing: 'Argon2id com salt criptográfico de alta entropia (resistente a GPU/ASIC)',
      tenantIsolation: 'PostgreSQL Row-Level Security (RLS) com parâmetro app.current_user_id',
      backupAndDisasterRecovery:
        'Snapshots diários automatizados com retenção geográfica segura e teste periódico de restauração',
      incidentResponsePlan: {
        commitment:
          'Protocolo de Resposta a Incidentes e Vazamento de Dados em conformidade com o Art. 48 da LGPD.',
        breachNotificationWindowHours: 72,
        regulatoryNotificationBody: 'Autoridade Nacional de Proteção de Dados (ANPD) e Usuários Afetados',
      },
      sections: [
        {
          sectionId: '1-infrastructure-security',
          title: '1. Segurança de Infraestrutura e Criptografia',
          content:
            'Todo o tráfego é transmitido por túneis criptografados TLS 1.3. O banco de dados PostgreSQL opera com Row-Level Security (RLS) ativo em todas as tabelas de saúde, impedindo qualquer vazamento cruzado entre usuários.',
        },
        {
          sectionId: '2-authentication-defense',
          title: '2. Mecanismos de Autenticação e Proteção contra Ataques',
          content:
            'Senhas são tratadas com o algoritmo Argon2id. Endpoints críticos contam com limitadores de taxa (Rate Limiting via Redis) para neutralizar tentativas de ataques de força bruta e injeção.',
        },
        {
          sectionId: '3-breach-response-plan',
          title: '3. Plano de Resposta a Incidentes de Segurança (LGPD Art. 48)',
          content:
            'Na remota hipótese de qualquer incidente de segurança relevante que envolva risco aos titulares de dados, a DualisCheckUp adota o seguinte protocolo operacional:',
          bullets: [
            'Isolamento e contenção imediata do vetor de ameaça em menos de 1 hora.',
            'Auditoria forense completa dos logs de acesso.',
            'Comunicação formal à ANPD e aos usuários afetados em prazo não superior a 72 horas.',
            'Emissão de relatório técnico de mitigação e reparação preventiva.',
          ],
        },
      ],
    };
  }

  public getMedicalDisclaimer(
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
        url: 'https://www.in.gov.br/web/dou/-/resolucao-de-diretoria-colegiada-rdc-n-657-de-24-de-marco-de-2022-389603457',
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
        url: 'https://www.in.gov.br/web/dou/-/resolucao-de-diretoria-colegiada-rdc-n-657-de-24-de-marco-de-2022-389603457',
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
        url: 'https://www.in.gov.br/en/web/dou/-/resolucao-de-diretoria-colegiada-rdc-n-657-de-24-de-marco-de-2022-389603457',
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
