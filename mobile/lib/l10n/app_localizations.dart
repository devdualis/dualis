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

  /// Title of the forgot password screen
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu sua senha?'**
  String get forgotPasswordTitle;

  /// Subtitle of the forgot password screen
  ///
  /// In pt, this message translates to:
  /// **'Informe o e-mail vinculado à sua conta e enviaremos um código para redefinir sua senha.'**
  String get forgotPasswordSubtitle;

  /// Submit button on the forgot password screen
  ///
  /// In pt, this message translates to:
  /// **'Enviar Código'**
  String get forgotPasswordSendCta;

  /// Success message shown after requesting a password reset code
  ///
  /// In pt, this message translates to:
  /// **'Se esse e-mail estiver cadastrado, enviamos um código de redefinição para ele.'**
  String get forgotPasswordSuccessMessage;

  /// Link back to the login screen from the forgot password screen
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao Login'**
  String get forgotPasswordBackToLogin;

  /// Title of the reset password screen
  ///
  /// In pt, this message translates to:
  /// **'Redefina sua senha'**
  String get resetPasswordTitle;

  /// Subtitle of the reset password screen
  ///
  /// In pt, this message translates to:
  /// **'Informe o código que enviamos e escolha uma nova senha.'**
  String get resetPasswordSubtitle;

  /// Label for the verification code field on the reset password screen
  ///
  /// In pt, this message translates to:
  /// **'Código de Verificação'**
  String get resetPasswordCodeLabel;

  /// Hint for the verification code field on the reset password screen
  ///
  /// In pt, this message translates to:
  /// **'Código de 6 dígitos'**
  String get resetPasswordCodeHint;

  /// Validation error when the verification code is missing or invalid
  ///
  /// In pt, this message translates to:
  /// **'Informe o código de 6 dígitos'**
  String get resetPasswordCodeRequired;

  /// Submit button on the reset password screen
  ///
  /// In pt, this message translates to:
  /// **'Redefinir Senha'**
  String get resetPasswordSubmitCta;

  /// Success message shown after resetting the password
  ///
  /// In pt, this message translates to:
  /// **'Sua senha foi redefinida. Você já pode fazer login.'**
  String get resetPasswordSuccessMessage;

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

  /// Shown when login fails because the email is not verified; the app then opens the verification screen
  ///
  /// In pt, this message translates to:
  /// **'Seu e-mail ainda não foi verificado. Digite o código enviado ou peça um novo.'**
  String get loginEmailNotVerified;

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
  /// **'Sugerir, com ajuda de IA, uma opção já existente do diário quando você escreve com as suas palavras (sem avaliação de saúde).'**
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
  /// **'Google LLC (API Gemini): o texto de \"escrever o meu\" pode ser enviado à Gemini só para sugerir uma opção já existente do diário. A IA não avalia a sua saúde.'**
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

  /// No description provided for @outcomeWellnessReadingsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} leituras'**
  String outcomeWellnessReadingsCount(int count);

  /// No description provided for @journalPatternTitle.
  ///
  /// In pt, this message translates to:
  /// **'Padrões nos seus registros'**
  String get journalPatternTitle;

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

  /// No description provided for @checkInSummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registro salvo'**
  String get checkInSummaryTitle;

  /// No description provided for @checkInSummaryBackHome.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao início'**
  String get checkInSummaryBackHome;

  /// No description provided for @checkInSummaryBackHomeCountdown.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao início ({seconds})'**
  String checkInSummaryBackHomeCountdown(int seconds);

  /// No description provided for @jv2FlowTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registro do dia'**
  String get jv2FlowTitle;

  /// No description provided for @jv2Back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get jv2Back;

  /// No description provided for @jv2Continue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get jv2Continue;

  /// No description provided for @jv2Skip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get jv2Skip;

  /// No description provided for @jv2Save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar registro'**
  String get jv2Save;

  /// No description provided for @jv2Yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get jv2Yes;

  /// No description provided for @jv2No.
  ///
  /// In pt, this message translates to:
  /// **'Não, continuar'**
  String get jv2No;

  /// No description provided for @jv2Cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get jv2Cancel;

  /// No description provided for @jv2Remove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get jv2Remove;

  /// No description provided for @jv2HelloName.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}!'**
  String jv2HelloName(String name);

  /// No description provided for @jv2Hello.
  ///
  /// In pt, this message translates to:
  /// **'Olá!'**
  String get jv2Hello;

  /// No description provided for @jv2GoodMorning.
  ///
  /// In pt, this message translates to:
  /// **'Bom dia.'**
  String get jv2GoodMorning;

  /// No description provided for @jv2GoodAfternoon.
  ///
  /// In pt, this message translates to:
  /// **'Boa tarde.'**
  String get jv2GoodAfternoon;

  /// No description provided for @jv2GoodEvening.
  ///
  /// In pt, this message translates to:
  /// **'Boa noite.'**
  String get jv2GoodEvening;

  /// No description provided for @jv2MoodQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Como você está se sentindo hoje?'**
  String get jv2MoodQuestion;

  /// No description provided for @jv2MoodBem.
  ///
  /// In pt, this message translates to:
  /// **'Bem'**
  String get jv2MoodBem;

  /// No description provided for @jv2MoodNormal.
  ///
  /// In pt, this message translates to:
  /// **'Normal'**
  String get jv2MoodNormal;

  /// No description provided for @jv2MoodNaoTaoBem.
  ///
  /// In pt, this message translates to:
  /// **'Não tão bem'**
  String get jv2MoodNaoTaoBem;

  /// No description provided for @jv2AreaConditions.
  ///
  /// In pt, this message translates to:
  /// **'Minhas condições'**
  String get jv2AreaConditions;

  /// No description provided for @jv2ConditionCardQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Como você está com {label} hoje?'**
  String jv2ConditionCardQuestion(String label);

  /// No description provided for @jv2TimeQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Isso que você sente tem mais a ver com…'**
  String get jv2TimeQuestion;

  /// No description provided for @jv2TimePassado.
  ///
  /// In pt, this message translates to:
  /// **'O que já passou'**
  String get jv2TimePassado;

  /// No description provided for @jv2TimePresente.
  ///
  /// In pt, this message translates to:
  /// **'O momento atual'**
  String get jv2TimePresente;

  /// No description provided for @jv2TimeFuturo.
  ///
  /// In pt, this message translates to:
  /// **'O que vem pela frente'**
  String get jv2TimeFuturo;

  /// No description provided for @jv2TimeShortPassado.
  ///
  /// In pt, this message translates to:
  /// **'Passado'**
  String get jv2TimeShortPassado;

  /// No description provided for @jv2TimeShortPresente.
  ///
  /// In pt, this message translates to:
  /// **'Presente'**
  String get jv2TimeShortPresente;

  /// No description provided for @jv2TimeShortFuturo.
  ///
  /// In pt, this message translates to:
  /// **'Futuro'**
  String get jv2TimeShortFuturo;

  /// No description provided for @jv2BranchQuestion.
  ///
  /// In pt, this message translates to:
  /// **'O que combina mais com você agora?'**
  String get jv2BranchQuestion;

  /// No description provided for @jv2OptionsQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Marque o que combina com você.'**
  String get jv2OptionsQuestion;

  /// No description provided for @jv2MultiSelectHint.
  ///
  /// In pt, this message translates to:
  /// **'Você pode marcar mais de um.'**
  String get jv2MultiSelectHint;

  /// No description provided for @jv2WriteMine.
  ///
  /// In pt, this message translates to:
  /// **'Escrever o meu'**
  String get jv2WriteMine;

  /// No description provided for @jv2WriteMineHint.
  ///
  /// In pt, this message translates to:
  /// **'Em poucas palavras'**
  String get jv2WriteMineHint;

  /// No description provided for @jv2WriteMineAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get jv2WriteMineAdd;

  /// No description provided for @jv2SuggestTitle.
  ///
  /// In pt, this message translates to:
  /// **'Isso se parece com uma opção que já existe'**
  String get jv2SuggestTitle;

  /// No description provided for @jv2SuggestBody.
  ///
  /// In pt, this message translates to:
  /// **'Quer guardar como \"{option}\" em vez do texto escrito?'**
  String jv2SuggestBody(String option);

  /// No description provided for @jv2SuggestYes.
  ///
  /// In pt, this message translates to:
  /// **'Usar essa opção'**
  String get jv2SuggestYes;

  /// No description provided for @jv2SuggestNo.
  ///
  /// In pt, this message translates to:
  /// **'Manter o que escrevi'**
  String get jv2SuggestNo;

  /// No description provided for @jv2MoreQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Quer registrar mais alguma coisa?'**
  String get jv2MoreQuestion;

  /// No description provided for @jv2MoreBodyQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Quer marcar outra parte do corpo?'**
  String get jv2MoreBodyQuestion;

  /// No description provided for @jv2BodyQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Onde você sente dor ou incômodo?'**
  String get jv2BodyQuestion;

  /// No description provided for @jv2BodyHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque em uma ou mais partes.'**
  String get jv2BodyHint;

  /// No description provided for @jv2BodyFront.
  ///
  /// In pt, this message translates to:
  /// **'Frente'**
  String get jv2BodyFront;

  /// No description provided for @jv2BodyBack.
  ///
  /// In pt, this message translates to:
  /// **'Costas'**
  String get jv2BodyBack;

  /// No description provided for @jv2ItemLimit.
  ///
  /// In pt, this message translates to:
  /// **'Você chegou ao limite de {max} itens neste registro.'**
  String jv2ItemLimit(int max);

  /// No description provided for @jv2BranchPassadoTristeza.
  ///
  /// In pt, this message translates to:
  /// **'Tristeza ou saudade'**
  String get jv2BranchPassadoTristeza;

  /// No description provided for @jv2BranchPassadoMemoria.
  ///
  /// In pt, this message translates to:
  /// **'Uma memória que incomoda'**
  String get jv2BranchPassadoMemoria;

  /// No description provided for @jv2BranchPresenteEnergia.
  ///
  /// In pt, this message translates to:
  /// **'Sem energia'**
  String get jv2BranchPresenteEnergia;

  /// No description provided for @jv2BranchPresenteSobrecarga.
  ///
  /// In pt, this message translates to:
  /// **'Irritado(a) ou sobrecarregado(a)'**
  String get jv2BranchPresenteSobrecarga;

  /// No description provided for @jv2BranchFuturoMente.
  ///
  /// In pt, this message translates to:
  /// **'Mente acelerada'**
  String get jv2BranchFuturoMente;

  /// No description provided for @jv2BranchFuturoMedo.
  ///
  /// In pt, this message translates to:
  /// **'Medo de algo dar errado'**
  String get jv2BranchFuturoMedo;

  /// No description provided for @jv2OptPassadoTristezaCulpa.
  ///
  /// In pt, this message translates to:
  /// **'Culpa ou arrependimento'**
  String get jv2OptPassadoTristezaCulpa;

  /// No description provided for @jv2OptPassadoTristezaSaudade.
  ///
  /// In pt, this message translates to:
  /// **'Falta de alguém ou de como as coisas eram'**
  String get jv2OptPassadoTristezaSaudade;

  /// No description provided for @jv2OptPassadoMemoriaLembranca.
  ///
  /// In pt, this message translates to:
  /// **'Uma lembrança ruim que volta'**
  String get jv2OptPassadoMemoriaLembranca;

  /// No description provided for @jv2OptPassadoMemoriaMagoa.
  ///
  /// In pt, this message translates to:
  /// **'Fico remoendo mágoas antigas'**
  String get jv2OptPassadoMemoriaMagoa;

  /// No description provided for @jv2OptPresenteEnergiaCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Corpo pesado, tenso ou dolorido'**
  String get jv2OptPresenteEnergiaCorpo;

  /// No description provided for @jv2OptPresenteEnergiaDesligado.
  ///
  /// In pt, this message translates to:
  /// **'No piloto automático, meio desligado'**
  String get jv2OptPresenteEnergiaDesligado;

  /// No description provided for @jv2OptPresenteSobrecargaPaciencia.
  ///
  /// In pt, this message translates to:
  /// **'Sem paciência, explodindo por pouco'**
  String get jv2OptPresenteSobrecargaPaciencia;

  /// No description provided for @jv2OptPresenteSobrecargaAperto.
  ///
  /// In pt, this message translates to:
  /// **'Aperto no peito e momentos de desespero'**
  String get jv2OptPresenteSobrecargaAperto;

  /// No description provided for @jv2OptFuturoMenteAntecipar.
  ///
  /// In pt, this message translates to:
  /// **'Fico antecipando problemas'**
  String get jv2OptFuturoMenteAntecipar;

  /// No description provided for @jv2OptFuturoMenteCobranca.
  ///
  /// In pt, this message translates to:
  /// **'Cobrança por perfeição ou controle'**
  String get jv2OptFuturoMenteCobranca;

  /// No description provided for @jv2OptFuturoMedoJulgamento.
  ///
  /// In pt, this message translates to:
  /// **'Medo de falhar ou ser julgado(a)'**
  String get jv2OptFuturoMedoJulgamento;

  /// No description provided for @jv2OptFuturoMedoDesanimo.
  ///
  /// In pt, this message translates to:
  /// **'Desânimo com o rumo das coisas'**
  String get jv2OptFuturoMedoDesanimo;

  /// No description provided for @jv2RegionCabeca.
  ///
  /// In pt, this message translates to:
  /// **'Cabeça e pescoço'**
  String get jv2RegionCabeca;

  /// No description provided for @jv2RegionPeito.
  ///
  /// In pt, this message translates to:
  /// **'Peito'**
  String get jv2RegionPeito;

  /// No description provided for @jv2RegionBarriga.
  ///
  /// In pt, this message translates to:
  /// **'Barriga'**
  String get jv2RegionBarriga;

  /// No description provided for @jv2RegionCostas.
  ///
  /// In pt, this message translates to:
  /// **'Costas'**
  String get jv2RegionCostas;

  /// No description provided for @jv2RegionMembros.
  ///
  /// In pt, this message translates to:
  /// **'Braços, pernas e mãos'**
  String get jv2RegionMembros;

  /// No description provided for @jv2AxisEmotional.
  ///
  /// In pt, this message translates to:
  /// **'Psicoemocional'**
  String get jv2AxisEmotional;

  /// No description provided for @jv2AxisPhysical.
  ///
  /// In pt, this message translates to:
  /// **'Físico'**
  String get jv2AxisPhysical;

  /// No description provided for @jv2WholeBody.
  ///
  /// In pt, this message translates to:
  /// **'No corpo todo'**
  String get jv2WholeBody;

  /// No description provided for @jv2RegionPele.
  ///
  /// In pt, this message translates to:
  /// **'Pele'**
  String get jv2RegionPele;

  /// No description provided for @jv2RegionMusculos.
  ///
  /// In pt, this message translates to:
  /// **'Músculos'**
  String get jv2RegionMusculos;

  /// No description provided for @jv2RegionHormonios.
  ///
  /// In pt, this message translates to:
  /// **'Hormônios e metabolismo'**
  String get jv2RegionHormonios;

  /// No description provided for @jv2SensationQuestion.
  ///
  /// In pt, this message translates to:
  /// **'É dor ou incômodo?'**
  String get jv2SensationQuestion;

  /// No description provided for @jv2SensationDor.
  ///
  /// In pt, this message translates to:
  /// **'Dor'**
  String get jv2SensationDor;

  /// No description provided for @jv2SensationIncomodo.
  ///
  /// In pt, this message translates to:
  /// **'Incômodo'**
  String get jv2SensationIncomodo;

  /// No description provided for @jv2BranchCabecaNuca.
  ///
  /// In pt, this message translates to:
  /// **'Nuca'**
  String get jv2BranchCabecaNuca;

  /// No description provided for @jv2BranchPeleCoceira.
  ///
  /// In pt, this message translates to:
  /// **'Coceira ou ardência'**
  String get jv2BranchPeleCoceira;

  /// No description provided for @jv2BranchPeleAparencia.
  ///
  /// In pt, this message translates to:
  /// **'Aparência da pele'**
  String get jv2BranchPeleAparencia;

  /// No description provided for @jv2BranchMusculosTensao.
  ///
  /// In pt, this message translates to:
  /// **'Tensão'**
  String get jv2BranchMusculosTensao;

  /// No description provided for @jv2BranchMusculosCansaco.
  ///
  /// In pt, this message translates to:
  /// **'Cansaço muscular'**
  String get jv2BranchMusculosCansaco;

  /// No description provided for @jv2BranchHormoniosTemperatura.
  ///
  /// In pt, this message translates to:
  /// **'Temperatura'**
  String get jv2BranchHormoniosTemperatura;

  /// No description provided for @jv2BranchHormoniosApetite.
  ///
  /// In pt, this message translates to:
  /// **'Apetite e sede'**
  String get jv2BranchHormoniosApetite;

  /// No description provided for @jv2OptCabecaNucaRigida.
  ///
  /// In pt, this message translates to:
  /// **'Nuca dura ou pesada'**
  String get jv2OptCabecaNucaRigida;

  /// No description provided for @jv2OptCabecaNucaPontada.
  ///
  /// In pt, this message translates to:
  /// **'Pontada na parte de trás'**
  String get jv2OptCabecaNucaPontada;

  /// No description provided for @jv2OptPeleCoceiraCoceira.
  ///
  /// In pt, this message translates to:
  /// **'Coceira'**
  String get jv2OptPeleCoceiraCoceira;

  /// No description provided for @jv2OptPeleCoceiraArdencia.
  ///
  /// In pt, this message translates to:
  /// **'Ardência'**
  String get jv2OptPeleCoceiraArdencia;

  /// No description provided for @jv2OptPeleAparenciaVermelhidao.
  ///
  /// In pt, this message translates to:
  /// **'Vermelhidão'**
  String get jv2OptPeleAparenciaVermelhidao;

  /// No description provided for @jv2OptPeleAparenciaManchas.
  ///
  /// In pt, this message translates to:
  /// **'Manchas'**
  String get jv2OptPeleAparenciaManchas;

  /// No description provided for @jv2OptMusculosTensaoRigidez.
  ///
  /// In pt, this message translates to:
  /// **'Rigidez'**
  String get jv2OptMusculosTensaoRigidez;

  /// No description provided for @jv2OptMusculosTensaoCaibra.
  ///
  /// In pt, this message translates to:
  /// **'Cãibra'**
  String get jv2OptMusculosTensaoCaibra;

  /// No description provided for @jv2OptMusculosCansacoFraqueza.
  ///
  /// In pt, this message translates to:
  /// **'Fraqueza'**
  String get jv2OptMusculosCansacoFraqueza;

  /// No description provided for @jv2OptMusculosCansacoDolorido.
  ///
  /// In pt, this message translates to:
  /// **'Dolorido'**
  String get jv2OptMusculosCansacoDolorido;

  /// No description provided for @jv2OptHormoniosTemperaturaCalorao.
  ///
  /// In pt, this message translates to:
  /// **'Calorões'**
  String get jv2OptHormoniosTemperaturaCalorao;

  /// No description provided for @jv2OptHormoniosTemperaturaFrio.
  ///
  /// In pt, this message translates to:
  /// **'Frio fora do comum'**
  String get jv2OptHormoniosTemperaturaFrio;

  /// No description provided for @jv2OptHormoniosApetiteSede.
  ///
  /// In pt, this message translates to:
  /// **'Sede fora do comum'**
  String get jv2OptHormoniosApetiteSede;

  /// No description provided for @jv2OptHormoniosApetiteFome.
  ///
  /// In pt, this message translates to:
  /// **'Fome fora do comum'**
  String get jv2OptHormoniosApetiteFome;

  /// No description provided for @jv2BranchCabecaPressao.
  ///
  /// In pt, this message translates to:
  /// **'Aperto, peso ou pressão'**
  String get jv2BranchCabecaPressao;

  /// No description provided for @jv2BranchCabecaSentidos.
  ///
  /// In pt, this message translates to:
  /// **'Olhos, boca ou garganta'**
  String get jv2BranchCabecaSentidos;

  /// No description provided for @jv2BranchPeitoRespiracao.
  ///
  /// In pt, this message translates to:
  /// **'Respiração diferente'**
  String get jv2BranchPeitoRespiracao;

  /// No description provided for @jv2BranchPeitoIncomodo.
  ///
  /// In pt, this message translates to:
  /// **'Incômodo no peito ou costelas'**
  String get jv2BranchPeitoIncomodo;

  /// No description provided for @jv2BranchBarrigaQueimacao.
  ///
  /// In pt, this message translates to:
  /// **'Queimação ou enjoo'**
  String get jv2BranchBarrigaQueimacao;

  /// No description provided for @jv2BranchBarrigaColica.
  ///
  /// In pt, this message translates to:
  /// **'Cólica ou estufamento'**
  String get jv2BranchBarrigaColica;

  /// No description provided for @jv2BranchCostasRigidez.
  ///
  /// In pt, this message translates to:
  /// **'Rigidez ou travamento'**
  String get jv2BranchCostasRigidez;

  /// No description provided for @jv2BranchCostasFisgada.
  ///
  /// In pt, this message translates to:
  /// **'Dor que fisga ao mexer'**
  String get jv2BranchCostasFisgada;

  /// No description provided for @jv2BranchMembrosCansaco.
  ///
  /// In pt, this message translates to:
  /// **'Cansaço ou dor'**
  String get jv2BranchMembrosCansaco;

  /// No description provided for @jv2BranchMembrosFormigamento.
  ///
  /// In pt, this message translates to:
  /// **'Formigamento'**
  String get jv2BranchMembrosFormigamento;

  /// No description provided for @jv2OptCabecaPressaoTemporas.
  ///
  /// In pt, this message translates to:
  /// **'Dor ou pressão nas têmporas ou testa'**
  String get jv2OptCabecaPressaoTemporas;

  /// No description provided for @jv2OptCabecaPressaoLatejando.
  ///
  /// In pt, this message translates to:
  /// **'Latejando, com incômodo à luz ou ao barulho'**
  String get jv2OptCabecaPressaoLatejando;

  /// No description provided for @jv2OptCabecaSentidosGarganta.
  ///
  /// In pt, this message translates to:
  /// **'Garganta arranhando ou seca'**
  String get jv2OptCabecaSentidosGarganta;

  /// No description provided for @jv2OptCabecaSentidosOlhos.
  ///
  /// In pt, this message translates to:
  /// **'Olhos pesados ou ardendo'**
  String get jv2OptCabecaSentidosOlhos;

  /// No description provided for @jv2OptPeitoRespiracaoCurta.
  ///
  /// In pt, this message translates to:
  /// **'Respiração curta'**
  String get jv2OptPeitoRespiracaoCurta;

  /// No description provided for @jv2OptPeitoRespiracaoTosse.
  ///
  /// In pt, this message translates to:
  /// **'Tosse ou peito carregado'**
  String get jv2OptPeitoRespiracaoTosse;

  /// No description provided for @jv2OptPeitoIncomodoBatedeira.
  ///
  /// In pt, this message translates to:
  /// **'Coração acelerado ou batedeira'**
  String get jv2OptPeitoIncomodoBatedeira;

  /// No description provided for @jv2OptPeitoIncomodoCostelas.
  ///
  /// In pt, this message translates to:
  /// **'Pontada nas costelas ao respirar fundo'**
  String get jv2OptPeitoIncomodoCostelas;

  /// No description provided for @jv2OptBarrigaQueimacaoSubindo.
  ///
  /// In pt, this message translates to:
  /// **'Queimação subindo'**
  String get jv2OptBarrigaQueimacaoSubindo;

  /// No description provided for @jv2OptBarrigaQueimacaoEnjoo.
  ///
  /// In pt, this message translates to:
  /// **'Enjoo'**
  String get jv2OptBarrigaQueimacaoEnjoo;

  /// No description provided for @jv2OptBarrigaColicaGases.
  ///
  /// In pt, this message translates to:
  /// **'Gases ou barriga estufada'**
  String get jv2OptBarrigaColicaGases;

  /// No description provided for @jv2OptBarrigaColicaPontadas.
  ///
  /// In pt, this message translates to:
  /// **'Cólica ou pontadas'**
  String get jv2OptBarrigaColicaPontadas;

  /// No description provided for @jv2OptCostasRigidezOmbros.
  ///
  /// In pt, this message translates to:
  /// **'Pescoço e ombros duros'**
  String get jv2OptCostasRigidezOmbros;

  /// No description provided for @jv2OptCostasRigidezLombar.
  ///
  /// In pt, this message translates to:
  /// **'Peso na lombar'**
  String get jv2OptCostasRigidezLombar;

  /// No description provided for @jv2OptCostasFisgadaIrradia.
  ///
  /// In pt, this message translates to:
  /// **'Pontada que desce para braço ou perna'**
  String get jv2OptCostasFisgadaIrradia;

  /// No description provided for @jv2OptCostasFisgadaAoMexer.
  ///
  /// In pt, this message translates to:
  /// **'Dor ao mexer'**
  String get jv2OptCostasFisgadaAoMexer;

  /// No description provided for @jv2OptMembrosCansacoJuntas.
  ///
  /// In pt, this message translates to:
  /// **'Juntas doloridas'**
  String get jv2OptMembrosCansacoJuntas;

  /// No description provided for @jv2OptMembrosCansacoPesados.
  ///
  /// In pt, this message translates to:
  /// **'Braços ou pernas cansados'**
  String get jv2OptMembrosCansacoPesados;

  /// No description provided for @jv2OptMembrosFormigamentoDormentes.
  ///
  /// In pt, this message translates to:
  /// **'Mãos ou pés formigando ou dormentes'**
  String get jv2OptMembrosFormigamentoDormentes;

  /// No description provided for @jv2OptMembrosFormigamentoChoque.
  ///
  /// In pt, this message translates to:
  /// **'Sensação de choque'**
  String get jv2OptMembrosFormigamentoChoque;

  /// No description provided for @jv2PersistenceQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Há quanto tempo você percebe isso?'**
  String get jv2PersistenceQuestion;

  /// No description provided for @jv2PersistenceHoje.
  ///
  /// In pt, this message translates to:
  /// **'Começou hoje'**
  String get jv2PersistenceHoje;

  /// No description provided for @jv2PersistenceDiasSemanas.
  ///
  /// In pt, this message translates to:
  /// **'Alguns dias ou semanas'**
  String get jv2PersistenceDiasSemanas;

  /// No description provided for @jv2PersistenceMesesAnos.
  ///
  /// In pt, this message translates to:
  /// **'Meses ou anos'**
  String get jv2PersistenceMesesAnos;

  /// No description provided for @jv2PersistenceOptional.
  ///
  /// In pt, this message translates to:
  /// **'Há quanto tempo? (opcional)'**
  String get jv2PersistenceOptional;

  /// No description provided for @jv2IntensityQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Agora, quanto isso pesa no seu dia?'**
  String get jv2IntensityQuestion;

  /// No description provided for @jv2IntensityCompactQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Para cada item, quanto pesa no seu dia?'**
  String get jv2IntensityCompactQuestion;

  /// No description provided for @jv2IntensityLevel.
  ///
  /// In pt, this message translates to:
  /// **'{level} de 5'**
  String jv2IntensityLevel(int level);

  /// No description provided for @jv2IntensityEmotional1.
  ///
  /// In pt, this message translates to:
  /// **'Passa rápido, sigo meu dia normalmente.'**
  String get jv2IntensityEmotional1;

  /// No description provided for @jv2IntensityEmotional2.
  ///
  /// In pt, this message translates to:
  /// **'Percebo, mas consigo manter o foco.'**
  String get jv2IntensityEmotional2;

  /// No description provided for @jv2IntensityEmotional3.
  ///
  /// In pt, this message translates to:
  /// **'Está tirando minha energia ou foco.'**
  String get jv2IntensityEmotional3;

  /// No description provided for @jv2IntensityEmotional4.
  ///
  /// In pt, this message translates to:
  /// **'Está mudando minha rotina (sono, tarefas, convívio).'**
  String get jv2IntensityEmotional4;

  /// No description provided for @jv2IntensityEmotional5.
  ///
  /// In pt, this message translates to:
  /// **'Está me travando quase por completo hoje.'**
  String get jv2IntensityEmotional5;

  /// No description provided for @jv2IntensityPhysical1.
  ///
  /// In pt, this message translates to:
  /// **'Sinto, mas não atrapalha nada.'**
  String get jv2IntensityPhysical1;

  /// No description provided for @jv2IntensityPhysical2.
  ///
  /// In pt, this message translates to:
  /// **'Incomoda, mas mantenho minhas atividades.'**
  String get jv2IntensityPhysical2;

  /// No description provided for @jv2IntensityPhysical3.
  ///
  /// In pt, this message translates to:
  /// **'Diminuiu meu ritmo ou me fez pausar.'**
  String get jv2IntensityPhysical3;

  /// No description provided for @jv2IntensityPhysical4.
  ///
  /// In pt, this message translates to:
  /// **'Não consigo fazer direito o que preciso.'**
  String get jv2IntensityPhysical4;

  /// No description provided for @jv2IntensityPhysical5.
  ///
  /// In pt, this message translates to:
  /// **'Está me travando quase por completo hoje.'**
  String get jv2IntensityPhysical5;

  /// No description provided for @jv2EmergencyLine.
  ///
  /// In pt, this message translates to:
  /// **'Se for uma emergência, use o botão Ajuda ou ligue 192.'**
  String get jv2EmergencyLine;

  /// No description provided for @jv2TriggersQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Tem algo que pode ter contribuído hoje?'**
  String get jv2TriggersQuestion;

  /// No description provided for @jv2TriggerTrabalho.
  ///
  /// In pt, this message translates to:
  /// **'Trabalho ou estudos'**
  String get jv2TriggerTrabalho;

  /// No description provided for @jv2TriggerFamilia.
  ///
  /// In pt, this message translates to:
  /// **'Família ou relações'**
  String get jv2TriggerFamilia;

  /// No description provided for @jv2TriggerSono.
  ///
  /// In pt, this message translates to:
  /// **'Noite mal dormida'**
  String get jv2TriggerSono;

  /// No description provided for @jv2TriggerAlimentacao.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação'**
  String get jv2TriggerAlimentacao;

  /// No description provided for @jv2TriggerEsforco.
  ///
  /// In pt, this message translates to:
  /// **'Esforço físico'**
  String get jv2TriggerEsforco;

  /// No description provided for @jv2TriggerQueda.
  ///
  /// In pt, this message translates to:
  /// **'Queda ou mau jeito'**
  String get jv2TriggerQueda;

  /// No description provided for @jv2TriggerMedicamento.
  ///
  /// In pt, this message translates to:
  /// **'Medicamento novo'**
  String get jv2TriggerMedicamento;

  /// No description provided for @jv2TriggerClima.
  ///
  /// In pt, this message translates to:
  /// **'Clima ou ambiente'**
  String get jv2TriggerClima;

  /// No description provided for @jv2TriggerNaoSei.
  ///
  /// In pt, this message translates to:
  /// **'Não sei'**
  String get jv2TriggerNaoSei;

  /// No description provided for @jv2TriggerOutro.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get jv2TriggerOutro;

  /// No description provided for @jv2TriggerNoteHint.
  ///
  /// In pt, this message translates to:
  /// **'Conte em poucas palavras'**
  String get jv2TriggerNoteHint;

  /// No description provided for @jv2NoteQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Quer contar mais?'**
  String get jv2NoteQuestion;

  /// No description provided for @jv2NoteHint.
  ///
  /// In pt, this message translates to:
  /// **'Escreva com suas palavras (opcional)'**
  String get jv2NoteHint;

  /// No description provided for @jv2SaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar agora. Tente de novo.'**
  String get jv2SaveError;

  /// No description provided for @jv2SavedOffline.
  ///
  /// In pt, this message translates to:
  /// **'Registro salvo no aparelho. Ele será enviado quando houver conexão.'**
  String get jv2SavedOffline;

  /// No description provided for @jv2ConditionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minhas condições'**
  String get jv2ConditionsTitle;

  /// No description provided for @jv2ConditionsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Informadas por você. Escreva com suas palavras; cada uma aparece no seu registro diário com a mesma escala de 1 a 5.'**
  String get jv2ConditionsSubtitle;

  /// No description provided for @jv2ConditionsAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get jv2ConditionsAdd;

  /// No description provided for @jv2ConditionsFieldHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Enxaqueca'**
  String get jv2ConditionsFieldHint;

  /// No description provided for @jv2ConditionsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não adicionou nenhuma.'**
  String get jv2ConditionsEmpty;

  /// No description provided for @jv2ConditionsArchive.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar'**
  String get jv2ConditionsArchive;

  /// No description provided for @jv2ConditionsArchiveConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar \"{label}\"? Seus registros antigos continuam com esse nome.'**
  String jv2ConditionsArchiveConfirm(String label);

  /// No description provided for @jv2ConditionsLimit.
  ///
  /// In pt, this message translates to:
  /// **'Você pode acompanhar até {max}.'**
  String jv2ConditionsLimit(int max);

  /// No description provided for @jv2ConditionsOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão. Tente de novo quando estiver online.'**
  String get jv2ConditionsOffline;

  /// No description provided for @jv2ConditionsError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar. Tente de novo.'**
  String get jv2ConditionsError;

  /// No description provided for @jv2ConditionsSettingsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe, com suas palavras, algo que você já conhece'**
  String get jv2ConditionsSettingsSubtitle;

  /// No description provided for @jv2PhraseTime1.
  ///
  /// In pt, this message translates to:
  /// **'Entendi. Vamos registrar isso com calma.'**
  String get jv2PhraseTime1;

  /// No description provided for @jv2PhraseTime2.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado por contar. Vamos anotar isso.'**
  String get jv2PhraseTime2;

  /// No description provided for @jv2PhraseTime3.
  ///
  /// In pt, this message translates to:
  /// **'Tudo bem. Um passo de cada vez.'**
  String get jv2PhraseTime3;

  /// No description provided for @jv2PhraseTime4.
  ///
  /// In pt, this message translates to:
  /// **'Certo. Vamos registrar do seu jeito.'**
  String get jv2PhraseTime4;

  /// No description provided for @jv2PhrasePassado1.
  ///
  /// In pt, this message translates to:
  /// **'A mente às vezes volta no tempo. Vamos anotar isso.'**
  String get jv2PhrasePassado1;

  /// No description provided for @jv2PhrasePassado2.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado por contar. Tem a ver com o quê?'**
  String get jv2PhrasePassado2;

  /// No description provided for @jv2PhrasePassado3.
  ///
  /// In pt, this message translates to:
  /// **'Vamos registrar isso com calma.'**
  String get jv2PhrasePassado3;

  /// No description provided for @jv2PhrasePresente1.
  ///
  /// In pt, this message translates to:
  /// **'Vamos anotar o que está pesando hoje.'**
  String get jv2PhrasePresente1;

  /// No description provided for @jv2PhrasePresente2.
  ///
  /// In pt, this message translates to:
  /// **'Entendi. O que combina mais com agora?'**
  String get jv2PhrasePresente2;

  /// No description provided for @jv2PhrasePresente3.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado por contar. Vamos registrar isso.'**
  String get jv2PhrasePresente3;

  /// No description provided for @jv2PhraseFuturo1.
  ///
  /// In pt, this message translates to:
  /// **'Pensar no que vem pela frente faz parte. Vamos anotar.'**
  String get jv2PhraseFuturo1;

  /// No description provided for @jv2PhraseFuturo2.
  ///
  /// In pt, this message translates to:
  /// **'Entendi. O que combina mais com você?'**
  String get jv2PhraseFuturo2;

  /// No description provided for @jv2PhraseFuturo3.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado por contar. Vamos registrar isso com calma.'**
  String get jv2PhraseFuturo3;

  /// No description provided for @jv2PhraseBody1.
  ///
  /// In pt, this message translates to:
  /// **'Vamos anotar o que você sente no corpo.'**
  String get jv2PhraseBody1;

  /// No description provided for @jv2PhraseBody2.
  ///
  /// In pt, this message translates to:
  /// **'Toque onde você sente desconforto.'**
  String get jv2PhraseBody2;

  /// No description provided for @jv2PhraseBody3.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado por contar. Onde você sente isso?'**
  String get jv2PhraseBody3;

  /// No description provided for @jv2PhraseRegion1.
  ///
  /// In pt, this message translates to:
  /// **'Vamos anotar o que você sente aqui.'**
  String get jv2PhraseRegion1;

  /// No description provided for @jv2PhraseRegion2.
  ///
  /// In pt, this message translates to:
  /// **'Entendi. Como é essa sensação?'**
  String get jv2PhraseRegion2;

  /// No description provided for @jv2PhraseRegion3.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado por contar. O que combina mais?'**
  String get jv2PhraseRegion3;

  /// No description provided for @jv2PhraseRegion4.
  ///
  /// In pt, this message translates to:
  /// **'Registrar ajuda você a acompanhar seu dia a dia.'**
  String get jv2PhraseRegion4;

  /// No description provided for @jv2PhraseIntensity1.
  ///
  /// In pt, this message translates to:
  /// **'Você escolhe o número. A escala é sua.'**
  String get jv2PhraseIntensity1;

  /// No description provided for @jv2PhraseIntensity2.
  ///
  /// In pt, this message translates to:
  /// **'Não existe resposta certa. Vale o que você sente.'**
  String get jv2PhraseIntensity2;

  /// No description provided for @jv2PhraseIntensity3.
  ///
  /// In pt, this message translates to:
  /// **'Quase lá. Só mais um pouco.'**
  String get jv2PhraseIntensity3;

  /// No description provided for @jv2PhraseTriggers1.
  ///
  /// In pt, this message translates to:
  /// **'Se quiser, marque o que pode ter contribuído.'**
  String get jv2PhraseTriggers1;

  /// No description provided for @jv2PhraseTriggers2.
  ///
  /// In pt, this message translates to:
  /// **'É opcional. Você pode pular.'**
  String get jv2PhraseTriggers2;

  /// No description provided for @jv2PhraseTriggers3.
  ///
  /// In pt, this message translates to:
  /// **'Quase pronto. Algo marcou o seu dia?'**
  String get jv2PhraseTriggers3;

  /// No description provided for @xv2CropTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajustar foto'**
  String get xv2CropTitle;

  /// No description provided for @xv2CropHint.
  ///
  /// In pt, this message translates to:
  /// **'Use dois dedos para aproximar e arraste para enquadrar.'**
  String get xv2CropHint;

  /// No description provided for @xv2CropReset.
  ///
  /// In pt, this message translates to:
  /// **'Recomeçar'**
  String get xv2CropReset;

  /// No description provided for @xv2CropConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Usar foto'**
  String get xv2CropConfirm;

  /// No description provided for @xv2GreetingMorning.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}! Bom dia'**
  String xv2GreetingMorning(String name);

  /// No description provided for @xv2GreetingAfternoon.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}! Boa tarde'**
  String xv2GreetingAfternoon(String name);

  /// No description provided for @xv2GreetingEvening.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}! Boa noite'**
  String xv2GreetingEvening(String name);

  /// No description provided for @xv2GreetingMorningNoName.
  ///
  /// In pt, this message translates to:
  /// **'Olá! Bom dia'**
  String get xv2GreetingMorningNoName;

  /// No description provided for @xv2GreetingAfternoonNoName.
  ///
  /// In pt, this message translates to:
  /// **'Olá! Boa tarde'**
  String get xv2GreetingAfternoonNoName;

  /// No description provided for @xv2GreetingEveningNoName.
  ///
  /// In pt, this message translates to:
  /// **'Olá! Boa noite'**
  String get xv2GreetingEveningNoName;

  /// No description provided for @xv2HydrationOfferTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quer lembretes para beber água?'**
  String get xv2HydrationOfferTitle;

  /// No description provided for @xv2HydrationOfferBody.
  ///
  /// In pt, this message translates to:
  /// **'Você escolhe os horários e a sua meta nos ajustes de hidratação. Dá para mudar quando quiser.'**
  String get xv2HydrationOfferBody;

  /// No description provided for @xv2HydrationOfferYes.
  ///
  /// In pt, this message translates to:
  /// **'Sim, configurar'**
  String get xv2HydrationOfferYes;

  /// No description provided for @xv2HydrationOfferNo.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get xv2HydrationOfferNo;

  /// No description provided for @xv2LibTitle.
  ///
  /// In pt, this message translates to:
  /// **'Biblioteca'**
  String get xv2LibTitle;

  /// No description provided for @xv2LibIntro.
  ///
  /// In pt, this message translates to:
  /// **'Textos gerais de fontes públicas sobre hábitos saudáveis. São iguais para todas as pessoas e não são orientação para o seu caso.'**
  String get xv2LibIntro;

  /// No description provided for @xv2LibSource.
  ///
  /// In pt, this message translates to:
  /// **'Fonte: {source}'**
  String xv2LibSource(String source);

  /// No description provided for @xv2LibReadTime.
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min de leitura'**
  String xv2LibReadTime(int minutes);

  /// No description provided for @xv2LibOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir texto'**
  String get xv2LibOpen;

  /// No description provided for @xv2LibOpenError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o link agora.'**
  String get xv2LibOpenError;

  /// No description provided for @xv2LibCatEmocoes.
  ///
  /// In pt, this message translates to:
  /// **'Emoções e humor'**
  String get xv2LibCatEmocoes;

  /// No description provided for @xv2LibCatEstresse.
  ///
  /// In pt, this message translates to:
  /// **'Estresse e descanso'**
  String get xv2LibCatEstresse;

  /// No description provided for @xv2LibCatSono.
  ///
  /// In pt, this message translates to:
  /// **'Sono'**
  String get xv2LibCatSono;

  /// No description provided for @xv2LibCatCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Corpo e movimento'**
  String get xv2LibCatCorpo;

  /// No description provided for @xv2LibCatAlimentacao.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação e digestão'**
  String get xv2LibCatAlimentacao;

  /// No description provided for @xv2LibCatHidratacao.
  ///
  /// In pt, this message translates to:
  /// **'Hidratação'**
  String get xv2LibCatHidratacao;

  /// No description provided for @xv2LibCatRelacoes.
  ///
  /// In pt, this message translates to:
  /// **'Relações e convívio'**
  String get xv2LibCatRelacoes;

  /// No description provided for @xv2LibCatAjuda.
  ///
  /// In pt, this message translates to:
  /// **'Primeiros cuidados e quando procurar ajuda'**
  String get xv2LibCatAjuda;

  /// No description provided for @xv2LibArtDesanimoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dias de desânimo e pouca energia'**
  String get xv2LibArtDesanimoTitle;

  /// No description provided for @xv2LibArtDesanimoSummary.
  ///
  /// In pt, this message translates to:
  /// **'Pequenas rotinas para dias de desânimo e onde encontrar apoio.'**
  String get xv2LibArtDesanimoSummary;

  /// No description provided for @xv2LibArtAgitacaoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Momentos de agitação: como desacelerar'**
  String get xv2LibArtAgitacaoTitle;

  /// No description provided for @xv2LibArtAgitacaoSummary.
  ///
  /// In pt, this message translates to:
  /// **'Informações gerais sobre nervosismo e pensamentos acelerados no dia a dia.'**
  String get xv2LibArtAgitacaoSummary;

  /// No description provided for @xv2LibArtTrabalhoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cansaço no trabalho e limites saudáveis'**
  String get xv2LibArtTrabalhoTitle;

  /// No description provided for @xv2LibArtTrabalhoSummary.
  ///
  /// In pt, this message translates to:
  /// **'Informações gerais sobre cansaço emocional no trabalho e pausas na rotina.'**
  String get xv2LibArtTrabalhoSummary;

  /// No description provided for @xv2LibArtRespiracaoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Respiração compassada para relaxar'**
  String get xv2LibArtRespiracaoTitle;

  /// No description provided for @xv2LibArtRespiracaoSummary.
  ///
  /// In pt, this message translates to:
  /// **'Alguns minutos de respiração tranquila podem ajudar a desacelerar em dias exigentes.'**
  String get xv2LibArtRespiracaoSummary;

  /// No description provided for @xv2LibArtSonoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hábitos para dormir melhor'**
  String get xv2LibArtSonoTitle;

  /// No description provided for @xv2LibArtSonoSummary.
  ///
  /// In pt, this message translates to:
  /// **'Horários regulares e hábitos simples que favorecem noites mais tranquilas.'**
  String get xv2LibArtSonoSummary;

  /// No description provided for @xv2LibArtBracosTitle.
  ///
  /// In pt, this message translates to:
  /// **'Braços e ombros: pausas e postura'**
  String get xv2LibArtBracosTitle;

  /// No description provided for @xv2LibArtBracosSummary.
  ///
  /// In pt, this message translates to:
  /// **'Informações gerais sobre esforço repetitivo e pausas durante o dia.'**
  String get xv2LibArtBracosSummary;

  /// No description provided for @xv2LibArtMovimentoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Movimente-se no dia a dia'**
  String get xv2LibArtMovimentoTitle;

  /// No description provided for @xv2LibArtMovimentoSummary.
  ///
  /// In pt, this message translates to:
  /// **'Orientações gerais sobre atividade física em todas as idades.'**
  String get xv2LibArtMovimentoSummary;

  /// No description provided for @xv2LibArtAlimentacaoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Guia Alimentar para a População Brasileira'**
  String get xv2LibArtAlimentacaoTitle;

  /// No description provided for @xv2LibArtAlimentacaoSummary.
  ///
  /// In pt, this message translates to:
  /// **'Princípios gerais para uma alimentação equilibrada, com comida de verdade.'**
  String get xv2LibArtAlimentacaoSummary;

  /// No description provided for @xv2LibArtAguaTitle.
  ///
  /// In pt, this message translates to:
  /// **'Água ao longo do dia'**
  String get xv2LibArtAguaTitle;

  /// No description provided for @xv2LibArtAguaSummary.
  ///
  /// In pt, this message translates to:
  /// **'Beber água ao longo do dia faz parte de hábitos de vida saudáveis.'**
  String get xv2LibArtAguaSummary;

  /// No description provided for @xv2LibArtConvivioTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bem-estar emocional e convívio'**
  String get xv2LibArtConvivioTitle;

  /// No description provided for @xv2LibArtConvivioSummary.
  ///
  /// In pt, this message translates to:
  /// **'Informações gerais sobre bem-estar emocional, relações e apoio da comunidade.'**
  String get xv2LibArtConvivioSummary;

  /// No description provided for @xv2LibArtSamuTitle.
  ///
  /// In pt, this message translates to:
  /// **'SAMU 192: como funciona'**
  String get xv2LibArtSamuTitle;

  /// No description provided for @xv2LibArtSamuSummary.
  ///
  /// In pt, this message translates to:
  /// **'O serviço móvel gratuito do SUS que atende pelo telefone 192 em todo o país.'**
  String get xv2LibArtSamuSummary;

  /// No description provided for @xv2LibArtCvvTitle.
  ///
  /// In pt, this message translates to:
  /// **'CVV 188: apoio emocional'**
  String get xv2LibArtCvvTitle;

  /// No description provided for @xv2LibArtCvvSummary.
  ///
  /// In pt, this message translates to:
  /// **'Conversa gratuita e sigilosa, 24 horas, por telefone, chat ou e-mail.'**
  String get xv2LibArtCvvSummary;

  /// No description provided for @xv2ReportedIntensity.
  ///
  /// In pt, this message translates to:
  /// **'Intensidade que você informou: {intensity}/5'**
  String xv2ReportedIntensity(int intensity);

  /// No description provided for @xv2SummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu registro de hoje'**
  String get xv2SummaryTitle;

  /// No description provided for @xv2SummarySaved.
  ///
  /// In pt, this message translates to:
  /// **'Seu registro foi salvo.'**
  String get xv2SummarySaved;

  /// No description provided for @xv2SummaryThanks.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado por registrar seu dia! 🌿 Na Biblioteca você encontra textos de fontes públicas, como o Ministério da Saúde, sobre hábitos saudáveis.'**
  String get xv2SummaryThanks;

  /// No description provided for @xv2SummaryOpenLibrary.
  ///
  /// In pt, this message translates to:
  /// **'Abrir a Biblioteca'**
  String get xv2SummaryOpenLibrary;

  /// No description provided for @xv2AdLabel.
  ///
  /// In pt, this message translates to:
  /// **'Anúncio'**
  String get xv2AdLabel;

  /// No description provided for @xv2AdLearnMore.
  ///
  /// In pt, this message translates to:
  /// **'Saiba mais'**
  String get xv2AdLearnMore;

  /// No description provided for @xv2AdPremiumTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dualis Premium'**
  String get xv2AdPremiumTitle;

  /// No description provided for @xv2AdPremiumBody.
  ///
  /// In pt, this message translates to:
  /// **'Veja seus registros de até 12 meses e escolha seus fundos. Em breve.'**
  String get xv2AdPremiumBody;

  /// No description provided for @xv2AdZocTitle.
  ///
  /// In pt, this message translates to:
  /// **'ZOC · Cadernos e agendas'**
  String get xv2AdZocTitle;

  /// No description provided for @xv2AdZocBody.
  ///
  /// In pt, this message translates to:
  /// **'Planeje a semana com calma, no papel. Exemplo de anúncio.'**
  String get xv2AdZocBody;

  /// No description provided for @xv2AdWgiTitle.
  ///
  /// In pt, this message translates to:
  /// **'WGI · Garrafas reutilizáveis'**
  String get xv2AdWgiTitle;

  /// No description provided for @xv2AdWgiBody.
  ///
  /// In pt, this message translates to:
  /// **'Leve sua água para onde for. Exemplo de anúncio.'**
  String get xv2AdWgiBody;

  /// No description provided for @xv2AdUboTitle.
  ///
  /// In pt, this message translates to:
  /// **'UBO · Playlists para relaxar'**
  String get xv2AdUboTitle;

  /// No description provided for @xv2AdUboBody.
  ///
  /// In pt, this message translates to:
  /// **'Sons de natureza para pausas no dia. Exemplo de anúncio.'**
  String get xv2AdUboBody;

  /// No description provided for @xv2DashTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get xv2DashTitle;

  /// No description provided for @xv2DashWindow.
  ///
  /// In pt, this message translates to:
  /// **'Seus registros dos últimos {days} dias'**
  String xv2DashWindow(int days);

  /// No description provided for @xv2DashRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get xv2DashRetry;

  /// No description provided for @xv2DashTimeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Passado, presente e futuro'**
  String get xv2DashTimeTitle;

  /// No description provided for @xv2DashTimeCount.
  ///
  /// In pt, this message translates to:
  /// **'{time}: {count}'**
  String xv2DashTimeCount(String time, int count);

  /// No description provided for @xv2DashNoEmotional.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro emocional neste período.'**
  String get xv2DashNoEmotional;

  /// No description provided for @xv2DashBodyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Partes do corpo que você marcou'**
  String get xv2DashBodyTitle;

  /// No description provided for @xv2DashFront.
  ///
  /// In pt, this message translates to:
  /// **'Frente'**
  String get xv2DashFront;

  /// No description provided for @xv2DashBack.
  ///
  /// In pt, this message translates to:
  /// **'Costas'**
  String get xv2DashBack;

  /// No description provided for @xv2DashRegionDays.
  ///
  /// In pt, this message translates to:
  /// **'{region}: {count, plural, =0{nenhum dia} =1{1 dia} other{{count} dias}}'**
  String xv2DashRegionDays(String region, num count);

  /// No description provided for @xv2DashLinesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Intensidade por dia'**
  String get xv2DashLinesTitle;

  /// No description provided for @xv2DashLinesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'A intensidade que você informou em cada registro (1 a 5).'**
  String get xv2DashLinesSubtitle;

  /// No description provided for @xv2DashDaysCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 dia} other{{count} dias}}'**
  String xv2DashDaysCount(num count);

  /// No description provided for @xv2DashSeeMore.
  ///
  /// In pt, this message translates to:
  /// **'Ver mais'**
  String get xv2DashSeeMore;

  /// No description provided for @xv2DashSeeLess.
  ///
  /// In pt, this message translates to:
  /// **'Ver menos'**
  String get xv2DashSeeLess;

  /// No description provided for @xv2DashNoItems.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item registrado neste período.'**
  String get xv2DashNoItems;

  /// No description provided for @xv2DashWaterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Água por dia'**
  String get xv2DashWaterTitle;

  /// No description provided for @xv2DashNoWater.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro de água neste período.'**
  String get xv2DashNoWater;

  /// No description provided for @xv2DashTogetherTitle.
  ///
  /// In pt, this message translates to:
  /// **'No mesmo dia'**
  String get xv2DashTogetherTitle;

  /// No description provided for @xv2DashCooccurrence.
  ///
  /// In pt, this message translates to:
  /// **'Nos {total} dias em que você marcou \'{a}\', também marcou \'{b}\' em {both}.'**
  String xv2DashCooccurrence(int total, String a, String b, int both);

  /// No description provided for @xv2DashEntriesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seus registros'**
  String get xv2DashEntriesTitle;

  /// No description provided for @xv2DashNoEntries.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem registros neste período.'**
  String get xv2DashNoEntries;

  /// No description provided for @xv2DashMoodLine.
  ///
  /// In pt, this message translates to:
  /// **'Como você estava: {mood}'**
  String xv2DashMoodLine(String mood);

  /// No description provided for @xv2DashDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir registro'**
  String get xv2DashDeleteTitle;

  /// No description provided for @xv2DashDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'Este registro será apagado do seu histórico.'**
  String get xv2DashDeleteBody;

  /// No description provided for @xv2DashDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get xv2DashDeleteConfirm;

  /// No description provided for @xv2WaterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hidratação 💧'**
  String get xv2WaterTitle;

  /// No description provided for @xv2WaterTodayLogs.
  ///
  /// In pt, this message translates to:
  /// **'Registros de hoje'**
  String get xv2WaterTodayLogs;

  /// No description provided for @xv2WaterHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 30 dias'**
  String get xv2WaterHistoryTitle;

  /// No description provided for @xv2WaterRemindersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes de água'**
  String get xv2WaterRemindersTitle;

  /// No description provided for @xv2WaterOther.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get xv2WaterOther;

  /// No description provided for @xv2WaterStreak.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Sequência: 0 dias} =1{Sequência: 1 dia} other{Sequência: {count} dias}}'**
  String xv2WaterStreak(num count);

  /// No description provided for @xv2WaterGoalChip.
  ///
  /// In pt, this message translates to:
  /// **'Sua meta: {ml} ml'**
  String xv2WaterGoalChip(int ml);

  /// No description provided for @xv2WaterGoalDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua meta diária'**
  String get xv2WaterGoalDialogTitle;

  /// No description provided for @xv2WaterGoalHint.
  ///
  /// In pt, this message translates to:
  /// **'Você escolhe a sua meta, entre 250 e 10000 ml.'**
  String get xv2WaterGoalHint;

  /// No description provided for @xv2WaterGoalSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get xv2WaterGoalSave;

  /// No description provided for @xv2WaterNoLogsToday.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum copo de água registrado hoje ainda.'**
  String get xv2WaterNoLogsToday;

  /// No description provided for @xv2WaterLoggedAt.
  ///
  /// In pt, this message translates to:
  /// **'Registrado às {time}'**
  String xv2WaterLoggedAt(String time);

  /// No description provided for @xv2WaterLoggedViaReminder.
  ///
  /// In pt, this message translates to:
  /// **'Registrado via lembrete das {time}'**
  String xv2WaterLoggedViaReminder(String time);

  /// No description provided for @xv2WaterDeleteLog.
  ///
  /// In pt, this message translates to:
  /// **'Excluir registro'**
  String get xv2WaterDeleteLog;

  /// No description provided for @jv2PendingSync.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando sincronizar'**
  String get jv2PendingSync;

  /// No description provided for @jv2OutboxRejectedNotice.
  ///
  /// In pt, this message translates to:
  /// **'Um registro não pôde ser enviado. Revise e tente de novo.'**
  String get jv2OutboxRejectedNotice;

  /// No description provided for @histTabEmotional.
  ///
  /// In pt, this message translates to:
  /// **'Psicoemocional'**
  String get histTabEmotional;

  /// No description provided for @histTabPhysical.
  ///
  /// In pt, this message translates to:
  /// **'Físico'**
  String get histTabPhysical;

  /// No description provided for @histPeriodDays.
  ///
  /// In pt, this message translates to:
  /// **'{days} dias'**
  String histPeriodDays(int days);

  /// No description provided for @histEmotionalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seus últimos {days} dias'**
  String histEmotionalTitle(int days);

  /// No description provided for @histPhysicalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Últimos {days} dias'**
  String histPhysicalTitle(int days);

  /// No description provided for @histIntensitySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Intensidade que você marcou, de 1 a 5'**
  String get histIntensitySubtitle;

  /// No description provided for @histChipHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque num chip para mostrar ou esconder a linha.'**
  String get histChipHint;

  /// No description provided for @histLineShown.
  ///
  /// In pt, this message translates to:
  /// **'{label}, linha visível'**
  String histLineShown(String label);

  /// No description provided for @histLineHidden.
  ///
  /// In pt, this message translates to:
  /// **'{label}, linha escondida'**
  String histLineHidden(String label);

  /// No description provided for @histOverlayChip.
  ///
  /// In pt, this message translates to:
  /// **'+ {label}'**
  String histOverlayChip(String label);

  /// No description provided for @histTimeBarTitle.
  ///
  /// In pt, this message translates to:
  /// **'Passado · Presente · Futuro'**
  String get histTimeBarTitle;

  /// No description provided for @histViewMap.
  ///
  /// In pt, this message translates to:
  /// **'Mapa'**
  String get histViewMap;

  /// No description provided for @histViewLinks.
  ///
  /// In pt, this message translates to:
  /// **'Conexões'**
  String get histViewLinks;

  /// No description provided for @histMapCaption.
  ///
  /// In pt, this message translates to:
  /// **'Cor = quantos dias você marcou. Toque numa parte do corpo para ver a linha do tempo.'**
  String get histMapCaption;

  /// No description provided for @histNoPhysical.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma parte do corpo marcada neste período.'**
  String get histNoPhysical;

  /// No description provided for @histLinksTop.
  ///
  /// In pt, this message translates to:
  /// **'Mesmo dia: {time} e {region} em {count, plural, =1{1 dia} other{{count} dias}}. Só contagem.'**
  String histLinksTop(String time, String region, int count);

  /// No description provided for @histLinksEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há dias com registro de tempo emocional e de corpo juntos neste período.'**
  String get histLinksEmpty;

  /// No description provided for @histTimelineTitle.
  ///
  /// In pt, this message translates to:
  /// **'Linha do tempo'**
  String get histTimelineTitle;

  /// No description provided for @histEmotionalTitleWeek.
  ///
  /// In pt, this message translates to:
  /// **'Como foi sua semana'**
  String get histEmotionalTitleWeek;

  /// No description provided for @histPhysicalTitleWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get histPhysicalTitleWeek;

  /// No description provided for @histPhysicalTitleMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get histPhysicalTitleMonth;

  /// No description provided for @histRegionHeadline.
  ///
  /// In pt, this message translates to:
  /// **'Nos últimos {period} dias você marcou {region} {count, plural, =1{1 vez} other{{count} vezes}}, em {days, plural, =1{1 dia} other{{days} dias}}.'**
  String histRegionHeadline(int period, String region, num count, num days);

  /// No description provided for @histRegionSensationTimes.
  ///
  /// In pt, this message translates to:
  /// **'{sensation}: {count, plural, =1{1 vez} other{{count} vezes}}'**
  String histRegionSensationTimes(String sensation, num count);

  /// No description provided for @histRegionMarksTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cada vez que você marcou'**
  String get histRegionMarksTitle;

  /// No description provided for @histRegionIntensity.
  ///
  /// In pt, this message translates to:
  /// **'Intensidade {value} de 5'**
  String histRegionIntensity(int value);

  /// No description provided for @histRegionEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Você não marcou esta parte do corpo neste período.'**
  String get histRegionEmpty;

  /// No description provided for @careHubTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meus cuidados'**
  String get careHubTitle;

  /// No description provided for @careHubToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get careHubToday;

  /// No description provided for @careHubNoRemindersToday.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum lembrete hoje'**
  String get careHubNoRemindersToday;

  /// No description provided for @careHubRemindersToday.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 lembrete hoje} other{{count} lembretes hoje}}'**
  String careHubRemindersToday(int count);

  /// No description provided for @careHubNext.
  ///
  /// In pt, this message translates to:
  /// **'Próximo: {name} · {time}'**
  String careHubNext(String name, String time);

  /// No description provided for @careHubVaccinesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhuma dose registrada} =1{1 dose registrada} other{{count} doses registradas}}'**
  String careHubVaccinesSubtitle(int count);

  /// No description provided for @careHubNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma informada'**
  String get careHubNone;

  /// No description provided for @careHubMedsActive.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum ativo} =1{1 ativo} other{{count} ativos}}'**
  String careHubMedsActive(int count);

  /// No description provided for @careHubLowStock.
  ///
  /// In pt, this message translates to:
  /// **'estoque baixo em {count}'**
  String careHubLowStock(int count);

  /// No description provided for @careHubNoUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma consulta marcada'**
  String get careHubNoUpcoming;

  /// No description provided for @careHubNextAppointment.
  ///
  /// In pt, this message translates to:
  /// **'Próxima: {date} · {who}'**
  String careHubNextAppointment(String date, String who);

  /// No description provided for @careHubDocuments.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum documento} =1{1 documento guardado} other{{count} documentos guardados}}'**
  String careHubDocuments(int count);

  /// No description provided for @careHubSummarySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'PDF para levar à consulta, se você quiser'**
  String get careHubSummarySubtitle;

  /// No description provided for @careVaccinesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vacinas'**
  String get careVaccinesTitle;

  /// No description provided for @careAllergiesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alergias informadas'**
  String get careAllergiesTitle;

  /// No description provided for @careMedicationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Medicamentos e lembretes'**
  String get careMedicationsTitle;

  /// No description provided for @careAppointmentsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Consultas'**
  String get careAppointmentsTitle;

  /// No description provided for @careExamsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exames'**
  String get careExamsTitle;

  /// No description provided for @careSummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo dos meus registros'**
  String get careSummaryTitle;

  /// No description provided for @careLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar. Verifique sua conexão.'**
  String get careLoadError;

  /// No description provided for @careRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get careRetry;

  /// No description provided for @careSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get careSave;

  /// No description provided for @careSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar. Tente de novo.'**
  String get careSaveError;

  /// No description provided for @careFillRequired.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os campos obrigatórios.'**
  String get careFillRequired;

  /// No description provided for @careCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get careCancel;

  /// No description provided for @careDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get careDelete;

  /// No description provided for @careDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar este registro?'**
  String get careDeleteTitle;

  /// No description provided for @careDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'Ele será removido deste perfil.'**
  String get careDeleteBody;

  /// No description provided for @careDays.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias'**
  String careDays(int count);

  /// No description provided for @careMon.
  ///
  /// In pt, this message translates to:
  /// **'Seg'**
  String get careMon;

  /// No description provided for @careTue.
  ///
  /// In pt, this message translates to:
  /// **'Ter'**
  String get careTue;

  /// No description provided for @careWed.
  ///
  /// In pt, this message translates to:
  /// **'Qua'**
  String get careWed;

  /// No description provided for @careThu.
  ///
  /// In pt, this message translates to:
  /// **'Qui'**
  String get careThu;

  /// No description provided for @careFri.
  ///
  /// In pt, this message translates to:
  /// **'Sex'**
  String get careFri;

  /// No description provided for @careSat.
  ///
  /// In pt, this message translates to:
  /// **'Sáb'**
  String get careSat;

  /// No description provided for @careSun.
  ///
  /// In pt, this message translates to:
  /// **'Dom'**
  String get careSun;

  /// No description provided for @careVaccineRegister.
  ///
  /// In pt, this message translates to:
  /// **'Registrar dose'**
  String get careVaccineRegister;

  /// No description provided for @careVaccineEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar dose'**
  String get careVaccineEdit;

  /// No description provided for @careVaccineTabCalendar.
  ///
  /// In pt, this message translates to:
  /// **'Calendário oficial'**
  String get careVaccineTabCalendar;

  /// No description provided for @careVaccineTabMine.
  ///
  /// In pt, this message translates to:
  /// **'Minhas doses'**
  String get careVaccineTabMine;

  /// No description provided for @careVaccineCalendarNote.
  ///
  /// In pt, this message translates to:
  /// **'{source} (Brasil), mostrado como publicado. Tire dúvidas na sua UBS ou com quem vacina você.'**
  String careVaccineCalendarNote(String source);

  /// No description provided for @carePniChild.
  ///
  /// In pt, this message translates to:
  /// **'Criança'**
  String get carePniChild;

  /// No description provided for @carePniTeen.
  ///
  /// In pt, this message translates to:
  /// **'Adolescente'**
  String get carePniTeen;

  /// No description provided for @carePniAdult.
  ///
  /// In pt, this message translates to:
  /// **'Adulto'**
  String get carePniAdult;

  /// No description provided for @carePniElderly.
  ///
  /// In pt, this message translates to:
  /// **'60+'**
  String get carePniElderly;

  /// No description provided for @carePniPregnant.
  ///
  /// In pt, this message translates to:
  /// **'Gestante'**
  String get carePniPregnant;

  /// No description provided for @careVaccineByCampaign.
  ///
  /// In pt, this message translates to:
  /// **'Conforme campanha vigente'**
  String get careVaccineByCampaign;

  /// No description provided for @careVaccineDosesInCalendar.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Dose única no calendário} other{{count} doses no calendário}}'**
  String careVaccineDosesInCalendar(int count);

  /// No description provided for @careVaccineBoosterEvery.
  ///
  /// In pt, this message translates to:
  /// **'Reforço a cada {years, plural, =1{ano} other{{years} anos}} no calendário'**
  String careVaccineBoosterEvery(int years);

  /// No description provided for @careVaccineLastDose.
  ///
  /// In pt, this message translates to:
  /// **'Sua última dose registrada: {date}'**
  String careVaccineLastDose(String date);

  /// No description provided for @careVaccineNoRecord.
  ///
  /// In pt, this message translates to:
  /// **'Sem registro'**
  String get careVaccineNoRecord;

  /// No description provided for @careVaccineCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} de {total}'**
  String careVaccineCount(int count, int total);

  /// No description provided for @careVaccineCountOnly.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 dose} other{{count} doses}}'**
  String careVaccineCountOnly(int count);

  /// No description provided for @careVaccineOfficialLink.
  ///
  /// In pt, this message translates to:
  /// **'Ver o calendário completo (gov.br)'**
  String get careVaccineOfficialLink;

  /// No description provided for @careVaccineEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma dose registrada ainda.'**
  String get careVaccineEmpty;

  /// No description provided for @careVaccineBatch.
  ///
  /// In pt, this message translates to:
  /// **'Lote {batch}'**
  String careVaccineBatch(String batch);

  /// No description provided for @careVaccineBoosterReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete de reforço: {date}'**
  String careVaccineBoosterReminder(String date);

  /// No description provided for @careDose1.
  ///
  /// In pt, this message translates to:
  /// **'1ª dose'**
  String get careDose1;

  /// No description provided for @careDose2.
  ///
  /// In pt, this message translates to:
  /// **'2ª dose'**
  String get careDose2;

  /// No description provided for @careDose3.
  ///
  /// In pt, this message translates to:
  /// **'3ª dose'**
  String get careDose3;

  /// No description provided for @careDoseBooster.
  ///
  /// In pt, this message translates to:
  /// **'Reforço'**
  String get careDoseBooster;

  /// No description provided for @careDoseSingle.
  ///
  /// In pt, this message translates to:
  /// **'Dose única'**
  String get careDoseSingle;

  /// No description provided for @careDoseYearly.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get careDoseYearly;

  /// No description provided for @careVaccineField.
  ///
  /// In pt, this message translates to:
  /// **'Vacina'**
  String get careVaccineField;

  /// No description provided for @careVaccineCustom.
  ///
  /// In pt, this message translates to:
  /// **'Outra (particular)'**
  String get careVaccineCustom;

  /// No description provided for @careVaccineCustomName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da vacina'**
  String get careVaccineCustomName;

  /// No description provided for @careVaccineAppliedOn.
  ///
  /// In pt, this message translates to:
  /// **'Data da aplicação'**
  String get careVaccineAppliedOn;

  /// No description provided for @careVaccineBatchField.
  ///
  /// In pt, this message translates to:
  /// **'Lote (opcional)'**
  String get careVaccineBatchField;

  /// No description provided for @careVaccinePlace.
  ///
  /// In pt, this message translates to:
  /// **'Onde (opcional)'**
  String get careVaccinePlace;

  /// No description provided for @careVaccineReceipt.
  ///
  /// In pt, this message translates to:
  /// **'Comprovante de vacina'**
  String get careVaccineReceipt;

  /// No description provided for @careVaccineReceiptAdd.
  ///
  /// In pt, this message translates to:
  /// **'Foto do comprovante'**
  String get careVaccineReceiptAdd;

  /// No description provided for @careVaccineReceiptSaved.
  ///
  /// In pt, this message translates to:
  /// **'Comprovante guardado'**
  String get careVaccineReceiptSaved;

  /// No description provided for @careVaccineReceiptHint.
  ///
  /// In pt, this message translates to:
  /// **'Fica guardada só no seu registro'**
  String get careVaccineReceiptHint;

  /// No description provided for @careVaccineRemindBooster.
  ///
  /// In pt, this message translates to:
  /// **'Lembrar do próximo reforço'**
  String get careVaccineRemindBooster;

  /// No description provided for @careVaccineBoosterDate.
  ///
  /// In pt, this message translates to:
  /// **'Data do lembrete'**
  String get careVaccineBoosterDate;

  /// No description provided for @careVaccineBoosterHint.
  ///
  /// In pt, this message translates to:
  /// **'A data vem do intervalo publicado no calendário oficial ({years, plural, =1{1 ano} other{{years} anos}}). Você pode mudar.'**
  String careVaccineBoosterHint(int years);

  /// No description provided for @careVaccineBoosterHintNone.
  ///
  /// In pt, this message translates to:
  /// **'O calendário não traz intervalo para esta vacina. Escolha a data que quiser.'**
  String get careVaccineBoosterHintNone;

  /// No description provided for @careAllergiesIntro.
  ///
  /// In pt, this message translates to:
  /// **'O que você já sabe que causa reação em você. Aparece no seu perfil e no resumo em PDF.'**
  String get careAllergiesIntro;

  /// No description provided for @careAllergiesNoCrossCheck.
  ///
  /// In pt, this message translates to:
  /// **'O Dualis guarda o que você escreve. Ele não verifica se um medicamento combina com suas alergias. Confirme sempre com quem receita ou com a farmácia.'**
  String get careAllergiesNoCrossCheck;

  /// No description provided for @careAllergiesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma alergia informada.'**
  String get careAllergiesEmpty;

  /// No description provided for @careAllergyAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar alergia'**
  String get careAllergyAdd;

  /// No description provided for @careAllergyEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar alergia'**
  String get careAllergyEdit;

  /// No description provided for @careAllergyMedication.
  ///
  /// In pt, this message translates to:
  /// **'Medicamentos'**
  String get careAllergyMedication;

  /// No description provided for @careAllergyFood.
  ///
  /// In pt, this message translates to:
  /// **'Alimentos'**
  String get careAllergyFood;

  /// No description provided for @careAllergyOther.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get careAllergyOther;

  /// No description provided for @careAllergyName.
  ///
  /// In pt, this message translates to:
  /// **'Nome (como você conhece)'**
  String get careAllergyName;

  /// No description provided for @careAllergyReaction.
  ///
  /// In pt, this message translates to:
  /// **'Reação, com suas palavras (opcional)'**
  String get careAllergyReaction;

  /// No description provided for @careAllergyReactionShown.
  ///
  /// In pt, this message translates to:
  /// **'Reação que você informou: \"{reaction}\"'**
  String careAllergyReactionShown(String reaction);

  /// No description provided for @careAllergyInformedOn.
  ///
  /// In pt, this message translates to:
  /// **'Informado em {date}'**
  String careAllergyInformedOn(String date);

  /// No description provided for @careAllergyInformedField.
  ///
  /// In pt, this message translates to:
  /// **'Desde quando (opcional)'**
  String get careAllergyInformedField;

  /// No description provided for @careAllergyOnProfile.
  ///
  /// In pt, this message translates to:
  /// **'Mostrada no cartão de perfil'**
  String get careAllergyOnProfile;

  /// No description provided for @careAllergyShowOnProfile.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar no cartão de perfil'**
  String get careAllergyShowOnProfile;

  /// No description provided for @careAllergyShowOnProfileHint.
  ///
  /// In pt, this message translates to:
  /// **'Visível para quem você compartilhar o perfil'**
  String get careAllergyShowOnProfileHint;

  /// No description provided for @careMedicationAdd.
  ///
  /// In pt, this message translates to:
  /// **'Medicamento'**
  String get careMedicationAdd;

  /// No description provided for @careMedicationEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar medicamento'**
  String get careMedicationEdit;

  /// No description provided for @careMedTabToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get careMedTabToday;

  /// No description provided for @careMedTabAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get careMedTabAll;

  /// No description provided for @careMedEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum medicamento cadastrado.'**
  String get careMedEmpty;

  /// No description provided for @careMedNoneToday.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum horário para hoje.'**
  String get careMedNoneToday;

  /// No description provided for @careMedMorning.
  ///
  /// In pt, this message translates to:
  /// **'Manhã'**
  String get careMedMorning;

  /// No description provided for @careMedAfternoon.
  ///
  /// In pt, this message translates to:
  /// **'Tarde'**
  String get careMedAfternoon;

  /// No description provided for @careMedNight.
  ///
  /// In pt, this message translates to:
  /// **'Noite'**
  String get careMedNight;

  /// No description provided for @careMedNote.
  ///
  /// In pt, this message translates to:
  /// **'Horários e quantidades são os que você configurou, conforme sua receita. O Dualis não sugere nem altera doses.'**
  String get careMedNote;

  /// No description provided for @careMedStockTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estoque: {name}'**
  String careMedStockTitle(String name);

  /// No description provided for @careMedStockBody.
  ///
  /// In pt, this message translates to:
  /// **'Restam {count}. Você pediu aviso com {warnAt}.'**
  String careMedStockBody(int count, int warnAt);

  /// No description provided for @careMedStockLeft.
  ///
  /// In pt, this message translates to:
  /// **'Estoque: {count}'**
  String careMedStockLeft(int count);

  /// No description provided for @careMedNoTimes.
  ///
  /// In pt, this message translates to:
  /// **'Sem horários'**
  String get careMedNoTimes;

  /// No description provided for @careMedPaused.
  ///
  /// In pt, this message translates to:
  /// **'Pausado'**
  String get careMedPaused;

  /// No description provided for @careMedTaken.
  ///
  /// In pt, this message translates to:
  /// **'Tomei'**
  String get careMedTaken;

  /// No description provided for @careMedSnooze.
  ///
  /// In pt, this message translates to:
  /// **'Adiar 15 min'**
  String get careMedSnooze;

  /// No description provided for @careMedSkip.
  ///
  /// In pt, this message translates to:
  /// **'Pulei'**
  String get careMedSkip;

  /// No description provided for @careMedTakenAt.
  ///
  /// In pt, this message translates to:
  /// **'tomado {time}'**
  String careMedTakenAt(String time);

  /// No description provided for @careMedSkipped.
  ///
  /// In pt, this message translates to:
  /// **'não tomado'**
  String get careMedSkipped;

  /// No description provided for @careMedSnoozed.
  ///
  /// In pt, this message translates to:
  /// **'adiado'**
  String get careMedSnoozed;

  /// No description provided for @careMedFromPrescriptionNote.
  ///
  /// In pt, this message translates to:
  /// **'Preenchido com o que foi lido na receita. Confira tudo e escolha os horários.'**
  String get careMedFromPrescriptionNote;

  /// No description provided for @careMedName.
  ///
  /// In pt, this message translates to:
  /// **'Nome (como está na receita ou na caixa)'**
  String get careMedName;

  /// No description provided for @careMedStrength.
  ///
  /// In pt, this message translates to:
  /// **'Concentração'**
  String get careMedStrength;

  /// No description provided for @careMedForm.
  ///
  /// In pt, this message translates to:
  /// **'Forma'**
  String get careMedForm;

  /// No description provided for @careMedAmount.
  ///
  /// In pt, this message translates to:
  /// **'Quanto tomar por vez (da sua receita)'**
  String get careMedAmount;

  /// No description provided for @careMedInstructions.
  ///
  /// In pt, this message translates to:
  /// **'Como está escrito na receita (opcional)'**
  String get careMedInstructions;

  /// No description provided for @careMedTimes.
  ///
  /// In pt, this message translates to:
  /// **'Horários'**
  String get careMedTimes;

  /// No description provided for @careMedAddTime.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get careMedAddTime;

  /// No description provided for @careMedTimesRequired.
  ///
  /// In pt, this message translates to:
  /// **'Escolha pelo menos um horário.'**
  String get careMedTimesRequired;

  /// No description provided for @careMedDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias'**
  String get careMedDays;

  /// No description provided for @careMedEveryDay.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dias'**
  String get careMedEveryDay;

  /// No description provided for @careMedUntil.
  ///
  /// In pt, this message translates to:
  /// **'Até quando (opcional)'**
  String get careMedUntil;

  /// No description provided for @careMedStockSection.
  ///
  /// In pt, this message translates to:
  /// **'Estoque (opcional)'**
  String get careMedStockSection;

  /// No description provided for @careMedStockHave.
  ///
  /// In pt, this message translates to:
  /// **'Tenho em casa'**
  String get careMedStockHave;

  /// No description provided for @careMedStockPerIntake.
  ///
  /// In pt, this message translates to:
  /// **'Usa por vez'**
  String get careMedStockPerIntake;

  /// No description provided for @careMedStockWarn.
  ///
  /// In pt, this message translates to:
  /// **'Avisar com'**
  String get careMedStockWarn;

  /// No description provided for @careMedBula.
  ///
  /// In pt, this message translates to:
  /// **'Bula oficial'**
  String get careMedBula;

  /// No description provided for @careMedBulaHint.
  ///
  /// In pt, this message translates to:
  /// **'Abre o Bulário Eletrônico da ANVISA'**
  String get careMedBulaHint;

  /// No description provided for @careMedBulaNeedsName.
  ///
  /// In pt, this message translates to:
  /// **'Escreva o nome do medicamento primeiro.'**
  String get careMedBulaNeedsName;

  /// No description provided for @careMedActive.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes ativos'**
  String get careMedActive;

  /// No description provided for @careMedSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar lembretes'**
  String get careMedSave;

  /// No description provided for @careAppointmentAdd.
  ///
  /// In pt, this message translates to:
  /// **'Consulta'**
  String get careAppointmentAdd;

  /// No description provided for @careAppointmentEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar consulta'**
  String get careAppointmentEdit;

  /// No description provided for @careAppointmentEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma consulta registrada.'**
  String get careAppointmentEmpty;

  /// No description provided for @careAppointmentUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Próximas'**
  String get careAppointmentUpcoming;

  /// No description provided for @careAppointmentPast.
  ///
  /// In pt, this message translates to:
  /// **'Anteriores'**
  String get careAppointmentPast;

  /// No description provided for @careAppointmentTitleFallback.
  ///
  /// In pt, this message translates to:
  /// **'Consulta'**
  String get careAppointmentTitleFallback;

  /// No description provided for @careAppointmentQuestions.
  ///
  /// In pt, this message translates to:
  /// **'Perguntas que quero fazer'**
  String get careAppointmentQuestions;

  /// No description provided for @careAppointmentNotes.
  ///
  /// In pt, this message translates to:
  /// **'Minhas anotações'**
  String get careAppointmentNotes;

  /// No description provided for @careAppointmentDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get careAppointmentDate;

  /// No description provided for @careAppointmentTime.
  ///
  /// In pt, this message translates to:
  /// **'Hora'**
  String get careAppointmentTime;

  /// No description provided for @careAppointmentProfessional.
  ///
  /// In pt, this message translates to:
  /// **'Profissional (opcional)'**
  String get careAppointmentProfessional;

  /// No description provided for @careAppointmentSpecialty.
  ///
  /// In pt, this message translates to:
  /// **'Especialidade'**
  String get careAppointmentSpecialty;

  /// No description provided for @careAppointmentPlace.
  ///
  /// In pt, this message translates to:
  /// **'Local'**
  String get careAppointmentPlace;

  /// No description provided for @careAppointmentReminderNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem lembrete'**
  String get careAppointmentReminderNone;

  /// No description provided for @careAppointmentReminder1d.
  ///
  /// In pt, this message translates to:
  /// **'1 dia antes'**
  String get careAppointmentReminder1d;

  /// No description provided for @careAppointmentReminder2h.
  ///
  /// In pt, this message translates to:
  /// **'2 horas antes'**
  String get careAppointmentReminder2h;

  /// No description provided for @careSectionJournal.
  ///
  /// In pt, this message translates to:
  /// **'Diário'**
  String get careSectionJournal;

  /// No description provided for @careSectionConditions.
  ///
  /// In pt, this message translates to:
  /// **'Condições'**
  String get careSectionConditions;

  /// No description provided for @careSectionMedications.
  ///
  /// In pt, this message translates to:
  /// **'Medicamentos'**
  String get careSectionMedications;

  /// No description provided for @careSectionAllergies.
  ///
  /// In pt, this message translates to:
  /// **'Alergias'**
  String get careSectionAllergies;

  /// No description provided for @careSectionVaccines.
  ///
  /// In pt, this message translates to:
  /// **'Vacinas'**
  String get careSectionVaccines;

  /// No description provided for @careSectionExams.
  ///
  /// In pt, this message translates to:
  /// **'Exames'**
  String get careSectionExams;

  /// No description provided for @careSectionNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get careSectionNotes;

  /// No description provided for @careSummaryInclude.
  ///
  /// In pt, this message translates to:
  /// **'Incluir'**
  String get careSummaryInclude;

  /// No description provided for @careSummaryJournal.
  ///
  /// In pt, this message translates to:
  /// **'Registros do diário ({count})'**
  String careSummaryJournal(int count);

  /// No description provided for @careSummaryConditions.
  ///
  /// In pt, this message translates to:
  /// **'Minhas condições (informadas por você)'**
  String get careSummaryConditions;

  /// No description provided for @careSummaryMedications.
  ///
  /// In pt, this message translates to:
  /// **'Medicamentos e horários'**
  String get careSummaryMedications;

  /// No description provided for @careSummaryNotes.
  ///
  /// In pt, this message translates to:
  /// **'Minhas notas'**
  String get careSummaryNotes;

  /// No description provided for @careSummaryIntensity.
  ///
  /// In pt, this message translates to:
  /// **'intensidade informada {value}/5'**
  String careSummaryIntensity(int value);

  /// No description provided for @careSummaryTaken.
  ///
  /// In pt, this message translates to:
  /// **'{taken} de {marked} marcados como tomados'**
  String careSummaryTaken(int taken, int marked);

  /// No description provided for @careSummaryReference.
  ///
  /// In pt, this message translates to:
  /// **'referência impressa: {text}'**
  String careSummaryReference(String text);

  /// No description provided for @careSummaryNothing.
  ///
  /// In pt, this message translates to:
  /// **'Nada registrado no período.'**
  String get careSummaryNothing;

  /// No description provided for @careSummaryMore.
  ///
  /// In pt, this message translates to:
  /// **'+ {count} no PDF'**
  String careSummaryMore(int count);

  /// No description provided for @careSummaryHeader.
  ///
  /// In pt, this message translates to:
  /// **'{name} · {from} a {to} · gerado pela própria pessoa'**
  String careSummaryHeader(String name, String from, String to);

  /// No description provided for @careSummaryFooter.
  ///
  /// In pt, this message translates to:
  /// **'Este documento reúne apenas o que a pessoa registrou. Não contém avaliação nem recomendação.'**
  String get careSummaryFooter;

  /// No description provided for @careSummaryShare.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar PDF'**
  String get careSummaryShare;

  /// No description provided for @careSummaryPrivacy.
  ///
  /// In pt, this message translates to:
  /// **'O PDF é criado no seu celular. Você decide com quem compartilhar.'**
  String get careSummaryPrivacy;

  /// No description provided for @careExamAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar exame'**
  String get careExamAdd;

  /// No description provided for @careExamFromCamera.
  ///
  /// In pt, this message translates to:
  /// **'Tirar foto'**
  String get careExamFromCamera;

  /// No description provided for @careExamFromGallery.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da galeria'**
  String get careExamFromGallery;

  /// No description provided for @careExamFromPdf.
  ///
  /// In pt, this message translates to:
  /// **'Escolher PDF'**
  String get careExamFromPdf;

  /// No description provided for @careExamWhatIsIt.
  ///
  /// In pt, this message translates to:
  /// **'O que é este documento?'**
  String get careExamWhatIsIt;

  /// No description provided for @careExamKindLab.
  ///
  /// In pt, this message translates to:
  /// **'Exame de laboratório'**
  String get careExamKindLab;

  /// No description provided for @careExamKindLabHint.
  ///
  /// In pt, this message translates to:
  /// **'Lemos os valores para você conferir'**
  String get careExamKindLabHint;

  /// No description provided for @careExamKindPrescription.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get careExamKindPrescription;

  /// No description provided for @careExamKindPrescriptionHint.
  ///
  /// In pt, this message translates to:
  /// **'Lemos nome e instruções para você conferir'**
  String get careExamKindPrescriptionHint;

  /// No description provided for @careExamKindArchive.
  ///
  /// In pt, this message translates to:
  /// **'Só arquivar'**
  String get careExamKindArchive;

  /// No description provided for @careExamKindArchiveHint.
  ///
  /// In pt, this message translates to:
  /// **'Guarda o arquivo sem ler'**
  String get careExamKindArchiveHint;

  /// No description provided for @careExamTooLarge.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo passa de 10 MB.'**
  String get careExamTooLarge;

  /// No description provided for @careExamReading.
  ///
  /// In pt, this message translates to:
  /// **'Lendo seu documento…'**
  String get careExamReading;

  /// No description provided for @careExamReadingHint.
  ///
  /// In pt, this message translates to:
  /// **'Leva até 1 minuto. Você pode sair desta tela.'**
  String get careExamReadingHint;

  /// No description provided for @careExamEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum documento guardado.'**
  String get careExamEmpty;

  /// No description provided for @careExamSectionLabs.
  ///
  /// In pt, this message translates to:
  /// **'Exames'**
  String get careExamSectionLabs;

  /// No description provided for @careExamSectionPrescriptions.
  ///
  /// In pt, this message translates to:
  /// **'Receitas'**
  String get careExamSectionPrescriptions;

  /// No description provided for @careExamSectionOther.
  ///
  /// In pt, this message translates to:
  /// **'Outros arquivos'**
  String get careExamSectionOther;

  /// No description provided for @careExamValuesOverTime.
  ///
  /// In pt, this message translates to:
  /// **'Meus valores ao longo do tempo'**
  String get careExamValuesOverTime;

  /// No description provided for @careExamNote.
  ///
  /// In pt, this message translates to:
  /// **'Os valores e as referências são os do laudo. O Dualis não diz se um resultado está bom ou ruim. Leve suas dúvidas a quem pediu o exame.'**
  String get careExamNote;

  /// No description provided for @careExamToCheck.
  ///
  /// In pt, this message translates to:
  /// **'Conferir {count}'**
  String careExamToCheck(int count);

  /// No description provided for @careExamCheck.
  ///
  /// In pt, this message translates to:
  /// **'Conferir'**
  String get careExamCheck;

  /// No description provided for @careExamChecked.
  ///
  /// In pt, this message translates to:
  /// **'Conferido'**
  String get careExamChecked;

  /// No description provided for @careExamReadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não lido'**
  String get careExamReadFailed;

  /// No description provided for @careExamArchived.
  ///
  /// In pt, this message translates to:
  /// **'Arquivado'**
  String get careExamArchived;

  /// No description provided for @careExamReviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conferir valores'**
  String get careExamReviewTitle;

  /// No description provided for @careExamSeeOriginal.
  ///
  /// In pt, this message translates to:
  /// **'Ver documento original'**
  String get careExamSeeOriginal;

  /// No description provided for @careExamCompareHint.
  ///
  /// In pt, this message translates to:
  /// **'Compare com o papel. Toque numa linha para corrigir.'**
  String get careExamCompareHint;

  /// No description provided for @careExamArchivedHint.
  ///
  /// In pt, this message translates to:
  /// **'Guardado sem leitura.'**
  String get careExamArchivedHint;

  /// No description provided for @careExamFailedHint.
  ///
  /// In pt, this message translates to:
  /// **'Não conseguimos ler este arquivo. Você pode digitar os valores ou tentar outra foto, com boa luz e o papel inteiro.'**
  String get careExamFailedHint;

  /// No description provided for @careExamTitleField.
  ///
  /// In pt, this message translates to:
  /// **'Nome do exame'**
  String get careExamTitleField;

  /// No description provided for @careExamLab.
  ///
  /// In pt, this message translates to:
  /// **'Laboratório'**
  String get careExamLab;

  /// No description provided for @careExamCollected.
  ///
  /// In pt, this message translates to:
  /// **'Data da coleta'**
  String get careExamCollected;

  /// No description provided for @careExamItem.
  ///
  /// In pt, this message translates to:
  /// **'Item'**
  String get careExamItem;

  /// No description provided for @careExamValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get careExamValue;

  /// No description provided for @careExamUnit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get careExamUnit;

  /// No description provided for @careExamDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get careExamDate;

  /// No description provided for @careExamReference.
  ///
  /// In pt, this message translates to:
  /// **'Referência impressa no laudo'**
  String get careExamReference;

  /// No description provided for @careExamReferencePrinted.
  ///
  /// In pt, this message translates to:
  /// **'Referência impressa'**
  String get careExamReferencePrinted;

  /// No description provided for @careExamNoRows.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum valor lido. Adicione as linhas que quiser guardar.'**
  String get careExamNoRows;

  /// No description provided for @careExamAddRow.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar linha'**
  String get careExamAddRow;

  /// No description provided for @careExamEditRow.
  ///
  /// In pt, this message translates to:
  /// **'Corrigir linha'**
  String get careExamEditRow;

  /// No description provided for @careExamRowSave.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar linha'**
  String get careExamRowSave;

  /// No description provided for @careExamRowRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover linha'**
  String get careExamRowRemove;

  /// No description provided for @careExamSavePending.
  ///
  /// In pt, this message translates to:
  /// **'Salvar (faltam {count, plural, =1{1 conferência} other{{count} conferências}})'**
  String careExamSavePending(int count);

  /// No description provided for @careExamSaved.
  ///
  /// In pt, this message translates to:
  /// **'Valores guardados.'**
  String get careExamSaved;

  /// No description provided for @careExamItemIntro.
  ///
  /// In pt, this message translates to:
  /// **'Valores que você conferiu, do mais recente ao mais antigo. A referência é a que cada laboratório imprimiu.'**
  String get careExamItemIntro;

  /// No description provided for @careReadConsentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ler documentos com o Google'**
  String get careReadConsentTitle;

  /// No description provided for @careReadConsentBody.
  ///
  /// In pt, this message translates to:
  /// **'Para ler a foto ou o PDF, o arquivo é enviado ao Google Cloud Vision, que extrai o texto em servidores nos Estados Unidos ou na União Europeia. Depois, a Gemini (região São Paulo) organiza esse texto, sem seu nome nem CPF. O Google não usa esses dados para treinar modelos.\n\nIsso é uma transferência internacional de dados de saúde (LGPD Art. 33; RGPD Art. 46). Você pode recusar e usar \"Só arquivar\" ou digitar os valores. Pode retirar este consentimento na Central de Privacidade.'**
  String get careReadConsentBody;

  /// No description provided for @careReadConsentAccept.
  ///
  /// In pt, this message translates to:
  /// **'Concordo'**
  String get careReadConsentAccept;

  /// No description provided for @careReadConsentDecline.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get careReadConsentDecline;

  /// No description provided for @careRxTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conferir receita'**
  String get careRxTitle;

  /// No description provided for @careRxCompareHint.
  ///
  /// In pt, this message translates to:
  /// **'Compare com a receita. Toque num campo para corrigir.'**
  String get careRxCompareHint;

  /// No description provided for @careRxNothingRead.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum medicamento lido.'**
  String get careRxNothingRead;

  /// No description provided for @careRxName.
  ///
  /// In pt, this message translates to:
  /// **'Nome lido'**
  String get careRxName;

  /// No description provided for @careRxStrength.
  ///
  /// In pt, this message translates to:
  /// **'Concentração lida'**
  String get careRxStrength;

  /// No description provided for @careRxInstructions.
  ///
  /// In pt, this message translates to:
  /// **'Como tomar (texto da receita)'**
  String get careRxInstructions;

  /// No description provided for @careRxEditField.
  ///
  /// In pt, this message translates to:
  /// **'Corrigir campo'**
  String get careRxEditField;

  /// No description provided for @careRxFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'{field, select, name{Nome} strength{Concentração} other{Como tomar}}'**
  String careRxFieldLabel(String field);

  /// No description provided for @careRxTimesYouChoose.
  ///
  /// In pt, this message translates to:
  /// **'Os horários você escolhe no próximo passo.'**
  String get careRxTimesYouChoose;

  /// No description provided for @careRxCheckFirst.
  ///
  /// In pt, this message translates to:
  /// **'Confira todos os campos'**
  String get careRxCheckFirst;

  /// No description provided for @careRxCreateReminder.
  ///
  /// In pt, this message translates to:
  /// **'Criar lembrete'**
  String get careRxCreateReminder;

  /// No description provided for @careRxReminderCreated.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete criado'**
  String get careRxReminderCreated;

  /// No description provided for @careRxNote.
  ///
  /// In pt, this message translates to:
  /// **'O Dualis copia o texto da receita. Ele não transforma \"12/12h\" em horários nem cria lembretes sozinho.'**
  String get careRxNote;

  /// No description provided for @careNotifChannelName.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes de cuidados'**
  String get careNotifChannelName;

  /// No description provided for @careNotifChannelDescription.
  ///
  /// In pt, this message translates to:
  /// **'Horários de medicamentos, consultas e reforços de vacina que você configurou.'**
  String get careNotifChannelDescription;

  /// No description provided for @careNotifMedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hora do seu lembrete'**
  String get careNotifMedTitle;

  /// No description provided for @careNotifAppointmentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete de consulta'**
  String get careNotifAppointmentTitle;

  /// No description provided for @careNotifAppointmentBody.
  ///
  /// In pt, this message translates to:
  /// **'{who} às {time}'**
  String careNotifAppointmentBody(String who, String time);

  /// No description provided for @careNotifBoosterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete de vacina'**
  String get careNotifBoosterTitle;

  /// No description provided for @careNotifBoosterBody.
  ///
  /// In pt, this message translates to:
  /// **'Data que você escolheu para o reforço: {name}'**
  String careNotifBoosterBody(String name);
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
