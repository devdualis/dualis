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

  @override
  String get triageBannerEmotional => 'Iniciando Autoevaluación Psicoemocional';

  @override
  String get triageBannerPhysical => 'Iniciando Autoevaluación Física';

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
  String get triagePreviewTitle => 'Revisión de su Evaluación';

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
  String get triageOptAnsiosaAgitacao => 'Ansiosa / Agitación';

  @override
  String get triageOptDepressivaDesanimo => 'Depresiva / Desánimo';

  @override
  String get triageOptEstresseBurnout => 'Estrés / Burnout';

  @override
  String get triageOptSomatica => 'Somática (Psicosomática)';

  @override
  String get triageOptSono => 'Sueño (Insomnio / Hipersomnia)';

  @override
  String get triageOptCognitivaFoco => 'Cognitiva / Foco';

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
  String get triagePreviewEmotional =>
      'Revisión de su Autoevaluación Psicoemocional';

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
  String get triageOptCabecaPescoco => 'Cabeza y Cuello';

  @override
  String get triageOptCardiovascularTorax => 'Cardiovascular / Tórax';

  @override
  String get triageOptRespiratorio => 'Sistema Respiratorio';

  @override
  String get triageOptGastrointestinalAbdomen => 'Gastrointestinal / Abdomen';

  @override
  String get triageOptColunaDorDorsal => 'Columna y Dolor Dorsal';

  @override
  String get triageOptMembrosSuperiores => 'Miembros Superiores D/I';

  @override
  String get triageOptMembrosInferiores => 'Miembros Inferiores D/I';

  @override
  String get triageOptNeurologico => 'Sistema Neurológico';

  @override
  String get triageOptGeniturinarioPelvico => 'Genitourinario / Pélvico';

  @override
  String get triageOptDermatologico => 'Sistema Dermatológico';

  @override
  String get triageOptMuscularGeralSistemico => 'Muscular / General Sistémico';

  @override
  String get triageOptEndocrinoMetabolico => 'Endocrino / Metabólico';

  @override
  String get triageQ2Physical =>
      '¿Cuánto tiempo persiste este dolor o anomalía?';

  @override
  String get triageOptComecouAgora => 'Empezó ahora';

  @override
  String get triageOptHaAlgunsDias => 'Hace unos días';

  @override
  String get triageOptCronica => 'Es crónica';

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
  String get triagePreviewPhysical => 'Revisión de su Evaluación Física';

  @override
  String triageIntensityLabel(int value) {
    return 'Intensidad: $value';
  }

  @override
  String get triageIntensityMin => 'Casi imperceptible';

  @override
  String get triageIntensityMax => 'Insoportable';

  @override
  String get outcomeScreenTitle => 'Resultado del Triaje';

  @override
  String get outcomeScreenSubtitle =>
      'Evaluación preventiva basada en sus respuestas';

  @override
  String get outcomeIntensityTitle => 'Intensidad Calculada';

  @override
  String get outcomeIntensityDescription =>
      'Puntuación calculada en la escala clínica del 1 al 5';

  @override
  String get outcomeDispositionTitle => 'Recomendación de Cuidado';

  @override
  String get outcomeDispositionSelfCare => 'Autocuidado Monitoreado';

  @override
  String get outcomeDispositionSelfCareDesc =>
      'Reposo, hidratación adecuada y seguimiento de los síntomas en las próximas 24 horas.';

  @override
  String get outcomeDispositionRoutine => 'Consulta de Rutina';

  @override
  String get outcomeDispositionRoutineDesc =>
      'Programe una consulta preventiva en los próximos días con un profesional de la salud.';

  @override
  String get outcomeDispositionUrgent => 'Atención de Urgencia';

  @override
  String get outcomeDispositionUrgentDesc =>
      'Busque evaluación médica presencial en un centro de salud dentro de 24 horas.';

  @override
  String get outcomeDispositionEmergency => 'Atención de Emergencia';

  @override
  String get outcomeDispositionEmergencyDesc =>
      'Sus síntomas requieren atención médica inmediata. Acuda al centro de urgencias más cercano.';

  @override
  String get outcomeOrganicPrimacyTitle => 'Atención: Primacía Orgánica';

  @override
  String get outcomeOrganicPrimacyDesc =>
      'Los síntomas físicos concomitantes al malestar emocional requieren evaluación médica física prioritaria antes de atribuirse únicamente al estrés psicológico.';

  @override
  String get outcomeArticlesTitle => 'Artículos Médicos Recomendados';

  @override
  String get outcomeArticlesSubtitle =>
      'Contenidos preventivos elaborados por especialistas reconocidos';

  @override
  String outcomeReadTime(int minutes) {
    return '$minutes min de lectura';
  }

  @override
  String get outcomeDoneButton => 'Concluir y Volver al Inicio';

  @override
  String get antiburlaTitle => 'Verificación Histórica';

  @override
  String antiburlaDialogPrompt(int days) {
    return 'Registraste un síntoma similar hace $days días. ¿Es la misma sensación que volvió o algo totalmente nuevo?';
  }

  @override
  String get antiburlaOptionRecurring => 'Es la misma sensación que volvió';

  @override
  String get antiburlaOptionRecurringDesc =>
      'Ajustaremos el inicio a \'Hace unos días\' para mantener tu historial clínico consistente.';

  @override
  String get antiburlaOptionNew => 'Es un sentimiento completamente nuevo';

  @override
  String get antiburlaOptionNewDesc =>
      'Lo mantendremos registrado como un evento agudo que comenzó hoy.';

  @override
  String get antiburlaBiologicalDiscordanceTitle =>
      'Aviso Anatómico Preventivo';

  @override
  String get antiburlaBiologicalDiscordanceDesc =>
      'Notamos una discrepancia entre la región anatómica informada y los parámetros de tu perfil. ¿Deseas revisar antes de continuar?';

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
      'Estás sin conexión. Tu historial y evaluación siguen funcionando normalmente.';

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
  String get heatLegendNone => 'Sin dolor';

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
  String get readRecommendedArticle => 'Leer Artículo Recomendado';

  @override
  String get privacyCenterTitle => 'Privacidad y Datos (LGPD)';

  @override
  String get exportDataTitle => 'Exportación de Datos';

  @override
  String get exportDataDesc =>
      'Descarga una copia completa de tus datos personales e historial clínico en formato JSON según el Art. 18, V de la LGPD.';

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
  String get settingsDataHistorySubtitle => 'Visualiza tu historial de triajes';

  @override
  String get deleteHistoryItemTitle => 'Eliminar registro del historial';

  @override
  String get deleteHistoryItemConfirm =>
      '¿Estás seguro de que deseas descartar este registro de triaje de tu historial? Esta acción no se puede deshacer.';

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
      'No se pudo cargar el historial de triajes en este momento.';

  @override
  String get errorArticleLinkUnavailable =>
      'Enlace del artículo preventivo no disponible.';

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
  String get navTodayOutcome => 'Resultado del Día';

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
    return '🩺 Check-in diario Dualis ($time)';
  }

  @override
  String get notifCheckinBody =>
      'Aún no has actualizado tu estado de salud hoy. ¡Toca para hacer tu check-in!';

  @override
  String get notifCheckinChannelName => 'Recordatorios de check-in diario';

  @override
  String get notifCheckinChannelDescription =>
      'Notificaciones cada 2 horas para recordarte actualizar tu check-in diario de salud';

  @override
  String get outcomeAxisPhysicalNumbered => '1. Eje de Evaluación Física';

  @override
  String get outcomeAxisEmotionalNumbered =>
      '2. Eje de Evaluación Psicoemocional';
}
