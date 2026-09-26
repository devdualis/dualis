import 'dart:async';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';

/// Payloads carried by local notifications. A tap on a notification is routed
/// to whichever feature listens for its payload.
abstract final class NotificationPayloads {
  static const String openWaterModal = 'open_water_modal';
  static const String openCheckIn = 'open_checkin';
}

/// Resolves the IANA identifier of the device timezone.
typedef LocalTimezoneResolver = Future<String> Function();

/// Single owner of the [FlutterLocalNotificationsPlugin].
///
/// The plugin is a process-wide singleton whose platform layer keeps only the
/// *last* `onDidReceiveNotificationResponse` passed to `initialize()`. Every
/// feature therefore goes through this center, which:
///  * initializes the plugin exactly once (concurrent callers share a Future);
///  * configures the local timezone (no hardcoded country fallback);
///  * reads the launch details so a tap that cold-started the app is not lost;
///  * dispatches tap payloads to filtered streams, buffering payloads that
///    arrive before anyone listens and replaying them to the first matching
///    subscriber.
class AppNotificationCenter {
  AppNotificationCenter({
    required this.plugin,
    LocalTimezoneResolver? timezoneResolver,
  }) : _timezoneResolver = timezoneResolver ?? _platformTimezone;

  static final Expando<AppNotificationCenter> _byPlugin =
      Expando<AppNotificationCenter>('AppNotificationCenter');

  /// Returns the one center bound to [plugin], creating it on first use, so
  /// every service built on the same plugin shares one initialization and one
  /// tap dispatcher.
  static AppNotificationCenter of(FlutterLocalNotificationsPlugin plugin) =>
      _byPlugin[plugin] ??= AppNotificationCenter(plugin: plugin);

  final FlutterLocalNotificationsPlugin plugin;
  final LocalTimezoneResolver _timezoneResolver;

  Future<void>? _initialization;
  final List<_PayloadSubscriber> _subscribers = <_PayloadSubscriber>[];
  final List<String> _pendingPayloads = <String>[];

