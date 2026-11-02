import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/hydration/domain/models/water_intake_log.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/features/hydration/presentation/widgets/water_intake_modal.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/home_hydration_card.dart';
import 'package:dualis_mobile/core/notifications/hydration_notification_service.dart';
import 'package:dualis_mobile/features/hydration/presentation/screens/hydration_dashboard_screen.dart';

class FakeHydrationController extends HydrationController {
  final HydrationState _initialState;
  final List<dynamic> deletedEntries = [];

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

  @override
  Future<bool> deleteLog(dynamic idOrEntry, {String? remoteId}) async {
    deletedEntries.add(idOrEntry);
    final toRemove = state.todayLogs.where((l) {
      if (idOrEntry is WaterIntakeEntry) {
        return (idOrEntry.id != null && l.id == idOrEntry.id) ||
            (idOrEntry.remoteId != null && l.remoteId == idOrEntry.remoteId) ||
            l == idOrEntry;
      } else if (idOrEntry is int) {
        return l.id == idOrEntry;
      } else if (idOrEntry is String) {
        return l.remoteId == idOrEntry;
      }
      return false;
    }).toList();

    final remaining = state.todayLogs.where((l) => !toRemove.contains(l)).toList();
    final newTotal = remaining.fold<int>(0, (sum, l) => sum + l.amountMl);
    state = state.copyWith(todayLogs: remaining, todayTotalMl: newTotal);
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
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home:  Scaffold(
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
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home:  Scaffold(
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

    testWidgets('displays loading state when state.isLoading is true', (tester) async {
      const testState = HydrationState(
        isLoading: true,
        todayTotalMl: 0,
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
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home:  Scaffold(
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
      await tester.pump();

      expect(find.text('Carregando...'), findsOneWidget);
      expect(find.text('0 ml (0%)'), findsNothing);
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
          child: MaterialApp(
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const  Scaffold(
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

  group('HydrationDashboardScreen Delete Logs', () {
    testWidgets('deletes remote-only log (id is null) when trash icon is tapped', (tester) async {
      final remoteEntry = WaterIntakeEntry(
        id: null,
        remoteId: 'remote-uuid-abc-123',
        userId: 'patient-1',
        amountMl: 300,
        timestamp: DateTime.now(),
        source: 'quick_chip',
      );

      final fakeController = FakeHydrationController(
        HydrationState(
          isLoading: false,
          todayTotalMl: 300,
          settings: const HydrationSettings(dailyTargetMl: 2000),
          last30DaysTotals: {},
          todayLogs: [remoteEntry],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationControllerProvider.overrideWith(() => fakeController),
          ],
          child: const MaterialApp(
            locale: Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HydrationDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('300 ml'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Tap the delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(fakeController.deletedEntries, contains(remoteEntry));
      expect(find.text('Nenhum copo de água registrado hoje ainda.'), findsOneWidget);
    });

    testWidgets('deletes local log (id is not null) when trash icon is tapped', (tester) async {
      final localEntry = WaterIntakeEntry(
        id: 77,
        remoteId: 'remote-uuid-xyz',
        userId: 'patient-1',
        amountMl: 250,
        timestamp: DateTime.now(),
        source: 'manual',
      );

      final fakeController = FakeHydrationController(
        HydrationState(
          isLoading: false,
          todayTotalMl: 250,
          settings: const HydrationSettings(dailyTargetMl: 2000),
          last30DaysTotals: {},
          todayLogs: [localEntry],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationControllerProvider.overrideWith(() => fakeController),
          ],
          child: const MaterialApp(
            locale: Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HydrationDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('250 ml'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Tap the delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(fakeController.deletedEntries, contains(localEntry));
      expect(find.text('Nenhum copo de água registrado hoje ainda.'), findsOneWidget);
    });
  });

  group('Hydration failure states', () {
    Widget dashboard(HydrationController controller) => ProviderScope(
          overrides: [hydrationControllerProvider.overrideWith(() => controller)],
          child: const MaterialApp(
            locale: Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HydrationDashboardScreen(),
          ),
        );

    testWidgets('load failure shows the reason and a retry that reloads', (tester) async {
      final controller = _FailingHydrationController(
        HydrationState(loadError: Exception('SocketException: Failed host lookup')),
      );
      await tester.pumpWidget(dashboard(controller));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar'), findsOneWidget);
      expect(
        find.text('Não foi possível conectar ao servidor. Verifique sua conexão com a internet.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('hydration_today_total')), findsNothing);

      await tester.tap(find.byKey(const Key('load_error_retry')));
      await tester.pumpAndSettle();
      expect(controller.loadCalls, 1);
    });

    testWidgets('quick add that fails says it was not saved', (tester) async {
      await tester.pumpWidget(dashboard(_FailingHydrationController(
        const HydrationState(settings: HydrationSettings(dailyTargetMl: 2000)),
      )));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('hydration_quick_add_200')));
      await tester.tap(find.byKey(const Key('hydration_quick_add_200')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save_failed_snack')), findsOneWidget);
      expect(find.text('Não foi possível salvar. Tente de novo.'), findsOneWidget);
      expect(find.byKey(const Key('hydration_logged_snack')), findsNothing);
    });

    testWidgets('modal that fails stays open and shows the error inside', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          hydrationControllerProvider.overrideWith(() => _FailingHydrationController(
                const HydrationState(settings: HydrationSettings(dailyTargetMl: 2000)),
              )),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => WaterIntakeModal.show(context),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('water_preset_500ml')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_water_intake_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('water_intake_save_failed')), findsOneWidget);
      expect(find.byKey(const Key('confirm_water_intake_button')), findsOneWidget);
      expect(find.text('💧 +500 ml registrados com sucesso!'), findsNothing);
    });

    testWidgets('reminder switch that fails to save says so and keeps its value', (tester) async {
      await tester.pumpWidget(dashboard(_FailingHydrationController(
        const HydrationState(settings: HydrationSettings(dailyTargetMl: 2000)),
      )));
      await tester.pumpAndSettle();

      final toggle = find.byKey(const Key('settings_water_reminder_switch'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save_failed_snack')), findsOneWidget);
      // Reminders start on; turning them off failed, so they stay on.
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    });

    testWidgets('home card speaks the app language', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          hydrationControllerProvider.overrideWith(() => _FailingHydrationController(
                const HydrationState(todayTotalMl: 500, settings: HydrationSettings(dailyTargetMl: 2000)),
              )),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HomeHydrationCard()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hydration'), findsOneWidget);
      expect(find.text('500 of 2000 ml today (25%)'), findsOneWidget);
      expect(find.text('Controle de Hidratação'), findsNothing);
    });
  });
}

/// Every save fails; loads only count calls.
class _FailingHydrationController extends HydrationController {
  _FailingHydrationController(this._initial);
  final HydrationState _initial;
  int loadCalls = 0;

  @override
  HydrationState build() => _initial;

  @override
  Future<void> loadData() async => loadCalls++;

  @override
  Future<bool> logWater({required int amountMl, String source = 'manual', DateTime? timestamp}) async =>
      false;

  @override
  Future<bool> deleteLog(dynamic idOrEntry, {String? remoteId}) async => false;

  @override
  Future<bool> toggleReminders(bool enabled) async => false;
}
