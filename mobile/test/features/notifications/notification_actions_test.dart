// Notification action buttons (quick task 261117-ndu): routing, snooze, the
// pending-action queue and its drain.
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:dualis_mobile/core/notifications/app_notification_center.dart';
import 'package:dualis_mobile/core/notifications/daily_checkin_notification_service.dart';
import 'package:dualis_mobile/features/care/data/care_api.dart';
import 'package:dualis_mobile/features/care/data/care_notifications.dart';
import 'package:dualis_mobile/features/care/domain/care_models.dart';
import 'package:dualis_mobile/core/notifications/hydration_notification_service.dart';
import 'package:dualis_mobile/core/notifications/notification_action_queue.dart';
import 'package:dualis_mobile/core/notifications/notification_actions.dart';
import 'package:dualis_mobile/features/sync/data/notification_action_sync.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _FakeTZDateTime extends Fake implements tz.TZDateTime {}

class _MockCareApi extends Mock implements CareApi {}

class _RecordingExecutor extends NotificationActionExecutor {
  _RecordingExecutor()
      : super(
          plugin: _MockPlugin(),
          queue: InMemoryNotificationActionQueue(),
          l10n: () => lookupAppLocalizations(const Locale('pt')),
        );

  final List<NotificationActionEffect> executed = [];

  @override
  Future<void> execute(NotificationActionEffect effect) async {
    executed.add(effect);
  }
}

final AppLocalizations _pt = lookupAppLocalizations(const Locale('pt'));
final DateTime _t = DateTime(2026, 11, 17, 9, 10);

_MockPlugin _schedulingPlugin(List<Map<Symbol, dynamic>> scheduled) {
  final plugin = _MockPlugin();
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
  return plugin;
}

