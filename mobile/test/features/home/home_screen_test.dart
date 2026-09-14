import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createHomeTestApp({AuthState? initialAuthState}) {
  final router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Onboarding Screen')),
        ),
      ),
      GoRoute(
        path: RoutePaths.triage,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Triage Screen')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      if (initialAuthState != null)
        authControllerProvider.overrideWith(
          () => _TestAuthController(initialAuthState),
        ),
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

class _TestAuthController extends AuthController {
  final AuthState _initial;
  _TestAuthController(this._initial);

  @override
  AuthState build() => _initial;

  @override
  Future<void> logout() async {
    state = const AuthState.initial();
  }
}

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('Renders authenticated user profile and LGPD protection badge',
        (WidgetTester tester) async {
      const mockUser = UserProfile(
        id: 'usr-123456',
        name: 'Dr. Ricardo Rincon',
        email: 'rinconrj@gmail.com',
        gender: Gender.masculino,
        dateOfBirth: '1990-01-01',
      );

      const authState = AuthState(
        isAuthenticated: true,
        user: mockUser,
        accessToken: 'mock-jwt-access-token',
        refreshToken: 'mock-jwt-refresh-token',
      );

      await tester.pumpWidget(createHomeTestApp(initialAuthState: authState));
      await tester.pumpAndSettle();

      // Verify greetings and user email
      expect(find.text('Olá, Dr. Ricardo Rincon'), findsOneWidget);
      expect(find.text('rinconrj@gmail.com'), findsOneWidget);

      // Verify LGPD badge
      expect(find.text('Prontuário Ativo & Protegido (LGPD Art. 11)'), findsOneWidget);

      // Verify Clinical systems
      expect(find.text('Visão Geral do Cuidado'), findsOneWidget);
      expect(find.text('Saúde Física & Sintomas'), findsOneWidget);
      expect(find.text('Bem-estar Psico-emocional'), findsOneWidget);
      expect(find.text('Criptografia AES-256-GCM'), findsOneWidget);

      // Verify CTAs
      expect(find.byKey(const Key('startTriageButton')), findsOneWidget);
      expect(find.byKey(const Key('logoutButton')), findsOneWidget);
    });

    testWidgets('Tapping start triage button navigates to /triage screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('startTriageButton')));
      await tester.pumpAndSettle();

      expect(find.text('Triage Screen'), findsOneWidget);
    });

    testWidgets('Tapping logout button opens dialog and confirms exit to onboarding',
        (WidgetTester tester) async {
      const mockUser = UserProfile(
        id: 'usr-123456',
        name: 'Carlos Silva',
        email: 'carlos@example.com',
        gender: Gender.masculino,
        dateOfBirth: '1990-01-01',
      );

      const authState = AuthState(
        isAuthenticated: true,
        user: mockUser,
        accessToken: 'jwt',
      );

      await tester.pumpWidget(createHomeTestApp(initialAuthState: authState));
      await tester.pumpAndSettle();

      // Scroll to logout button and tap
      await tester.ensureVisible(find.byKey(const Key('logoutButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logoutButton')));
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sair da Conta'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Deseja realmente encerrar sua sessão? Seus dados clínicos permanecem seguros e criptografados.'),
        findsOneWidget,
      );

      // Tap 'Sair' within dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sair'),
        ),
      );
      await tester.pumpAndSettle();

      // Should have navigated to Onboarding
      expect(find.text('Onboarding Screen'), findsOneWidget);
    });
  });
}
