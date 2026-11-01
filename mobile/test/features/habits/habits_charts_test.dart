import 'package:dualis_mobile/features/habits/domain/models/habit_day.dart';
import 'package:dualis_mobile/features/journal_insights/presentation/widgets/habits_charts.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createChartsTestWidget({
  required List<HabitDay> habits,
  required int days,
  required DateTime today,
  required DateTime start,
  bool showPeriod = false,
}) {
  return MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('pt'),
      Locale('en'),
      Locale('es'),
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        child: HabitsChartsSection(
          habits: habits,
          days: days,
          today: today,
          start: start,
          showPeriod: showPeriod,
        ),
      ),
    ),
  );
}

void main() {
  group('HabitsChartsSection widget test', () {
    final today = DateTime(2026, 10, 31);
    final start = DateTime(2026, 10, 2); // 30-day window ending today

    testWidgets('renders sleep and movement charts with exact count texts',
        (tester) async {
      final habits = [
        const HabitDay(
          day: '2026-10-30',
          sleepQuality: HabitSleepQuality.mal,
          sleepHours: HabitSleepHours.menos5,
        ),
        const HabitDay(
          day: '2026-10-29',
          sleepQuality: HabitSleepQuality.mal,
          sleepHours: HabitSleepHours.menos5,
        ),
        const HabitDay(
          day: '2026-10-28',
          sleepQuality: HabitSleepQuality.bem,
          sleepHours: HabitSleepHours.hours7To8,
          moved: true,
          movementMinutes: HabitMovementMinutes.minutes30To60,
        ),
        const HabitDay(
          day: '2026-10-27',
          moved: true,
          movementMinutes: HabitMovementMinutes.ate15,
        ),
      ];

      await tester.pumpWidget(createChartsTestWidget(
        habits: habits,
        days: 30,
        today: today,
        start: start,
        showPeriod: false,
      ));
      await tester.pumpAndSettle();

      // Verify sleep chart and count text
      expect(find.byKey(const Key('habits_sleep_chart')), findsOneWidget);
      expect(
        find.text('Você dormiu mal em 2 dos últimos 30 dias'),
        findsOneWidget,
      );

      // Verify movement chart and count text
      expect(find.byKey(const Key('habits_movement_chart')), findsOneWidget);
      expect(
        find.text('Você se mexeu em 2 dias'),
        findsOneWidget,
      );

      // Period chart should NOT be rendered when showPeriod = false and 0 period days
      expect(find.byKey(const Key('habits_period_chart')), findsNothing);
    });

    testWidgets('renders period chart when showPeriod is true', (tester) async {
      final habits = [
        const HabitDay(
          day: '2026-10-15',
          period: true,
        ),
      ];

      await tester.pumpWidget(createChartsTestWidget(
        habits: habits,
        days: 30,
        today: today,
        start: start,
        showPeriod: true,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habits_period_chart')), findsOneWidget);
      expect(
        find.text('Dias com menstruação: 1'),
        findsOneWidget,
      );
    });
  });
}
