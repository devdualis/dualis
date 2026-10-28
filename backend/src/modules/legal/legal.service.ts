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

/**
 * Current version of the legal documents (terms, privacy policy, disclaimer).
 * 2026.2 = wellness repositioning: the app is no longer described as a triage
 * tool. Bumping it forces every user to accept the new texts again.
 * Env overrides (TERMS_VERSION, PRIVACY_VERSION, DISCLAIMER_VERSION) still win.
 */
export const LEGAL_DOCUMENTS_VERSION = '2026.2';

const LEGAL_DOCUMENTS_EFFECTIVE_DATE = '2026-10-16';
const LEGAL_DOCUMENTS_LAST_UPDATED = '2026-10-16';

/** Canonical intended-use statement (plan §1.1). Must stay identical everywhere. */
export const INTENDED_USE_STATEMENT: Record<SupportedLanguage, string> = {
  'pt-BR':
    'O DualisCheckUp é um aplicativo de bem-estar e autoconhecimento. Ele ajuda você a registrar diariamente como se sente física e emocionalmente, acompanhar hábitos como hidratação e sono, visualizar seus próprios registros ao longo do tempo e acessar conteúdos educativos gerais sobre hábitos saudáveis. O DualisCheckUp não é um dispositivo médico: não avalia, não classifica nem interpreta sintomas, não indica nível de urgência, não faz diagnóstico, não recomenda tratamento e não substitui um profissional de saúde. Em caso de emergência, ligue 192 (SAMU). Se você estiver em sofrimento emocional, ligue 188 (CVV).',
  en: 'DualisCheckUp is a wellness and self-awareness app. It helps you keep a daily journal of how you feel physically and emotionally, track habits such as hydration and sleep, view your own entries over time, and access general educational content about healthy habits. DualisCheckUp is not a medical device: it does not assess, classify or interpret symptoms, does not indicate urgency levels, does not diagnose, does not recommend treatment and does not replace a healthcare professional. In an emergency, call your local emergency number. If you are in emotional distress, contact your local crisis line.',
  es: 'DualisCheckUp es una aplicación de bienestar y autoconocimiento. Te ayuda a registrar a diario cómo te sientes física y emocionalmente, seguir hábitos como la hidratación y el sueño, ver tus propios registros a lo largo del tiempo y acceder a contenidos educativos generales sobre hábitos saludables. DualisCheckUp no es un dispositivo médico: no evalúa, no clasifica ni interpreta síntomas, no indica niveles de urgencia, no realiza diagnósticos, no recomienda tratamientos y no sustituye a un profesional de la salud. En caso de emergencia, llama al número de emergencias local. Si estás pasando por un momento de angustia emocional, contacta con la línea de crisis de tu país.',
};

@Injectable()
export class LegalService {
  private readonly defaultVersion = LEGAL_DOCUMENTS_VERSION;

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
    const effectiveDate = LEGAL_DOCUMENTS_EFFECTIVE_DATE;
    const lastUpdated = LEGAL_DOCUMENTS_LAST_UPDATED;

