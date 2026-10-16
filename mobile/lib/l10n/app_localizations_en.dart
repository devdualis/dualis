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
  String get valueCard1Title => 'Integrated Wellness Journal';

  @override
  String get valueCard1Body =>
      'Log how you feel in body and mind in a single 1-minute daily check-in.';

  @override
  String get valueCard2Title => 'Your Data, Protected';

  @override
  String get valueCard2Body =>
      'Your wellness entries are encrypted and under your control, in line with the LGPD.';

  @override
  String get valueCard3Title => 'Content for Healthy Habits';

  @override
  String get valueCard3Body =>
      'Short, general reads on sleep, stress, posture, hydration and more.';

  @override
  String get lgpdConsentCheckbox =>
      'I have read and agree to the Privacy Policy and give specific and prominent consent to the processing of my sensitive personal health data to record and view my wellness journal, under Art. 11, I of the LGPD.';

  @override
  String get privacyVeilTitle => 'Protected Health Data';

  @override
  String get privacyVeilBody =>
      'Authenticate with biometrics or passcode to access your entries.';

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
  String get emergencyTitle => 'Need help now?';

  @override
  String get emergencySubtitle =>
      'If you or someone near you is in danger, call emergency services. Don\'t wait.';

  @override
  String get emergencyFindHospital => 'Find the nearest emergency room';

  @override
  String get emergencyDispatcherHint =>
      'When calling, state your address clearly and stay calm.';

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
  String get triageBannerEmotional => 'Today\'s emotional check-in';

  @override
  String get triageBannerPhysical => 'Today\'s physical check-in';

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
  String get triagePreviewTitle => 'Review your entry';

  @override
  String get triagePreviewSubmit => 'Confirm and Submit';

  @override
  String get triageQ1Emotional =>
      'Looking at your emotional and mental side, which word best describes how you feel right now?';

  @override
  String get triageOptNormal => 'Normal / Feeling well';

  @override
  String get triageSaveNormal => 'Complete as Normal / Well';

  @override
  String get triageOptAnsiedade => 'Anxiety / Agitation';

  @override
  String get triageOptTristeza => 'Sadness / Low Mood';

  @override
  String get triageOptEstresse => 'Stress / Irritability';

  @override
  String get triageOptCansaco => 'Mental Fatigue';

  @override
  String get triageOptAnsiosaAgitacao => 'Restless / Agitated';

  @override
  String get triageOptDepressivaDesanimo => 'Feeling low / Discouraged';

  @override
  String get triageOptEstresseBurnout => 'Stressed / Worn out';

  @override
  String get triageOptSomatica => 'Tension in the body';

  @override
  String get triageOptSono => 'Poor sleep or too much sleep';

  @override
  String get triageOptCognitivaFoco => 'Trouble focusing';

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
  String get triagePreviewEmotional => 'Review your entry';

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
  String get triageOptCabecaPescoco => 'Head and neck';

  @override
  String get triageOptCardiovascularTorax => 'Chest';

  @override
  String get triageOptRespiratorio => 'Breathing';

  @override
  String get triageOptGastrointestinalAbdomen => 'Belly';

  @override
  String get triageOptColunaDorDorsal => 'Back';

  @override
  String get triageOptMembrosSuperiores => 'Arms';

  @override
  String get triageOptMembrosInferiores => 'Legs';

  @override
  String get triageOptNeurologico => 'Dizziness / tingling';

  @override
  String get triageOptGeniturinarioPelvico => 'Intimate / urinary area';

  @override
  String get triageOptDermatologico => 'Skin';

  @override
  String get triageOptMuscularGeralSistemico => 'Whole body / tiredness';

  @override
  String get triageOptEndocrinoMetabolico => 'Thirst, hunger or energy';

  @override
  String get triageQ2Physical =>
      'How long have you been feeling this discomfort?';

  @override
  String get triageOptComecouAgora => 'Started just now';

  @override
  String get triageOptHaAlgunsDias => 'A few days ago';

  @override
  String get triageOptCronica => 'It\'s been going on for a long time';

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
  String get triagePreviewPhysical => 'Review your entry';

  @override
  String triageIntensityLabel(int value) {
    return 'Intensity: $value';
  }

  @override
  String get triageIntensityMin => 'Barely noticeable';

  @override
  String get triageIntensityMax => 'Unbearable';

  @override
  String get outcomeScreenTitle => 'Your entry summary';

  @override
  String get outcomeScreenSubtitle => 'A snapshot of what you logged today';

  @override
  String get outcomeIntensityTitle => 'Intensity you reported';

  @override
  String get outcomeIntensityDescription =>
      'Your own 1–5 rating for how you felt';

  @override
  String get outcomeArticlesTitle => 'Wellness reading';

  @override
  String get outcomeArticlesSubtitle =>
      'General educational content. Not guidance for your situation.';

  @override
  String outcomeReadTime(int minutes) {
    return '$minutes min read';
  }

  @override
  String get outcomeDoneButton => 'Finish and Return Home';

  @override
  String get antiburlaTitle => 'Has this come up before?';

  @override
  String antiburlaDialogPrompt(int days) {
    return 'You recorded a similar symptom $days days ago. Is this the same sensation returning or something completely new?';
  }

  @override
  String get antiburlaOptionRecurring => 'It\'s the same sensation returning';

  @override
  String get antiburlaOptionRecurringDesc =>
      'We\'ll log this as something that came back, to keep your journal organized.';

  @override
  String get antiburlaOptionNew => 'It\'s a completely new feeling';

  @override
  String get antiburlaOptionNewDesc =>
      'We will keep it recorded as an acute event starting today.';

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
      'You are offline. Your entries keep working normally.';

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
  String get heatLegendNone => 'No entries';

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
  String get readRecommendedArticle => 'Read article';

  @override
  String get privacyCenterTitle => 'Privacy & Data (LGPD)';

  @override
  String get exportDataTitle => 'Data Export';

  @override
  String get exportDataDesc =>
      'Download a complete copy of your personal data and wellness entries in JSON format under LGPD Art. 18, V.';

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
  String get settingsDataHistorySubtitle => 'View your entry history';

  @override
  String get deleteHistoryItemTitle => 'Delete history record';

  @override
  String get deleteHistoryItemConfirm =>
      'Are you sure you want to discard this entry from your history? This action cannot be undone.';

  @override
  String get deleteHistoryItemSuccess => 'Record removed successfully.';

  @override
  String get deleteHistoryItemError => 'Could not remove the record.';

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
  String get errorLoadHistory => 'Unable to load your entry history right now.';

  @override
  String get errorArticleLinkUnavailable => 'Article link not available.';

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
  String get navTodayOutcome => 'My Day';

  @override
  String get navHistory => 'History & Map';

  @override
  String get navHydration => 'Water';

  @override
  String get notifWaterTitle => '💧 Time to Drink Water';

  @override
  String notifWaterTitleAt(String time) {
    return '💧 Time to Drink Water ($time)';
  }

  @override
  String get notifWaterBodyTracking => 'Tap to log how much water you drank.';

  @override
  String get notifWaterBodyReminder => 'Keep your body hydrated and healthy!';

  @override
  String get notifWaterChimeChannelName => 'Water Reminders (Soft Chime)';

  @override
  String get notifWaterChimeChannelDescription =>
      'Message-style alert reminding you to stay hydrated';

  @override
  String get notifWaterAlarmChannelName => 'Water Reminders (Alarm Sound)';

  @override
  String get notifWaterAlarmChannelDescription =>
      'Alarm sound reminding you to drink water every 2 hours';

  @override
  String notifCheckinTitleAt(String time) {
    return '🌿 Dualis Daily Check-in ($time)';
  }

  @override
  String get notifCheckinBody =>
      'You haven\'t made today\'s entry yet. Tap to check in!';

  @override
  String get notifCheckinChannelName => 'Daily Check-in Reminders';

  @override
  String get notifCheckinChannelDescription =>
      'Notifications every 2 hours to remind you of your daily wellness check-in';

  @override
  String get outcomeAxisPhysicalNumbered => '1. Physical Assessment Axis';

  @override
  String get outcomeAxisEmotionalNumbered =>
      '2. Psycho-emotional Assessment Axis';

  @override
  String get familySharingTitle => 'Family Sharing';

  @override
  String get familySharingTabOutgoing => 'Who can see my data';

  @override
  String get familySharingTabIncoming => 'Shared with me';

  @override
  String get familySharingUnavailableTitle => 'Feature not available yet';

  @override
  String get familySharingUnavailableBody =>
      'Family sharing is coming in a future version of DualisCheckUp.';

  @override
  String get familySharingInviteButton => 'Invite a Family Member or Caregiver';

  @override
  String get familySharingEnterCodeButton =>
      'Have an invite code? Enter and Accept';

  @override
  String get familySharingEmptyOutgoing =>
      'Nobody has access to your data right now.';

  @override
  String get familySharingEmptyIncoming =>
      'No family member has shared data with you yet.';

  @override
  String get familySharingScopeViewOnly => 'View Only';

  @override
  String get familySharingScopeCoManage => 'Co-management';

  @override
  String get familySharingScopeViewOnlyOption => 'View Only (Recommended)';

  @override
  String get familySharingScopeCoManageOption =>
      'Co-management (Can add entries)';

  @override
  String familySharingActiveSince(String date) {
    return 'Active since $date';
  }

  @override
  String get familySharingActive => 'Active access';

  @override
  String familySharingPendingUntil(String code, String date) {
    return 'Code $code · awaiting acceptance until $date';
  }

  @override
  String get familySharingExpired => 'Invite expired';

  @override
  String get familySharingRevokeButton => 'Revoke Access';

  @override
  String get familySharingRevokeConfirmTitle => 'Revoke access?';

  @override
  String get familySharingRevokeConfirmBody =>
      'Are you sure? Access will stop immediately.';

  @override
  String get familySharingCancel => 'Cancel';

  @override
  String get familySharingRevoked => 'Access revoked.';

  @override
  String get familySharingRevokeError =>
      'Could not revoke access. Please try again.';

  @override
  String get familySharingInviteTitle => 'Invite a Family Member or Caregiver';

  @override
  String get familySharingInviteProfileLabel => 'Profile to share';

  @override
  String get familySharingInviteScopeLabel => 'Permission';

  @override
  String get familySharingInviteGenerate => 'Generate Code';

  @override
  String get familySharingInviteError =>
      'Could not create the invite. Please try again.';

  @override
  String get familySharingInviteCodeHint =>
      'Send this code to your family member. It expires in 72 hours.';

  @override
  String familySharingInviteDeadline(String date) {
    return 'Valid until $date';
  }

  @override
  String get familySharingCopyCode => 'Copy Code';

  @override
  String get familySharingCodeCopied => 'Code copied.';

  @override
  String get familySharingDone => 'Done';

  @override
  String get familySharingAcceptTitle => 'Enter invite code';

  @override
  String get familySharingAcceptFieldLabel => '6-character code';

  @override
  String get familySharingAcceptSubmit => 'Accept Invite';

  @override
  String get familySharingAcceptError => 'Invalid or expired code.';

  @override
  String get familySharingAccepted =>
      'Invite accepted. The profile is now in your list.';

  @override
  String get addDependentTitle => 'Register Legal Dependent';

  @override
  String get addDependentNameLabel => 'Dependent\'s full name';

  @override
  String get addDependentDobLabel => 'Date of birth';

  @override
  String get addDependentDobHint => 'Tap to select';

  @override
  String get addDependentDobPickerHelp => 'Select date of birth';

  @override
  String get addDependentDobInvalid => 'Enter a valid date of birth.';

  @override
  String get addDependentDobFuture => 'Date of birth cannot be in the future.';

  @override
  String get addDependentRelationshipLabel =>
      'Relationship / legal representation';

  @override
  String get addDependentRelationshipHint => 'Select legal relationship';

  @override
  String get addDependentRelationshipParent =>
      'Minor child (parental authority)';

  @override
  String get addDependentRelationshipCurator =>
      'Court-appointed curator of an incapacitated adult';

  @override
  String get addDependentRelationshipLegalGuardian =>
      'Legal guardian of a minor';

  @override
  String get addDependentLgpdArt14Consent =>
      'I declare, under penalty of law, that I am the parent or legal representative of this dependent and expressly authorize the collection and processing of their wellness data on the DualisCheckUp platform, in strict compliance with Article 14 of the LGPD (Law 13.709/2018).';

  @override
  String get addDependentSubmit => 'Register Dependent';

  @override
  String get addDependentSuccess => 'Dependent registered successfully.';

  @override
  String get addDependentGenericError =>
      'Could not register the dependent. Please try again.';

  @override
  String get profileSwitcherSheetTitle => 'Profiles';

  @override
  String get profileSwitcherMyProfile => 'My Profile';

  @override
  String get profileSwitcherDependents => 'My Dependents (Legal Guardianship)';

  @override
  String get profileSwitcherShared => 'Shared Profiles (Optional)';

  @override
  String get profileSwitcherAddDependent => '+ Add Legal Dependent';

  @override
  String get profileSwitcherManageSharing => 'Manage Family Sharing';

  @override
  String get profileSwitcherRenameTitle => 'Rename Profile';

  @override
  String get profileSwitcherRenameLabel => 'Profile name';

  @override
  String get profileSwitcherRenameSave => 'Save';

  @override
  String get profileSwitcherRenameCancel => 'Cancel';

  @override
  String get profileSwitcherDeleteTitle => 'Delete Profile?';

  @override
  String profileSwitcherDeleteConfirm(String name) {
    return 'Are you sure you want to delete profile \"$name\"? This action cannot be undone.';
  }

  @override
  String get profileSwitcherDeleteAction => 'Delete';

  @override
  String get profileSwitcherClose => 'Close';

  @override
  String get profileSwitcherBadgeMinor => 'Minor';

  @override
  String get profileSwitcherBadgeAdult => 'Adult dependent';

  @override
  String get profileSwitcherBadgeViewOnly => 'View only';

  @override
  String get profileSwitcherBadgeCoManage => 'Co-management';

  @override
  String get profileSwitcherBadgePrimary => 'Primary';

  @override
  String get profileSwitcherNoDependents => 'No dependents registered.';

  @override
  String get profileSwitcherNoShared => 'No profiles shared with you.';

  @override
  String get profileSwitcherActionError =>
      'Could not complete the action. Please try again.';

  @override
  String get familySharingCancelInvite => 'Cancel Invite';

  @override
  String activeProfileBannerDataOf(String profileName) {
    return 'Showing $profileName\'s data';
  }

  @override
  String get activeProfileBannerSwitchToMine => 'My profile';

  @override
  String get activeProfileReadOnlyNote => 'Read-only';

  @override
  String activeProfileCardTitle(String profileName) {
    return '$profileName\'s profile';
  }

  @override
  String get emergencyMapsQuery => 'emergency room';

  @override
  String get safetyClose => 'Close';

  @override
  String safetyCallLine(String name, String number) {
    return 'Call $name ($number)';
  }

  @override
  String get safetyKindEmergency => 'Emergency services';

  @override
  String get safetyKindAmbulance => 'Ambulance';

  @override
  String get safetyKindFire => 'Fire department';

  @override
  String get safetyKindPolice => 'Police';

  @override
  String get safetyKindEmotionalSupport => 'Emotional support';

  @override
  String get safetyKindHealthLine => 'Health line';

  @override
  String get safetyFree24h => '24/7, free';

  @override
  String safetyWarningSignsTitle(String number) {
    return 'Call $number right away if you or someone else has:';
  }

  @override
  String get safetyWarningSign1 => 'strong pain or pressure in the chest';

  @override
  String get safetyWarningSign2 => 'severe shortness of breath';

  @override
  String get safetyWarningSign3 =>
      'a drooping face, weakness on one side of the body or slurred speech';

  @override
  String get safetyWarningSign4 =>
      'the worst headache of your life, starting suddenly';

  @override
  String get safetyWarningSign5 => 'fainting or a seizure';

  @override
  String get safetyWarningSign6 => 'bleeding that won\'t stop';

  @override
  String get safetyWarningSignsSource =>
      'Source: Ministério da Saúde (Brazil) / SAMU';

  @override
  String safetyCrisisWithLine(String crisis, String emergency) {
    return 'If you are thinking about hurting yourself or ending your life, call $crisis or $emergency.';
  }

  @override
  String safetyCrisisNoLine(String emergency) {
    return 'If you are thinking about hurting yourself or ending your life, call $emergency or contact your local crisis line.';
  }

  @override
  String safetyLocalNumberHint(String number) {
    return 'If $number doesn\'t work where you are, call your local emergency number.';
  }

  @override
  String safetyNoticeGeneral(String number) {
    return 'If this is an emergency, don\'t use the app: call $number now.';
  }

  @override
  String get safetyNoticeOpenResources => 'See help contacts';

  @override
  String get urgentHelpButton => 'Urgent help';

  @override
  String get lgpdConsentPrefix => 'I have read and agree to the ';

  @override
  String get lgpdConsentTermsLink => 'Terms of Service';

  @override
  String get lgpdConsentAnd => ' and the ';

  @override
  String get lgpdConsentPrivacyLink => 'Privacy Policy';

  @override
  String get lgpdConsentSuffix =>
      ', and give specific and prominent consent to the processing of my sensitive personal health data to record and view my wellness journal, under Art. 11, I of the LGPD. ';

  @override
  String get lgpdConsentLearnMore => '(Learn more)';

  @override
  String get lgpdConsentSheetTitle =>
      'Privacy Policy and Consent (LGPD Art. 11, I)';

  @override
  String get lgpdConsentSheetBody =>
      'DualisCheckUp is a wellness and self-awareness app. It helps you keep a daily journal of how you feel physically and emotionally, track habits such as hydration and sleep, view your own entries over time, and access general educational content about healthy habits. DualisCheckUp is not a medical device: it does not assess, classify or interpret symptoms, does not indicate urgency levels, does not diagnose, does not recommend treatment and does not replace a healthcare professional. In an emergency, call your local emergency number. If you are in emotional distress, contact your local crisis line.';

  @override
  String get lgpdConsentSheetBasesTitle => 'Applicable laws:';

  @override
  String get lgpdConsentSheetBases =>
      '• Law 13,709/2018 (LGPD): Art. 7 and Art. 11 (processing of personal and sensitive health data), Art. 14 (data of children and adolescents) and Art. 18 (data subject rights).\n• Consumer Protection Code (CDC): Art. 49 - 7-day right of withdrawal.';

  @override
  String get lgpdConsentViewTerms => 'View Terms of Service';

  @override
  String get lgpdConsentViewPolicy => 'View Full Policy';

  @override
  String get termsAppBarTitle => 'SaaS Terms of Service';

  @override
  String get termsHeaderTitle => 'Terms and Conditions of Use';

  @override
  String get termsVersionLine => 'Version 2026.2 • Updated on 10/16/2026';

  @override
  String get termsIntro =>
      'Cloud software service (SaaS) agreement between the User and DualisCheckUp Saúde e Tecnologia Ltda., registered under CNPJ no. 48.291.834/0001-92, headquartered in São Paulo/SP, Brazil.';

  @override
  String get termsSection1Title => '1. Acceptance and Legal Capacity';

  @override
  String get termsSection1Body =>
      'By signing up for or using DualisCheckUp, you declare that you have full legal capacity (18 years or older, or legally emancipated) and fully agree to these Terms of Service and our Privacy Policy.';

  @override
  String get termsSection2Title => '2. Nature of the Service';

  @override
  String get termsSection2Body =>
      'DualisCheckUp is a wellness and self-awareness app. It helps you keep a daily journal of how you feel physically and emotionally, track habits such as hydration and sleep, view your own entries over time, and access general educational content about healthy habits. DualisCheckUp is not a medical device: it does not assess, classify or interpret symptoms, does not indicate urgency levels, does not diagnose, does not recommend treatment and does not replace a healthcare professional. In an emergency, call your local emergency number. If you are in emotional distress, contact your local crisis line.';

  @override
  String get termsSection2Bullet1 =>
      'It does not assess symptoms, indicate urgency, diagnose or recommend treatment.';

  @override
  String get termsSection2Bullet2 =>
      'Intensities and other information shown are the ones you entered yourself.';

  @override
  String get termsSection2Bullet3 =>
      'In an emergency in Brazil, call 192 (SAMU) or 188 (CVV); elsewhere, call your local emergency number.';

  @override
  String get termsSection3Title => '3. SaaS Plans, Billing and Refunds';

  @override
  String get termsSection3Body =>
      'Additional features may be offered in automatically renewing plans, processed by third-party payment providers:';

  @override
  String get termsSection3Bullet1 =>
      'Easy Cancellation: You can cancel your subscription at any time in the app with one tap, with no lock-in or cancellation fees.';

  @override
  String get termsSection3Bullet2 =>
      'Right of Withdrawal (CDC Art. 49): Full refund guaranteed within 7 (seven) calendar days of the initial purchase.';

  @override
  String get termsSection3Bullet3 =>
      'Continued Access: Cancelling stops future invoices and keeps your access until the end of the paid monthly cycle.';

  @override
  String get termsSection4Title => '4. Intellectual Property';

  @override
  String get termsSection4Body =>
      'All intellectual property rights in the software, content, trademarks and interfaces belong exclusively to DualisCheckUp Saúde e Tecnologia Ltda. Copying, reverse engineering or data scraping is strictly prohibited.';

  @override
  String get termsSection5Title => '5. Suspension for Security Violations';

  @override
  String get termsSection5Body =>
      'Accounts that attempt intrusions, brute-force attacks, unauthorized penetration tests or submit fraudulent data will be blocked immediately and reported to the competent authorities.';

  @override
  String get termsSection6Title => '6. Jurisdiction and Legal Contact';

  @override
  String get termsSection6Body =>
      'These terms are governed by Brazilian law. The courts of the Judicial District of São Paulo/SP are the sole forum for disputes arising from this agreement.\n\nFor questions or legal notices: legal@dualischeckup.com.';

  @override
  String get privacyPolicyAppBarTitle => 'Privacy Policy (LGPD)';

  @override
  String get privacyPolicyHeaderTitle => 'Privacy Policy & Data Protection';

  @override
  String get privacyPolicyHeaderSubtitle =>
      'Compliance with Brazil\'s General Data Protection Law (LGPD - Law 13,709/2018)';

  @override
  String get privacyPolicyIntro =>
      'Your privacy and the confidentiality of your health data are our top priority. This policy explains how we process and protect your information and how you stay in full control of it.';

  @override
  String get privacyPolicyDpoLine =>
      'Data Protection Officer (DPO): dpo@dualischeckup.com';

  @override
  String get privacyPolicySection1Title =>
      '1. Personal and Sensitive Data We Collect';

  @override
  String get privacyPolicySection1Body =>
      'Under Article 11 of the LGPD, sensitive personal health data is processed with your specific and prominent consent (Art. 11, I):';

  @override
  String get privacyPolicySection1Bullet1 =>
      'Identification Data: Full name, email address and date of birth.';

  @override
  String get privacyPolicySection1Bullet2 =>
      'Profile Data: Biological sex and water intake, used to set your hydration goals.';

  @override
  String get privacyPolicySection1Bullet3 =>
      'Wellness Journal: Notes on how you feel physically and emotionally and the intensity you report.';

  @override
  String get privacyPolicySection1Bullet4 =>
      'Technical Access Data: Masked IP address, cryptographic session logs and short-lived authentication tokens.';

  @override
  String get privacyPolicySection2Title =>
      '2. Purposes and Ban on Selling Data';

  @override
  String get privacyPolicySection2Body =>
      'Your health data is processed only for:';

  @override
  String get privacyPolicySection2Bullet1 =>
      'Recording and viewing your wellness journal.';

  @override
  String get privacyPolicySection2Bullet2 =>
      'Automatically organizing your notes by body area or mood (AI-assisted, with no health assessment).';

  @override
  String get privacyPolicySection2Bullet3 => 'Keeping your history consistent.';

  @override
  String get privacyPolicySection2Bullet4 =>
      'Ethical Commitment: Selling, trading or transferring your data for payment to insurers, advertisers or third parties is expressly PROHIBITED.';

  @override
  String get privacyPolicySection3Title =>
      '3. Processors and International Transfer';

  @override
  String get privacyPolicySection3Body =>
      'To provide the service, we share data only with:';

  @override
  String get privacyPolicySection3Bullet1 =>
      'Google LLC (Gemini API): The text of your notes is sent to Google\'s Gemini API to organize them automatically. The AI does not assess your health.';

  @override
  String get privacyPolicySection3Bullet2 =>
      'International Transfer: This processing may take place on servers located outside Brazil (LGPD Art. 33).';

  @override
  String get privacyPolicySection3Bullet3 =>
      'Cloud Infrastructure: Hosting and database providers, bound by confidentiality and security obligations.';

  @override
  String get privacyPolicySection4Title => '4. Payments';

  @override
  String get privacyPolicySection4Body =>
      'When paid plans are available, card data stays isolated from our servers:';

  @override
  String get privacyPolicySection4Bullet1 =>
      'Third-Party Processing: Payments are handled by specialized payment gateways.';

  @override
  String get privacyPolicySection4Bullet2 =>
      'Zero Storage: DualisCheckUp servers do NOT receive, process or store credit card numbers or CVV codes.';

  @override
  String get privacyPolicySection5Title =>
      '5. Your Rights as Data Subject (LGPD Art. 18)';

  @override
  String get privacyPolicySection5Body =>
      'You can exercise your legal rights instantly, right in the app:';

  @override
  String get privacyPolicySection5Bullet1 =>
      'Data Export: Download all your entries in a structured format (JSON) with one tap in the Privacy Center.';

  @override
  String get privacyPolicySection5Bullet2 =>
      'Permanent Deletion: Request the irreversible deletion of your account and all associated data.';

  @override
  String get privacyPolicySection5Bullet3 =>
      'Consent Withdrawal: Stop using the app and withdraw your authorization at any time.';

  @override
  String get privacyPolicySection6Title =>
      '6. Information Security & Incident Response';

  @override
  String get privacyPolicySection6Body =>
      'End-to-end technical measures protect your entries:';

  @override
  String get privacyPolicySection6Bullet1 =>
      'RLS Isolation: Every PostgreSQL query is protected by a Row-Level Security policy scoped to your user key.';

  @override
  String get privacyPolicySection6Bullet2 =>
      'Strong Encryption: Mandatory TLS 1.3 connections and passwords protected with Argon2id.';

  @override
  String get privacyPolicySection6Bullet3 =>
      '72-hour Notification Plan: Prompt notice to Brazil\'s National Data Protection Authority (ANPD) and to users of any relevant security incident (LGPD Art. 48).';

  @override
  String get privacyPolicySection7Title =>
      '7. Notifications, Communications and Opt-Out';

  @override
  String get privacyPolicySection7Body =>
      'We respect your peace of mind and attention:';

  @override
  String get privacyPolicySection7Bullet1 =>
      'You are free to turn off hydration reminders or wellness tip notifications in Settings at any time.';

  @override
  String get privacyPolicySection7Bullet2 =>
      'Security and account recovery notices are strictly transactional and protected.';

  @override
  String get privacyPolicyCtaQuestion =>
      'Want to export your data or manage your account now?';

  @override
  String get privacyPolicyCtaButton => 'Go to the Privacy Center';

  @override
  String get onboardingIntendedUseNote =>
      'DualisCheckUp is a wellness and self-awareness app. It is not a medical device and does not replace a healthcare professional.';

  @override
  String get privacyVeilBiometricReason =>
      'Authenticate to access your entries.';

  @override
  String get privacyVeilUnlock => 'Unlock';

  @override
  String get privacyVeilUnlockManually => 'Unlock manually';

  @override
  String get wizardNarrativeLabel => 'Optional description (in your own words)';

  @override
  String get wizardNarrativeHint =>
      'If you like, describe in your own words how you are.';

  @override
  String get wizardStepZeroFreeTextLabel =>
      'Prefer to describe it in your own words?';

  @override
  String get wizardStepZeroFreeTextHint =>
      'If you like, describe in your own words what you\'re feeling.';

  @override
  String deleteHistoryItemIntensity(int value) {
    return 'Reported intensity: $value/5';
  }

  @override
  String get bodyMapRegionHeadNeck => 'Head and neck';

  @override
  String get bodyMapRegionHeadNeckHint => 'Headache, neck pain or stiffness';

  @override
  String get bodyMapRegionDizziness => 'Dizziness / tingling';

  @override
  String get bodyMapRegionDizzinessHint =>
      'Dizziness, feeling off balance, tingling';

  @override
  String get bodyMapRegionBack => 'Back';

  @override
  String get bodyMapRegionBackHint => 'Pain in the back, spine or lower back';

  @override
  String get bodyMapRegionBreathing => 'Breathing';

  @override
  String get bodyMapRegionBreathingHint => 'Shortness of breath, cough';

  @override
  String get bodyMapRegionChest => 'Chest';

  @override
  String get bodyMapRegionChestHint =>
      'Tightness or discomfort in the chest, racing heart';

  @override
  String get bodyMapRegionBelly => 'Belly';

  @override
  String get bodyMapRegionBellyHint => 'Belly discomfort, cramps, heartburn';

  @override
  String get bodyMapRegionPelvic => 'Intimate / urinary area';

  @override
  String get bodyMapRegionPelvicHint =>
      'Discomfort in the pelvic area or when urinating';

  @override
  String get bodyMapRegionRightArm => 'Right arm';

  @override
  String get bodyMapRegionRightArmHint => 'Right arm, shoulder, elbow or wrist';

  @override
  String get bodyMapRegionLeftArm => 'Left arm';

  @override
  String get bodyMapRegionLeftArmHint => 'Left arm, shoulder, elbow or wrist';

  @override
  String get bodyMapRegionRightLeg => 'Right leg';

  @override
  String get bodyMapRegionRightLegHint => 'Right hip, thigh, knee or ankle';

  @override
  String get bodyMapRegionLeftLeg => 'Left leg';

  @override
  String get bodyMapRegionLeftLegHint => 'Left hip, thigh, knee or ankle';

  @override
  String get bodyMapRegionSkin => 'Skin';

  @override
  String get bodyMapRegionSkinHint => 'Itching, spots';

  @override
  String get bodyMapRegionWholeBody => 'Whole body / tiredness';

  @override
  String get bodyMapRegionWholeBodyHint => 'Aches all over the body, tiredness';

  @override
  String get bodyMapRegionEnergy => 'Thirst, hunger or energy';

  @override
  String get bodyMapRegionEnergyHint => 'Changes in energy, thirst or hunger';

  @override
  String get bodyMapGroupHead => 'Head';

  @override
  String get bodyMapGroupTrunk => 'Trunk';

  @override
  String get bodyMapGroupLimbs => 'Arms and legs';

  @override
  String get bodyMapGroupWholeBody => 'Whole body and skin';

  @override
  String get bodyMapViewMap => 'Body map';

  @override
  String get bodyMapViewAll => 'All areas';

  @override
  String get bodyMapShortSkin => 'Skin';

  @override
  String get bodyMapShortWholeBody => 'Whole body';

  @override
  String get bodyMapShortEnergy => 'Energy';

  @override
  String bodyMapMaxIntensity(int value) {
    return 'Highest intensity you reported in the last 14 days: $value/5';
  }

  @override
  String bodyMapNoEntriesThisSide(String otherArea, int value) {
    return 'No entries on this side in the last 14 days.\n($otherArea: reported intensity $value/5)';
  }

  @override
  String bodyMapViewOtherSide(String area) {
    return 'View $area';
  }

  @override
  String get bodyMapNoEntries14Days => 'No entries in the last 14 days';

  @override
  String get settingsChangePhotoSubtitle =>
      'Choose how you want to select your profile photo.';

  @override
  String get settingsPhotoCamera => 'Camera';

  @override
  String get settingsPhotoCameraSubtitle => 'Take a new photo';

  @override
  String get settingsPhotoGallery => 'Gallery';

  @override
  String get settingsPhotoGallerySubtitle => 'Choose from your photo library';

  @override
  String get settingsPhotoPresets => 'Avatars';

  @override
  String get settingsPhotoPresetsSubtitle =>
      'Choose an illustrated self-care icon';

  @override
  String get settingsLogoutConfirmBody =>
      'Do you really want to sign out? Your data stays safe and encrypted.';

  @override
  String get settingsLogoutConfirmAction => 'Sign out';

  @override
  String get settingsNameHint => 'Your full name';

  @override
  String get settingsRemindersTile => 'Reminders and Hydration';

  @override
  String get settingsRemindersSubtitle =>
      'Notification times, alarms and closed-app test';

  @override
  String get settingsTermsTile => 'Terms of Use';

  @override
  String get settingsTermsSubtitle =>
      'Terms of use, plans, cancellation and refunds';

  @override
  String get settingsPrivacyPolicyTile => 'Privacy Policy (LGPD)';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'Data processing, your rights and DPO';

  @override
  String get settingsCommunicationsSection =>
      'Communications and Notifications';

  @override
  String get settingsEducationalTipsTile =>
      'Wellness Tips and Educational Notifications';

  @override
  String get settingsEducationalTipsSubtitle =>
      'General wellness tips. You can opt out at any time.';

  @override
  String get settingsEducationalTipsOn =>
      'Educational notifications turned on.';

  @override
  String get settingsEducationalTipsOff =>
      'Opt-out confirmed: educational notifications turned off.';

  @override
  String get settingsOperatorInfo =>
      'Operated by DualisCheckUp Saúde e Tecnologia Ltda.\nCNPJ 48.291.834/0001-92 • São Paulo - SP, Brazil\nDPO: dpo@dualischeckup.com';

  @override
  String get avatarSelectorSubtitle =>
      'Pick a self-care icon to personalize your profile.';

  @override
  String get avatarConfirm => 'Confirm Avatar';

  @override
  String get avatarPresetSelfCare => 'Self-care';

  @override
  String get avatarPresetBalance => 'Balance';

  @override
  String get avatarPresetProtection => 'Protection';

  @override
  String get avatarPresetVitality => 'Vitality';

  @override
  String get avatarPresetWellbeing => 'Well-being';

  @override
  String get avatarPresetEnergy => 'Energy';

  @override
  String get avatarPresetFocus => 'Mental Focus';

  @override
  String get avatarPresetRadiant => 'Radiant';

  @override
  String get loginTitle => 'Sign in to DualisCheckUp';

  @override
  String get loginSubtitle => 'Access your wellness journal securely.';

  @override
  String get authEmailHint => 'your.email@example.com';

  @override
  String get loginPasswordRequired => 'Password is required.';

  @override
  String get loginNoAccountPrompt => 'Don\'t have an account yet? ';

  @override
  String get forgotPasswordLink => 'Forgot your password?';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your account email. We\'ll send you a code to reset your password.';

  @override
  String get forgotPasswordSendCta => 'Send code';

  @override
  String get forgotPasswordSuccessMessage =>
      'If the email is registered, a reset code has been sent.';

  @override
  String get forgotPasswordBackToLogin => 'Back to login';

  @override
  String get resetPasswordTitle => 'Create new password';

  @override
  String get resetPasswordSubtitle =>
      'Enter the code you received by email and choose a new password.';

  @override
  String get resetPasswordCodeLabel => 'Verification code';

  @override
  String get resetPasswordCodeHint => 'Enter the 6-digit code';

  @override
  String get resetPasswordCodeRequired => 'Verification code is required.';

  @override
  String get resetPasswordSubmitCta => 'Reset password';

  @override
  String get resetPasswordSuccessMessage =>
      'Password reset successfully. You can now log in with your new password.';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Share a few details to personalize your experience.';

  @override
  String get registerNameHint => 'e.g. Carlos Silva';

  @override
  String get registerDobHint => 'DD/MM/YYYY';

  @override
  String get registerDobHelper =>
      'e.g. 15/08/1990 or pick a date from the calendar.';

  @override
  String get registerDobPickerHelp => 'Select your date of birth';

  @override
  String get registerDobPickerConfirm => 'Confirm';

  @override
  String get registerPasswordHint => 'At least 8 characters';

  @override
  String get registerPasswordHelper =>
      'Use 8+ characters with an uppercase letter, a number and a symbol.';

  @override
  String get registerHydrationTitle => 'Hydration Reminders and Tracking';

  @override
  String get registerHydrationSubtitle => 'Set up your hydration habits';

  @override
  String get registerWaterReminderTitle => 'Reminder to drink water every 2h';

  @override
  String get registerWaterReminderSubtitle =>
      'Even hours: 8am, 10am, 12pm, 2pm, 4pm, 6pm and 8pm';

  @override
  String get registerReminderStyleLabel => 'Reminder type / sound:';

  @override
  String get registerReminderStyleChime => 'Notice (Message)';

  @override
  String get registerReminderStyleAlarm => 'Phone Alarm';

  @override
  String get registerWaterTrackingTitle => 'Track amount consumed';

  @override
  String get registerWaterTrackingOnDesc =>
      'When the alarm rings, the app opens so you can log how much water you drank';

  @override
  String get registerWaterTrackingOffDesc =>
      'Only plays the reminder on time, without opening the log';

  @override
  String get registerHaveAccountPrompt => 'Already have an account? ';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeGreetingNoName => 'Hello!';

  @override
  String get homeSessionActive => 'Active session';

  @override
  String get homeDataProtectedBadge => 'Your entries are protected';

  @override
  String get homeTodayEntryDone => 'Today\'s entry completed';

  @override
  String get notFoundErrorCode => 'ERROR 404';

  @override
  String get notFoundTitle => 'Page Not Found';

  @override
  String get notFoundBody => 'The page you tried to open does not exist.';

  @override
  String get notFoundBackToDashboard => 'Back to Dashboard';

  @override
  String get notFoundGoHome => 'Go to Home';

  @override
  String get notFoundGoBack => 'Back to previous screen';

  @override
  String get wellnessConfirmTitle => 'All Good Here!';

  @override
  String get wellnessConfirmBody =>
      'Great news! You said you\'re feeling well both physically and emotionally today.\n\nYour daily check-in is complete and your data is protected. Keep up your healthy self-care habits!';

  @override
  String get wellnessConfirmButton => 'Finish Check-in';

  @override
  String get adBannerHeader =>
      'Local partner • This ad doesn\'t use your health data';

  @override
  String get adBannerSampleBody =>
      'First-aid and personal care items up to 20% off.';

  @override
  String get outcomeStaticGuidance =>
      'This app does not assess your health. If any discomfort persists, worsens, or worries you, talk to a healthcare professional. In an emergency, call your local emergency number.';

  @override
  String get outcomeDualAxisNote =>
      'You logged both body sensations and emotions today. If any physical discomfort persists or worsens, talk to a healthcare professional.';

  @override
  String get outcomeAiInsightTitle => 'How we organized your note';

  @override
  String outcomeAiInsightLayTerm(String term) {
    return 'Term you used: $term';
  }

  @override
  String outcomeAiInsightArea(String area) {
    return 'Body area or mood: $area';
  }

  @override
  String get outcomeWellnessReadingsTitle => 'Wellness readings';

  @override
  String get outcomeWellnessReadingsDisclaimer =>
      'General educational content. Not guidance for your situation.';

  @override
  String get outcomeWellnessReadingsRelatedTitle =>
      'Readings related to what you logged';

  @override
  String outcomeWellnessReadingsCount(int count) {
    return '$count readings';
  }

  @override
  String get outcomeArticlesEmpty => 'No readings available right now.';

  @override
  String get journalPatternTitle => 'Patterns in your entries';

  @override
  String journalPatternDescription(String category, int count, int windowDays) {
    return 'You logged $category with high intensity $count times in the last $windowDays days. If this is affecting your daily life, talking to a healthcare professional may help.';
  }

  @override
  String historyIntensityInformed(int n) {
    return 'Reported intensity: $n/5';
  }

  @override
  String get todayOutcomeCompletedBadge => 'Entry completed';

  @override
  String get todayOutcomeUpdateButton => 'Update today\'s entry';

  @override
  String get todayOutcomeDetailedCheckinButton => 'Add a detailed entry';

  @override
  String get appUpdateTitle => 'Update the app';

  @override
  String appUpdateMessage(String minVersion) {
    return 'This version is no longer supported. Install version $minVersion or newer from the app store.';
  }

  @override
  String get appUpdateButton => 'Open app store';

  @override
  String outcomeSummaryIntensity(int value) {
    return 'Reported intensity: $value/5';
  }

  @override
  String outcomeSummaryRecordedAt(String time) {
    return 'Logged at $time';
  }

  @override
  String outcomeTodayYouLogged(String option) {
    return 'You logged: $option';
  }

  @override
  String get outcomeTodayStatusGood => 'Good';

  @override
  String get outcomeTodayStatusSoSo => 'So-so';

  @override
  String get outcomeTodayStatusBad => 'Not well';

  @override
  String get outcomeHistoryDetailTitle => 'Entry details';

  @override
  String get outcomeHistoryNoNarrative =>
      'You did not add a description to this entry.';
}
