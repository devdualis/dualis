import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dualis_mobile/core/constants/app_colors.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/shared/widgets/dualis_primary_button.dart';

class MockAuthRepository implements AuthRepository {
  bool loginCalled = false;
  String? lastEmail;
  String? lastPassword;
  bool shouldSucceed = true;
  DioException? failureDioError;

  final UserProfile mockUser = const UserProfile(
    id: 'user-123',
    name: 'Paciente Teste',
    email: 'teste@exemplo.com',
    gender: Gender.masculino,
    dateOfBirth: '1990-01-01',
    isEmailVerified: true,
  );

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    loginCalled = true;
    lastEmail = email;
    lastPassword = password;
    if (!shouldSucceed) {
      if (failureDioError != null) {
        throw failureDioError!;
      }
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return {
      'user': mockUser.toJson(),
      'accessToken': 'mock-access-token',
      'refreshToken': 'mock-refresh-token',
    };
  }

  @override
  Future<UserProfile> getProfile({required String token}) async => mockUser;

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String dateOfBirth,
    required bool lgpdConsent,
    String? disclaimerVersion,
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async =>
      {};

  @override
  Future<UserProfile> updateProfile({
    required String token,
    String? name,
    String? dateOfBirth,
    String? picture,
    String? gender,
  }) async =>
      mockUser;

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {}
}

class MockSecureStorage extends SecureStorageService {
  @override
  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<void> clearAll() async {}
}

Widget createLoginTestApp({
  required MockAuthRepository repository,
  Locale locale = const Locale('pt', 'BR'),
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.login,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home Screen')),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Onboarding Screen')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      secureStorageServiceProvider.overrideWithValue(MockSecureStorage()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('LoginScreen Tests', () {
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
    });

    testWidgets('1. Renders logo, title, email, password fields and login CTA',
        (tester) async {
      await tester.pumpWidget(createLoginTestApp(repository: mockRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loginBrandLogo')), findsOneWidget);
      expect(find.text('Entrar no DualisCheckUp'), findsOneWidget);
      expect(find.byKey(const Key('loginEmailField')), findsOneWidget);
      expect(find.byKey(const Key('loginPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);
    });

    testWidgets('2. Empty submit shows validation errors', (tester) async {
      await tester.pumpWidget(createLoginTestApp(repository: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();

      expect(mockRepo.loginCalled, isFalse);
      expect(find.text('Informe um endereço de e-mail válido.'), findsOneWidget);
      expect(find.text('Senha é obrigatória.'), findsOneWidget);
    });

    testWidgets('3. Successful login navigates to /home', (tester) async {
      await tester.pumpWidget(createLoginTestApp(repository: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('loginEmailField')),
        'paciente@exemplo.com',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'SenhaSegura123!',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();

      expect(mockRepo.loginCalled, isTrue);
      expect(mockRepo.lastEmail, 'paciente@exemplo.com');
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('4. Failed 401 login shows localized friendly credentials error SnackBar',
        (tester) async {
      mockRepo.shouldSucceed = false;

      await tester.pumpWidget(createLoginTestApp(repository: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('loginEmailField')),
        'paciente@exemplo.com',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'SenhaIncorreta!',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();

      expect(mockRepo.loginCalled, isTrue);
      expect(
        find.text('E-mail ou senha incorretos. Por favor, verifique suas credenciais.'),
        findsOneWidget,
      );
    });

    testWidgets('5. Network connection error shows friendly localized error in Spanish',
        (tester) async {
      mockRepo.shouldSucceed = false;
      mockRepo.failureDioError = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionError,
      );

      await tester.pumpWidget(createLoginTestApp(
        repository: mockRepo,
        locale: const Locale('es'),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('loginEmailField')),
        'paciente@ejemplo.com',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'Password123!',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();

      expect(mockRepo.loginCalled, isTrue);
      expect(
        find.text('No se pudo conectar con el servidor. Verifica tu conexión a internet.'),
        findsOneWidget,
      );
    });
  });
}
