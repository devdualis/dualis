// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'DualisCheckUp';

  @override
  String get screen1PrimaryCta => 'Crear Cuenta';

  @override
  String get screen1SecondaryCta => 'Iniciar Sesión';

  @override
  String get screen2PrimaryCta => 'Finalizar Registro';

  @override
  String get valueCard1Title => 'Triaje Preventivo Unificado';

  @override
  String get valueCard1Body =>
      'Conecte su salud física y estado psico-emocional en un único flujo diario inteligente.';

  @override
  String get valueCard2Title => 'Historial Médico Blindado';

  @override
  String get valueCard2Body =>
      'Su historial clínico protegido por cifrado AES-256 y custodiado bajo la LGPD.';

  @override
  String get valueCard3Title => 'Orientaciones Preventivas Precisas';

  @override
  String get valueCard3Body =>
      'Recomendaciones y artículos de especialistas médicos de renombre sin diagnósticos falsos.';

  @override
  String get lgpdConsentCheckbox =>
      'He leído y acepto la Política de Privacidad y consiento expresamente el tratamiento de mis datos personales sensibles de salud conforme al Art. 11 de la LGPD.';

  @override
  String get privacyVeilTitle => 'Datos de Salud Protegidos';

  @override
  String get privacyVeilBody =>
      'Autentíquese con biometría o contraseña para acceder.';

  @override
  String get formErrorName => 'Por favor, ingrese su nombre completo.';

  @override
  String get formErrorEmail => 'Ingrese un correo electrónico válido.';

  @override
  String get formErrorPassword =>
      'La contraseña debe tener al menos 8 caracteres con mayúscula, minúscula, número y símbolo.';

  @override
  String get fullName => 'Nombre Completo';

  @override
  String get birthDate => 'Fecha de Nacimiento';

  @override
  String get biologicalSex => 'Sexo Biológico';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get sexMale => 'Masculino';

  @override
  String get sexFemale => 'Femenino';

  @override
  String get sexOther => 'Otro';

  @override
  String get language => 'Idioma';

  @override
  String get portuguese => 'Portugués';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'Inglés';
}
