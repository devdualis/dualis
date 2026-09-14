import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService secureStorageService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorageService = SecureStorageService(storage: mockStorage);
  });

  group('SecureStorageService Hardware Keystore Integration Tests (AUTH-02)', () {
    const testAccessToken = 'mock.jwt.access.token.123';
    const testRefreshToken = 'mock.jwt.refresh.token.456';
    const testUserId = '123e4567-e89b-12d3-a456-426614174000';

    test('persistTokens stores access token, refresh token, and userId atomically',
        () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await secureStorageService.persistTokens(
        accessToken: testAccessToken,
        refreshToken: testRefreshToken,
        userId: testUserId,
      );

      verify(() => mockStorage.write(
            key: 'dualis_access_token',
            value: testAccessToken,
          )).called(1);

      verify(() => mockStorage.write(
            key: 'dualis_refresh_token',
            value: testRefreshToken,
          )).called(1);

      verify(() => mockStorage.write(
            key: 'dualis_user_id',
            value: testUserId,
          )).called(1);
    });

    test('getAccessToken retrieves the persisted access token', () async {
      when(() => mockStorage.read(key: 'dualis_access_token'))
          .thenAnswer((_) async => testAccessToken);

      final token = await secureStorageService.getAccessToken();
      expect(token, equals(testAccessToken));
      verify(() => mockStorage.read(key: 'dualis_access_token')).called(1);
    });

    test('getRefreshToken retrieves the persisted refresh token', () async {
      when(() => mockStorage.read(key: 'dualis_refresh_token'))
          .thenAnswer((_) async => testRefreshToken);

      final token = await secureStorageService.getRefreshToken();
      expect(token, equals(testRefreshToken));
      verify(() => mockStorage.read(key: 'dualis_refresh_token')).called(1);
    });

    test('getUserId retrieves the stored user UUID', () async {
      when(() => mockStorage.read(key: 'dualis_user_id'))
          .thenAnswer((_) async => testUserId);

      final id = await secureStorageService.getUserId();
      expect(id, equals(testUserId));
      verify(() => mockStorage.read(key: 'dualis_user_id')).called(1);
    });

    test('isBiometricEnabled returns true when flag is set to "true"', () async {
      when(() => mockStorage.read(key: 'dualis_biometric_enabled'))
          .thenAnswer((_) async => 'true');

      final enabled = await secureStorageService.isBiometricEnabled();
      expect(enabled, isTrue);

      when(() => mockStorage.read(key: 'dualis_biometric_enabled'))
          .thenAnswer((_) async => 'false');

      final disabled = await secureStorageService.isBiometricEnabled();
      expect(disabled, isFalse);
    });

    test('setBiometricEnabled stores boolean flag as string', () async {
      when(() => mockStorage.write(
            key: 'dualis_biometric_enabled',
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await secureStorageService.setBiometricEnabled(true);
      verify(() => mockStorage.write(
            key: 'dualis_biometric_enabled',
            value: 'true',
          )).called(1);

      await secureStorageService.setBiometricEnabled(false);
      verify(() => mockStorage.write(
            key: 'dualis_biometric_enabled',
            value: 'false',
          )).called(1);
    });

    test('clearAll delegates to deleteAll on mockStorage', () async {
      when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

      await secureStorageService.clearAll();
      verify(() => mockStorage.deleteAll()).called(1);
    });
  });
}
