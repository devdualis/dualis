import 'dart:async';
import 'dart:ui' show DartPluginRegistrant, Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../../features/care/data/care_notifications.dart';
import '../../l10n/app_localizations.dart';
import 'app_notification_center.dart';
import 'hydration_notification_service.dart';
import 'notification_action_queue.dart';

/// Ids of the notification buttons. They come back from the OS on a tap.
abstract final class NotificationActionIds {
  static const String checkinOpen = 'checkin_open';
  static const String checkinLater = 'checkin_later';
  static const String waterDrank250 = 'water_drank_250';
  static const String waterSnoozeChimeTracking = 'water_snooze_chime_tracking';
  static const String waterSnoozeChime = 'water_snooze_chime';
  static const String waterSnoozeAlarm = 'water_snooze_alarm';
  static const String medTaken = 'med_taken';
  static const String medSnooze = 'med_snooze';
  static const String apptDetails = 'appt_details';
  static const String apptDirections = 'appt_directions';
  static const String vaccineOpen = 'vaccine_open';
  static const String vaccineTomorrow = 'vaccine_tomorrow';
}

/// iOS notification categories (one per button set), registered at init.
abstract final class NotificationCategoryIds {
  static const String checkin = 'dualis_checkin';
  static const String waterChimeTracking = 'dualis_water_chime_tracking';
  static const String waterChime = 'dualis_water_chime';
  static const String waterAlarm = 'dualis_water_alarm';
  static const String careMedication = 'dualis_care_medication';
  static const String careAppointmentPlace = 'dualis_care_appointment_place';
  static const String careAppointment = 'dualis_care_appointment';
  static const String careVaccine = 'dualis_care_vaccine';
}

const Set<DarwinNotificationActionOption> _foreground =
    <DarwinNotificationActionOption>{DarwinNotificationActionOption.foreground};

/// Every iOS category with its approved buttons (two at most). Only the
/// buttons that open a screen bring the app to the foreground.
List<DarwinNotificationCategory> darwinNotificationCategories(
  AppLocalizations l10n,
) {
  DarwinNotificationAction background(String id, String title) =>
      DarwinNotificationAction.plain(id, title);
  DarwinNotificationAction foreground(String id, String title) =>
      DarwinNotificationAction.plain(id, title, options: _foreground);

  DarwinNotificationCategory water(String categoryId, String snoozeId) =>
      DarwinNotificationCategory(categoryId, actions: [
        background(NotificationActionIds.waterDrank250, l10n.notifActionWaterDrank),
        background(snoozeId, l10n.notifActionSnooze30),
      ]);

  return <DarwinNotificationCategory>[
    DarwinNotificationCategory(NotificationCategoryIds.checkin, actions: [
      foreground(NotificationActionIds.checkinOpen, l10n.notifActionCheckinStart),
      background(NotificationActionIds.checkinLater, l10n.notifActionLater),
    ]),
    water(NotificationCategoryIds.waterChimeTracking,
        NotificationActionIds.waterSnoozeChimeTracking),
    water(NotificationCategoryIds.waterChime,
        NotificationActionIds.waterSnoozeChime),
    water(NotificationCategoryIds.waterAlarm,
        NotificationActionIds.waterSnoozeAlarm),
    DarwinNotificationCategory(NotificationCategoryIds.careMedication, actions: [
      background(NotificationActionIds.medTaken, l10n.notifActionMedTaken),
      background(NotificationActionIds.medSnooze, l10n.notifActionSnooze15),
    ]),
    DarwinNotificationCategory(NotificationCategoryIds.careAppointmentPlace,
        actions: [
          foreground(NotificationActionIds.apptDetails, l10n.notifActionSeeDetails),
          foreground(
              NotificationActionIds.apptDirections, l10n.notifActionDirections),
        ]),
    DarwinNotificationCategory(NotificationCategoryIds.careAppointment, actions: [
      foreground(NotificationActionIds.apptDetails, l10n.notifActionSeeDetails),
    ]),
    DarwinNotificationCategory(NotificationCategoryIds.careVaccine, actions: [
      foreground(NotificationActionIds.vaccineOpen, l10n.notifActionSeeVaccines),
      background(
          NotificationActionIds.vaccineTomorrow, l10n.notifActionRemindTomorrow),
    ]),
  ];
}

/// Payloads of scheduled care reminders. They hold record ids and times only:
/// the OS stores them with pending notifications, so never a medication,
/// vaccine or specialty name and never the appointment place.
abstract final class CarePayloads {
  static const String _med = 'care_med';
  static const String _appt = 'care_appt';
  static const String vaccine = 'care_vaccine';

  static final RegExp _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final RegExp _id = RegExp(r'^[A-Za-z0-9_-]+$');

  static String medication(String id, String hhmm) => '$_med|$id|$hhmm';

  static String appointment(String id) => '$_appt|$id';