    if (lang === 'es') {
      return {
        version,
        effectiveDate,
        lastUpdated,
        language: 'es',
        legalEntity: entity,
        title: 'Términos y Condiciones de Uso del SaaS DualisCheckUp',
        summary:
          'Contrato de prestación de servicios de software para el registro personal de bienestar y autoconocimiento.',
        sections: [
          {
            sectionId: '1-acceptance',
            title: '1. Aceptación de los Términos y Capacidad Legal',
            content:
              'Al crear una cuenta o utilizar la plataforma DualisCheckUp, usted acepta vincularse legalmente a estos Términos de Uso. Debe tener al menos 18 años o la mayoría de edad legal en su jurisdicción para suscribirse.',
          },
          {
            sectionId: '2-nature-of-service',
            title: '2. Naturaleza del Servicio',
            content: INTENDED_USE_STATEMENT.es,
            bullets: [
              'No evalúa síntomas, no indica urgencia, no diagnostica y no recomienda tratamientos.',
              'Las intensidades y la información que se muestran son las que usted mismo registró.',
              'En una emergencia en Brasil, llame al 192 (SAMU) o al 188 (CVV); en otros países, al número de emergencias local.',
            ],
          },
          {
            sectionId: '3-subscriptions-billing-refunds',
            title: '3. Suscripciones, Facturación, Cancelaciones y Reembolsos',
            content:
              'El acceso a funcionalidades adicionales puede ofrecerse mediante suscripciones periódicas, procesadas por intermediarios de pago externos.',
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
              'El software, los contenidos, las marcas y las interfaces de la plataforma son propiedad exclusiva de DualisCheckUp Saúde e Tecnologia Ltda. Queda prohibida la ingeniería inversa, extracción de datos o uso no autorizado.',
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
          'Software-as-a-Service customer contract for a personal wellness and self-awareness journal.',
        sections: [
          {
            sectionId: '1-acceptance',
            title: '1. Acceptance of Terms & Legal Capacity',
            content:
              'By creating an account or accessing DualisCheckUp, you agree to be bound by these Terms. You must be at least 18 years of age or the legal age of majority in your jurisdiction to register.',
          },
          {
            sectionId: '2-nature-of-service',
            title: '2. Nature of the Service',
            content: INTENDED_USE_STATEMENT.en,
            bullets: [
              'It does not assess symptoms, indicate urgency, diagnose or recommend treatment.',
              'Intensities and other information shown are the ones you entered yourself.',
              'In an emergency in Brazil, call 192 (SAMU) or 188 (CVV); elsewhere, call your local emergency number.',
            ],
          },
          {
            sectionId: '3-subscriptions-billing-refunds',
            title: '3. Subscriptions, Billing, Cancellations & Refunds',
            content:
              'Additional features may be offered through recurring subscriptions processed by third-party payment providers. Users can cancel at any time with no lock-in fees. A 7-day unconditional refund window applies to all initial subscription charges.',
          },
          {
            sectionId: '4-intellectual-property',
            title: '4. Intellectual Property Rights',
            content:
              'The software, content, trademarks and interfaces of the platform are owned exclusively by DualisCheckUp. Reverse engineering, data scraping, or unauthorized exploitation is strictly prohibited.',
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
        'Contrato de prestação de serviços de software em nuvem para registro pessoal de bem-estar e autoconhecimento.',
      sections: [
        {
          sectionId: '1-aceitacao',
          title: '1. Aceitação dos Termos e Capacidade Civil',
          content:
            'Ao criar uma conta ou utilizar o aplicativo DualisCheckUp, o Usuário declara ter capacidade civil plena (maior de 18 anos) e concorda expressamente com as disposições deste Contrato de Prestação de Serviços de Software.',
        },
        {
          sectionId: '2-natureza-do-servico',
          title: '2. Natureza do Serviço',
          content: INTENDED_USE_STATEMENT['pt-BR'],
          bullets: [
            'Não avalia sintomas, não indica urgência, não diagnostica e não recomenda tratamento.',
            'As intensidades e demais informações exibidas são as que você mesmo registrou.',
            'Em emergência, ligue 192 (SAMU) ou 188 (CVV).',
          ],
        },
        {
          sectionId: '3-pagamentos-cancelamento-reembolso',
          title: '3. Planos, Cobrança, Cancelamento e Política de Reembolso',
          content:
            'O acesso a recursos adicionais pode ser disponibilizado mediante planos de assinatura, processados por intermediadores de pagamento terceiros.',
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
            'A DualisCheckUp Saúde e Tecnologia Ltda. é titular exclusiva dos direitos sobre software, conteúdos, marcas e interfaces da plataforma. É vedada a engenharia reversa, cópia ou comercialização não autorizada.',
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
    const effectiveDate = LEGAL_DOCUMENTS_EFFECTIVE_DATE;
    const lastUpdated = LEGAL_DOCUMENTS_LAST_UPDATED;

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
            'Consentimiento específico y destacado del titular para datos sensibles de salud (LGPD Art. 11, I / GDPR Art. 9(2)(a))',
            'Ejecución del contrato de prestación del servicio, para los datos de registro (LGPD Art. 7, V)',
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
              'Recolectamos únicamente la información necesaria para el funcionamiento de la aplicación:',
            bullets: [
              'Datos de registro: Nombre, correo electrónico, fecha de nacimiento, sexo biológico.',
              'Datos sensibles de salud: Anotaciones diarias sobre cómo se siente física y emocionalmente, la intensidad que usted informa, consumo de agua y otros hábitos.',
              'Datos técnicos de seguridad: Dirección IP anonimizada, registros de auditoría de acceso, versión del dispositivo.',
            ],
          },
          {
            sectionId: '2-purposes',
            title: '2. Finalidad del Tratamiento',
            content:
              'Los datos sensibles de salud se tratan exclusivamente para las siguientes finalidades. Nunca vendemos datos de salud a terceros, anunciantes o aseguradoras.',
            bullets: [
              'Registro y visualización de su diario de bienestar.',
              'Sugerir, con ayuda de IA, una opción ya existente del diario cuando usted escribe con sus palabras (sin evaluación de salud).',
              'Consistencia del historial.',
            ],
          },
          {
            sectionId: '3-processors-international-transfer',
            title: '3. Encargados del Tratamiento y Transferencia Internacional',
            content:
              'Para prestar el servicio compartimos datos únicamente con los siguientes encargados del tratamiento:',
            bullets: [
              'Google LLC (API Gemini): el texto de "escribir el mío" puede enviarse a Gemini solo para sugerir una opción ya existente del diario. La IA no evalúa su salud.',
              'Transferencia internacional: ese procesamiento puede realizarse fuera de Brasil (LGPD Art. 33).',
              'Proveedores de infraestructura en la nube (alojamiento y base de datos), sujetos a obligaciones de confidencialidad y seguridad.',
            ],
          },
          {
            sectionId: '4-payments',
            title: '4. Pagos',
            content:
              'Cuando existan planes de pago, los pagos serán procesados por intermediarios de pago externos. DualisCheckUp jamás almacena números de tarjeta de crédito en sus servidores.',
          },
          {
            sectionId: '5-retention-and-deletion',
            title: '5. Período de Retención y Derecho de Eliminación',
            content:
              'Sus datos se conservan mientras su cuenta permanezca activa. El usuario puede solicitar la eliminación total y permanente en cualquier momento desde la Central de Privacidad.',
          },
          {
            sectionId: '6-communications',
            title: '6. Comunicaciones y Desuscripción (Opt-Out)',
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
            'Specific and prominent consent of the data subject for sensitive health data (LGPD Art. 11, I / GDPR Art. 9(2)(a))',
            'Performance of the service contract, for account data (LGPD Art. 7, V)',
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
            content: 'We collect only what is necessary to run your wellness journal:',
            bullets: [
              'Account info: Name, email address, date of birth, biological sex.',
              'Sensitive health data: Daily notes on how you feel physically and emotionally, the intensity you report, water intake and other habits.',
              'Security logs: Anonymized IP addresses, session telemetry, audit hashes.',
            ],
          },
          {
            sectionId: '2-purposes',
            title: '2. Purpose of Data Processing',
            content:
              'Sensitive health data is processed solely for the purposes below. We strictly forbid the sale or sharing of health data with advertising networks or insurance brokers.',
            bullets: [
              'Recording and viewing your wellness journal.',
              'Suggesting, with AI help, an existing diary option when you write in your own words (no health assessment).',
              'Keeping your history consistent.',
            ],
          },
          {
            sectionId: '3-processors-international-transfer',
            title: '3. Processors & International Transfer',
            content: 'We share data only with the following processors, to run the service:',
            bullets: [
              'Google LLC (Gemini API): text from "write my own" may be sent to Gemini only to suggest an existing diary option. The AI does not assess your health.',
              'International transfer: that processing may take place outside Brazil (LGPD Art. 33).',
              'Cloud infrastructure providers (hosting and database), bound by confidentiality and security obligations.',
            ],
          },
          {
            sectionId: '4-payments',
            title: '4. Payments & Zero Cardholder Storage',
            content:
              'When paid plans are available, payments are handled by third-party payment providers. DualisCheckUp servers never receive, store, or process raw credit card numbers.',
          },
          {
            sectionId: '5-rights-and-deletion',
            title: '5. Data Subject Rights & Deletion',
            content:
              'Users hold the complete right to export their journal entries as JSON or trigger permanent irreversible deletion directly within the Privacy Center.',
          },
          {
            sectionId: '6-communications-optout',
            title: '6. Communications & Instant Opt-Out',
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
          'Consentimento específico e destacado do Titular para dados pessoais sensíveis de saúde (LGPD Art. 11, I)',
          'Execução do contrato de prestação do serviço, para os dados cadastrais (LGPD Art. 7º, V)',
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
            'Coletamos estritamente os dados necessários para o funcionamento do seu diário de bem-estar e para a segurança do Usuário:',
          bullets: [
            'Dados Cadastrais: Nome completo, endereço de e-mail autenticado, data de nascimento e sexo biológico.',
            'Dados Sensíveis de Saúde: Anotações diárias sobre como você se sente física e emocionalmente, intensidade informada por você, registros de hidratação e de outros hábitos.',
            'Dados de Acesso e Metadados: Endereço IP mascarado, registros cronológicos de login, hashes de integridade do histórico.',
          ],
        },
        {
          sectionId: '2-finalidade-tratamento',
          title: '2. Finalidade e Não Comercialização',
          content:
            'Os dados sensíveis de saúde são tratados exclusivamente para as finalidades abaixo. É expressamente PROIBIDA a venda, comercialização ou compartilhamento de dados de saúde com seguradoras, anunciantes ou terceiros não autorizados.',
          bullets: [
            'Registro e visualização do seu diário de bem-estar.',
            'Sugerir, com ajuda de IA, uma opção já existente do diário quando você escreve com as suas palavras (sem avaliação de saúde).',
            'Consistência do histórico.',
          ],
        },
        {
          sectionId: '3-operadores-transferencia-internacional',
          title: '3. Operadores e Transferência Internacional',
          content:
            'Compartilhamos dados apenas com os operadores abaixo, para a prestação do serviço:',
          bullets: [
            'Google LLC (API Gemini): o texto de "escrever o meu" pode ser enviado à Gemini só para sugerir uma opção já existente do diário. A IA não avalia a sua saúde.',
            'Transferência internacional: esse processamento pode ocorrer fora do Brasil (LGPD Art. 33).',
            'Provedores de infraestrutura em nuvem (hospedagem e banco de dados), sujeitos a obrigações de confidencialidade e segurança.',
          ],
        },
        {
          sectionId: '4-pagamentos',
          title: '4. Pagamentos',
          content:
            'Quando houver planos pagos, as transações serão processadas por intermediadores de pagamento terceiros. Os servidores da DualisCheckUp NUNCA tocam, visualizam ou armazenam números de cartão de crédito ou códigos de segurança (CVV).',
        },
        {
          sectionId: '5-direitos-titular-lgpd',
          title: '5. Direitos do Titular e Exclusão Imediata (Art. 18 da LGPD)',
          content:
            'O Usuário possui controle direto sobre seus dados diretamente na Central de Privacidade do aplicativo:',
          bullets: [
            'Exportação Completa: Download de todos os seus registros em formato padronizado JSON.',
            'Exclusão Permanente: Opção de apagar a conta e todos os dados associados mediante confirmação com senha, resultando na eliminação criptográfica irreversível dos bancos de dados.',
          ],
        },
        {
          sectionId: '6-comunicacoes-e-opt-out',
          title: '6. Comunicações, Notificações e Mecanismo de Opt-Out',
          content:
            'As mensagens de rotina (lembretes de água e dicas de bem-estar) exigem consentimento prévio e podem ser ativadas ou desativadas a qualquer instante na tela de Configurações, garantindo liberdade total de descontinuidade de mensagens informativas.',
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
        regulatoryBody: 'Autoridade Nacional de Proteção de Dados (ANPD)',
        normativeAct: 'Lei nº 13.709/2018 (LGPD)',
        summary:
          'Rege o tratamento dos seus dados pessoais, inclusive os dados sensíveis de saúde registrados no diário (Art. 7, 11, 14 e 18).',
        url: 'https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm',
      },
      {
        regulatoryBody: 'Secretaria Nacional do Consumidor (Senacon)',
        normativeAct: 'Lei nº 8.078/1990 (Código de Defesa do Consumidor)',
        summary:
          'Garante os direitos do consumidor na contratação do serviço, incluindo o direito de arrependimento em 7 dias (Art. 49).',
        url: 'https://www.planalto.gov.br/ccivil_03/leis/l8078compilado.htm',
      },
    ];

    const emergencyContacts: EmergencyContactDto[] = [
      {
        name: 'SAMU',
        phone: '192',
        description: 'Serviço de Atendimento Móvel de Urgência.',
      },
      {
        name: 'Bombeiros',
        phone: '193',
        description: 'Corpo de Bombeiros para resgates e acidentes.',
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
      disclaimerText: INTENDED_USE_STATEMENT['pt-BR'],
      shortDisclaimer:
        'O DualisCheckUp é um app de bem-estar, não é um dispositivo médico e não substitui um profissional de saúde.',
      citations,
      emergencyContacts,
    };
  }

  private getSpanishDisclaimer(version: string): MedicalDisclaimerResponseDto {
    const citations: RegulatoryCitationDto[] = [
      {
        regulatoryBody: 'Autoridad Nacional de Protección de Datos (ANPD)',
        normativeAct: 'Ley nº 13.709/2018 (LGPD)',
        summary:
          'Regula el tratamiento de sus datos personales, incluidos los datos sensibles de salud registrados en el diario (Art. 7, 11, 14 y 18).',
        url: 'https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm',
      },
      {
        regulatoryBody: 'Secretaría Nacional del Consumidor (Senacon)',
        normativeAct: 'Ley nº 8.078/1990 (Código de Defensa del Consumidor)',
        summary:
          'Garantiza los derechos del consumidor al contratar el servicio, incluido el derecho de retracto en 7 días (Art. 49).',
        url: 'https://www.planalto.gov.br/ccivil_03/leis/l8078compilado.htm',
      },
    ];

    const emergencyContacts: EmergencyContactDto[] = [
      {
        name: 'SAMU / Emergencias',
        phone: '192',
        description: 'Servicio de atención móvil de urgencias en Brasil (en otros países, llame al número de emergencias local).',
      },
      {
        name: 'Bomberos / Rescate',
        phone: '193',
        description: 'Cuerpo de bomberos y unidades de rescate.',
      },
      {
        name: 'CVV / Asistencia en Crisis',
        phone: '188',
        description: 'Línea de apoyo emocional y prevención del suicidio, confidencial y gratuita.',
      },
    ];

    return {
      version,
      language: 'es',
      disclaimerText: INTENDED_USE_STATEMENT.es,
      shortDisclaimer:
        'DualisCheckUp es una app de bienestar, no es un dispositivo médico y no reemplaza a un profesional de la salud.',
      citations,
      emergencyContacts,
    };
  }

  private getEnglishDisclaimer(version: string): MedicalDisclaimerResponseDto {
    const citations: RegulatoryCitationDto[] = [
      {
        regulatoryBody: 'Brazilian National Data Protection Authority (ANPD)',
        normativeAct: 'Law 13,709/2018 (LGPD)',
        summary:
          'Governs the processing of your personal data, including the sensitive health data you record in your journal (Arts. 7, 11, 14 and 18).',
        url: 'https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm',
      },
      {
        regulatoryBody: 'National Consumer Secretariat (Senacon)',
        normativeAct: 'Law 8,078/1990 (Consumer Protection Code)',
        summary:
          'Protects your consumer rights when subscribing, including the 7-day right of withdrawal (Art. 49).',
        url: 'https://www.planalto.gov.br/ccivil_03/leis/l8078compilado.htm',
      },
    ];

    const emergencyContacts: EmergencyContactDto[] = [
      {
        name: 'SAMU / Emergency Medical Services',
        phone: '192',
        description: 'Mobile emergency service in Brazil (elsewhere, call your local emergency number).',
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
      disclaimerText: INTENDED_USE_STATEMENT.en,
      shortDisclaimer:
        'DualisCheckUp is a wellness app, is not a medical device and does not replace a healthcare professional.',
      citations,
      emergencyContacts,
    };
  }
}
