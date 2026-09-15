import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/shared/widgets/dualis_primary_button.dart';

class MockSecureStorageService extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {}

  @override
  Future<void> clearAll() async {}
}

class MockAuthRepository implements AuthRepository {
  bool verifyCalled = false;
  bool resendCalled = false;
  String? lastEmail;
  String? lastCode;
  bool shouldSucceed = true;
  String? failureErrorMessage;

  final UserProfile mockUser = const UserProfile(
    id: 'user-uuid-123',
    name: 'Test Patient',
    email: 'test@example.com',
    gender: Gender.masculino,
    dateOfBirth: '1990-01-01',
    isEmailVerified: true,
  );

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
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async =>
      {};

  @override
  Future<UserProfile> getProfile({required String token}) async => mockUser;

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

  @override
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    verifyCalled = true;
    lastEmail = email;
    lastCode = code;

    if (!shouldSucceed) {
      throw DioException(
        requestOptions: RequestOptions(path: '/verify-email'),
        response: Response(
          requestOptions: RequestOptions(path: '/verify-email'),
          statusCode: 400,
          data: {'message': failureErrorMessage ?? 'Código de verificação incorreto.'},
        ),
      );
    }

    return {
      'user': mockUser.toJson(),
      'accessToken': 'jwt-access-token-123',
      'refreshToken': 'jwt-refresh-token-456',
    };
  }

  @override
  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    resendCalled = true;
    lastEmail = email;
    if (!shouldSucceed) {
      throw DioException(
        requestOptions: RequestOptions(path: '/resend-verification'),
        response: Response(
          requestOptions: RequestOptions(path: '/resend-verification'),
          statusCode: 429,
          data: {'message': 'Aguarde 60 segundos antes de solicitar um novo código.'},
        ),
      );
    }
    return {'success': true};
  }
}

Widget createTestWidget({
  required MockAuthRepository mockRepo,
  required String email,
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.verifyEmail,
    routes: [
      GoRoute(
        path: RoutePaths.verifyEmail,
        builder: (context, state) => EmailVerificationScreen(email: email),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home Screen')),
        ),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login Screen')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
      secureStorageServiceProvider.overrideWithValue(MockSecureStorageService()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
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
  group('EmailVerificationScreen Widget Tests', () {
    late MockAuthRepository mockRepo;
    const testEmail = 'patient@dualishealth.com';

    setUp(() {
      mockRepo = MockAuthRepository();
    });

    testWidgets('Renders all required elements with masked email and 6 OTP fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockRepo: mockRepo, email: testEmail));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verificationBrandLogo')), findsOneWidget);
      expect(find.text('Verifique seu e-mail'), findsOneWidget);
      expect(find.text('p***t@dualishealth.com'), findsOneWidget);

      for (int i = 0; i < 6; i++) {
        expect(find.byKey(Key('otp_digit_$i')), findsOneWidget);
      }

      final buttonFinder = find.widgetWithText(DualisPrimaryButton, 'Confirmar e Ativar Conta');
      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<DualisPrimaryButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('Entering complete 6-digit code enables submit button and auto-submits',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockRepo: mockRepo, email: testEmail));
      await tester.pumpAndSettle();

      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_digit_$i')), '${i + 1}');
      }
      await tester.pumpAndSettle();

      expect(mockRepo.verifyCalled, isTrue);
      expect(mockRepo.lastEmail, testEmail);
      expect(mockRepo.lastCode, '123456');

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('Failed verification displays error snackbar with clinical Crimson alert',
        (WidgetTester tester) async {
      mockRepo.shouldSucceed = false;
      mockRepo.failureErrorMessage = 'Código de verificação incorreto ou expirado.';

      await tester.pumpWidget(createTestWidget(mockRepo: mockRepo, email: testEmail));
      await tester.pumpAndSettle();

      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_digit_$i')), '9');
      }
      await tester.pumpAndSettle();

      expect(mockRepo.verifyCalled, isTrue);
      expect(find.text('Código de verificação incorreto ou expirado.'), findsOneWidget);
    });

    testWidgets('Resend countdown timer updates and shows resend button when time elapses',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockRepo: mockRepo, email: testEmail));
      await tester.pump();

      expect(find.textContaining('Reenviar código em'), findsOneWidget);

      // Fast forward 61 seconds for cooldown to expire
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();

      final resendButtonFinder = find.text('Não recebeu o código? Reenviar');
      expect(resendButtonFinder, findsOneWidget);

      // Scroll into view and tap resend
      await tester.ensureVisible(resendButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(resendButtonFinder);
      await tester.pumpAndSettle();

      expect(mockRepo.resendCalled, isTrue);
      expect(mockRepo.lastEmail, testEmail);
      expect(find.text('Novo código enviado para seu e-mail.'), findsOneWidget);
    });
  });
}
