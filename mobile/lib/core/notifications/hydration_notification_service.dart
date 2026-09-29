import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/hydration/domain/models/hydration_settings.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/locale_provider.dart';
import 'app_notification_center.dart';

typedef HydrationModalCallback = void Function();

class HydrationNotificationService {
  HydrationNotificationService({
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
  /// cancel/schedule sequences could leave a stale trigger armed.
  Future<void> _lastReschedule = Future<void>.value();

  static const String chimeChannelId = 'dualis_hydration_chime';
  static const String alarmChannelId = 'dualis_hydration_alarm';

  /// Scheduled reminders use `reminderIdBase + hour` (hour 0..23).
  static const int reminderIdBase = 1000;

  /// "Test notification now" / immediate reminder.
  static const int immediateReminderId = 9999;

  /// In-seconds test reminder id.
  static const int testReminderId = 1999;

  /// When today's hydration target is reached, reminder slots still ahead today
  /// are scheduled as one-shots on the next [completedLookaheadDays] days
  /// so that no reminders fire for the rest of today, but upcoming days remain
  /// scheduled even if the user does not open the app tomorrow.
  static const int completedLookaheadDays = 3;

  /// One-shot slot for `dayOffset` days ahead: `1000 + 100 * dayOffset + hour`.
  static int oneShotId(int dayOffset, int hour) =>
      reminderIdBase + 100 * dayOffset + hour;

  /// Every scheduled-reminder ID this service may have created, whatever the
  /// hours configured at the time, including one-shot lookahead slots.
  static List<int> get scheduledReminderIds => [
        for (var hour = 0; hour < 24; hour++) reminderIdBase + hour,
        for (var day = 1; day <= completedLookaheadDays; day++)
          for (var hour = 0; hour < 24; hour++) oneShotId(day, hour),
      ];

  /// Every notification ID owned by this service. Other features' IDs (e.g.
  /// daily check-in 2000+) are never touched.
  static List<int> get ownedNotificationIds =>
      [...scheduledReminderIds, immediateReminderId, testReminderId];

  FlutterLocalNotificationsPlugin get _plugin => _center.plugin;

  /// Taps on water reminders (`open_water_modal`), including the tap that
  /// launched the app.
  Stream<String> get onNotificationOpened => _center.payloads(
        where: (payload) => payload == NotificationPayloads.openWaterModal,
      );

  Future<void> initialize() => _center.initialize();

  Future<bool> requestPermissions() => _center.requestPermissions();

  /// Verifica se o dispositivo Android permite o agendamento de alarmes exatos
  Future<bool> canScheduleExactAlarms() => _center.canScheduleExactAlarms();

  /// Abre a tela do sistema para conceder permissão de alarmes exatos (Android 12+)
  Future<void> requestExactAlarmsPermission() =>
      _center.requestExactAlarmsPermission();

  /// Requests exact-alarm access only when Android reports it missing.
  Future<bool> ensureExactAlarmsPermission() =>
      _center.ensureExactAlarmsPermission();

  Future<void> ensureBackgroundAlarmsReliability() =>
      _center.ensureBackgroundAlarmsReliability();

  AppLocalizations _l10n() =>
      resolveNotificationLocalizations(_localeResolver?.call());

  NotificationDetails _getNotificationDetails(
    ReminderSoundStyle style,
    AppLocalizations l10n,
  ) {
    if (style == ReminderSoundStyle.phoneAlarm) {
      return NotificationDetails(
        android: AndroidNotificationDetails(
          alarmChannelId,
          l10n.notifWaterAlarmChannelName,
          channelDescription: l10n.notifWaterAlarmChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        chimeChannelId,
        l10n.notifWaterChimeChannelName,
        channelDescription: l10n.notifWaterChimeChannelDescription,
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

  String _body(AppLocalizations l10n, bool trackingEnabled) => trackingEnabled
      ? l10n.notifWaterBodyTracking
      : l10n.notifWaterBodyReminder;

  tz.TZDateTime _now() => _clock?.call() ?? tz.TZDateTime.now(tz.local);

  Future<void> scheduleHydrationReminders(
    HydrationSettings settings, {
    bool isGoalReached = false,
  }) {
    final run = _lastReschedule.then(
      (_) => _reschedule(settings: settings, isGoalReached: isGoalReached),
    );
    _lastReschedule = run.catchError((Object _) {});
    return run;
  }

  Future<void> _reschedule({
    required HydrationSettings settings,
    required bool isGoalReached,
  }) async {
    await initialize();
    await _cancelScheduledReminders();

    if (!settings.reminderEnabled) return;

    // Garante que permissões de notificação sejam solicitadas ao agendar
    await requestPermissions();

    final l10n = _l10n();
    final details = _getNotificationDetails(settings.reminderSoundStyle, l10n);
    final body = _body(l10n, settings.trackingEnabled);
    final now = _now();

    // Verifica se alarmes exatos são permitidos pelo SO
    final exactAllowed = await canScheduleExactAlarms();
    final scheduleMode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final hour in settings.scheduledHours) {
      if (hour < 0 || hour > 23) continue;
      final timeFormatted = formatReminderHour(hour);
      final title = l10n.notifWaterTitleAt(timeFormatted);

      try {
        final todaySlot = tz.TZDateTime(
          now.location,
          now.year,
          now.month,
          now.day,
          hour,
        );
        final stillAheadToday = todaySlot.isAfter(now);

        // Se a meta foi atingida hoje:
        // - Horários que ainda estão por vir hoje NÃO devem disparar hoje.
        //   São agendados como one-shots para os próximos dias (1..completedLookaheadDays).
        // - Horários que já passaram hoje continuam repetindo diariamente (próximo disparo amanhã).
        //
        // Se a meta NÃO foi atingida hoje (ou voltou a ser menor que a meta após deletar registros):
        // - Todos os horários repetem diariamente (logo, os que ainda estão à frente hoje DISPARARÃO hoje).
        if (!isGoalReached || !stillAheadToday) {
          await _schedule(
            id: reminderIdBase + hour,
            title: title,
            body: body,
            details: details,
            date: AppNotificationCenter.nextInstanceOfHour(hour, now: now),
            repeatDaily: true,
            scheduleMode: scheduleMode,
          );
          continue;
        }

        // Meta atingida hoje e horário ainda à frente hoje:
        // Agenda one-shots para os próximos dias sem disparar mais hoje.
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
            scheduleMode: scheduleMode,
          );
        }
      } catch (e) {
        debugPrint(
            'Erro no cálculo de data do lembrete de água das $timeFormatted: $e');
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
    required AndroidScheduleMode scheduleMode,
  }) async {
    try {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: date,
          notificationDetails: details,
          payload: NotificationPayloads.openWaterModal,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
        );
      } catch (e) {
        debugPrint(
            'Aviso ao agendar lembrete de água $id com $scheduleMode: $e. Tentando modo inexato...');
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: date,
          notificationDetails: details,
          payload: NotificationPayloads.openWaterModal,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
        );
      }
    } catch (scheduleErr) {
      debugPrint('Aviso ao agendar lembrete de água $id: $scheduleErr');
    }
  }

  Future<void> showImmediateReminder({
    required ReminderSoundStyle style,
    required bool trackingEnabled,
    String? customBody,
  }) async {
    await initialize();
    final l10n = _l10n();
    final details = _getNotificationDetails(style, l10n);

    await _plugin.show(
      id: immediateReminderId,
      title: l10n.notifWaterTitle,
      body: customBody ?? _body(l10n, trackingEnabled),
      notificationDetails: details,
      payload: NotificationPayloads.openWaterModal,
    );
  }

  /// Agenda uma notificação de teste para daqui a [seconds] segundos para
  /// que o usuário possa fechar o aplicativo e validar o recebimento com o app fechado.
  Future<void> scheduleTestReminderInSeconds({
    int seconds = 10,
    required ReminderSoundStyle style,
    required bool trackingEnabled,
    String? customBody,
  }) async {
    await initialize();
    await requestPermissions();
    final l10n = _l10n();
    final details = _getNotificationDetails(style, l10n);
    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    final exactAllowed = await canScheduleExactAlarms();
    final scheduleMode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _plugin.zonedSchedule(
        id: testReminderId,
        title: l10n.notifWaterTitle,
        body: customBody ??
            '💧 Dualis: Alerta de teste em segundo plano! O app está ativo na memória.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        payload: NotificationPayloads.openWaterModal,
        androidScheduleMode: scheduleMode,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: testReminderId,
        title: l10n.notifWaterTitle,
        body: customBody ??
            '💧 Dualis: Alerta de teste em segundo plano! O app está ativo na memória.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        payload: NotificationPayloads.openWaterModal,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _cancelIds(Iterable<int> ids) async {
    for (final id in ids) {
      try {
        await _plugin.cancel(id: id);
      } catch (e) {
        debugPrint('Erro ao cancelar lembrete de água $id: $e');
      }
    }
  }

  Future<void> _cancelScheduledReminders() => _cancelIds(scheduledReminderIds);

  /// Cancels only this service's own notifications — never `cancelAll()`,
  /// which would also wipe the daily check-in reminders.
  Future<void> cancelAllReminders() => _cancelIds(ownedNotificationIds);

  /// The tap dispatcher is shared (AppNotificationCenter); nothing to release.
  void dispose() {}
}

final hydrationNotificationServiceProvider =
    Provider<HydrationNotificationService>((ref) {
  final service = HydrationNotificationService(
    center: ref.watch(appNotificationCenterProvider),
    localeResolver: () => ref.read(localeProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
