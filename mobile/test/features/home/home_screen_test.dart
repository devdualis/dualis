import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/features/hydration/presentation/hydration_reminder_offer.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createHomeTestApp({
  AuthState? initialAuthState,
  TriageOutcome? initialOutcome,
  DateTime? now,
  bool hydrationOfferPending = false,
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
      GoRoute(
        path: RoutePaths.library,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Library Screen')),
        ),
      ),
      GoRoute(
        path: RoutePaths.hydration,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Hydration Screen')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      homeClockProvider.overrideWithValue(
        () => now ?? DateTime(2026, 10, 27, 9),
      ),
      hydrationReminderOfferProvider.overrideWithValue(
        _FakeHydrationOffer(hydrationOfferPending),
      ),
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

class _FakeHydrationOffer extends HydrationReminderOffer {
  bool pending;
  _FakeHydrationOffer(this.pending) : super(SecureStorageService());

  @override
  Future<bool> takePending() async {
    final value = pending;
    pending = false;
    return value;
  }
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
        name: 'Ricardo Rincon',
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
      expect(find.text('Olá, Ricardo! Bom dia'), findsOneWidget);
      expect(find.text('rinconrj@gmail.com'), findsOneWidget);

      // Verify LGPD badge
      expect(find.text('Seus registros estão protegidos'), findsOneWidget);

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

    testWidgets('Shows the completed stage card on the main home tab and the full result on Meu Dia tab',
        (WidgetTester tester) async {
      final mockOutcome = TriageOutcome(
        id: 'checkin-chest-1',
        vertical: 'physical',
        intensityScore: 5,
        primaryCategory: 'cardiovascular_torax',
        categoryLabel: 'Peito',
        somaticMapping: 'Aperto no peito e coração acelerado',
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
        aiMappedLayTerm: 'Dor e aperto no peito',
      );

      await tester.pumpWidget(createHomeTestApp(initialOutcome: mockOutcome));
      await tester.pumpAndSettle();

      // Verify physical stage card is marked completed, NOT displaying uncompleted start button
      expect(find.byKey(const Key('fisica_completed_card')), findsOneWidget);
      expect(find.byKey(const Key('start_fisica_triage_button')), findsNothing);

      // Tapping the "Meu Dia" nav destination switches to Tab 1
      await tester.tap(find.byKey(const Key('nav_destination_today_outcome')));
      await tester.pumpAndSettle();

      // Verify Tab 1 "Meu Dia" is now active
      expect(find.byKey(const Key('today_triage_result_scroll_view')), findsOneWidget);
      expect(find.text('Meu Dia'), findsOneWidget);
    });
    const greetUser = UserProfile(
      id: 'usr-1',
      name: 'Ana Maria Souza',
      email: 'ana@example.com',
      gender: Gender.feminino,
      dateOfBirth: '1990-01-01',
    );
    const greetAuth = AuthState(
      isAuthenticated: true,
      user: greetUser,
      accessToken: 'jwt',
    );

    for (final (hour, text) in [
      (6, 'Olá, Ana! Bom dia'),
      (11, 'Olá, Ana! Bom dia'),
      (12, 'Olá, Ana! Boa tarde'),
      (17, 'Olá, Ana! Boa tarde'),
      (18, 'Olá, Ana! Boa noite'),
      (2, 'Olá, Ana! Boa noite'),
    ]) {
      testWidgets('greets by first name and local hour ($hour h)', (tester) async {
        await tester.pumpWidget(createHomeTestApp(
          initialAuthState: greetAuth,
          now: DateTime(2026, 10, 27, hour),
        ));
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget);
      });
    }

    testWidgets('library is reachable from the Home app bar', (tester) async {
      await tester.pumpWidget(createHomeTestApp(initialAuthState: greetAuth));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home_library_button')));
      await tester.pumpAndSettle();
      expect(find.text('Library Screen'), findsOneWidget);
    });

    testWidgets('first Home visit after registration offers water reminders once',
        (tester) async {
      await tester.pumpWidget(createHomeTestApp(
        initialAuthState: greetAuth,
        hydrationOfferPending: true,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Quer lembretes para beber água?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('hydration_reminder_offer_yes')));
      await tester.pumpAndSettle();
      expect(find.text('Hydration Screen'), findsOneWidget);
    });

    testWidgets('no water reminder offer when not pending', (tester) async {
      await tester.pumpWidget(createHomeTestApp(initialAuthState: greetAuth));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hydration_reminder_offer_dialog')), findsNothing);
    });
  });
}
