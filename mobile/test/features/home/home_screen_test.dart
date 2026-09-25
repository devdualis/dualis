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
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createHomeTestApp({
  AuthState? initialAuthState,
  TriageOutcome? initialOutcome,
}) {
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
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Settings Screen')),
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
      if (initialOutcome != null)
        triageOutcomeProvider.overrideWith(
          () => _TestTriageOutcomeController(initialOutcome),
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

class _TestTriageOutcomeController extends TriageOutcomeNotifier {
  final TriageOutcome _outcome;
  _TestTriageOutcomeController(this._outcome);

  @override
  TriageOutcomeState build() => TriageOutcomeState(outcome: _outcome);

  @override
  Future<void> loadTodayOutcome() async {
    state = state.copyWith(outcome: _outcome);
  }
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
        dateOfBirth: '1985-10-20',
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

      expect(find.byKey(const Key('home_settings_button')), findsOneWidget);
      expect(find.byKey(const Key('home_profile_card')), findsOneWidget);
      expect(find.byKey(const Key('home_hydration_nav_button')), findsNothing);
      expect(find.byKey(const Key('nav_destination_hydration')), findsOneWidget);

      // Verify Stage Buttons
      expect(find.byKey(const Key('start_psicoemocional_triage_button')), findsOneWidget);
      expect(find.byKey(const Key('start_fisica_triage_button')), findsOneWidget);
    });

    testWidgets('Tapping stage buttons navigates to /triage screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('start_psicoemocional_triage_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start_psicoemocional_triage_button')));
      await tester.pumpAndSettle();

      expect(find.text('Triage Screen'), findsOneWidget);
    });

    testWidgets('Tapping settings button navigates to /settings screen',
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

      await tester.tap(find.byKey(const Key('home_settings_button')));
      await tester.pumpAndSettle();

      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('Renders TodayTriageSummaryCard on main home tab when today triage outcome exists',
        (WidgetTester tester) async {
      final mockOutcome = TriageOutcome(
        id: 'triage-cardio-critical-1',
        vertical: 'physical',
        intensityScore: 5,
        careDisposition: CareDisposition.emergency,
        primaryCategory: 'cardiovascular_torax',
        categoryLabel: 'Cardiovascular e Tórax',
        somaticMapping: 'Sensação de aperto torácico ou palpitação funcional',
        organicPrimacyApplied: false,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
        aiMappedLayTerm: 'Dor e aperto no peito',
      );

      await tester.pumpWidget(createHomeTestApp(initialOutcome: mockOutcome));
      await tester.pumpAndSettle();

      // Verify TodayTriageSummaryCard is visible on Home Tab with simplified header
      expect(find.byKey(const Key('today_triage_summary_card')), findsOneWidget);
      expect(find.text('Triagem de Hoje Concluída'), findsOneWidget);
      expect(find.text('Atendimento de Emergência'), findsWidgets);

      // Verify physical stage card is marked completed, NOT displaying uncompleted start button
      expect(find.byKey(const Key('fisica_completed_card')), findsOneWidget);
      expect(find.byKey(const Key('start_fisica_triage_button')), findsNothing);

      // Verify card is clickable to view full outcome
      final viewFullBtn = find.byKey(const Key('view_full_triage_result_button'));
      expect(viewFullBtn, findsOneWidget);

      // Tapping card switches tab to Tab 1
      await tester.ensureVisible(viewFullBtn);
      await tester.tap(viewFullBtn);
      await tester.pumpAndSettle();

      // Verify Tab 1 "Resultado do Dia" is now active
      expect(find.byKey(const Key('today_triage_result_scroll_view')), findsOneWidget);
      expect(find.text('Resultado do Dia'), findsOneWidget);
    });
  });
}
