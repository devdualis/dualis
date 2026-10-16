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
  /// **'Diário de Bem-Estar Integrado'**
  String get valueCard1Title;

  /// Body copy of the first onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Registre como você está no corpo e nas emoções em um único check-in diário de 1 minuto.'**
  String get valueCard1Body;

  /// Title of the second onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Seus Dados Protegidos'**
  String get valueCard2Title;

  /// Body copy of the second onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Seus registros de bem-estar ficam criptografados e sob seu controle, conforme a LGPD.'**
  String get valueCard2Body;

  /// Title of the third onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Conteúdos para Hábitos Saudáveis'**
  String get valueCard3Title;

  /// Body copy of the third onboarding carousel card
  ///
  /// In pt, this message translates to:
  /// **'Leituras curtas e gerais sobre sono, estresse, postura, hidratação e mais.'**
  String get valueCard3Body;

  /// LGPD Art. 11, I consent sentence (full text, C-05)
  ///
  /// In pt, this message translates to:
  /// **'Li e concordo com a Política de Privacidade e consinto, de forma específica e destacada, com o tratamento dos meus dados pessoais sensíveis de saúde para registrar e visualizar meu diário de bem-estar, nos termos do Art. 11, I da LGPD.'**
  String get lgpdConsentCheckbox;

  /// Title displayed when privacy veil obscures health data
  ///
  /// In pt, this message translates to:
  /// **'Dados de Saúde Protegidos'**
  String get privacyVeilTitle;

  /// Body copy displayed on the privacy veil
  ///
  /// In pt, this message translates to:
  /// **'Autentique-se com biometria ou senha para acessar seus registros.'**
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
  /// **'Precisa de ajuda agora?'**
  String get emergencyTitle;

  /// Subtitle describing immediate risk and advising urgent care
  ///
  /// In pt, this message translates to:
  /// **'Se você ou alguém perto de você estiver em perigo, ligue para a emergência. Não espere.'**
  String get emergencySubtitle;

  /// Button label to open maps looking for nearest emergency room
  ///
  /// In pt, this message translates to:
  /// **'Buscar pronto-socorro mais próximo'**
  String get emergencyFindHospital;

  /// Hint text advising patient to provide address clearly to emergency dispatchers
  ///
  /// In pt, this message translates to:
  /// **'Ao ligar, informe seu endereço com clareza e mantenha a calma.'**
  String get emergencyDispatcherHint;

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
  /// **'Registro emocional de hoje'**
  String get triageBannerEmotional;

  /// Banner text for physical triage vertical
  ///
  /// In pt, this message translates to:
  /// **'Registro físico de hoje'**
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
  /// **'Revise seu registro'**
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

  /// Opção de triagem: Normal / Me sinto bem
  ///
  /// In pt, this message translates to:
  /// **'Normal / Me sinto bem'**
  String get triageOptNormal;

  /// Botão de salvar triagem imediatamente como normal
  ///
  /// In pt, this message translates to:
  /// **'Concluir como Normal / Bem'**
  String get triageSaveNormal;

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
  /// **'Inquieto(a) / Agitado(a)'**
  String get triageOptAnsiosaAgitacao;

  /// Emotional dimension 2: Depressiva / Desânimo
  ///
  /// In pt, this message translates to:
  /// **'Pra baixo / Desanimado(a)'**
  String get triageOptDepressivaDesanimo;

  /// Emotional dimension 3: Estresse / Burnout
  ///
  /// In pt, this message translates to:
  /// **'Estressado(a) / Esgotado(a)'**
  String get triageOptEstresseBurnout;

  /// Emotional dimension 4: Somática (Psicossomática)
  ///
  /// In pt, this message translates to:
  /// **'Tensão no corpo'**
  String get triageOptSomatica;

  /// Emotional dimension 5: Sono (Insônia/Hipersônia)
  ///
  /// In pt, this message translates to:
  /// **'Sono ruim ou sono demais'**
  String get triageOptSono;

  /// Emotional dimension 6: Cognitiva / Foco
  ///
  /// In pt, this message translates to:
  /// **'Dificuldade de foco'**
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
  /// **'Revise seu registro'**
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
  /// **'Cabeça e pescoço'**
  String get triageOptCabecaPescoco;

  /// Physical system 2: Cardiovascular / Tórax
  ///
  /// In pt, this message translates to:
  /// **'Peito'**
  String get triageOptCardiovascularTorax;

  /// Physical system 3: Sistema Respiratório
  ///
  /// In pt, this message translates to:
  /// **'Respiração'**
  String get triageOptRespiratorio;

  /// Physical system 4: Gastrointestinal / Abdômen
  ///
  /// In pt, this message translates to:
  /// **'Barriga'**
  String get triageOptGastrointestinalAbdomen;

  /// Physical system 5: Coluna e Dor Dorsal
  ///
  /// In pt, this message translates to:
  /// **'Costas'**
  String get triageOptColunaDorDorsal;

  /// Physical system 6: Membros Superiores D/E
  ///
  /// In pt, this message translates to:
  /// **'Braços'**
  String get triageOptMembrosSuperiores;

  /// Physical system 7: Membros Inferiores D/E
  ///
  /// In pt, this message translates to:
  /// **'Pernas'**
  String get triageOptMembrosInferiores;

  /// Physical system 8: Sistema Neurológico
  ///
  /// In pt, this message translates to:
  /// **'Tontura / formigamento'**
  String get triageOptNeurologico;

  /// Physical system 9: Geniturinário / Pélvico
  ///
  /// In pt, this message translates to:
  /// **'Região íntima / urinária'**
  String get triageOptGeniturinarioPelvico;

  /// Physical system 10: Sistema Dermatológico
  ///
  /// In pt, this message translates to:
  /// **'Pele'**
  String get triageOptDermatologico;

  /// Physical system 11: Muscular / Geral Sistêmico
  ///
  /// In pt, this message translates to:
  /// **'Corpo todo / cansaço'**
  String get triageOptMuscularGeralSistemico;

  /// Physical system 12: Endócrino / Metabólico
  ///
  /// In pt, this message translates to:
  /// **'Sede, fome ou energia'**
  String get triageOptEndocrinoMetabolico;

  /// Question 2 physical
  ///
  /// In pt, this message translates to:
  /// **'Há quanto tempo você sente esse desconforto?'**
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
  /// **'Já faz bastante tempo'**
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
  /// **'Revise seu registro'**
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

  /// Outcome screen title (wellness)
  ///
  /// In pt, this message translates to:
  /// **'Resumo do seu registro'**
  String get outcomeScreenTitle;

  /// Subtitle of Screen 6 Triage Outcome
  ///
  /// In pt, this message translates to:
  /// **'Um retrato do que você registrou hoje'**
  String get outcomeScreenSubtitle;

  /// Intensity title
  ///
  /// In pt, this message translates to:
  /// **'Intensidade que você informou'**
  String get outcomeIntensityTitle;

  /// Intensity score description
  ///
  /// In pt, this message translates to:
  /// **'Sua própria nota de 1 a 5 para como se sentiu'**
  String get outcomeIntensityDescription;

  /// Articles section title
  ///
  /// In pt, this message translates to:
  /// **'Leituras sobre bem-estar'**
  String get outcomeArticlesTitle;

  /// Articles section subtitle
  ///
  /// In pt, this message translates to:
  /// **'Conteúdos educativos gerais. Não são orientação para o seu caso.'**
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
  /// **'Isso já apareceu antes?'**
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
  /// **'Vamos registrar como algo que voltou, para seu diário ficar organizado.'**
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
  /// **'Você está offline. Seus registros continuam funcionando normalmente.'**
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
  /// **'Sem registro'**
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
  /// **'Ler artigo'**
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
  /// **'Baixe uma cópia completa dos seus dados pessoais e registros de bem-estar em formato JSON conforme o Art. 18, V da LGPD.'**
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
  /// **'Visualize seu histórico de registros'**
  String get settingsDataHistorySubtitle;

  /// Title of the delete history item confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Descartar registro do histórico'**
  String get deleteHistoryItemTitle;

  /// Confirmation message when discarding a history entry
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza de que deseja descartar este registro do seu histórico? Esta ação é irreversível.'**
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
  /// **'Não foi possível carregar o histórico de registros no momento.'**
  String get errorLoadHistory;

  /// Article link unavailable
  ///
  /// In pt, this message translates to:
  /// **'Link do artigo não disponível.'**
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
  /// **'Meu Dia'**
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
  /// **'🌿 Check-in Diário Dualis ({time})'**
  String notifCheckinTitleAt(String time);

  /// Daily check-in reminder notification body
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não fez seu registro de hoje. Toque para fazer seu check-in!'**
  String get notifCheckinBody;

  /// Android notification channel name, daily check-in reminders
  ///
  /// In pt, this message translates to:
  /// **'Lembretes de Check-in Diário'**
  String get notifCheckinChannelName;

  /// Android notification channel description, daily check-in reminders
  ///
  /// In pt, this message translates to:
  /// **'Notificações a cada 2 horas para lembrar do seu check-in diário de bem-estar'**
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

  /// No description provided for @familySharingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhamento Familiar'**
  String get familySharingTitle;

  /// No description provided for @familySharingTabOutgoing.
  ///
  /// In pt, this message translates to:
  /// **'Quem acessa meus dados'**
  String get familySharingTabOutgoing;

  /// No description provided for @familySharingTabIncoming.
  ///
  /// In pt, this message translates to:
  /// **'Dados compartilhados comigo'**
  String get familySharingTabIncoming;

  /// No description provided for @familySharingUnavailableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recurso ainda não disponível'**
  String get familySharingUnavailableTitle;

  /// No description provided for @familySharingUnavailableBody.
  ///
  /// In pt, this message translates to:
  /// **'O compartilhamento familiar chegará em uma próxima versão do DualisCheckUp.'**
  String get familySharingUnavailableBody;

  /// No description provided for @familySharingInviteButton.
  ///
  /// In pt, this message translates to:
  /// **'Convidar Familiar ou Acompanhante'**
  String get familySharingInviteButton;

  /// No description provided for @familySharingEnterCodeButton.
  ///
  /// In pt, this message translates to:
  /// **'Possui um código de convite? Inserir e Aceitar'**
  String get familySharingEnterCodeButton;

  /// No description provided for @familySharingEmptyOutgoing.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém tem acesso aos seus dados no momento.'**
  String get familySharingEmptyOutgoing;

  /// No description provided for @familySharingEmptyIncoming.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum familiar compartilhou dados com você ainda.'**
  String get familySharingEmptyIncoming;

  /// No description provided for @familySharingScopeViewOnly.
  ///
  /// In pt, this message translates to:
  /// **'Somente Leitura'**
  String get familySharingScopeViewOnly;

  /// No description provided for @familySharingScopeCoManage.
  ///
  /// In pt, this message translates to:
  /// **'Co-gestão'**
  String get familySharingScopeCoManage;

  /// No description provided for @familySharingScopeViewOnlyOption.
  ///
  /// In pt, this message translates to:
  /// **'Somente Leitura (Recomendado)'**
  String get familySharingScopeViewOnlyOption;

  /// No description provided for @familySharingScopeCoManageOption.
  ///
  /// In pt, this message translates to:
  /// **'Co-gestão (Pode adicionar registros)'**
  String get familySharingScopeCoManageOption;

  /// No description provided for @familySharingActiveSince.
  ///
  /// In pt, this message translates to:
  /// **'Ativo desde {date}'**
  String familySharingActiveSince(String date);

  /// No description provided for @familySharingActive.
  ///
  /// In pt, this message translates to:
  /// **'Acesso ativo'**
  String get familySharingActive;

  /// No description provided for @familySharingPendingUntil.
  ///
  /// In pt, this message translates to:
  /// **'Código {code} · aguardando aceite até {date}'**
  String familySharingPendingUntil(String code, String date);

  /// No description provided for @familySharingExpired.
  ///
  /// In pt, this message translates to:
  /// **'Convite expirado'**
  String get familySharingExpired;

  /// No description provided for @familySharingRevokeButton.
  ///
  /// In pt, this message translates to:
  /// **'Revogar Acesso'**
  String get familySharingRevokeButton;

  /// No description provided for @familySharingRevokeConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Revogar acesso?'**
  String get familySharingRevokeConfirmTitle;

  /// No description provided for @familySharingRevokeConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza? O acesso será interrompido imediatamente.'**
  String get familySharingRevokeConfirmBody;

  /// No description provided for @familySharingCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get familySharingCancel;

  /// No description provided for @familySharingRevoked.
  ///
  /// In pt, this message translates to:
  /// **'Acesso revogado.'**
  String get familySharingRevoked;

  /// No description provided for @familySharingRevokeError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível revogar o acesso. Tente novamente.'**
  String get familySharingRevokeError;

  /// No description provided for @familySharingInviteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Convidar Familiar ou Acompanhante'**
  String get familySharingInviteTitle;

  /// No description provided for @familySharingInviteProfileLabel.
  ///
  /// In pt, this message translates to:
  /// **'Perfil a compartilhar'**
  String get familySharingInviteProfileLabel;

  /// No description provided for @familySharingInviteScopeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Permissão'**
  String get familySharingInviteScopeLabel;

  /// No description provided for @familySharingInviteGenerate.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Código'**
  String get familySharingInviteGenerate;

  /// No description provided for @familySharingInviteError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível gerar o convite. Tente novamente.'**
  String get familySharingInviteError;

  /// No description provided for @familySharingInviteCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Envie este código para o familiar. Ele expira em 72 horas.'**
  String get familySharingInviteCodeHint;

  /// No description provided for @familySharingInviteDeadline.
  ///
  /// In pt, this message translates to:
  /// **'Válido até {date}'**
  String familySharingInviteDeadline(String date);

  /// No description provided for @familySharingCopyCode.
  ///
  /// In pt, this message translates to:
  /// **'Copiar Código'**
  String get familySharingCopyCode;

  /// No description provided for @familySharingCodeCopied.
  ///
  /// In pt, this message translates to:
  /// **'Código copiado.'**
  String get familySharingCodeCopied;

  /// No description provided for @familySharingDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get familySharingDone;

  /// No description provided for @familySharingAcceptTitle.
  ///
  /// In pt, this message translates to:
  /// **'Inserir código de convite'**
  String get familySharingAcceptTitle;

  /// No description provided for @familySharingAcceptFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código de 6 caracteres'**
  String get familySharingAcceptFieldLabel;

  /// No description provided for @familySharingAcceptSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Aceitar Convite'**
  String get familySharingAcceptSubmit;

  /// No description provided for @familySharingAcceptError.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido ou expirado.'**
  String get familySharingAcceptError;

  /// No description provided for @familySharingAccepted.
  ///
  /// In pt, this message translates to:
  /// **'Convite aceito. O perfil já aparece na sua lista.'**
  String get familySharingAccepted;

  /// Title of the legal dependent registration bottom sheet
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar Dependente Legal'**
  String get addDependentTitle;

  /// No description provided for @addDependentNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo do Dependente'**
  String get addDependentNameLabel;

  /// No description provided for @addDependentDobLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data de Nascimento'**
  String get addDependentDobLabel;

  /// No description provided for @addDependentDobHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque para selecionar'**
  String get addDependentDobHint;

  /// No description provided for @addDependentDobPickerHelp.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a data de nascimento'**
  String get addDependentDobPickerHelp;

  /// No description provided for @addDependentDobInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma data de nascimento válida.'**
  String get addDependentDobInvalid;

  /// No description provided for @addDependentDobFuture.
  ///
  /// In pt, this message translates to:
  /// **'A data de nascimento não pode estar no futuro.'**
  String get addDependentDobFuture;

  /// No description provided for @addDependentRelationshipLabel.
  ///
  /// In pt, this message translates to:
  /// **'Grau de Parentesco / Representação'**
  String get addDependentRelationshipLabel;

  /// No description provided for @addDependentRelationshipHint.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o vínculo legal'**
  String get addDependentRelationshipHint;

  /// No description provided for @addDependentRelationshipParent.
  ///
  /// In pt, this message translates to:
  /// **'Filho(a) menor de idade (Poder Familiar)'**
  String get addDependentRelationshipParent;

  /// No description provided for @addDependentRelationshipCurator.
  ///
  /// In pt, this message translates to:
  /// **'Curador(a) de maior incapaz (Curatela)'**
  String get addDependentRelationshipCurator;

  /// No description provided for @addDependentRelationshipLegalGuardian.
  ///
  /// In pt, this message translates to:
  /// **'Tutor(a) legal de menor (Tutela)'**
  String get addDependentRelationshipLegalGuardian;

  /// No description provided for @addDependentLgpdArt14Consent.
  ///
  /// In pt, this message translates to:
  /// **'Declaro, sob as penas da lei, que sou pai, mãe ou representante legal deste dependente e autorizo expressamente a coleta e tratamento dos seus dados de bem-estar na plataforma DualisCheckUp, em estrita conformidade com o Artigo 14 da LGPD (Lei 13.709/2018).'**
  String get addDependentLgpdArt14Consent;

  /// No description provided for @addDependentSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar Dependente'**
  String get addDependentSubmit;

  /// No description provided for @addDependentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Dependente cadastrado com sucesso.'**
  String get addDependentSuccess;

  /// No description provided for @addDependentGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível cadastrar o dependente. Tente novamente.'**
  String get addDependentGenericError;

  /// Header title of the profile selection bottom sheet
  ///
  /// In pt, this message translates to:
  /// **'Perfis'**
  String get profileSwitcherSheetTitle;

  /// Section title for the primary user profile
  ///
  /// In pt, this message translates to:
  /// **'Meu Perfil'**
  String get profileSwitcherMyProfile;

  /// Section title for registered legal dependents
  ///
  /// In pt, this message translates to:
  /// **'Meus Dependentes (Permissão Legal)'**
  String get profileSwitcherDependents;

  /// Section title for shared family profiles
  ///
  /// In pt, this message translates to:
  /// **'Perfis Compartilhados (Opcional)'**
  String get profileSwitcherShared;

  /// Button to open legal dependent registration
  ///
  /// In pt, this message translates to:
  /// **'+ Adicionar Dependente (Legal)'**
  String get profileSwitcherAddDependent;

  /// Button to open family sharing management screen
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar Compartilhamento Familiar'**
  String get profileSwitcherManageSharing;

  /// Title of profile rename dialog
  ///
  /// In pt, this message translates to:
  /// **'Renomear Perfil'**
  String get profileSwitcherRenameTitle;

  /// Label for rename input field
  ///
  /// In pt, this message translates to:
  /// **'Nome do perfil'**
  String get profileSwitcherRenameLabel;

  /// Confirm button for profile rename
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get profileSwitcherRenameSave;

  /// Cancel button for profile rename
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get profileSwitcherRenameCancel;

  /// Title of profile delete confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Excluir Perfil?'**
  String get profileSwitcherDeleteTitle;

  /// Confirmation message when deleting a profile
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir o perfil \"{name}\"? Esta ação não pode ser desfeita.'**
  String profileSwitcherDeleteConfirm(String name);

  /// Confirm button to delete profile
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get profileSwitcherDeleteAction;

  /// Close button tooltip
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get profileSwitcherClose;

  /// Badge for dependent minor
  ///
  /// In pt, this message translates to:
  /// **'Menor de idade'**
  String get profileSwitcherBadgeMinor;

  /// Badge for dependent adult
  ///
  /// In pt, this message translates to:
  /// **'Maior sob tutela'**
  String get profileSwitcherBadgeAdult;

  /// Badge for view-only shared access
  ///
  /// In pt, this message translates to:
  /// **'Somente leitura'**
  String get profileSwitcherBadgeViewOnly;

  /// Badge for co-manage shared access
  ///
  /// In pt, this message translates to:
  /// **'Co-gestão'**
  String get profileSwitcherBadgeCoManage;

  /// Badge for primary profile
  ///
  /// In pt, this message translates to:
  /// **'Titular'**
  String get profileSwitcherBadgePrimary;

  /// Empty state for dependents section
  ///
  /// In pt, this message translates to:
  /// **'Nenhum dependente cadastrado.'**
  String get profileSwitcherNoDependents;

  /// Empty state for shared section
  ///
  /// In pt, this message translates to:
  /// **'Nenhum perfil compartilhado com você.'**
  String get profileSwitcherNoShared;

  /// Snackbar when renaming or deleting a profile fails
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a ação. Tente novamente.'**
  String get profileSwitcherActionError;

  /// Button to cancel a pending outgoing invite
  ///
  /// In pt, this message translates to:
  /// **'Cancelar Convite'**
  String get familySharingCancelInvite;

  /// Banner when viewing clinical data for a non-primary active profile
  ///
  /// In pt, this message translates to:
  /// **'Exibindo dados de {profileName}'**
  String activeProfileBannerDataOf(String profileName);

  /// Tap action on active profile banner to return to the signed-in user's primary profile
  ///
  /// In pt, this message translates to:
  /// **'Meu perfil'**
  String get activeProfileBannerSwitchToMine;

  /// Shown when the active shared profile grants VIEW_ONLY access
  ///
  /// In pt, this message translates to:
  /// **'Somente leitura'**
  String get activeProfileReadOnlyNote;

  /// Home card title when a dependent or shared profile is active
  ///
  /// In pt, this message translates to:
  /// **'Perfil de {profileName}'**
  String activeProfileCardTitle(String profileName);

  /// Search text sent to the maps app to find the nearest emergency room.
  ///
  /// In pt, this message translates to:
  /// **'pronto-socorro'**
  String get emergencyMapsQuery;

  /// No description provided for @safetyClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get safetyClose;

  /// Call button on the help resources screen.
  ///
  /// In pt, this message translates to:
  /// **'Ligar {name} ({number})'**
  String safetyCallLine(String name, String number);

  /// No description provided for @safetyKindEmergency.
  ///
  /// In pt, this message translates to:
  /// **'Emergência'**
  String get safetyKindEmergency;

  /// No description provided for @safetyKindAmbulance.
  ///
  /// In pt, this message translates to:
  /// **'Ambulância'**
  String get safetyKindAmbulance;

  /// No description provided for @safetyKindFire.
  ///
  /// In pt, this message translates to:
  /// **'Bombeiros'**
  String get safetyKindFire;

  /// No description provided for @safetyKindPolice.
  ///
  /// In pt, this message translates to:
  /// **'Polícia'**
  String get safetyKindPolice;

  /// No description provided for @safetyKindEmotionalSupport.
  ///
  /// In pt, this message translates to:
  /// **'Apoio emocional'**
  String get safetyKindEmotionalSupport;

  /// No description provided for @safetyKindHealthLine.
  ///
  /// In pt, this message translates to:
  /// **'Linha de saúde'**
  String get safetyKindHealthLine;

  /// No description provided for @safetyFree24h.
  ///
  /// In pt, this message translates to:
  /// **'24h, gratuito'**
  String get safetyFree24h;

  /// No description provided for @safetyWarningSignsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ligue {number} imediatamente se você ou alguém tiver:'**
  String safetyWarningSignsTitle(String number);

  /// No description provided for @safetyWarningSign1.
  ///
  /// In pt, this message translates to:
  /// **'dor ou pressão forte no peito'**
  String get safetyWarningSign1;

  /// No description provided for @safetyWarningSign2.
  ///
  /// In pt, this message translates to:
  /// **'falta de ar intensa'**
  String get safetyWarningSign2;

  /// No description provided for @safetyWarningSign3.
  ///
  /// In pt, this message translates to:
  /// **'rosto torto, fraqueza num lado do corpo ou fala enrolada'**
  String get safetyWarningSign3;

  /// No description provided for @safetyWarningSign4.
  ///
  /// In pt, this message translates to:
  /// **'a pior dor de cabeça da vida, de início súbito'**
  String get safetyWarningSign4;

  /// No description provided for @safetyWarningSign5.
  ///
  /// In pt, this message translates to:
  /// **'desmaio ou convulsão'**
  String get safetyWarningSign5;

  /// No description provided for @safetyWarningSign6.
  ///
  /// In pt, this message translates to:
  /// **'sangramento que não para'**
  String get safetyWarningSign6;

  /// No description provided for @safetyWarningSignsSource.
  ///
  /// In pt, this message translates to:
  /// **'Fonte: Ministério da Saúde / SAMU'**
  String get safetyWarningSignsSource;

  /// No description provided for @safetyCrisisWithLine.
  ///
  /// In pt, this message translates to:
  /// **'Se você está pensando em se machucar ou em tirar a própria vida, ligue {crisis} ou {emergency}.'**
  String safetyCrisisWithLine(String crisis, String emergency);

  /// No description provided for @safetyCrisisNoLine.
  ///
  /// In pt, this message translates to:
  /// **'Se você está pensando em se machucar ou em tirar a própria vida, ligue {emergency} ou procure a linha de apoio emocional do seu país.'**
  String safetyCrisisNoLine(String emergency);

  /// No description provided for @safetyLocalNumberHint.
  ///
  /// In pt, this message translates to:
  /// **'Se o {number} não funcionar onde você está, ligue para o número local de emergência.'**
  String safetyLocalNumberHint(String number);

  /// Same non-blocking notice for everyone. Never name a condition.
  ///
  /// In pt, this message translates to:
  /// **'Se isso for uma emergência, não use o app: ligue {number} agora.'**
  String safetyNoticeGeneral(String number);

  /// No description provided for @safetyNoticeOpenResources.
  ///
  /// In pt, this message translates to:
  /// **'Ver contatos de ajuda'**
  String get safetyNoticeOpenResources;

  /// Global button that opens the help resources screen.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda urgente'**
  String get urgentHelpButton;

  /// No description provided for @lgpdConsentPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Li e concordo com os '**
  String get lgpdConsentPrefix;

  /// No description provided for @lgpdConsentTermsLink.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get lgpdConsentTermsLink;

  /// No description provided for @lgpdConsentAnd.
  ///
  /// In pt, this message translates to:
  /// **' e a '**
  String get lgpdConsentAnd;

  /// No description provided for @lgpdConsentPrivacyLink.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get lgpdConsentPrivacyLink;

  /// No description provided for @lgpdConsentSuffix.
  ///
  /// In pt, this message translates to:
  /// **', e consinto, de forma específica e destacada, com o tratamento dos meus dados pessoais sensíveis de saúde para registrar e visualizar meu diário de bem-estar, nos termos do Art. 11, I da LGPD. '**
  String get lgpdConsentSuffix;

  /// No description provided for @lgpdConsentLearnMore.
  ///
  /// In pt, this message translates to:
  /// **'(Saiba mais)'**
  String get lgpdConsentLearnMore;

  /// No description provided for @lgpdConsentSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade e Termo de Consentimento (LGPD Art. 11, I)'**
  String get lgpdConsentSheetTitle;

  /// Canonical intended-use statement (plan §1.1)
  ///
  /// In pt, this message translates to:
  /// **'O DualisCheckUp é um aplicativo de bem-estar e autoconhecimento. Ele ajuda você a registrar diariamente como se sente física e emocionalmente, acompanhar hábitos como hidratação e sono, visualizar seus próprios registros ao longo do tempo e acessar conteúdos educativos gerais sobre hábitos saudáveis. O DualisCheckUp não é um dispositivo médico: não avalia, não classifica nem interpreta sintomas, não indica nível de urgência, não faz diagnóstico, não recomenda tratamento e não substitui um profissional de saúde. Em caso de emergência, ligue 192 (SAMU). Se você estiver em sofrimento emocional, ligue 188 (CVV).'**
  String get lgpdConsentSheetBody;

  /// No description provided for @lgpdConsentSheetBasesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bases normativas:'**
  String get lgpdConsentSheetBasesTitle;

  /// No description provided for @lgpdConsentSheetBases.
  ///
  /// In pt, this message translates to:
  /// **'• Lei nº 13.709/2018 (LGPD): Art. 7 e Art. 11 (tratamento de dados pessoais e de dados sensíveis de saúde), Art. 14 (dados de crianças e adolescentes) e Art. 18 (direitos do titular).\n• Código de Defesa do Consumidor (CDC): Art. 49 - Direito de Arrependimento em 7 dias.'**
  String get lgpdConsentSheetBases;

  /// No description provided for @lgpdConsentViewTerms.
  ///
  /// In pt, this message translates to:
  /// **'Ver Termos de Uso'**
  String get lgpdConsentViewTerms;

  /// No description provided for @lgpdConsentViewPolicy.
  ///
  /// In pt, this message translates to:
  /// **'Ver Política Completa'**
  String get lgpdConsentViewPolicy;

  /// No description provided for @termsAppBarTitle.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso do SaaS'**
  String get termsAppBarTitle;

  /// No description provided for @termsHeaderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Termos e Condições de Uso'**
  String get termsHeaderTitle;

  /// No description provided for @termsVersionLine.
  ///
  /// In pt, this message translates to:
  /// **'Versão 2026.2 • Atualizado em 16/10/2026'**
  String get termsVersionLine;

  /// No description provided for @termsIntro.
  ///
  /// In pt, this message translates to:
  /// **'Contrato de prestação de serviços de software em nuvem (SaaS) celebrado entre o Usuário e a DualisCheckUp Saúde e Tecnologia Ltda., inscrita no CNPJ sob o nº 48.291.834/0001-92, com sede em São Paulo/SP, Brasil.'**
  String get termsIntro;

  /// No description provided for @termsSection1Title.
  ///
  /// In pt, this message translates to:
  /// **'1. Aceitação e Capacidade Civil'**
  String get termsSection1Title;

  /// No description provided for @termsSection1Body.
  ///
  /// In pt, this message translates to:
  /// **'Ao cadastrar-se ou utilizar o DualisCheckUp, você declara possuir capacidade civil plena (maior de 18 anos ou emancipado) e manifesta concordância integral com estes Termos de Uso e com nossa Política de Privacidade.'**
  String get termsSection1Body;

  /// No description provided for @termsSection2Title.
  ///
  /// In pt, this message translates to:
  /// **'2. Natureza do Serviço'**
  String get termsSection2Title;

  /// Canonical intended-use statement (plan §1.1)
  ///
  /// In pt, this message translates to:
  /// **'O DualisCheckUp é um aplicativo de bem-estar e autoconhecimento. Ele ajuda você a registrar diariamente como se sente física e emocionalmente, acompanhar hábitos como hidratação e sono, visualizar seus próprios registros ao longo do tempo e acessar conteúdos educativos gerais sobre hábitos saudáveis. O DualisCheckUp não é um dispositivo médico: não avalia, não classifica nem interpreta sintomas, não indica nível de urgência, não faz diagnóstico, não recomenda tratamento e não substitui um profissional de saúde. Em caso de emergência, ligue 192 (SAMU). Se você estiver em sofrimento emocional, ligue 188 (CVV).'**
  String get termsSection2Body;

  /// No description provided for @termsSection2Bullet1.
  ///
  /// In pt, this message translates to:
  /// **'Não avalia sintomas, não indica urgência, não diagnostica e não recomenda tratamento.'**
  String get termsSection2Bullet1;

  /// No description provided for @termsSection2Bullet2.
  ///
  /// In pt, this message translates to:
  /// **'As intensidades e demais informações exibidas são as que você mesmo registrou.'**
  String get termsSection2Bullet2;

  /// No description provided for @termsSection2Bullet3.
  ///
  /// In pt, this message translates to:
  /// **'Em emergência, ligue 192 (SAMU) ou 188 (CVV).'**
  String get termsSection2Bullet3;

  /// No description provided for @termsSection3Title.
  ///
  /// In pt, this message translates to:
  /// **'3. Planos SaaS, Cobrança e Reembolso'**
  String get termsSection3Title;

  /// No description provided for @termsSection3Body.
  ///
  /// In pt, this message translates to:
  /// **'Recursos adicionais podem ser oferecidos em planos com renovação automática periódica, processados por intermediadores de pagamento terceiros:'**
  String get termsSection3Body;

  /// No description provided for @termsSection3Bullet1.
  ///
  /// In pt, this message translates to:
  /// **'Cancelamento Facilitado: Você pode cancelar sua assinatura a qualquer momento no app com um toque, sem fidelidade ou taxas de cancelamento.'**
  String get termsSection3Bullet1;

  /// No description provided for @termsSection3Bullet2.
  ///
  /// In pt, this message translates to:
  /// **'Direito de Arrependimento (CDC Art. 49): Garantia de reembolso integral em até 7 (sete) dias corridos a partir da contratação inicial.'**
  String get termsSection3Bullet2;

  /// No description provided for @termsSection3Bullet3.
  ///
  /// In pt, this message translates to:
  /// **'Acesso Contínuo: O cancelamento interrompe faturas subsequentes e preserva seu acesso até o término do ciclo mensal contratado.'**
  String get termsSection3Bullet3;

  /// No description provided for @termsSection4Title.
  ///
  /// In pt, this message translates to:
  /// **'4. Propriedade Intelectual'**
  String get termsSection4Title;

  /// No description provided for @termsSection4Body.
  ///
  /// In pt, this message translates to:
  /// **'Todos os direitos de propriedade intelectual sobre software, conteúdos, marcas e interfaces pertencem com exclusividade à DualisCheckUp Saúde e Tecnologia Ltda. É estritamente vedada a reprodução, engenharia reversa ou mineração de dados.'**
  String get termsSection4Body;

  /// No description provided for @termsSection5Title.
  ///
  /// In pt, this message translates to:
  /// **'5. Suspensão por Violação de Segurança'**
  String get termsSection5Title;

  /// No description provided for @termsSection5Body.
  ///
  /// In pt, this message translates to:
  /// **'Contas que executarem tentativas de invasão, ataques de força bruta, testes de penetração não autorizados ou submissão de dados fraudulentos serão imediatamente bloqueadas, com encaminhamento às autoridades competentes.'**
  String get termsSection5Body;

  /// No description provided for @termsSection6Title.
  ///
  /// In pt, this message translates to:
  /// **'6. Foro e Contato Jurídico'**
  String get termsSection6Title;

  /// No description provided for @termsSection6Body.
  ///
  /// In pt, this message translates to:
  /// **'Estes termos são regidos pelas leis brasileiras. Fica eleito o Foro da Comarca de São Paulo/SP como único competente para dirimir litígios decorrentes deste contrato.\n\nPara dúvidas ou notificações legais: legal@dualischeckup.com.'**
  String get termsSection6Body;

  /// No description provided for @privacyPolicyAppBarTitle.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade (LGPD)'**
  String get privacyPolicyAppBarTitle;

  /// No description provided for @privacyPolicyHeaderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade & Proteção de Dados'**
  String get privacyPolicyHeaderTitle;

  /// No description provided for @privacyPolicyHeaderSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/2018)'**
  String get privacyPolicyHeaderSubtitle;

  /// No description provided for @privacyPolicyIntro.
  ///
  /// In pt, this message translates to:
  /// **'A sua privacidade e a confidencialidade dos seus dados de saúde são a nossa prioridade absoluta. Esta política descreve como tratamos, protegemos e permitimos que você controle integralmente suas informações.'**
  String get privacyPolicyIntro;

  /// No description provided for @privacyPolicyDpoLine.
  ///
  /// In pt, this message translates to:
  /// **'Encarregado de Dados (DPO): dpo@dualischeckup.com'**
  String get privacyPolicyDpoLine;

  /// No description provided for @privacyPolicySection1Title.
  ///
  /// In pt, this message translates to:
  /// **'1. Dados Pessoais e Sensíveis Coletados'**
  String get privacyPolicySection1Title;

  /// No description provided for @privacyPolicySection1Body.
  ///
  /// In pt, this message translates to:
  /// **'Nos termos do Artigo 11 da LGPD, o tratamento de dados pessoais sensíveis de saúde é realizado com o seu consentimento específico e destacado (Art. 11, I):'**
  String get privacyPolicySection1Body;

  /// No description provided for @privacyPolicySection1Bullet1.
  ///
  /// In pt, this message translates to:
  /// **'Dados de Identificação: Nome completo, endereço de e-mail e data de nascimento.'**
  String get privacyPolicySection1Bullet1;

  /// No description provided for @privacyPolicySection1Bullet2.
  ///
  /// In pt, this message translates to:
  /// **'Dados de Perfil: Sexo biológico e consumo de água, usados para ajustar suas metas de hidratação.'**
  String get privacyPolicySection1Bullet2;

  /// No description provided for @privacyPolicySection1Bullet3.
  ///
  /// In pt, this message translates to:
  /// **'Diário de Bem-Estar: Anotações sobre como você se sente física e emocionalmente e a intensidade informada por você.'**
  String get privacyPolicySection1Bullet3;

  /// No description provided for @privacyPolicySection1Bullet4.
  ///
  /// In pt, this message translates to:
  /// **'Dados de Acesso Técnico: Endereço IP mascarado, registros criptográficos de sessão e tokens de autenticação transitórios.'**
  String get privacyPolicySection1Bullet4;

  /// No description provided for @privacyPolicySection2Title.
  ///
  /// In pt, this message translates to:
  /// **'2. Finalidades e Proibição de Venda de Dados'**
  String get privacyPolicySection2Title;

  /// No description provided for @privacyPolicySection2Body.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados de saúde são tratados somente para:'**
  String get privacyPolicySection2Body;

  /// No description provided for @privacyPolicySection2Bullet1.
  ///
  /// In pt, this message translates to:
  /// **'Registro e visualização do seu diário de bem-estar.'**
  String get privacyPolicySection2Bullet1;

  /// No description provided for @privacyPolicySection2Bullet2.
  ///
  /// In pt, this message translates to:
  /// **'Organização automática das suas anotações por área do corpo ou emoção (com auxílio de IA, sem avaliação de saúde).'**
  String get privacyPolicySection2Bullet2;

  /// No description provided for @privacyPolicySection2Bullet3.
  ///
  /// In pt, this message translates to:
  /// **'Consistência do histórico.'**
  String get privacyPolicySection2Bullet3;

  /// No description provided for @privacyPolicySection2Bullet4.
  ///
  /// In pt, this message translates to:
  /// **'Compromisso Ético: É expressamente PROIBIDA a venda, comercialização ou cessão onerosa dos seus dados para corretoras de seguros, anunciantes ou terceiros.'**
  String get privacyPolicySection2Bullet4;

  /// No description provided for @privacyPolicySection3Title.
  ///
  /// In pt, this message translates to:
  /// **'3. Operadores e Transferência Internacional'**
  String get privacyPolicySection3Title;

  /// No description provided for @privacyPolicySection3Body.
  ///
  /// In pt, this message translates to:
  /// **'Para prestar o serviço, compartilhamos dados apenas com:'**
  String get privacyPolicySection3Body;

  /// No description provided for @privacyPolicySection3Bullet1.
  ///
  /// In pt, this message translates to:
  /// **'Google LLC (API Gemini): O texto das suas anotações é enviado à API Gemini do Google para organizá-las automaticamente. A IA não avalia a sua saúde.'**
  String get privacyPolicySection3Bullet1;

  /// No description provided for @privacyPolicySection3Bullet2.
  ///
  /// In pt, this message translates to:
  /// **'Transferência Internacional: Esse processamento pode ocorrer em servidores localizados fora do Brasil (LGPD Art. 33).'**
  String get privacyPolicySection3Bullet2;

  /// No description provided for @privacyPolicySection3Bullet3.
  ///
  /// In pt, this message translates to:
  /// **'Infraestrutura em Nuvem: Provedores de hospedagem e banco de dados, sujeitos a obrigações de confidencialidade e segurança.'**
  String get privacyPolicySection3Bullet3;

  /// No description provided for @privacyPolicySection4Title.
  ///
  /// In pt, this message translates to:
  /// **'4. Pagamentos'**
  String get privacyPolicySection4Title;

  /// No description provided for @privacyPolicySection4Body.
  ///
  /// In pt, this message translates to:
  /// **'Quando houver planos pagos, os dados de cartão ficam isolados dos nossos servidores:'**
  String get privacyPolicySection4Body;

  /// No description provided for @privacyPolicySection4Bullet1.
  ///
  /// In pt, this message translates to:
  /// **'Processamento por Terceiros: Os pagamentos são intermediados por gateways de pagamento especializados.'**
  String get privacyPolicySection4Bullet1;

  /// No description provided for @privacyPolicySection4Bullet2.
  ///
  /// In pt, this message translates to:
  /// **'Zero Armazenamento: Os servidores da DualisCheckUp NÃO recebem, não processam e não salvam números de cartão de crédito ou códigos CVV.'**
  String get privacyPolicySection4Bullet2;

  /// No description provided for @privacyPolicySection5Title.
  ///
  /// In pt, this message translates to:
  /// **'5. Seus Direitos como Titular (Art. 18 da LGPD)'**
  String get privacyPolicySection5Title;

  /// No description provided for @privacyPolicySection5Body.
  ///
  /// In pt, this message translates to:
  /// **'Você pode exercer seus direitos legais diretamente pelo aplicativo de forma instantânea:'**
  String get privacyPolicySection5Body;

  /// No description provided for @privacyPolicySection5Bullet1.
  ///
  /// In pt, this message translates to:
  /// **'Exportação de Dados: Baixe todos os seus registros em formato estruturado (JSON) com um clique na Central de Privacidade.'**
  String get privacyPolicySection5Bullet1;

  /// No description provided for @privacyPolicySection5Bullet2.
  ///
  /// In pt, this message translates to:
  /// **'Exclusão Definitiva: Solicite a exclusão irrevogável da sua conta e de todos os dados associados.'**
  String get privacyPolicySection5Bullet2;

  /// No description provided for @privacyPolicySection5Bullet3.
  ///
  /// In pt, this message translates to:
  /// **'Revogação do Consentimento: Encerre o uso e retire a autorização a qualquer momento.'**
  String get privacyPolicySection5Bullet3;

  /// No description provided for @privacyPolicySection6Title.
  ///
  /// In pt, this message translates to:
  /// **'6. Segurança da Informação & Resposta a Incidentes'**
  String get privacyPolicySection6Title;

  /// No description provided for @privacyPolicySection6Body.
  ///
  /// In pt, this message translates to:
  /// **'Medidas técnicas de ponta a ponta protegem seus registros:'**
  String get privacyPolicySection6Body;

  /// No description provided for @privacyPolicySection6Bullet1.
  ///
  /// In pt, this message translates to:
  /// **'Isolamento RLS: Cada consulta ao banco PostgreSQL é blindada pela política de Row-Level Security com chave de usuário isolada.'**
  String get privacyPolicySection6Bullet1;

  /// No description provided for @privacyPolicySection6Bullet2.
  ///
  /// In pt, this message translates to:
  /// **'Criptografia Forte: Conexões TLS 1.3 obrigatórias e senhas protegidas pelo algoritmo Argon2id.'**
  String get privacyPolicySection6Bullet2;

  /// No description provided for @privacyPolicySection6Bullet3.
  ///
  /// In pt, this message translates to:
  /// **'Plano de Notificação em até 72h: Protocolo de comunicação imediata à Autoridade Nacional de Proteção de Dados (ANPD) e aos usuários em qualquer evento relevante de segurança (LGPD Art. 48).'**
  String get privacyPolicySection6Bullet3;

  /// No description provided for @privacyPolicySection7Title.
  ///
  /// In pt, this message translates to:
  /// **'7. Notificações, Comunicações e Opt-Out'**
  String get privacyPolicySection7Title;

  /// No description provided for @privacyPolicySection7Body.
  ///
  /// In pt, this message translates to:
  /// **'Respeitamos a sua tranquilidade e atenção:'**
  String get privacyPolicySection7Body;

  /// No description provided for @privacyPolicySection7Bullet1.
  ///
  /// In pt, this message translates to:
  /// **'Você tem liberdade total para desativar lembretes de hidratação ou notificações de dicas de bem-estar na aba de Configurações a qualquer momento.'**
  String get privacyPolicySection7Bullet1;

  /// No description provided for @privacyPolicySection7Bullet2.
  ///
  /// In pt, this message translates to:
  /// **'Avisos de segurança e recuperação de conta são de natureza estritamente transacional e protegidos.'**
  String get privacyPolicySection7Bullet2;

  /// No description provided for @privacyPolicyCtaQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Deseja exportar seus dados ou gerenciar sua conta agora?'**
  String get privacyPolicyCtaQuestion;

  /// No description provided for @privacyPolicyCtaButton.
  ///
  /// In pt, this message translates to:
  /// **'Ir para a Central de Privacidade'**
  String get privacyPolicyCtaButton;

  /// No description provided for @onboardingIntendedUseNote.
  ///
  /// In pt, this message translates to:
  /// **'O DualisCheckUp é um aplicativo de bem-estar e autoconhecimento. Não é um dispositivo médico e não substitui um profissional de saúde.'**
  String get onboardingIntendedUseNote;

  /// No description provided for @privacyVeilBiometricReason.
  ///
  /// In pt, this message translates to:
  /// **'Autentique-se para acessar seus registros.'**
  String get privacyVeilBiometricReason;

  /// No description provided for @privacyVeilUnlock.
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear'**
  String get privacyVeilUnlock;

  /// No description provided for @privacyVeilUnlockManually.
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear manualmente'**
  String get privacyVeilUnlockManually;

  /// No description provided for @wizardNarrativeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição opcional (em suas palavras)'**
  String get wizardNarrativeLabel;

  /// No description provided for @wizardNarrativeHint.
  ///
  /// In pt, this message translates to:
  /// **'Se quiser, escreva com suas palavras como você está.'**
  String get wizardNarrativeHint;

  /// No description provided for @deleteHistoryItemIntensity.
  ///
  /// In pt, this message translates to:
  /// **'Intensidade informada: {value}/5'**
  String deleteHistoryItemIntensity(int value);

  /// No description provided for @bodyMapRegionHeadNeck.
  ///
  /// In pt, this message translates to:
  /// **'Cabeça e pescoço'**
  String get bodyMapRegionHeadNeck;

  /// No description provided for @bodyMapRegionHeadNeckHint.
  ///
  /// In pt, this message translates to:
  /// **'Dor de cabeça, dor ou rigidez no pescoço'**
  String get bodyMapRegionHeadNeckHint;

  /// No description provided for @bodyMapRegionDizziness.
  ///
  /// In pt, this message translates to:
  /// **'Tontura / formigamento'**
  String get bodyMapRegionDizziness;

  /// No description provided for @bodyMapRegionDizzinessHint.
  ///
  /// In pt, this message translates to:
  /// **'Tontura, sensação de desequilíbrio, formigamento'**
  String get bodyMapRegionDizzinessHint;

  /// No description provided for @bodyMapRegionBack.
  ///
  /// In pt, this message translates to:
  /// **'Costas'**
  String get bodyMapRegionBack;

  /// No description provided for @bodyMapRegionBackHint.
  ///
  /// In pt, this message translates to:
  /// **'Dor nas costas, na coluna ou na lombar'**
  String get bodyMapRegionBackHint;

  /// No description provided for @bodyMapRegionBreathing.
  ///
  /// In pt, this message translates to:
  /// **'Respiração'**
  String get bodyMapRegionBreathing;

  /// No description provided for @bodyMapRegionBreathingHint.
  ///
  /// In pt, this message translates to:
  /// **'Falta de ar, tosse'**
  String get bodyMapRegionBreathingHint;

  /// No description provided for @bodyMapRegionChest.
  ///
  /// In pt, this message translates to:
  /// **'Peito'**
  String get bodyMapRegionChest;

  /// No description provided for @bodyMapRegionChestHint.
  ///
  /// In pt, this message translates to:
  /// **'Aperto ou desconforto no peito, coração acelerado'**
  String get bodyMapRegionChestHint;

  /// No description provided for @bodyMapRegionBelly.
  ///
  /// In pt, this message translates to:
  /// **'Barriga'**
  String get bodyMapRegionBelly;

  /// No description provided for @bodyMapRegionBellyHint.
  ///
  /// In pt, this message translates to:
  /// **'Desconforto na barriga, cólica, azia'**
  String get bodyMapRegionBellyHint;

  /// No description provided for @bodyMapRegionPelvic.
  ///
  /// In pt, this message translates to:
  /// **'Região íntima / urinária'**
  String get bodyMapRegionPelvic;

  /// No description provided for @bodyMapRegionPelvicHint.
  ///
  /// In pt, this message translates to:
  /// **'Desconforto na região pélvica ou ao urinar'**
  String get bodyMapRegionPelvicHint;

  /// No description provided for @bodyMapRegionRightArm.
  ///
  /// In pt, this message translates to:
  /// **'Braço direito'**
  String get bodyMapRegionRightArm;

  /// No description provided for @bodyMapRegionRightArmHint.
  ///
  /// In pt, this message translates to:
  /// **'Braço, ombro, cotovelo ou punho direito'**
  String get bodyMapRegionRightArmHint;

  /// No description provided for @bodyMapRegionLeftArm.
  ///
  /// In pt, this message translates to:
  /// **'Braço esquerdo'**
  String get bodyMapRegionLeftArm;

  /// No description provided for @bodyMapRegionLeftArmHint.
  ///
  /// In pt, this message translates to:
  /// **'Braço, ombro, cotovelo ou punho esquerdo'**
  String get bodyMapRegionLeftArmHint;

  /// No description provided for @bodyMapRegionRightLeg.
  ///
  /// In pt, this message translates to:
  /// **'Perna direita'**
  String get bodyMapRegionRightLeg;

  /// No description provided for @bodyMapRegionRightLegHint.
  ///
  /// In pt, this message translates to:
  /// **'Quadril, coxa, joelho ou tornozelo direito'**
  String get bodyMapRegionRightLegHint;

  /// No description provided for @bodyMapRegionLeftLeg.
  ///
  /// In pt, this message translates to:
  /// **'Perna esquerda'**
  String get bodyMapRegionLeftLeg;

  /// No description provided for @bodyMapRegionLeftLegHint.
  ///
  /// In pt, this message translates to:
  /// **'Quadril, coxa, joelho ou tornozelo esquerdo'**
  String get bodyMapRegionLeftLegHint;

  /// No description provided for @bodyMapRegionSkin.
  ///
  /// In pt, this message translates to:
  /// **'Pele'**
  String get bodyMapRegionSkin;

  /// No description provided for @bodyMapRegionSkinHint.
  ///
  /// In pt, this message translates to:
  /// **'Coceira, manchas'**
  String get bodyMapRegionSkinHint;

  /// No description provided for @bodyMapRegionWholeBody.
  ///
  /// In pt, this message translates to:
  /// **'Corpo todo / cansaço'**
  String get bodyMapRegionWholeBody;

  /// No description provided for @bodyMapRegionWholeBodyHint.
  ///
  /// In pt, this message translates to:
  /// **'Dor no corpo todo, cansaço'**
  String get bodyMapRegionWholeBodyHint;

  /// No description provided for @bodyMapRegionEnergy.
  ///
  /// In pt, this message translates to:
  /// **'Sede, fome ou energia'**
  String get bodyMapRegionEnergy;

  /// No description provided for @bodyMapRegionEnergyHint.
  ///
  /// In pt, this message translates to:
  /// **'Mudanças de energia, sede ou fome'**
  String get bodyMapRegionEnergyHint;

  /// No description provided for @bodyMapGroupHead.
  ///
  /// In pt, this message translates to:
  /// **'Cabeça'**
  String get bodyMapGroupHead;

  /// No description provided for @bodyMapGroupTrunk.
  ///
  /// In pt, this message translates to:
  /// **'Tronco'**
  String get bodyMapGroupTrunk;

  /// No description provided for @bodyMapGroupLimbs.
  ///
  /// In pt, this message translates to:
  /// **'Braços e pernas'**
  String get bodyMapGroupLimbs;

  /// No description provided for @bodyMapGroupWholeBody.
  ///
  /// In pt, this message translates to:
  /// **'Corpo todo e pele'**
  String get bodyMapGroupWholeBody;

  /// No description provided for @bodyMapViewMap.
  ///
  /// In pt, this message translates to:
  /// **'Mapa do corpo'**
  String get bodyMapViewMap;

  /// No description provided for @bodyMapViewAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas as áreas'**
  String get bodyMapViewAll;

  /// No description provided for @bodyMapShortSkin.
  ///
  /// In pt, this message translates to:
  /// **'Pele'**
  String get bodyMapShortSkin;

  /// No description provided for @bodyMapShortWholeBody.
  ///
  /// In pt, this message translates to:
  /// **'Corpo todo'**
  String get bodyMapShortWholeBody;

  /// No description provided for @bodyMapShortEnergy.
  ///
  /// In pt, this message translates to:
  /// **'Energia'**
  String get bodyMapShortEnergy;

  /// No description provided for @bodyMapMaxIntensity.
  ///
  /// In pt, this message translates to:
  /// **'Maior intensidade informada nos últimos 14 dias: {value}/5'**
  String bodyMapMaxIntensity(int value);

  /// No description provided for @bodyMapNoEntriesThisSide.
  ///
  /// In pt, this message translates to:
  /// **'Sem registros deste lado nos últimos 14 dias.\n({otherArea}: intensidade informada {value}/5)'**
  String bodyMapNoEntriesThisSide(String otherArea, int value);

  /// No description provided for @bodyMapViewOtherSide.
  ///
  /// In pt, this message translates to:
  /// **'Ver {area}'**
  String bodyMapViewOtherSide(String area);

  /// No description provided for @bodyMapNoEntries14Days.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro nos últimos 14 dias'**
  String get bodyMapNoEntries14Days;

  /// No description provided for @settingsChangePhotoSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha como deseja selecionar sua foto de perfil.'**
  String get settingsChangePhotoSubtitle;

  /// No description provided for @settingsPhotoCamera.
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get settingsPhotoCamera;

  /// No description provided for @settingsPhotoCameraSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Tirar uma nova foto'**
  String get settingsPhotoCameraSubtitle;

  /// No description provided for @settingsPhotoGallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get settingsPhotoGallery;

  /// No description provided for @settingsPhotoGallerySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da biblioteca de fotos'**
  String get settingsPhotoGallerySubtitle;

  /// No description provided for @settingsPhotoPresets.
  ///
  /// In pt, this message translates to:
  /// **'Avatares'**
  String get settingsPhotoPresets;

  /// No description provided for @settingsPhotoPresetsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolher um ícone ilustrado de autocuidado'**
  String get settingsPhotoPresetsSubtitle;

  /// No description provided for @settingsLogoutConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente encerrar sua sessão? Seus dados permanecem seguros e criptografados.'**
  String get settingsLogoutConfirmBody;

  /// No description provided for @settingsLogoutConfirmAction.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get settingsLogoutConfirmAction;

  /// No description provided for @settingsNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Seu nome completo'**
  String get settingsNameHint;

  /// No description provided for @settingsRemindersTile.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes e Hidratação'**
  String get settingsRemindersTile;

  /// No description provided for @settingsRemindersSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Horários de notificações, alarmes e teste com app fechado'**
  String get settingsRemindersSubtitle;

  /// No description provided for @settingsTermsTile.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get settingsTermsTile;

  /// No description provided for @settingsTermsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Condições de uso, planos, cancelamento e reembolso'**
  String get settingsTermsSubtitle;

  /// No description provided for @settingsPrivacyPolicyTile.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade (LGPD)'**
  String get settingsPrivacyPolicyTile;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Tratamento de dados, direitos do titular e DPO'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsCommunicationsSection.
  ///
  /// In pt, this message translates to:
  /// **'Comunicações e Notificações'**
  String get settingsCommunicationsSection;

  /// No description provided for @settingsEducationalTipsTile.
  ///
  /// In pt, this message translates to:
  /// **'Dicas de Bem-Estar e Notificações Educativas'**
  String get settingsEducationalTipsTile;

  /// No description provided for @settingsEducationalTipsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Dicas gerais de bem-estar. Você pode desativar (opt-out) a qualquer momento.'**
  String get settingsEducationalTipsSubtitle;

  /// No description provided for @settingsEducationalTipsOn.
  ///
  /// In pt, this message translates to:
  /// **'Notificações educativas ativadas.'**
  String get settingsEducationalTipsOn;

  /// No description provided for @settingsEducationalTipsOff.
  ///
  /// In pt, this message translates to:
  /// **'Opt-out confirmado: Notificações educativas desativadas.'**
  String get settingsEducationalTipsOff;

  /// No description provided for @settingsOperatorInfo.
  ///
  /// In pt, this message translates to:
  /// **'Operado por DualisCheckUp Saúde e Tecnologia Ltda.\nCNPJ 48.291.834/0001-92 • São Paulo - SP, Brasil\nDPO: dpo@dualischeckup.com'**
  String get settingsOperatorInfo;

  /// No description provided for @avatarSelectorSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um ícone de autocuidado para personalizar seu perfil.'**
  String get avatarSelectorSubtitle;

  /// No description provided for @avatarConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Avatar'**
  String get avatarConfirm;

  /// No description provided for @avatarPresetSelfCare.
  ///
  /// In pt, this message translates to:
  /// **'Autocuidado'**
  String get avatarPresetSelfCare;

  /// No description provided for @avatarPresetBalance.
  ///
  /// In pt, this message translates to:
  /// **'Equilíbrio'**
  String get avatarPresetBalance;

  /// No description provided for @avatarPresetProtection.
  ///
  /// In pt, this message translates to:
  /// **'Proteção'**
  String get avatarPresetProtection;

  /// No description provided for @avatarPresetVitality.
  ///
  /// In pt, this message translates to:
  /// **'Vitalidade'**
  String get avatarPresetVitality;

  /// No description provided for @avatarPresetWellbeing.
  ///
  /// In pt, this message translates to:
  /// **'Bem-estar'**
  String get avatarPresetWellbeing;

  /// No description provided for @avatarPresetEnergy.
  ///
  /// In pt, this message translates to:
  /// **'Energia'**
  String get avatarPresetEnergy;

  /// No description provided for @avatarPresetFocus.
  ///
  /// In pt, this message translates to:
  /// **'Foco Mental'**
  String get avatarPresetFocus;

  /// No description provided for @avatarPresetRadiant.
  ///
  /// In pt, this message translates to:
  /// **'Radiante'**
  String get avatarPresetRadiant;

  /// No description provided for @loginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar no DualisCheckUp'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Acesse seu diário de bem-estar com segurança.'**
  String get loginSubtitle;

  /// No description provided for @authEmailHint.
  ///
  /// In pt, this message translates to:
  /// **'seu.email@exemplo.com'**
  String get authEmailHint;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Senha é obrigatória.'**
  String get loginPasswordRequired;

  /// No description provided for @loginNoAccountPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não possui conta? '**
  String get loginNoAccountPrompt;

  /// No description provided for @registerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar sua conta'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Informe alguns dados para personalizar sua experiência.'**
  String get registerSubtitle;

  /// No description provided for @registerNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Carlos Silva'**
  String get registerNameHint;

  /// No description provided for @registerDobHint.
  ///
  /// In pt, this message translates to:
  /// **'DD/MM/AAAA'**
  String get registerDobHint;

  /// No description provided for @registerDobHelper.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 15/08/1990 ou selecione pelo calendário.'**
  String get registerDobHelper;

  /// No description provided for @registerDobPickerHelp.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a data de nascimento'**
  String get registerDobPickerHelp;

  /// No description provided for @registerDobPickerConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get registerDobPickerConfirm;

  /// No description provided for @registerPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get registerPasswordHint;

  /// No description provided for @registerPasswordHelper.
  ///
  /// In pt, this message translates to:
  /// **'Use 8+ caracteres com maiúscula, número e símbolo.'**
  String get registerPasswordHelper;

  /// No description provided for @registerHydrationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes e Controle de Hidratação'**
  String get registerHydrationTitle;

  /// No description provided for @registerHydrationSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Configure seus hábitos de hidratação'**
  String get registerHydrationSubtitle;

  /// No description provided for @registerWaterReminderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alerta para tomar água a cada 2h'**
  String get registerWaterReminderTitle;

  /// No description provided for @registerWaterReminderSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Horários pares: 8h, 10h, 12h, 14h, 16h, 18h e 20h'**
  String get registerWaterReminderSubtitle;

  /// No description provided for @registerReminderStyleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de lembrete / som:'**
  String get registerReminderStyleLabel;

  /// No description provided for @registerReminderStyleChime.
  ///
  /// In pt, this message translates to:
  /// **'Aviso (Mensagem)'**
  String get registerReminderStyleChime;

  /// No description provided for @registerReminderStyleAlarm.
  ///
  /// In pt, this message translates to:
  /// **'Alarme Telefônico'**
  String get registerReminderStyleAlarm;

  /// No description provided for @registerWaterTrackingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Controle de quantidade consumida'**
  String get registerWaterTrackingTitle;

  /// No description provided for @registerWaterTrackingOnDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ao tocar no alarme, o app abre para registrar a quantidade de água'**
  String get registerWaterTrackingOnDesc;

  /// No description provided for @registerWaterTrackingOffDesc.
  ///
  /// In pt, this message translates to:
  /// **'Apenas soa o lembrete no horário, sem abrir preenchimento'**
  String get registerWaterTrackingOffDesc;

  /// No description provided for @registerHaveAccountPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Já possui uma conta? '**
  String get registerHaveAccountPrompt;

  /// No description provided for @homeGreeting.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingNoName.
  ///
  /// In pt, this message translates to:
  /// **'Olá!'**
  String get homeGreetingNoName;

  /// No description provided for @homeSessionActive.
  ///
  /// In pt, this message translates to:
  /// **'Sessão ativa'**
  String get homeSessionActive;

  /// No description provided for @homeDataProtectedBadge.
  ///
  /// In pt, this message translates to:
  /// **'Seus registros estão protegidos'**
  String get homeDataProtectedBadge;

  /// No description provided for @homeTodayEntryDone.
  ///
  /// In pt, this message translates to:
  /// **'Registro de hoje concluído'**
  String get homeTodayEntryDone;

  /// No description provided for @notFoundErrorCode.
  ///
  /// In pt, this message translates to:
  /// **'ERRO 404'**
  String get notFoundErrorCode;

  /// No description provided for @notFoundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Página Não Encontrada'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In pt, this message translates to:
  /// **'A página que você tentou acessar não existe.'**
  String get notFoundBody;

  /// No description provided for @notFoundBackToDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o Painel'**
  String get notFoundBackToDashboard;

  /// No description provided for @notFoundGoHome.
  ///
  /// In pt, this message translates to:
  /// **'Ir para o Início'**
  String get notFoundGoHome;

  /// No description provided for @notFoundGoBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar à tela anterior'**
  String get notFoundGoBack;

  /// No description provided for @wellnessConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tudo Bem por Aqui!'**
  String get wellnessConfirmTitle;

  /// No description provided for @wellnessConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Que excelente notícia! Você indicou estar se sentindo bem tanto física quanto emocionalmente hoje.\n\nSeu check-in diário foi concluído com sucesso e seus dados estão protegidos. Continue cultivando bons hábitos de autocuidado!'**
  String get wellnessConfirmBody;

  /// No description provided for @wellnessConfirmButton.
  ///
  /// In pt, this message translates to:
  /// **'Concluir Check-in'**
  String get wellnessConfirmButton;

  /// No description provided for @adBannerHeader.
  ///
  /// In pt, this message translates to:
  /// **'Parceiro local • Anúncio não usa seus dados de saúde'**
  String get adBannerHeader;

  /// No description provided for @adBannerSampleBody.
  ///
  /// In pt, this message translates to:
  /// **'Itens de primeiros socorros e higiene pessoal com até 20% off.'**
  String get adBannerSampleBody;

  /// No description provided for @outcomeStaticGuidance.
  ///
  /// In pt, this message translates to:
  /// **'Este app não avalia sua saúde. Se algum desconforto persistir, piorar ou te preocupar, procure um profissional de saúde. Em emergência, ligue 192.'**
  String get outcomeStaticGuidance;

  /// No description provided for @outcomeDualAxisNote.
  ///
  /// In pt, this message translates to:
  /// **'Você registrou sensações no corpo e nas emoções hoje. Se algum desconforto físico persistir ou piorar, converse com um profissional de saúde.'**
  String get outcomeDualAxisNote;

  /// No description provided for @outcomeAiInsightTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como organizamos sua anotação'**
  String get outcomeAiInsightTitle;

  /// No description provided for @outcomeAiInsightLayTerm.
  ///
  /// In pt, this message translates to:
  /// **'Termo que você usou: {term}'**
  String outcomeAiInsightLayTerm(String term);

  /// No description provided for @outcomeAiInsightArea.
  ///
  /// In pt, this message translates to:
  /// **'Área ou emoção: {area}'**
  String outcomeAiInsightArea(String area);

  /// No description provided for @outcomeWellnessReadingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Leituras sobre bem-estar'**
  String get outcomeWellnessReadingsTitle;

  /// No description provided for @outcomeWellnessReadingsDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdos educativos gerais. Não são orientação para o seu caso.'**
  String get outcomeWellnessReadingsDisclaimer;

  /// No description provided for @outcomeWellnessReadingsRelatedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Leituras relacionadas ao tema que você registrou'**
  String get outcomeWellnessReadingsRelatedTitle;

  /// No description provided for @outcomeWellnessReadingsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} leituras'**
  String outcomeWellnessReadingsCount(int count);

  /// No description provided for @outcomeArticlesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma leitura disponível no momento.'**
  String get outcomeArticlesEmpty;

  /// No description provided for @journalPatternTitle.
  ///
  /// In pt, this message translates to:
  /// **'Padrões nos seus registros'**
  String get journalPatternTitle;

  /// No description provided for @journalPatternDescription.
  ///
  /// In pt, this message translates to:
  /// **'Você registrou {category} com intensidade alta {count} vezes nos últimos {windowDays} dias. Se isso está atrapalhando seu dia a dia, pode ser útil conversar com um profissional de saúde.'**
  String journalPatternDescription(String category, int count, int windowDays);

  /// No description provided for @historyIntensityInformed.
  ///
  /// In pt, this message translates to:
  /// **'Intensidade informada: {n}/5'**
  String historyIntensityInformed(int n);

  /// No description provided for @todayOutcomeCompletedBadge.
  ///
  /// In pt, this message translates to:
  /// **'Registro concluído'**
  String get todayOutcomeCompletedBadge;

  /// No description provided for @todayOutcomeUpdateButton.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar registro de hoje'**
  String get todayOutcomeUpdateButton;

  /// No description provided for @todayOutcomeDetailedCheckinButton.
  ///
  /// In pt, this message translates to:
  /// **'Fazer registro detalhado'**
  String get todayOutcomeDetailedCheckinButton;

  /// No description provided for @appUpdateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualize o aplicativo'**
  String get appUpdateTitle;

  /// No description provided for @appUpdateMessage.
  ///
  /// In pt, this message translates to:
  /// **'Esta versão não é mais suportada. Instale a versão {minVersion} ou mais recente na loja de aplicativos.'**
  String appUpdateMessage(String minVersion);

  /// No description provided for @appUpdateButton.
  ///
  /// In pt, this message translates to:
  /// **'Abrir loja de aplicativos'**
  String get appUpdateButton;

  /// Chip on the Home summary card of today's entry. Self-reported intensity.
  ///
  /// In pt, this message translates to:
  /// **'Intensidade informada: {value}/5'**
  String outcomeSummaryIntensity(int value);

  /// Time today's entry was saved (HH:mm).
  ///
  /// In pt, this message translates to:
  /// **'Registrado às {time}'**
  String outcomeSummaryRecordedAt(String time);

  /// Repeats the option the person chose, without reinterpreting it (audit C-32).
  ///
  /// In pt, this message translates to:
  /// **'Você registrou: {option}'**
  String outcomeTodayYouLogged(String option);

  /// No description provided for @outcomeTodayStatusGood.
  ///
  /// In pt, this message translates to:
  /// **'Bem'**
  String get outcomeTodayStatusGood;

  /// No description provided for @outcomeTodayStatusSoSo.
  ///
  /// In pt, this message translates to:
  /// **'Mais ou menos'**
  String get outcomeTodayStatusSoSo;

  /// No description provided for @outcomeTodayStatusBad.
  ///
  /// In pt, this message translates to:
  /// **'Mal'**
  String get outcomeTodayStatusBad;

  /// No description provided for @outcomeHistoryDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do registro'**
  String get outcomeHistoryDetailTitle;

  /// No description provided for @outcomeHistoryNoNarrative.
  ///
  /// In pt, this message translates to:
  /// **'Você não adicionou uma descrição neste registro.'**
  String get outcomeHistoryNoNarrative;
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
