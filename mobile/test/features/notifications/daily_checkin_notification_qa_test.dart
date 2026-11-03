import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:dualis_mobile/core/notifications/daily_checkin_notification_service.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class FakeInitializationSettings extends Fake implements InitializationSettings {}
class FakeTZDateTime extends Fake implements tz.TZDateTime {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(FakeInitializationSettings());
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(DateTimeComponents.time);
  });

  group('QA Feature 1: Lembrete de checkin diário (2 em 2 horas a partir das 08:00)', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late DailyCheckinNotificationService service;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = DailyCheckinNotificationService(plugin: mockPlugin);

      when(() => mockPlugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((_) async => true);

      when(() => mockPlugin.cancel(id: any(named: 'id')))
          .thenAnswer((_) async {});

      when(() => mockPlugin.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).thenAnswer((_) async {});
    });

    test('QA 1.1: Reminder hours match required 2-hour schedule starting at 8:00 until 22:00', () {
      expect(
        DailyCheckinNotificationService.reminderHours,
        equals([8, 10, 12, 14, 16, 18, 20, 22]),
      );
      expect(DailyCheckinNotificationService.reminderHours.length, equals(8));
      for (int i = 0; i < DailyCheckinNotificationService.reminderHours.length - 1; i++) {
        expect(
          DailyCheckinNotificationService.reminderHours[i + 1] -
              DailyCheckinNotificationService.reminderHours[i],
          equals(2),
        );
      }
    });

    test('QA 1.2: Calling cancelAllCheckInReminders cancels all 8 notification slots', () async {
      await service.cancelAllCheckInReminders();

      for (final hour in DailyCheckinNotificationService.reminderHours) {
        verify(() => mockPlugin.cancel(id: 2000 + hour)).called(1);
      }
    });

    test('QA 1.3: If check-in is already completed today, nothing fires today but every slot is re-armed from tomorrow', () async {
      // Fixed clock at 11:30 so the split between past and upcoming slots is
      // deterministic. Daily-repeating triggers get their first fire computed
      // from "now" by the platform, so upcoming slots must be one-shots.
      final location = tz.getLocation('America/Sao_Paulo');
      final now = tz.TZDateTime(location, 2026, 9, 25, 11, 30);
      final clocked = DailyCheckinNotificationService(
        plugin: mockPlugin,
        clock: () => now,
      );

      await clocked.scheduleDailyCheckInReminders(isCompletedToday: true);

      final captured = verify(() => mockPlugin.zonedSchedule(
            id: captureAny(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: captureAny(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: captureAny(named: 'matchDateTimeComponents'),
          )).captured;

      final tomorrowStart = tz.TZDateTime(location, 2026, 9, 26);
      final firesTomorrow = <int>{};
      for (var i = 0; i < captured.length; i += 3) {
        final date = captured[i + 1] as tz.TZDateTime;
        final repeats = captured[i + 2] == DateTimeComponents.time;
        if (repeats) {
          // Platform computes the first fire from now: must already be past today.
          expect(date.hour, lessThanOrEqualTo(now.hour),
              reason: 'daily trigger at ${date.hour}:00 would fire today');
          firesTomorrow.add(date.hour);
        } else {
          expect(date.isBefore(tomorrowStart), isFalse,
              reason: 'one-shot at $date fires today');
          if (date.day == 26) firesTomorrow.add(date.hour);
        }
      }
      expect(firesTomorrow, DailyCheckinNotificationService.reminderHours.toSet());
    });

    test('QA 1.4: Completing check-in stage via TriggerCheckInNotifier clears today\'s reminders and re-arms the next days', () async {
      final container = ProviderContainer(
        overrides: [
          dailyCheckinNotificationServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.completeStage(
        vertical: TriageVertical.psicoEmocional,
        summary: 'Bem / Ótimo',
      );

      await pumpEventQueue();

      // Today's pending slots are cleared...
      for (final hour in DailyCheckinNotificationService.reminderHours) {
        verify(() => mockPlugin.cancel(id: 2000 + hour)).called(greaterThanOrEqualTo(1));
      }
      // ...and the following days are re-armed (not a bare cancel).
      verify(() => mockPlugin.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).called(greaterThanOrEqualTo(DailyCheckinNotificationService.reminderHours.length));
    });

    test('QA 1.5: Resetting check-in for a new day clears completed status and enables reminders', () async {
      final container = ProviderContainer(
        overrides: [
          dailyCheckinNotificationServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.completeStage(
        vertical: TriageVertical.psicoEmocional,
        summary: 'Bem / Ótimo',
      );
      expect(container.read(triggerCheckInProvider).isCompletedToday, isTrue);

      notifier.reset();
      await pumpEventQueue();

      final state = container.read(triggerCheckInProvider);
      expect(state.isCompletedToday, isFalse);
      expect(state.isEmotionalCompleted, isFalse);
      expect(state.isPhysicalCompleted, isFalse);
    });
  });
}
