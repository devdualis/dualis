import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:dualis_mobile/core/notifications/hydration_notification_service.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/hydration/data/hydration_repository.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/hydration/domain/models/water_intake_log.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class FakeTZDateTime extends Fake implements tz.TZDateTime {}

class PluginHarness {
  PluginHarness() {
    when(() => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
        )).thenAnswer((_) async => true);
    when(() => plugin.getNotificationAppLaunchDetails())
        .thenAnswer((_) async => null);
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((invocation) async {
      cancelledIds.add(invocation.namedArguments[#id] as int);
    });
    when(() => plugin.cancelAll()).thenAnswer((_) async {
      cancelAllCalls++;
    });
    when(() => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        )).thenAnswer((invocation) async {
      scheduled.add(invocation.namedArguments);
    });
  }

  final MockFlutterLocalNotificationsPlugin plugin =
      MockFlutterLocalNotificationsPlugin();
  final List<int> cancelledIds = <int>[];
  final List<Map<Symbol, dynamic>> scheduled = <Map<Symbol, dynamic>>[];
  int cancelAllCalls = 0;
}

bool _repeatsDaily(Map<Symbol, dynamic> call) =>
    call[#matchDateTimeComponents] == DateTimeComponents.time;

tz.TZDateTime _date(Map<Symbol, dynamic> call) =>
    call[#scheduledDate] as tz.TZDateTime;

bool _firesToday(Map<Symbol, dynamic> call, tz.TZDateTime now) {
  final date = _date(call);
  if (_repeatsDaily(call)) {
    final todaySlot = tz.TZDateTime(
        date.location, now.year, now.month, now.day, date.hour, date.minute);
    return todaySlot.isAfter(now);
  }
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

bool _firesTomorrowAt(Map<Symbol, dynamic> call, int hour, tz.TZDateTime now) {
  final date = _date(call);
  if (date.hour != hour || date.minute != 0) return false;
  if (_repeatsDaily(call)) return true;
  final tomorrow =
      tz.TZDateTime(date.location, now.year, now.month, now.day + 1);
  return date.year == tomorrow.year &&
      date.month == tomorrow.month &&
      date.day == tomorrow.day;
}

class FakeHydrationRepository implements HydrationRepository {
  HydrationSettings settings = const HydrationSettings(
    dailyTargetMl: 2000,
    reminderEnabled: true,
    scheduledHours: [8, 10, 12, 14, 16, 18, 20],
  );
  List<WaterIntakeEntry> logs = [];
  int _nextId = 1;

  @override
  Future<HydrationSettings> getSettings() async => settings;

  @override
  Future<void> saveSettings(HydrationSettings newSettings) async {
    settings = newSettings;
  }

  @override
  Future<List<WaterIntakeEntry>> getLogsForDay({
    required String userId,
    required DateTime day,
  }) async =>
      List.unmodifiable(logs);

  @override
  Future<Map<DateTime, int>> getLast7DaysTotals({
    required String userId,
    DateTime? referenceDate,
  }) async =>
      {};

  @override
  Future<void> deleteLog(int id) async {
    logs.removeWhere((l) => l.id == id);
  }

  @override
  Future<void> deleteRemoteLog(String remoteId) async {}

  @override
  Future<int> getTodayTotalMl({required String userId}) async =>
      logs.fold<int>(0, (sum, l) => sum + l.amountMl);

  @override
  Future<WaterIntakeEntry> logWaterIntake({
    required String userId,
    required int amountMl,
    String source = 'manual',
    DateTime? timestamp,
  }) async {
    final entry = WaterIntakeEntry(
      id: _nextId++,
      userId: userId,
      amountMl: amountMl,
      timestamp: timestamp ?? DateTime.now(),
      source: source,
    );
    logs.add(entry);
    return entry;
  }
}

class RecordingHydrationService extends Fake
    implements HydrationNotificationService {
  final List<bool> scheduledWithGoalReached = <bool>[];
  int cancelAllCalls = 0;

  @override
  Future<void> scheduleHydrationReminders(
    HydrationSettings settings, {
    bool isGoalReached = false,
  }) async {
    scheduledWithGoalReached.add(isGoalReached);
  }

  @override
  Future<void> cancelAllReminders() async {
    cancelAllCalls++;
  }

  void clear() {
    scheduledWithGoalReached.clear();
    cancelAllCalls = 0;
  }
}

class SignedInAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        isAuthenticated: true,
        user: UserProfile(
          id: 'user-hydration-1',
          email: 'water@test.com',
          name: 'Water User',
          gender: Gender.outro,
        ),
      );
}

class FakeSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getUserId() async => 'user-hydration-1';
  @override
  Future<String?> getAccessToken() async => 'token-123';
  @override
  Future<void> clearAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(FakeInitializationSettings());
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(DateTimeComponents.time);
  });

  group('HydrationNotificationService goal reached vs pending behavior', () {
    test(
        'when isGoalReached: true at 11:30, nothing fires today and every slot fires tomorrow',
        () async {
      final harness = PluginHarness();
      final now = tz.TZDateTime(tz.local, 2026, 9, 27, 11, 30);
      final service = HydrationNotificationService(
        plugin: harness.plugin,
        clock: () => now,
      );

      const settings = HydrationSettings(
        reminderEnabled: true,
        scheduledHours: [8, 10, 12, 14, 16, 18, 20],
      );

      await service.scheduleHydrationReminders(settings, isGoalReached: true);

      // Verify that NO notification fires today
      expect(
        harness.scheduled.where((c) => _firesToday(c, now)),
        isEmpty,
        reason: 'Hydration goal is reached, so no reminders should fire today',
      );

      // Verify that all 7 slots fire tomorrow
      for (final hour in settings.scheduledHours) {
        expect(
          harness.scheduled.any((c) => _firesTomorrowAt(c, hour, now)),
          isTrue,
          reason: 'Slot $hour:00 must fire tomorrow',
        );
      }
    });

    test(
        'when isGoalReached: false at 11:30, upcoming slots today WILL fire today',
        () async {
      final harness = PluginHarness();
      final now = tz.TZDateTime(tz.local, 2026, 9, 27, 11, 30);
      final service = HydrationNotificationService(
        plugin: harness.plugin,
        clock: () => now,
      );

      const settings = HydrationSettings(
        reminderEnabled: true,
        scheduledHours: [8, 10, 12, 14, 16, 18, 20],
      );

      await service.scheduleHydrationReminders(settings, isGoalReached: false);

      // Upcoming slots (12, 14, 16, 18, 20) must fire today
      final firingToday =
          harness.scheduled.where((c) => _firesToday(c, now)).toList();
      expect(firingToday.length, 5);

      final hoursToday =
          firingToday.map((c) => (_date(c)).hour).toList()..sort();
      expect(hoursToday, [12, 14, 16, 18, 20]);
    });
  });

  group('HydrationController goal completion and deletion cycle', () {
    late FakeHydrationRepository repository;
    late RecordingHydrationService recorder;
    late ProviderContainer container;

    setUp(() async {
      repository = FakeHydrationRepository();
      recorder = RecordingHydrationService();
      container = ProviderContainer(
        overrides: [
          hydrationRepositoryProvider.overrideWithValue(repository),
          hydrationNotificationServiceProvider.overrideWithValue(recorder),
          authControllerProvider.overrideWith(SignedInAuthController.new),
          secureStorageServiceProvider.overrideWithValue(FakeSecureStorage()),
        ],
      );

      // Listen to keep provider alive
      container.listen(hydrationControllerProvider, (_, __) {});
      // Allow initial loadData to complete
      await pumpEventQueue();
      recorder.clear();
    });

    tearDown(() {
      container.dispose();
    });

    test(
        'completing 2000 ml silences notifications; deleting logs restores them',
        () async {
      final controller =
          container.read(hydrationControllerProvider.notifier);

      // Initially below target: 0 / 2000 ml
      expect(container.read(hydrationControllerProvider).todayTotalMl, 0);
      expect(container.read(hydrationControllerProvider).isGoalReached, isFalse);

      // Step 1: Log 1500 ml -> still below 2000 ml
      await controller.logWater(amountMl: 1500);
      await pumpEventQueue();
      expect(container.read(hydrationControllerProvider).todayTotalMl, 1500);
      expect(container.read(hydrationControllerProvider).isGoalReached, isFalse);
      expect(recorder.scheduledWithGoalReached, isEmpty,
          reason: 'Did not transition from unreached to reached, no new schedule');

      // Step 2: Log 500 ml -> reaches 2000 ml (goal reached!)
      await controller.logWater(amountMl: 500);
      await pumpEventQueue();
      expect(container.read(hydrationControllerProvider).todayTotalMl, 2000);
      expect(container.read(hydrationControllerProvider).isGoalReached, isTrue);
      expect(recorder.scheduledWithGoalReached.last, isTrue,
          reason: 'Reaching 2000 ml must schedule with isGoalReached: true');

      recorder.clear();

      // Step 3: User deletes the 500 ml glass -> total drops to 1500 ml (< 2000 ml)
      final logToDelete = repository.logs.firstWhere((l) => l.amountMl == 500);
      await controller.deleteLog(logToDelete.id!);
      await pumpEventQueue();

      expect(container.read(hydrationControllerProvider).todayTotalMl, 1500);
      expect(container.read(hydrationControllerProvider).isGoalReached, isFalse);
      expect(recorder.scheduledWithGoalReached.last, isFalse,
          reason:
              'Dropping back below 2000 ml after deleting glasses must re-arm reminders with isGoalReached: false');

      recorder.clear();

      // Step 4: User drinks again and completes 600 ml -> reaches 2100 ml (>= 2000 ml)
      await controller.logWater(amountMl: 600);
      await pumpEventQueue();

      expect(container.read(hydrationControllerProvider).todayTotalMl, 2100);
      expect(container.read(hydrationControllerProvider).isGoalReached, isTrue);
      expect(recorder.scheduledWithGoalReached.last, isTrue,
          reason:
              'Completing the goal again after dropping below must silence notifications again (isGoalReached: true)');
    });
  });
}
