import 'package:dio/dio.dart';
import '../../l10n/app_localizations.dart';

/// Utility class to sanitize technical exceptions (Dio, Socket, HTTP status codes)
/// into user-friendly, localized error messages.
class ErrorMessageResolver {
  const ErrorMessageResolver._();

  /// Resolves any error into a user-friendly localized string.
  static String resolve(dynamic error, AppLocalizations l10n) {
    if (error == null) {
      return l10n.errorUnexpected;
    }

    if (error is DioException) {
      return _resolveDioException(error, l10n);
    }

    final rawStr = error.toString();
    final lowerStr = rawStr.toLowerCase();

    // Network / Socket errors
    if (lowerStr.contains('socketexception') ||
        lowerStr.contains('failed host lookup') ||
        lowerStr.contains('connection refused') ||
        lowerStr.contains('network is unreachable') ||
        lowerStr.contains('sem conexão') ||
        lowerStr.contains('conexão') ||
        lowerStr.contains('conexao') ||
        lowerStr.contains('conectar') ||
        lowerStr.contains('sin conexión') ||
        lowerStr.contains('no internet') ||
        lowerStr.contains('connection') ||
        lowerStr.contains('network')) {
      return l10n.errorNetworkConnection;
    }

    // Timeouts
    if (lowerStr.contains('timeout') ||
        lowerStr.contains('timed out') ||
        lowerStr.contains('tempo esgotado') ||
        lowerStr.contains('tiempo agotado')) {
      return l10n.errorConnectionTimeout;
    }

    // Auth & credentials
    if (lowerStr.contains('401') ||
        lowerStr.contains('unauthorized') ||
        lowerStr.contains('credenciais inválidas') ||
        lowerStr.contains('credenciales inválidas') ||
        lowerStr.contains('invalid credentials') ||
        lowerStr.contains('e-mail ou senha incorretos') ||
        lowerStr.contains('correo o contraseña incorrectos')) {
      return l10n.errorInvalidCredentials;
    }

    // Session expired
    if (lowerStr.contains('sessão expirada') ||
        lowerStr.contains('sesión expirada') ||
        lowerStr.contains('session expired') ||
        lowerStr.contains('token expired') ||
        lowerStr.contains('jwt expired')) {
      return l10n.errorSessionExpired;
    }

    // Conflict / Duplicate Email
    if (lowerStr.contains('409') ||
        lowerStr.contains('conflict') ||
        lowerStr.contains('already exists') ||
        lowerStr.contains('já cadastrado') ||
        lowerStr.contains('ya registrado') ||
        lowerStr.contains('email_already_registered')) {
      return l10n.errorEmailAlreadyExists;
    }

    // Verification code invalid / expired
    if (lowerStr.contains('código inválido') ||
        lowerStr.contains('código expirado') ||
        lowerStr.contains('codigo invalido') ||
        lowerStr.contains('codigo expirado') ||
        lowerStr.contains('invalid code') ||
        lowerStr.contains('expired code') ||
        lowerStr.contains('invalid verification code')) {
      return l10n.errorEmailVerificationCodeInvalid;
    }

    // Server 500 errors
    if (lowerStr.contains('500') ||
        lowerStr.contains('502') ||
        lowerStr.contains('503') ||
        lowerStr.contains('internal server error')) {
      return l10n.errorServerInternal;
    }

    // Clean Exception prefix if it's already a clean user-facing string
    if (error is Exception) {
      if (rawStr.startsWith('Exception: ')) {
        final stripped = rawStr.substring('Exception: '.length).trim();
        // Ensure no technical syntax is leaked
        if (!stripped.contains('DioException') &&
            !stripped.contains('SocketException') &&
            !stripped.contains('HttpException') &&
            !stripped.contains('{') &&
            !stripped.contains('}') &&
            !stripped.contains('Error:')) {
          return stripped;
        }
      }
    }

    if (error is String) {
      final trimmed = error.trim();
      if (trimmed.isNotEmpty &&
          !trimmed.startsWith('Exception:') &&
          !trimmed.contains('DioException') &&
          !trimmed.contains('{') &&
          !trimmed.contains('}')) {
        return trimmed;
      }
    }

    return l10n.errorUnexpected;
  }

  static String _resolveDioException(DioException error, AppLocalizations l10n) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return l10n.errorConnectionTimeout;

      case DioExceptionType.connectionError:
        return l10n.errorNetworkConnection;

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (responseData is Map) {
          final message = responseData['message'] ?? responseData['error'];
          if (message is String) {
            final msgLower = message.toLowerCase();
            if (statusCode == 401 ||
                msgLower.contains('unauthorized') ||
                msgLower.contains('credenciais') ||
                msgLower.contains('credentials') ||
                msgLower.contains('invalid password') ||
                msgLower.contains('senha incorreta')) {
              return l10n.errorInvalidCredentials;
            }
            if (statusCode == 409 ||
                msgLower.contains('conflict') ||
                msgLower.contains('already exists') ||
                msgLower.contains('já cadastrado') ||
                msgLower.contains('ya registrado')) {
              return l10n.errorEmailAlreadyExists;
            }
            if (msgLower.contains('código') ||
                msgLower.contains('codigo') ||
                msgLower.contains('code') ||
                msgLower.contains('verification')) {
              return l10n.errorEmailVerificationCodeInvalid;
            }
          }
        }

        if (statusCode == 401) {
          return l10n.errorInvalidCredentials;
        }
        if (statusCode == 409) {
          return l10n.errorEmailAlreadyExists;
        }
        if (statusCode != null && statusCode >= 500) {
          return l10n.errorServerInternal;
        }
        return l10n.errorUnexpected;

      case DioExceptionType.cancel:
        return l10n.errorUnexpected;

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      default:
        return l10n.errorNetworkConnection;
    }
  }
}
