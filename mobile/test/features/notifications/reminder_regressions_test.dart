// Regression tests for debug session notif-agua-checkin (findings 1, 2, 3, 7).
//
// Written only against the services' pre-fix public API (plugin: constructor,
// schedule/cancel methods, onNotificationOpened) so that the same file
// demonstrates the bugs on the old code and guards the fix.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:dualis_mobile/core/notifications/daily_checkin_notification_service.dart';
import 'package:dualis_mobile/core/notifications/hydration_notification_service.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class FakeTZDateTime extends Fake implements tz.TZDateTime {}

/// Mock plugin that mimics the real platform layer: the plugin is one
/// instance and only the LAST `onDidReceiveNotificationResponse` passed to
/// `initialize()` is kept.
class PluginHarness {
  PluginHarness() {
    when(() => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
        )).thenAnswer((invocation) async {
      platformTapHandler = invocation
              .namedArguments[#onDidReceiveNotificationResponse]
          as void Function(NotificationResponse)?;
      return true;
    });
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
  void Function(NotificationResponse)? platformTapHandler;

  void tap(String payload) => platformTapHandler!(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      ));
}

bool _repeatsDaily(Map<Symbol, dynamic> call) =>
    call[#matchDateTimeComponents] == DateTimeComponents.time;

tz.TZDateTime _date(Map<Symbol, dynamic> call) =>
    call[#scheduledDate] as tz.TZDateTime;

/// Whether the platform would fire [call] later today. Both the Android and
/// iOS plugins compute a daily-repeating trigger's first fire from "now"
/// using only the time of day, ignoring the date passed in.
bool _firesToday(Map<Symbol, dynamic> call) {
  final date = _date(call);
  final now = tz.TZDateTime.now(date.location);
  if (_repeatsDaily(call)) {
    final todaySlot = tz.TZDateTime(
        date.location, now.year, now.month, now.day, date.hour, date.minute);
    return todaySlot.isAfter(now);
  }
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

/// Whether [call] fires tomorrow at [hour]:00.
bool _firesTomorrowAt(Map<Symbol, dynamic> call, int hour) {
  final date = _date(call);
  if (date.hour != hour || date.minute != 0) return false;
  if (_repeatsDaily(call)) return true;
  final now = tz.TZDateTime.now(date.location);
  final tomorrow =
      tz.TZDateTime(date.location, now.year, now.month, now.day + 1);
  return date.year == tomorrow.year &&
      date.month == tomorrow.month &&
      date.day == tomorrow.day;
}

class _FakeSecureStorage extends Fake implements SecureStorageService {
  int clearAllCalls = 0;

  @override
  Future<String?> getUserId() async => null;
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<Map<String, dynamic>?> getDailyCheckIn(String userId) async => null;
  @override
  Future<void> saveDailyCheckIn({
    required String userId,
    required Map<String, dynamic> data,
  }) async {}
  @override
  Future<void> clearDailyCheckIn(String userId) async {}
  @override
  Future<Map<String, dynamic>?> getTodayTriageOutcome(String userId) async =>
      null;
  @override
  Future<void> clearTodayTriageOutcome(String userId) async {}
  @override
  Future<void> clearAll() async {
    clearAllCalls++;
  }
}

class _EmptyHistoryDataSource extends TriageHistoryRemoteDataSource {
  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async =>
      const TriageHistoryResponse(
        logs: [],
        physicalSummary: {},
        emotionalSummary: [],
        criticalRecurrences: [],
      );
}

/// Records what the controller asks of the check-in reminder service.
class _RecordingCheckinService extends Fake
    implements DailyCheckinNotificationService {
  final List<bool> scheduledWithCompleted = <bool>[];
  int bareCancelCalls = 0;

  @override
  Future<void> scheduleDailyCheckInReminders({
    required bool isCompletedToday,
  }) async {
    scheduledWithCompleted.add(isCompletedToday);
  }

  @override
  Future<void> cancelAllCheckInReminders() async => bareCancelCalls++;

  void clear() {
    scheduledWithCompleted.clear();
    bareCancelCalls = 0;
  }
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

  group('Finding 1: hydration never wipes the check-in reminders', () {
    test('scheduleHydrationReminders never calls cancelAll() nor cancels 2000+ IDs',
        () async {
      final harness = PluginHarness();
      final hydration = HydrationNotificationService(plugin: harness.plugin);

      await hydration.scheduleHydrationReminders(const HydrationSettings());

      expect(harness.cancelAllCalls, 0,
          reason: 'cancelAll() also cancels the check-in reminders (2000+hour)');
      expect(harness.cancelledIds.where((id) => id >= 2000 && id < 9999),
          isEmpty);
      // Its own previous slots are still cleared before rescheduling.
      for (final hour in const HydrationSettings().scheduledHours) {
        expect(harness.cancelledIds, contains(1000 + hour));
      }
      expect(harness.scheduled, hasLength(7));
    });

    test('cancelAllReminders (reminders disabled) only cancels hydration IDs',
        () async {
      final harness = PluginHarness();
      final hydration = HydrationNotificationService(plugin: harness.plugin);

      await hydration.cancelAllReminders();

      expect(harness.cancelAllCalls, 0);
      expect(harness.cancelledIds, isNotEmpty);
      expect(
        harness.cancelledIds.every((id) => (id >= 1000 && id < 1024) || id == 9999),
        isTrue,
        reason: 'cancelled: ${harness.cancelledIds}',
      );
      for (var hour = 0; hour < 24; hour++) {
        expect(harness.cancelledIds, contains(1000 + hour));
      }
      expect(harness.cancelledIds, contains(9999));
    });
  });

  group('Finding 2: completing today keeps the following days reminded', () {
    test('scheduleDailyCheckInReminders(isCompletedToday: true): nothing fires today, every slot fires tomorrow',
        () async {
      final harness = PluginHarness();
      final checkin = DailyCheckinNotificationService(plugin: harness.plugin);

      await checkin.scheduleDailyCheckInReminders(isCompletedToday: true);

      expect(harness.scheduled.where(_firesToday), isEmpty,
          reason: 'today is already checked in');
      for (final hour in DailyCheckinNotificationService.reminderHours) {
        expect(
          harness.scheduled.any((call) => _firesTomorrowAt(call, hour)),
          isTrue,
          reason: 'the $hour:00 reminder must still fire tomorrow',
        );
      }
      expect(
        harness.scheduled.every((c) => c[#payload] == 'open_checkin'),
        isTrue,
      );
    });

    group('controller completion paths re-arm reminders instead of a bare cancel', () {
      late _RecordingCheckinService recorder;
      late ProviderContainer container;

      setUp(() async {
        recorder = _RecordingCheckinService();
        container = ProviderContainer(overrides: [
          dailyCheckinNotificationServiceProvider.overrideWithValue(recorder),
          secureStorageServiceProvider.overrideWithValue(_FakeSecureStorage()),
          triageHistoryDataSourceProvider
              .overrideWithValue(_EmptyHistoryDataSource()),
        ]);
        container.read(triggerCheckInProvider);
        // Let build()'s loadTodayCheckIn settle, then observe only the
        // completion call.
        await pumpEventQueue();
        recorder.clear();
      });

      tearDown(() => container.dispose());

      Future<void> expectRearmedFromTomorrow() async {
        await pumpEventQueue();
        expect(recorder.bareCancelCalls, 0,
            reason: 'a bare cancel silences every future day');
        expect(recorder.scheduledWithCompleted, contains(true));
      }

      test('completeStage', () async {
        container.read(triggerCheckInProvider.notifier).completeStage(
              vertical: TriageVertical.psicoEmocional,
              summary: 'Bem',
            );
        await expectRearmedFromTomorrow();
      });

      test('markCompletedToday', () async {
        container.read(triggerCheckInProvider.notifier).markCompletedToday();
        await expectRearmedFromTomorrow();
      });

      test('markCompletedWithOutcome', () async {
        container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(
              TriageOutcome(
                id: 'o-1',
                vertical: 'physical',
                intensityScore: 2,
                careDisposition: CareDisposition.selfCare,
                primaryCategory: 'cabeca_pescoco',
                categoryLabel: 'Cabeça e Pescoço',
                somaticMapping: 'Cefaleia',
                organicPrimacyApplied: false,
                recommendedArticles: const [],
                recordedAt: DateTime.now(),
              ),
            );
        await expectRearmedFromTomorrow();
      });
    });
  });

  group('Finding 3: one tap handler for both reminder kinds', () {
    test('plugin.initialize() runs once even when both services initialize',
        () async {
      final harness = PluginHarness();
      final hydration = HydrationNotificationService(plugin: harness.plugin);
      final checkin = DailyCheckinNotificationService(plugin: harness.plugin);

      await Future.wait([hydration.initialize(), checkin.initialize()]);
      await hydration.initialize();
      await checkin.initialize();

      verify(() => harness.plugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).called(1);
    });

    test('water and check-in taps both reach their own consumers', () async {
      final harness = PluginHarness();
      final hydration = HydrationNotificationService(plugin: harness.plugin);
      final checkin = DailyCheckinNotificationService(plugin: harness.plugin);

      final waterTaps = <String>[];
      final checkinTaps = <String>[];
      final waterSub = hydration.onNotificationOpened.listen(waterTaps.add);
      final checkinSub = checkin.onNotificationOpened.listen(checkinTaps.add);
      addTearDown(waterSub.cancel);
      addTearDown(checkinSub.cancel);

      // Hydration first, check-in last: the order that used to leave only
      // the check-in callback registered on the platform.
      await hydration.initialize();
      await checkin.initialize();

      harness.tap('open_water_modal');
      harness.tap('open_checkin');
      await pumpEventQueue();

      expect(waterTaps, ['open_water_modal']);
      expect(checkinTaps, ['open_checkin']);
    });
  });

  group('Finding 7: logout stops reminders', () {
    test('AuthController.logout cancels hydration and check-in reminders',
        () async {
      final harness = PluginHarness();
      final storage = _FakeSecureStorage();
      final container = ProviderContainer(overrides: [
        secureStorageServiceProvider.overrideWithValue(storage),
        hydrationNotificationServiceProvider.overrideWithValue(
            HydrationNotificationService(plugin: harness.plugin)),
        dailyCheckinNotificationServiceProvider.overrideWithValue(
            DailyCheckinNotificationService(plugin: harness.plugin)),
      ]);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).logout();

      expect(storage.clearAllCalls, 1);
      final cancelled = harness.cancelledIds.toSet();
      for (final hour in const HydrationSettings().scheduledHours) {
        expect(cancelled, contains(1000 + hour),
            reason: 'water reminder $hour:00 kept firing after logout');
      }
      for (final hour in DailyCheckinNotificationService.reminderHours) {
        expect(cancelled, contains(2000 + hour),
            reason: 'check-in reminder $hour:00 kept firing after logout');
      }
    });
  });
}
