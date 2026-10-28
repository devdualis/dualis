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
  String get forgotPasswordTitle => 'Forgot your password?';

  @override
  String get forgotPasswordSubtitle =>
      'Enter the email linked to your account and we\'ll send you a code to reset your password.';

  @override
  String get forgotPasswordSendCta => 'Send Code';

  @override
  String get forgotPasswordSuccessMessage =>
      'If that email is registered, we\'ve sent a reset code to it.';

  @override
  String get forgotPasswordBackToLogin => 'Back to Login';

  @override
  String get resetPasswordTitle => 'Reset your password';

  @override
  String get resetPasswordSubtitle =>
      'Enter the code we sent you and choose a new password.';

  @override
  String get resetPasswordCodeLabel => 'Verification Code';

  @override
  String get resetPasswordCodeHint => '6-digit code';

  @override
  String get resetPasswordCodeRequired => 'Enter the 6-digit code';

  @override
  String get resetPasswordSubmitCta => 'Reset Password';

  @override
  String get resetPasswordSuccessMessage =>
      'Your password has been reset. You can now log in.';

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
  String get loginEmailNotVerified =>
      'Your email is not verified yet. Enter the code we sent or request a new one.';

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
      'Suggesting, with AI help, an existing diary option when you write in your own words (no health assessment).';

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
      'Google LLC (Gemini API): text from \"write my own\" may be sent to Gemini only to suggest an existing diary option. The AI does not assess your health.';

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
  String outcomeWellnessReadingsCount(int count) {
    return '$count readings';
  }

  @override
  String get journalPatternTitle => 'Patterns in your entries';

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
  String get checkInSummaryTitle => 'Entry saved';

  @override
  String get checkInSummaryBackHome => 'Back to home';

  @override
  String checkInSummaryBackHomeCountdown(int seconds) {
    return 'Back to home ($seconds)';
  }

  @override
  String get jv2FlowTitle => 'Today\'s entry';

  @override
  String get jv2Back => 'Back';

  @override
  String get jv2Continue => 'Continue';

  @override
  String get jv2Skip => 'Skip';

  @override
  String get jv2Save => 'Save entry';

  @override
  String get jv2Yes => 'Yes';

  @override
  String get jv2No => 'No, continue';

  @override
  String get jv2Cancel => 'Cancel';

  @override
  String get jv2Remove => 'Remove';

  @override
  String jv2HelloName(String name) {
    return 'Hi, $name!';
  }

  @override
  String get jv2Hello => 'Hi!';

  @override
  String get jv2GoodMorning => 'Good morning.';

  @override
  String get jv2GoodAfternoon => 'Good afternoon.';

  @override
  String get jv2GoodEvening => 'Good evening.';

  @override
  String get jv2MoodQuestion => 'How are you feeling today?';

  @override
  String get jv2MoodBem => 'Good';

  @override
  String get jv2MoodNormal => 'Okay';

  @override
  String get jv2MoodNaoTaoBem => 'Not so good';

  @override
  String get jv2AreaQuestion => 'What would you like to record?';

  @override
  String get jv2AreaHint => 'You can pick more than one.';

  @override
  String get jv2AreaEmotional => 'How I feel';

  @override
  String get jv2AreaEmotionalHint => 'Emotions and mood';

  @override
  String get jv2AreaPhysical => 'My body';

  @override
  String get jv2AreaPhysicalHint => 'Where I feel discomfort';

  @override
  String get jv2AreaConditions => 'My conditions';

  @override
  String jv2ConditionCardQuestion(String label) {
    return 'How are you doing with $label today?';
  }

  @override
  String get jv2TimeQuestion => 'What you feel has more to do with…';

  @override
  String get jv2TimePassado => 'What already happened';

  @override
  String get jv2TimePresente => 'Right now';

  @override
  String get jv2TimeFuturo => 'What lies ahead';

  @override
  String get jv2TimeShortPassado => 'Past';

  @override
  String get jv2TimeShortPresente => 'Present';

  @override
  String get jv2TimeShortFuturo => 'Future';

  @override
  String get jv2BranchQuestion => 'What fits you best right now?';

  @override
  String get jv2OptionsQuestion => 'Pick what fits you.';

  @override
  String get jv2MultiSelectHint => 'You can pick more than one.';

  @override
  String get jv2WriteMine => 'Write my own';

  @override
  String get jv2WriteMineHint => 'In a few words';

  @override
  String get jv2WriteMineAdd => 'Add';

  @override
  String get jv2SuggestTitle => 'This looks like an option that already exists';

  @override
  String jv2SuggestBody(String option) {
    return 'Save as \"$option\" instead of the text you wrote?';
  }

  @override
  String get jv2SuggestYes => 'Use that option';

  @override
  String get jv2SuggestNo => 'Keep what I wrote';

  @override
  String get jv2MoreQuestion => 'Would you like to record anything else?';

  @override
  String get jv2MoreBodyQuestion =>
      'Would you like to mark another part of the body?';

  @override
  String get jv2BodyQuestion => 'Where do you feel discomfort right now?';

  @override
  String get jv2BodyHint => 'Tap one or more parts.';

  @override
  String get jv2BodyFront => 'Front';

  @override
  String get jv2BodyBack => 'Back';

  @override
  String jv2ItemLimit(int max) {
    return 'You reached the limit of $max items in this entry.';
  }

  @override
  String get jv2BranchPassadoTristeza => 'Sadness or missing something';

  @override
  String get jv2BranchPassadoMemoria => 'A memory that bothers me';

  @override
  String get jv2BranchPresenteEnergia => 'No energy';

  @override
  String get jv2BranchPresenteSobrecarga => 'Irritated or overloaded';

  @override
  String get jv2BranchFuturoMente => 'Racing mind';

  @override
  String get jv2BranchFuturoMedo => 'Afraid something will go wrong';

  @override
  String get jv2OptPassadoTristezaCulpa => 'Guilt or regret';

  @override
  String get jv2OptPassadoTristezaSaudade =>
      'Missing someone or how things used to be';

  @override
  String get jv2OptPassadoMemoriaLembranca =>
      'A bad memory that keeps coming back';

  @override
  String get jv2OptPassadoMemoriaMagoa => 'I keep going over old hurts';

  @override
  String get jv2OptPresenteEnergiaCorpo => 'Body feels heavy, tense or sore';

  @override
  String get jv2OptPresenteEnergiaDesligado =>
      'On autopilot, a bit switched off';

  @override
  String get jv2OptPresenteSobrecargaPaciencia =>
      'Short on patience, snapping over little things';

  @override
  String get jv2OptPresenteSobrecargaAperto =>
      'Tight chest and moments of despair';

  @override
  String get jv2OptFuturoMenteAntecipar => 'I keep anticipating problems';

  @override
  String get jv2OptFuturoMenteCobranca => 'Pressure for perfection or control';

  @override
  String get jv2OptFuturoMedoJulgamento => 'Fear of failing or being judged';

  @override
  String get jv2OptFuturoMedoDesanimo =>
      'Discouraged about where things are going';

  @override
  String get jv2RegionCabeca => 'Head and neck';

  @override
  String get jv2RegionPeito => 'Chest';

  @override
  String get jv2RegionBarriga => 'Belly';

  @override
  String get jv2RegionCostas => 'Back';

  @override
  String get jv2RegionMembros => 'Arms, legs and hands';

  @override
  String get jv2BranchCabecaPressao => 'Tightness, heaviness or pressure';

  @override
  String get jv2BranchCabecaSentidos => 'Eyes, mouth or throat';

  @override
  String get jv2BranchPeitoRespiracao => 'Breathing feels different';

  @override
  String get jv2BranchPeitoIncomodo => 'Discomfort in the chest or ribs';

  @override
  String get jv2BranchBarrigaQueimacao => 'Burning or nausea';

  @override
  String get jv2BranchBarrigaColica => 'Cramps or bloating';

  @override
  String get jv2BranchCostasRigidez => 'Stiffness or locking up';

  @override
  String get jv2BranchCostasFisgada => 'Sharp pain when moving';

  @override
  String get jv2BranchMembrosCansaco => 'Tiredness or pain';

  @override
  String get jv2BranchMembrosFormigamento => 'Tingling';

  @override
  String get jv2OptCabecaPressaoTemporas =>
      'Pain or pressure in the temples or forehead';

  @override
  String get jv2OptCabecaPressaoLatejando =>
      'Throbbing, bothered by light or noise';

  @override
  String get jv2OptCabecaSentidosGarganta => 'Scratchy or dry throat';

  @override
  String get jv2OptCabecaSentidosOlhos => 'Heavy or burning eyes';

  @override
  String get jv2OptPeitoRespiracaoCurta => 'Short breath';

  @override
  String get jv2OptPeitoRespiracaoTosse => 'Cough or heavy chest';

  @override
  String get jv2OptPeitoIncomodoBatedeira => 'Racing or pounding heart';

  @override
  String get jv2OptPeitoIncomodoCostelas =>
      'Stitch in the ribs when breathing deeply';

  @override
  String get jv2OptBarrigaQueimacaoSubindo => 'Burning that rises';

  @override
  String get jv2OptBarrigaQueimacaoEnjoo => 'Nausea';

  @override
  String get jv2OptBarrigaColicaGases => 'Gas or bloated belly';

  @override
  String get jv2OptBarrigaColicaPontadas => 'Cramps or stabbing pains';

  @override
  String get jv2OptCostasRigidezOmbros => 'Stiff neck and shoulders';

  @override
  String get jv2OptCostasRigidezLombar => 'Heaviness in the lower back';

  @override
  String get jv2OptCostasFisgadaIrradia =>
      'Stabbing pain running down an arm or leg';

  @override
  String get jv2OptCostasFisgadaAoMexer => 'Pain when moving';

  @override
  String get jv2OptMembrosCansacoJuntas => 'Sore joints';

  @override
  String get jv2OptMembrosCansacoPesados => 'Tired arms or legs';

  @override
  String get jv2OptMembrosFormigamentoDormentes =>
      'Tingling or numb hands or feet';

  @override
  String get jv2OptMembrosFormigamentoChoque => 'Electric-shock feeling';

  @override
  String get jv2PersistenceQuestion => 'How long have you noticed this?';

  @override
  String get jv2PersistenceHoje => 'Started today';

  @override
  String get jv2PersistenceDiasSemanas => 'A few days or weeks';

  @override
  String get jv2PersistenceMesesAnos => 'Months or years';

  @override
  String get jv2PersistenceOptional => 'How long? (optional)';

  @override
  String get jv2IntensityQuestion =>
      'Now, how much does this weigh on your day?';

  @override
  String get jv2IntensityCompactQuestion =>
      'For each item, how much does it weigh on your day?';

  @override
  String jv2IntensityLevel(int level) {
    return '$level of 5';
  }

  @override
  String get jv2IntensityEmotional1 =>
      'It passes quickly, I go on with my day as usual.';

  @override
  String get jv2IntensityEmotional2 => 'I notice it, but I can stay focused.';

  @override
  String get jv2IntensityEmotional3 => 'It is taking my energy or focus.';

  @override
  String get jv2IntensityEmotional4 =>
      'It is changing my routine (sleep, tasks, time with others).';

  @override
  String get jv2IntensityEmotional5 =>
      'It is holding me back almost completely today.';

  @override
  String get jv2IntensityPhysical1 =>
      'I feel it, but it does not get in the way.';

  @override
  String get jv2IntensityPhysical2 =>
      'It bothers me, but I keep up my activities.';

  @override
  String get jv2IntensityPhysical3 => 'It slowed me down or made me pause.';

  @override
  String get jv2IntensityPhysical4 => 'I cannot properly do what I need to.';

  @override
  String get jv2IntensityPhysical5 =>
      'It is holding me back almost completely today.';

  @override
  String get jv2EmergencyLine =>
      'If this is an emergency, use the Help button or call your local emergency number.';

  @override
  String get jv2TriggersQuestion =>
      'Is there anything that may have contributed today?';

  @override
  String get jv2TriggerTrabalho => 'Work or studies';

  @override
  String get jv2TriggerFamilia => 'Family or relationships';

  @override
  String get jv2TriggerSono => 'Poor night of sleep';

  @override
  String get jv2TriggerAlimentacao => 'Food';

  @override
  String get jv2TriggerEsforco => 'Physical effort';

  @override
  String get jv2TriggerQueda => 'A fall or awkward movement';

  @override
  String get jv2TriggerMedicamento => 'New medicine';

  @override
  String get jv2TriggerClima => 'Weather or surroundings';

  @override
  String get jv2TriggerNaoSei => 'I am not sure';

  @override
  String get jv2TriggerOutro => 'Other';

  @override
  String get jv2TriggerNoteHint => 'Tell us in a few words';

  @override
  String get jv2NoteQuestion => 'Would you like to say more?';

  @override
  String get jv2NoteHint => 'Write in your own words (optional)';

  @override
  String get jv2SaveError => 'Could not save right now. Please try again.';

  @override
  String get jv2SavedOffline =>
      'Entry saved on this device. It will be sent when you are online.';

  @override
  String get jv2ConditionsTitle => 'My conditions';

  @override
  String get jv2ConditionsSubtitle =>
      'Added by you. Write them in your own words; each one shows up in your daily entry with the same 1 to 5 scale.';

  @override
  String get jv2ConditionsAdd => 'Add';

  @override
  String get jv2ConditionsFieldHint => 'E.g. Migraine';

  @override
  String get jv2ConditionsEmpty => 'You have not added any yet.';

  @override
  String get jv2ConditionsArchive => 'Archive';

  @override
  String jv2ConditionsArchiveConfirm(String label) {
    return 'Archive \"$label\"? Your past entries keep this name.';
  }

  @override
  String jv2ConditionsLimit(int max) {
    return 'You can track up to $max.';
  }

  @override
  String get jv2ConditionsOffline =>
      'No connection. Try again when you are online.';

  @override
  String get jv2ConditionsError => 'Could not save. Please try again.';

  @override
  String get jv2ConditionsSettingsSubtitle =>
      'Follow, in your own words, something you already know about';

  @override
  String get jv2PhraseTime1 => 'Got it. Let us note this down calmly.';

  @override
  String get jv2PhraseTime2 => 'Thanks for sharing. Let us write it down.';

  @override
  String get jv2PhraseTime3 => 'That is okay. One step at a time.';

  @override
  String get jv2PhraseTime4 => 'Okay. Let us record it your way.';

  @override
  String get jv2PhrasePassado1 =>
      'The mind sometimes goes back in time. Let us note it down.';

  @override
  String get jv2PhrasePassado2 => 'Thanks for sharing. What is it about?';

  @override
  String get jv2PhrasePassado3 => 'Let us record this calmly.';

  @override
  String get jv2PhrasePresente1 => 'Let us note what feels heavy today.';

  @override
  String get jv2PhrasePresente2 => 'Got it. What fits best right now?';

  @override
  String get jv2PhrasePresente3 => 'Thanks for sharing. Let us record it.';

  @override
  String get jv2PhraseFuturo1 =>
      'Thinking about what lies ahead is part of life. Let us note it.';

  @override
  String get jv2PhraseFuturo2 => 'Got it. What fits you best?';

  @override
  String get jv2PhraseFuturo3 => 'Thanks for sharing. Let us record it calmly.';

  @override
  String get jv2PhraseBody1 => 'Let us note what you feel in your body.';

  @override
  String get jv2PhraseBody2 => 'Tap where you feel discomfort.';

  @override
  String get jv2PhraseBody3 => 'Thanks for sharing. Where do you feel it?';

  @override
  String get jv2PhraseRegion1 => 'Let us note what you feel here.';

  @override
  String get jv2PhraseRegion2 => 'Got it. What is the feeling like?';

  @override
  String get jv2PhraseRegion3 => 'Thanks for sharing. What fits best?';

  @override
  String get jv2PhraseRegion4 => 'Recording helps you follow your day to day.';

  @override
  String get jv2PhraseIntensity1 => 'You pick the number. The scale is yours.';

  @override
  String get jv2PhraseIntensity2 =>
      'There is no right answer. What you feel is what counts.';

  @override
  String get jv2PhraseIntensity3 => 'Almost there. Just a little more.';

  @override
  String get jv2PhraseTriggers1 =>
      'If you like, mark what may have contributed.';

  @override
  String get jv2PhraseTriggers2 => 'It is optional. You can skip it.';

  @override
  String get jv2PhraseTriggers3 => 'Almost done. Did anything stand out today?';

  @override
  String get xv2CropTitle => 'Adjust photo';

  @override
  String get xv2CropHint => 'Pinch to zoom and drag to frame your photo.';

  @override
  String get xv2CropReset => 'Reset';

  @override
  String get xv2CropConfirm => 'Use photo';

  @override
  String xv2GreetingMorning(String name) {
    return 'Hi, $name! Good morning';
  }

  @override
  String xv2GreetingAfternoon(String name) {
    return 'Hi, $name! Good afternoon';
  }

  @override
  String xv2GreetingEvening(String name) {
    return 'Hi, $name! Good evening';
  }

  @override
  String get xv2GreetingMorningNoName => 'Hi! Good morning';

  @override
  String get xv2GreetingAfternoonNoName => 'Hi! Good afternoon';

  @override
  String get xv2GreetingEveningNoName => 'Hi! Good evening';

  @override
  String get xv2HydrationOfferTitle =>
      'Would you like reminders to drink water?';

  @override
  String get xv2HydrationOfferBody =>
      'You choose the times and your goal in the hydration settings. You can change them anytime.';

  @override
  String get xv2HydrationOfferYes => 'Yes, set up';

  @override
  String get xv2HydrationOfferNo => 'Not now';

  @override
  String get xv2LibTitle => 'Library';

  @override
  String get xv2LibIntro =>
      'General texts from public sources about healthy habits. They are the same for everyone and are not guidance for your situation.';

  @override
  String xv2LibSource(String source) {
    return 'Source: $source';
  }

  @override
  String xv2LibReadTime(int minutes) {
    return '$minutes min read';
  }

  @override
  String get xv2LibOpen => 'Open text';

  @override
  String get xv2LibOpenError => 'The link could not be opened right now.';

  @override
  String get xv2LibCatEmocoes => 'Emotions and mood';

  @override
  String get xv2LibCatEstresse => 'Stress and rest';

  @override
  String get xv2LibCatSono => 'Sleep';

  @override
  String get xv2LibCatCorpo => 'Body and movement';

  @override
  String get xv2LibCatAlimentacao => 'Food and digestion';

  @override
  String get xv2LibCatHidratacao => 'Hydration';

  @override
  String get xv2LibCatRelacoes => 'Relationships and social life';

  @override
  String get xv2LibCatAjuda => 'First care and when to seek help';

  @override
  String get xv2LibArtDesanimoTitle => 'Days of low mood and little energy';

  @override
  String get xv2LibArtDesanimoSummary =>
      'Small routines for low days and where to find support.';

  @override
  String get xv2LibArtAgitacaoTitle => 'Restless moments: how to slow down';

  @override
  String get xv2LibArtAgitacaoSummary =>
      'General information about nervousness and racing thoughts in daily life.';

  @override
  String get xv2LibArtTrabalhoTitle => 'Tiredness at work and healthy limits';

  @override
  String get xv2LibArtTrabalhoSummary =>
      'General information about emotional tiredness at work and breaks in your routine.';

  @override
  String get xv2LibArtRespiracaoTitle => 'Paced breathing to relax';

  @override
  String get xv2LibArtRespiracaoSummary =>
      'A few minutes of calm breathing can help you slow down on demanding days.';

  @override
  String get xv2LibArtSonoTitle => 'Habits for better sleep';

  @override
  String get xv2LibArtSonoSummary =>
      'Regular times and simple habits that support calmer nights.';

  @override
  String get xv2LibArtBracosTitle => 'Arms and shoulders: breaks and posture';

  @override
  String get xv2LibArtBracosSummary =>
      'General information about repetitive effort and breaks during the day.';

  @override
  String get xv2LibArtMovimentoTitle => 'Move more every day';

  @override
  String get xv2LibArtMovimentoSummary =>
      'General guidance on physical activity at every age.';

  @override
  String get xv2LibArtAlimentacaoTitle =>
      'Dietary Guidelines for the Brazilian Population';

  @override
  String get xv2LibArtAlimentacaoSummary =>
      'General principles for balanced eating based on real food.';

  @override
  String get xv2LibArtAguaTitle => 'Water throughout the day';

  @override
  String get xv2LibArtAguaSummary =>
      'Drinking water throughout the day is part of healthy living habits.';

  @override
  String get xv2LibArtConvivioTitle => 'Emotional wellbeing and social life';

  @override
  String get xv2LibArtConvivioSummary =>
      'General information about emotional wellbeing, relationships and community support.';

  @override
  String get xv2LibArtSamuTitle => 'SAMU 192: how it works';

  @override
  String get xv2LibArtSamuSummary =>
      'The free mobile service of Brazil\'s public health system, reached by dialling 192 nationwide.';

  @override
  String get xv2LibArtCvvTitle => 'CVV 188: emotional support';

  @override
  String get xv2LibArtCvvSummary =>
      'Free, confidential conversation, 24 hours a day, by phone, chat or e-mail.';

  @override
  String xv2ReportedIntensity(int intensity) {
    return 'Intensity you reported: $intensity/5';
  }

  @override
  String get xv2SummaryTitle => 'Your entry for today';

  @override
  String get xv2SummarySaved => 'Your entry was saved.';

  @override
  String get xv2SummaryThanks =>
      'Thank you for logging your day! 🌿 In the Library you will find texts from public sources, such as the Brazilian Ministry of Health, about healthy habits.';

  @override
  String get xv2SummaryOpenLibrary => 'Open the Library';

  @override
  String get xv2AdLabel => 'Ad';

  @override
  String get xv2AdLearnMore => 'Learn more';

  @override
  String get xv2AdPremiumTitle => 'Dualis Premium';

  @override
  String get xv2AdPremiumBody =>
      'See up to 12 months of your entries and choose your backgrounds. Coming soon.';

  @override
  String get xv2AdZocTitle => 'ZOC · Notebooks and planners';

  @override
  String get xv2AdZocBody => 'Plan your week calmly, on paper. Sample ad.';

  @override
  String get xv2AdWgiTitle => 'WGI · Reusable bottles';

  @override
  String get xv2AdWgiBody => 'Take your water wherever you go. Sample ad.';

  @override
  String get xv2AdUboTitle => 'UBO · Playlists to unwind';

  @override
  String get xv2AdUboBody => 'Nature sounds for breaks in your day. Sample ad.';

  @override
  String get xv2DashTitle => 'History';

  @override
  String xv2DashWindow(int days) {
    return 'Your entries from the last $days days';
  }

  @override
  String get xv2DashRetry => 'Try again';

  @override
  String get xv2DashTimeTitle => 'Past, present and future';

  @override
  String xv2DashTimeCount(String time, int count) {
    return '$time: $count';
  }

  @override
  String get xv2DashNoEmotional => 'No emotional entries in this period.';

  @override
  String get xv2DashBodyTitle => 'Body parts you marked';

  @override
  String get xv2DashFront => 'Front';

  @override
  String get xv2DashBack => 'Back';

  @override
  String xv2DashRegionDays(String region, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'no days',
    );
    return '$region: $_temp0';
  }

  @override
  String get xv2DashLinesTitle => 'Intensity per day';

  @override
  String get xv2DashLinesSubtitle =>
      'The intensity you reported in each entry (1 to 5).';

  @override
  String xv2DashDaysCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get xv2DashSeeMore => 'See more';

  @override
  String get xv2DashSeeLess => 'See less';

  @override
  String get xv2DashNoItems => 'No items recorded in this period.';

  @override
  String get xv2DashWaterTitle => 'Water per day';

  @override
  String get xv2DashNoWater => 'No water logged in this period.';

  @override
  String get xv2DashTogetherTitle => 'On the same day';

  @override
  String xv2DashCooccurrence(int total, String a, String b, int both) {
    return 'On the $total days you marked \'$a\', you also marked \'$b\' on $both.';
  }

  @override
  String get xv2DashEntriesTitle => 'Your entries';

  @override
  String get xv2DashNoEntries => 'You have no entries in this period yet.';

  @override
  String xv2DashMoodLine(String mood) {
    return 'How you were: $mood';
  }

  @override
  String get xv2DashDeleteTitle => 'Delete entry';

  @override
  String get xv2DashDeleteBody =>
      'This entry will be removed from your history.';

  @override
  String get xv2DashDeleteConfirm => 'Delete';

  @override
  String get xv2WaterTitle => 'Hydration 💧';

  @override
  String get xv2WaterTodayLogs => 'Today\'s logs';

  @override
  String get xv2WaterHistoryTitle => 'Last 30 days';

  @override
  String get xv2WaterRemindersTitle => 'Water reminders';

  @override
  String get xv2WaterOther => 'Other';

  @override
  String xv2WaterStreak(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Streak: $count days',
      one: 'Streak: 1 day',
      zero: 'Streak: 0 days',
    );
    return '$_temp0';
  }

  @override
  String xv2WaterGoalChip(int ml) {
    return 'Your goal: $ml ml';
  }

  @override
  String get xv2WaterGoalDialogTitle => 'Your daily goal';

  @override
  String get xv2WaterGoalHint =>
      'You choose your own goal, between 250 and 10000 ml.';

  @override
  String get xv2WaterGoalSave => 'Save';

  @override
  String get xv2WaterNoLogsToday => 'No glass of water logged today yet.';

  @override
  String xv2WaterLoggedAt(String time) {
    return 'Logged at $time';
  }

  @override
  String xv2WaterLoggedViaReminder(String time) {
    return 'Logged from the $time reminder';
  }

  @override
  String get xv2WaterDeleteLog => 'Delete log';

  @override
  String get jv2PendingSync => 'Waiting to sync';

  @override
  String get jv2OutboxRejectedNotice =>
      'One entry could not be sent. Check it and try again.';
}
