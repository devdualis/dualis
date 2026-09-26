import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/hydration/domain/models/water_intake_log.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/features/hydration/presentation/screens/hydration_dashboard_screen.dart';
import 'package:dualis_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/screens/historical_dashboard_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class _FakeHistoryDataSource extends TriageHistoryRemoteDataSource {
  final TriageHistoryResponse response;
  _FakeHistoryDataSource(this.response);

  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async => response;

  @override
  Future<bool> deleteHistoryItem(String id) async => true;
}

class FakeHydrationController extends HydrationController {
  final HydrationState _initialState;
  FakeHydrationController(this._initialState);

  @override
  HydrationState build() => _initialState;

  @override
  Future<void> loadData() async {}

  @override
  Future<bool> logWater({
    required int amountMl,
    String source = 'manual',
    DateTime? timestamp,
  }) async {
    state = state.copyWith(
      todayTotalMl: state.todayTotalMl + amountMl,
      todayLogs: [
        ...state.todayLogs,
        WaterIntakeEntry(
          id: DateTime.now().millisecondsSinceEpoch,
          userId: 'test-user',
          amountMl: amountMl,
          timestamp: DateTime.now(),
          source: source,
        ),
      ],
    );
    return true;
  }
}

Widget createHydrationQATestApp({
  String initialLocation = RoutePaths.home,
  FakeHydrationController? hydrationController,
}) {
  final fakeHydration = hydrationController ??
      FakeHydrationController(
        const HydrationState(
          isLoading: false,
          todayTotalMl: 0,
          settings: HydrationSettings(dailyTargetMl: 2000),
          last7DaysTotals: {},
          todayLogs: [],
        ),
      );

  final mockHistory = TriageHistoryResponse(
    logs: [],
    physicalSummary: {},
    emotionalSummary: [],
    criticalRecurrences: [],
  );

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.hydration,
        builder: (context, state) => const HydrationDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.history,
        builder: (context, state) => const HistoricalDashboardScreen(),
      ),
    ],
  );

  final app = MaterialApp.router(
    routerConfig: router,
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );

  return ProviderScope(
    overrides: [
      hydrationControllerProvider.overrideWith(() => fakeHydration),
      triageHistoryDataSourceProvider.overrideWithValue(_FakeHistoryDataSource(mockHistory)),
    ],
    child: app,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QA Feature 2: Tela dedicada para consumo de água e remoção de outros locais', () {
    testWidgets('QA 2.1: HomeScreen does NOT render hydration card in body',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHydrationQATestApp(initialLocation: RoutePaths.home));
      await tester.pumpAndSettle();

      // Hydration card removed from Home body
      expect(find.byKey(const Key('home_hydration_card')), findsNothing);
      expect(find.text('Hidratação Diária'), findsNothing);
    });

    testWidgets('QA 2.2: SettingsScreen does NOT render hydration notification controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHydrationQATestApp(initialLocation: RoutePaths.settings));
      await tester.pumpAndSettle();

      expect(find.text('Lembretes de Hidratação'), findsNothing);
      expect(find.text('Notificações de Hidratação'), findsNothing);
      expect(find.text('Intervalo de Lembrete'), findsNothing);
    });

    testWidgets('QA 2.3: HistoricalDashboardScreen does NOT render water consumption chart',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHydrationQATestApp(initialLocation: RoutePaths.history));
      await tester.pumpAndSettle();

      expect(find.text('Consumo de Água'), findsNothing);
      expect(find.text('Histórico de Hidratação'), findsNothing);
    });

    testWidgets('QA 2.4: Water icon removed from top AppBar and included in bottom navigation bar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHydrationQATestApp(initialLocation: RoutePaths.home));
      await tester.pumpAndSettle();

      // Upper AppBar water icon is REMOVED
      expect(find.byKey(const Key('home_hydration_nav_button')), findsNothing);

      // Bottom navigation bar has hydration destination with hidden text label for clean look
      final bottomNavButton = find.byKey(const Key('nav_destination_hydration'));
      expect(bottomNavButton, findsOneWidget);
      expect(find.text('Água'), findsNothing);

      // Tapping bottom navigation bar tab opens HydrationDashboardScreen
      await tester.tap(bottomNavButton);
      await tester.pumpAndSettle();

      expect(find.byType(HydrationDashboardScreen), findsOneWidget);
      expect(find.text('Controle de Hidratação 💧'), findsOneWidget);
    });

    testWidgets('QA 2.5: HydrationDashboardScreen allows quick-adding water and updates total',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = FakeHydrationController(
        const HydrationState(
          isLoading: false,
          todayTotalMl: 0,
          settings: HydrationSettings(dailyTargetMl: 2000),
          last7DaysTotals: {},
          todayLogs: [],
        ),
      );

      await tester.pumpWidget(createHydrationQATestApp(
        initialLocation: RoutePaths.hydration,
        hydrationController: controller,
      ));
      await tester.pumpAndSettle();

      expect(find.text('0 / 2000 ml'), findsOneWidget);
      expect(find.text('+200 ml'), findsOneWidget);
      expect(find.text('+300 ml'), findsOneWidget);
      expect(find.text('+500 ml'), findsOneWidget);

      // Tap +200 ml chip
      await tester.tap(find.text('+200 ml'));
      await tester.pumpAndSettle();

      expect(find.text('200 / 2000 ml'), findsOneWidget);

      // Tap +300 ml chip
      await tester.tap(find.text('+300 ml'));
      await tester.pumpAndSettle();

      expect(find.text('500 / 2000 ml'), findsOneWidget);
    });
  });
}
