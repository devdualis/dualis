import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    } catch (_) {}
    return 'http://localhost:3000';
  }

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _envBaseUrl.isNotEmpty ? _envBaseUrl : _defaultBaseUrl;

  static const String register = '/v1/auth/register';
  static const String verifyEmail = '/v1/auth/verify-email';
  static const String resendVerification = '/v1/auth/resend-verification';
  static const String login = '/v1/auth/login';
  static const String me = '/v1/auth/me';
  static const String refresh = '/v1/auth/refresh';
  static const String updateProfile = '/v1/auth/profile';
  static const String changePassword = '/v1/auth/change-password';

  static const String disclaimer = '/v1/legal/disclaimer';
  static const String consent = '/v1/legal/consent';

  static const String emergencyEvent = '/v1/triage/emergency-event';

  static const String triageOutcome = '/v1/triage/outcome';
  static const String dailyCheckIn = '/v1/triage/daily-checkin';

  static const String antiburlaCheck = '/v1/triage/antiburla-check';

  static const String triageHistory = '/v1/triage/history';
  static const String classifySymptom = '/v1/ai/classify-symptom';
  static const String exportData = '/v1/auth/export-data';
  static const String deleteAccount = '/v1/auth/account';
}
