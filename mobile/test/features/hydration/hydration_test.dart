import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/hydration/domain/models/water_intake_log.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/features/hydration/presentation/widgets/water_consumption_chart.dart';
import 'package:dualis_mobile/features/hydration/presentation/widgets/water_intake_modal.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/home_hydration_card.dart';
import 'package:dualis_mobile/core/notifications/hydration_notification_service.dart';

class FakeHydrationController extends HydrationController {
  final HydrationState _initialState;
  FakeHydrationController(this._initialState);

  @override
  HydrationState build() {
    return _initialState;
  }

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
          id: 999,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HydrationSettings Domain Model', () {
    test('default settings values are correct', () {
      const settings = HydrationSettings();
      expect(settings.reminderEnabled, isTrue);
      expect(settings.trackingEnabled, isTrue);
      expect(settings.reminderSoundStyle, ReminderSoundStyle.whatsappChime);
      expect(settings.dailyTargetMl, 2000);
      expect(settings.scheduledHours, [8, 10, 12, 14, 16, 18, 20]);
    });

    test('ReminderSoundStyle fromId works correctly', () {
      expect(
        ReminderSoundStyle.fromId('phone_alarm'),
        ReminderSoundStyle.phoneAlarm,
      );
      expect(
        ReminderSoundStyle.fromId('whatsapp_chime'),
        ReminderSoundStyle.whatsappChime,
      );
      expect(
        ReminderSoundStyle.fromId('unknown'),
        ReminderSoundStyle.whatsappChime,
      );
    });

    test('toJson and fromJson work correctly', () {
      const settings = HydrationSettings(
        reminderEnabled: true,
        trackingEnabled: true,
        reminderSoundStyle: ReminderSoundStyle.phoneAlarm,
        dailyTargetMl: 2500,
        scheduledHours: [8, 10, 12, 14, 16, 18, 20],
      );

      final json = settings.toJson();
      final recovered = HydrationSettings.fromJson(json);

      expect(recovered.reminderEnabled, isTrue);
      expect(recovered.trackingEnabled, isTrue);
      expect(recovered.reminderSoundStyle, ReminderSoundStyle.phoneAlarm);
      expect(recovered.dailyTargetMl, 2500);
      expect(recovered.scheduledHours, [8, 10, 12, 14, 16, 18, 20]);
    });

