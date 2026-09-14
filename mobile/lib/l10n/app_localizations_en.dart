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
}
