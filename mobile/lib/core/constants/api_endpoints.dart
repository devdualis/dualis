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

  // Base URL (defaults to platform-specific localhost, can be overridden via dart-define)
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _envBaseUrl.isNotEmpty ? _envBaseUrl : _defaultBaseUrl;

  // Authentication Endpoints
  static const String register = '/v1/auth/register';
  static const String login = '/v1/auth/login';
  static const String me = '/v1/auth/me';
  static const String refresh = '/v1/auth/refresh';

  // Legal & Regulatory Endpoints
  static const String disclaimer = '/v1/legal/disclaimer';
  static const String consent = '/v1/legal/consent';
}
