import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/features/care/data/care_api.dart';
import 'package:dualis_mobile/features/care/presentation/screens/summary_screen.dart';
import 'package:dualis_mobile/features/journal/data/journal_remote_data_source.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/condition_readings_screen.dart';
import 'package:dualis_mobile/features/journal/presentation/widgets/readings_chart.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../care/care_screens_test.dart' show FakeCareApi;
import 'journal_test_helpers.dart';

class _Ana extends ActiveProfileController {
  @override
  ActiveProfileState build() => const ActiveProfileState(
        profiles: [
          Profile(
            id: 'p1',
            name: 'Ana',
            profileType: ProfileType.primary,
            ownership: ProfileOwnership.own,
            accessLevel: ProfileAccessLevel.owner,
          ),
        ],
        activeProfileId: 'p1',
      );
}

void main() {
  final pt = AppLocalizationsPt();
  setUpAll(() => initializeDateFormatting('pt'));
  const condition = UserCondition(
    id: 'c1',
    label: 'Hipertensão',
    tracking: [JournalKeys.trackingBloodPressure, JournalKeys.trackingWeight],
  );

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int daysAgo, int hour, [int minute = 0]) =>
      DateTime(today.year, today.month, today.day - daysAgo, hour, minute);

  List<ConditionReading> serverReadings() => [
        ConditionReading.bloodPressure(
            id: 'r1', conditionId: 'c1', measuredAt: at(0, 0, 10), systolic: 120, diastolic: 80, pulse: 72),
        ConditionReading.bloodPressure(
            id: 'r2', conditionId: 'c1', measuredAt: at(0, 0, 5), systolic: 131, diastolic: 86),
        ConditionReading.bloodPressure(
            id: 'r3', conditionId: 'c1', measuredAt: at(1, 9), systolic: 118, diastolic: 79),
        ConditionReading.weight(id: 'r4', conditionId: 'c1', measuredAt: at(3, 7, 30), kg: 72.5),
        // Outside 7 days, inside 30.
        ConditionReading.bloodPressure(
            id: 'r5', conditionId: 'c1', measuredAt: at(20, 8), systolic: 125, diastolic: 82),
        // Another condition: never shown here.
        ConditionReading.bloodPressure(
            id: 'x1', conditionId: 'c2', measuredAt: at(0, 0, 1), systolic: 140, diastolic: 90),
      ];

  Widget app(List<Override> overrides, Widget home) => ProviderScope(
        overrides: [
          ...overrides,
          activeProfileControllerProvider.overrideWith(_Ana.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('pt'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<JournalHarness> pumpScreen(WidgetTester tester, {bool online = true, List<JournalEntry> outbox = const []}) async {
    tallView(tester);
    final h = JournalHarness(conditions: const [condition], online: online);
    h.remote.readings = serverReadings();
    for (final e in outbox) {
      await h.local.enqueue(e);
    }
    await tester.pumpWidget(app(h.overrides, const ConditionReadingsScreen(conditionId: 'c1')));
    await tester.pumpAndSettle();
    return h;
  }

  JournalEntry outboxEntry() => JournalEntry(
        clientId: 'local-1',
        recordedAt: at(0, 0, 20),
        mood: 'bem',
        area: 'physical',
        items: [
          JournalItem(
            kind: JournalKeys.kindCondition,
            conditionId: 'c1',
            readings: [
              ConditionReading.bloodPressure(measuredAt: at(0, 0, 15), systolic: 127, diastolic: 84),
            ],
          ),
        ],
      );

  group('raw text of a reading', () {
    test('values and units only, as typed', () {
      expect(
        readingValueText(pt, 'pt',
            ConditionReading.bloodPressure(measuredAt: at(0, 8), systolic: 120, diastolic: 80, pulse: 72)),
        '120/80 mmHg · pulso 72 bpm',
      );
      expect(
        readingValueText(pt, 'pt',
            ConditionReading.glucose(measuredAt: at(0, 8), mgdl: 98, moment: JournalKeys.momentJejum)),
        '98 mg/dL · Jejum',
      );
      expect(readingValueText(pt, 'pt', ConditionReading.weight(measuredAt: at(0, 8), kg: 72.5)), '72,5 kg');
      expect(readingValueText(pt, 'en', ConditionReading.weight(measuredAt: at(0, 8), kg: 72.25)), '72.25 kg');
      expect(
        readingTooltipText(pt, 'pt',
            ConditionReading.bloodPressure(measuredAt: DateTime(2026, 11, 1, 8, 30), systolic: 120, diastolic: 80)),
        '120/80 mmHg · 01/11 08:30',
      );
    });

    test('a day with no reading breaks the line', () {
      final runs = readingRuns([
        ConditionReading.weight(measuredAt: at(0, 8), kg: 70),
        ConditionReading.weight(measuredAt: at(1, 8), kg: 71),
        ConditionReading.weight(measuredAt: at(1, 20), kg: 71.2),
        ConditionReading.weight(measuredAt: at(4, 8), kg: 72),
      ]);
      expect(runs.map((r) => r.length), [1, 3]);
      // Oldest first inside a run.
      expect(runs.last.first.kg, 71);
    });
  });

  testWidgets('lists readings by day, newest first, with name and profile', (tester) async {
    final h = await pumpScreen(tester);
    expect(find.byKey(const Key('chronic_history_name')), findsOneWidget);
    expect(find.text('Hipertensão'), findsOneWidget);
    expect(find.text(pt.chronicHistoryProfile('Ana')), findsOneWidget);
    expect(h.remote.readingRequests.single['conditionId'], 'c1');

    final dayTitle = find.textContaining(RegExp('^Hoje, '));
    expect(dayTitle, findsOneWidget);
    expect(find.textContaining(RegExp('^Ontem, ')), findsOneWidget);
    expect(find.text('120/80 mmHg · pulso 72 bpm'), findsOneWidget);
    expect(find.text('131/86 mmHg'), findsOneWidget);
    expect(find.text('118/79 mmHg'), findsOneWidget);
    expect(find.text('72,5 kg'), findsOneWidget);
    // Another condition's reading never shows.
    expect(find.text('140/90 mmHg'), findsNothing);
    // Newest first inside a day.
    expect(tester.getTopLeft(find.text('120/80 mmHg · pulso 72 bpm')).dy,
        lessThan(tester.getTopLeft(find.text('131/86 mmHg')).dy));
  });

  testWidgets('7 / 30 / 90 days filter the period', (tester) async {
    await pumpScreen(tester);
    // Default 30 days.
    expect(find.text('125/82 mmHg'), findsOneWidget);
    await tapKey(tester, 'chronic_history_range_7');
    expect(find.text('125/82 mmHg'), findsNothing);
    expect(find.text('120/80 mmHg · pulso 72 bpm'), findsOneWidget);
    await tapKey(tester, 'chronic_history_range_90');
    expect(find.text('125/82 mmHg'), findsOneWidget);
  });

  testWidgets('one raw chart per kind: discrete dots, no smoothing, bands or value colours', (tester) async {
    await pumpScreen(tester);
    expect(find.byKey(const Key('chronic_history_chart_blood_pressure')), findsOneWidget);
    expect(find.byKey(const Key('chronic_history_chart_weight')), findsOneWidget);
    expect(find.byKey(const Key('chronic_history_chart_glucose')), findsNothing);
    expect(find.text(pt.chronicHistoryCount(4)), findsOneWidget);
    expect(find.text(pt.chronicHistoryCount(1)), findsOneWidget);

    final bpChart = tester.widget<LineChart>(find.descendant(
      of: find.byKey(const Key('chronic_history_chart_blood_pressure')),
      matching: find.byType(LineChart),
    ));
    final data = bpChart.data;
    final bars = data.lineBarsData;
    // Runs: day 20 alone, then yesterday+today; two lines each.
    expect(bars, hasLength(4));
    final spots = bars.expand((b) => b.spots).toList();
    expect(spots, hasLength(8)); // 4 readings x systolic/diastolic
    expect(spots.map((s) => s.y), containsAll([120.0, 80.0, 131.0, 86.0, 118.0, 79.0, 125.0, 82.0]));
    for (final b in bars) {
      expect(b.isCurved, isFalse);
      expect(b.belowBarData.show, isFalse);
      expect(b.aboveBarData.show, isFalse);
      expect({readingsLineTeal, readingsLineSlate}, contains(b.color));
    }
    expect(data.extraLinesData.horizontalLines, isEmpty);
    expect(data.rangeAnnotations.horizontalRangeAnnotations, isEmpty);
    expect(data.betweenBarsData, isEmpty);
    expect(data.clipData.right, isFalse, reason: "dots on edge are not clipped");

    // Nothing that reads as a judgement or a direction.
    expect(
      find.textContaining(RegExp(r'normal|alt[ao]\b|baix[ao]\b|m[ée]dia|tend[eê]ncia|ideal|meta|subiu|caiu|high|low|average|trend',
          caseSensitive: false)),
      findsNothing,
    );
  });

  testWidgets('axis ends sit on the grid, so edge labels never overlap grid labels', (tester) async {
    // Live e2e (16-04-05): 120/80 alone gave labels 74 and 78 on top of each
    // other, because the ends of the axis were not multiples of the interval.
    final start = DateTime(today.year, today.month, today.day - 29);
    for (final readings in [
      [ConditionReading.bloodPressure(measuredAt: at(0, 8), systolic: 120, diastolic: 80)],
      [ConditionReading.bloodPressure(measuredAt: at(0, 8), systolic: 130, diastolic: 85)],
      [ConditionReading.glucose(measuredAt: at(0, 8), mgdl: 98, moment: JournalKeys.momentJejum)],
      [ConditionReading.weight(measuredAt: at(0, 8), kg: 72.5)],
    ]) {
      final kind = readings.single.kind;
      await tester.pumpWidget(app(const [], Scaffold(
        body: ReadingsChart(kind: kind, readings: readings, start: start, days: 30),
      )));
      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      final interval = data.titlesData.leftTitles.sideTitles.interval!;
      expect(data.minY % interval, 0, reason: '$kind minY ${data.minY} / $interval');
      expect(data.maxY % interval, 0, reason: '$kind maxY ${data.maxY} / $interval');
      expect(data.gridData.horizontalInterval, interval);
      final values = data.lineBarsData.expand((b) => b.spots).map((s) => s.y);
      expect(values.every((v) => v > data.minY && v < data.maxY), isTrue,
          reason: 'every dot stays inside the axis');
    }
  });

  testWidgets('readings still in the outbox show, marked as waiting to sync', (tester) async {
    await pumpScreen(tester, outbox: [outboxEntry()]);
    expect(find.text('127/84 mmHg'), findsOneWidget);
    expect(find.byTooltip(pt.chronicHistoryPending), findsOneWidget);
    expect(find.byKey(const Key('chronic_history_offline')), findsNothing);
  });

  testWidgets('offline: device readings only, with a note', (tester) async {
    await pumpScreen(tester, online: false, outbox: [outboxEntry()]);
    expect(find.byKey(const Key('chronic_history_offline')), findsOneWidget);
    expect(find.text('127/84 mmHg'), findsOneWidget);
    expect(find.text('120/80 mmHg · pulso 72 bpm'), findsNothing);
  });

  testWidgets('empty period says so', (tester) async {
    tallView(tester);
    final h = JournalHarness(conditions: const [condition]);
    await tester.pumpWidget(app(h.overrides, const ConditionReadingsScreen(conditionId: 'c1')));
    await tester.pumpAndSettle();
    expect(find.text(pt.chronicHistoryEmpty(30)), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  group('route ${RoutePaths.conditionReadings}', () {
    Future<GoRouter> pumpRoute(WidgetTester tester, {required bool premium}) async {
      tallView(tester);
      final h = JournalHarness(conditions: const [condition]);
      h.remote.readings = serverReadings();
      final router = createRouter(initialLocation: RoutePaths.conditionReadingsOf('c1'));
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...h.overrides,
          premiumProfilesEnabledProvider.overrideWithValue(premium),
          activeProfileControllerProvider.overrideWith(_Ana.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
          locale: const Locale('pt'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('Premium build opens the history', (tester) async {
      final router = await pumpRoute(tester, premium: true);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/conditions/c1/readings');
      expect(find.byType(ConditionReadingsScreen), findsOneWidget);
      expect(find.text('Hipertensão'), findsOneWidget);
    });

    testWidgets('Free build goes to the Premium promo', (tester) async {
      final router = await pumpRoute(tester, premium: false);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/premium-promo');
      expect(find.byType(ConditionReadingsScreen), findsNothing);
    });
  });

  group('summary', () {
    Future<void> pumpSummary(WidgetTester tester, {required bool premium}) async {
      tallView(tester);
      final h = JournalHarness(conditions: const [condition]);
      h.remote.created.add(JournalEntry(
        clientId: 'e1',
        recordedAt: at(1, 9, 5),
        mood: 'bem',
        area: 'physical',
        items: [
          JournalItem(
            kind: JournalKeys.kindCondition,
            conditionId: 'c1',
            readings: [
              ConditionReading.bloodPressure(measuredAt: at(1, 21), systolic: 130, diastolic: 85),
              ConditionReading.bloodPressure(measuredAt: at(1, 8, 10), systolic: 120, diastolic: 80, pulse: 72),
            ],
          ),
        ],
      ));
      await tester.pumpWidget(app([
        journalRemoteDataSourceProvider.overrideWithValue(h.remote),
        careApiProvider.overrideWithValue(FakeCareApi()),
        premiumProfilesEnabledProvider.overrideWithValue(premium),
      ], const SummaryScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('Premium: readings block lists raw values with date and time, oldest first', (tester) async {
      await pumpSummary(tester, premium: true);
      expect(find.byKey(const Key('summary_section_readings')), findsOneWidget);
      expect(find.text(pt.chronicHistorySummaryTitle), findsOneWidget);
      final first = find.textContaining(RegExp(r'^• Hipertensão · \d\d/\d\d/\d{4} 08:10 · 120/80 mmHg · pulso 72 bpm$'));
      final second = find.textContaining(RegExp(r'^• Hipertensão · \d\d/\d\d/\d{4} 21:00 · 130/85 mmHg$'));
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(tester.getTopLeft(first).dy, lessThan(tester.getTopLeft(second).dy));
      // Footer disclaimer stays.
      expect(find.text(pt.careSummaryFooter), findsOneWidget);
    });

    testWidgets('Free: no readings section', (tester) async {
      await pumpSummary(tester, premium: false);
      expect(find.byKey(const Key('summary_section_readings')), findsNothing);
      expect(find.text(pt.chronicHistorySummaryTitle), findsNothing);
      expect(find.textContaining('120/80 mmHg'), findsNothing);
    });
  });
}
