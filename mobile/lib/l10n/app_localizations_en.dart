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
}