NotificationResponse _action(String actionId, {String? payload, int? id}) =>
    NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: actionId,
      payload: payload,
      id: id,
    );

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(_FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(DateTimeComponents.time);
    registerFallbackValue(CareKind.medicationIntake);
    registerFallbackValue(IntakeAction.taken);
    registerFallbackValue(DateTime(2026));
  });

  group('resolveNotificationAction: water', () {
    test('"Bebi 250 ml" queues 250 ml at the tap time with a fresh id', () {
      final a = resolveNotificationAction(
          actionId: NotificationActionIds.waterDrank250, now: _t);
      final b = resolveNotificationAction(
          actionId: NotificationActionIds.waterDrank250, now: _t);
      expect(a, isA<EnqueueAction>());
      final entry = (a as EnqueueAction).action;
      expect(entry.kind, PendingNotificationActionKind.water);
      expect(entry.amountMl, 250);
      expect(entry.at, _t);
      expect(entry.id, isNotEmpty);
      expect(entry.id, isNot((b as EnqueueAction).action.id));
    });

    test('each snooze id maps to its variant, +30 min, id 1998', () {
      final cases = {
        NotificationActionIds.waterSnoozeChimeTracking:
            WaterReminderVariant.chimeTracking,
        NotificationActionIds.waterSnoozeChime:
            WaterReminderVariant.chimeReminder,
        NotificationActionIds.waterSnoozeAlarm: WaterReminderVariant.alarm,
      };
      cases.forEach((actionId, variant) {
        final effect = resolveNotificationAction(actionId: actionId, now: _t);
        expect(effect, isA<Snooze>());
        final snooze = effect as Snooze;
        expect(snooze.kind, SnoozeKind.water);
        expect(snooze.id, 1998);
        expect(snooze.id, HydrationNotificationService.snoozeReminderId);
        expect(snooze.at, _t.add(const Duration(minutes: 30)));
        expect(snooze.payload, NotificationPayloads.openWaterModal);
        expect(snooze.waterVariant, variant);
      });
    });

    test('unknown action ids dismiss', () {
      expect(resolveNotificationAction(actionId: 'nope', now: _t),
          isA<Dismiss>());
      expect(resolveNotificationAction(now: _t), isA<Dismiss>());
    });
  });

  group('water notification details', () {
    test('both styles carry "Bebi 250 ml" and the variant snooze', () {
      for (final variant in WaterReminderVariant.values) {
        final details =
            HydrationNotificationService.notificationDetails(variant, _pt);
        final actions = details.android!.actions!;
        expect(actions, hasLength(2));
        expect(actions[0].id, NotificationActionIds.waterDrank250);
        expect(actions[0].title, 'Bebi 250 ml');
        expect(actions[0].showsUserInterface, isFalse);
        expect(actions[1].id, variant.snoozeActionId);
        expect(actions[1].title, 'Adiar 30 min');
        expect(actions[1].showsUserInterface, isFalse);
        expect(details.iOS!.categoryIdentifier, variant.categoryId);
      }
    });

    test('alarm keeps the alarm channel and fullScreenIntent', () {
      final alarm = HydrationNotificationService.notificationDetails(
          WaterReminderVariant.alarm, _pt);
      expect(alarm.android!.channelId,
          HydrationNotificationService.alarmChannelId);
      expect(alarm.android!.fullScreenIntent, isTrue);
      expect(alarm.iOS!.interruptionLevel, InterruptionLevel.timeSensitive);
      final chime = HydrationNotificationService.notificationDetails(
          WaterReminderVariant.chimeReminder, _pt);
      expect(chime.android!.channelId,
          HydrationNotificationService.chimeChannelId);
      expect(chime.android!.fullScreenIntent, isFalse);
    });

    test('snooze id is owned but not rescheduled away', () {
      expect(HydrationNotificationService.ownedNotificationIds, contains(1998));
      expect(HydrationNotificationService.scheduledReminderIds,
          isNot(contains(1998)));
    });
  });

  group('NotificationActionExecutor', () {
    for (final variant in WaterReminderVariant.values) {
      test('water snooze (${variant.name}) schedules one 1998 one-off', () async {
        final scheduled = <Map<Symbol, dynamic>>[];
        final plugin = _schedulingPlugin(scheduled);
        final executor = NotificationActionExecutor(
          plugin: plugin,
          queue: InMemoryNotificationActionQueue(),
          l10n: () => _pt,
        );
        final effect = resolveNotificationAction(
            actionId: variant.snoozeActionId, now: _t) as Snooze;

        await executor.execute(effect);

        expect(scheduled, hasLength(1));
        final call = scheduled.single;
        expect(call[#id], 1998);
        expect(call[#title], HydrationNotificationService.title(variant, _pt));
        expect(call[#body], HydrationNotificationService.body(variant, _pt));
        expect(call[#payload], NotificationPayloads.openWaterModal);
        expect(call[#matchDateTimeComponents], isNull);
        expect((call[#scheduledDate] as tz.TZDateTime).toUtc(),
            _t.add(const Duration(minutes: 30)).toUtc());
        final details = call[#notificationDetails] as NotificationDetails;
        expect(details.android!.channelId,
            variant == WaterReminderVariant.alarm
                ? HydrationNotificationService.alarmChannelId
                : HydrationNotificationService.chimeChannelId);
        expect(details.android!.fullScreenIntent,
            variant == WaterReminderVariant.alarm);
        expect(details.android!.actions, hasLength(2));
        expect(details.iOS!.categoryIdentifier, variant.categoryId);
      });
    }

    test('enqueue writes to the queue; dismiss and open do nothing', () async {
      final scheduled = <Map<Symbol, dynamic>>[];
      final queue = InMemoryNotificationActionQueue();
      final executor = NotificationActionExecutor(
        plugin: _schedulingPlugin(scheduled),
        queue: queue,
        l10n: () => _pt,
      );
      await executor.execute(resolveNotificationAction(
          actionId: NotificationActionIds.waterDrank250, now: _t));
      await executor.execute(const Dismiss());
      await executor.execute(const OpenInApp('open_checkin'));
      expect(await queue.list(), hasLength(1));
      expect(scheduled, isEmpty);
    });

    test('a failing plugin never throws', () async {
      final plugin = _MockPlugin();
      when(() => plugin.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).thenThrow(Exception('boom'));
      final executor = NotificationActionExecutor(
        plugin: plugin,
        queue: InMemoryNotificationActionQueue(),
        l10n: () => _pt,
      );
      await executor.execute(resolveNotificationAction(
          actionId: NotificationActionIds.waterSnoozeAlarm, now: _t));
    });
  });

  group('FileNotificationActionQueue', () {
    late Directory dir;
    late FileNotificationActionQueue queue;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('notif_actions_');
      queue = FileNotificationActionQueue(directory: () async => dir);
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    PendingNotificationAction water(String id, DateTime at) =>
        PendingNotificationAction(
          id: id,
          kind: PendingNotificationActionKind.water,
          at: at,
          amountMl: 250,
        );

    test('round-trips entries oldest first and removes one', () async {
      await queue.add(water('b', _t.add(const Duration(minutes: 5))));
      await queue.add(PendingNotificationAction(
        id: 'a',
        kind: PendingNotificationActionKind.medicationTaken,
        at: _t,
        medicationId: 'med-1',
        scheduledFor: DateTime(2026, 11, 17, 8, 30),
      ));
      final listed = await queue.list();
      expect(listed.map((e) => e.id), ['a', 'b']);
      expect(listed.first.medicationId, 'med-1');
      expect(listed.first.scheduledFor!.toUtc(),
          DateTime(2026, 11, 17, 8, 30).toUtc());
      expect(listed.last.amountMl, 250);
      expect(dir.listSync().whereType<File>().where((f) => f.path.endsWith('.tmp')),
          isEmpty);

      await queue.remove('a');
      expect((await queue.list()).map((e) => e.id), ['b']);
    });

    test('ignores a corrupt file without throwing', () async {
      await queue.add(water('ok', _t));
      await File('${dir.path}/broken.json').writeAsString('{not json');
      await File('${dir.path}/wrong.json').writeAsString('{"id":"x"}');
      final listed = await queue.list();
      expect(listed.map((e) => e.id), ['ok']);
    });

    test('clear empties it and the language survives a round-trip', () async {
      await queue.add(water('x', _t));
      await queue.saveLanguageCode('es');
      await queue.clear();
      expect(await queue.list(), isEmpty);
      expect(await queue.readLanguageCode(), 'es');
    });

    test('entries hold no free text', () async {
      await queue.add(water('w', _t));
      final raw = File('${dir.path}/w.json').readAsStringSync();
      expect(raw, isNot(contains('name')));
      expect(raw, isNot(contains('place')));
    });
  });

  group('NotificationActionDrain', () {
    PendingNotificationAction water(String id, DateTime at) =>
        PendingNotificationAction(
          id: id,
          kind: PendingNotificationActionKind.water,
          at: at,
          amountMl: 250,
        );

    test('done and drop remove, retry keeps, old entries dropped unhandled',
        () async {
      final queue = InMemoryNotificationActionQueue();
      await queue.add(water('done', _t));
      await queue.add(water('drop', _t.add(const Duration(seconds: 1))));
      await queue.add(water('retry', _t.add(const Duration(seconds: 2))));
      await queue.add(water('old', _t.subtract(const Duration(days: 8))));
      final handled = <String>[];
      final drain = NotificationActionDrain(
        queue,
        clock: () => _t.add(const Duration(minutes: 1)),
        handle: (entry) async {
          handled.add(entry.id);
          return switch (entry.id) {
            'done' => DrainOutcome.done,
            'drop' => DrainOutcome.drop,
            _ => DrainOutcome.retry,
          };
        },
      );
      expect(await drain.drain(), 1);
      expect(handled, ['done', 'drop', 'retry']);
      expect((await queue.list()).map((e) => e.id), ['retry']);
    });

    test('an empty queue never calls the handler', () async {
      var calls = 0;
      final drain = NotificationActionDrain(
        InMemoryNotificationActionQueue(),
        handle: (_) async {
          calls++;
          return DrainOutcome.done;
        },
      );
      expect(await drain.drain(), 0);
      expect(calls, 0);
    });

    test('a throwing handler keeps the entry for a retry', () async {
      final queue = InMemoryNotificationActionQueue();
      await queue.add(water('x', _t));
      final drain = NotificationActionDrain(queue,
          clock: () => _t, handle: (_) async => throw Exception('offline'));
      expect(await drain.drain(), 0);
      expect(await queue.list(), hasLength(1));
    });
  });

  group('NotificationActionSync: water', () {
    test('logs queued water for the signed-in user and refreshes totals',
        () async {
      final queue = InMemoryNotificationActionQueue();
      await queue.add(PendingNotificationAction(
        id: 'w1',
        kind: PendingNotificationActionKind.water,
        at: _t,
        amountMl: 250,
      ));
      final logs = <(String, int, DateTime)>[];
      var refreshed = 0;
      final sync = NotificationActionSync(
        queue: queue,
        userId: () => 'user-1',
        clock: () => _t,
        logWater: ({required userId, required amountMl, required timestamp}) async {
          logs.add((userId, amountMl, timestamp));
        },
        onWaterLogged: () async => refreshed++,
      );
      expect(await sync.drain(), 1);
      expect(logs, [('user-1', 250, _t)]);
      expect(refreshed, 1);
      expect(await queue.list(), isEmpty);
    });

    test('no signed-in user keeps the entry', () async {
      final queue = InMemoryNotificationActionQueue();
      await queue.add(PendingNotificationAction(
        id: 'w1',
        kind: PendingNotificationActionKind.water,
        at: _t,
        amountMl: 250,
      ));
      var calls = 0;
      final sync = NotificationActionSync(
        queue: queue,
        userId: () => null,
        clock: () => _t,
        logWater: ({required userId, required amountMl, required timestamp}) async =>
            calls++,
      );
      expect(await sync.drain(), 0);
      expect(calls, 0);
      expect(await queue.list(), hasLength(1));
    });
  });

  group('AppNotificationCenter action responses', () {
    test('a background action id goes to the executor, no payload dispatch',
        () async {
      final executor = _RecordingExecutor();
      final center = AppNotificationCenter(
        plugin: _MockPlugin(),
        timezoneResolver: () async => 'UTC',
        actionExecutor: executor,
      );
      final received = <String>[];
      final sub = center.payloads().listen(received.add);
      center.handleNotificationResponse(_action(
          NotificationActionIds.waterDrank250,
          payload: NotificationPayloads.openWaterModal,
          id: 1010));
      await Future<void>.delayed(Duration.zero);
      expect(executor.executed.single, isA<EnqueueAction>());
      expect(received, isEmpty);
      expect(center.pendingPayloads, isEmpty);
      await sub.cancel();
    });

    test('a body tap still dispatches its payload', () async {
      final executor = _RecordingExecutor();
      final center = AppNotificationCenter(
        plugin: _MockPlugin(),
        timezoneResolver: () async => 'UTC',
        actionExecutor: executor,
      );
      final received = <String>[];
      final sub = center.payloads().listen(received.add);
      center.handleNotificationResponse(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: NotificationPayloads.openWaterModal,
      ));
      await Future<void>.delayed(Duration.zero);
      expect(received, [NotificationPayloads.openWaterModal]);
      expect(executor.executed, isEmpty);
      await sub.cancel();
    });
  });

  test('initialize registers the background handler and iOS categories',
      () async {
    final plugin = _MockPlugin();
    Map<Symbol, dynamic>? args;
    when(() => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
          onDidReceiveBackgroundNotificationResponse:
              any(named: 'onDidReceiveBackgroundNotificationResponse'),
        )).thenAnswer((invocation) async {
      args = invocation.namedArguments;
      return true;
    });
    when(() => plugin.getNotificationAppLaunchDetails())
        .thenAnswer((_) async => null);
    final center = AppNotificationCenter(
      plugin: plugin,
      timezoneResolver: () async => 'UTC',
      localeResolver: () => const Locale('es'),
    );
    await center.initialize();
    expect(args![#onDidReceiveBackgroundNotificationResponse],
        same(notificationActionBackgroundHandler));
    final settings = args![#settings] as InitializationSettings;
    expect(settings.iOS!.requestAlertPermission, isFalse);
    expect(settings.iOS!.requestSoundPermission, isFalse);
    expect(settings.iOS!.requestBadgePermission, isFalse);
    final checkin = settings.iOS!.notificationCategories
        .firstWhere((c) => c.identifier == NotificationCategoryIds.checkin);
    expect(checkin.actions.first.title, 'Hacer check-in');
  });

  group('darwinNotificationCategories', () {
    test('unique ids, two actions at most, foreground only to open screens',
        () {
      final categories = darwinNotificationCategories(_pt);
      final ids = categories.map((c) => c.identifier).toList();
      expect(ids.toSet(), hasLength(ids.length));
      const openers = {
        NotificationActionIds.checkinOpen,
        NotificationActionIds.apptDetails,
        NotificationActionIds.apptDirections,
        NotificationActionIds.vaccineOpen,
      };
      for (final category in categories) {
        expect(category.actions.length, inInclusiveRange(1, 2));
        for (final action in category.actions) {
          expect(
            action.options.contains(DarwinNotificationActionOption.foreground),
            openers.contains(action.identifier),
            reason: action.identifier,
          );
        }
      }
      for (final variant in WaterReminderVariant.values) {
        expect(ids, contains(variant.categoryId));
      }
    });
  });

  group('check-in buttons', () {
    test('Fazer check-in opens the app, Mais tarde only dismisses', () {
      final details = DailyCheckinNotificationService.notificationDetails(_pt);
      final actions = details.android!.actions!;
      expect(actions, hasLength(2));
      expect(actions[0].id, NotificationActionIds.checkinOpen);
      expect(actions[0].title, 'Fazer check-in');
      expect(actions[0].showsUserInterface, isTrue);
      expect(actions[1].id, NotificationActionIds.checkinLater);
      expect(actions[1].title, 'Mais tarde');
      expect(actions[1].showsUserInterface, isFalse);
      expect(actions[1].cancelNotification, isTrue);
      expect(details.iOS!.categoryIdentifier, NotificationCategoryIds.checkin);
      expect(details.android!.channelId,
          DailyCheckinNotificationService.checkinChannelId);
    });

    test('checkin_open reaches the open_checkin stream; later schedules nothing',
        () async {
      final executor = _RecordingExecutor();
      final center = AppNotificationCenter(
        plugin: _MockPlugin(),
        timezoneResolver: () async => 'UTC',
        actionExecutor: executor,
      );
      final received = <String>[];
      final sub = center
          .payloads(where: (p) => p == NotificationPayloads.openCheckIn)
          .listen(received.add);
      center.handleNotificationResponse(_action(
          NotificationActionIds.checkinOpen,
          payload: NotificationPayloads.openCheckIn));
      center.handleNotificationResponse(_action(
          NotificationActionIds.checkinLater,
          payload: NotificationPayloads.openCheckIn));
      await Future<void>.delayed(Duration.zero);
      expect(received, [NotificationPayloads.openCheckIn]);
      expect(executor.executed.single, isA<Dismiss>());
    });
  });

  group('medication buttons', () {
    test('medicationScheduledFor picks the latest slot at or before the tap',
        () {
      expect(medicationScheduledFor('08:30', DateTime(2026, 11, 17, 9, 10)),
          DateTime(2026, 11, 17, 8, 30));
      expect(medicationScheduledFor('23:50', DateTime(2026, 11, 18, 0, 6)),
          DateTime(2026, 11, 17, 23, 50));
      expect(medicationScheduledFor('09:10', DateTime(2026, 11, 17, 9, 10)),
          DateTime(2026, 11, 17, 9, 10));
      expect(medicationScheduledFor('99:00', _t), isNull);
    });

    test('Tomei queues the slot with ids only; malformed payload dismisses',
        () {
      final effect = resolveNotificationAction(
        actionId: NotificationActionIds.medTaken,
        payload: CarePayloads.medication('med-1', '08:30'),
        now: _t,
      );
      final entry = (effect as EnqueueAction).action;
      expect(entry.kind, PendingNotificationActionKind.medicationTaken);
      expect(entry.medicationId, 'med-1');
      expect(entry.scheduledFor, DateTime(2026, 11, 17, 8, 30));
      for (final bad in [null, '', 'care_med|med-1', 'care_med|a b|08:30',
          'care_med|med-1|8h', 'open_checkin']) {
        expect(
            resolveNotificationAction(
                actionId: NotificationActionIds.medTaken,
                payload: bad,
                now: _t),
            isA<Dismiss>(),
            reason: '$bad');
      }
    });

    test('snooze ids stay out of the rescheduled care range', () {
      expect(careSnoozeId(6000), 6100);
      expect(careSnoozeId(6029), 6129);
      expect(careSnoozeId(6105), 6105);
      expect(careSnoozeId(null), 6130);
      expect(careSnoozeId(42), 6130);
      expect(vaccineSnoozeId(6003), 6203);
      expect(vaccineSnoozeId(6210), 6210);
      expect(vaccineSnoozeId(7000), 6230);
    });

    test('Adiar 15 min schedules the same medication reminder once', () async {
      final scheduled = <Map<Symbol, dynamic>>[];
      final executor = NotificationActionExecutor(
        plugin: _schedulingPlugin(scheduled),
        queue: InMemoryNotificationActionQueue(),
        l10n: () => _pt,
      );
      final payload = CarePayloads.medication('med-1', '08:30');
      await executor.execute(resolveNotificationAction(
        actionId: NotificationActionIds.medSnooze,
        payload: payload,
        notificationId: 6004,
        now: _t,
      ));
      final call = scheduled.single;
      expect(call[#id], 6104);
      expect(call[#title], _pt.careNotifMedTitle);
      expect(call[#body], _pt.careNotifMedBody);
      expect(call[#payload], payload);
      expect(call[#matchDateTimeComponents], isNull);
      expect((call[#scheduledDate] as tz.TZDateTime).toUtc(),
          _t.add(const Duration(minutes: 15)).toUtc());
      final details = call[#notificationDetails] as NotificationDetails;
      expect(details.android!.channelId, CareNotificationService.channelId);
      expect(details.android!.actions!.map((a) => a.id),
          [NotificationActionIds.medTaken, NotificationActionIds.medSnooze]);
    });
  });

  group('NotificationActionSync: medication', () {
    final slot = DateTime(2026, 11, 17, 8, 30);
    PendingNotificationAction taken() => PendingNotificationAction(
          id: 'm1',
          kind: PendingNotificationActionKind.medicationTaken,
          at: _t,
          medicationId: 'med-1',
          scheduledFor: slot,
        );
    CareRecord intake(DateTime at, String action) => CareRecord(
          id: 'i-$action',
          kind: CareKind.medicationIntake,
          data: {'action': action},
          createdAt: at,
          occursAt: at.toUtc(),
        );

    late _MockCareApi api;
    late InMemoryNotificationActionQueue queue;
    late List<String> invalidated;
    String? user;

    NotificationActionSync sync() => NotificationActionSync(
          queue: queue,
          userId: () => user,
          clock: () => _t,
          logWater: ({required userId, required amountMl, required timestamp}) async {},
          careApi: () => api,
          onMedicationLogged: invalidated.add,
        );

    setUp(() async {
      api = _MockCareApi();
      queue = InMemoryNotificationActionQueue();
      invalidated = [];
      user = 'user-1';
      await queue.add(taken());
      when(() => api.logIntake(any(), any(), any())).thenAnswer((_) async =>
          intake(slot, 'taken'));
    });

    test('no user keeps it and calls nothing', () async {
      user = null;
      expect(await sync().drain(), 0);
      verifyNever(() => api.list(any(), parentId: any(named: 'parentId')));
      expect(await queue.list(), hasLength(1));
    });

    test('an already taken slot is done without a POST', () async {
      when(() => api.list(CareKind.medicationIntake, parentId: 'med-1'))
          .thenAnswer((_) async => [intake(slot.add(const Duration(seconds: 20)), 'taken')]);
      expect(await sync().drain(), 1);
      verifyNever(() => api.logIntake(any(), any(), any()));
      expect(await queue.list(), isEmpty);
      expect(invalidated, ['med-1']);
    });

    test('otherwise logs the intake once', () async {
      when(() => api.list(CareKind.medicationIntake, parentId: 'med-1'))
          .thenAnswer((_) async => [intake(slot, 'skipped'),
                intake(slot.subtract(const Duration(days: 1)), 'taken')]);
      expect(await sync().drain(), 1);
      verify(() => api.logIntake('med-1', slot, IntakeAction.taken)).called(1);
      expect(await queue.list(), isEmpty);
    });

    DioException dio(int? status) => DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: status == null
              ? DioExceptionType.connectionError
              : DioExceptionType.badResponse,
          response: status == null
              ? null
              : Response(requestOptions: RequestOptions(path: '/x'), statusCode: status),
        );

    for (final status in [400, 403, 404, 422]) {
      test('a $status drops it', () async {
        when(() => api.list(any(), parentId: any(named: 'parentId')))
            .thenAnswer((_) async => []);
        when(() => api.logIntake(any(), any(), any())).thenThrow(dio(status));
        expect(await sync().drain(), 0);
        expect(await queue.list(), isEmpty);
      });
    }

    for (final status in [null, 401, 500, 503]) {
      test('${status ?? 'no response'} keeps it for a retry', () async {
        when(() => api.list(any(), parentId: any(named: 'parentId')))
            .thenThrow(dio(status));
        expect(await sync().drain(), 0);
        expect(await queue.list(), hasLength(1));
        verifyNever(() => api.logIntake(any(), any(), any()));
      });
    }
  });
}
