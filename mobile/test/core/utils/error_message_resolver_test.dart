import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/utils/error_message_resolver.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

void main() {
  group('ErrorMessageResolver Unit Tests', () {
    late AppLocalizations l10nPt;
    late AppLocalizations l10nEs;
    late AppLocalizations l10nEn;

    setUpAll(() async {
      l10nPt = await AppLocalizations.delegate.load(const Locale('pt'));
      l10nEs = await AppLocalizations.delegate.load(const Locale('es'));
      l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('Maps DioException.connectionError to friendly network error in PT, ES, EN', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      expect(
        ErrorMessageResolver.resolve(dioError, l10nPt),
        equals(l10nPt.errorNetworkConnection),
      );
      expect(
        ErrorMessageResolver.resolve(dioError, l10nEs),
        equals(l10nEs.errorNetworkConnection),
      );
      expect(
        ErrorMessageResolver.resolve(dioError, l10nEn),
        equals(l10nEn.errorNetworkConnection),
      );
    });

    test('Maps DioException.connectionTimeout to timeout error', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        ErrorMessageResolver.resolve(dioError, l10nPt),
        equals(l10nPt.errorConnectionTimeout),
      );
      expect(
        ErrorMessageResolver.resolve(dioError, l10nEs),
        equals(l10nEs.errorConnectionTimeout),
      );
      expect(
        ErrorMessageResolver.resolve(dioError, l10nEn),
        equals(l10nEn.errorConnectionTimeout),
      );
    });

    test('Maps 401 Unauthorized response to invalid credentials', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        ErrorMessageResolver.resolve(dioError, l10nPt),
        equals(l10nPt.errorInvalidCredentials),
      );
      expect(
        ErrorMessageResolver.resolve(dioError, l10nEs),
        equals(l10nEs.errorInvalidCredentials),
      );
      expect(
        ErrorMessageResolver.resolve(dioError, l10nEn),
        equals(l10nEn.errorInvalidCredentials),
      );
    });

    test('Maps 409 Conflict to email already registered', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 409,
          data: {'message': 'Email already registered'},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        ErrorMessageResolver.resolve(dioError, l10nPt),
        equals(l10nPt.errorEmailAlreadyExists),
      );
      expect(
        ErrorMessageResolver.resolve(dioError, l10nEs),
        equals(l10nEs.errorEmailAlreadyExists),
      );
      expect(
        ErrorMessageResolver.resolve(dioError, l10nEn),
        equals(l10nEn.errorEmailAlreadyExists),
      );
    });

    test('Maps 500 Internal Server Error to friendly instability message', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        ErrorMessageResolver.resolve(dioError, l10nPt),
        equals(l10nPt.errorServerInternal),
      );
      expect(
        ErrorMessageResolver.resolve(dioError, l10nEs),
        equals(l10nEs.errorServerInternal),
      );
      expect(
        ErrorMessageResolver.resolve(dioError, l10nEn),
        equals(l10nEn.errorServerInternal),
      );
    });

    test('Maps Session Expired exception to friendly session expired message', () {
      final exception = Exception('Sessão expirada. Faça login novamente.');
      expect(
        ErrorMessageResolver.resolve(exception, l10nPt),
        equals(l10nPt.errorSessionExpired),
      );
      expect(
        ErrorMessageResolver.resolve(exception, l10nEs),
        equals(l10nEs.errorSessionExpired),
      );
      expect(
        ErrorMessageResolver.resolve(exception, l10nEn),
        equals(l10nEn.errorSessionExpired),
      );
    });

    test('Maps Verification Code Invalid string to localized code error', () {
      expect(
        ErrorMessageResolver.resolve('invalid verification code', l10nPt),
        equals(l10nPt.errorEmailVerificationCodeInvalid),
      );
      expect(
        ErrorMessageResolver.resolve('código expirado', l10nEs),
        equals(l10nEs.errorEmailVerificationCodeInvalid),
      );
      expect(
        ErrorMessageResolver.resolve('invalid code', l10nEn),
        equals(l10nEn.errorEmailVerificationCodeInvalid),
      );
    });

    test('Strips Exception: prefix safely for clean user messages', () {
      final exception = Exception('Operação cancelada pelo usuário.');
      expect(
        ErrorMessageResolver.resolve(exception, l10nPt),
        equals('Operação cancelada pelo usuário.'),
      );
    });

    test('Handles null error gracefully with unexpected error message', () {
      expect(
        ErrorMessageResolver.resolve(null, l10nPt),
        equals(l10nPt.errorUnexpected),
      );
    });
  });
}