    test('copyWith updates specified fields only', () {
      const original = HydrationSettings(
        reminderEnabled: false,
        trackingEnabled: false,
        dailyTargetMl: 2000,
      );

      final updated = original.copyWith(
        reminderEnabled: true,
        dailyTargetMl: 3000,
      );

      expect(updated.reminderEnabled, isTrue);
      expect(updated.trackingEnabled, isFalse);
      expect(updated.dailyTargetMl, 3000);
    });
  });

  group('WaterIntakeEntry Domain Model', () {
    test('creates entry with correct properties', () {
      final now = DateTime.now();
      final entry = WaterIntakeEntry(
        id: 1,
        userId: 'user-abc',
        amountMl: 300,
        timestamp: now,
        source: 'manual',
      );

      expect(entry.id, 1);
      expect(entry.userId, 'user-abc');
      expect(entry.amountMl, 300);
      expect(entry.timestamp, now);
      expect(entry.source, 'manual');
    });

    test('toJson and fromJson preserves data', () {
      final now = DateTime(2026, 9, 18, 14, 0);
      final entry = WaterIntakeEntry(
        id: 100,
        userId: 'user-xyz',
        amountMl: 250,
        timestamp: now,
        source: 'notification_modal',
      );

      final json = entry.toJson();
      final recovered = WaterIntakeEntry.fromJson(json);

      expect(recovered.id, 100);
      expect(recovered.amountMl, 250);
      expect(recovered.source, 'notification_modal');
      expect(recovered.timestamp, now);
    });
  });

  group('HydrationState Class', () {
    test('computes progress metrics correctly', () {
      const state = HydrationState(
        todayTotalMl: 1000,
        settings: HydrationSettings(dailyTargetMl: 2000),
      );

      expect(state.dailyTargetMl, 2000);
      expect(state.progressRatio, 0.5);
      expect(state.progressPercent, 50);
      expect(state.isGoalReached, isFalse);
    });

    test('isGoalReached is true when target achieved', () {
      const state = HydrationState(
        todayTotalMl: 2200,
        settings: HydrationSettings(dailyTargetMl: 2000),
      );

      expect(state.progressPercent, 110);
      expect(state.isGoalReached, isTrue);
    });

    test('progressRatio clamps at 1.5', () {
      const state = HydrationState(
        todayTotalMl: 4000,
        settings: HydrationSettings(dailyTargetMl: 2000),
      );

      expect(state.progressRatio, 1.5);
    });
  });

  group('WaterConsumptionChart Widget', () {
    testWidgets('renders empty state when map is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaterConsumptionChart(
              last7DaysTotals: {},
              dailyTargetMl: 2000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum registro de consumo de água ainda.'),
        findsOneWidget,
      );
    });

    testWidgets('renders 7-day bars and target benchmark', (tester) async {
      final now = DateTime.now();
      final last7Days = {
        DateTime(now.year, now.month, now.day - 3): 1500,
        DateTime(now.year, now.month, now.day - 2): 2100,
        DateTime(now.year, now.month, now.day - 1): 1800,
        DateTime(now.year, now.month, now.day): 2400,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WaterConsumptionChart(
                last7DaysTotals: last7Days,
                dailyTargetMl: 2000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Consumo de Água (7 Dias)'), findsOneWidget);
      expect(find.text('Meta diária: 2000 ml'), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Média 7 dias'), findsOneWidget);
      expect(find.text('Meta'), findsOneWidget);
    });
  });

  group('WaterIntakeModal Widget', () {
    testWidgets('displays intake chips and button', (tester) async {
      const testState = HydrationState(
        todayTotalMl: 500,
        settings: HydrationSettings(dailyTargetMl: 2000),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationControllerProvider.overrideWith(
              () => FakeHydrationController(testState),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => WaterIntakeModal.show(context),
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Hora de se hidratar 💧'), findsOneWidget);
      expect(find.text('Meta do dia: 2000 ml'), findsOneWidget);
      expect(find.text('500 ml (25%)'), findsOneWidget);
      expect(find.text('150 ml'), findsOneWidget);
      expect(find.text('200 ml'), findsOneWidget);
      expect(find.text('250 ml'), findsOneWidget);
      expect(find.text('300 ml'), findsOneWidget);
      expect(find.text('500 ml'), findsOneWidget);
      expect(find.text('Registrar Consumo'), findsOneWidget);
    });

    testWidgets('tapping preset chip updates selection and logs water', (tester) async {
      const testState = HydrationState(
        todayTotalMl: 500,
        settings: HydrationSettings(dailyTargetMl: 2000),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationControllerProvider.overrideWith(
              () => FakeHydrationController(testState),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => WaterIntakeModal.show(context),
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Tap 500 ml chip
      await tester.tap(find.byKey(const Key('water_preset_500ml')));
      await tester.pumpAndSettle();

      // Tap confirm button
      await tester.tap(find.byKey(const Key('confirm_water_intake_button')));
      await tester.pumpAndSettle();

      // Success SnackBar is shown
      expect(find.text('💧 +500 ml registrados com sucesso!'), findsOneWidget);
    });
  });

  group('HomeHydrationCard Widget', () {
    testWidgets('renders card on home dashboard with action', (tester) async {
      const testState = HydrationState(
        todayTotalMl: 750,
        settings: HydrationSettings(dailyTargetMl: 2000),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationControllerProvider.overrideWith(
              () => FakeHydrationController(testState),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HomeHydrationCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Controle de Hidratação'), findsOneWidget);
      expect(find.text('750 de 2000 ml atingidos hoje (38%)'), findsOneWidget);
      expect(find.text('+250 ml (Copo)'), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_rounded), findsWidgets);
    });
  });

  group('HydrationNotificationService', () {
    test('canScheduleExactAlarms returns false safely when plugin is uninitialized', () async {
      final service = HydrationNotificationService();
      final result = await service.canScheduleExactAlarms();
      expect(result, isFalse);
    });

    test('scheduleHydrationReminders when disabled does not throw', () async {
      final service = HydrationNotificationService();
      const settings = HydrationSettings(reminderEnabled: false);
      // Should complete normally without throwing
      await expectLater(
        service.scheduleHydrationReminders(settings),
        completes,
      );
    });
  });
}
