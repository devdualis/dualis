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

  /// Emotional dimension 1: Ansiosa / Agitação
  ///
  /// In pt, this message translates to:
  /// **'Ansiosa / Agitação'**
  String get triageOptAnsiosaAgitacao;

  /// Emotional dimension 2: Depressiva / Desânimo
  ///
  /// In pt, this message translates to:
  /// **'Depressiva / Desânimo'**
  String get triageOptDepressivaDesanimo;

  /// Emotional dimension 3: Estresse / Burnout
  ///
  /// In pt, this message translates to:
  /// **'Estresse / Burnout'**
  String get triageOptEstresseBurnout;

  /// Emotional dimension 4: Somática (Psicossomática)
  ///
  /// In pt, this message translates to:
  /// **'Somática (Psicossomática)'**
  String get triageOptSomatica;

  /// Emotional dimension 5: Sono (Insônia/Hipersônia)
  ///
  /// In pt, this message translates to:
  /// **'Sono (Insônia / Hipersônia)'**
  String get triageOptSono;

  /// Emotional dimension 6: Cognitiva / Foco
  ///
  /// In pt, this message translates to:
  /// **'Cognitiva / Foco'**
  String get triageOptCognitivaFoco;

  /// Emotional dimension 7: Autoestima / Autoimagem
  ///
  /// In pt, this message translates to:
  /// **'Autoestima / Autoimagem'**
  String get triageOptAutoestima;

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

  /// Question 4 emotional generic
  ///
  /// In pt, this message translates to:
  /// **'Você consegue identificar se existe um motivo principal para isso estar acontecendo hoje?'**
  String get triageQ4Emotional;

  /// Question 4 anxiety and agitation
  ///
  /// In pt, this message translates to:
  /// **'O que parece estar disparando essa sensação de ansiedade, agitação ou aperto?'**
  String get triageQ4Ansiedade;

  /// Question 4 depression and discouragement
  ///
  /// In pt, this message translates to:
  /// **'Você consegue identificar se algum acontecimento recente ou sentimento pesou mais no seu desânimo?'**
  String get triageQ4Depressao;

  /// Question 4 stress and burnout
  ///
  /// In pt, this message translates to:
  /// **'De onde vem a maior parte da pressão ou esgotamento que você está sentindo?'**
  String get triageQ4EstresseBurnout;

  /// Question 4 somatic tension
  ///
  /// In pt, this message translates to:
  /// **'Essa tensão no corpo ou aperto físico costuma piorar em quais situações?'**
  String get triageQ4Somatica;

  /// Question 4 sleep disturbances
  ///
  /// In pt, this message translates to:
  /// **'Qual tem sido a principal dificuldade que atrapalha suas noites de sono?'**
  String get triageQ4Sono;

  /// Question 4 cognitive focus
  ///
  /// In pt, this message translates to:
  /// **'O que mais parece estar prejudicando sua concentração ou clareza mental?'**
  String get triageQ4CognitivaFoco;

  /// Question 4 self-esteem
  ///
  /// In pt, this message translates to:
  /// **'O que tem despertado com mais intensidade essa sensação de insegurança ou autocrítica?'**
  String get triageQ4Autoestima;

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

  /// Emotional trigger: Overwhelmed by tasks or deadlines
  ///
  /// In pt, this message translates to:
  /// **'Sobrecarga de tarefas, prazos ou expectativas'**
  String get triageOptSimCobrancaPrazos;

  /// Emotional trigger: Interpersonal conflict
  ///
  /// In pt, this message translates to:
  /// **'Conflito ou discussão com pessoa próxima'**
  String get triageOptSimConflitoRelacionamento;

  /// Emotional trigger: Uncertainty or fear of change
  ///
  /// In pt, this message translates to:
  /// **'Medo de mudanças, notícias ou incerteza futura'**
  String get triageOptSimIncertezaFuturo;

  /// Emotional trigger: Excess caffeine or agitation
  ///
  /// In pt, this message translates to:
  /// **'Excesso de café, energéticos ou ambiente agitado'**
  String get triageOptSimExcessoEstimulantes;

  /// Emotional trigger: Cannot identify, sudden onset
  ///
  /// In pt, this message translates to:
  /// **'Não sei identificar, surgiu de repente'**
  String get triageOptNaoSeiDizerEmocional;

  /// Emotional trigger: Loss, breakup or grief
  ///
  /// In pt, this message translates to:
  /// **'Perda, término de relacionamento ou luto'**
  String get triageOptSimPerdaLuto;

  /// Emotional trigger: Loneliness or isolation
  ///
  /// In pt, this message translates to:
  /// **'Sensação de solidão, isolamento ou incompreensão'**
  String get triageOptSimSolidaoIsolamento;

  /// Emotional trigger: Frustration or disappointment
  ///
  /// In pt, this message translates to:
  /// **'Frustração com algo que não saiu como esperado'**
  String get triageOptSimFrustracaoDesilusao;

  /// Emotional trigger: Accumulated exhaustion without breaks
  ///
  /// In pt, this message translates to:
  /// **'Cansaço prolongado sem pausas para recuperação'**
  String get triageOptSimCansacoAcumulado;

  /// Emotional trigger: Work pressure or excessive hours
  ///
  /// In pt, this message translates to:
  /// **'Excesso de carga horária, cobranças ou prazos no trabalho'**
  String get triageOptSimPressaoTrabalho;

  /// Emotional trigger: Family, financial or domestic strain
  ///
  /// In pt, this message translates to:
  /// **'Cuidados familiares, finanças ou tarefas domésticas'**
  String get triageOptSimResponsabilidadesCasa;

  /// Emotional trigger: Lack of rest or downtime
  ///
  /// In pt, this message translates to:
  /// **'Sem tempo livre para lazer, repouso ou desconectar'**
  String get triageOptSimFaltaDescanso;

  /// Emotional trigger: Toxic or straining environment
  ///
  /// In pt, this message translates to:
  /// **'Relações difíceis ou ambiente diário desgastante'**
  String get triageOptSimAmbienteToxico;

  /// Emotional trigger: During work or intense pressure
  ///
  /// In pt, this message translates to:
  /// **'Durante a jornada de trabalho ou momentos de pressão'**
  String get triageOptSimDuranteTrabalho;

  /// Emotional trigger: After conflict or fright
  ///
  /// In pt, this message translates to:
  /// **'Logo após discussões, desentendimentos ou sustos'**
  String get triageOptSimDiscussaoConflito;

  /// Emotional trigger: End of day when attempting to rest
  ///
  /// In pt, this message translates to:
  /// **'No fim do dia, ao tentar relaxar ou deitar'**
  String get triageOptSimFinalDoDia;

  /// Emotional trigger: Whenever thinking about issues
  ///
  /// In pt, this message translates to:
  /// **'Em qualquer momento ao pensar nos problemas'**
  String get triageOptSimPreocupacaoConstante;

  /// Emotional trigger: Racing thoughts at bedtime
  ///
  /// In pt, this message translates to:
  /// **'Cabeça acelerada / pensamentos na hora de dormir'**
  String get triageOptSimDificuldadePegarSono;

  /// Emotional trigger: Middle of the night awakening
  ///
  /// In pt, this message translates to:
  /// **'Acordar no meio da noite e não conseguir voltar a dormir'**
  String get triageOptSimAcordaMadrugada;

  /// Emotional trigger: Restless sleep or nightmares
  ///
  /// In pt, this message translates to:
  /// **'Sono leve, agitado, com pesadelos ou despertares'**
  String get triageOptSimSonoAgitadoPesadelos;

  /// Emotional trigger: Late screens or irregular sleep habits
  ///
  /// In pt, this message translates to:
  /// **'Uso de celular/telas até tarde ou horários irregulares'**
  String get triageOptSimHorarioIrregularTelas;

  /// Emotional trigger: Multitasking overload
  ///
  /// In pt, this message translates to:
  /// **'Muitas coisas para fazer ao mesmo tempo / excesso de estímulos'**
  String get triageOptSimSobrecargaMultitarefas;

  /// Emotional trigger: Intrusive worried thoughts
  ///
  /// In pt, this message translates to:
  /// **'Pensamentos de preocupação que interrompem o raciocínio'**
  String get triageOptSimPreocupacaoIntrusiva;

  /// Emotional trigger: Accumulated mental exhaustion
  ///
  /// In pt, this message translates to:
  /// **'Cansaço mental acumulado após muitas horas de esforço'**
  String get triageOptSimExaustaoMental;

  /// Emotional trigger: Lack of motivation or apathy
  ///
  /// In pt, this message translates to:
  /// **'Desinteresse, falta de energia ou apatia com as tarefas'**
  String get triageOptSimFaltaMotivacao;

  /// Emotional trigger: Comparison on social media or peers
  ///
  /// In pt, this message translates to:
  /// **'Comparação com outras pessoas (redes sociais ou colegas)'**
  String get triageOptSimComparacaoRedes;

  /// Emotional trigger: Fear of failure or judgment
  ///
  /// In pt, this message translates to:
  /// **'Medo de errar, não corresponder ou ser julgado'**
  String get triageOptSimMedoFalharJulgamento;

  /// Emotional trigger: Recent criticism or rejection
  ///
  /// In pt, this message translates to:
  /// **'Crítica recente recebida ou sensação de rejeição'**
  String get triageOptSimCriticaRejeicao;

  /// Emotional trigger: Difficulty acknowledging own achievements
  ///
  /// In pt, this message translates to:
  /// **'Dificuldade em reconhecer suas próprias conquistas'**
  String get triageOptSimDesvalorizacaoPropria;

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

  /// Physical system 1: Cabeça e Pescoço
  ///
  /// In pt, this message translates to:
  /// **'Cabeça e Pescoço'**
  String get triageOptCabecaPescoco;

  /// Physical system 2: Cardiovascular / Tórax
  ///
  /// In pt, this message translates to:
  /// **'Cardiovascular / Tórax'**
  String get triageOptCardiovascularTorax;

  /// Physical system 3: Sistema Respiratório
  ///
  /// In pt, this message translates to:
  /// **'Sistema Respiratório'**
  String get triageOptRespiratorio;

  /// Physical system 4: Gastrointestinal / Abdômen
  ///
  /// In pt, this message translates to:
  /// **'Gastrointestinal / Abdômen'**
  String get triageOptGastrointestinalAbdomen;

  /// Physical system 5: Coluna e Dor Dorsal
  ///
  /// In pt, this message translates to:
  /// **'Coluna e Dor Dorsal'**
  String get triageOptColunaDorDorsal;

  /// Physical system 6: Membros Superiores D/E
  ///
  /// In pt, this message translates to:
  /// **'Membros Superiores D/E'**
  String get triageOptMembrosSuperiores;

  /// Physical system 7: Membros Inferiores D/E
  ///
  /// In pt, this message translates to:
  /// **'Membros Inferiores D/E'**
  String get triageOptMembrosInferiores;

  /// Physical system 8: Sistema Neurológico
  ///
  /// In pt, this message translates to:
  /// **'Sistema Neurológico'**
  String get triageOptNeurologico;

  /// Physical system 9: Geniturinário / Pélvico
  ///
  /// In pt, this message translates to:
  /// **'Geniturinário / Pélvico'**
  String get triageOptGeniturinarioPelvico;

  /// Physical system 10: Sistema Dermatológico
  ///
  /// In pt, this message translates to:
  /// **'Sistema Dermatológico'**
  String get triageOptDermatologico;

  /// Physical system 11: Muscular / Geral Sistêmico
  ///
  /// In pt, this message translates to:
  /// **'Muscular / Geral Sistêmico'**
  String get triageOptMuscularGeralSistemico;

  /// Physical system 12: Endócrino / Metabólico
  ///
  /// In pt, this message translates to:
  /// **'Endócrino / Metabólico'**
  String get triageOptEndocrinoMetabolico;

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

  /// Question 4 physical generic
  ///
  /// In pt, this message translates to:
  /// **'Você lembra de ter feito algum esforço atípico, exercício pesado ou sofrido alguma batida/queda recentemente?'**
  String get triageQ4Physical;

  /// Question 4 head and neck
  ///
  /// In pt, this message translates to:
  /// **'Você notou algum fator associado, como estresse intenso, muitas horas em telas, noite mal dormida ou sinusite/resfriado?'**
  String get triageQ4CabecaPescoco;

  /// Question 4 cardiovascular and chest
  ///
  /// In pt, this message translates to:
  /// **'O desconforto no peito ou palpitação começou após esforço físico, estresse emocional ou consumo de estimulantes?'**
  String get triageQ4CardiovascularTorax;

  /// Question 4 respiratory
  ///
  /// In pt, this message translates to:
  /// **'Você teve contato com poeira, fumaça, ar frio ou está com sintomas de gripe/resfriado?'**
  String get triageQ4Respiratorio;

  /// Question 4 gastrointestinal
  ///
  /// In pt, this message translates to:
  /// **'Você ingeriu algum alimento diferente ou pesado, tomou remédios recentes ou ficou muito tempo em jejum?'**
  String get triageQ4Gastrointestinal;

  /// Question 4 spine and back
  ///
  /// In pt, this message translates to:
  /// **'Você carregou peso excessivo, permaneceu muito tempo em má postura ou sofreu algum impacto/queda?'**
  String get triageQ4ColunaDorDorsal;

  /// Question 4 upper limbs
  ///
  /// In pt, this message translates to:
  /// **'Você realizou movimentos repetitivos (digitação, esforço manual), treino de braço/ombro ou sofreu impacto/queda?'**
  String get triageQ4MembrosSuperiores;

  /// Question 4 lower limbs
  ///
  /// In pt, this message translates to:
  /// **'Você fez caminhada longa, corrida, ficou muito tempo em pé/sentado ou sofreu torção/tropeço?'**
  String get triageQ4MembrosInferiores;

  /// Question 4 neurological
  ///
  /// In pt, this message translates to:
  /// **'O sintoma surgiu após levantar-se rápido, ficar sem comer/beber água, crise de ansiedade ou posição desconfortável?'**
  String get triageQ4Neurologico;

  /// Question 4 genitourinary and pelvic
  ///
  /// In pt, this message translates to:
  /// **'Você percebeu relação com pouca água/reter urina, ciclo menstrual, relação íntima ou uso de roupas úmidas?'**
  String get triageQ4Geniturinario;

  /// Question 4 dermatological
  ///
  /// In pt, this message translates to:
  /// **'Você notou algo que possa ter causado isso, como um produto novo, exposição ao sol/calor ou contato com algo (planta, inseto, substância)?'**
  String get triageQ4Dermatological;

  /// Question 4 muscular general
  ///
  /// In pt, this message translates to:
  /// **'Você sente isso associado a cansaço extremo, início de gripe/virose, falta de descanso ou desidratação?'**
  String get triageQ4MuscularGeral;

  /// Question 4 endocrine and metabolic
  ///
  /// In pt, this message translates to:
  /// **'Você notou relação com jejum prolongado, refeição açucarada, alteração de medicamento ou calor excessivo?'**
  String get triageQ4EndocrinoMetabolico;

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

  /// Dermatological trigger: New product
  ///
  /// In pt, this message translates to:
  /// **'Sim, usei um produto novo (cosmético, sabonete, etc.)'**
  String get triageOptSimProdutoNovo;

  /// Dermatological trigger: Sun/heat exposure
  ///
  /// In pt, this message translates to:
  /// **'Sim, houve exposição ao sol, calor ou suor intenso'**
  String get triageOptSimExposicaoSolCalor;

  /// Dermatological trigger: Insect/plant/substance contact
  ///
  /// In pt, this message translates to:
  /// **'Sim, tive contato com planta, inseto ou substância'**
  String get triageOptSimPicadaContato;

  /// Trigger: Stress or irregular sleep
  ///
  /// In pt, this message translates to:
  /// **'Estresse ou sono irregular'**
  String get triageOptSimEstresseSono;

  /// Trigger: Screen time / eye strain
  ///
  /// In pt, this message translates to:
  /// **'Muitas horas em telas / esforço visual'**
  String get triageOptSimTelasEsforcoVisual;

  /// Trigger: Muscle tension / neck posture
  ///
  /// In pt, this message translates to:
  /// **'Tensão muscular ou má postura no pescoço'**
  String get triageOptSimPosturaPescoco;

  /// Trigger: Cold or sinusitis
  ///
  /// In pt, this message translates to:
  /// **'Sintomas de resfriado ou sinusite'**
  String get triageOptSimResfriadoSinusite;

  /// Trigger: After physical exertion
  ///
  /// In pt, this message translates to:
  /// **'Logo após esforço físico ou caminhada'**
  String get triageOptSimEsforcoFisico;

  /// Trigger: Anxiety or acute stress
  ///
  /// In pt, this message translates to:
  /// **'Momento de forte ansiedade ou estresse'**
  String get triageOptSimEstresseAnsiedade;

  /// Trigger: Caffeine or stimulant intake
  ///
  /// In pt, this message translates to:
  /// **'Consumo de café, energético ou estimulante'**
  String get triageOptSimCafeinaEstimulante;

  /// Trigger: At rest or spontaneous
  ///
  /// In pt, this message translates to:
  /// **'Não, surgiu espontaneamente ou em repouso'**
  String get triageOptNaoSurgiuEmRepouso;

  /// Trigger: Dust, smoke, allergen exposure
  ///
  /// In pt, this message translates to:
  /// **'Exposição a poeira, mofo, fumaça ou ar-condicionado'**
  String get triageOptSimAlergiaAmbiente;

  /// Trigger: Flu or respiratory infection
  ///
  /// In pt, this message translates to:
  /// **'Sintomas de gripe, resfriado ou dor de garganta'**
  String get triageOptSimGripeInfeccao;

  /// Trigger: Weather change or cold air
  ///
  /// In pt, this message translates to:
  /// **'Mudança brusca de temperatura ou ar frio'**
  String get triageOptSimMudancaClima;

  /// Trigger: Unusual or heavy food
  ///
  /// In pt, this message translates to:
  /// **'Alimento diferente, pesado ou suspeito'**
  String get triageOptSimAlimentacaoDiferente;

  /// Trigger: Recent medication
  ///
  /// In pt, this message translates to:
  /// **'Uso recente de medicamento ou anti-inflamatório'**
  String get triageOptSimMedicamentoRecente;

  /// Trigger: Fasting or severe stress
  ///
  /// In pt, this message translates to:
  /// **'Longo período de jejum ou estresse intenso'**
  String get triageOptSimJejumEstresse;

  /// Trigger: Unrelated to food
  ///
  /// In pt, this message translates to:
  /// **'Não, começou sem relação com alimentação'**
  String get triageOptNaoSemRelacaoAlimento;

  /// Trigger: Heavy lifting
  ///
  /// In pt, this message translates to:
  /// **'Pegou peso ou fez esforço lombar'**
  String get triageOptSimCarregouPeso;

  /// Trigger: Prolonged sitting or poor posture
  ///
  /// In pt, this message translates to:
  /// **'Muito tempo sentado ou má postura ao dormir'**
  String get triageOptSimPosturaProlongada;

  /// Trigger: Awkward movement or impact
  ///
  /// In pt, this message translates to:
  /// **'Movimento brusco (\'mau jeito\') ou impacto/queda'**
  String get triageOptSimMauJeitoQueda;

  /// Trigger: Repetitive motions
  ///
  /// In pt, this message translates to:
  /// **'Movimentos repetitivos (digitação, celular, trabalho manual)'**
  String get triageOptSimMovimentoRepetitivo;

  /// Trigger: Arm/shoulder workout or strain
  ///
  /// In pt, this message translates to:
  /// **'Exercício físico ou sobrecarga nos braços/ombros'**
  String get triageOptSimTreinoSobrecarga;

  /// Trigger: Direct impact or slept on arm
  ///
  /// In pt, this message translates to:
  /// **'Pancada, queda ou dormiu de mau jeito sobre o braço'**
  String get triageOptSimTraumaPancada;

  /// Trigger: Long walk or sports
  ///
  /// In pt, this message translates to:
  /// **'Caminhada longa, corrida ou esporte recente'**
  String get triageOptSimCaminhadaCorrida;

  /// Trigger: Long standing or sitting
  ///
  /// In pt, this message translates to:
  /// **'Muitas horas em pé ou muito tempo sentado'**
  String get triageOptSimTempoEmPeSentado;

  /// Trigger: Sprain, stumble, or fall
  ///
  /// In pt, this message translates to:
  /// **'Torção no tornozelo/joelho, tropeço ou queda'**
  String get triageOptSimTorcaoTropeco;

  /// Trigger: Standing up quickly
  ///
  /// In pt, this message translates to:
  /// **'Ao levantar-se rapidamente ou mudar de posição'**
  String get triageOptSimLevantarRapido;

  /// Trigger: Fasting or dehydration
  ///
  /// In pt, this message translates to:
  /// **'Horas sem se alimentar ou pouca ingestão de água'**
  String get triageOptSimJejumDesidratacao;

  /// Trigger: Tension or hyperventilation
  ///
  /// In pt, this message translates to:
  /// **'Durante momento de tensão ou respiração acelerada'**
  String get triageOptSimAnsiedadeHiperventilacao;

  /// Trigger: Nerve compression posture
  ///
  /// In pt, this message translates to:
  /// **'Membro pressionado ou postura comprimindo nervo'**
  String get triageOptSimCompressaoPostural;

  /// Trigger: Low water or held urine
  ///
  /// In pt, this message translates to:
  /// **'Pouca ingestão de água ou segurou urina por muito tempo'**
  String get triageOptSimBaixaIngestaoUrina;

  /// Trigger: Menstrual cycle
  ///
  /// In pt, this message translates to:
  /// **'Período pré-menstrual ou menstrual'**
  String get triageOptSimCicloMenstrual;

  /// Trigger: Post intimacy or intimate product
  ///
  /// In pt, this message translates to:
  /// **'Após relação íntima ou troca de produtos íntimos'**
  String get triageOptSimPosRelacaoIntima;

  /// Trigger: Damp or tight clothing
  ///
  /// In pt, this message translates to:
  /// **'Uso de roupas úmidas ou muito apertadas'**
  String get triageOptSimRoupasUmidas;

  /// Trigger: Extreme fatigue or sleepless nights
  ///
  /// In pt, this message translates to:
  /// **'Cansaço extremo, sobrecarga ou noites sem dormir'**
  String get triageOptSimCansacoEsgotamento;

  /// Trigger: Fever or viral symptoms
  ///
  /// In pt, this message translates to:
  /// **'Sensação de febre, calafrio ou início de virose'**
  String get triageOptSimSintomasGripeVirose;

  /// Trigger: Atypical whole-body activity
  ///
  /// In pt, this message translates to:
  /// **'Atividade física atípica (mudança, faxina pesada)'**
  String get triageOptSimAtividadeGlobal;

  /// Trigger: Dehydration or prolonged heat
  ///
  /// In pt, this message translates to:
  /// **'Pouca hidratação ou exposição prolongada ao calor'**
  String get triageOptSimDesidratacaoCalor;

  /// Trigger: Fasting or heavy sugary meal
  ///
  /// In pt, this message translates to:
  /// **'Horas sem comer ou após refeição pesada/açucarada'**
  String get triageOptSimJejumAlimentacao;

  /// Trigger: Missed or altered medication
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu ou alterou dose de medicamento habitual'**
  String get triageOptSimAjusteMedicamento;

  /// Trigger: High heat or low fluids
  ///
  /// In pt, this message translates to:
  /// **'Ambiente muito quente ou baixa ingestão de líquidos'**
  String get triageOptSimCalorDesidratacao;

  /// Trigger: Acute stress or routine disruption
  ///
  /// In pt, this message translates to:
  /// **'Pico recente de estresse ou quebra de rotina'**
  String get triageOptSimEstresseSobrecarga;

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

  /// Title for the off-topic narrative confirmation bottom sheet
  ///
  /// In pt, this message translates to:
  /// **'Isso parece um sintoma?'**
  String get offTopicNarrativeTitle;

  /// Body text for the off-topic narrative confirmation bottom sheet
  ///
  /// In pt, this message translates to:
  /// **'O texto que você escreveu não parece descrever um sintoma físico ou emocional. Deseja revisar sua descrição ou continuar mesmo assim?'**
  String get offTopicNarrativeDesc;

  /// Button to go back and edit the free-text narrative
  ///
  /// In pt, this message translates to:
  /// **'Editar Descrição'**
  String get offTopicNarrativeEditButton;

  /// Button to proceed despite the off-topic narrative warning
  ///
  /// In pt, this message translates to:
  /// **'Continuar Mesmo Assim'**
  String get offTopicNarrativeContinueButton;

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

  /// Title for the settings and profile management screen
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// Section header for user profile details
  ///
  /// In pt, this message translates to:
  /// **'Perfil e Identificação'**
  String get profileSection;

  /// Action button to change user avatar
  ///
  /// In pt, this message translates to:
  /// **'Alterar Foto'**
  String get changeAvatar;

  /// Title for avatar selection modal
  ///
  /// In pt, this message translates to:
  /// **'Escolha seu Avatar'**
  String get selectAvatar;

  /// Label for full name input field
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get nameLabel;

  /// Label for date of birth picker field
  ///
  /// In pt, this message translates to:
  /// **'Data de Nascimento'**
  String get dateOfBirthLabel;

  /// Label for calculated age display
  ///
  /// In pt, this message translates to:
  /// **'Idade'**
  String get ageLabel;

  /// Display text for age in years
  ///
  /// In pt, this message translates to:
  /// **'{age} anos'**
  String yearsOld(int age);

  /// Button to save profile modifications
  ///
  /// In pt, this message translates to:
  /// **'Salvar Alterações'**
  String get saveProfile;

  /// Snackbar message when profile is successfully updated
  ///
  /// In pt, this message translates to:
  /// **'Perfil atualizado com sucesso!'**
  String get profileUpdatedSuccess;

  /// Section header for security settings
  ///
  /// In pt, this message translates to:
  /// **'Segurança e Acesso'**
  String get securitySection;

  /// Title and button for password change
  ///
  /// In pt, this message translates to:
  /// **'Alterar Senha'**
  String get changePassword;

  /// Label for current password input
  ///
  /// In pt, this message translates to:
  /// **'Senha Atual'**
  String get currentPassword;

  /// Label for new password input
  ///
  /// In pt, this message translates to:
  /// **'Nova Senha'**
  String get newPassword;

  /// Label for new password confirmation input
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Nova Senha'**
  String get confirmNewPassword;

  /// Placeholder for current password input
  ///
  /// In pt, this message translates to:
  /// **'Digite sua senha atual'**
  String get currentPasswordHint;

  /// Placeholder for new password input
  ///
  /// In pt, this message translates to:
  /// **'Nova senha segura'**
  String get newPasswordHint;

  /// Placeholder for confirming new password input
  ///
  /// In pt, this message translates to:
  /// **'Repita a nova senha'**
  String get confirmPasswordHint;

  /// Snackbar message when password is successfully changed
  ///
  /// In pt, this message translates to:
  /// **'Senha alterada com sucesso!'**
  String get passwordChangedSuccess;

  /// Error message when new password and confirmation do not match
  ///
  /// In pt, this message translates to:
  /// **'As novas senhas não coincidem.'**
  String get passwordsDoNotMatch;

  /// Hint describing password complexity requirements
  ///
  /// In pt, this message translates to:
  /// **'Mínimo de 8 caracteres, com letra maiúscula, minúscula, número e símbolo.'**
  String get passwordComplexityHint;

  /// Navigation link to privacy center
  ///
  /// In pt, this message translates to:
  /// **'Central de Privacidade e LGPD'**
  String get privacyShortcut;

  /// Button to securely log out from application
  ///
  /// In pt, this message translates to:
  /// **'Sair da Conta'**
  String get logoutButton;

  /// Section header for language selection in settings
  ///
  /// In pt, this message translates to:
  /// **'Idioma do Aplicativo'**
  String get settingsLanguageSection;

  /// Portuguese language option
  ///
  /// In pt, this message translates to:
  /// **'Português (Brasil)'**
  String get settingsLanguagePortuguese;

  /// Spanish language option
  ///
  /// In pt, this message translates to:
  /// **'Español'**
  String get settingsLanguageSpanish;

  /// English language option
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Section header for privacy and data in settings
  ///
  /// In pt, this message translates to:
  /// **'Privacidade e Dados'**
  String get settingsPrivacySection;

  /// Tile to navigate to full privacy center
  ///
  /// In pt, this message translates to:
  /// **'Central de Privacidade e LGPD'**
  String get settingsPrivacyCenterTile;

  /// Subtitle for privacy center tile
  ///
  /// In pt, this message translates to:
  /// **'Acesse e gerencie seus dados de saúde'**
  String get settingsPrivacyCenterSubtitle;

  /// Tile to navigate to historical dashboard
  ///
  /// In pt, this message translates to:
  /// **'Histórico e Tendências'**
  String get settingsDataHistoryTile;

  /// Subtitle for history tile
  ///
  /// In pt, this message translates to:
  /// **'Visualize seu histórico de triagens'**
  String get settingsDataHistorySubtitle;

  /// Title of the delete history item confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Descartar registro do histórico'**
  String get deleteHistoryItemTitle;

  /// Confirmation message when discarding a history entry
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza de que deseja descartar este registro de triagem do seu histórico? Esta ação é irreversível.'**
  String get deleteHistoryItemConfirm;

  /// Success snackbar message when record is deleted
  ///
  /// In pt, this message translates to:
  /// **'Registro removido com sucesso.'**
  String get deleteHistoryItemSuccess;

  /// Error snackbar message when record deletion fails
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível remover o registro.'**
  String get deleteHistoryItemError;

  /// Action button text to discard/delete
  ///
  /// In pt, this message translates to:
  /// **'Descartar'**
  String get deleteAction;

  /// Friendly network connection error
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.'**
  String get errorNetworkConnection;

  /// Friendly connection timeout error
  ///
  /// In pt, this message translates to:
  /// **'A comunicação com o servidor demorou muito. Tente novamente.'**
  String get errorConnectionTimeout;

  /// Friendly invalid credentials error
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou senha incorretos. Por favor, verifique suas credenciais.'**
  String get errorInvalidCredentials;

  /// Friendly duplicate email error
  ///
  /// In pt, this message translates to:
  /// **'Este e-mail já está cadastrado em nossa plataforma.'**
  String get errorEmailAlreadyExists;

  /// Friendly session expired error
  ///
  /// In pt, this message translates to:
  /// **'Sua sessão expirou. Por favor, acesse novamente.'**
  String get errorSessionExpired;

  /// Friendly verification code error
  ///
  /// In pt, this message translates to:
  /// **'Código de verificação incorreto ou expirado. Verifique os dígitos ou solicite um novo código.'**
  String get errorEmailVerificationCodeInvalid;

  /// Email verification success message
  ///
  /// In pt, this message translates to:
  /// **'E-mail verificado com sucesso! Bem-vindo ao DualisCheckUp.'**
  String get emailVerificationSuccess;

  /// Resend code success message
  ///
  /// In pt, this message translates to:
  /// **'Novo código enviado para seu e-mail.'**
  String get newCodeSentSuccess;

  /// Profile update error
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o perfil. Tente novamente.'**
  String get errorUpdateProfile;

  /// Change password error
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível alterar a senha. Verifique sua senha atual.'**
  String get errorChangePassword;

  /// Camera/gallery access error
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível acessar a câmera ou galeria do dispositivo.'**
  String get errorCameraGalleryAccess;

  /// Generic required field error
  ///
  /// In pt, this message translates to:
  /// **'Este campo é obrigatório.'**
  String get errorFieldRequired;

  /// Current password required error
  ///
  /// In pt, this message translates to:
  /// **'Informe sua senha atual.'**
  String get errorCurrentPasswordRequired;

  /// New password minimum length error
  ///
  /// In pt, this message translates to:
  /// **'A nova senha deve ter pelo menos 8 caracteres.'**
  String get errorNewPasswordMinLength;

  /// Password letters and numbers requirement error
  ///
  /// In pt, this message translates to:
  /// **'A senha deve conter letras e números.'**
  String get errorPasswordLettersAndDigits;

  /// Name minimum length error
  ///
  /// In pt, this message translates to:
  /// **'Nome deve ter pelo menos 2 caracteres.'**
  String get errorNameMinLength;

  /// Hint for date of birth selection
  ///
  /// In pt, this message translates to:
  /// **'Selecione sua data de nascimento'**
  String get selectDateOfBirthHint;

  /// Error loading triage history
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o histórico de triagens no momento.'**
  String get errorLoadHistory;

  /// Article link unavailable
  ///
  /// In pt, this message translates to:
  /// **'Link do artigo preventivo não disponível.'**
  String get errorArticleLinkUnavailable;

  /// Unable to open link error
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o link solicitado.'**
  String get errorUnableToOpenLink;

  /// Server internal error
  ///
  /// In pt, this message translates to:
  /// **'Nossos serviços estão passando por uma instabilidade temporária. Tente novamente em instantes.'**
  String get errorServerInternal;

  /// Unexpected generic error
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu uma instabilidade inesperada. Por favor, tente novamente.'**
  String get errorUnexpected;

  /// Bottom navigation Home label
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// Bottom navigation Today Outcome label
  ///
  /// In pt, this message translates to:
  /// **'Resultado do Dia'**
  String get navTodayOutcome;

  /// Bottom navigation History label
  ///
  /// In pt, this message translates to:
  /// **'Histórico & Mapa'**
  String get navHistory;

  /// Bottom navigation Hydration label
  ///
  /// In pt, this message translates to:
  /// **'Água'**
  String get navHydration;

  /// Water reminder notification title (immediate reminder)
  ///
  /// In pt, this message translates to:
  /// **'💧 Hora de Beber Água'**
  String get notifWaterTitle;

  /// Scheduled water reminder notification title
  ///
  /// In pt, this message translates to:
  /// **'💧 Hora de Beber Água ({time})'**
  String notifWaterTitleAt(String time);

  /// Water reminder body when intake tracking is enabled
  ///
  /// In pt, this message translates to:
  /// **'Toque para registrar a quantidade de água consumida.'**
  String get notifWaterBodyTracking;

  /// Water reminder body when intake tracking is disabled
  ///
  /// In pt, this message translates to:
  /// **'Mantenha seu corpo hidratado e saudável!'**
  String get notifWaterBodyReminder;

  /// Android notification channel name, soft water reminders
  ///
  /// In pt, this message translates to:
  /// **'Lembretes de Água (Aviso Suave)'**
  String get notifWaterChimeChannelName;

  /// Android notification channel description, soft water reminders
  ///
  /// In pt, this message translates to:
  /// **'Aviso de chegada estilo mensagem para lembrete de hidratação'**
  String get notifWaterChimeChannelDescription;

  /// Android notification channel name, alarm-style water reminders
  ///
  /// In pt, this message translates to:
  /// **'Lembretes de Água (Alarme Sonoro)'**
  String get notifWaterAlarmChannelName;

  /// Android notification channel description, alarm-style water reminders
  ///
  /// In pt, this message translates to:
  /// **'Alarme sonoro para lembrar de beber água a cada 2 horas'**
  String get notifWaterAlarmChannelDescription;

  /// Scheduled daily check-in reminder notification title
  ///
  /// In pt, this message translates to:
  /// **'🩺 Check-in Diário Dualis ({time})'**
  String notifCheckinTitleAt(String time);

  /// Daily check-in reminder notification body
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não atualizou seu estado de saúde hoje. Toque para realizar seu check-in!'**
  String get notifCheckinBody;

  /// Android notification channel name, daily check-in reminders
  ///
  /// In pt, this message translates to:
  /// **'Lembretes de Check-in Diário'**
  String get notifCheckinChannelName;

  /// Android notification channel description, daily check-in reminders
  ///
  /// In pt, this message translates to:
  /// **'Notificações a cada 2 horas para lembrar de atualizar seu check-in diário de saúde'**
  String get notifCheckinChannelDescription;

  /// Today's result, dual view: label of the first (physical) axis card
  ///
  /// In pt, this message translates to:
  /// **'1. Eixo Avaliação Física'**
  String get outcomeAxisPhysicalNumbered;

  /// Today's result, dual view: label of the second (psycho-emotional / associated component) axis card
  ///
  /// In pt, this message translates to:
  /// **'2. Eixo Avaliação Psico-emocional'**
  String get outcomeAxisEmotionalNumbered;
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
