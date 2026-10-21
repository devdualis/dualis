import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class FakeUserProfile extends Fake implements UserProfile {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserProfile());
  });
  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockSecureStorage;
  late ProviderContainer container;

  const testUser = UserProfile(
    id: 'user-persistence-uuid-123',
    name: 'Ricardo Rincon',
    email: 'ricardo@dualis.test',
    gender: Gender.masculino,
    dateOfBirth: '1985-05-15',
    isEmailVerified: true,
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    mockSecureStorage = MockSecureStorageService();

    when(() => mockSecureStorage.clearUserProfile()).thenAnswer((_) async {});
    when(() => mockSecureStorage.clearAll()).thenAnswer((_) async {});
    when(() => mockSecureStorage.saveUserProfile(any())).thenAnswer((_) async {});
    when(() => mockSecureStorage.getRefreshToken()).thenAnswer((_) async => null);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
        secureStorageServiceProvider.overrideWithValue(mockSecureStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthController WhatsApp-style Session Persistence Tests', () {
    test('restoreSession restores cached profile immediately and stays authenticated',
        () async {
      when(() => mockSecureStorage.getAccessToken())
          .thenAnswer((_) async => 'stored-access-token');
      when(() => mockSecureStorage.getUserProfile())
          .thenAnswer((_) async => testUser);
      when(() => mockRepository.getProfile(token: 'stored-access-token'))
          .thenAnswer((_) async => testUser);

      final controller = container.read(authControllerProvider.notifier);
      await controller.restoreSession();

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, equals(testUser));
      expect(state.accessToken, equals('stored-access-token'));
      verify(() => mockSecureStorage.saveUserProfile(testUser)).called(1);
    });

    test('restoreSession preserves local session if network is offline (resilient)',
        () async {
      when(() => mockSecureStorage.getAccessToken())
          .thenAnswer((_) async => 'stored-access-token');
      when(() => mockSecureStorage.getUserProfile())
          .thenAnswer((_) async => testUser);
      when(() => mockRepository.getProfile(token: 'stored-access-token'))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          type: DioExceptionType.connectionError,
        ),
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.restoreSession();

      final state = container.read(authControllerProvider);
      // User must STAY authenticated with cached profile, NOT logged out!
      expect(state.isAuthenticated, isTrue);
      expect(state.user, equals(testUser));
      // Storage should NEVER have been wiped on network error!
      verifyNever(() => mockSecureStorage.clearAll());
    });

    test('restoreSession logs out only when server returns 401 Unauthorized',
        () async {
      when(() => mockSecureStorage.getAccessToken())
          .thenAnswer((_) async => 'expired-token');
      when(() => mockSecureStorage.getUserProfile())
          .thenAnswer((_) async => testUser);
      when(() => mockRepository.getProfile(token: 'expired-token')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/me'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.restoreSession();

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      verify(() => mockSecureStorage.clearAll()).called(1);
    });

    test(
        'restoreSession preserves local session if 401 occurs but refresh token is still present',
        () async {
      when(() => mockSecureStorage.getAccessToken())
          .thenAnswer((_) async => 'expired-token');
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => 'valid-refresh-token');
      when(() => mockSecureStorage.getUserProfile())
          .thenAnswer((_) async => testUser);
      when(() => mockRepository.getProfile(token: 'expired-token')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/me'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.restoreSession();

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, equals(testUser));
      verifyNever(() => mockSecureStorage.clearAll());
    });

    test('logout clears secure storage and resets auth state', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.logout();

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      verify(() => mockSecureStorage.clearAll()).called(1);
    });
  });

  group('AuthController pending email verification', () {
    DioException notVerifiedError() => DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
            data: {
              'code': 'EMAIL_NOT_VERIFIED',
              'message':
                  'E-mail não verificado. Por favor, confirme seu e-mail antes de entrar.',
            },
          ),
          type: DioExceptionType.badResponse,
        );

    test('restoreSession without a token loads the pending verification email',
        () async {
      when(() => mockSecureStorage.getAccessToken()).thenAnswer((_) async => null);
      when(() => mockSecureStorage.getUserProfile()).thenAnswer((_) async => null);
      when(() => mockSecureStorage.getPendingVerificationEmail())
          .thenAnswer((_) async => 'maria@dualis.test');

      await container.read(authControllerProvider.notifier).restoreSession();

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.pendingVerificationEmail, 'maria@dualis.test');
    });

    test('login with an unverified email remembers it and flags verification',
        () async {
      when(() => mockRepository.login(
            email: 'maria@dualis.test',
            password: 'Senha123!',
          )).thenThrow(notVerifiedError());
      when(() => mockSecureStorage.savePendingVerificationEmail(any()))
          .thenAnswer((_) async {});

      final controller = container.read(authControllerProvider.notifier);
      final ok = await controller.login(email: 'maria@dualis.test', password: 'Senha123!');

      expect(ok, isFalse);
      expect(controller.lastLoginNeedsVerification, isTrue);
      expect(container.read(authControllerProvider).pendingVerificationEmail,
          'maria@dualis.test');
      verify(() => mockSecureStorage.savePendingVerificationEmail('maria@dualis.test'))
          .called(1);
      // No code was sent in this session: resend is allowed right away.
      expect(controller.resendCooldownRemaining(const Duration(seconds: 60)),
          Duration.zero);
    });

    test('login with wrong credentials does not flag verification', () async {
      when(() => mockRepository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {'message': 'Credenciais inválidas.'},
        ),
        type: DioExceptionType.badResponse,
      ));

      final controller = container.read(authControllerProvider.notifier);
      await controller.login(email: 'maria@dualis.test', password: 'x');

      expect(controller.lastLoginNeedsVerification, isFalse);
      expect(container.read(authControllerProvider).pendingVerificationEmail, isNull);
    });

    test('successful verification clears the pending email', () async {
      when(() => mockRepository.login(
            email: 'ricardo@dualis.test',
            password: 'Senha123!',
          )).thenThrow(notVerifiedError());
      when(() => mockSecureStorage.savePendingVerificationEmail(any()))
          .thenAnswer((_) async {});
      when(() => mockSecureStorage.clearPendingVerificationEmail())
          .thenAnswer((_) async {});
      when(() => mockSecureStorage.persistTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async {});
      when(() => mockRepository.verifyEmail(email: 'ricardo@dualis.test', code: '123456'))
          .thenAnswer((_) async => {
                'user': testUser.toJson(),
                'accessToken': 'a',
                'refreshToken': 'r',
              });

      final controller = container.read(authControllerProvider.notifier);
      await controller.login(email: 'ricardo@dualis.test', password: 'Senha123!');
      final ok = await controller.verifyEmail(email: 'ricardo@dualis.test', code: '123456');

      expect(ok, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.pendingVerificationEmail, isNull);
      verify(() => mockSecureStorage.clearPendingVerificationEmail()).called(1);
    });
  });
}
