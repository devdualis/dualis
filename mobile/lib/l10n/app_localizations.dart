import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// Application title
  ///
  /// In pt, this message translates to:
  /// **'DualisCheckUp'**
  String get appTitle;

  /// Primary action button on Screen 1
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get screen1PrimaryCta;

  /// Secondary action button on Screen 1
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get screen1SecondaryCta;

  /// Primary action button on Screen 2
  ///
  /// In pt, this message translates to:
  /// **'Finalizar Cadastro'**
  String get screen2PrimaryCta;

  /// Title of the first onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Triagem Preventiva Unificada'**
  String get valueCard1Title;

  /// Body copy of the first onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Conecte sua saúde física e estado psico-emocional em um único fluxo diário inteligente, garantindo cuidado holístico e sem ruídos.'**
  String get valueCard1Body;

  /// Title of the second onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Registros Médicos Blindados'**
  String get valueCard2Title;

  /// Body copy of the second onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Seu histórico clínico protegido por criptografia AES-256 e custodiado sob os mais rigorosos padrões da LGPD. Você é o único dono dos seus dados.'**
  String get valueCard2Body;

  /// Title of the third onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Orientações Preventivas Precisas'**
  String get valueCard3Title;

  /// Body copy of the third onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Recomendações e artigos de especialistas médicos renomados sem diagnósticos falsos ou alarmismos desnecessários.'**
  String get valueCard3Body;

  /// LGPD Article 11 mandatory consent checkbox text
  ///
  /// In pt, this message translates to:
  /// **'Li e concordo com a Política de Privacidade e consinto expressamente com o tratamento de meus dados pessoais sensíveis de saúde para fins de triagem preventiva e acompanhamento longitudinal, nos termos do Art. 11 da LGPD.'**
  String get lgpdConsentCheckbox;

  /// Title displayed when privacy veil obscures health data
  ///
  /// In pt, this message translates to:
  /// **'Dados de Saúde Protegidos'**
  String get privacyVeilTitle;

  /// Body copy displayed on the privacy veil
  ///
  /// In pt, this message translates to:
  /// **'Autentique-se com biometria ou senha para acessar seu prontuário.'**
  String get privacyVeilBody;

  /// Validation error for full name input
  ///
  /// In pt, this message translates to:
  /// **'Por favor, informe seu nome completo (nome e sobrenome).'**
  String get formErrorName;

  /// Validation error for email input
  ///
  /// In pt, this message translates to:
  /// **'Informe um endereço de e-mail válido.'**
  String get formErrorEmail;

  /// Validation error for password input
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 8 caracteres, incluindo letra maiúscula, minúscula, número e símbolo especial.'**
  String get formErrorPassword;

  /// Label for full name input field
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get fullName;

  /// Label for date of birth input field
  ///
  /// In pt, this message translates to:
  /// **'Data de Nascimento'**
  String get birthDate;

  /// Label for biological sex segmented control
  ///
  /// In pt, this message translates to:
  /// **'Sexo Biológico'**
  String get biologicalSex;

  /// Label for email input field
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get email;

  /// Label for password input field
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// Biological sex male option
  ///
  /// In pt, this message translates to:
  /// **'Masculino'**
  String get sexMale;

  /// Biological sex female option
  ///
  /// In pt, this message translates to:
  /// **'Feminino'**
  String get sexFemale;

  /// Biological sex other option
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get sexOther;

  /// Language label
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// Portuguese language name
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get portuguese;

  /// Spanish language name
  ///
  /// In pt, this message translates to:
  /// **'Espanhol'**
  String get spanish;

  /// English language name
  ///
  /// In pt, this message translates to:
  /// **'Inglês'**
  String get english;

  /// Title of the emergency risk alert screen
  ///
  /// In pt, this message translates to:
  /// **'Alerta de Risco Imediato'**
  String get emergencyTitle;

  /// Subtitle describing immediate risk and advising urgent care
  ///
  /// In pt, this message translates to:
  /// **'Sintomas de gravidade identificados. Procure atendimento médico urgente.'**
  String get emergencySubtitle;

  /// Emergency badge for critical chest pain
  ///
  /// In pt, this message translates to:
  /// **'Dor Torácica Crítica'**
  String get emergencyBadgeChestPain;

  /// Emergency badge for acute respiratory distress
  ///
  /// In pt, this message translates to:
  /// **'Dificuldade Respiratória Aguda'**
  String get emergencyBadgeRespiratory;

  /// Emergency badge for suspected stroke
  ///
  /// In pt, this message translates to:
  /// **'Suspeita de Déficit Neurológico (AVC)'**
  String get emergencyBadgeStroke;

  /// Emergency badge for sudden explosive thunderclap headache
  ///
  /// In pt, this message translates to:
  /// **'Cefaleia Súbita e Explosiva'**
  String get emergencyBadgeHeadache;

  /// Emergency badge for acute emotional crisis / life safety
  ///
  /// In pt, this message translates to:
  /// **'Apoio Emocional Imediato / Risco à Vida'**
  String get emergencyBadgeEmotional;

  /// Emergency badge for general critical intensity symptoms
  ///
  /// In pt, this message translates to:
  /// **'Sintoma Crítico (Nível 4–5)'**
  String get emergencyBadgeGeneral;

  /// First physical emergency action step
  ///
  /// In pt, this message translates to:
  /// **'Interrompa qualquer esforço físico e permaneça em repouso.'**
  String get emergencyInstructionPhysical1;

  /// Second physical emergency action step
  ///
  /// In pt, this message translates to:
  /// **'Não dirija até o hospital. Acione o 192 ou peça ajuda a terceiros.'**
  String get emergencyInstructionPhysical2;

  /// Third physical emergency action step
  ///
  /// In pt, this message translates to:
  /// **'Afrouxe roupas apertadas e tente manter a calma enquanto o socorro chega.'**
  String get emergencyInstructionPhysical3;

  /// First emotional emergency action step
  ///
  /// In pt, this message translates to:
  /// **'Você não está sozinho(a). Ajuda qualificada e sigilosa está disponível agora.'**
  String get emergencyInstructionEmotional1;

  /// Second emotional emergency action step
  ///
  /// In pt, this message translates to:
  /// **'O CVV oferece apoio emocional gratuito 24 horas por dia pelo telefone 188.'**
  String get emergencyInstructionEmotional2;

  /// Third emotional emergency action step
  ///
  /// In pt, this message translates to:
  /// **'Se sentir que está em perigo imediato, acione o 192 ou procure a emergência.'**
  String get emergencyInstructionEmotional3;

  /// Button label to dial SAMU emergency services (192)
  ///
  /// In pt, this message translates to:
  /// **'Ligar SAMU (192)'**
  String get emergencyCallSamu;

  /// Button label to dial Bombeiros fire/rescue (193)
  ///
  /// In pt, this message translates to:
  /// **'Ligar Bombeiros (193)'**
  String get emergencyCallBombeiros;

  /// Button label to dial CVV crisis emotional hotline (188)
  ///
  /// In pt, this message translates to:
  /// **'Ligar CVV - Apoio Emocional (188)'**
  String get emergencyCallCvv;

  /// Button label to dial Police emergency line (190)
  ///
  /// In pt, this message translates to:
  /// **'Ligar Polícia (190)'**
  String get emergencyCallPolicia;

  /// Button label to open maps looking for nearest emergency room
  ///
  /// In pt, this message translates to:
  /// **'Buscar Pronto-Socorro Mais Próximo'**
  String get emergencyFindHospital;

  /// Hint text advising patient to provide address clearly to emergency dispatchers
  ///
  /// In pt, this message translates to:
  /// **'Ao ligar, informe seu endereço com clareza e mantenha a calma.'**
  String get emergencyDispatcherHint;

  /// Text button to initiate exiting the emergency screen
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao Início (Não recomendado)'**
  String get emergencyExitButton;

  /// Title of the exit confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Atenção Médica Urgente'**
  String get emergencyExitConfirmTitle;

  /// Body message of the exit confirmation dialog warning of life-safety risks
  ///
  /// In pt, this message translates to:
  /// **'Seus sintomas indicam uma situação de risco à vida. Recomendamos fortemente que você contate um serviço médico antes de sair. Deseja realmente voltar ao início?'**
  String get emergencyExitConfirmBody;

  /// Primary action button to stay on the emergency screen
  ///
  /// In pt, this message translates to:
  /// **'Permanecer na Emergência'**
  String get emergencyExitConfirmStay;

  /// Destructive secondary action button confirming exit despite life-safety warnings
  ///
  /// In pt, this message translates to:
  /// **'Entendi os Riscos / Sair'**
  String get emergencyExitConfirmLeave;

  /// Title of the telephony fallback dialog for tablets/devices without phone dialers
  ///
  /// In pt, this message translates to:
  /// **'Dispositivo sem Discador'**
  String get emergencyFallbackTitle;

  /// Body text of telephony fallback dialog with instructions
  ///
  /// In pt, this message translates to:
  /// **'Este aparelho não suporta chamadas diretas. Disque manualmente para o número abaixo em outro telefone:'**
  String get emergencyFallbackBody;

  /// Button label to copy emergency number to clipboard
  ///
  /// In pt, this message translates to:
  /// **'Copiar Número'**
  String get emergencyCopyNumber;

  /// Toast or snackbar message indicating emergency number was copied
  ///
  /// In pt, this message translates to:
  /// **'Número copiado para a área de transferência.'**
  String get emergencyCopiedToast;

  /// Banner text for emotional triage vertical
  ///
  /// In pt, this message translates to:
  /// **'Iniciando Autoavaliação Psico-Emocional'**
  String get triageBannerEmotional;

  /// Banner text for physical triage vertical
  ///
  /// In pt, this message translates to:
  /// **'Iniciando Autoavaliação Física'**
  String get triageBannerPhysical;

  /// Step progress indicator
  ///
  /// In pt, this message translates to:
  /// **'Passo {step} de {total}'**
  String triageStep(int step, int total);

  /// Button to advance to next triage step
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get triageNext;

  /// Button to go back to previous triage step
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get triageBack;

  /// Confirm button label
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get triageConfirm;

  /// Title of the preview step card
  ///
  /// In pt, this message translates to:
  /// **'Revisão da sua Avaliação'**
  String get triagePreviewTitle;

  /// Final submission CTA button
  ///
  /// In pt, this message translates to:
  /// **'Confirmar e Finalizar'**
  String get triagePreviewSubmit;

  /// Question 1 emotional
  ///
  /// In pt, this message translates to:
  /// **'Olhando para o seu lado emocional e mental, qual palavra descreve melhor o que você está sentindo agora?'**
  String get triageQ1Emotional;

  /// Emotional option: Anxiety/Agitation
  ///
  /// In pt, this message translates to:
  /// **'Ansiedade / Agitação'**
  String get triageOptAnsiedade;

  /// Emotional option: Sadness/Discouragement
  ///
  /// In pt, this message translates to:
  /// **'Tristeza / Desânimo'**
  String get triageOptTristeza;

  /// Emotional option: Stress/Irritability
  ///
  /// In pt, this message translates to:
  /// **'Estresse / Irritabilidade'**
  String get triageOptEstresse;

  /// Emotional option: Mental Fatigue
  ///
  /// In pt, this message translates to:
  /// **'Cansaço Mental'**
  String get triageOptCansaco;

  /// Question 2 emotional
  ///
  /// In pt, this message translates to:
  /// **'Você tem se sentido assim frequentemente nos últimos dias ou é algo muito específico de hoje?'**
  String get triageQ2Emotional;

  /// Persistence option: Started today
  ///
  /// In pt, this message translates to:
  /// **'Começou hoje'**
  String get triageOptComecouHoje;

  /// Persistence option: A few days ago
  ///
  /// In pt, this message translates to:
  /// **'Já faz alguns dias'**
  String get triageOptJaFazDias;

  /// Persistence option: Constant for weeks
  ///
  /// In pt, this message translates to:
  /// **'É algo constante há semanas'**
  String get triageOptConstanteSemanas;

  /// Question 3 emotional
  ///
  /// In pt, this message translates to:
  /// **'Essa sensação está parecendo um leve incômodo de fundo ou algo forte que está acelerando seus pensamentos?'**
  String get triageQ3Emotional;

  /// Emotional intensity: Mild and controllable
  ///
  /// In pt, this message translates to:
  /// **'Leve e controlável'**
  String get triageOptLeveControlavel;

  /// Emotional intensity: Moderate
  ///
  /// In pt, this message translates to:
  /// **'Moderada'**
  String get triageOptModerada;

  /// Emotional intensity: Very strong and hard to control
  ///
  /// In pt, this message translates to:
  /// **'Muito forte e difícil de segurar'**
  String get triageOptMuitoForte;

  /// Question 4 emotional
  ///
  /// In pt, this message translates to:
  /// **'Você consegue identificar se existe um motivo principal para isso estar acontecendo hoje?'**
  String get triageQ4Emotional;

  /// Trigger option: Work/Studies
  ///
  /// In pt, this message translates to:
  /// **'Trabalho / Estudos'**
  String get triageOptTrabalho;

  /// Trigger option: Family/Relationships
  ///
  /// In pt, this message translates to:
  /// **'Família / Relacionamentos'**
  String get triageOptFamilia;

  /// Trigger option: Poor sleep
  ///
  /// In pt, this message translates to:
  /// **'Noite ruim de sono'**
  String get triageOptNoiteRuim;

  /// Trigger option: Cannot tell
  ///
  /// In pt, this message translates to:
  /// **'Não sei dizer'**
  String get triageOptNaoSei;

  /// Emotional preview step description
  ///
  /// In pt, this message translates to:
  /// **'Revisão da sua Autoavaliação Psico-Emocional'**
  String get triagePreviewEmotional;

  /// Question 1 physical
  ///
  /// In pt, this message translates to:
  /// **'Vamos falar sobre a parte física. Onde você está sentindo esse desconforto ou dor principal?'**
  String get triageQ1Physical;

  /// Physical location: Head
  ///
  /// In pt, this message translates to:
  /// **'Cabeça'**
  String get triageOptCabeca;

  /// Physical location: Back/Spine
  ///
  /// In pt, this message translates to:
  /// **'Costas / Coluna'**
  String get triageOptCostas;

  /// Physical location: Joints
  ///
  /// In pt, this message translates to:
  /// **'Articulações (Joelho, Ombro, etc.)'**
  String get triageOptArticulacoes;

  /// Physical location: Abdomen/Stomach
  ///
  /// In pt, this message translates to:
  /// **'Abdômen / Estômago'**
  String get triageOptAbdomen;

  /// Question 2 physical
  ///
  /// In pt, this message translates to:
  /// **'Há quanto tempo essa dor ou anomalia persiste?'**
  String get triageQ2Physical;

  /// Physical persistence: Started now
  ///
  /// In pt, this message translates to:
  /// **'Começou agora'**
  String get triageOptComecouAgora;

  /// Physical persistence: A few days ago
  ///
  /// In pt, this message translates to:
  /// **'Há alguns dias'**
  String get triageOptHaAlgunsDias;

  /// Physical persistence: Chronic
  ///
  /// In pt, this message translates to:
  /// **'É crônica'**
  String get triageOptCronica;

  /// Question 3 physical
  ///
  /// In pt, this message translates to:
  /// **'Em uma escala de 1 a 5 (onde 1 é quase imperceptível e 5 é insuportável), como está agora?'**
  String get triageQ3Physical;

  /// Question 4 physical
  ///
  /// In pt, this message translates to:
  /// **'Você lembra de ter feito algum esforço atípico, exercício pesado ou sofrido alguma batida/queda recentemente?'**
  String get triageQ4Physical;

  /// Physical trigger: Intense exercise
  ///
  /// In pt, this message translates to:
  /// **'Sim, exercício intenso'**
  String get triageOptSimExercicio;

  /// Physical trigger: Fall/impact
  ///
  /// In pt, this message translates to:
  /// **'Sim, sofri uma queda'**
  String get triageOptSimQueda;

  /// Physical trigger: Started out of nowhere
  ///
  /// In pt, this message translates to:
  /// **'Não, começou do nada'**
  String get triageOptNaoComecouNada;

  /// Physical preview step description
  ///
  /// In pt, this message translates to:
  /// **'Revisão da sua Avaliação Física'**
  String get triagePreviewPhysical;

  /// Intensity label
  ///
  /// In pt, this message translates to:
  /// **'Intensidade: {value}'**
  String triageIntensityLabel(int value);

  /// Intensity scale minimum label
  ///
  /// In pt, this message translates to:
  /// **'Quase imperceptível'**
  String get triageIntensityMin;

  /// Intensity scale maximum label
  ///
  /// In pt, this message translates to:
  /// **'Insuportável'**
  String get triageIntensityMax;

  /// Title of Screen 6 Triage Outcome
  ///
  /// In pt, this message translates to:
  /// **'Resultado da Triagem'**
  String get outcomeScreenTitle;

  /// Subtitle of Screen 6 Triage Outcome
  ///
  /// In pt, this message translates to:
  /// **'Avaliação preventiva baseada nas suas respostas'**
  String get outcomeScreenSubtitle;

  /// Intensity title
  ///
  /// In pt, this message translates to:
  /// **'Intensidade Calculada'**
  String get outcomeIntensityTitle;

  /// Intensity score description
  ///
  /// In pt, this message translates to:
  /// **'Pontuação calculada na escala clínica de 1 a 5'**
  String get outcomeIntensityDescription;

  /// Disposition title
  ///
  /// In pt, this message translates to:
  /// **'Recomendação de Cuidado'**
  String get outcomeDispositionTitle;

  /// Self-care disposition
  ///
  /// In pt, this message translates to:
  /// **'Auto-cuidado Monitorado'**
  String get outcomeDispositionSelfCare;

  /// Self-care description
  ///
  /// In pt, this message translates to:
  /// **'Repouso, hidratação adequada e acompanhamento dos sintomas nas próximas 24 horas.'**
  String get outcomeDispositionSelfCareDesc;

  /// Routine disposition
  ///
  /// In pt, this message translates to:
  /// **'Consulta de Rotina'**
  String get outcomeDispositionRoutine;

  /// Routine description
  ///
  /// In pt, this message translates to:
  /// **'Agende uma consulta preventiva nos próximos dias com um profissional de saúde.'**
  String get outcomeDispositionRoutineDesc;

  /// Urgent disposition
  ///
  /// In pt, this message translates to:
  /// **'Pronto Atendimento'**
  String get outcomeDispositionUrgent;

  /// Urgent description
  ///
  /// In pt, this message translates to:
  /// **'Busque avaliação médica presencial em uma unidade de saúde em até 24 horas.'**
  String get outcomeDispositionUrgentDesc;

  /// Emergency disposition
  ///
  /// In pt, this message translates to:
  /// **'Atendimento de Emergência'**
  String get outcomeDispositionEmergency;

  /// Emergency description
  ///
  /// In pt, this message translates to:
  /// **'Seus sintomas exigem atenção imediata. Procure um serviço de emergência ou ligue 192.'**
  String get outcomeDispositionEmergencyDesc;

  /// Organic primacy title
  ///
  /// In pt, this message translates to:
  /// **'Atenção: Primazia Orgânica'**
  String get outcomeOrganicPrimacyTitle;

  /// Organic primacy description
  ///
  /// In pt, this message translates to:
  /// **'Sintomas físicos concomitantes ao desconforto emocional requerem avaliação médica física prioritária antes de serem atribuídos unicamente ao estresse psicológico.'**
  String get outcomeOrganicPrimacyDesc;

  /// Articles section title
  ///
  /// In pt, this message translates to:
  /// **'Artigos Médicos Recomendados'**
  String get outcomeArticlesTitle;

  /// Articles section subtitle
  ///
  /// In pt, this message translates to:
  /// **'Conteúdos preventivos elaborados por especialistas renomados'**
  String get outcomeArticlesSubtitle;

  /// Article read time in minutes
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min de leitura'**
  String outcomeReadTime(int minutes);

  /// Button to finish triage and return home
  ///
  /// In pt, this message translates to:
  /// **'Concluir e Voltar ao Início'**
  String get outcomeDoneButton;

  /// Screen 5 Antiburla Bottom Sheet title
  ///
  /// In pt, this message translates to:
  /// **'Verificação Histórica'**
  String get antiburlaTitle;

  /// Empathetic question prompt for Antiburla historical check
  ///
  /// In pt, this message translates to:
  /// **'Você registrou um sintoma similar há {days} dias. É a mesma sensação que voltou ou algo totalmente novo?'**
  String antiburlaDialogPrompt(int days);

  /// Button label when symptom is recurring from previous episode
  ///
  /// In pt, this message translates to:
  /// **'É a mesma sensação que voltou'**
  String get antiburlaOptionRecurring;

  /// Explanation for recurring symptom choice
  ///
  /// In pt, this message translates to:
  /// **'Ajustaremos o início para \'Há alguns dias\' para manter seu histórico clínico consistente.'**
  String get antiburlaOptionRecurringDesc;

  /// Button label when symptom is an isolated new occurrence
  ///
  /// In pt, this message translates to:
  /// **'É um sentimento completamente novo'**
  String get antiburlaOptionNew;

  /// Explanation for new symptom choice
  ///
  /// In pt, this message translates to:
  /// **'Manteremos registrado como um evento agudo que começou hoje.'**
  String get antiburlaOptionNewDesc;

  /// Title for biological discordance alert
  ///
  /// In pt, this message translates to:
  /// **'Aviso Anatômico Preventivo'**
  String get antiburlaBiologicalDiscordanceTitle;

  /// Description for biological discordance alert
  ///
  /// In pt, this message translates to:
  /// **'Notamos uma divergência entre a anatomia informada e os parâmetros do seu perfil. Deseja revisar antes de prosseguir?'**
  String get antiburlaBiologicalDiscordanceDesc;

  /// Notice banner when device is offline
  ///
  /// In pt, this message translates to:
  /// **'Modo Offline — Seus check-ins serão salvos localmente e sincronizados automaticamente.'**
  String get offlineBannerText;

  /// Count of pending outbox sync items
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 registro pendente de sincronização} other{{count} registros pendentes de sincronização}}'**
  String offlineSyncPendingCount(int count);

  /// Toast message when outbox sync completes
  ///
  /// In pt, this message translates to:
  /// **'Sincronização concluída com sucesso.'**
  String get offlineSyncSuccessText;

  /// Explanatory text for offline functionality
  ///
  /// In pt, this message translates to:
  /// **'Você está offline. Seu histórico e avaliação continuam funcionando normalmente.'**
  String get offlineModeNotice;

  /// Title of the historical dashboard screen
  ///
  /// In pt, this message translates to:
  /// **'Histórico & Tendências'**
  String get historyScreenTitle;

  /// Tab label for emotional vertical
  ///
  /// In pt, this message translates to:
  /// **'Psico-Emocional'**
  String get tabEmotional;

  /// Tab label for physical vertical
  ///
  /// In pt, this message translates to:
  /// **'Física'**
  String get tabPhysical;

  /// Title of the 2D anatomical body map
  ///
  /// In pt, this message translates to:
  /// **'Mapa Corporal 2D (14 Dias)'**
  String get bodyMapTitle;

  /// Hint to interact with the body map
  ///
  /// In pt, this message translates to:
  /// **'Toque em uma região para ver detalhes'**
  String get bodyMapHint;

  /// Legend label for no pain
  ///
  /// In pt, this message translates to:
  /// **'Sem dor'**
  String get heatLegendNone;

  /// Legend label for mild pain
  ///
  /// In pt, this message translates to:
  /// **'Leve (1-2)'**
  String get heatLegendMild;

  /// Legend label for moderate pain
  ///
  /// In pt, this message translates to:
  /// **'Moderada (3)'**
  String get heatLegendModerate;

  /// Legend label for severe pain
  ///
  /// In pt, this message translates to:
  /// **'Intensa (4-5)'**
  String get heatLegendSevere;

  /// Title for emotional trend chart
  ///
  /// In pt, this message translates to:
  /// **'Evolução Emocional (7 Dias)'**
  String get emotionalChartTitle;

  /// Title for critical recurrence cards
  ///
  /// In pt, this message translates to:
  /// **'Foco de Atenção'**
  String get criticalRecurrenceTitle;

  /// Title for retrospective list feed
  ///
  /// In pt, this message translates to:
  /// **'Registros Anteriores'**
  String get retrospectiveFeedTitle;

  /// Empty state title when history is empty
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro anterior'**
  String get emptyHistoryTitle;

  /// Empty state subtitle
  ///
  /// In pt, this message translates to:
  /// **'Seus check-ins diários concluídos aparecerão aqui.'**
  String get emptyHistorySubtitle;

  /// Button to read recommended article on recurrence card
  ///
  /// In pt, this message translates to:
  /// **'Ler Artigo Recomendado'**
  String get readRecommendedArticle;

  /// Title for Privacy Center screen
  ///
  /// In pt, this message translates to:
  /// **'Privacidade & Dados (LGPD)'**
  String get privacyCenterTitle;

  /// Title for data export section
  ///
  /// In pt, this message translates to:
  /// **'Exportação de Dados'**
  String get exportDataTitle;

  /// Description for data export section
  ///
  /// In pt, this message translates to:
  /// **'Baixe uma cópia completa dos seus dados pessoais e histórico clínico em formato JSON conforme o Art. 18, V da LGPD.'**
  String get exportDataDesc;

  /// Button to export user data
  ///
  /// In pt, this message translates to:
  /// **'Exportar Dados (JSON)'**
  String get exportDataButton;

  /// Success message after exporting data
  ///
  /// In pt, this message translates to:
  /// **'Dados exportados com sucesso.'**
  String get exportSuccessMessage;

  /// Title for account deletion section
  ///
  /// In pt, this message translates to:
  /// **'Exclusão Permanente da Conta'**
  String get deleteAccountTitle;

  /// Description for account deletion section
  ///
  /// In pt, this message translates to:
  /// **'Apague definitivamente sua conta e todos os registros de saúde conforme o Art. 18 da LGPD. Esta ação não pode ser desfeita.'**
  String get deleteAccountDesc;

  /// Button to trigger account deletion dialog
  ///
  /// In pt, this message translates to:
  /// **'Excluir Minha Conta'**
  String get deleteAccountButton;

  /// Title for delete confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Exclusão Definitiva'**
  String get deleteConfirmTitle;

  /// Description for delete confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Para confirmar a exclusão irreversível da sua conta e de todos os dados de saúde, digite sua senha:'**
  String get deleteConfirmDesc;

  /// Success message after account deletion
  ///
  /// In pt, this message translates to:
  /// **'Conta e dados excluídos com sucesso.'**
  String get deleteSuccessMessage;

  /// Button to confirm permanent deletion
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Exclusão Irreversível'**
  String get confirmPermanentDeletion;

  /// Placeholder for password confirmation input
  ///
  /// In pt, this message translates to:
  /// **'Senha de confirmação'**
  String get enterPassword;

  /// Title for exported JSON preview dialog
  ///
  /// In pt, this message translates to:
  /// **'Prévia dos Dados Exportados'**
  String get previewDataTitle;

  /// Generic cancel button text
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// Generic close button text
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
