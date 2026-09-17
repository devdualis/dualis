// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DualisCheckUp';

  @override
  String get screen1PrimaryCta => 'Create Account';

  @override
  String get screen1SecondaryCta => 'Sign In';

  @override
  String get screen2PrimaryCta => 'Complete Registration';

  @override
  String get valueCard1Title => 'Unified Preventive Triage';

  @override
  String get valueCard1Body =>
      'Connect your physical health and emotional state in a single intelligent daily check-in.';

  @override
  String get valueCard2Title => 'Armored Medical Records';

  @override
  String get valueCard2Body =>
      'Your medical history protected by AES-256 encryption and strictly guarded under LGPD.';

  @override
  String get valueCard3Title => 'Accurate Preventive Guidance';

  @override
  String get valueCard3Body =>
      'Evidence-based recommendations and articles from renowned medical specialists.';

  @override
  String get lgpdConsentCheckbox =>
      'I have read and agree to the Privacy Policy and explicitly consent to the processing of my sensitive personal health data for preventive triage and longitudinal tracking purposes, pursuant to Art. 11 of the LGPD.';

  @override
  String get privacyVeilTitle => 'Protected Health Data';

  @override
  String get privacyVeilBody =>
      'Authenticate with biometrics or passcode to access your records.';

  @override
  String get formErrorName => 'Please enter your full name (first and last).';

  @override
  String get formErrorEmail => 'Please enter a valid email address.';

  @override
  String get formErrorPassword =>
      'Password must be at least 8 characters long with uppercase, lowercase, number and symbol.';

  @override
  String get fullName => 'Full Name';

  @override
  String get birthDate => 'Date of Birth';

  @override
  String get biologicalSex => 'Biological Sex';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexOther => 'Other';

  @override
  String get language => 'Language';

  @override
  String get portuguese => 'Portuguese';

  @override
  String get spanish => 'Spanish';

  @override
  String get english => 'English';

  @override
  String get emergencyTitle => 'Immediate Risk Alert';

  @override
  String get emergencySubtitle =>
      'Severe symptoms identified. Seek immediate emergency medical care.';

  @override
  String get emergencyBadgeChestPain => 'Critical Chest Pain';

  @override
  String get emergencyBadgeRespiratory => 'Acute Respiratory Distress';

  @override
  String get emergencyBadgeStroke => 'Suspected Neurological Deficit (Stroke)';

  @override
  String get emergencyBadgeHeadache => 'Sudden Severe Headache';

  @override
  String get emergencyBadgeEmotional =>
      'Immediate Crisis Support / Life Safety';

  @override
  String get emergencyBadgeGeneral => 'Critical Symptom (Level 4–5)';

  @override
  String get emergencyInstructionPhysical1 =>
      'Stop any physical activity and rest immediately.';

  @override
  String get emergencyInstructionPhysical2 =>
      'Do not drive to the hospital. Call emergency services or ask someone for help.';

  @override
  String get emergencyInstructionPhysical3 =>
      'Loosen tight clothing and try to stay calm while waiting for assistance.';

  @override
  String get emergencyInstructionEmotional1 =>
      'You are not alone. Qualified, confidential help is available right now.';

  @override
  String get emergencyInstructionEmotional2 =>
      'Free, confidential 24/7 crisis support is available. In Brazil, dial 188 (CVV).';

  @override
  String get emergencyInstructionEmotional3 =>
      'If you feel in immediate danger, call emergency services (192) or go to the ER.';

  @override
  String get emergencyCallSamu => 'Call SAMU (192)';

  @override
  String get emergencyCallBombeiros => 'Call Fire / Rescue (193)';

  @override
  String get emergencyCallCvv => 'Call Crisis Line (188)';

  @override
  String get emergencyCallPolicia => 'Call Police (190)';

  @override
  String get emergencyFindHospital => 'Find Nearest Emergency Room';

  @override
  String get emergencyDispatcherHint =>
      'When calling, state your address clearly and stay calm.';

  @override
  String get emergencyExitButton => 'Return to Home (Not recommended)';

  @override
  String get emergencyExitConfirmTitle => 'Urgent Medical Attention';

  @override
  String get emergencyExitConfirmBody =>
      'Your symptoms indicate a life-threatening risk. We strongly advise contacting emergency services before leaving. Are you sure you want to exit?';

  @override
  String get emergencyExitConfirmStay => 'Stay on Emergency Screen';

  @override
  String get emergencyExitConfirmLeave => 'I Understand Risks / Exit';

  @override
  String get emergencyFallbackTitle => 'Calling Not Supported';

  @override
  String get emergencyFallbackBody =>
      'Direct calling is not supported on this device. Please dial the following number from another phone:';

  @override
  String get emergencyCopyNumber => 'Copy Number';

  @override
  String get emergencyCopiedToast => 'Number copied to clipboard.';

  @override
  String get triageBannerEmotional =>
      'Starting Psycho-Emotional Self-Assessment';

  @override
  String get triageBannerPhysical => 'Starting Physical Self-Assessment';

  @override
  String triageStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get triageNext => 'Next';

  @override
  String get triageBack => 'Back';

  @override
  String get triageConfirm => 'Confirm';

  @override
  String get triagePreviewTitle => 'Review Your Assessment';

  @override
  String get triagePreviewSubmit => 'Confirm and Submit';

  @override
  String get triageQ1Emotional =>
      'Looking at your emotional and mental side, which word best describes how you feel right now?';

  @override
  String get triageOptAnsiedade => 'Anxiety / Agitation';

  @override
  String get triageOptTristeza => 'Sadness / Low Mood';

  @override
  String get triageOptEstresse => 'Stress / Irritability';

  @override
  String get triageOptCansaco => 'Mental Fatigue';

  @override
  String get triageOptAnsiosaAgitacao => 'Anxious / Agitation';

  @override
  String get triageOptDepressivaDesanimo => 'Depressive / Low Mood';

  @override
  String get triageOptEstresseBurnout => 'Stress / Burnout';

  @override
  String get triageOptSomatica => 'Somatic (Psychosomatic)';

  @override
  String get triageOptSono => 'Sleep (Insomnia / Hypersomnia)';

  @override
  String get triageOptCognitivaFoco => 'Cognitive / Focus';

  @override
  String get triageOptAutoestima => 'Self-esteem / Self-image';

  @override
  String get triageQ2Emotional =>
      'Have you felt this way frequently in recent days or is it very specific to today?';

  @override
  String get triageOptComecouHoje => 'Started today';

  @override
  String get triageOptJaFazDias => 'A few days ago';

  @override
  String get triageOptConstanteSemanas => 'Constant for weeks';

  @override
  String get triageQ3Emotional =>
      'Does this feeling seem like a mild background nuisance or something strong accelerating your thoughts?';

  @override
  String get triageOptLeveControlavel => 'Mild and controllable';

  @override
  String get triageOptModerada => 'Moderate';

  @override
  String get triageOptMuitoForte => 'Very strong and hard to manage';

  @override
  String get triageQ4Emotional =>
      'Can you identify if there is a primary reason for this happening today?';

  @override
  String get triageQ4Ansiedade =>
      'What seems to be triggering this feeling of anxiety, restlessness, or tension?';

  @override
  String get triageQ4Depressao =>
      'Can you identify if a recent event or specific feeling contributed to this low mood?';

  @override
  String get triageQ4EstresseBurnout =>
      'Where is most of the pressure or exhaustion you are experiencing coming from?';

  @override
  String get triageQ4Somatica =>
      'In which situations does this physical tension or body discomfort tend to worsen?';

  @override
  String get triageQ4Sono =>
      'What has been the main issue disrupting your sleep?';

  @override
  String get triageQ4CognitivaFoco =>
      'What seems to be interfering most with your concentration or mental clarity?';

  @override
  String get triageQ4Autoestima =>
      'What has been triggering this sense of self-doubt or self-criticism most intensely?';

  @override
  String get triageOptTrabalho => 'Work / Studies';

  @override
  String get triageOptFamilia => 'Family / Relationships';

  @override
  String get triageOptNoiteRuim => 'Poor night of sleep';

  @override
  String get triageOptNaoSei => 'Cannot tell';

  @override
  String get triageOptSimCobrancaPrazos =>
      'Overwhelmed by tasks, deadlines, or expectations';

  @override
  String get triageOptSimConflitoRelacionamento =>
      'Conflict or argument with someone close';

  @override
  String get triageOptSimIncertezaFuturo =>
      'Fear of changes, news, or future uncertainty';

  @override
  String get triageOptSimExcessoEstimulantes =>
      'Excess coffee, energy drinks, or noisy environment';

  @override
  String get triageOptNaoSeiDizerEmocional =>
      'Cannot identify, started suddenly';

  @override
  String get triageOptSimPerdaLuto => 'Loss, breakup, or grieving';

  @override
  String get triageOptSimSolidaoIsolamento =>
      'Feeling lonely, isolated, or misunderstood';

  @override
  String get triageOptSimFrustracaoDesilusao =>
      'Disappointment when things did not go as hoped';

  @override
  String get triageOptSimCansacoAcumulado =>
      'Prolonged fatigue without recovery breaks';

  @override
  String get triageOptSimPressaoTrabalho =>
      'Excessive workload, demands, or tight deadlines';

  @override
  String get triageOptSimResponsabilidadesCasa =>
      'Family caregiving, finances, or household chores';

  @override
  String get triageOptSimFaltaDescanso =>
      'Lack of free time for leisure, rest, or disconnecting';

  @override
  String get triageOptSimAmbienteToxico =>
      'Difficult interpersonal dynamics or stressful routine';

  @override
  String get triageOptSimDuranteTrabalho =>
      'During work shifts or high-pressure moments';

  @override
  String get triageOptSimDiscussaoConflito =>
      'Immediately after arguments, conflicts, or shock';

  @override
  String get triageOptSimFinalDoDia =>
      'At the end of the day when attempting to rest or sleep';

  @override
  String get triageOptSimPreocupacaoConstante =>
      'Whenever thinking about challenging issues';

  @override
  String get triageOptSimDificuldadePegarSono =>
      'Racing thoughts or active mind at bedtime';

  @override
  String get triageOptSimAcordaMadrugada =>
      'Waking up in the middle of the night and unable to sleep';

  @override
  String get triageOptSimSonoAgitadoPesadelos =>
      'Restless, light sleep with nightmares or frequent waking';

  @override
  String get triageOptSimHorarioIrregularTelas =>
      'Late-night screen use or irregular sleep schedule';

  @override
  String get triageOptSimSobrecargaMultitarefas =>
      'Multitasking overload or too many stimuli at once';

  @override
  String get triageOptSimPreocupacaoIntrusiva =>
      'Intrusive worry thoughts interrupting focus';

  @override
  String get triageOptSimExaustaoMental =>
      'Mental exhaustion accumulated after prolonged effort';

  @override
  String get triageOptSimFaltaMotivacao =>
      'Disinterest, lack of energy, or apathy toward tasks';

  @override
  String get triageOptSimComparacaoRedes =>
      'Comparing yourself to others on social media or peers';

  @override
  String get triageOptSimMedoFalharJulgamento =>
      'Fear of failing, falling short, or being judged';

  @override
  String get triageOptSimCriticaRejeicao =>
      'Recent criticism received or feeling rejected';

  @override
  String get triageOptSimDesvalorizacaoPropria =>
      'Difficulty acknowledging your own accomplishments';

  @override
  String get triagePreviewEmotional =>
      'Review of your Psycho-Emotional Self-Assessment';

  @override
  String get triageQ1Physical =>
      'Let us talk about the physical aspect. Where are you feeling this primary discomfort or pain?';

  @override
  String get triageOptCabeca => 'Head';

  @override
  String get triageOptCostas => 'Back / Spine';

  @override
  String get triageOptArticulacoes => 'Joints (Knee, Shoulder, etc.)';

  @override
  String get triageOptAbdomen => 'Abdomen / Stomach';

  @override
  String get triageOptCabecaPescoco => 'Head and Neck';

  @override
  String get triageOptCardiovascularTorax => 'Cardiovascular / Chest';

  @override
  String get triageOptRespiratorio => 'Respiratory System';

  @override
  String get triageOptGastrointestinalAbdomen => 'Gastrointestinal / Abdomen';

  @override
  String get triageOptColunaDorDorsal => 'Spine and Back Pain';

  @override
  String get triageOptMembrosSuperiores => 'Upper Limbs R/L';

  @override
  String get triageOptMembrosInferiores => 'Lower Limbs R/L';

  @override
  String get triageOptNeurologico => 'Neurological System';

  @override
  String get triageOptGeniturinarioPelvico => 'Genitourinary / Pelvic';

  @override
  String get triageOptDermatologico => 'Dermatological System';

  @override
  String get triageOptMuscularGeralSistemico => 'Muscular / General Systemic';

  @override
  String get triageOptEndocrinoMetabolico => 'Endocrine / Metabolic';

  @override
  String get triageQ2Physical => 'How long has this pain or symptom persisted?';

  @override
  String get triageOptComecouAgora => 'Started just now';

  @override
  String get triageOptHaAlgunsDias => 'A few days ago';

  @override
  String get triageOptCronica => 'It is chronic';

  @override
  String get triageQ3Physical =>
      'On a scale of 1 to 5 (where 1 is barely noticeable and 5 is unbearable), how is it right now?';

  @override
  String get triageQ4Physical =>
      'Do you recall doing atypical strenuous exercise, heavy exertion, or suffering a fall/impact recently?';

  @override
  String get triageQ4CabecaPescoco =>
      'Did you notice any contributing factor, such as intense stress, prolonged screen time, poor sleep, or a cold/sinus issue?';

  @override
  String get triageQ4CardiovascularTorax =>
      'Did the chest discomfort or palpitations start after physical exertion, emotional stress, or stimulant intake?';

  @override
  String get triageQ4Respiratorio =>
      'Were you exposed to dust, smoke, cold air, or do you have symptoms of a cold or flu?';

  @override
  String get triageQ4Gastrointestinal =>
      'Did you eat something unusual or heavy, take medications recently, or fast for a prolonged period?';

  @override
  String get triageQ4ColunaDorDorsal =>
      'Did you lift heavy objects, remain in poor posture for a long time, or experience an impact/fall?';

  @override
  String get triageQ4MembrosSuperiores =>
      'Did you perform repetitive motions (typing, manual work), upper body training, or suffer an impact/fall?';

  @override
  String get triageQ4MembrosInferiores =>
      'Did you go on a long walk/run, stand or sit for many hours, or suffer a twist/trip/fall?';

  @override
  String get triageQ4Neurologico =>
      'Did the symptom occur after standing up quickly, skipping meals/water, anxiety, or an awkward posture?';

  @override
  String get triageQ4Geniturinario =>
      'Did you notice any link to low hydration, holding urine, menstrual cycle, intimacy, or wet/tight clothing?';

  @override
  String get triageQ4Dermatological =>
      'Did you notice anything that might have triggered this, like a new product, sun/heat exposure, or contact with something (plant, insect, substance)?';

  @override
  String get triageQ4MuscularGeral =>
      'Is this associated with extreme fatigue, early cold/flu symptoms, lack of rest, or dehydration?';

  @override
  String get triageQ4EndocrinoMetabolico =>
      'Did you notice any connection to prolonged fasting, sugary meals, medication changes, or intense heat?';

  @override
  String get triageOptSimExercicio => 'Yes, intense exercise';

  @override
  String get triageOptSimQueda => 'Yes, suffered a fall';

  @override
  String get triageOptNaoComecouNada => 'No, started out of nowhere';

  @override
  String get triageOptSimProdutoNovo =>
      'Yes, I used a new product (cosmetic, soap, etc.)';

  @override
  String get triageOptSimExposicaoSolCalor =>
      'Yes, there was sun exposure, heat, or intense sweating';

  @override
  String get triageOptSimPicadaContato =>
      'Yes, I had contact with a plant, insect, or substance';

  @override
  String get triageOptSimEstresseSono => 'Stress or irregular sleep';

  @override
  String get triageOptSimTelasEsforcoVisual =>
      'Prolonged screen time / eye strain';

  @override
  String get triageOptSimPosturaPescoco =>
      'Muscle tension or poor neck posture';

  @override
  String get triageOptSimResfriadoSinusite => 'Cold or sinusitis symptoms';

  @override
  String get triageOptSimEsforcoFisico =>
      'Right after physical exertion or walking';

  @override
  String get triageOptSimEstresseAnsiedade =>
      'During intense anxiety or stress';

  @override
  String get triageOptSimCafeinaEstimulante =>
      'After coffee, energy drink, or stimulant';

  @override
  String get triageOptNaoSurgiuEmRepouso =>
      'No, started spontaneously or at rest';

  @override
  String get triageOptSimAlergiaAmbiente =>
      'Exposure to dust, mold, smoke, or AC';

  @override
  String get triageOptSimGripeInfeccao => 'Cold, flu, or sore throat symptoms';

  @override
  String get triageOptSimMudancaClima => 'Sudden weather change or cold air';

  @override
  String get triageOptSimAlimentacaoDiferente =>
      'Unusual, heavy, or suspicious food';

  @override
  String get triageOptSimMedicamentoRecente =>
      'Recent medication or anti-inflammatory use';

  @override
  String get triageOptSimJejumEstresse => 'Prolonged fasting or intense stress';

  @override
  String get triageOptNaoSemRelacaoAlimento =>
      'No, started with no relation to food';

  @override
  String get triageOptSimCarregouPeso =>
      'Lifted heavy weight or strained lower back';

  @override
  String get triageOptSimPosturaProlongada =>
      'Prolonged sitting or poor sleeping posture';

  @override
  String get triageOptSimMauJeitoQueda =>
      'Awkward sudden movement or impact/fall';

  @override
  String get triageOptSimMovimentoRepetitivo =>
      'Repetitive motions (typing, phone, manual work)';

  @override
  String get triageOptSimTreinoSobrecarga =>
      'Exercise or strain on arms/shoulders';

  @override
  String get triageOptSimTraumaPancada =>
      'Impact, fall, or slept awkwardly on arm';

  @override
  String get triageOptSimCaminhadaCorrida => 'Long walk, run, or recent sports';

  @override
  String get triageOptSimTempoEmPeSentado =>
      'Many hours standing or prolonged sitting';

  @override
  String get triageOptSimTorcaoTropeco =>
      'Twisted ankle/knee, stumble, or fall';

  @override
  String get triageOptSimLevantarRapido =>
      'Standing up quickly or changing posture';

  @override
  String get triageOptSimJejumDesidratacao =>
      'Hours without eating or low water intake';

  @override
  String get triageOptSimAnsiedadeHiperventilacao =>
      'During moments of tension or rapid breathing';

  @override
  String get triageOptSimCompressaoPostural =>
      'Pressed limb or posture pinching a nerve';

  @override
  String get triageOptSimBaixaIngestaoUrina =>
      'Low water intake or held urine for too long';

  @override
  String get triageOptSimCicloMenstrual => 'Premenstrual or menstrual phase';

  @override
  String get triageOptSimPosRelacaoIntima =>
      'After sexual intercourse or new intimate products';

  @override
  String get triageOptSimRoupasUmidas => 'Wearing damp or very tight clothing';

  @override
  String get triageOptSimCansacoEsgotamento =>
      'Extreme tiredness, burnout, or sleepless nights';

  @override
  String get triageOptSimSintomasGripeVirose =>
      'Feverish feeling, chills, or viral illness';

  @override
  String get triageOptSimAtividadeGlobal =>
      'Unusual whole-body activity (moving, heavy chores)';

  @override
  String get triageOptSimDesidratacaoCalor =>
      'Low hydration or prolonged heat exposure';

  @override
  String get triageOptSimJejumAlimentacao =>
      'Hours without eating or after sugary/heavy food';

  @override
  String get triageOptSimAjusteMedicamento =>
      'Missed or adjusted regular medication dose';

  @override
  String get triageOptSimCalorDesidratacao =>
      'Very hot environment or low fluid intake';

  @override
  String get triageOptSimEstresseSobrecarga =>
      'Recent stress peak or disrupted routine';

  @override
  String get triagePreviewPhysical => 'Review of your Physical Assessment';

  @override
  String triageIntensityLabel(int value) {
    return 'Intensity: $value';
  }

  @override
  String get triageIntensityMin => 'Barely noticeable';

  @override
  String get triageIntensityMax => 'Unbearable';

  @override
  String get outcomeScreenTitle => 'Triage Result';

  @override
  String get outcomeScreenSubtitle =>
      'Preventive assessment based on your responses';

  @override
  String get outcomeIntensityTitle => 'Calculated Intensity';

  @override
  String get outcomeIntensityDescription =>
      'Score calculated on the clinical scale from 1 to 5';

  @override
  String get outcomeDispositionTitle => 'Care Recommendation';

  @override
  String get outcomeDispositionSelfCare => 'Monitored Self-Care';

  @override
  String get outcomeDispositionSelfCareDesc =>
      'Rest, adequate hydration, and symptom observation over the next 24 hours.';

  @override
  String get outcomeDispositionRoutine => 'Routine Consultation';

  @override
  String get outcomeDispositionRoutineDesc =>
      'Schedule a preventive appointment with a healthcare professional over the coming days.';

  @override
  String get outcomeDispositionUrgent => 'Urgent Care';

  @override
  String get outcomeDispositionUrgentDesc =>
      'Seek in-person medical evaluation at a clinical care facility within 24 hours.';

  @override
  String get outcomeDispositionEmergency => 'Emergency Care';

  @override
  String get outcomeDispositionEmergencyDesc =>
      'Your symptoms require immediate medical attention. Visit the nearest emergency room or dial emergency services.';

  @override
  String get outcomeOrganicPrimacyTitle => 'Clinical Notice: Organic Primacy';

  @override
  String get outcomeOrganicPrimacyDesc =>
      'Physical symptoms accompanying emotional distress require prior medical evaluation before being attributed solely to psychological stress.';

  @override
  String get outcomeArticlesTitle => 'Recommended Medical Articles';

  @override
  String get outcomeArticlesSubtitle =>
      'Evidence-based preventive guides written by renowned medical specialists';

  @override
  String outcomeReadTime(int minutes) {
    return '$minutes min read';
  }

  @override
  String get outcomeDoneButton => 'Finish and Return Home';

  @override
  String get antiburlaTitle => 'Historical Verification';

  @override
  String antiburlaDialogPrompt(int days) {
    return 'You recorded a similar symptom $days days ago. Is this the same sensation returning or something completely new?';
  }

  @override
  String get antiburlaOptionRecurring => 'It\'s the same sensation returning';

  @override
  String get antiburlaOptionRecurringDesc =>
      'We will adjust the onset to \'A few days ago\' to keep your clinical history consistent.';

  @override
  String get antiburlaOptionNew => 'It\'s a completely new feeling';

  @override
  String get antiburlaOptionNewDesc =>
      'We will keep it recorded as an acute event starting today.';

  @override
  String get antiburlaBiologicalDiscordanceTitle => 'Preventive Anatomy Notice';

  @override
  String get antiburlaBiologicalDiscordanceDesc =>
      'We noticed a discrepancy between the anatomical region selected and your profile parameters. Would you like to review before proceeding?';

  @override
  String get offTopicNarrativeTitle => 'Does this look like a symptom?';

  @override
  String get offTopicNarrativeDesc =>
      'The text you wrote doesn\'t seem to describe a physical or emotional symptom. Would you like to review your description or continue anyway?';

  @override
  String get offTopicNarrativeEditButton => 'Edit Description';

  @override
  String get offTopicNarrativeContinueButton => 'Continue Anyway';

  @override
  String get offlineBannerText =>
      'Offline Mode — Your check-ins will be saved locally and synced automatically once connection is restored.';

  @override
  String offlineSyncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending sync check-ins',
      one: '1 pending sync check-in',
    );
    return '$_temp0';
  }

  @override
  String get offlineSyncSuccessText =>
      'Synchronization completed successfully.';

  @override
  String get offlineModeNotice =>
      'You are offline. Your triage assessment continues to function seamlessly.';

  @override
  String get historyScreenTitle => 'History & Trends';

  @override
  String get tabEmotional => 'Psycho-Emotional';

  @override
  String get tabPhysical => 'Physical';

  @override
  String get bodyMapTitle => '2D Body Map (14 Days)';

  @override
  String get bodyMapHint => 'Tap a region to view details';

  @override
  String get heatLegendNone => 'No pain';

  @override
  String get heatLegendMild => 'Mild (1-2)';

  @override
  String get heatLegendModerate => 'Moderate (3)';

  @override
  String get heatLegendSevere => 'Severe (4-5)';

  @override
  String get emotionalChartTitle => 'Emotional Evolution (7 Days)';

  @override
  String get criticalRecurrenceTitle => 'Focus of Attention';

  @override
  String get retrospectiveFeedTitle => 'Past Records';

  @override
  String get emptyHistoryTitle => 'No records yet';

  @override
  String get emptyHistorySubtitle =>
      'Your completed daily check-ins will appear here.';

  @override
  String get readRecommendedArticle => 'Read Recommended Article';

  @override
  String get privacyCenterTitle => 'Privacy & Data (LGPD)';

  @override
  String get exportDataTitle => 'Data Export';

  @override
  String get exportDataDesc =>
      'Download a complete copy of your personal data and clinical history in JSON format under LGPD Art. 18, V.';

  @override
  String get exportDataButton => 'Export Data (JSON)';

  @override
  String get exportSuccessMessage => 'Data exported successfully.';

  @override
  String get deleteAccountTitle => 'Permanent Account Deletion';

  @override
  String get deleteAccountDesc =>
      'Permanently delete your account and all health records under LGPD Art. 18. This action cannot be undone.';

  @override
  String get deleteAccountButton => 'Delete My Account';

  @override
  String get deleteConfirmTitle => 'Confirm Permanent Deletion';

  @override
  String get deleteConfirmDesc =>
      'To confirm the irreversible deletion of your account and all health data, enter your password:';

  @override
  String get deleteSuccessMessage => 'Account and data deleted successfully.';

  @override
  String get confirmPermanentDeletion => 'Confirm Permanent Deletion';

  @override
  String get enterPassword => 'Confirmation password';

  @override
  String get previewDataTitle => 'Exported Data Preview';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileSection => 'Profile & Identity';

  @override
  String get changeAvatar => 'Change Picture';

  @override
  String get selectAvatar => 'Choose your Avatar';

  @override
  String get nameLabel => 'Full Name';

  @override
  String get dateOfBirthLabel => 'Date of Birth';

  @override
  String get ageLabel => 'Age';

  @override
  String yearsOld(int age) {
    return '$age years old';
  }

  @override
  String get saveProfile => 'Save Changes';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully!';

  @override
  String get securitySection => 'Security & Access';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get currentPasswordHint => 'Enter your current password';

  @override
  String get newPasswordHint => 'Enter secure new password';

  @override
  String get confirmPasswordHint => 'Repeat the new password';

  @override
  String get passwordChangedSuccess => 'Password changed successfully!';

  @override
  String get passwordsDoNotMatch => 'The new passwords do not match.';

  @override
  String get passwordComplexityHint =>
      'Minimum 8 characters, with uppercase, lowercase, number, and special character.';

  @override
  String get privacyShortcut => 'Privacy & Data Center (LGPD)';

  @override
  String get logoutButton => 'Log Out';

  @override
  String get settingsLanguageSection => 'App Language';

  @override
  String get settingsLanguagePortuguese => 'Português (Brasil)';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsPrivacySection => 'Privacy & Data';

  @override
  String get settingsPrivacyCenterTile => 'Privacy & Data Center (LGPD)';

  @override
  String get settingsPrivacyCenterSubtitle =>
      'Access and manage your health data';

  @override
  String get settingsDataHistoryTile => 'History & Trends';

  @override
  String get settingsDataHistorySubtitle => 'View your triage history';

  @override
  String get deleteHistoryItemTitle => 'Delete history record';

  @override
  String get deleteHistoryItemConfirm =>
      'Are you sure you want to discard this triage record from your history? This action cannot be undone.';

  @override
  String get deleteHistoryItemSuccess => 'Record removed successfully.';

  @override
  String get deleteHistoryItemError => 'Não foi possível remover o registro.';

  @override
  String get deleteAction => 'Delete';

  @override
  String get errorNetworkConnection =>
      'Unable to connect to the server. Please check your internet connection.';

  @override
  String get errorConnectionTimeout =>
      'The server took too long to respond. Please try again.';

  @override
  String get errorInvalidCredentials =>
      'Incorrect email or password. Please verify your credentials.';

  @override
  String get errorEmailAlreadyExists =>
      'This email address is already registered on our platform.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorEmailVerificationCodeInvalid =>
      'Incorrect or expired verification code. Check the digits or request a new code.';

  @override
  String get emailVerificationSuccess =>
      'Email verified successfully! Welcome to DualisCheckUp.';

  @override
  String get newCodeSentSuccess => 'A new code has been sent to your email.';

  @override
  String get errorUpdateProfile =>
      'Could not update profile. Please try again.';

  @override
  String get errorChangePassword =>
      'Could not change password. Please verify your current password.';

  @override
  String get errorCameraGalleryAccess =>
      'Could not access camera or photo gallery on device.';

  @override
  String get errorFieldRequired => 'This field is required.';

  @override
  String get errorCurrentPasswordRequired => 'Enter your current password.';

  @override
  String get errorNewPasswordMinLength =>
      'New password must be at least 8 characters.';

  @override
  String get errorPasswordLettersAndDigits =>
      'Password must contain letters and numbers.';

  @override
  String get errorNameMinLength => 'Name must have at least 2 characters.';

  @override
  String get selectDateOfBirthHint => 'Select your date of birth';

  @override
  String get errorLoadHistory =>
      'Unable to load triage history at this moment.';

  @override
  String get errorArticleLinkUnavailable =>
      'Preventive article link unavailable.';

  @override
  String get errorUnableToOpenLink => 'Could not open the requested link.';

  @override
  String get errorServerInternal =>
      'Our services are experiencing temporary instability. Please try again shortly.';

  @override
  String get errorUnexpected =>
      'An unexpected error occurred. Please try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navTodayOutcome => 'Today\'s Result';

  @override
  String get navHistory => 'History & Map';
}