  /// Null on anything malformed.
  static ({String id, String hhmm})? parseMedication(String? payload) {
    final parts = payload?.split('|');
    if (parts == null || parts.length != 3 || parts[0] != _med) return null;
    if (!_id.hasMatch(parts[1]) || !_hhmm.hasMatch(parts[2])) return null;
    return (id: parts[1], hhmm: parts[2]);
  }

  /// Null on anything malformed.
  static String? parseAppointment(String? payload) {
    final parts = payload?.split('|');
    if (parts == null || parts.length != 2 || parts[0] != _appt) return null;
    return _id.hasMatch(parts[1]) ? parts[1] : null;
  }
}

enum SnoozeKind { water, medication, vaccine }

/// What a notification button resolves to.
sealed class NotificationActionEffect {
  const NotificationActionEffect();
}

/// Foreground button: the app opens on the screen for [payload].
final class OpenInApp extends NotificationActionEffect {
  const OpenInApp(this.payload);
  final String payload;
}

/// Background button that records something: queued, applied later by the
/// main isolate.
final class EnqueueAction extends NotificationActionEffect {
  const EnqueueAction(this.action);
  final PendingNotificationAction action;
}

/// Background button that shows the same reminder once more at [at].
final class Snooze extends NotificationActionEffect {
  const Snooze({
    required this.kind,
    required this.id,
    required this.at,
    required this.payload,
    this.waterVariant,
  });

  final SnoozeKind kind;
  final int id;
  final DateTime at;
  final String payload;
  final WaterReminderVariant? waterVariant;
}

/// Nothing to do beyond the dismissal the OS already did.
final class Dismiss extends NotificationActionEffect {
  const Dismiss();
}

/// First care id (see CareNotificationService) and its slot count.
const int _careIdBase = 6000;
const int _careSlots = 30;

/// Medication snooze id: the original slot + 100, so a care reschedule (which
/// cancels 6000-6029 only) never kills a pending snooze.
int careSnoozeId(int? id) {
  const snoozeBase = _careIdBase + 100;
  if (id != null && id >= _careIdBase && id < _careIdBase + _careSlots) {
    return id + 100;
  }
  if (id != null && id >= snoozeBase && id < snoozeBase + _careSlots) return id;
  return snoozeBase + _careSlots;
}

/// Vaccine snooze id: 6200 + the original slot offset.
int vaccineSnoozeId(int? id) {
  const snoozeBase = _careIdBase + 200;
  if (id != null && id >= _careIdBase && id < _careIdBase + _careSlots) {
    return snoozeBase + (id - _careIdBase);
  }
  if (id != null && id >= snoozeBase && id < snoozeBase + _careSlots) return id;
  return snoozeBase + _careSlots;
}

/// The most recent local occurrence of [hhmm] at or before [actionAt], built
/// from calendar fields (yesterday when today's slot is still ahead). Null
/// when [hhmm] is malformed.
DateTime? medicationScheduledFor(String hhmm, DateTime actionAt) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  final local = actionAt.toLocal();
  final today = DateTime(local.year, local.month, local.day, hour, minute);
  if (!today.isAfter(local)) return today;
  return DateTime(local.year, local.month, local.day - 1, hour, minute);
}

/// Maps a button tap to its effect. Pure: unknown ids and malformed payloads
/// resolve to [Dismiss].
NotificationActionEffect resolveNotificationAction({
  String? actionId,
  String? payload,
  int? notificationId,
  required DateTime now,
  String Function()? newId,
}) {
  String id() => (newId ?? const Uuid().v4)();

  Snooze waterSnooze(WaterReminderVariant variant) => Snooze(
        kind: SnoozeKind.water,
        id: HydrationNotificationService.snoozeReminderId,
        at: now.add(const Duration(minutes: 30)),
        payload: NotificationPayloads.openWaterModal,
        waterVariant: variant,
      );

  switch (actionId) {
    case NotificationActionIds.checkinOpen:
      return const OpenInApp(NotificationPayloads.openCheckIn);
    case NotificationActionIds.checkinLater:
      return const Dismiss();
    case NotificationActionIds.waterDrank250:
      return EnqueueAction(PendingNotificationAction(
        id: id(),
        kind: PendingNotificationActionKind.water,
        at: now,
        amountMl: 250,
      ));
    case NotificationActionIds.waterSnoozeChimeTracking:
      return waterSnooze(WaterReminderVariant.chimeTracking);
    case NotificationActionIds.waterSnoozeChime:
      return waterSnooze(WaterReminderVariant.chimeReminder);
    case NotificationActionIds.waterSnoozeAlarm:
      return waterSnooze(WaterReminderVariant.alarm);
    case NotificationActionIds.medTaken:
      final med = CarePayloads.parseMedication(payload);
      final scheduledFor =
          med == null ? null : medicationScheduledFor(med.hhmm, now);
      if (med == null || scheduledFor == null) return const Dismiss();
      return EnqueueAction(PendingNotificationAction(
        id: id(),
        kind: PendingNotificationActionKind.medicationTaken,
        at: now,
        medicationId: med.id,
        scheduledFor: scheduledFor,
      ));
    case NotificationActionIds.medSnooze:
      if (CarePayloads.parseMedication(payload) == null) return const Dismiss();
      return Snooze(
        kind: SnoozeKind.medication,
        id: careSnoozeId(notificationId),
        at: now.add(const Duration(minutes: 15)),
        payload: payload!,
      );
    case NotificationActionIds.apptDetails:
      return const OpenInApp(NotificationPayloads.openCareAppointments);
    case NotificationActionIds.apptDirections:
      final apptId = CarePayloads.parseAppointment(payload);
      return OpenInApp(apptId == null
          ? NotificationPayloads.openCareAppointments
          : NotificationPayloads.careDirections(apptId));
    case NotificationActionIds.vaccineOpen:
      return const OpenInApp(NotificationPayloads.openCareVaccines);
    case NotificationActionIds.vaccineTomorrow:
      return Snooze(
        kind: SnoozeKind.vaccine,
        id: vaccineSnoozeId(notificationId),
        at: now.add(const Duration(hours: 24)),
        payload: CarePayloads.vaccine,
      );
  }
  return const Dismiss();
}

