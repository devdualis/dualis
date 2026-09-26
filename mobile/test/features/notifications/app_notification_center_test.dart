// Debug session notif-agua-checkin: shared notification center (findings 3,
// 5), localized texts / timezone fallback (6), check-in scheduling edges (2),
// logout state reset (7) and exact-alarm requests (8).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:dualis_mobile/core/notifications/app_notification_center.dart';
import 'package:dualis_mobile/core/notifications/daily_checkin_notification_service.dart';
import 'package:dualis_mobile/core/notifications/hydration_notification_service.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/features/hydration/data/hydration_repository.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/hydration/domain/models/water_intake_log.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/features/hydration/presentation/widgets/water_intake_modal.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/locale_provider.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class FakeTZDateTime extends Fake implements tz.TZDateTime {}

const _zone = 'Europe/Madrid';

NotificationResponse _response(String payload) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: payload,
    );

class Harness {
  Harness({NotificationAppLaunchDetails? launchDetails}) {
    when(() => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
        )).thenAnswer((invocation) async {
      tapHandler = invocation.namedArguments[#onDidReceiveNotificationResponse]
          as void Function(NotificationResponse)?;
      return true;
    });
    when(() => plugin.getNotificationAppLaunchDetails())
        .thenAnswer((_) async => launchDetails);
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((invocation) async {
      cancelledIds.add(invocation.namedArguments[#id] as int);
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
    center = AppNotificationCenter(
      plugin: plugin,
      timezoneResolver: () async => _zone,
    );
  }

  final MockFlutterLocalNotificationsPlugin plugin =
      MockFlutterLocalNotificationsPlugin();
  late final AppNotificationCenter center;
  final List<int> cancelledIds = <int>[];
  final List<Map<Symbol, dynamic>> scheduled = <Map<Symbol, dynamic>>[];
  void Function(NotificationResponse)? tapHandler;

  Map<int, Map<Symbol, dynamic>> get scheduledById => {
        for (final call in scheduled) call[#id] as int: call,
      };
}

tz.TZDateTime _madrid(int y, int m, int d, int h, [int min = 0]) =>
    tz.TZDateTime(tz.getLocation(_zone), y, m, d, h, min);

class _FakeSecureStorage extends Fake implements SecureStorageService {
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
  Future<void> clearAll() async {}
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

class _SignedInAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        isAuthenticated: true,
        user: UserProfile(
          id: 'user-1',
          name: 'Ana',
          email: 'ana@example.com',
          gender: Gender.feminino,
        ),
      );
}

/// Only user-1 has water logs.
class _FakeHydrationRepository implements HydrationRepository {
  HydrationSettings settings = const HydrationSettings();

  @override
  Future<HydrationSettings> getSettings() async => settings;
  @override
  Future<void> saveSettings(HydrationSettings newSettings) async =>
      settings = newSettings;
  @override
  Future<List<WaterIntakeEntry>> getLogsForDay({
    required String userId,
    required DateTime day,
  }) async =>
      userId == 'user-1'
          ? [
              WaterIntakeEntry(
                id: 1,
                userId: userId,
                amountMl: 250,
                timestamp: DateTime.now(),
              ),
            ]
          : const [];
  @override
  Future<Map<DateTime, int>> getLast7DaysTotals({
    required String userId,
    DateTime? referenceDate,
  }) async =>
      const {};
  @override
  Future<void> deleteLog(int id) async {}
  @override
  Future<int> getTodayTotalMl({required String userId}) async => 0;
  @override
  Future<WaterIntakeEntry> logWaterIntake({
    required String userId,
    required int amountMl,
    String source = 'manual',
    DateTime? timestamp,
  }) =>
      throw UnimplementedError();
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

  group('Finding 3: AppNotificationCenter owns the plugin', () {
    test('concurrent initialize() calls share one plugin initialization', () async {
      final h = Harness();
      await Future.wait([h.center.initialize(), h.center.initialize()]);
      await h.center.initialize();
      verify(() => h.plugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).called(1);
      verify(() => h.plugin.getNotificationAppLaunchDetails()).called(1);
    });

    test('services built on the same plugin share one center', () {
      final plugin = MockFlutterLocalNotificationsPlugin();
      expect(identical(AppNotificationCenter.of(plugin),
          AppNotificationCenter.of(plugin)), isTrue);
    });

    test('initialization does not prompt for notification permissions', () async {
      final h = Harness();
      await h.center.initialize();
      final settings = verify(() => h.plugin.initialize(
            settings: captureAny(named: 'settings'),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).captured.single as InitializationSettings;
      expect(settings.iOS!.requestAlertPermission, isFalse);
      expect(settings.android, isNotNull);
    });
  });

  group('Finding 5: taps are never lost (cold start / early taps)', () {
    test('the tap that launched the app is delivered to a late subscriber, once',
        () async {
      final h = Harness(
        launchDetails: NotificationAppLaunchDetails(
          true,
          notificationResponse: _response(NotificationPayloads.openWaterModal),
        ),
      );
      final hydration = HydrationNotificationService(center: h.center);

      await h.center.initialize();
      expect(h.center.pendingPayloads, [NotificationPayloads.openWaterModal]);

      final first = <String>[];
      final sub = hydration.onNotificationOpened.listen(first.add);
      await pumpEventQueue();
      expect(first, [NotificationPayloads.openWaterModal]);
      await sub.cancel();

      final second = <String>[];
      final sub2 = hydration.onNotificationOpened.listen(second.add);
      await pumpEventQueue();
      expect(second, isEmpty, reason: 'a consumed tap must not replay');
      await sub2.cancel();
    });

    test('no launch payload when the app was not opened from a notification',
        () async {
      final h = Harness(
        launchDetails: NotificationAppLaunchDetails(
          false,
          notificationResponse: _response(NotificationPayloads.openWaterModal),
        ),
      );
      await h.center.initialize();
      expect(h.center.pendingPayloads, isEmpty);
    });

    test('a buffered check-in tap is not consumed by the water listener', () async {
      final h = Harness();
      final hydration = HydrationNotificationService(center: h.center);
      final checkin = DailyCheckinNotificationService(center: h.center);
      await h.center.initialize();

      h.tapHandler!(_response(NotificationPayloads.openCheckIn));

      final water = <String>[];
      final waterSub = hydration.onNotificationOpened.listen(water.add);
      await pumpEventQueue();
      expect(water, isEmpty);

      final checkins = <String>[];
      final checkinSub = checkin.onNotificationOpened.listen(checkins.add);
      await pumpEventQueue();
      expect(checkins, [NotificationPayloads.openCheckIn]);

      await waterSub.cancel();
      await checkinSub.cancel();
    });

    testWidgets('HomeScreen opens the water modal for a cold-start water tap',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final h = Harness(
        launchDetails: NotificationAppLaunchDetails(
          true,
          notificationResponse: _response(NotificationPayloads.openWaterModal),
        ),
      );
      await tester.runAsync(h.center.initialize);

      final router = GoRouter(
        initialLocation: RoutePaths.home,
        routes: [
          GoRoute(
            path: RoutePaths.home,
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appNotificationCenterProvider.overrideWithValue(h.center),
          hydrationControllerProvider.overrideWith(_IdleHydrationController.new),
          triageHistoryDataSourceProvider
              .overrideWithValue(_EmptyHistoryDataSource()),
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
      ));
      await tester.pumpAndSettle();

      expect(find.byType(WaterIntakeModal), findsOneWidget);
      expect(h.center.pendingPayloads, isEmpty);
    });
  });

  group('Finding 2: check-in scheduling around today\'s completion', () {
    Future<Harness> schedule({
      required tz.TZDateTime now,
      required bool completed,
    }) async {
      final h = Harness();
      final service = DailyCheckinNotificationService(
        center: h.center,
        clock: () => now,
        localeResolver: () => const Locale('en'),
      );
      await service.scheduleDailyCheckInReminders(isCompletedToday: completed);
      return h;
    }

    test('pending at 11:30: all 8 slots repeat daily (12:00..22:00 still fire today)',
        () async {
      final h = await schedule(now: _madrid(2026, 9, 25, 11, 30), completed: false);
      expect(h.scheduled, hasLength(8));
      for (final hour in DailyCheckinNotificationService.reminderHours) {
        final call = h.scheduledById[2000 + hour]!;
        expect(call[#matchDateTimeComponents], DateTimeComponents.time);
        expect((call[#scheduledDate] as tz.TZDateTime).hour, hour);
      }
    });

    test('completed at 11:30: past slots keep repeating, upcoming ones move to the next days',
        () async {
      final h = await schedule(now: _madrid(2026, 9, 25, 11, 30), completed: true);

      for (final hour in [8, 10]) {
        final call = h.scheduledById[2000 + hour]!;
        expect(call[#matchDateTimeComponents], DateTimeComponents.time);
        expect(call[#scheduledDate], _madrid(2026, 9, 26, hour));
      }
      for (final hour in [12, 14, 16, 18, 20, 22]) {
        expect(h.scheduledById.containsKey(2000 + hour), isFalse,
            reason: 'a daily trigger at $hour:00 would still fire today');
        for (var day = 1; day <= DailyCheckinNotificationService.completedLookaheadDays; day++) {
          final call = h.scheduledById[DailyCheckinNotificationService.oneShotId(day, hour)]!;
          expect(call[#matchDateTimeComponents], isNull);
          expect(call[#scheduledDate], _madrid(2026, 9, 25 + day, hour));
        }
      }
      expect(h.scheduled, hasLength(2 + 6 * 3));
    });

    test('completed at 07:00: every slot becomes one-shots for the next days', () async {
      final h = await schedule(now: _madrid(2026, 9, 25, 7), completed: true);
      expect(h.scheduled, hasLength(8 * 3));
      expect(h.scheduled.every((c) => c[#matchDateTimeComponents] == null), isTrue);
      expect(
        h.scheduled.every((c) => (c[#scheduledDate] as tz.TZDateTime)
            .isAfter(_madrid(2026, 9, 26, 0))),
        isTrue,
      );
    });

    test('completed at 23:00: every slot keeps repeating daily (next fire tomorrow)',
        () async {
      final h = await schedule(now: _madrid(2026, 9, 25, 23), completed: true);
      expect(h.scheduled, hasLength(8));
      expect(
        h.scheduled.every((c) => c[#matchDateTimeComponents] == DateTimeComponents.time),
        isTrue,
      );
    });

    test('overlapping reschedules do not interleave: the last request wins', () async {
      // loadTodayCheckIn (pending) can still be running when a completion
      // re-arms the reminders; interleaved cancel/schedule sequences could
      // leave a daily trigger for an upcoming slot armed after completion.
      final h = Harness();
      final active = <int, Map<Symbol, dynamic>>{};
      when(() => h.plugin.cancel(id: any(named: 'id'))).thenAnswer((inv) async {
        active.remove(inv.namedArguments[#id] as int);
      });
      when(() => h.plugin.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).thenAnswer((inv) async {
        active[inv.namedArguments[#id] as int] = inv.namedArguments;
      });
      final service = DailyCheckinNotificationService(
        center: h.center,
        clock: () => _madrid(2026, 9, 25, 11, 30),
      );

      final pending = service.scheduleDailyCheckInReminders(isCompletedToday: false);
      final completed = service.scheduleDailyCheckInReminders(isCompletedToday: true);
      await Future.wait([pending, completed]);

      for (final hour in [12, 14, 16, 18, 20, 22]) {
        expect(active.containsKey(2000 + hour), isFalse,
            reason: 'daily $hour:00 trigger left armed: fires today after completion');
      }
      expect(active.length, 2 + 6 * DailyCheckinNotificationService.completedLookaheadDays);
    });

    test('cancelAllCheckInReminders also cancels the one-shot slots', () async {
      final h = Harness();
      await DailyCheckinNotificationService(center: h.center)
          .cancelAllCheckInReminders();
      expect(h.cancelledIds.toSet(),
          DailyCheckinNotificationService.ownedNotificationIds.toSet());
      expect(h.cancelledIds.every((id) => id >= 2000 && id < 2400), isTrue);
    });

    test('next-day slots keep the wall-clock hour across a DST change', () {
      // Europe/Madrid springs forward on 2026-03-29.
      final next = AppNotificationCenter.nextInstanceOfHour(
        8,
        now: _madrid(2026, 3, 28, 10),
        dayOffset: 1,
      );
      expect(next.day, 29);
      expect(next.hour, 8);
    });
  });

  group('Finding 6: localized texts, no country-specific timezone default', () {
    Future<Map<Symbol, dynamic>> firstCheckin(Locale locale) async {
      final h = Harness();
      await DailyCheckinNotificationService(
        center: h.center,
        clock: () => _madrid(2026, 9, 25, 7),
        localeResolver: () => locale,
      ).scheduleDailyCheckInReminders(isCompletedToday: false);
      return h.scheduledById[2008]!;
    }

    test('check-in reminder texts follow the app language', () async {
      final pt = await firstCheckin(const Locale('pt', 'BR'));
      final es = await firstCheckin(const Locale('es'));
      final en = await firstCheckin(const Locale('en'));

      expect(pt[#title], '🩺 Check-in Diário Dualis (08:00)');
      expect(es[#title], '🩺 Check-in diario Dualis (08:00)');
      expect(en[#title], '🩺 Dualis Daily Check-in (08:00)');
      expect(es[#body], lookupAppLocalizations(const Locale('es')).notifCheckinBody);
      expect(en[#body], isNot(pt[#body]));
      final channel = (en[#notificationDetails] as NotificationDetails).android!;
      expect(channel.channelName, 'Daily Check-in Reminders');
    });

    test('water reminder texts and channel follow the app language', () async {
      final h = Harness();
      await HydrationNotificationService(
        center: h.center,
        localeResolver: () => const Locale('es'),
      ).scheduleHydrationReminders(const HydrationSettings(
        reminderSoundStyle: ReminderSoundStyle.phoneAlarm,
      ));
      final call = h.scheduledById[1008]!;
      expect(call[#title], '💧 Hora de beber agua (08:00)');
      expect(call[#body], 'Toca para registrar la cantidad de agua consumida.');
      final android = (call[#notificationDetails] as NotificationDetails).android!;
      expect(android.channelName, 'Recordatorios de agua (alarma sonora)');
      expect(android.fullScreenIntent, isTrue);
    });

    test('unsupported app locale falls back instead of throwing', () {
      expect(() => resolveNotificationLocalizations(const Locale('de')),
          returnsNormally);
    });

    test('timezone fallback uses the device UTC offset, not a country', () {
      expect(AppNotificationCenter.fallbackLocationForOffset(const Duration(hours: -3))!.name,
          'Etc/GMT+3');
      expect(AppNotificationCenter.fallbackLocationForOffset(Duration.zero)!.name,
          'Etc/UTC');
      final india = AppNotificationCenter.fallbackLocationForOffset(
          const Duration(hours: 5, minutes: 30))!;
      expect(india.currentTimeZone.offset, const Duration(hours: 5, minutes: 30));
    });

    test('unavailable device timezone falls back to the device offset', () async {
      final h = Harness();
      final center = AppNotificationCenter(
        plugin: h.plugin,
        timezoneResolver: () async => throw Exception('no plugin'),
      );
      await center.initialize();
      expect(tz.local.currentTimeZone.offset, DateTime.now().timeZoneOffset);
    });

    test('no hardcoded America/Sao_Paulo in the notification sources', () {
      final dir = Directory('lib/core/notifications');
      for (final file in dir.listSync().whereType<File>()) {
        expect(file.readAsStringSync(), isNot(contains('America/Sao_Paulo')),
            reason: file.path);
      }
    });

    test('changing the app language re-arms check-in reminders in that language',
        () async {
      final h = Harness();
      final container = ProviderContainer(overrides: [
        appNotificationCenterProvider.overrideWithValue(h.center),
        authControllerProvider.overrideWith(_SignedInAuthController.new),
        secureStorageServiceProvider.overrideWithValue(_FakeSecureStorage()),
        triageHistoryDataSourceProvider
            .overrideWithValue(_EmptyHistoryDataSource()),
      ]);
      addTearDown(container.dispose);

      container.read(triggerCheckInProvider);
      await pumpEventQueue();
      h.scheduled.clear();

      container.read(localeProvider.notifier).setLocale(const Locale('en'));
      await pumpEventQueue();

      expect(h.scheduled, isNotEmpty);
      expect(
        h.scheduled.every((c) => (c[#title] as String).contains('Dualis Daily Check-in')),
        isTrue,
      );
    });
  });

  group('Finding 7: logout resets hydration state and keeps reminders off', () {
    test('logout drops the previous user\'s water data and does not re-arm reminders',
        () async {
      final h = Harness();
      final repository = _FakeHydrationRepository();
      final container = ProviderContainer(overrides: [
        appNotificationCenterProvider.overrideWithValue(h.center),
        authControllerProvider.overrideWith(_SignedInAuthController.new),
        secureStorageServiceProvider.overrideWithValue(_FakeSecureStorage()),
        hydrationRepositoryProvider.overrideWithValue(repository),
      ]);
      addTearDown(container.dispose);
      final keepAlive = container.listen(hydrationControllerProvider, (_, __) {});
      addTearDown(keepAlive.close);

      await pumpEventQueue();
      expect(container.read(hydrationControllerProvider).todayTotalMl, 250);
      expect(h.scheduled, isNotEmpty, reason: 'signed in: reminders armed');

      h.scheduled.clear();
      h.cancelledIds.clear();
      await container.read(authControllerProvider.notifier).logout();
      await pumpEventQueue();

      final state = container.read(hydrationControllerProvider);
      expect(state.todayTotalMl, 0);
      expect(state.todayLogs, isEmpty);
      expect(h.scheduled, isEmpty, reason: 'no reminders may come back after logout');
      expect(h.cancelledIds, containsAll([for (var hr = 0; hr < 24; hr++) 1000 + hr]));
    });
  });

  group('Finding 8: exact alarms requested only when needed', () {
    late Harness h;
    late MockAndroidPlugin android;

    setUp(() {
      h = Harness();
      android = MockAndroidPlugin();
      when(() => h.plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()).thenReturn(android);
      when(() => android.requestNotificationsPermission())
          .thenAnswer((_) async => true);
      when(() => android.requestExactAlarmsPermission())
          .thenAnswer((_) async => true);
    });

    test('ensureExactAlarmsPermission asks only when Android reports it missing',
        () async {
      when(() => android.canScheduleExactNotifications())
          .thenAnswer((_) async => false);
      await h.center.ensureExactAlarmsPermission();
      verify(() => android.requestExactAlarmsPermission()).called(1);

      when(() => android.canScheduleExactNotifications())
          .thenAnswer((_) async => true);
      await h.center.ensureExactAlarmsPermission();
      verifyNever(() => android.requestExactAlarmsPermission());
    });

    test('picking the alarm style asks once; routine reschedules never nag', () async {
      when(() => android.canScheduleExactNotifications())
          .thenAnswer((_) async => false);
      final container = ProviderContainer(overrides: [
        appNotificationCenterProvider.overrideWithValue(h.center),
        authControllerProvider.overrideWith(_SignedInAuthController.new),
        secureStorageServiceProvider.overrideWithValue(_FakeSecureStorage()),
        hydrationRepositoryProvider
            .overrideWithValue(_FakeHydrationRepository()),
      ]);
      addTearDown(container.dispose);
      final keepAlive = container.listen(hydrationControllerProvider, (_, __) {});
      addTearDown(keepAlive.close);

      await pumpEventQueue(); // loadData -> scheduleHydrationReminders
      expect(h.scheduled, isNotEmpty);
      verifyNever(() => android.requestExactAlarmsPermission());

      final notifier = container.read(hydrationControllerProvider.notifier);
      await notifier.setSoundStyle(ReminderSoundStyle.phoneAlarm);
      verify(() => android.requestExactAlarmsPermission()).called(1);

      await notifier.setDailyTarget(2500);
      verifyNever(() => android.requestExactAlarmsPermission());
    });
  });
}

class _IdleHydrationController extends HydrationController {
  @override
  HydrationState build() => const HydrationState(
        settings: HydrationSettings(trackingEnabled: true),
      );

  @override
  Future<void> loadData() async {}
}
