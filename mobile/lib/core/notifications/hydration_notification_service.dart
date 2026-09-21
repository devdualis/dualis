import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/hydration/domain/models/hydration_settings.dart';

typedef HydrationModalCallback = void Function();

class HydrationNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final StreamController<String> _notificationPayloadController =
      StreamController<String>.broadcast();

  static const String chimeChannelId = 'dualis_hydration_chime';
  static const String chimeChannelName = 'Lembretes de Água (Aviso Suave)';

  static const String alarmChannelId = 'dualis_hydration_alarm';
  static const String alarmChannelName = 'Lembretes de Água (Alarme Sonoro)';

  bool _isInitialized = false;

  HydrationNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  Stream<String> get onNotificationOpened =>
      _notificationPayloadController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _notificationPayloadController.add(payload);
        }
      },
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  NotificationDetails _getNotificationDetails(ReminderSoundStyle style) {
    if (style == ReminderSoundStyle.phoneAlarm) {
      return const NotificationDetails(
        android: AndroidNotificationDetails(
          alarmChannelId,
          alarmChannelName,
          channelDescription:
              'Alarme sonoro para lembrar de beber água a cada 2 horas',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );
    }

    return const NotificationDetails(
      android: AndroidNotificationDetails(
        chimeChannelId,
        chimeChannelName,
        channelDescription:
            'Aviso de chegada estilo mensagem para lembrete de hidratação',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
  }

  Future<void> scheduleHydrationReminders(HydrationSettings settings) async {
    await initialize();
    await cancelAllReminders();

    if (!settings.reminderEnabled) return;

    final details = _getNotificationDetails(settings.reminderSoundStyle);

    for (final hour in settings.scheduledHours) {
      final notificationId = 1000 + hour;
      final timeFormatted = '${hour.toString().padLeft(2, '0')}:00';

      try {
        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          0,
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: '💧 Hora de Beber Água ($timeFormatted)',
          body: settings.trackingEnabled
              ? 'Toque para registrar a quantidade de água consumida.'
              : 'Mantenha seu corpo hidratado e saudável!',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          payload: 'open_water_modal',
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('Erro ao agendar lembrete das $timeFormatted: $e');
      }
    }
  }

  Future<void> showImmediateReminder({
    required ReminderSoundStyle style,
    required bool trackingEnabled,
    String? customBody,
  }) async {
    await initialize();
    final details = _getNotificationDetails(style);

    await _notificationsPlugin.show(
      id: 9999,
      title: '💧 Hora de Beber Água',
      body: customBody ??
          (trackingEnabled
              ? 'Toque para registrar a quantidade de água consumida.'
              : 'Mantenha seu corpo hidratado e saudável!'),
      notificationDetails: details,
      payload: 'open_water_modal',
    );
  }

  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  void dispose() {
    _notificationPayloadController.close();
  }
}

final hydrationNotificationServiceProvider =
    Provider<HydrationNotificationService>((ref) {
  final service = HydrationNotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});
