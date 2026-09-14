class ApiEndpoints {
  // Base URL (defaults to localhost:3000, can be overridden via dart-define)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Authentication Endpoints
  static const String register = '/v1/auth/register';
  static const String login = '/v1/auth/login';
  static const String me = '/v1/auth/me';
  static const String refresh = '/v1/auth/refresh';

  // Legal & Regulatory Endpoints
  static const String disclaimer = '/v1/legal/disclaimer';
  static const String consent = '/v1/legal/consent';
}