/// Applies an effect: queues recorded actions and schedules snoozes. Never
/// throws, so a failure in the background engine cannot crash anything.
class NotificationActionExecutor {
  NotificationActionExecutor({
    required this.plugin,
    required this.queue,
    required FutureOr<AppLocalizations> Function() l10n,
  }) : _l10n = l10n;

  final FlutterLocalNotificationsPlugin plugin;
  final NotificationActionQueue queue;
  final FutureOr<AppLocalizations> Function() _l10n;

  Future<void> execute(NotificationActionEffect effect) async {
    try {
      switch (effect) {
        case EnqueueAction(:final action):
          await queue.add(action);
        case Snooze():
          await _snooze(effect);
        case OpenInApp():
        case Dismiss():
          break;
      }
    } catch (e) {
      debugPrint('Notification action failed: $e');
    }
  }

  Future<void> _snooze(Snooze snooze) async {
    final l10n = await _l10n();
    final NotificationDetails details;
    final String title;
    final String body;
    switch (snooze.kind) {
      case SnoozeKind.water:
        final variant = snooze.waterVariant ?? WaterReminderVariant.chimeReminder;
        details = HydrationNotificationService.notificationDetails(variant, l10n);
        title = HydrationNotificationService.title(variant, l10n);
        body = HydrationNotificationService.body(variant, l10n);
      case SnoozeKind.medication:
        details = CareNotificationService.medicationDetails(l10n);
        title = l10n.careNotifMedTitle;
        body = l10n.careNotifMedBody;
      case SnoozeKind.vaccine:
        details = CareNotificationService.vaccineDetails(l10n);
        title = l10n.careNotifBoosterTitle;
        body = l10n.careNotifBoosterBody;
    }

    // A UTC instant needs no timezone database (the background engine has
    // none loaded).
    final scheduledDate = tz.TZDateTime.from(snooze.at, tz.UTC);
    final exact = await _canScheduleExact();
    Future<void> schedule(AndroidScheduleMode mode) => plugin.zonedSchedule(
          id: snooze.id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          payload: snooze.payload,
          androidScheduleMode: mode,
          matchDateTimeComponents: null,
        );
    try {
      await schedule(exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle);
    } catch (e) {
      if (!exact) rethrow;
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<bool> _canScheduleExact() async {
    try {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return (await android?.canScheduleExactNotifications()) ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Runs in a separate engine for buttons that do not open the app. Opens no
/// database and reads no auth state: it only queues the action or schedules a
/// snooze. The main isolate drains the queue on start, resume and reconnect.
@pragma('vm:entry-point')
Future<void> notificationActionBackgroundHandler(
  NotificationResponse response,
) async {
  if (response.notificationResponseType !=
      NotificationResponseType.selectedNotificationAction) {
    return;
  }
  try {
    DartPluginRegistrant.ensureInitialized();
    final queue = FileNotificationActionQueue();
    final effect = resolveNotificationAction(
      actionId: response.actionId,
      payload: response.payload,
      notificationId: response.id,
      now: DateTime.now(),
    );
    final executor = NotificationActionExecutor(
      plugin: FlutterLocalNotificationsPlugin(),
      queue: queue,
      l10n: () async {
        final code = await queue.readLanguageCode();
        return resolveNotificationLocalizations(
          code == null ? null : Locale(code),
        );
      },
    );
    await executor.execute(effect);
  } catch (e) {
    debugPrint('Background notification action failed: $e');
  }
}
