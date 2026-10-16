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
  String get triageBannerEmotional => 'Registro emocional de hoy';

  @override
  String get triageBannerPhysical => 'Registro físico de hoy';

  @override
  String triageStep(int step, int total) {
    return 'Paso $step de $total';
  }

  @override
  String get triageNext => 'Siguiente';

  @override
  String get triageBack => 'Volver';

  @override
  String get triageConfirm => 'Confirmar';

  @override
  String get triagePreviewTitle => 'Revisa tu registro';

  @override
  String get triagePreviewSubmit => 'Confirmar y Finalizar';

  @override
  String get triageQ1Emotional =>
      'Mirando su lado emocional y mental, ¿qué palabra describe mejor lo que siente ahora?';

  @override
  String get triageOptNormal => 'Normal / Me siento bien';

  @override
  String get triageSaveNormal => 'Concluir como Normal / Bien';

  @override
  String get triageOptAnsiedade => 'Ansiedad / Agitación';

  @override
  String get triageOptTristeza => 'Tristeza / Desánimo';

  @override
  String get triageOptEstresse => 'Estrés / Irritabilidad';

  @override
  String get triageOptCansaco => 'Cansancio Mental';

  @override
  String get triageOptAnsiosaAgitacao => 'Inquieto(a) / Agitado(a)';

  @override
  String get triageOptDepressivaDesanimo => 'Bajo(a) de ánimo / Desanimado(a)';

  @override
  String get triageOptEstresseBurnout => 'Estresado(a) / Agotado(a)';

  @override
  String get triageOptSomatica => 'Tensión en el cuerpo';

  @override
  String get triageOptSono => 'Dormir mal o dormir demasiado';

  @override
  String get triageOptCognitivaFoco => 'Dificultad para concentrarse';

  @override
  String get triageOptAutoestima => 'Autoestima / Autoimagen';

  @override
  String get triageQ2Emotional =>
      '¿Se ha sentido así con frecuencia en los últimos días o es algo específico de hoy?';

  @override
  String get triageOptComecouHoje => 'Empezó hoy';

  @override
  String get triageOptJaFazDias => 'Hace unos días';

  @override
  String get triageOptConstanteSemanas =>
      'Es algo constante desde hace semanas';

  @override
  String get triageQ3Emotional =>
      '¿Esta sensación parece una leve molestia de fondo o algo fuerte que acelera sus pensamientos?';

  @override
  String get triageOptLeveControlavel => 'Leve y controlable';

  @override
  String get triageOptModerada => 'Moderada';

  @override
  String get triageOptMuitoForte => 'Muy fuerte y difícil de controlar';

  @override
  String get triageQ4Emotional =>
      '¿Puede identificar si existe un motivo principal para lo que está sucediendo hoy?';

  @override
  String get triageQ4Ansiedade =>
      '¿Qué parece estar detonando esta sensación de ansiedad, agitación o nerviosismo?';

  @override
  String get triageQ4Depressao =>
      '¿Puede identificar si algún evento reciente o sentimiento agravó este desánimo o tristeza?';

  @override
  String get triageQ4EstresseBurnout =>
      '¿De dónde proviene la mayor parte de la presión o agotamiento que siente?';

  @override
  String get triageQ4Somatica =>
      '¿Esta tensión corporal o molestia física suele empeorar en qué situaciones?';

  @override
  String get triageQ4Sono =>
      '¿Cuál ha sido la principal dificultad que interrumpe sus noches de sueño?';

  @override
  String get triageQ4CognitivaFoco =>
      '¿Qué parece estar afectando más su concentración o claridad mental?';

  @override
  String get triageQ4Autoestima =>
      '¿Qué ha despertado con mayor intensidad esta sensación de inseguridad o autocrítica?';

  @override
  String get triageOptTrabalho => 'Trabajo / Estudios';

  @override
  String get triageOptFamilia => 'Familia / Relaciones';

  @override
  String get triageOptNoiteRuim => 'Mala noche de sueño';

  @override
  String get triageOptNaoSei => 'No sabría decir';

  @override
  String get triageOptSimCobrancaPrazos =>
      'Sobrecarga de tareas, plazos o expectativas';

  @override
  String get triageOptSimConflitoRelacionamento =>
      'Conflicto o discusión con persona cercana';

  @override
  String get triageOptSimIncertezaFuturo =>
      'Miedo a cambios, noticias o incertidumbre futura';

  @override
  String get triageOptSimExcessoEstimulantes =>
      'Exceso de café, energizantes o ambiente ruidoso';

  @override
  String get triageOptNaoSeiDizerEmocional =>
      'No logro identificarlo, surgió de repente';

  @override
  String get triageOptSimPerdaLuto => 'Pérdida, ruptura de relación o duelo';

  @override
  String get triageOptSimSolidaoIsolamento =>
      'Sensación de soledad, aislamiento o incomprensión';

  @override
  String get triageOptSimFrustracaoDesilusao =>
      'Frustración con algo que no salió como se esperaba';

  @override
  String get triageOptSimCansacoAcumulado =>
      'Cansancio prolongado sin pausas para recuperarse';

  @override
  String get triageOptSimPressaoTrabalho =>
      'Exceso de horario, exigencias o plazos en el trabajo';

  @override
  String get triageOptSimResponsabilidadesCasa =>
      'Cuidado de familiares, finanzas o responsabilidades en el hogar';

  @override
  String get triageOptSimFaltaDescanso =>
      'Sin tiempo libre para ocio, descanso o desconectarse';

  @override
  String get triageOptSimAmbienteToxico =>
      'Relaciones difíciles o ambiente diario desgastante';

  @override
  String get triageOptSimDuranteTrabalho =>
      'Durante la jornada de trabajo o momentos de presión';

  @override
  String get triageOptSimDiscussaoConflito =>
      'Justo tras discusiones, desacuerdos o sobresaltos';

  @override
  String get triageOptSimFinalDoDia =>
      'Al final del día, al intentar relajarse o acostarse';

  @override
  String get triageOptSimPreocupacaoConstante =>
      'En cualquier momento al pensar en problemas';

  @override
  String get triageOptSimDificuldadePegarSono =>
      'Mente acelerada / pensamientos al momento de dormir';

  @override
  String get triageOptSimAcordaMadrugada =>
      'Despertar a medianoche y no poder volver a dormir';

  @override
  String get triageOptSimSonoAgitadoPesadelos =>
      'Sueño ligero, agitado, con pesadillas o frecuentes despertares';

  @override
  String get triageOptSimHorarioIrregularTelas =>
      'Uso de pantallas hasta tarde o horarios irregulares';

  @override
  String get triageOptSimSobrecargaMultitarefas =>
      'Demasiadas cosas que hacer a la vez / exceso de estímulos';

  @override
  String get triageOptSimPreocupacaoIntrusiva =>
      'Pensamientos de preocupación que interrumpen el razonamiento';

  @override
  String get triageOptSimExaustaoMental =>
      'Cansancio mental acumulado tras muchas horas de esfuerzo';

  @override
  String get triageOptSimFaltaMotivacao =>
      'Falta de interés, energía o apatía con las tareas';

  @override
  String get triageOptSimComparacaoRedes =>
      'Comparación con otras personas (redes sociales o colegas)';

  @override
  String get triageOptSimMedoFalharJulgamento =>
      'Miedo a fallar, no cumplir expectativas o ser juzgado';

  @override
  String get triageOptSimCriticaRejeicao =>
      'Crítica reciente recibida o sensación de rechazo';

  @override
  String get triageOptSimDesvalorizacaoPropria =>
      'Dificultad para reconocer los propios logros';

  @override
  String get triagePreviewEmotional => 'Revisa tu registro';

  @override
  String get triageQ1Physical =>
      'Hablemos de la parte física. ¿Dónde siente esta molestia o dolor principal?';

  @override
  String get triageOptCabeca => 'Cabeza';

  @override
  String get triageOptCostas => 'Espalda / Columna';

  @override
  String get triageOptArticulacoes => 'Articulaciones (Rodilla, Hombro, etc.)';

  @override
  String get triageOptAbdomen => 'Abdomen / Estómago';

  @override
  String get triageOptCabecaPescoco => 'Cabeza y cuello';

  @override
  String get triageOptCardiovascularTorax => 'Pecho';

  @override
  String get triageOptRespiratorio => 'Respiración';

  @override
  String get triageOptGastrointestinalAbdomen => 'Barriga';

  @override
  String get triageOptColunaDorDorsal => 'Espalda';

  @override
  String get triageOptMembrosSuperiores => 'Brazos';

  @override
  String get triageOptMembrosInferiores => 'Piernas';

  @override
  String get triageOptNeurologico => 'Mareo / hormigueo';

  @override
  String get triageOptGeniturinarioPelvico => 'Zona íntima / urinaria';

  @override
  String get triageOptDermatologico => 'Piel';

  @override
  String get triageOptMuscularGeralSistemico => 'Todo el cuerpo / cansancio';

  @override
  String get triageOptEndocrinoMetabolico => 'Sed, hambre o energía';

  @override
  String get triageQ2Physical => '¿Desde hace cuánto sientes esta molestia?';

  @override
  String get triageOptComecouAgora => 'Empezó ahora';

  @override
  String get triageOptHaAlgunsDias => 'Hace unos días';

  @override
  String get triageOptCronica => 'Hace bastante tiempo';

  @override
  String get triageQ3Physical =>
      'En una escala del 1 al 5 (donde 1 es casi imperceptible y 5 es insoportable), ¿cómo está ahora?';

  @override
  String get triageQ4Physical =>
      '¿Recuerda haber hecho un esfuerzo atípico, ejercicio pesado o sufrido un golpe/caída recientemente?';

  @override
  String get triageQ4CabecaPescoco =>
      '¿Notó algún factor asociado, como estrés intenso, muchas horas frente a pantallas, mala noche de sueño o resfriado/sinusitis?';

  @override
  String get triageQ4CardiovascularTorax =>
      '¿El malestar en el pecho o palpitación comenzó tras esfuerzo físico, estrés emocional o consumo de estimulantes?';

  @override
  String get triageQ4Respiratorio =>
      '¿Tuvo contacto con polvo, humo, aire frío o tiene síntomas de gripe/resfriado?';

  @override
  String get triageQ4Gastrointestinal =>
      '¿Ingirió algún alimento diferente o pesado, tomó medicamentos recientes o estuvo mucho tiempo en ayunas?';

  @override
  String get triageQ4ColunaDorDorsal =>
      '¿Cargó peso excesivo, permaneció mucho tiempo en mala postura o sufrió algún impacto/caída?';

  @override
  String get triageQ4MembrosSuperiores =>
      '¿Realizó movimientos repetitivos (teclado, esfuerzo manual), entrenamiento de brazos/hombros o sufrió impacto/caída?';

  @override
  String get triageQ4MembrosInferiores =>
      '¿Hizo caminata larga, corrió, estuvo mucho tiempo de pie/sentado o sufrió torcedura/tropezón?';

  @override
  String get triageQ4Neurologico =>
      '¿El síntoma surgió tras levantarse rápido, no comer/hidratarse, crisis de ansiedad o posición incómoda?';

  @override
  String get triageQ4Geniturinario =>
      '¿Notó relación con poca agua/aguantar orina, ciclo menstrual, relación íntima o ropa húmeda?';

  @override
  String get triageQ4Dermatological =>
      '¿Notó algo que pudo haber causado esto, como un producto nuevo, exposición al sol/calor o contacto con algo (planta, insecto, sustancia)?';

  @override
  String get triageQ4MuscularGeral =>
      '¿Siente esto asociado a cansancio extremo, inicio de gripe/virosis, falta de descanso o deshidratación?';

  @override
  String get triageQ4EndocrinoMetabolico =>
      '¿Notó relación con ayuno prolongado, comida azucarada, cambio de medicina o calor excesivo?';

  @override
  String get triageOptSimExercicio => 'Sí, ejercicio intenso';

  @override
  String get triageOptSimQueda => 'Sí, sufrí una caída';

  @override
  String get triageOptNaoComecouNada => 'No, empezó de la nada';

  @override
  String get triageOptSimProdutoNovo =>
      'Sí, usé un producto nuevo (cosmético, jabón, etc.)';

  @override
  String get triageOptSimExposicaoSolCalor =>
      'Sí, hubo exposición al sol, calor o sudor intenso';

  @override
  String get triageOptSimPicadaContato =>
      'Sí, tuve contacto con una planta, insecto o sustancia';

  @override
  String get triageOptSimEstresseSono => 'Estrés o sueño irregular';

  @override
  String get triageOptSimTelasEsforcoVisual =>
      'Muchas horas en pantallas / esfuerzo visual';

  @override
  String get triageOptSimPosturaPescoco =>
      'Tensión muscular o mala postura en el cuello';

  @override
  String get triageOptSimResfriadoSinusite =>
      'Síntomas de resfriado o sinusitis';

  @override
  String get triageOptSimEsforcoFisico =>
      'Justo después de esfuerzo físico o caminata';

  @override
  String get triageOptSimEstresseAnsiedade =>
      'Momento de fuerte ansiedad o estrés';

  @override
  String get triageOptSimCafeinaEstimulante =>
      'Consumo de café, energético o estimulante';

  @override
  String get triageOptNaoSurgiuEmRepouso =>
      'No, surgió espontáneamente o en reposo';

  @override
  String get triageOptSimAlergiaAmbiente =>
      'Exposición a polvo, moho, humo o aire acondicionado';

  @override
  String get triageOptSimGripeInfeccao =>
      'Síntomas de gripe, resfriado o dolor de garganta';

  @override
  String get triageOptSimMudancaClima =>
      'Cambio brusco de temperatura o aire frío';

  @override
  String get triageOptSimAlimentacaoDiferente =>
      'Alimento diferente, pesado o sospechoso';

  @override
  String get triageOptSimMedicamentoRecente =>
      'Uso reciente de medicamento o antiinflamatorio';

  @override
  String get triageOptSimJejumEstresse =>
      'Largo período de ayuno o estrés intenso';

  @override
  String get triageOptNaoSemRelacaoAlimento =>
      'No, comenzó sin relación con la comida';

  @override
  String get triageOptSimCarregouPeso => 'Cargó peso o hizo esfuerzo lumbar';

  @override
  String get triageOptSimPosturaProlongada =>
      'Mucho tiempo sentado o mala postura al dormir';

  @override
  String get triageOptSimMauJeitoQueda =>
      'Movimiento brusco (\'mal esfuerzo\') o impacto/caída';

  @override
  String get triageOptSimMovimentoRepetitivo =>
      'Movimientos repetitivos (teclado, celular, trabajo manual)';

  @override
  String get triageOptSimTreinoSobrecarga =>
      'Ejercicio físico o sobrecarga en brazos/hombros';

  @override
  String get triageOptSimTraumaPancada =>
      'Golpe, caída o durmió en mala posición sobre el brazo';

  @override
  String get triageOptSimCaminhadaCorrida =>
      'Caminata larga, carrera o deporte reciente';

  @override
  String get triageOptSimTempoEmPeSentado =>
      'Muchas horas de pie o mucho tiempo sentado';

  @override
  String get triageOptSimTorcaoTropeco =>
      'Torcedura de tobillo/rodilla, tropezón o caída';

  @override
  String get triageOptSimLevantarRapido =>
      'Al levantarse rápidamente o cambiar de postura';

  @override
  String get triageOptSimJejumDesidratacao =>
      'Horas sin comer o poca hidratación';

  @override
  String get triageOptSimAnsiedadeHiperventilacao =>
      'Durante momento de tensión o respiración agitada';

  @override
  String get triageOptSimCompressaoPostural =>
      'Extremidad presionada o postura comprimiendo nervio';

  @override
  String get triageOptSimBaixaIngestaoUrina =>
      'Poca hidratación o retuvo orina por mucho tiempo';

  @override
  String get triageOptSimCicloMenstrual => 'Período premenstrual o menstrual';

  @override
  String get triageOptSimPosRelacaoIntima =>
      'Tras relación íntima o cambio de productos íntimos';

  @override
  String get triageOptSimRoupasUmidas => 'Uso de ropa húmeda o muy ajustada';

  @override
  String get triageOptSimCansacoEsgotamento =>
      'Cansancio extremo, sobrecarga o noches sin dormir';

  @override
  String get triageOptSimSintomasGripeVirose =>
      'Sensación de fiebre, escalofríos o inicio de virosis';

  @override
  String get triageOptSimAtividadeGlobal =>
      'Actividad física inhabitual (mudanza, limpieza pesada)';

  @override
  String get triageOptSimDesidratacaoCalor =>
      'Poca hidratación o exposición prolongada al calor';

  @override
  String get triageOptSimJejumAlimentacao =>
      'Horas sin comer o tras comida pesada/azucarada';

  @override
  String get triageOptSimAjusteMedicamento =>
      'Olvidó o modificó dosis de medicamento habitual';

  @override
  String get triageOptSimCalorDesidratacao =>
      'Ambiente muy caluroso o baja ingestión de líquidos';

  @override
  String get triageOptSimEstresseSobrecarga =>
      'Pico reciente de estrés o cambio de rutina';

  @override
  String get triagePreviewPhysical => 'Revisa tu registro';

  @override
  String triageIntensityLabel(int value) {
    return 'Intensidad: $value';
  }

  @override
  String get triageIntensityMin => 'Casi imperceptible';

  @override
  String get triageIntensityMax => 'Insoportable';

  @override
  String get outcomeScreenTitle => 'Resumen de tu registro';

  @override
  String get outcomeScreenSubtitle => 'Una foto de lo que registraste hoy';

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
  String outcomeReadTime(int minutes) {
    return '$minutes min de lectura';
  }

  @override
  String get outcomeDoneButton => 'Concluir y Volver al Inicio';

  @override
  String get antiburlaTitle => '¿Esto ya apareció antes?';

  @override
  String antiburlaDialogPrompt(int days) {
    return 'Registraste un síntoma similar hace $days días. ¿Es la misma sensación que volvió o algo totalmente nuevo?';
  }

  @override
  String get antiburlaOptionRecurring => 'Es la misma sensación que volvió';

  @override
  String get antiburlaOptionRecurringDesc =>
      'Lo registraremos como algo que volvió, para mantener tu diario organizado.';

  @override
  String get antiburlaOptionNew => 'Es un sentimiento completamente nuevo';

  @override
  String get antiburlaOptionNewDesc =>
      'Lo mantendremos registrado como un evento agudo que comenzó hoy.';

  @override
  String get offTopicNarrativeTitle => '¿Esto parece un síntoma?';

  @override
  String get offTopicNarrativeDesc =>
      'El texto que escribiste no parece describir un síntoma físico o emocional. ¿Deseas revisar tu descripción o continuar de todos modos?';

  @override
  String get offTopicNarrativeEditButton => 'Editar Descripción';

  @override
  String get offTopicNarrativeContinueButton => 'Continuar de Todos Modos';

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
  String get bodyMapTitle => 'Mapa Corporal 2D (14 Días)';

  @override
  String get bodyMapHint => 'Toca una región para ver detalles';

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
  String get criticalRecurrenceTitle => 'Foco de Atención';

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
  String get deleteHistoryItemTitle => 'Eliminar registro del historial';

  @override
  String get deleteHistoryItemConfirm =>
      '¿Estás seguro de que deseas descartar este registro de tu historial? Esta acción no se puede deshacer.';

  @override
  String get deleteHistoryItemSuccess => 'Registro eliminado con éxito.';

  @override
  String get deleteHistoryItemError => 'No fue posible eliminar el registro.';

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
  String get navTodayOutcome => 'Mi Día';

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
  String safetyNoticeGeneral(String number) {
    return 'Si esto es una emergencia, no uses la app: llama al $number ahora.';
  }

  @override
  String get safetyNoticeOpenResources => 'Ver contactos de ayuda';

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
      'Contrato de prestación de servicios de software en la nube (SaaS) celebrado entre el Usuario y DualisCheckUp Saúde e Tecnologia Ltda., inscrita en el CNPJ con el nº 48.291.834/0001-92, con sede en São Paulo/SP, Brasil.';

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
      'Todos los derechos de propiedad intelectual sobre el software, los contenidos, las marcas y las interfaces pertenecen exclusivamente a DualisCheckUp Saúde e Tecnologia Ltda. Queda estrictamente prohibida la reproducción, la ingeniería inversa o la extracción de datos.';

  @override
  String get termsSection5Title => '5. Suspensión por Violación de Seguridad';

  @override
  String get termsSection5Body =>
      'Las cuentas que realicen intentos de intrusión, ataques de fuerza bruta, pruebas de penetración no autorizadas o envíen datos fraudulentos serán bloqueadas de inmediato y comunicadas a las autoridades competentes.';

  @override
  String get termsSection6Title => '6. Jurisdicción y Contacto Legal';

  @override
  String get termsSection6Body =>
      'Estos términos se rigen por las leyes brasileñas. Se elige el Foro de la Comarca de São Paulo/SP como único competente para resolver los litigios derivados de este contrato.\n\nPara dudas o notificaciones legales: legal@dualischeckup.com.';

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
      'Encargado de Protección de Datos (DPO): dpo@dualischeckup.com';

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
      'Organización automática de tus anotaciones por área del cuerpo o emoción (con ayuda de IA, sin evaluación de salud).';

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
      'Para prestar el servicio, compartimos datos únicamente con:';

  @override
  String get privacyPolicySection3Bullet1 =>
      'Google LLC (API Gemini): El texto de tus anotaciones se envía a la API Gemini de Google para organizarlas automáticamente. La IA no evalúa tu salud.';

  @override
  String get privacyPolicySection3Bullet2 =>
      'Transferencia Internacional: Este procesamiento puede realizarse en servidores ubicados fuera de Brasil (LGPD Art. 33).';

  @override
  String get privacyPolicySection3Bullet3 =>
      'Infraestructura en la Nube: Proveedores de alojamiento y base de datos, sujetos a obligaciones de confidencialidad y seguridad.';

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
  String get wizardNarrativeLabel => 'Descripción opcional (con tus palabras)';

  @override
  String get wizardNarrativeHint =>
      'Si quieres, escribe con tus palabras cómo estás.';

  @override
  String get wizardStepZeroFreeTextLabel =>
      '¿Prefieres describirlo con tus propias palabras?';

  @override
  String get wizardStepZeroFreeTextHint =>
      'Si quieres, escribe con tus palabras lo que estás sintiendo.';

  @override
  String deleteHistoryItemIntensity(int value) {
    return 'Intensidad informada: $value/5';
  }

  @override
  String get bodyMapRegionHeadNeck => 'Cabeza y cuello';

  @override
  String get bodyMapRegionHeadNeckHint =>
      'Dolor de cabeza, dolor o rigidez en el cuello';

  @override
  String get bodyMapRegionDizziness => 'Mareo / hormigueo';

  @override
  String get bodyMapRegionDizzinessHint =>
      'Mareo, sensación de desequilibrio, hormigueo';

  @override
  String get bodyMapRegionBack => 'Espalda';

  @override
  String get bodyMapRegionBackHint => 'Dolor de espalda, columna o zona lumbar';

  @override
  String get bodyMapRegionBreathing => 'Respiración';

  @override
  String get bodyMapRegionBreathingHint => 'Falta de aire, tos';

  @override
  String get bodyMapRegionChest => 'Pecho';

  @override
  String get bodyMapRegionChestHint =>
      'Opresión o molestia en el pecho, corazón acelerado';

  @override
  String get bodyMapRegionBelly => 'Barriga';

  @override
  String get bodyMapRegionBellyHint =>
      'Molestia en la barriga, cólicos, acidez';

  @override
  String get bodyMapRegionPelvic => 'Zona íntima / urinaria';

  @override
  String get bodyMapRegionPelvicHint =>
      'Molestia en la zona pélvica o al orinar';

  @override
  String get bodyMapRegionRightArm => 'Brazo derecho';

  @override
  String get bodyMapRegionRightArmHint =>
      'Brazo, hombro, codo o muñeca derechos';

  @override
  String get bodyMapRegionLeftArm => 'Brazo izquierdo';

  @override
  String get bodyMapRegionLeftArmHint =>
      'Brazo, hombro, codo o muñeca izquierdos';

  @override
  String get bodyMapRegionRightLeg => 'Pierna derecha';

  @override
  String get bodyMapRegionRightLegHint =>
      'Cadera, muslo, rodilla o tobillo derechos';

  @override
  String get bodyMapRegionLeftLeg => 'Pierna izquierda';

  @override
  String get bodyMapRegionLeftLegHint =>
      'Cadera, muslo, rodilla o tobillo izquierdos';

  @override
  String get bodyMapRegionSkin => 'Piel';

  @override
  String get bodyMapRegionSkinHint => 'Picazón, manchas';

  @override
  String get bodyMapRegionWholeBody => 'Todo el cuerpo / cansancio';

  @override
  String get bodyMapRegionWholeBodyHint => 'Dolor en todo el cuerpo, cansancio';

  @override
  String get bodyMapRegionEnergy => 'Sed, hambre o energía';

  @override
  String get bodyMapRegionEnergyHint => 'Cambios de energía, sed o hambre';

  @override
  String get bodyMapGroupHead => 'Cabeza';

  @override
  String get bodyMapGroupTrunk => 'Tronco';

  @override
  String get bodyMapGroupLimbs => 'Brazos y piernas';

  @override
  String get bodyMapGroupWholeBody => 'Todo el cuerpo y piel';

  @override
  String get bodyMapViewMap => 'Mapa del cuerpo';

  @override
  String get bodyMapViewAll => 'Todas las áreas';

  @override
  String get bodyMapShortSkin => 'Piel';

  @override
  String get bodyMapShortWholeBody => 'Todo el cuerpo';

  @override
  String get bodyMapShortEnergy => 'Energía';

  @override
  String bodyMapMaxIntensity(int value) {
    return 'Mayor intensidad informada en los últimos 14 días: $value/5';
  }

  @override
  String bodyMapNoEntriesThisSide(String otherArea, int value) {
    return 'Sin registros de este lado en los últimos 14 días.\n($otherArea: intensidad informada $value/5)';
  }

  @override
  String bodyMapViewOtherSide(String area) {
    return 'Ver $area';
  }

  @override
  String get bodyMapNoEntries14Days => 'Ningún registro en los últimos 14 días';

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
      'Operado por DualisCheckUp Saúde e Tecnologia Ltda.\nCNPJ 48.291.834/0001-92 • São Paulo - SP, Brasil\nDPO: dpo@dualischeckup.com';

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
  String get forgotPasswordLink => '¿Olvidaste tu contraseña?';

  @override
  String get forgotPasswordTitle => 'Restablecer contraseña';

  @override
  String get forgotPasswordSubtitle =>
      'Indica el correo de tu cuenta. Te enviaremos un código para restablecer tu contraseña.';

  @override
  String get forgotPasswordSendCta => 'Enviar código';

  @override
  String get forgotPasswordSuccessMessage =>
      'Si el correo está registrado, se envió un código de restablecimiento.';

  @override
  String get forgotPasswordBackToLogin => 'Volver al inicio de sesión';

  @override
  String get resetPasswordTitle => 'Crear nueva contraseña';

  @override
  String get resetPasswordSubtitle =>
      'Ingresa el código recibido por correo y elige una nueva contraseña.';

  @override
  String get resetPasswordCodeLabel => 'Código de verificación';

  @override
  String get resetPasswordCodeHint => 'Ingresa el código de 6 dígitos';

  @override
  String get resetPasswordCodeRequired =>
      'El código de verificación es obligatorio.';

  @override
  String get resetPasswordSubmitCta => 'Restablecer contraseña';

  @override
  String get resetPasswordSuccessMessage =>
      'Contraseña restablecida con éxito. Ya puedes iniciar sesión con la nueva contraseña.';

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
  String get outcomeWellnessReadingsRelatedTitle =>
      'Lecturas relacionadas con lo que registraste';

  @override
  String outcomeWellnessReadingsCount(int count) {
    return '$count lecturas';
  }

  @override
  String get outcomeArticlesEmpty => 'No hay lecturas disponibles por ahora.';

  @override
  String get journalPatternTitle => 'Patrones en tus registros';

  @override
  String journalPatternDescription(String category, int count, int windowDays) {
    return 'Registraste $category con intensidad alta $count veces en los últimos $windowDays días. Si esto afecta tu día a día, puede ayudar hablar con un profesional de salud.';
  }

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
  String outcomeSummaryIntensity(int value) {
    return 'Intensidad informada: $value/5';
  }

  @override
  String outcomeSummaryRecordedAt(String time) {
    return 'Registrado a las $time';
  }

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
  String get outcomeHistoryDetailTitle => 'Detalles del registro';

  @override
  String get outcomeHistoryNoNarrative =>
      'No agregaste una descripción en este registro.';
}
