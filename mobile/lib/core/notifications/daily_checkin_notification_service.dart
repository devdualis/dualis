import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../../l10n/locale_provider.dart';
import 'app_notification_center.dart';

class DailyCheckinNotificationService {
  DailyCheckinNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    AppNotificationCenter? center,
    Locale Function()? localeResolver,
    tz.TZDateTime Function()? clock,
  })  : _center = center ??
            AppNotificationCenter.of(
                plugin ?? FlutterLocalNotificationsPlugin()),
        _localeResolver = localeResolver,
        _clock = clock;

  final AppNotificationCenter _center;
  final Locale Function()? _localeResolver;
  final tz.TZDateTime Function()? _clock;

  /// Reschedules run one after another (last request wins): interleaved
  /// cancel/schedule sequences could leave a stale daily trigger armed.
  Future<void> _lastReschedule = Future<void>.value();

  static const String checkinChannelId = 'dualis_daily_checkin';

  /// Horários de check-in de 2 em 2 horas a partir das 08:00
  static const List<int> reminderHours = [8, 10, 12, 14, 16, 18, 20, 22];

  /// Daily-repeating slot: `dailyIdBase + hour`.
  static const int dailyIdBase = 2000;

  /// When today's check-in is already done, slots still ahead today are
  /// scheduled as one-shots on the next [completedLookaheadDays] days
  /// (see [scheduleDailyCheckInReminders]). Kept small for iOS's 64 pending
  /// notifications limit.
  static const int completedLookaheadDays = 3;

  /// One-shot slot for `dayOffset` days ahead: `2000 + 100 * dayOffset + hour`.
  static int oneShotId(int dayOffset, int hour) =>
      dailyIdBase + 100 * dayOffset + hour;

  /// Every notification ID owned by this service (never hydration's).
  static List<int> get ownedNotificationIds => [
        for (final hour in reminderHours) dailyIdBase + hour,
        for (var day = 1; day <= completedLookaheadDays; day++)
          for (final hour in reminderHours) oneShotId(day, hour),
      ];

  FlutterLocalNotificationsPlugin get _plugin => _center.plugin;

  /// Taps on check-in reminders (`open_checkin`), including the tap that
  /// launched the app.
  Stream<String> get onNotificationOpened => _center.payloads(
        where: (payload) => payload == NotificationPayloads.openCheckIn,
      );

  Future<void> initialize() => _center.initialize();

  Future<bool> requestPermissions() => _center.requestPermissions();

  AppLocalizations _l10n() =>
      resolveNotificationLocalizations(_localeResolver?.call());

  tz.TZDateTime _now() => _clock?.call() ?? tz.TZDateTime.now(tz.local);

  NotificationDetails _getNotificationDetails(AppLocalizations l10n) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        checkinChannelId,
        l10n.notifCheckinChannelName,
        channelDescription: l10n.notifCheckinChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        enableVibration: true,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
  }

  /// Agenda lembretes a cada 2 horas a partir das 08:00 (8, 10, 12, 14, 16, 18, 20, 22).
  ///
  /// Pending check-in: every slot repeats daily.
  ///
  /// Check-in already done today: nothing may fire today, yet the following
  /// days must keep their reminders. A daily-repeating trigger cannot skip
  /// today — both the Android and the iOS plugin recompute its first fire
  /// from "now", ignoring the date passed in — so:
  ///  * slots already past today keep repeating daily (next fire: tomorrow);
  ///  * slots still ahead today become one-shots on each of the next
  ///    [completedLookaheadDays] days (re-armed whenever the app loads the
  ///    check-in state).
  Future<void> scheduleDailyCheckInReminders({required bool isCompletedToday}) {
    final run = _lastReschedule.then(
      (_) => _reschedule(isCompletedToday: isCompletedToday),
    );
    _lastReschedule = run.catchError((Object _) {});
    return run;
  }

  Future<void> _reschedule({required bool isCompletedToday}) async {
    await initialize();
    await cancelAllCheckInReminders();
    await requestPermissions();

    final l10n = _l10n();
    final details = _getNotificationDetails(l10n);
    final body = l10n.notifCheckinBody;
    final now = _now();

    for (final hour in reminderHours) {
      final title = l10n.notifCheckinTitleAt(formatReminderHour(hour));
      try {
        final todaySlot =
            tz.TZDateTime(now.location, now.year, now.month, now.day, hour);
        final stillAheadToday = todaySlot.isAfter(now);

        if (!isCompletedToday || !stillAheadToday) {
          await _schedule(
            id: dailyIdBase + hour,
            title: title,
            body: body,
            details: details,
            date: AppNotificationCenter.nextInstanceOfHour(hour, now: now),
            repeatDaily: true,
          );
          continue;
        }

        for (var day = 1; day <= completedLookaheadDays; day++) {
          await _schedule(
            id: oneShotId(day, hour),
            title: title,
            body: body,
            details: details,
            date: AppNotificationCenter.nextInstanceOfHour(
              hour,
              now: now,
              dayOffset: day,
            ),
            repeatDaily: false,
          );
        }
      } catch (calcErr) {
        debugPrint('Erro de cálculo para check-in das $hour:00: $calcErr');
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
    required tz.TZDateTime date,
    required bool repeatDaily,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: date,
        notificationDetails: details,
        payload: NotificationPayloads.openCheckIn,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      );
    } catch (scheduleErr) {
      debugPrint('Aviso ao agendar check-in $id: $scheduleErr');
    }
  }

  /// Cancela todos os lembretes de check-in diário (diários e pontuais)
  Future<void> cancelAllCheckInReminders() async {
    for (final id in ownedNotificationIds) {
      try {
        await _plugin.cancel(id: id);
      } catch (e) {
        debugPrint('Erro ao cancelar lembrete de check-in $id: $e');
      }
    }
  }

  /// The tap dispatcher is shared (AppNotificationCenter); nothing to release.
  void dispose() {}
}

final dailyCheckinNotificationServiceProvider =
    Provider<DailyCheckinNotificationService>((ref) {
  final service = DailyCheckinNotificationService(
    center: ref.watch(appNotificationCenterProvider),
    localeResolver: () => ref.read(localeProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
