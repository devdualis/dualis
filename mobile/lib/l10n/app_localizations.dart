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
