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

  @override
  String get emergencyTitle => 'Alerta de Riesgo Inmediato';

  @override
  String get emergencySubtitle =>
      'Síntomas graves identificados. Busque atención médica urgente.';

  @override
  String get emergencyBadgeChestPain => 'Dolor Torácico Crítico';

  @override
  String get emergencyBadgeRespiratory => 'Dificultad Respiratoria Aguda';

  @override
  String get emergencyBadgeStroke => 'Sospecha de Déficit Neurológico (ACV)';

  @override
  String get emergencyBadgeHeadache => 'Cefalea Súbita y Explosiva';

  @override
  String get emergencyBadgeEmotional =>
      'Apoyo Emocional Inmediato / Riesgo Vital';

  @override
  String get emergencyBadgeGeneral => 'Síntoma Crítico (Nivel 4–5)';

  @override
  String get emergencyInstructionPhysical1 =>
      'Interrumpa cualquier esfuerzo físico y permanezca en reposo.';

  @override
  String get emergencyInstructionPhysical2 =>
      'No conduzca al hospital. Llame al 192 o pida ayuda a un acompañante.';

  @override
  String get emergencyInstructionPhysical3 =>
      'Afloje la ropa ajustada e intente mantener la calma mientras espera la ayuda.';

  @override
  String get emergencyInstructionEmotional1 =>
      'No estás solo/a. Hay ayuda especializada y confidencial disponible ahora mismo.';

  @override
  String get emergencyInstructionEmotional2 =>
      'El CVV ofrece apoyo emocional gratuito las 24 horas a través del teléfono 188.';

  @override
  String get emergencyInstructionEmotional3 =>
      'Si siente que está en peligro inmediato, llame al 192 o acuda a una sala de emergencias.';

  @override
  String get emergencyCallSamu => 'Llamar SAMU (192)';

  @override
  String get emergencyCallBombeiros => 'Llamar Bomberos (193)';

  @override
  String get emergencyCallCvv => 'Llamar CVV - Apoyo Emocional (188)';

  @override
  String get emergencyCallPolicia => 'Llamar Policía (190)';

  @override
  String get emergencyFindHospital => 'Buscar Sala de Urgencias Cercana';

  @override
  String get emergencyDispatcherHint =>
      'Al llamar, informe su dirección con claridad y mantenga la calma.';

  @override
  String get emergencyExitButton => 'Volver al Inicio (No recomendado)';

  @override
  String get emergencyExitConfirmTitle => 'Atención Médica Urgente';

  @override
  String get emergencyExitConfirmBody =>
      'Sus síntomas indican una situación de riesgo vital. Le recomendamos encarecidamente que contacte con un servicio médico antes de salir. ¿Desea realmente volver al inicio?';

  @override
  String get emergencyExitConfirmStay => 'Permanecer en Emergencia';

  @override
  String get emergencyExitConfirmLeave => 'Entendido / Salir';

  @override
  String get emergencyFallbackTitle => 'Dispositivo sin Marcador';

  @override
  String get emergencyFallbackBody =>
      'Este dispositivo no soporta llamadas directas. Marque manualmente el siguiente número en otro teléfono:';

  @override
  String get emergencyCopyNumber => 'Copiar Número';

  @override
  String get emergencyCopiedToast => 'Número copiado al portapapeles.';
}
