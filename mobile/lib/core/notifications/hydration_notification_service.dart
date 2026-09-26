import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  })  : _center = center ??
            AppNotificationCenter.of(
                plugin ?? FlutterLocalNotificationsPlugin()),
        _localeResolver = localeResolver;

  final AppNotificationCenter _center;
  final Locale Function()? _localeResolver;

  static const String chimeChannelId = 'dualis_hydration_chime';
  static const String alarmChannelId = 'dualis_hydration_alarm';

  /// Scheduled reminders use `reminderIdBase + hour` (hour 0..23).
  static const int reminderIdBase = 1000;

  /// "Test notification now" / immediate reminder.
  static const int immediateReminderId = 9999;

  /// Every scheduled-reminder ID this service may have created, whatever the
  /// hours configured at the time.
  static List<int> get scheduledReminderIds =>
      [for (var hour = 0; hour < 24; hour++) reminderIdBase + hour];

  /// Every notification ID owned by this service. Other features' IDs (e.g.
  /// daily check-in 2000+) are never touched.
  static List<int> get ownedNotificationIds =>
      [...scheduledReminderIds, immediateReminderId];

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

  Future<void> scheduleHydrationReminders(HydrationSettings settings) async {
    await initialize();
    await _cancelScheduledReminders();

    if (!settings.reminderEnabled) return;

    // Garante que permissões de notificação sejam solicitadas ao agendar
    await requestPermissions();

    final l10n = _l10n();
    final details = _getNotificationDetails(settings.reminderSoundStyle, l10n);
    final body = _body(l10n, settings.trackingEnabled);

    // Verifica se alarmes exatos são permitidos pelo SO
    final exactAllowed = await canScheduleExactAlarms();
    final scheduleMode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final hour in settings.scheduledHours) {
      if (hour < 0 || hour > 23) continue;
      final notificationId = reminderIdBase + hour;
      final timeFormatted = formatReminderHour(hour);

      try {
        final scheduledDate = AppNotificationCenter.nextInstanceOfHour(hour);
        final title = l10n.notifWaterTitleAt(timeFormatted);

        try {
          await _plugin.zonedSchedule(
            id: notificationId,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            payload: NotificationPayloads.openWaterModal,
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (e) {
          debugPrint('Aviso ao agendar com $scheduleMode: $e. Tentando modo inexato...');
          try {
            await _plugin.zonedSchedule(
              id: notificationId,
              title: title,
              body: body,
              scheduledDate: scheduledDate,
              notificationDetails: details,
              payload: NotificationPayloads.openWaterModal,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.time,
            );
          } catch (e2) {
            debugPrint('Erro fatal ao agendar lembrete das $timeFormatted: $e2');
          }
        }
      } catch (e) {
        debugPrint('Erro no cálculo de data do lembrete das $timeFormatted: $e');
      }
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