  static Future<String> _platformTimezone() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  /// Idempotent: the plugin is initialized once, however many callers race.
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    await _configureLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permissions are requested explicitly (requestPermissions) when reminders
    // are scheduled, never as a side effect of initializing at app start.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        ),
        onDidReceiveNotificationResponse: handleNotificationResponse,
      );
    } catch (e) {
      debugPrint('Notification plugin initialization failed: $e');
    }

    try {
      final launchDetails = await plugin.getNotificationAppLaunchDetails();
      final response = launchDetails?.notificationResponse;
      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          response != null) {
        handleNotificationResponse(response);
      }
    } catch (e) {
      debugPrint('Could not read notification launch details: $e');
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      tz_data.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone database initialization failed: $e');
      return;
    }

    try {
      final identifier = await _timezoneResolver();
      tz.setLocalLocation(tz.getLocation(identifier));
      return;
    } catch (e) {
      debugPrint('Device timezone unavailable ($e); using device UTC offset.');
    }

    final fallback = fallbackLocationForOffset(DateTime.now().timeZoneOffset);
    if (fallback != null) tz.setLocalLocation(fallback);
  }

  /// A zone matching the device's current UTC [offset], so reminders still
  /// fire at the right wall-clock hour when the IANA name is unavailable.
  /// Never assumes a country.
  static tz.Location? fallbackLocationForOffset(Duration offset) {
    if (offset.inMinutes % 60 == 0) {
      final hours = offset.inHours;
      // IANA "Etc/GMT" zones invert the sign: Etc/GMT+3 is UTC-03:00.
      final name = hours == 0
          ? 'Etc/UTC'
          : 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
      try {
        return tz.getLocation(name);
      } catch (_) {}
    }
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.currentTimeZone.offset == offset) return location;
    }
    return null;
  }

  /// Entry point for every tap, live or launch. Public so the plugin callback
  /// and tests share the same path.
  void handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _dispatch(payload);
  }

  void _dispatch(String payload) {
    final targets =
        _subscribers.where((s) => s.accepts(payload)).toList(growable: false);
    if (targets.isEmpty) {
      if (!_pendingPayloads.contains(payload)) _pendingPayloads.add(payload);
      return;
    }
    for (final target in targets) {
      target.controller.add(payload);
    }
  }

  /// Tap payloads accepted by [where]. Payloads that arrived while nobody was
  /// listening (e.g. the tap that launched the app) are delivered to the first
  /// matching subscriber and then consumed.
  Stream<String> payloads({bool Function(String payload)? where}) {
    final accepts = where ?? (_) => true;
    final controller = StreamController<String>();
    final subscriber = _PayloadSubscriber(accepts, controller);
    controller.onListen = () {
      _subscribers.add(subscriber);
      final replay = _pendingPayloads.where(accepts).toList(growable: false);
      _pendingPayloads.removeWhere(accepts);
      replay.forEach(controller.add);
    };
    controller.onCancel = () {
      _subscribers.remove(subscriber);
    };
    return controller.stream;
  }

  @visibleForTesting
  List<String> get pendingPayloads => List.unmodifiable(_pendingPayloads);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  Future<bool> requestPermissions() async {
    try {
      final android = _android;
      if (android != null) {
        return (await android.requestNotificationsPermission()) ?? false;
      }
      final ios = _ios;
      if (ios != null) {
        return (await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            )) ??
            false;
      }
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
    return true;
  }

  /// Whether Android currently allows exact alarms (false elsewhere).
  Future<bool> canScheduleExactAlarms() async {
    try {
      final android = _android;
      if (android != null) {
        return (await android.canScheduleExactNotifications()) ?? false;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Opens the Android "Alarms & reminders" settings screen.
  Future<void> requestExactAlarmsPermission() async {
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Exact alarm permission request failed: $e');
    }
  }

  /// Asks for exact-alarm access only on Android and only when it is missing.
  /// Meant for explicit user actions (enabling reminders / alarm style), not
  /// for every reschedule.
  Future<bool> ensureExactAlarmsPermission() async {
    if (_android == null) return false;
    if (await canScheduleExactAlarms()) return true;
    await requestExactAlarmsPermission();
    return canScheduleExactAlarms();
  }

  /// Next wall-clock occurrence of [hour]:00 in the local timezone that is
  /// strictly after [now]. With [dayOffset] > 0 the occurrence is forced onto
  /// that many days after [now]'s date. Built from calendar fields (not +24h)
  /// so DST transitions keep the wall-clock hour.
  static tz.TZDateTime nextInstanceOfHour(
    int hour, {
    tz.TZDateTime? now,
    int dayOffset = 0,
  }) {
    final current = now ?? tz.TZDateTime.now(tz.local);
    final location = current.location;
    if (dayOffset > 0) {
      return tz.TZDateTime(
        location,
        current.year,
        current.month,
        current.day + dayOffset,
        hour,
      );
    }
    final today =
        tz.TZDateTime(location, current.year, current.month, current.day, hour);
    if (today.isAfter(current)) return today;
    return tz.TZDateTime(
      location,
      current.year,
      current.month,
      current.day + 1,
      hour,
    );
  }
}

class _PayloadSubscriber {
  _PayloadSubscriber(this.accepts, this.controller);

  final bool Function(String payload) accepts;
  final StreamController<String> controller;
}

/// Notification texts in the app language, falling back to the device
/// language and finally English when [locale] is unsupported or absent.
AppLocalizations resolveNotificationLocalizations(Locale? locale) {
  final candidates = <Locale>[
    if (locale != null) locale,
    PlatformDispatcher.instance.locale,
    const Locale('en'),
  ];
  for (final candidate in candidates) {
    try {
      return lookupAppLocalizations(candidate);
    } catch (_) {}
  }
  return lookupAppLocalizations(const Locale('en'));
}

/// `HH:00`, used in reminder titles.
String formatReminderHour(int hour) => '${hour.toString().padLeft(2, '0')}:00';

/// One center per ProviderScope — the app has exactly one, so the plugin is
/// initialized once and every feature shares its tap dispatcher. Scoping it
/// to the container (rather than [AppNotificationCenter.of]'s process-wide
/// instance) keeps an initialization started in one scope — e.g. one widget
/// test's fake-async zone — from being awaited by another.
final appNotificationCenterProvider = Provider<AppNotificationCenter>((ref) {
  return AppNotificationCenter(plugin: FlutterLocalNotificationsPlugin());
});
