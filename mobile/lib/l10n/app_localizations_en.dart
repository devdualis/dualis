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
  String get triageOptTrabalho => 'Work / Studies';

  @override
  String get triageOptFamilia => 'Family / Relationships';

  @override
  String get triageOptNoiteRuim => 'Poor night of sleep';

  @override
  String get triageOptNaoSei => 'Cannot tell';

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
  String get triageOptSimExercicio => 'Yes, intense exercise';

  @override
  String get triageOptSimQueda => 'Yes, suffered a fall';

  @override
  String get triageOptNaoComecouNada => 'No, started out of nowhere';

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
}
