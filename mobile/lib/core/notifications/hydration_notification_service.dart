import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (tzErr) {
        debugPrint('Aviso ao carregar timezone via FlutterTimezone ($tzErr). Usando fallback America/Sao_Paulo');
        try {
          tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Aviso ao inicializar timezones: $e');
    }

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

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _notificationPayloadController.add(payload);
          }
        },
      );
    } catch (e) {
      debugPrint('Erro ao inicializar plugin de notificações: $e');
    }

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    try {
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
    } catch (e) {
      debugPrint('Erro ao solicitar permissões de notificação: $e');
      return false;
    }

    return true;
  }

  /// Verifica se o dispositivo Android permite o agendamento de alarmes exatos
  Future<bool> canScheduleExactAlarms() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return (await androidImpl.canScheduleExactNotifications()) ?? false;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Abre a tela do sistema para conceder permissão de alarmes exatos (Android 13+)
  Future<void> requestExactAlarmsPermission() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Erro ao solicitar permissão de alarme exato: $e');
    }
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

    // Garante que permissões de notificação sejam solicitadas ao agendar
    await requestPermissions();

    final details = _getNotificationDetails(settings.reminderSoundStyle);

    // Verifica se alarmes exatos são permitidos pelo SO
    final exactAllowed = await canScheduleExactAlarms();
    final scheduleMode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

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

        try {
          await _notificationsPlugin.zonedSchedule(
            id: notificationId,
            title: '💧 Hora de Beber Água ($timeFormatted)',
            body: settings.trackingEnabled
                ? 'Toque para registrar a quantidade de água consumida.'
                : 'Mantenha seu corpo hidratado e saudável!',
            scheduledDate: scheduledDate,
            notificationDetails: details,
            payload: 'open_water_modal',
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (e) {
          debugPrint('Aviso ao agendar com $scheduleMode: $e. Tentando modo inexato...');
          try {
            await _notificationsPlugin.zonedSchedule(
              id: notificationId,
              title: '💧 Hora de Beber Água ($timeFormatted)',
              body: settings.trackingEnabled
                  ? 'Toque para registrar a quantidade de água consumida.'
                  : 'Mantenha seu corpo hidratado e saudável!',
              scheduledDate: scheduledDate,
              notificationDetails: details,
              payload: 'open_water_modal',
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
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Erro ao cancelar lembretes anteriores: $e');
    }
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
