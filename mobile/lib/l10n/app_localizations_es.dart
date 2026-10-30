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
  String get valueCard1Title => 'Diario de Bienestar Integrado';

  @override
  String get valueCard1Body =>
      'Registra cómo estás en el cuerpo y en las emociones en un único check-in diario de 1 minuto.';

  @override
  String get valueCard2Title => 'Tus Datos Protegidos';

  @override
  String get valueCard2Body =>
      'Tus registros de bienestar están cifrados y bajo tu control, conforme a la LGPD.';

  @override
  String get valueCard3Title => 'Contenidos para Hábitos Saludables';

  @override
  String get valueCard3Body =>
      'Lecturas breves y generales sobre sueño, estrés, postura, hidratación y más.';

  @override
  String get lgpdConsentCheckbox =>
      'He leído y acepto la Política de Privacidad y consiento, de forma específica y destacada, el tratamiento de mis datos personales sensibles de salud para registrar y ver mi diario de bienestar, conforme al Art. 11, I de la LGPD.';

  @override
  String get privacyVeilTitle => 'Datos de Salud Protegidos';

  @override
  String get privacyVeilBody =>
      'Autentícate con biometría o contraseña para acceder a tus registros.';

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
  String get emergencyTitle => '¿Necesitas ayuda ahora?';

  @override
  String get emergencySubtitle =>
      'Si tú o alguien cerca de ti está en peligro, llama a emergencias. No esperes.';

  @override
  String get emergencyFindHospital => 'Buscar urgencias más cercanas';

  @override
  String get emergencyDispatcherHint =>
      'Al llamar, informe su dirección con claridad y mantenga la calma.';

  @override
  String get emergencyFallbackTitle => 'Dispositivo sin Marcador';

  @override
  String get emergencyFallbackBody =>
      'Este dispositivo no soporta llamadas directas. Marque manualmente el siguiente número en otro teléfono:';

  @override
  String get emergencyCopyNumber => 'Copiar Número';

  @override
  String get emergencyCopiedToast => 'Número copiado al portapapeles.';

  @override
  String get outcomeIntensityTitle => 'Intensidad que informaste';

  @override
  String get outcomeIntensityDescription =>
      'Tu propia nota del 1 al 5 sobre cómo te sentiste';

  @override
  String get outcomeArticlesTitle => 'Lecturas sobre bienestar';

  @override
  String get outcomeArticlesSubtitle =>
      'Contenidos educativos generales. No son orientación para tu caso.';

  @override
  String get offlineBannerText =>
      'Modo Offline — Tus registros se guardarán localmente y se sincronizarán automáticamente.';

  @override
  String offlineSyncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros pendientes de sincronización',
      one: '1 registro pendiente de sincronización',
    );
    return '$_temp0';
  }

  @override
  String get offlineSyncSuccessText => 'Sincronización completada con éxito.';

  @override
  String get offlineModeNotice =>
      'Estás sin conexión. Tus registros siguen funcionando normalmente.';

  @override
  String get historyScreenTitle => 'Historial y Tendencias';

  @override
  String get tabEmotional => 'Psicoemocional';

  @override
  String get tabPhysical => 'Física';

  @override
  String get heatLegendNone => 'Sin registro';

  @override
  String get heatLegendMild => 'Leve (1-2)';

  @override
  String get heatLegendModerate => 'Moderada (3)';

  @override
  String get heatLegendSevere => 'Intensa (4-5)';

  @override
  String get emotionalChartTitle => 'Evolución Emocional (7 Días)';

  @override
  String get retrospectiveFeedTitle => 'Registros Anteriores';

  @override
  String get emptyHistoryTitle => 'Sin registros aún';

  @override
  String get emptyHistorySubtitle =>
      'Tus chequeos diarios completados aparecerán aquí.';

  @override
  String get readRecommendedArticle => 'Leer artículo';

  @override
  String get privacyCenterTitle => 'Privacidad y Datos (LGPD)';

  @override
  String get exportDataTitle => 'Exportación de Datos';

  @override
  String get exportDataDesc =>
      'Descarga una copia completa de tus datos personales y registros de bienestar en formato JSON según el Art. 18, V de la LGPD.';

  @override
  String get exportDataButton => 'Exportar Datos (JSON)';

  @override
  String get exportSuccessMessage => 'Datos exportados con éxito.';

  @override
  String get deleteAccountTitle => 'Eliminación Permanente de Cuenta';

  @override
  String get deleteAccountDesc =>
      'Elimina definitivamente tu cuenta y todos los registros de salud según el Art. 18 de la LGPD. Esta acción no se puede deshacer.';

  @override
  String get deleteAccountButton => 'Eliminar Mi Cuenta';

  @override
  String get deleteConfirmTitle => 'Confirmar Eliminación Definitiva';

  @override
  String get deleteConfirmDesc =>
      'Para confirmar la eliminación irreversible de tu cuenta y todos los datos de salud, ingresa tu contraseña:';

  @override
  String get deleteSuccessMessage => 'Cuenta y datos eliminados con éxito.';

  @override
  String get confirmPermanentDeletion => 'Confirmar Eliminación Irreversible';

  @override
  String get enterPassword => 'Tu contraseña';

  @override
  String get previewDataTitle => 'Vista Previa de Datos Exportados';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get profileSection => 'Perfil e Identificación';

  @override
  String get changeAvatar => 'Cambiar Foto';

  @override
  String get selectAvatar => 'Elige tu Avatar';

  @override
  String get nameLabel => 'Nombre Completo';

  @override
  String get dateOfBirthLabel => 'Fecha de Nacimiento';

  @override
  String get ageLabel => 'Edad';

  @override
  String yearsOld(int age) {
    return '$age años';
  }

  @override
  String get saveProfile => 'Guardar Cambios';

  @override
  String get profileUpdatedSuccess => '¡Perfil actualizado con éxito!';

  @override
  String get securitySection => 'Seguridad y Acceso';

  @override
  String get changePassword => 'Cambiar Contraseña';

  @override
  String get currentPassword => 'Contraseña Actual';

  @override
  String get newPassword => 'Nueva Contraseña';

  @override
  String get confirmNewPassword => 'Confirmar Nueva Contraseña';

  @override
  String get currentPasswordHint => 'Ingresa tu contraseña actual';

  @override
  String get newPasswordHint => 'Nueva contraseña segura';

  @override
  String get confirmPasswordHint => 'Repite la nueva contraseña';

  @override
  String get passwordChangedSuccess => '¡Contraseña cambiada con éxito!';

  @override
  String get passwordsDoNotMatch => 'Las nuevas contraseñas no coinciden.';

  @override
  String get passwordComplexityHint =>
      'Mínimo de 8 caracteres, con mayúscula, minúscula, número y símbolo.';

  @override
  String get forgotPasswordTitle => '¿Olvidaste tu contraseña?';

  @override
  String get forgotPasswordSubtitle =>
      'Ingresa el correo vinculado a tu cuenta y te enviaremos un código para restablecer tu contraseña.';

  @override
  String get forgotPasswordSendCta => 'Enviar Código';

  @override
  String get forgotPasswordSuccessMessage =>
      'Si ese correo está registrado, te enviamos un código de restablecimiento.';

  @override
  String get forgotPasswordBackToLogin => 'Volver al Inicio de Sesión';

  @override
  String get resetPasswordTitle => 'Restablece tu contraseña';

  @override
  String get resetPasswordSubtitle =>
      'Ingresa el código que te enviamos y elige una nueva contraseña.';

  @override
  String get resetPasswordCodeLabel => 'Código de Verificación';

  @override
  String get resetPasswordCodeHint => 'Código de 6 dígitos';

  @override
  String get resetPasswordCodeRequired => 'Ingresa el código de 6 dígitos';

  @override
  String get resetPasswordSubmitCta => 'Restablecer Contraseña';

  @override
  String get resetPasswordSuccessMessage =>
      'Tu contraseña fue restablecida. Ya puedes iniciar sesión.';

  @override
  String get privacyShortcut => 'Centro de Privacidad y LGPD';

  @override
  String get logoutButton => 'Cerrar Sesión';

  @override
  String get settingsLanguageSection => 'Idioma de la Aplicación';

  @override
  String get settingsLanguagePortuguese => 'Português (Brasil)';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsPrivacySection => 'Privacidad y Datos';

  @override
  String get settingsPrivacyCenterTile => 'Centro de Privacidad y LGPD';

  @override
  String get settingsPrivacyCenterSubtitle =>
      'Accede y gestiona tus datos de salud';

  @override
  String get settingsDataHistoryTile => 'Historial y Tendencias';

  @override
  String get settingsDataHistorySubtitle =>
      'Visualiza tu historial de registros';

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get errorNetworkConnection =>
      'No se pudo conectar con el servidor. Verifica tu conexión a internet.';

  @override
  String get errorConnectionTimeout =>
      'La comunicación con el servidor tardó demasiado. Intenta nuevamente.';

  @override
  String get errorInvalidCredentials =>
      'Correo o contraseña incorrectos. Por favor, verifica tus credenciales.';

  @override
  String get errorEmailAlreadyExists =>
      'Este correo electrónico ya está registrado en nuestra plataforma.';

  @override
  String get errorSessionExpired =>
      'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';

  @override
  String get errorEmailVerificationCodeInvalid =>
      'Código de verificación incorrecto o expirado. Verifica los dígitos o solicita un nuevo código.';

  @override
  String get loginEmailNotVerified =>
      'Tu correo aún no está verificado. Ingresa el código enviado o solicita uno nuevo.';

  @override
  String get emailVerificationSuccess =>
      '¡Correo electrónico verificado con éxito! Bienvenido a DualisCheckUp.';

  @override
  String get newCodeSentSuccess =>
      'Nuevo código enviado a tu correo electrónico.';

  @override
  String get errorUpdateProfile =>
      'No se pudo actualizar el perfil. Intenta nuevamente.';

  @override
  String get errorChangePassword =>
      'No se pudo cambiar la contraseña. Verifica tu contraseña actual.';

  @override
  String get errorCameraGalleryAccess =>
      'No se pudo acceder a la cámara o galería del dispositivo.';

  @override
  String get errorFieldRequired => 'Este campo es obligatorio.';

  @override
  String get errorCurrentPasswordRequired => 'Ingresa tu contraseña actual.';

  @override
  String get errorNewPasswordMinLength =>
      'La nueva contraseña debe tener al menos 8 caracteres.';

  @override
  String get errorPasswordLettersAndDigits =>
      'La contraseña debe contener letras y números.';

  @override
  String get errorNameMinLength =>
      'El nombre debe tener al menos 2 caracteres.';

  @override
  String get selectDateOfBirthHint => 'Selecciona tu fecha de nacimiento';

  @override
  String get errorLoadHistory =>
      'No se pudo cargar el historial de registros en este momento.';

  @override
  String get errorArticleLinkUnavailable =>
      'Enlace del artículo no disponible.';

  @override
  String get errorUnableToOpenLink => 'No se pudo abrir el enlace solicitado.';

  @override
  String get errorServerInternal =>
      'Nuestros servicios experimentan una inestabilidad temporal. Intenta nuevamente en unos instantes.';

  @override
  String get errorUnexpected =>
      'Ocurrió una inestabilidad inesperada. Por favor, intenta de nuevo.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navHistory => 'Historial y Mapa';

  @override
  String get navHydration => 'Agua';

  @override
  String get notifWaterTitle => '💧 Hora de beber agua';

  @override
  String notifWaterTitleAt(String time) {
    return '💧 Hora de beber agua ($time)';
  }

  @override
  String get notifWaterBodyTracking =>
      'Toca para registrar la cantidad de agua consumida.';

  @override
  String get notifWaterBodyReminder =>
      '¡Mantén tu cuerpo hidratado y saludable!';

  @override
  String get notifWaterChimeChannelName =>
      'Recordatorios de agua (aviso suave)';

  @override
  String get notifWaterChimeChannelDescription =>
      'Aviso tipo mensaje para recordarte que te hidrates';

  @override
  String get notifWaterAlarmChannelName =>
      'Recordatorios de agua (alarma sonora)';

  @override
  String get notifWaterAlarmChannelDescription =>
      'Alarma sonora para recordarte beber agua cada 2 horas';

  @override
  String notifCheckinTitleAt(String time) {
    return '🌿 Check-in diario Dualis ($time)';
  }

  @override
  String get notifCheckinBody =>
      'Aún no hiciste tu registro de hoy. ¡Toca para hacer tu check-in!';

  @override
  String get notifCheckinChannelName => 'Recordatorios de check-in diario';

  @override
  String get notifCheckinChannelDescription =>
      'Notificaciones cada 2 horas para recordarte tu check-in diario de bienestar';

  @override
  String get outcomeAxisPhysicalNumbered => '1. Eje de Evaluación Física';

  @override
  String get outcomeAxisEmotionalNumbered =>
      '2. Eje de Evaluación Psicoemocional';

  @override
  String get familySharingTitle => 'Compartir en familia';

  @override
  String get familySharingTabOutgoing => 'Quién ve mis datos';

  @override
  String get familySharingTabIncoming => 'Compartidos conmigo';

  @override
  String get familySharingUnavailableTitle => 'Función aún no disponible';

  @override
  String get familySharingUnavailableBody =>
      'Compartir en familia llegará en una próxima versión de DualisCheckUp.';

  @override
  String get familySharingInviteButton => 'Invitar a un familiar o acompañante';

  @override
  String get familySharingEnterCodeButton =>
      '¿Tienes un código de invitación? Ingresar y aceptar';

  @override
  String get familySharingEmptyOutgoing =>
      'Nadie tiene acceso a tus datos en este momento.';

  @override
  String get familySharingEmptyIncoming =>
      'Ningún familiar ha compartido datos contigo todavía.';

  @override
  String get familySharingScopeViewOnly => 'Solo lectura';

  @override
  String get familySharingScopeCoManage => 'Cogestión';

  @override
  String get familySharingScopeViewOnlyOption => 'Solo lectura (recomendado)';

  @override
  String get familySharingScopeCoManageOption =>
      'Cogestión (puede añadir registros)';

  @override
  String familySharingActiveSince(String date) {
    return 'Activo desde $date';
  }

  @override
  String get familySharingActive => 'Acceso activo';

  @override
  String familySharingPendingUntil(String code, String date) {
    return 'Código $code · pendiente de aceptación hasta $date';
  }

  @override
  String get familySharingExpired => 'Invitación vencida';

  @override
  String get familySharingRevokeButton => 'Revocar acceso';

  @override
  String get familySharingRevokeConfirmTitle => '¿Revocar acceso?';

  @override
  String get familySharingRevokeConfirmBody =>
      '¿Estás seguro? El acceso se interrumpirá de inmediato.';

  @override
  String get familySharingCancel => 'Cancelar';

  @override
  String get familySharingRevoked => 'Acceso revocado.';

  @override
  String get familySharingRevokeError =>
      'No se pudo revocar el acceso. Inténtalo de nuevo.';

  @override
  String get familySharingInviteTitle => 'Invitar a un familiar o acompañante';

  @override
  String get familySharingInviteProfileLabel => 'Perfil a compartir';

  @override
  String get familySharingInviteScopeLabel => 'Permiso';

  @override
  String get familySharingInviteGenerate => 'Generar código';

  @override
  String get familySharingInviteError =>
      'No se pudo crear la invitación. Inténtalo de nuevo.';

  @override
  String get familySharingInviteCodeHint =>
      'Envía este código a tu familiar. Vence en 72 horas.';

  @override
  String familySharingInviteDeadline(String date) {
    return 'Válido hasta $date';
  }

  @override
  String get familySharingCopyCode => 'Copiar código';

  @override
  String get familySharingCodeCopied => 'Código copiado.';

  @override
  String get familySharingDone => 'Listo';

  @override
  String get familySharingAcceptTitle => 'Ingresar código de invitación';

  @override
  String get familySharingAcceptFieldLabel => 'Código de 6 caracteres';

  @override
  String get familySharingAcceptSubmit => 'Aceptar invitación';

  @override
  String get familySharingAcceptError => 'Código inválido o vencido.';

  @override
  String get familySharingAccepted =>
      'Invitación aceptada. El perfil ya aparece en tu lista.';

  @override
  String get addDependentTitle => 'Registrar dependiente legal';

  @override
  String get addDependentNameLabel => 'Nombre completo del dependiente';

  @override
  String get addDependentDobLabel => 'Fecha de nacimiento';

  @override
  String get addDependentDobHint => 'Toca para seleccionar';

  @override
  String get addDependentDobPickerHelp => 'Selecciona la fecha de nacimiento';

  @override
  String get addDependentDobInvalid =>
      'Ingresa una fecha de nacimiento válida.';

  @override
  String get addDependentDobFuture =>
      'La fecha de nacimiento no puede ser futura.';

  @override
  String get addDependentRelationshipLabel =>
      'Grado de parentesco / representación';

  @override
  String get addDependentRelationshipHint => 'Selecciona el vínculo legal';

  @override
  String get addDependentRelationshipParent =>
      'Hijo(a) menor (patria potestad)';

  @override
  String get addDependentRelationshipCurator =>
      'Curador(a) de mayor incapaz (curatela)';

  @override
  String get addDependentRelationshipLegalGuardian =>
      'Tutor(a) legal de menor (tutela)';

  @override
  String get addDependentLgpdArt14Consent =>
      'Declaro, bajo pena de ley, que soy padre, madre o representante legal de este dependiente y autorizo expresamente la recopilación y el tratamiento de sus datos de bienestar en la plataforma DualisCheckUp, en estricta conformidad con el Artículo 14 de la LGPD (Ley 13.709/2018).';

  @override
  String get addDependentSubmit => 'Registrar dependiente';

  @override
  String get addDependentSuccess => 'Dependiente registrado con éxito.';

  @override
  String get addDependentGenericError =>
      'No se pudo registrar el dependiente. Inténtalo de nuevo.';

  @override
  String get profileSwitcherSheetTitle => 'Perfiles';

  @override
  String get profileSwitcherMyProfile => 'Mi Perfil';

  @override
  String get profileSwitcherDependents => 'Mis Dependientes (Tutela Legal)';

  @override
  String get profileSwitcherShared => 'Perfiles Compartidos (Opcional)';

  @override
  String get profileSwitcherAddDependent => '+ Añadir Dependiente Legal';

  @override
  String get profileSwitcherManageSharing =>
      'Administrar Compartición Familiar';

  @override
  String get profileSwitcherRenameTitle => 'Renombrar Perfil';

  @override
  String get profileSwitcherRenameLabel => 'Nombre del perfil';

  @override
  String get profileSwitcherRenameSave => 'Guardar';

  @override
  String get profileSwitcherRenameCancel => 'Cancelar';

  @override
  String get profileSwitcherDeleteTitle => '¿Eliminar Perfil?';

  @override
  String profileSwitcherDeleteConfirm(String name) {
    return '¿Está seguro de eliminar el perfil \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String get profileSwitcherDeleteAction => 'Eliminar';

  @override
  String get profileSwitcherClose => 'Cerrar';

  @override
  String get profileSwitcherBadgeMinor => 'Menor de edad';

  @override
  String get profileSwitcherBadgeAdult => 'Adulto dependiente';

  @override
  String get profileSwitcherBadgeViewOnly => 'Solo lectura';

  @override
  String get profileSwitcherBadgeCoManage => 'Co-gestión';

  @override
  String get profileSwitcherBadgePrimary => 'Titular';

  @override
  String get profileSwitcherNoDependents => 'Ningún dependiente registrado.';

  @override
  String get profileSwitcherNoShared => 'Ningún perfil compartido contigo.';

  @override
  String get profileSwitcherActionError =>
      'No se pudo completar la acción. Inténtalo de nuevo.';

  @override
  String get familySharingCancelInvite => 'Cancelar invitación';

  @override
  String activeProfileBannerDataOf(String profileName) {
    return 'Mostrando datos de $profileName';
  }

  @override
  String get activeProfileBannerSwitchToMine => 'Mi perfil';

  @override
  String get activeProfileReadOnlyNote => 'Solo lectura';

  @override
  String activeProfileCardTitle(String profileName) {
    return 'Perfil de $profileName';
  }

  @override
  String get emergencyMapsQuery => 'urgencias hospital';

  @override
  String get safetyClose => 'Cerrar';

  @override
  String safetyCallLine(String name, String number) {
    return 'Llamar a $name ($number)';
  }

  @override
  String get safetyKindEmergency => 'Emergencias';

  @override
  String get safetyKindAmbulance => 'Ambulancia';

  @override
  String get safetyKindFire => 'Bomberos';

  @override
  String get safetyKindPolice => 'Policía';

  @override
  String get safetyKindEmotionalSupport => 'Apoyo emocional';

  @override
  String get safetyKindHealthLine => 'Línea de salud';

  @override
  String get safetyFree24h => '24 h, gratuito';

  @override
  String safetyWarningSignsTitle(String number) {
    return 'Llama al $number de inmediato si tú o alguien tiene:';
  }

  @override
  String get safetyWarningSign1 => 'dolor o presión fuerte en el pecho';

  @override
  String get safetyWarningSign2 => 'falta de aire intensa';

  @override
  String get safetyWarningSign3 =>
      'cara torcida, debilidad en un lado del cuerpo o habla arrastrada';

  @override
  String get safetyWarningSign4 =>
      'el peor dolor de cabeza de la vida, de inicio súbito';

  @override
  String get safetyWarningSign5 => 'desmayo o convulsión';

  @override
  String get safetyWarningSign6 => 'sangrado que no se detiene';

  @override
  String get safetyWarningSignsSource =>
      'Fuente: Ministério da Saúde (Brasil) / SAMU';

  @override
  String safetyCrisisWithLine(String crisis, String emergency) {
    return 'Si estás pensando en hacerte daño o en quitarte la vida, llama al $crisis o al $emergency.';
  }

  @override
  String safetyCrisisNoLine(String emergency) {
    return 'Si estás pensando en hacerte daño o en quitarte la vida, llama al $emergency o busca la línea de apoyo emocional de tu país.';
  }

  @override
  String safetyLocalNumberHint(String number) {
    return 'Si el $number no funciona donde estás, llama al número local de emergencias.';
  }

  @override
  String get urgentHelpButton => 'Ayuda urgente';

  @override
  String get lgpdConsentPrefix => 'He leído y acepto los ';

  @override
  String get lgpdConsentTermsLink => 'Términos de Uso';

  @override
  String get lgpdConsentAnd => ' y la ';

  @override
  String get lgpdConsentPrivacyLink => 'Política de Privacidad';

  @override
  String get lgpdConsentSuffix =>
      ', y consiento, de forma específica y destacada, el tratamiento de mis datos personales sensibles de salud para registrar y ver mi diario de bienestar, conforme al Art. 11, I de la LGPD. ';

  @override
  String get lgpdConsentLearnMore => '(Más información)';

  @override
  String get lgpdConsentSheetTitle =>
      'Política de Privacidad y Consentimiento (LGPD Art. 11, I)';

  @override
  String get lgpdConsentSheetBody =>
      'DualisCheckUp es una aplicación de bienestar y autoconocimiento. Te ayuda a registrar a diario cómo te sientes física y emocionalmente, seguir hábitos como la hidratación y el sueño, ver tus propios registros a lo largo del tiempo y acceder a contenidos educativos generales sobre hábitos saludables. DualisCheckUp no es un dispositivo médico: no evalúa, no clasifica ni interpreta síntomas, no indica niveles de urgencia, no realiza diagnósticos, no recomienda tratamientos y no sustituye a un profesional de la salud. En caso de emergencia, llama al número de emergencias local. Si estás pasando por un momento de angustia emocional, contacta con la línea de crisis de tu país.';

  @override
  String get lgpdConsentSheetBasesTitle => 'Bases normativas:';

  @override
  String get lgpdConsentSheetBases =>
      '• Ley nº 13.709/2018 (LGPD): Art. 7 y Art. 11 (tratamiento de datos personales y de datos sensibles de salud), Art. 14 (datos de niños y adolescentes) y Art. 18 (derechos del titular).\n• Código de Defensa del Consumidor (CDC): Art. 49 - Derecho de retracto en 7 días.';

  @override
  String get lgpdConsentViewTerms => 'Ver Términos de Uso';

  @override
  String get lgpdConsentViewPolicy => 'Ver Política Completa';

  @override
  String get termsAppBarTitle => 'Términos de Uso del SaaS';

  @override
  String get termsHeaderTitle => 'Términos y Condiciones de Uso';

  @override
  String get termsVersionLine => 'Versión 2026.2 • Actualizado el 16/10/2026';

  @override
  String get termsIntro =>
      'Contrato de prestación de servicios de software en la nube (SaaS) celebrado entre el Usuario y WGI (Brothers Baum Ltda.), inscrita en el CNPJ con el nº 30.889.282/0001-90, con sede en Arandu 57, Ed. Itaverá, 12º andar, Brooklin, São Paulo - SP, CEP 04562-031, Brasil.';

  @override
  String get termsSection1Title => '1. Aceptación y Capacidad Legal';

  @override
  String get termsSection1Body =>
      'Al registrarte o utilizar DualisCheckUp, declaras tener plena capacidad legal (mayor de 18 años o emancipado) y aceptas íntegramente estos Términos de Uso y nuestra Política de Privacidad.';

  @override
  String get termsSection2Title => '2. Naturaleza del Servicio';

  @override
  String get termsSection2Body =>
      'DualisCheckUp es una aplicación de bienestar y autoconocimiento. Te ayuda a registrar a diario cómo te sientes física y emocionalmente, seguir hábitos como la hidratación y el sueño, ver tus propios registros a lo largo del tiempo y acceder a contenidos educativos generales sobre hábitos saludables. DualisCheckUp no es un dispositivo médico: no evalúa, no clasifica ni interpreta síntomas, no indica niveles de urgencia, no realiza diagnósticos, no recomienda tratamientos y no sustituye a un profesional de la salud. En caso de emergencia, llama al número de emergencias local. Si estás pasando por un momento de angustia emocional, contacta con la línea de crisis de tu país.';

  @override
  String get termsSection2Bullet1 =>
      'No evalúa síntomas, no indica urgencia, no diagnostica y no recomienda tratamientos.';

  @override
  String get termsSection2Bullet2 =>
      'Las intensidades y la información que se muestran son las que tú mismo registraste.';

  @override
  String get termsSection2Bullet3 =>
      'En una emergencia en Brasil, llama al 192 (SAMU) o al 188 (CVV); en otros países, al número de emergencias local.';

  @override
  String get termsSection3Title => '3. Planes SaaS, Facturación y Reembolsos';

  @override
  String get termsSection3Body =>
      'Las funciones adicionales pueden ofrecerse en planes con renovación automática periódica, procesados por intermediarios de pago externos:';

  @override
  String get termsSection3Bullet1 =>
      'Cancelación Sencilla: Puedes cancelar tu suscripción en cualquier momento desde la app con un toque, sin permanencia ni cargos por cancelación.';

  @override
  String get termsSection3Bullet2 =>
      'Derecho de Retracto (CDC Art. 49): Reembolso íntegro garantizado dentro de los 7 (siete) días corridos desde la contratación inicial.';

  @override
  String get termsSection3Bullet3 =>
      'Acceso Continuo: La cancelación detiene las facturas siguientes y mantiene tu acceso hasta el final del ciclo mensual contratado.';

  @override
  String get termsSection4Title => '4. Propiedad Intelectual';

  @override
  String get termsSection4Body =>
      'Todos los derechos de propiedad intelectual sobre el software, los contenidos, las marcas y las interfaces pertenecen exclusivamente a WGI (Brothers Baum Ltda.) Queda estrictamente prohibida la reproducción, la ingeniería inversa o la extracción de datos.';

  @override
  String get termsSection5Title => '5. Suspensión por Violación de Seguridad';

  @override
  String get termsSection5Body =>
      'Las cuentas que realicen intentos de intrusión, ataques de fuerza bruta, pruebas de penetración no autorizadas o envíen datos fraudulentos serán bloqueadas de inmediato y comunicadas a las autoridades competentes.';

  @override
  String get termsSection6Title => '6. Jurisdicción y Contacto Legal';

  @override
  String get termsSection6Body =>
      'Estos términos se rigen por las leyes brasileñas. Se elige el Foro de la Comarca de São Paulo/SP como único competente para resolver los litigios derivados de este contrato.\n\nPara dudas o notificaciones legales: contato@dualischeckup.com.';

  @override
  String get privacyPolicyAppBarTitle => 'Política de Privacidad (LGPD)';

  @override
  String get privacyPolicyHeaderTitle =>
      'Política de Privacidad y Protección de Datos';

  @override
  String get privacyPolicyHeaderSubtitle =>
      'Conformidad con la Ley General de Protección de Datos de Brasil (LGPD - Ley nº 13.709/2018)';

  @override
  String get privacyPolicyIntro =>
      'Tu privacidad y la confidencialidad de tus datos de salud son nuestra prioridad absoluta. Esta política describe cómo tratamos y protegemos tu información y cómo mantienes el control total sobre ella.';

  @override
  String get privacyPolicyDpoLine =>
      'Encargado de Protección de Datos (DPO): contato@dualischeckup.com';

  @override
  String get privacyPolicySection1Title =>
      '1. Datos Personales y Sensibles que Recolectamos';

  @override
  String get privacyPolicySection1Body =>
      'Conforme el Artículo 11 de la LGPD, los datos personales sensibles de salud se tratan con tu consentimiento específico y destacado (Art. 11, I):';

  @override
  String get privacyPolicySection1Bullet1 =>
      'Datos de Identificación: Nombre completo, correo electrónico y fecha de nacimiento.';

  @override
  String get privacyPolicySection1Bullet2 =>
      'Datos de Perfil: Sexo biológico y consumo de agua, usados para ajustar tus metas de hidratación.';

  @override
  String get privacyPolicySection1Bullet3 =>
      'Diario de Bienestar: Anotaciones sobre cómo te sientes física y emocionalmente y la intensidad que informas.';

  @override
  String get privacyPolicySection1Bullet4 =>
      'Datos de Acceso Técnico: Dirección IP enmascarada, registros criptográficos de sesión y tokens de autenticación temporales.';

  @override
  String get privacyPolicySection2Title =>
      '2. Finalidades y Prohibición de Venta de Datos';

  @override
  String get privacyPolicySection2Body =>
      'Tus datos de salud se tratan únicamente para:';

  @override
  String get privacyPolicySection2Bullet1 =>
      'Registro y visualización de tu diario de bienestar.';

  @override
  String get privacyPolicySection2Bullet2 =>
      'Sugerir, con ayuda de IA, una opción ya existente del diario cuando escribes con tus palabras (sin evaluación de salud).';

  @override
  String get privacyPolicySection2Bullet3 => 'Consistencia del historial.';

  @override
  String get privacyPolicySection2Bullet4 =>
      'Compromiso Ético: Queda expresamente PROHIBIDA la venta, comercialización o cesión onerosa de tus datos a aseguradoras, anunciantes o terceros.';

  @override
  String get privacyPolicySection3Title =>
      '3. Encargados del Tratamiento y Transferencia Internacional';

  @override
  String get privacyPolicySection3Body =>
      'Compartimos datos únicamente con encargados del tratamiento contratados para prestar el servicio. Tratan los datos solo según nuestras instrucciones, con obligaciones de confidencialidad y seguridad:';

  @override
  String get privacyPolicySection3Bullet1 =>
      'Inteligencia artificial: el texto de \"escribir el mío\" puede enviarse a un proveedor de IA solo para sugerir una opción ya existente del diario. La IA no evalúa tu salud.';

  @override
  String get privacyPolicySection3Bullet2 =>
      'Lectura de documentos: las fotos y PDF de exámenes y recetas que eliges leer se envían a un proveedor de reconocimiento de texto, y un proveedor de IA ordena ese texto, sin tu nombre ni CPF. Antes, la app te pide tu consentimiento específico e indica el proveedor y el país donde se tratan los datos. Estos proveedores no pueden usar los datos para entrenar modelos.';

  @override
  String get privacyPolicySection3Bullet3 =>
      'Envío de correos: tu correo electrónico, tu nombre de pila y los códigos de verificación o de restablecimiento de contraseña se envían a un proveedor de correo solo para entregar esos mensajes. No enviamos datos de salud por correo.';

  @override
  String get privacyPolicySection3Bullet4 =>
      'Infraestructura en la nube: proveedores de alojamiento y base de datos.';

  @override
  String get privacyPolicySection3Bullet5 =>
      'Transferencia internacional: algunos encargados tratan datos fuera de Brasil, y la app puede usarse desde fuera de Brasil. Se realiza con tu consentimiento específico y con las garantías contractuales del proveedor (LGPD Art. 33; RGPD Art. 46, cláusulas contractuales tipo).';

  @override
  String get privacyPolicySection3Bullet6 =>
      'Lista de encargados: puedes pedir en cualquier momento la lista actualizada de encargados en contato@dualischeckup.com (LGPD Art. 18, VII).';

  @override
  String get privacyPolicySection4Title => '4. Pagos';

  @override
  String get privacyPolicySection4Body =>
      'Cuando existan planes de pago, los datos de tarjeta quedan aislados de nuestros servidores:';

  @override
  String get privacyPolicySection4Bullet1 =>
      'Procesamiento por Terceros: Los pagos se gestionan a través de pasarelas de pago especializadas.';

  @override
  String get privacyPolicySection4Bullet2 =>
      'Cero Almacenamiento: Los servidores de DualisCheckUp NO reciben, no procesan ni guardan números de tarjeta de crédito ni códigos CVV.';

  @override
  String get privacyPolicySection5Title =>
      '5. Tus Derechos como Titular (Art. 18 de la LGPD)';

  @override
  String get privacyPolicySection5Body =>
      'Puedes ejercer tus derechos legales al instante, directamente desde la aplicación:';

  @override
  String get privacyPolicySection5Bullet1 =>
      'Exportación de Datos: Descarga todos tus registros en formato estructurado (JSON) con un toque en la Central de Privacidad.';

  @override
  String get privacyPolicySection5Bullet2 =>
      'Eliminación Definitiva: Solicita la eliminación irreversible de tu cuenta y de todos los datos asociados.';

  @override
  String get privacyPolicySection5Bullet3 =>
      'Revocación del Consentimiento: Deja de usar la app y retira tu autorización en cualquier momento.';

  @override
  String get privacyPolicySection6Title =>
      '6. Seguridad de la Información y Respuesta a Incidentes';

  @override
  String get privacyPolicySection6Body =>
      'Medidas técnicas de extremo a extremo protegen tus registros:';

  @override
  String get privacyPolicySection6Bullet1 =>
      'Aislamiento RLS: Cada consulta a la base PostgreSQL está protegida por una política de Row-Level Security con clave de usuario aislada.';

  @override
  String get privacyPolicySection6Bullet2 =>
      'Cifrado Robusto: Conexiones TLS 1.3 obligatorias y contraseñas protegidas con el algoritmo Argon2id.';

  @override
  String get privacyPolicySection6Bullet3 =>
      'Plan de Notificación en hasta 72 h: Comunicación inmediata a la Autoridad Nacional de Protección de Datos (ANPD) y a los usuarios ante cualquier incidente de seguridad relevante (LGPD Art. 48).';

  @override
  String get privacyPolicySection7Title =>
      '7. Notificaciones, Comunicaciones y Opt-Out';

  @override
  String get privacyPolicySection7Body =>
      'Respetamos tu tranquilidad y tu atención:';

  @override
  String get privacyPolicySection7Bullet1 =>
      'Tienes total libertad para desactivar los recordatorios de hidratación o las notificaciones de consejos de bienestar en Configuración en cualquier momento.';

  @override
  String get privacyPolicySection7Bullet2 =>
      'Los avisos de seguridad y de recuperación de cuenta son estrictamente transaccionales y protegidos.';

  @override
  String get privacyPolicyCtaQuestion =>
      '¿Quieres exportar tus datos o gestionar tu cuenta ahora?';

  @override
  String get privacyPolicyCtaButton => 'Ir a la Central de Privacidad';

  @override
  String get onboardingIntendedUseNote =>
      'DualisCheckUp es una aplicación de bienestar y autoconocimiento. No es un dispositivo médico y no sustituye a un profesional de la salud.';

  @override
  String get privacyVeilBiometricReason =>
      'Autentícate para acceder a tus registros.';

  @override
  String get privacyVeilUnlock => 'Desbloquear';

  @override
  String get privacyVeilUnlockManually => 'Desbloquear manualmente';

  @override
  String get settingsChangePhotoSubtitle =>
      'Elige cómo quieres seleccionar tu foto de perfil.';

  @override
  String get settingsPhotoCamera => 'Cámara';

  @override
  String get settingsPhotoCameraSubtitle => 'Tomar una foto nueva';

  @override
  String get settingsPhotoGallery => 'Galería';

  @override
  String get settingsPhotoGallerySubtitle => 'Elegir de la biblioteca de fotos';

  @override
  String get settingsPhotoPresets => 'Avatares';

  @override
  String get settingsPhotoPresetsSubtitle =>
      'Elegir un ícono ilustrado de autocuidado';

  @override
  String get settingsLogoutConfirmBody =>
      '¿Realmente deseas cerrar tu sesión? Tus datos permanecen seguros y cifrados.';

  @override
  String get settingsLogoutConfirmAction => 'Salir';

  @override
  String get settingsNameHint => 'Tu nombre completo';

  @override
  String get settingsRemindersTile => 'Recordatorios e Hidratación';

  @override
  String get settingsRemindersSubtitle =>
      'Horarios de notificaciones, alarmas y prueba con la app cerrada';

  @override
  String get settingsTermsTile => 'Términos de Uso';

  @override
  String get settingsTermsSubtitle =>
      'Condiciones de uso, planes, cancelación y reembolso';

  @override
  String get settingsPrivacyPolicyTile => 'Política de Privacidad (LGPD)';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'Tratamiento de datos, derechos del titular y DPO';

  @override
  String get settingsCommunicationsSection => 'Comunicaciones y Notificaciones';

  @override
  String get settingsEducationalTipsTile =>
      'Consejos de Bienestar y Notificaciones Educativas';

  @override
  String get settingsEducationalTipsSubtitle =>
      'Consejos generales de bienestar. Puedes desactivarlos (opt-out) en cualquier momento.';

  @override
  String get settingsEducationalTipsOn =>
      'Notificaciones educativas activadas.';

  @override
  String get settingsEducationalTipsOff =>
      'Opt-out confirmado: notificaciones educativas desactivadas.';

  @override
  String get settingsOperatorInfo =>
      'Operado por WGI (Brothers Baum Ltda.)\nCNPJ 30.889.282/0001-90 • São Paulo - SP, Brasil\nContato: contato@dualischeckup.com';

  @override
  String get avatarSelectorSubtitle =>
      'Selecciona un ícono de autocuidado para personalizar tu perfil.';

  @override
  String get avatarConfirm => 'Confirmar Avatar';

  @override
  String get avatarPresetSelfCare => 'Autocuidado';

  @override
  String get avatarPresetBalance => 'Equilibrio';

  @override
  String get avatarPresetProtection => 'Protección';

  @override
  String get avatarPresetVitality => 'Vitalidad';

  @override
  String get avatarPresetWellbeing => 'Bienestar';

  @override
  String get avatarPresetEnergy => 'Energía';

  @override
  String get avatarPresetFocus => 'Enfoque Mental';

  @override
  String get avatarPresetRadiant => 'Radiante';

  @override
  String get loginTitle => 'Entrar en DualisCheckUp';

  @override
  String get loginSubtitle =>
      'Accede a tu diario de bienestar de forma segura.';

  @override
  String get authEmailHint => 'tu.correo@ejemplo.com';

  @override
  String get loginPasswordRequired => 'La contraseña es obligatoria.';

  @override
  String get loginNoAccountPrompt => '¿Aún no tienes cuenta? ';

  @override
  String get registerTitle => 'Crea tu cuenta';

  @override
  String get registerSubtitle =>
      'Indica algunos datos para personalizar tu experiencia.';

  @override
  String get registerNameHint => 'Ej.: Carlos Silva';

  @override
  String get registerDobHint => 'DD/MM/AAAA';

  @override
  String get registerDobHelper =>
      'Ej.: 15/08/1990 o selecciona en el calendario.';

  @override
  String get registerDobPickerHelp => 'Selecciona la fecha de nacimiento';

  @override
  String get registerDobPickerConfirm => 'Confirmar';

  @override
  String get registerPasswordHint => 'Mínimo 8 caracteres';

  @override
  String get registerPasswordHelper =>
      'Usa 8+ caracteres con mayúscula, número y símbolo.';

  @override
  String get registerHydrationTitle => 'Recordatorios y Control de Hidratación';

  @override
  String get registerHydrationSubtitle =>
      'Configura tus hábitos de hidratación';

  @override
  String get registerWaterReminderTitle => 'Aviso para tomar agua cada 2 h';

  @override
  String get registerWaterReminderSubtitle =>
      'Horas pares: 8 h, 10 h, 12 h, 14 h, 16 h, 18 h y 20 h';

  @override
  String get registerReminderStyleLabel => 'Tipo de recordatorio / sonido:';

  @override
  String get registerReminderStyleChime => 'Aviso (Mensaje)';

  @override
  String get registerReminderStyleAlarm => 'Alarma Telefónica';

  @override
  String get registerWaterTrackingTitle => 'Control de cantidad consumida';

  @override
  String get registerWaterTrackingOnDesc =>
      'Al sonar la alarma, la app se abre para registrar la cantidad de agua';

  @override
  String get registerWaterTrackingOffDesc =>
      'Solo suena el recordatorio a la hora, sin abrir el registro';

  @override
  String get registerHaveAccountPrompt => '¿Ya tienes una cuenta? ';

  @override
  String homeGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get homeGreetingNoName => '¡Hola!';

  @override
  String get homeSessionActive => 'Sesión activa';

  @override
  String get homeDataProtectedBadge => 'Tus registros están protegidos';

  @override
  String get homeTodayEntryDone => 'Registro de hoy completado';

  @override
  String get notFoundErrorCode => 'ERROR 404';

  @override
  String get notFoundTitle => 'Página No Encontrada';

  @override
  String get notFoundBody => 'La página a la que intentaste acceder no existe.';

  @override
  String get notFoundBackToDashboard => 'Volver al Panel';

  @override
  String get notFoundGoHome => 'Ir al Inicio';

  @override
  String get notFoundGoBack => 'Volver a la pantalla anterior';

  @override
  String get wellnessConfirmTitle => '¡Todo Bien por Aquí!';

  @override
  String get wellnessConfirmBody =>
      '¡Excelente noticia! Indicaste que te sientes bien tanto física como emocionalmente hoy.\n\nTu check-in diario se completó con éxito y tus datos están protegidos. ¡Sigue cultivando buenos hábitos de autocuidado!';

  @override
  String get wellnessConfirmButton => 'Finalizar Check-in';

  @override
  String get adBannerHeader =>
      'Socio local • Este anuncio no usa tus datos de salud';

  @override
  String get adBannerSampleBody =>
      'Artículos de primeros auxilios e higiene personal con hasta 20% de descuento.';

  @override
  String get outcomeStaticGuidance =>
      'Esta app no evalúa tu salud. Si alguna molestia persiste, empeora o te preocupa, consulta a un profesional de salud. En emergencia, llama al número local de emergencias.';

  @override
  String get outcomeDualAxisNote =>
      'Registraste sensaciones en el cuerpo y en las emociones hoy. Si alguna molestia física persiste o empeora, habla con un profesional de salud.';

  @override
  String get outcomeAiInsightTitle => 'Cómo organizamos tu anotación';

  @override
  String outcomeAiInsightLayTerm(String term) {
    return 'Término que usaste: $term';
  }

  @override
  String outcomeAiInsightArea(String area) {
    return 'Zona del cuerpo o emoción: $area';
  }

  @override
  String get outcomeWellnessReadingsTitle => 'Lecturas sobre bienestar';

  @override
  String get outcomeWellnessReadingsDisclaimer =>
      'Contenidos educativos generales. No son orientación para tu caso.';

  @override
  String outcomeWellnessReadingsCount(int count) {
    return '$count lecturas';
  }

  @override
  String get journalPatternTitle => 'Patrones en tus registros';

  @override
  String historyIntensityInformed(int n) {
    return 'Intensidad informada: $n/5';
  }

  @override
  String get todayOutcomeCompletedBadge => 'Registro completado';

  @override
  String get todayOutcomeUpdateButton => 'Actualizar registro de hoy';

  @override
  String get todayOutcomeDetailedCheckinButton => 'Hacer registro detallado';

  @override
  String get appUpdateTitle => 'Actualiza la aplicación';

  @override
  String appUpdateMessage(String minVersion) {
    return 'Esta versión ya no es compatible. Instala la versión $minVersion o más reciente desde la tienda.';
  }

  @override
  String get appUpdateButton => 'Abrir tienda de aplicaciones';

  @override
  String outcomeTodayYouLogged(String option) {
    return 'Registraste: $option';
  }

  @override
  String get outcomeTodayStatusGood => 'Bien';

  @override
  String get outcomeTodayStatusSoSo => 'Más o menos';

  @override
  String get outcomeTodayStatusBad => 'Mal';

  @override
  String get checkInSummaryTitle => 'Registro guardado';

  @override
  String get checkInSummaryBackHome => 'Volver al inicio';

  @override
  String checkInSummaryBackHomeCountdown(int seconds) {
    return 'Volver al inicio ($seconds)';
  }

  @override
  String get jv2FlowTitle => 'Registro del día';

  @override
  String get jv2Back => 'Volver';

  @override
  String get jv2Continue => 'Continuar';

  @override
  String get jv2Skip => 'Omitir';

  @override
  String get jv2Save => 'Guardar registro';

  @override
  String get jv2Yes => 'Sí';

  @override
  String get jv2No => 'No, continuar';

  @override
  String get jv2Cancel => 'Cancelar';

  @override
  String get jv2Remove => 'Quitar';

  @override
  String jv2HelloName(String name) {
    return '¡Hola, $name!';
  }

  @override
  String get jv2Hello => '¡Hola!';

  @override
  String get jv2GoodMorning => 'Buenos días.';

  @override
  String get jv2GoodAfternoon => 'Buenas tardes.';

  @override
  String get jv2GoodEvening => 'Buenas noches.';

  @override
  String get jv2MoodQuestion => '¿Cómo te sientes hoy?';

  @override
  String get jv2MoodBem => 'Bien';

  @override
  String get jv2MoodNormal => 'Normal';

  @override
  String get jv2MoodNaoTaoBem => 'No tan bien';

  @override
  String get jv2AreaConditions => 'Mis condiciones';

  @override
  String jv2ConditionCardQuestion(String label) {
    return '¿Cómo estás con $label hoy?';
  }

  @override
  String get jv2TimeQuestion => 'Lo que sientes tiene más que ver con…';

  @override
  String get jv2TimePassado => 'Lo que ya pasó';

  @override
  String get jv2TimePresente => 'El momento actual';

  @override
  String get jv2TimeFuturo => 'Lo que viene';

  @override
  String get jv2TimeShortPassado => 'Pasado';

  @override
  String get jv2TimeShortPresente => 'Presente';

  @override
  String get jv2TimeShortFuturo => 'Futuro';

  @override
  String get jv2BranchQuestion => '¿Qué va más contigo ahora?';

  @override
  String get jv2OptionsQuestion => 'Marca lo que va contigo.';

  @override
  String get jv2MultiSelectHint => 'Puedes marcar más de uno.';

  @override
  String get jv2WriteMine => 'Escribir el mío';

  @override
  String get jv2WriteMineHint => 'En pocas palabras';

  @override
  String get jv2WriteMineAdd => 'Agregar';

  @override
  String get jv2SuggestTitle => 'Esto se parece a una opción que ya existe';

  @override
  String jv2SuggestBody(String option) {
    return '¿Guardar como \"$option\" en vez del texto escrito?';
  }

  @override
  String get jv2SuggestYes => 'Usar esa opción';

  @override
  String get jv2SuggestNo => 'Mantener lo que escribí';

  @override
  String get jv2MoreQuestion => '¿Quieres registrar algo más?';

  @override
  String get jv2MoreBodyQuestion => '¿Quieres marcar otra parte del cuerpo?';

  @override
  String get jv2BodyQuestion => '¿Dónde sientes dolor o molestia?';

  @override
  String get jv2BodyHint => 'Toca una o más partes.';

  @override
  String get jv2BodyFront => 'Frente';

  @override
  String get jv2BodyBack => 'Espalda';

  @override
  String jv2ItemLimit(int max) {
    return 'Llegaste al límite de $max ítems en este registro.';
  }

  @override
  String get jv2BranchPassadoTristeza => 'Tristeza o nostalgia';

  @override
  String get jv2BranchPassadoMemoria => 'Un recuerdo que molesta';

  @override
  String get jv2BranchPresenteEnergia => 'Sin energía';

  @override
  String get jv2BranchPresenteSobrecarga => 'Irritado(a) o sobrecargado(a)';

  @override
  String get jv2BranchFuturoMente => 'Mente acelerada';

  @override
  String get jv2BranchFuturoMedo => 'Miedo de que algo salga mal';

  @override
  String get jv2OptPassadoTristezaCulpa => 'Culpa o arrepentimiento';

  @override
  String get jv2OptPassadoTristezaSaudade =>
      'Echar de menos a alguien o cómo eran las cosas';

  @override
  String get jv2OptPassadoMemoriaLembranca => 'Un mal recuerdo que vuelve';

  @override
  String get jv2OptPassadoMemoriaMagoa => 'Le doy vueltas a viejas heridas';

  @override
  String get jv2OptPresenteEnergiaCorpo => 'Cuerpo pesado, tenso o adolorido';

  @override
  String get jv2OptPresenteEnergiaDesligado =>
      'En piloto automático, medio desconectado';

  @override
  String get jv2OptPresenteSobrecargaPaciencia =>
      'Sin paciencia, estallando por poco';

  @override
  String get jv2OptPresenteSobrecargaAperto =>
      'Opresión en el pecho y momentos de desesperación';

  @override
  String get jv2OptFuturoMenteAntecipar => 'Me adelanto a los problemas';

  @override
  String get jv2OptFuturoMenteCobranca => 'Exigencia de perfección o control';

  @override
  String get jv2OptFuturoMedoJulgamento => 'Miedo a fallar o a ser juzgado(a)';

  @override
  String get jv2OptFuturoMedoDesanimo => 'Desánimo por el rumbo de las cosas';

  @override
  String get jv2RegionCabeca => 'Cabeza y cuello';

  @override
  String get jv2RegionPeito => 'Pecho';

  @override
  String get jv2RegionBarriga => 'Barriga';

  @override
  String get jv2RegionCostas => 'Espalda';

  @override
  String get jv2RegionMembros => 'Brazos, piernas y manos';

  @override
  String get jv2AxisEmotional => 'Psicoemocional';

  @override
  String get jv2AxisPhysical => 'Físico';

  @override
  String get jv2WholeBody => 'En todo el cuerpo';

  @override
  String get jv2RegionPele => 'Piel';

  @override
  String get jv2RegionMusculos => 'Músculos';

  @override
  String get jv2RegionHormonios => 'Hormonas y metabolismo';

  @override
  String get jv2SensationQuestion => '¿Es dolor o molestia?';

  @override
  String get jv2SensationDor => 'Dolor';

  @override
  String get jv2SensationIncomodo => 'Molestia';

  @override
  String get jv2BranchCabecaNuca => 'Nuca';

  @override
  String get jv2BranchPeleCoceira => 'Picor o ardor';

  @override
  String get jv2BranchPeleAparencia => 'Aspecto de la piel';

  @override
  String get jv2BranchMusculosTensao => 'Tensión';

  @override
  String get jv2BranchMusculosCansaco => 'Cansancio muscular';

  @override
  String get jv2BranchHormoniosTemperatura => 'Temperatura';

  @override
  String get jv2BranchHormoniosApetite => 'Apetito y sed';

  @override
  String get jv2OptCabecaNucaRigida => 'Nuca rígida o pesada';

  @override
  String get jv2OptCabecaNucaPontada => 'Punzada en la parte de atrás';

  @override
  String get jv2OptPeleCoceiraCoceira => 'Picor';

  @override
  String get jv2OptPeleCoceiraArdencia => 'Ardor';

  @override
  String get jv2OptPeleAparenciaVermelhidao => 'Enrojecimiento';

  @override
  String get jv2OptPeleAparenciaManchas => 'Manchas';

  @override
  String get jv2OptMusculosTensaoRigidez => 'Rigidez';

  @override
  String get jv2OptMusculosTensaoCaibra => 'Calambre';

  @override
  String get jv2OptMusculosCansacoFraqueza => 'Debilidad';

  @override
  String get jv2OptMusculosCansacoDolorido => 'Adolorido';

  @override
  String get jv2OptHormoniosTemperaturaCalorao => 'Sofocos';

  @override
  String get jv2OptHormoniosTemperaturaFrio => 'Frío fuera de lo común';

  @override
  String get jv2OptHormoniosApetiteSede => 'Sed fuera de lo común';

  @override
  String get jv2OptHormoniosApetiteFome => 'Hambre fuera de lo común';

  @override
  String get jv2BranchCabecaPressao => 'Opresión, peso o presión';

  @override
  String get jv2BranchCabecaSentidos => 'Ojos, boca o garganta';

  @override
  String get jv2BranchPeitoRespiracao => 'Respiración diferente';

  @override
  String get jv2BranchPeitoIncomodo => 'Molestia en el pecho o las costillas';

  @override
  String get jv2BranchBarrigaQueimacao => 'Ardor o náuseas';

  @override
  String get jv2BranchBarrigaColica => 'Cólico o hinchazón';

  @override
  String get jv2BranchCostasRigidez => 'Rigidez o bloqueo';

  @override
  String get jv2BranchCostasFisgada => 'Dolor punzante al moverme';

  @override
  String get jv2BranchMembrosCansaco => 'Cansancio o dolor';

  @override
  String get jv2BranchMembrosFormigamento => 'Hormigueo';

  @override
  String get jv2OptCabecaPressaoTemporas =>
      'Dolor o presión en las sienes o la frente';

  @override
  String get jv2OptCabecaPressaoLatejando =>
      'Pulsante, con molestia a la luz o al ruido';

  @override
  String get jv2OptCabecaSentidosGarganta => 'Garganta raspada o seca';

  @override
  String get jv2OptCabecaSentidosOlhos => 'Ojos pesados o ardiendo';

  @override
  String get jv2OptPeitoRespiracaoCurta => 'Respiración corta';

  @override
  String get jv2OptPeitoRespiracaoTosse => 'Tos o pecho cargado';

  @override
  String get jv2OptPeitoIncomodoBatedeira =>
      'Corazón acelerado o palpitaciones';

  @override
  String get jv2OptPeitoIncomodoCostelas =>
      'Punzada en las costillas al respirar hondo';

  @override
  String get jv2OptBarrigaQueimacaoSubindo => 'Ardor que sube';

  @override
  String get jv2OptBarrigaQueimacaoEnjoo => 'Náuseas';

  @override
  String get jv2OptBarrigaColicaGases => 'Gases o barriga hinchada';

  @override
  String get jv2OptBarrigaColicaPontadas => 'Cólicos o punzadas';

  @override
  String get jv2OptCostasRigidezOmbros => 'Cuello y hombros rígidos';

  @override
  String get jv2OptCostasRigidezLombar => 'Peso en la zona lumbar';

  @override
  String get jv2OptCostasFisgadaIrradia =>
      'Punzada que baja al brazo o la pierna';

  @override
  String get jv2OptCostasFisgadaAoMexer => 'Dolor al moverme';

  @override
  String get jv2OptMembrosCansacoJuntas => 'Articulaciones adoloridas';

  @override
  String get jv2OptMembrosCansacoPesados => 'Brazos o piernas cansados';

  @override
  String get jv2OptMembrosFormigamentoDormentes =>
      'Manos o pies con hormigueo o adormecidos';

  @override
  String get jv2OptMembrosFormigamentoChoque => 'Sensación de descarga';

  @override
  String get jv2PersistenceQuestion => '¿Desde cuándo lo notas?';

  @override
  String get jv2PersistenceHoje => 'Empezó hoy';

  @override
  String get jv2PersistenceDiasSemanas => 'Algunos días o semanas';

  @override
  String get jv2PersistenceMesesAnos => 'Meses o años';

  @override
  String get jv2PersistenceOptional => '¿Desde cuándo? (opcional)';

  @override
  String get jv2IntensityQuestion => 'Ahora, ¿cuánto pesa esto en tu día?';

  @override
  String get jv2IntensityCompactQuestion =>
      'Para cada ítem, ¿cuánto pesa en tu día?';

  @override
  String jv2IntensityLevel(int level) {
    return '$level de 5';
  }

  @override
  String get jv2IntensityEmotional1 =>
      'Pasa rápido, sigo mi día con normalidad.';

  @override
  String get jv2IntensityEmotional2 =>
      'Lo noto, pero consigo mantener el foco.';

  @override
  String get jv2IntensityEmotional3 => 'Me está quitando energía o foco.';

  @override
  String get jv2IntensityEmotional4 =>
      'Está cambiando mi rutina (sueño, tareas, convivencia).';

  @override
  String get jv2IntensityEmotional5 =>
      'Me está frenando casi por completo hoy.';

  @override
  String get jv2IntensityPhysical1 => 'Lo siento, pero no me estorba.';

  @override
  String get jv2IntensityPhysical2 => 'Molesta, pero mantengo mis actividades.';

  @override
  String get jv2IntensityPhysical3 =>
      'Bajó mi ritmo o me hizo hacer una pausa.';

  @override
  String get jv2IntensityPhysical4 => 'No consigo hacer bien lo que necesito.';

  @override
  String get jv2IntensityPhysical5 => 'Me está frenando casi por completo hoy.';

  @override
  String get jv2EmergencyLine =>
      'Si es una emergencia, usa el botón Ayuda o llama al número de emergencias de tu país.';

  @override
  String get jv2TriggersQuestion => '¿Hay algo que pudo haber contribuido hoy?';

  @override
  String get jv2TriggerTrabalho => 'Trabajo o estudios';

  @override
  String get jv2TriggerFamilia => 'Familia o relaciones';

  @override
  String get jv2TriggerSono => 'Noche mal dormida';

  @override
  String get jv2TriggerAlimentacao => 'Alimentación';

  @override
  String get jv2TriggerEsforco => 'Esfuerzo físico';

  @override
  String get jv2TriggerQueda => 'Caída o mal movimiento';

  @override
  String get jv2TriggerMedicamento => 'Medicamento nuevo';

  @override
  String get jv2TriggerClima => 'Clima o ambiente';

  @override
  String get jv2TriggerNaoSei => 'No sé';

  @override
  String get jv2TriggerOutro => 'Otro';

  @override
  String get jv2TriggerNoteHint => 'Cuéntalo en pocas palabras';

  @override
  String get jv2NoteQuestion => '¿Quieres contar algo más?';

  @override
  String get jv2NoteHint => 'Escribe con tus palabras (opcional)';

  @override
  String get jv2SaveError => 'No se pudo guardar ahora. Inténtalo de nuevo.';

  @override
  String get jv2SavedOffline =>
      'Registro guardado en el dispositivo. Se enviará cuando haya conexión.';

  @override
  String get jv2ConditionsTitle => 'Mis condiciones';

  @override
  String get jv2ConditionsSubtitle =>
      'Informadas por ti. Escríbelas con tus palabras; cada una aparece en tu registro diario con la misma escala de 1 a 5.';

  @override
  String get jv2ConditionsAdd => 'Agregar';

  @override
  String get jv2ConditionsFieldHint => 'Ej.: Migraña';

  @override
  String get jv2ConditionsEmpty => 'Todavía no agregaste ninguna.';

  @override
  String get jv2ConditionsArchive => 'Archivar';

  @override
  String jv2ConditionsArchiveConfirm(String label) {
    return '¿Archivar \"$label\"? Tus registros anteriores mantienen ese nombre.';
  }

  @override
  String jv2ConditionsLimit(int max) {
    return 'Puedes seguir hasta $max.';
  }

  @override
  String get jv2ConditionsOffline =>
      'Sin conexión. Inténtalo de nuevo cuando tengas conexión.';

  @override
  String get jv2ConditionsError => 'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get jv2ConditionsSettingsSubtitle =>
      'Sigue, con tus palabras, algo que ya conoces';

  @override
  String get jv2PhraseTime1 => 'Entendido. Vamos a registrarlo con calma.';

  @override
  String get jv2PhraseTime2 => 'Gracias por contarlo. Vamos a anotarlo.';

  @override
  String get jv2PhraseTime3 => 'Está bien. Un paso a la vez.';

  @override
  String get jv2PhraseTime4 => 'De acuerdo. Vamos a registrarlo a tu manera.';

  @override
  String get jv2PhrasePassado1 =>
      'A veces la mente vuelve atrás. Vamos a anotarlo.';

  @override
  String get jv2PhrasePassado2 =>
      'Gracias por contarlo. ¿Con qué tiene que ver?';

  @override
  String get jv2PhrasePassado3 => 'Vamos a registrarlo con calma.';

  @override
  String get jv2PhrasePresente1 => 'Vamos a anotar lo que pesa hoy.';

  @override
  String get jv2PhrasePresente2 => 'Entendido. ¿Qué va más con este momento?';

  @override
  String get jv2PhrasePresente3 => 'Gracias por contarlo. Vamos a registrarlo.';

  @override
  String get jv2PhraseFuturo1 =>
      'Pensar en lo que viene es parte de la vida. Vamos a anotarlo.';

  @override
  String get jv2PhraseFuturo2 => 'Entendido. ¿Qué va más contigo?';

  @override
  String get jv2PhraseFuturo3 =>
      'Gracias por contarlo. Vamos a registrarlo con calma.';

  @override
  String get jv2PhraseBody1 => 'Vamos a anotar lo que sientes en el cuerpo.';

  @override
  String get jv2PhraseBody2 => 'Toca donde sientes molestia.';

  @override
  String get jv2PhraseBody3 => 'Gracias por contarlo. ¿Dónde lo sientes?';

  @override
  String get jv2PhraseRegion1 => 'Vamos a anotar lo que sientes aquí.';

  @override
  String get jv2PhraseRegion2 => 'Entendido. ¿Cómo es esa sensación?';

  @override
  String get jv2PhraseRegion3 => 'Gracias por contarlo. ¿Qué va más contigo?';

  @override
  String get jv2PhraseRegion4 => 'Registrar te ayuda a seguir tu día a día.';

  @override
  String get jv2PhraseIntensity1 => 'Tú eliges el número. La escala es tuya.';

  @override
  String get jv2PhraseIntensity2 =>
      'No hay respuesta correcta. Vale lo que sientes.';

  @override
  String get jv2PhraseIntensity3 => 'Casi listo. Solo un poco más.';

  @override
  String get jv2PhraseTriggers1 =>
      'Si quieres, marca lo que pudo haber contribuido.';

  @override
  String get jv2PhraseTriggers2 => 'Es opcional. Puedes omitirlo.';

  @override
  String get jv2PhraseTriggers3 => 'Casi listo. ¿Algo marcó tu día?';

  @override
  String get xv2CropTitle => 'Ajustar foto';

  @override
  String get xv2CropHint =>
      'Usa dos dedos para acercar y arrastra para encuadrar.';

  @override
  String get xv2CropReset => 'Reiniciar';

  @override
  String get xv2CropConfirm => 'Usar foto';

  @override
  String xv2GreetingMorning(String name) {
    return '¡Hola, $name! Buenos días';
  }

  @override
  String xv2GreetingAfternoon(String name) {
    return '¡Hola, $name! Buenas tardes';
  }

  @override
  String xv2GreetingEvening(String name) {
    return '¡Hola, $name! Buenas noches';
  }

  @override
  String get xv2GreetingMorningNoName => '¡Hola! Buenos días';

  @override
  String get xv2GreetingAfternoonNoName => '¡Hola! Buenas tardes';

  @override
  String get xv2GreetingEveningNoName => '¡Hola! Buenas noches';

  @override
  String get xv2HydrationOfferTitle =>
      '¿Quieres recordatorios para beber agua?';

  @override
  String get xv2HydrationOfferBody =>
      'Tú eliges los horarios y tu meta en los ajustes de hidratación. Puedes cambiarlos cuando quieras.';

  @override
  String get xv2HydrationOfferYes => 'Sí, configurar';

  @override
  String get xv2HydrationOfferNo => 'Ahora no';

  @override
  String get xv2LibTitle => 'Biblioteca';

  @override
  String get xv2LibIntro =>
      'Textos generales de fuentes públicas sobre hábitos saludables. Son iguales para todas las personas y no son orientación para tu caso.';

  @override
  String xv2LibSource(String source) {
    return 'Fuente: $source';
  }

  @override
  String xv2LibReadTime(int minutes) {
    return '$minutes min de lectura';
  }

  @override
  String get xv2LibOpen => 'Abrir texto';

  @override
  String get xv2LibOpenError => 'No se pudo abrir el enlace ahora.';

  @override
  String get xv2LibCatEmocoes => 'Emociones y estado de ánimo';

  @override
  String get xv2LibCatEstresse => 'Estrés y descanso';

  @override
  String get xv2LibCatSono => 'Sueño';

  @override
  String get xv2LibCatCorpo => 'Cuerpo y movimiento';

  @override
  String get xv2LibCatAlimentacao => 'Alimentación y digestión';

  @override
  String get xv2LibCatHidratacao => 'Hidratación';

  @override
  String get xv2LibCatRelacoes => 'Relaciones y convivencia';

  @override
  String get xv2LibCatAjuda => 'Primeros cuidados y cuándo buscar ayuda';

  @override
  String get xv2LibArtDesanimoTitle => 'Días de desánimo y poca energía';

  @override
  String get xv2LibArtDesanimoSummary =>
      'Pequeñas rutinas para días de desánimo y dónde encontrar apoyo.';

  @override
  String get xv2LibArtAgitacaoTitle =>
      'Momentos de agitación: cómo bajar el ritmo';

  @override
  String get xv2LibArtAgitacaoSummary =>
      'Información general sobre nerviosismo y pensamientos acelerados en el día a día.';

  @override
  String get xv2LibArtTrabalhoTitle =>
      'Cansancio en el trabajo y límites saludables';

  @override
  String get xv2LibArtTrabalhoSummary =>
      'Información general sobre el cansancio emocional en el trabajo y las pausas en la rutina.';

  @override
  String get xv2LibArtRespiracaoTitle => 'Respiración pausada para relajarte';

  @override
  String get xv2LibArtRespiracaoSummary =>
      'Unos minutos de respiración tranquila pueden ayudarte a bajar el ritmo en días exigentes.';

  @override
  String get xv2LibArtSonoTitle => 'Hábitos para dormir mejor';

  @override
  String get xv2LibArtSonoSummary =>
      'Horarios regulares y hábitos sencillos que favorecen noches más tranquilas.';

  @override
  String get xv2LibArtBracosTitle => 'Brazos y hombros: pausas y postura';

  @override
  String get xv2LibArtBracosSummary =>
      'Información general sobre el esfuerzo repetitivo y las pausas durante el día.';

  @override
  String get xv2LibArtMovimentoTitle => 'Muévete en el día a día';

  @override
  String get xv2LibArtMovimentoSummary =>
      'Orientaciones generales sobre actividad física en todas las edades.';

  @override
  String get xv2LibArtAlimentacaoTitle =>
      'Guía Alimentaria para la Población Brasileña';

  @override
  String get xv2LibArtAlimentacaoSummary =>
      'Principios generales para una alimentación equilibrada, con comida de verdad.';

  @override
  String get xv2LibArtAguaTitle => 'Agua a lo largo del día';

  @override
  String get xv2LibArtAguaSummary =>
      'Beber agua a lo largo del día forma parte de hábitos de vida saludables.';

  @override
  String get xv2LibArtConvivioTitle => 'Bienestar emocional y convivencia';

  @override
  String get xv2LibArtConvivioSummary =>
      'Información general sobre bienestar emocional, relaciones y apoyo de la comunidad.';

  @override
  String get xv2LibArtSamuTitle => 'SAMU 192: cómo funciona';

  @override
  String get xv2LibArtSamuSummary =>
      'El servicio móvil gratuito del sistema público de Brasil, que atiende en el 192 en todo el país.';

  @override
  String get xv2LibArtCvvTitle => 'CVV 188: apoyo emocional';

  @override
  String get xv2LibArtCvvSummary =>
      'Conversación gratuita y confidencial, las 24 horas, por teléfono, chat o correo.';

  @override
  String xv2ReportedIntensity(int intensity) {
    return 'Intensidad que informaste: $intensity/5';
  }

  @override
  String get xv2SummaryTitle => 'Tu registro de hoy';

  @override
  String get xv2SummarySaved => 'Tu registro se guardó.';

  @override
  String get xv2SummaryThanks =>
      '¡Gracias por registrar tu día! 🌿 En la Biblioteca encontrarás textos de fuentes públicas, como el Ministerio de Salud de Brasil, sobre hábitos saludables.';

  @override
  String get xv2SummaryOpenLibrary => 'Abrir la Biblioteca';

  @override
  String get xv2AdLabel => 'Anuncio';

  @override
  String get xv2AdLearnMore => 'Más información';

  @override
  String get xv2AdPremiumTitle => 'Dualis Premium';

  @override
  String get xv2AdPremiumBody =>
      'Ve hasta 12 meses de tus registros y elige tus fondos. Muy pronto.';

  @override
  String get xv2AdZocTitle => 'ZOC · Cuadernos y agendas';

  @override
  String get xv2AdZocBody =>
      'Planifica la semana con calma, en papel. Anuncio de ejemplo.';

  @override
  String get xv2AdWgiTitle => 'WGI · Botellas reutilizables';

  @override
  String get xv2AdWgiBody => 'Lleva tu agua a donde vayas. Anuncio de ejemplo.';

  @override
  String get xv2AdUboTitle => 'UBO · Listas para relajarte';

  @override
  String get xv2AdUboBody =>
      'Sonidos de la naturaleza para pausas en el día. Anuncio de ejemplo.';

  @override
  String get xv2DashTitle => 'Historial';

  @override
  String xv2DashWindow(int days) {
    return 'Tus registros de los últimos $days días';
  }

  @override
  String get xv2DashRetry => 'Intentar de nuevo';

  @override
  String get xv2DashTimeTitle => 'Pasado, presente y futuro';

  @override
  String xv2DashTimeCount(String time, int count) {
    return '$time: $count';
  }

  @override
  String get xv2DashNoEmotional => 'Ningún registro emocional en este periodo.';

  @override
  String get xv2DashBodyTitle => 'Partes del cuerpo que marcaste';

  @override
  String get xv2DashFront => 'Frente';

  @override
  String get xv2DashBack => 'Espalda';

  @override
  String xv2DashRegionDays(String region, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: 'ningún día',
    );
    return '$region: $_temp0';
  }

  @override
  String get xv2DashLinesTitle => 'Intensidad por día';

  @override
  String get xv2DashLinesSubtitle =>
      'La intensidad que informaste en cada registro (1 a 5).';

  @override
  String xv2DashDaysCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get xv2DashSeeMore => 'Ver más';

  @override
  String get xv2DashSeeLess => 'Ver menos';

  @override
  String get xv2DashNoItems => 'Ningún elemento registrado en este periodo.';

  @override
  String get xv2DashWaterTitle => 'Agua por día';

  @override
  String get xv2DashNoWater => 'Ningún registro de agua en este periodo.';

  @override
  String get xv2DashTogetherTitle => 'El mismo día';

  @override
  String xv2DashCooccurrence(int total, String a, String b, int both) {
    return 'En los $total días en que marcaste \'$a\', también marcaste \'$b\' en $both.';
  }

  @override
  String get xv2DashEntriesTitle => 'Tus registros';

  @override
  String get xv2DashNoEntries => 'Aún no tienes registros en este periodo.';

  @override
  String xv2DashMoodLine(String mood) {
    return 'Cómo estabas: $mood';
  }

  @override
  String get xv2DashDeleteTitle => 'Eliminar registro';

  @override
  String get xv2DashDeleteBody => 'Este registro se borrará de tu historial.';

  @override
  String get xv2DashDeleteConfirm => 'Eliminar';

  @override
  String get xv2WaterTitle => 'Hidratación 💧';

  @override
  String get xv2WaterTodayLogs => 'Registros de hoy';

  @override
  String get xv2WaterHistoryTitle => 'Últimos 30 días';

  @override
  String get xv2WaterRemindersTitle => 'Recordatorios de agua';

  @override
  String get xv2WaterOther => 'Otro';

  @override
  String xv2WaterStreak(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Racha: $count días',
      one: 'Racha: 1 día',
      zero: 'Racha: 0 días',
    );
    return '$_temp0';
  }

  @override
  String xv2WaterGoalChip(int ml) {
    return 'Tu meta: $ml ml';
  }

  @override
  String get xv2WaterGoalDialogTitle => 'Tu meta diaria';

  @override
  String get xv2WaterGoalHint => 'Tú eliges tu meta, entre 250 y 10000 ml.';

  @override
  String get xv2WaterGoalSave => 'Guardar';

  @override
  String get xv2WaterNoLogsToday =>
      'Todavía no registraste ningún vaso de agua hoy.';

  @override
  String xv2WaterLoggedAt(String time) {
    return 'Registrado a las $time';
  }

  @override
  String xv2WaterLoggedViaReminder(String time) {
    return 'Registrado desde el recordatorio de las $time';
  }

  @override
  String get xv2WaterDeleteLog => 'Eliminar registro';

  @override
  String get jv2PendingSync => 'Esperando sincronizar';

  @override
  String get jv2OutboxRejectedNotice =>
      'Un registro no se pudo enviar. Revísalo e inténtalo de nuevo.';

  @override
  String get histTabEmotional => 'Psicoemocional';

  @override
  String get histTabPhysical => 'Físico';

  @override
  String histPeriodDays(int days) {
    return '$days días';
  }

  @override
  String histEmotionalTitle(int days) {
    return 'Tus últimos $days días';
  }

  @override
  String histPhysicalTitle(int days) {
    return 'Últimos $days días';
  }

  @override
  String get histIntensitySubtitle => 'Intensidad que marcaste, de 1 a 5';

  @override
  String get histChipHint => 'Toca un chip para mostrar u ocultar la línea.';

  @override
  String histLineShown(String label) {
    return '$label, línea visible';
  }

  @override
  String histLineHidden(String label) {
    return '$label, línea oculta';
  }

  @override
  String histOverlayChip(String label) {
    return '+ $label';
  }

  @override
  String get histTimeBarTitle => 'Pasado · Presente · Futuro';

  @override
  String get histViewMap => 'Mapa';

  @override
  String get histViewLinks => 'Conexiones';

  @override
  String get histMapCaption =>
      'Color = cuántos días lo marcaste. Toca una parte del cuerpo para ver su línea de tiempo.';

  @override
  String get histNoPhysical =>
      'Ninguna parte del cuerpo marcada en este período.';

  @override
  String histLinksTop(String time, String region, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return 'Mismo día: $time y $region en $_temp0. Solo conteo.';
  }

  @override
  String get histLinksEmpty =>
      'Aún no hay días con un tiempo emocional y una parte del cuerpo juntos en este período.';

  @override
  String get histTimelineTitle => 'Línea de tiempo';

  @override
  String get histEmotionalTitleWeek => 'Cómo fue tu semana';

  @override
  String get histPhysicalTitleWeek => 'Esta semana';

  @override
  String get histPhysicalTitleMonth => 'Este mes';

  @override
  String histRegionHeadline(int period, String region, num count, num days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: '1 vez',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return 'En los últimos $period días marcaste $region $_temp0, en $_temp1.';
  }

  @override
  String histRegionSensationTimes(String sensation, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: '1 vez',
    );
    return '$sensation: $_temp0';
  }

  @override
  String get histRegionMarksTitle => 'Cada vez que lo marcaste';

  @override
  String histRegionIntensity(int value) {
    return 'Intensidad $value de 5';
  }

  @override
  String get histRegionEmpty =>
      'No marcaste esta parte del cuerpo en este período.';

  @override
  String get careHubTitle => 'Mis cuidados';

  @override
  String get careHubToday => 'Hoy';

  @override
  String get careHubNoRemindersToday => 'Ningún recordatorio hoy';

  @override
  String careHubRemindersToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordatorios hoy',
      one: '1 recordatorio hoy',
    );
    return '$_temp0';
  }

  @override
  String careHubNext(String name, String time) {
    return 'Próximo: $name · $time';
  }

  @override
  String careHubVaccinesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosis registradas',
      one: '1 dosis registrada',
      zero: 'Ninguna dosis registrada',
    );
    return '$_temp0';
  }

  @override
  String get careHubNone => 'Ninguna informada';

  @override
  String careHubMedsActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activos',
      one: '1 activo',
      zero: 'Ninguno activo',
    );
    return '$_temp0';
  }

  @override
  String careHubLowStock(int count) {
    return 'stock bajo en $count';
  }

  @override
  String get careHubNoUpcoming => 'Ninguna consulta agendada';

  @override
  String careHubNextAppointment(String date, String who) {
    return 'Próxima: $date · $who';
  }

  @override
  String careHubPrescriptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recetas guardadas',
      one: '1 receta guardada',
      zero: 'Ninguna receta',
    );
    return '$_temp0';
  }

  @override
  String careHubDocuments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos guardados',
      one: '1 documento guardado',
      zero: 'Ningún documento',
    );
    return '$_temp0';
  }

  @override
  String get careHubSummarySubtitle =>
      'PDF para llevar a la consulta, si usted quiere';

  @override
  String get careVaccinesTitle => 'Vacunas';

  @override
  String get careAllergiesTitle => 'Alergias informadas';

  @override
  String get careMedicationsTitle => 'Medicamentos y recordatorios';

  @override
  String get careAppointmentsTitle => 'Consultas';

  @override
  String get careExamsTitle => 'Exámenes';

  @override
  String get careSummaryTitle => 'Resumen de mis registros';

  @override
  String get careLoadError => 'No se pudo cargar. Verifique su conexión.';

  @override
  String get careRetry => 'Intentar de nuevo';

  @override
  String get careSave => 'Guardar';

  @override
  String get careSaveError => 'No se pudo guardar. Intente de nuevo.';

  @override
  String get careFillRequired => 'Complete los campos obligatorios.';

  @override
  String get careCancel => 'Cancelar';

  @override
  String get careDelete => 'Eliminar';

  @override
  String get careDeleteTitle => '¿Eliminar este registro?';

  @override
  String get careDeleteBody => 'Se eliminará de este perfil.';

  @override
  String careDays(int count) {
    return '$count días';
  }

  @override
  String get careMon => 'Lun';

  @override
  String get careTue => 'Mar';

  @override
  String get careWed => 'Mié';

  @override
  String get careThu => 'Jue';

  @override
  String get careFri => 'Vie';

  @override
  String get careSat => 'Sáb';

  @override
  String get careSun => 'Dom';

  @override
  String get careVaccineRegister => 'Registrar dosis';

  @override
  String get careVaccineEdit => 'Editar dosis';

  @override
  String get careVaccineTabCalendar => 'Calendario oficial';

  @override
  String get careVaccineTabMine => 'Mis dosis';

  @override
  String careVaccineCalendarNote(String source) {
    return '$source (Brasil), mostrado tal como se publicó. Consulte en su centro de salud o con quien lo vacuna.';
  }

  @override
  String get carePniChild => 'Niño';

  @override
  String get carePniTeen => 'Adolescente';

  @override
  String get carePniAdult => 'Adulto';

  @override
  String get carePniElderly => '60+';

  @override
  String get carePniPregnant => 'Embarazo';

  @override
  String get careVaccineByCampaign => 'Según la campaña vigente';

  @override
  String careVaccineDosesInCalendar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosis en el calendario',
      one: 'Dosis única en el calendario',
    );
    return '$_temp0';
  }

  @override
  String careVaccineBoosterEvery(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years años',
      one: 'año',
    );
    return 'Refuerzo cada $_temp0 en el calendario';
  }

  @override
  String careVaccineLastDose(String date) {
    return 'Su última dosis registrada: $date';
  }

  @override
  String get careVaccineNoRecord => 'Sin registro';

  @override
  String careVaccineCount(int count, int total) {
    return '$count de $total';
  }

  @override
  String careVaccineCountOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosis',
      one: '1 dosis',
    );
    return '$_temp0';
  }

  @override
  String get careVaccineOfficialLink => 'Ver el calendario completo (gov.br)';

  @override
  String get careVaccineEmpty => 'Todavía no hay dosis registradas.';

  @override
  String careVaccineBatch(String batch) {
    return 'Lote $batch';
  }

  @override
  String careVaccineBoosterReminder(String date) {
    return 'Recordatorio de refuerzo: $date';
  }

  @override
  String get careDose1 => '1.ª dosis';

  @override
  String get careDose2 => '2.ª dosis';

  @override
  String get careDose3 => '3.ª dosis';

  @override
  String get careDoseBooster => 'Refuerzo';

  @override
  String get careDoseSingle => 'Dosis única';

  @override
  String get careDoseYearly => 'Anual';

  @override
  String get careVaccineField => 'Vacuna';

  @override
  String get careVaccineCustom => 'Otra (privada)';

  @override
  String get careVaccineCustomName => 'Nombre de la vacuna';

  @override
  String get careVaccineAppliedOn => 'Fecha de aplicación';

  @override
  String get careVaccineBatchField => 'Lote (opcional)';

  @override
  String get careVaccinePlace => 'Dónde (opcional)';

  @override
  String get careVaccineReceipt => 'Comprobante de vacuna';

  @override
  String get careVaccineReceiptAdd => 'Foto del comprobante';

  @override
  String get careVaccineReceiptSaved => 'Comprobante guardado';

  @override
  String get careVaccineReceiptHint => 'Se guarda solo en su registro';

  @override
  String get careVaccineRemindBooster => 'Recordarme el próximo refuerzo';

  @override
  String get careVaccineBoosterDate => 'Fecha del recordatorio';

  @override
  String careVaccineBoosterHint(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years años',
      one: '1 año',
    );
    return 'La fecha sale del intervalo publicado en el calendario oficial ($_temp0). Usted puede cambiarla.';
  }

  @override
  String get careVaccineBoosterHintNone =>
      'El calendario no indica intervalo para esta vacuna. Elija la fecha que quiera.';

  @override
  String get careAllergiesIntro =>
      'Lo que usted ya sabe que le causa reacción. Aparece en su perfil y en el resumen en PDF.';

  @override
  String get careAllergiesNoCrossCheck =>
      'Dualis guarda lo que usted escribe. No verifica si un medicamento coincide con sus alergias. Confirme siempre con quien receta o con la farmacia.';

  @override
  String get careAllergiesEmpty => 'Ninguna alergia informada.';

  @override
  String get careAllergyAdd => 'Agregar alergia';

  @override
  String get careAllergyEdit => 'Editar alergia';

  @override
  String get careAllergyMedication => 'Medicamentos';

  @override
  String get careAllergyFood => 'Alimentos';

  @override
  String get careAllergyOther => 'Otros';

  @override
  String get careAllergyName => 'Nombre (como usted lo conoce)';

  @override
  String get careAllergyReaction => 'Reacción, con sus palabras (opcional)';

  @override
  String careAllergyReactionShown(String reaction) {
    return 'Reacción que usted informó: \"$reaction\"';
  }

  @override
  String careAllergyInformedOn(String date) {
    return 'Informado el $date';
  }

  @override
  String get careAllergyInformedField => 'Desde cuándo (opcional)';

  @override
  String get careAllergyOnProfile => 'Se muestra en la tarjeta de perfil';

  @override
  String get careAllergyShowOnProfile => 'Mostrar en la tarjeta de perfil';

  @override
  String get careAllergyShowOnProfileHint =>
      'Visible para quien usted comparta el perfil';

  @override
  String get careMedicationAdd => 'Medicamento';

  @override
  String get careMedicationEdit => 'Editar medicamento';

  @override
  String get careMedTabToday => 'Hoy';

  @override
  String get careMedTabAll => 'Todos';

  @override
  String get careMedEmpty => 'Ningún medicamento registrado.';

  @override
  String get careMedNoneToday => 'Nada programado para hoy.';

  @override
  String get careMedMorning => 'Mañana';

  @override
  String get careMedAfternoon => 'Tarde';

  @override
  String get careMedNight => 'Noche';

  @override
  String get careMedNote =>
      'Los horarios y cantidades son los que usted configuró, según su receta. Dualis no sugiere ni cambia dosis.';

  @override
  String careMedStockTitle(String name) {
    return 'Stock: $name';
  }

  @override
  String careMedStockBody(int count, int warnAt) {
    return 'Quedan $count. Usted pidió aviso con $warnAt.';
  }

  @override
  String careMedStockLeft(int count) {
    return 'Stock: $count';
  }

  @override
  String get careMedNoTimes => 'Sin horarios';

  @override
  String get careMedPaused => 'Pausado';

  @override
  String get careMedTaken => 'Lo tomé';

  @override
  String get careMedSnooze => 'Posponer 15 min';

  @override
  String get careMedSkip => 'No lo tomé';

  @override
  String careMedTakenAt(String time) {
    return 'tomado $time';
  }

  @override
  String get careMedSkipped => 'no tomado';

  @override
  String get careMedSnoozed => 'pospuesto';

  @override
  String get careMedFromPrescriptionNote =>
      'Completado con lo leído en la receta. Revise todo y elija los horarios.';

  @override
  String get careMedName => 'Nombre (como figura en la receta o la caja)';

  @override
  String get careMedStrength => 'Concentración';

  @override
  String get careMedForm => 'Forma';

  @override
  String get careMedAmount => 'Cuánto tomar cada vez (de su receta)';

  @override
  String get careMedInstructions => 'Como está escrito en la receta (opcional)';

  @override
  String get careMedTimes => 'Horarios';

  @override
  String get careMedAddTime => 'Horario';

  @override
  String get careMedTimesRequired => 'Elija al menos un horario.';

  @override
  String get careMedDays => 'Días';

  @override
  String get careMedEveryDay => 'Todos los días';

  @override
  String get careMedUntil => 'Hasta cuándo (opcional)';

  @override
  String get careMedStockSection => 'Stock (opcional)';

  @override
  String get careMedStockHave => 'En casa';

  @override
  String get careMedStockPerIntake => 'Por vez';

  @override
  String get careMedStockWarn => 'Aviso con';

  @override
  String get careMedBula => 'Prospecto oficial';

  @override
  String get careMedBulaHint => 'Abre el buscador oficial de ANVISA (Brasil)';

  @override
  String get careMedBulaNeedsName =>
      'Escriba primero el nombre del medicamento.';

  @override
  String get careMedActive => 'Recordatorios activos';

  @override
  String get careMedSave => 'Guardar recordatorios';

  @override
  String get careAppointmentAdd => 'Consulta';

  @override
  String get careAppointmentEdit => 'Editar consulta';

  @override
  String get careAppointmentEmpty => 'Ninguna consulta registrada.';

  @override
  String get careAppointmentUpcoming => 'Próximas';

  @override
  String get careAppointmentPast => 'Anteriores';

  @override
  String get careAppointmentTitleFallback => 'Consulta';

  @override
  String get careAppointmentQuestions => 'Preguntas que quiero hacer';

  @override
  String get careAppointmentNotes => 'Mis notas';

  @override
  String get careAppointmentDate => 'Fecha';

  @override
  String get careAppointmentTime => 'Hora';

  @override
  String get careAppointmentProfessional => 'Quién la atiende (opcional)';

  @override
  String get careAppointmentSpecialty => 'Especialidad';

  @override
  String get careAppointmentPlace => 'Lugar';

  @override
  String get careAppointmentOpenMap => 'Abrir en Google Maps';

  @override
  String get careAppointmentReminderNone => 'Sin recordatorio';

  @override
  String get careAppointmentReminder1d => '1 día antes';

  @override
  String get careAppointmentReminder2h => '2 horas antes';

  @override
  String get careSectionJournal => 'Diario';

  @override
  String get careSectionConditions => 'Condiciones';

  @override
  String get careSectionMedications => 'Medicamentos';

  @override
  String get careSectionAllergies => 'Alergias';

  @override
  String get careSectionVaccines => 'Vacunas';

  @override
  String get careSectionExams => 'Exámenes';

  @override
  String get careSectionNotes => 'Notas';

  @override
  String get careSummaryInclude => 'Incluir';

  @override
  String careSummaryJournal(int count) {
    return 'Registros del diario ($count)';
  }

  @override
  String get careSummaryConditions => 'Mis condiciones (informadas por usted)';

  @override
  String get careSummaryMedications => 'Medicamentos y horarios';

  @override
  String get careSummaryNotes => 'Mis notas';

  @override
  String careSummaryIntensity(int value) {
    return 'intensidad informada $value/5';
  }

  @override
  String careSummaryTaken(int taken, int marked) {
    return '$taken de $marked marcados como tomados';
  }

  @override
  String careSummaryReference(String text) {
    return 'referencia impresa: $text';
  }

  @override
  String get careSummaryNothing => 'Nada registrado en el período.';

  @override
  String careSummaryMore(int count) {
    return '+ $count en el PDF';
  }

  @override
  String careSummaryHeader(String name, String from, String to) {
    return '$name · $from a $to · generado por la propia persona';
  }

  @override
  String get careSummaryFooter =>
      'Este documento reúne solo lo que la persona registró. No contiene evaluación ni recomendación.';

  @override
  String get careSummaryShare => 'Compartir PDF';

  @override
  String get careSummaryPrivacy =>
      'El PDF se crea en su teléfono. Usted decide con quién compartirlo.';

  @override
  String get careExamAdd => 'Agregar examen';

  @override
  String get careExamFromCamera => 'Tomar foto';

  @override
  String get careExamFromGallery => 'Elegir de la galería';

  @override
  String get careExamFromPdf => 'Elegir PDF';

  @override
  String get careExamWhatIsIt => '¿Qué es este documento?';

  @override
  String get careExamKindLab => 'Examen de laboratorio';

  @override
  String get careExamKindLabHint =>
      'Leemos los valores para que usted los revise';

  @override
  String get careExamKindPrescription => 'Receta';

  @override
  String get careExamKindPrescriptionHint =>
      'Leemos nombre e instrucciones para que usted los revise';

  @override
  String get careExamKindArchive => 'Solo archivar';

  @override
  String get careExamKindArchiveHint => 'Guarda el archivo sin leerlo';

  @override
  String get careExamTooLarge => 'El archivo supera 10 MB.';

  @override
  String get careExamReading => 'Leyendo su documento…';

  @override
  String get careExamReadingHint =>
      'Tarda hasta 1 minuto. Puede salir de esta pantalla.';

  @override
  String get careExamEmpty => 'Ningún documento guardado.';

  @override
  String get careExamSectionLabs => 'Exámenes';

  @override
  String get careExamSectionPrescriptions => 'Recetas';

  @override
  String get careRxListAdd => 'Agregar receta';

  @override
  String get careRxListEmpty => 'Ninguna receta guardada.';

  @override
  String get careRxListNote =>
      'Dualis copia lo que está escrito en la receta. Confirme siempre con quien la recetó o con la farmacia.';

  @override
  String get careExamSectionOther => 'Otros archivos';

  @override
  String get careExamValuesOverTime => 'Mis valores a lo largo del tiempo';

  @override
  String get careExamValuesSearch => 'Buscar ítem (ej.: TSH)';

  @override
  String get careExamValuesNoMatch => 'Ningún ítem con ese nombre';

  @override
  String get careExamValuesOtherGroup => 'Otros exámenes';

  @override
  String careExamValuesItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ítems',
      one: '1 ítem',
    );
    return '$_temp0';
  }

  @override
  String careExamValuesShowMore(int count) {
    return 'Ver $count más';
  }

  @override
  String get careExamValuesShowLess => 'Ver menos';

  @override
  String get careExamNote =>
      'Los valores y referencias son los del informe. Dualis no dice si un resultado está bien o mal. Lleve sus dudas a quien pidió el examen.';

  @override
  String careExamToCheck(int count) {
    return 'Revisar $count';
  }

  @override
  String get careExamCheck => 'Revisar';

  @override
  String get careExamChecked => 'Revisado';

  @override
  String get careExamReadFailed => 'No leído';

  @override
  String get careExamArchived => 'Archivado';

  @override
  String get careExamReviewTitle => 'Revisar valores';

  @override
  String get careExamSeeOriginal => 'Ver documento original';

  @override
  String get careExamCompareHint =>
      'Compare con el papel. Toque una fila para corregirla.';

  @override
  String get careExamArchivedHint => 'Guardado sin lectura.';

  @override
  String get careExamFailedHint =>
      'No pudimos leer este archivo. Puede escribir los valores o probar otra foto, con buena luz y la hoja completa.';

  @override
  String get careExamDuplicateFile =>
      'Este archivo ya fue enviado. Abrimos el que ya tiene.';

  @override
  String get careExamPossibleDuplicate =>
      'Parece el mismo examen que ya tiene en otro documento.';

  @override
  String get careExamDuplicateSeeOther => 'Ver el otro';

  @override
  String get careExamDuplicateDiscard => 'Descartar este';

  @override
  String get careExamDuplicateKeep => 'Conservar los dos';

  @override
  String get careReadAgain => 'Leer el archivo de nuevo';

  @override
  String get careReadingAgain =>
      'Leyendo el archivo de nuevo. Puede tardar unos segundos.';

  @override
  String get careExamTitleField => 'Título del documento';

  @override
  String careExamTitleMany(String first, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exámenes',
      one: '1 examen',
    );
    return '$first + $_temp0';
  }

  @override
  String careExamSections(int count) {
    return 'Exámenes en este documento ($count)';
  }

  @override
  String get careExamLab => 'Laboratorio';

  @override
  String get careExamCollected => 'Fecha de toma';

  @override
  String get careExamItem => 'Ítem';

  @override
  String get careExamValue => 'Valor';

  @override
  String get careExamUnit => 'Unidad';

  @override
  String get careExamDate => 'Fecha';

  @override
  String get careExamReference => 'Referencia impresa en el informe';

  @override
  String get careExamReferencePrinted => 'Referencia impresa';

  @override
  String get careExamNoRows =>
      'Ningún valor leído. Agregue las filas que quiera guardar.';

  @override
  String get careExamAddRow => 'Agregar fila';

  @override
  String get careExamEditRow => 'Corregir fila';

  @override
  String get careExamRowSave => 'Confirmar fila';

  @override
  String get careExamRowRemove => 'Quitar fila';

  @override
  String careExamSavePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'faltan $count revisiones',
      one: 'falta 1 revisión',
    );
    return 'Guardar ($_temp0)';
  }

  @override
  String get careExamSaved => 'Valores guardados.';

  @override
  String get careExamItemIntro =>
      'Valores que usted revisó, del más reciente al más antiguo. La referencia es la que imprimió cada laboratorio.';

  @override
  String get careReadConsentTitle => 'Leer documentos con Google';

  @override
  String get careReadConsentBody =>
      'La foto o el PDF se envía a Google Cloud Vision, que lee el texto en EE. UU. o la UE (transferencia internacional de datos de salud). Gemini, en São Paulo, ordena el texto sin su nombre ni CPF. Google no entrena modelos con esto.\n\nSi prefiere, use \"Solo archivar\" o escriba los valores. Puede retirar el consentimiento en el Centro de Privacidad.';

  @override
  String get careReadConsentAccept => 'Acepto';

  @override
  String get careReadConsentDecline => 'Ahora no';

  @override
  String get careRxTitle => 'Revisar receta';

  @override
  String get careRxCompareHint =>
      'Compare con la receta. Toque un campo para corregirlo.';

  @override
  String get careRxNothingRead => 'Ningún medicamento leído.';

  @override
  String get careRxName => 'Nombre leído';

  @override
  String get careRxStrength => 'Concentración leída';

  @override
  String get careRxInstructions => 'Cómo tomar (texto de la receta)';

  @override
  String get careRxEditField => 'Corregir campo';

  @override
  String careRxFieldLabel(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'name': 'Nombre',
      'strength': 'Concentración',
      'other': 'Cómo tomar',
    });
    return '$_temp0';
  }

  @override
  String get careRxTimesYouChoose =>
      'Los horarios los elige usted en el siguiente paso.';

  @override
  String get careRxCheckFirst => 'Revise todos los campos';

  @override
  String get careRxCreateReminder => 'Crear recordatorio';

  @override
  String get careRxReminderCreated => 'Recordatorio creado';

  @override
  String get careRxNote =>
      'Dualis copia el texto de la receta. No convierte \"cada 12 h\" en horarios ni crea recordatorios por su cuenta.';

  @override
  String get careNotifChannelName => 'Recordatorios de cuidados';

  @override
  String get careNotifChannelDescription =>
      'Horarios de medicamentos, consultas y refuerzos de vacunas que usted configuró.';

  @override
  String get careNotifMedTitle => 'Hora de su recordatorio';

  @override
  String get careNotifAppointmentTitle => 'Recordatorio de consulta';

  @override
  String careNotifAppointmentBody(String who, String time) {
    return '$who a las $time';
  }

  @override
  String get careNotifBoosterTitle => 'Recordatorio de vacuna';

  @override
  String careNotifBoosterBody(String name) {
    return 'Fecha que usted eligió para el refuerzo: $name';
  }

  @override
  String get careMedicationNew => 'Nuevo medicamento';

  @override
  String get gxTabEmotions => 'Emociones';

  @override
  String get gxTabBody => 'Cuerpo';

  @override
  String get gxTabWater => 'Agua';

  @override
  String get gxTabTogether => 'Juntos';

  @override
  String get gxPieTitle => 'Pasado, presente y futuro';

  @override
  String get gxPieSubtitle =>
      'Parte de los registros emocionales en cada tiempo. La intensidad no cambia el tamaño de la porción.';

  @override
  String gxRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
    );
    return '$_temp0';
  }

  @override
  String gxPieTop(String answer, int count, int total) {
    return 'Opción más registrada: “$answer” · $count de $total';
  }

  @override
  String gxPieTied(int count, int total) {
    return 'Opciones empatadas, $count de $total cada una:';
  }

  @override
  String gxPieWithoutAxis(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros sin elección de tiempo (fuera del gráfico)',
      one: '1 registro sin elección de tiempo (fuera del gráfico)',
    );
    return '$_temp0';
  }

  @override
  String get gxLinesTitleEmotional => 'Intensidad informada por tiempo';

  @override
  String get gxLinesTitlePhysical => 'Intensidad informada por región';

  @override
  String get gxLinesSubtitle =>
      'Cada punto es un registro (1 a 5). La línea se corta en los días sin registro.';

  @override
  String get gxLegendHint =>
      'Toca la leyenda para mostrar u ocultar una línea. Toca un punto para ver el registro.';

  @override
  String gxIntensityValue(int value) {
    return 'Intensidad $value/5';
  }

  @override
  String get gxAnswersTitleEmotional => 'Respuestas por tiempo';

  @override
  String get gxAnswersTitlePhysical => 'Respuestas por región';

  @override
  String get gxAnswersSubtitle =>
      'El símbolo muestra el camino elegido. La altura es la intensidad informada.';

  @override
  String get gxWrittenByYou => 'Escrito por ti';

  @override
  String get gxNoIntensityPoints =>
      'Ningún registro con intensidad en este filtro.';

  @override
  String get gxBodyMapTitle => 'Marcas en el cuerpo';

  @override
  String gxRegionDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días con marca',
      one: '1 día con marca',
    );
    return '$_temp0';
  }

  @override
  String gxMarks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marcas',
      one: '1 marca',
    );
    return '$_temp0';
  }

  @override
  String get gxBodyMapCaption =>
      'Número = días con al menos una marca en la región. El color solo identifica la región.';

  @override
  String get gxWholeBody => 'Cuerpo entero (sin posición en el mapa)';

  @override
  String get gxViewUnspecified => 'vista no informada';

  @override
  String get gxSeeEvolution => 'Ver evolución';

  @override
  String get gxCalendarTitle => 'Calendario combinado';

  @override
  String get gxCalendarSubtitle =>
      'Cabeza: emociones · Silueta: cuerpo · Gota: agua registrada';

  @override
  String get gxCalendarCaption =>
      'Cabeza y silueta: tamaño según la intensidad informada. Gota: tamaño fijo, litros del día. Día sin registro no es cero. Toca el día para ver todo.';

  @override
  String get gxOutOfPeriod => 'Fuera del período';

  @override
  String get gxIntensityNotInformed => 'intensidad no informada';

  @override
  String get gxWaterLogged => 'Agua registrada';

  @override
  String get gxDayNothing => 'Ningún registro en este día.';

  @override
  String get gxSameDayNote =>
      'Estar en el mismo día no indica relación entre los elementos.';

  @override
  String gxGoalPercent(int percent, int goal) {
    return '$percent% de la meta elegida ($goal ml)';
  }

  @override
  String gxPeriodRange(String start, String end) {
    return '$start a $end';
  }

  @override
  String get gxNoWaterRecord => 'Ningún registro de agua';

  @override
  String gxWaterDayTitle(String date) {
    return 'Agua registrada el $date';
  }

  @override
  String get gxWaterStepTitle => 'Volumen registrado a lo largo del día';

  @override
  String gxWaterGoalLine(int goal) {
    return 'Meta elegida: $goal ml';
  }

  @override
  String gxWaterStepTooltip(String time, int added, int total) {
    return '$time · +$added ml\nAcumulado: $total ml';
  }

  @override
  String get gxWaterBarsTitle => 'Agua registrada en el período';

  @override
  String get gxWaterCardTotal => 'Total';

  @override
  String get gxWaterCardDays => 'Días con registro';

  @override
  String get gxWaterCardAverage => 'Promedio por día con registro';

  @override
  String get gxWaterCardGoal => 'Días que alcanzaron la meta elegida';

  @override
  String gxOfN(int a, int b) {
    return '$a de $b';
  }

  @override
  String get gxNoRecord => 'Sin registro';

  @override
  String get gxTodayInProgress => 'Hoy aún está en curso.';

  @override
  String get gxWaterCalendarTitle => 'Calendario de agua';

  @override
  String get gxWaterCalendarHint =>
      'Toca un día para ver el volumen a lo largo del día.';

  @override
  String gxWaterLoggedSnack(int ml) {
    return '$ml ml registrados';
  }

  @override
  String get gxUndo => 'Deshacer';

  @override
  String gxDayDetailTitle(String date) {
    return 'Registros del $date';
  }

  @override
  String get gxIntensityAxis => 'Intensidad informada';
}
