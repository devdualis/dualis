import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:dualis_mobile/features/dashboard/presentation/screens/check_in_summary_screen.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/anatomical_body_map.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/emotional_trend_chart.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class _FakeHistoryDataSource implements TriageHistoryRemoteDataSource {
  int fetchCount = 0;
  bool offline = false;

  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async {
    fetchCount++;
    if (offline) throw Exception('offline');
    return const TriageHistoryResponse(
      logs: [],
      physicalSummary: {'coluna_dorsal': 4},
      emotionalSummary: [
        EmotionalDayData(
          date: '2026-10-18',
          dimensions: {'estresse_burnout': 3},
        ),
      ],
      journalPatterns: [],
    );
  }

  @override
  Future<bool> deleteHistoryItem(String id) async => true;
}

void main() {
  late _FakeHistoryDataSource dataSource;

  setUp(() => dataSource = _FakeHistoryDataSource());

  late GoRouter router;

  Future<void> pumpSummary(
    WidgetTester tester,
    CheckInSummaryArgs args, {
    ProviderContainer? container,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    router = GoRouter(
      initialLocation: RoutePaths.checkInSummary,
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder:
              (context, state) =>
                  const Scaffold(body: Text('Home Screen Destination')),
        ),
        GoRoute(
          path: RoutePaths.emergency,
          builder:
              (context, state) =>
                  const Scaffold(body: Text('Emergency Screen')),
        ),
        GoRoute(
          path: RoutePaths.checkInSummary,
          builder: (context, state) => CheckInSummaryScreen(args: args),
        ),
      ],
    );

    final app = MaterialApp.router(
      routerConfig: router,
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
    await tester.pumpWidget(
      container != null
          ? UncontrolledProviderScope(container: container, child: app)
          : ProviderScope(
            overrides: [
              triageHistoryDataSourceProvider.overrideWithValue(dataSource),
            ],
            child: app,
          ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('physical check-in shows only the body map', (tester) async {
    await pumpSummary(tester, const CheckInSummaryArgs(showBodyMap: true));

    expect(find.text('Registro salvo'), findsOneWidget);
    expect(find.byType(AnatomicalBodyMap), findsOneWidget);
    expect(find.byType(EmotionalTrendChart), findsNothing);
    expect(dataSource.fetchCount, 1);
  });

  testWidgets('emotional check-in shows only the emotional trend', (
    tester,
  ) async {
    await pumpSummary(
      tester,
      const CheckInSummaryArgs(showEmotionalTrend: true),
    );

    expect(find.byType(EmotionalTrendChart), findsOneWidget);
    expect(find.byType(AnatomicalBodyMap), findsNothing);
  });

  testWidgets('dual check-in shows both views', (tester) async {
    await pumpSummary(
      tester,
      const CheckInSummaryArgs(showBodyMap: true, showEmotionalTrend: true),
    );

    expect(find.byType(AnatomicalBodyMap), findsOneWidget);
    expect(find.byType(EmotionalTrendChart), findsOneWidget);
  });

  testWidgets('returns Home by itself after 5 seconds', (tester) async {
    await pumpSummary(tester, const CheckInSummaryArgs(showBodyMap: true));

    expect(find.text('Voltar ao início (5)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Voltar ao início (1)'), findsOneWidget);
    expect(find.text('Home Screen Destination'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Home Screen Destination'), findsOneWidget);
  });

  testWidgets('touching the screen stops the automatic return', (tester) async {
    await pumpSummary(tester, const CheckInSummaryArgs(showBodyMap: true));

    await tester.tap(find.text('Registro salvo'));
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('Home Screen Destination'), findsNothing);
    expect(find.text('Voltar ao início'), findsOneWidget);

    await tester.tap(find.byKey(const Key('check_in_summary_home_button')));
    await tester.pumpAndSettle();
    expect(find.text('Home Screen Destination'), findsOneWidget);
  });

  testWidgets('system back goes Home instead of leaving the app', (
    tester,
  ) async {
    await pumpSummary(
      tester,
      const CheckInSummaryArgs(showEmotionalTrend: true),
    );

    final popHandled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(popHandled, isTrue);
    expect(find.text('Home Screen Destination'), findsOneWidget);
  });

  testWidgets('urgent help opened on top is never closed by the countdown', (
    tester,
  ) async {
    await pumpSummary(tester, const CheckInSummaryArgs(showBodyMap: true));

    // Same navigation as the global urgent-help button.
    router.push(RoutePaths.emergency);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(find.text('Emergency Screen'), findsOneWidget);
    expect(find.text('Home Screen Destination'), findsNothing);
  });

  testWidgets('cached history is refreshed, and kept when offline', (
    tester,
  ) async {
    final container = ProviderContainer(
      // No automatic retry timer after the offline failure.
      retry: (_, __) => null,
      overrides: [
        triageHistoryDataSourceProvider.overrideWithValue(dataSource),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(dashboardControllerProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(dashboardControllerProvider.future);
    expect(dataSource.fetchCount, 1);

    dataSource.offline = true;
    await pumpSummary(
      tester,
      const CheckInSummaryArgs(showBodyMap: true),
      container: container,
    );
    await tester.pump();

    expect(dataSource.fetchCount, 2);
    expect(find.byType(AnatomicalBodyMap), findsOneWidget);
  });
}
