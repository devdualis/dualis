import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/notifications/app_notification_center.dart';
import '../../../core/notifications/notification_actions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/locale_provider.dart';
import '../domain/care_models.dart';

/// Local reminders for "Meus cuidados": the medication times, appointment
/// reminders and vaccine boosters the person chose. Notification texts never
/// show medication, vaccine or specialty names (they stay readable on the lock
/// screen) and never advise a dose.
class CareNotificationService {
  CareNotificationService(this._center, this._l10n);

  final AppNotificationCenter _center;
  final AppLocalizations Function() _l10n;

  static const String channelId = 'dualis_care_reminders';
  static const int _idBase = 6000;

  /// iOS keeps at most 64 pending notifications for the whole app; check-in and
  /// water reminders use part of them.
  static const int maxPending = 30;

  Future<void> reschedule({
    required List<Medication> medications,
    required List<CareRecord> appointments,
    required List<CareRecord> vaccineDoses,
  }) async {
    try {
      await _center.initialize();
      for (var i = 0; i < maxPending; i++) {
        await _center.plugin.cancel(id: _idBase + i);
      }
      final l10n = _l10n();
      final medDetails = medicationDetails(l10n);
      final apptDetails = appointmentDetails(l10n, hasPlace: false);
      final apptPlaceDetails = appointmentDetails(l10n, hasPlace: true);
      final boosterDetails = vaccineDetails(l10n);
      final now = tz.TZDateTime.now(tz.local);
      final jobs = <_Job>[];

      for (final med in medications.where((m) => m.active)) {
        final body = l10n.careNotifMedBody;
        for (final time in med.times) {
          final parts = time.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          // Record id and HH:mm only, never the medication name.
          final payload = CarePayloads.medication(
            med.id,
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
          );
          if (med.weekdays.isEmpty) {
            var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
            if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
            jobs.add(_Job(l10n.careNotifMedTitle, body, at, DateTimeComponents.time, medDetails, payload));
          } else {
            for (final weekday in med.weekdays) {
              var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
              while (at.weekday != weekday || !at.isAfter(now)) {
                at = at.add(const Duration(days: 1));
              }
              jobs.add(_Job(l10n.careNotifMedTitle, body, at, DateTimeComponents.dayOfWeekAndTime, medDetails, payload));
            }
          }
        }
      }

      for (final appt in appointments) {
        final startsAt = appt.occursAt?.toLocal();
        final reminder = appt.str('reminder');
        if (startsAt == null || reminder == null || reminder == 'none') continue;
        final at = startsAt.subtract(reminder == '1d' ? const Duration(days: 1) : const Duration(hours: 2));
        if (!at.isAfter(now)) continue;
        final sameDay = at.year == startsAt.year && at.month == startsAt.month && at.day == startsAt.day;
        final body = sameDay
            ? l10n.careNotifAppointmentBodyToday(_hhmm(startsAt))
            : l10n.careNotifAppointmentBodyTomorrow(_hhmm(startsAt));
        // "Como chegar" only when there is a place; the place itself never goes
        // into the payload (the app reads it from the record).
        final hasPlace = appt.str('place') != null;
        jobs.add(_Job(
          l10n.careNotifAppointmentTitle,
          body,
          tz.TZDateTime.from(at, tz.local),
          null,
          hasPlace ? apptPlaceDetails : apptDetails,
          CarePayloads.appointment(appt.id),
        ));
      }

      for (final dose in vaccineDoses) {
        final booster = DateTime.tryParse(dose.str('boosterOn') ?? '');
        if (booster == null) continue;
        final at = tz.TZDateTime(tz.local, booster.year, booster.month, booster.day, 9);
        if (!at.isAfter(now)) continue;
        jobs.add(_Job(l10n.careNotifBoosterTitle, l10n.careNotifBoosterBody, at, null, boosterDetails, CarePayloads.vaccine));
      }

      final exact = await _center.canScheduleExactAlarms();
      for (var i = 0; i < jobs.length && i < maxPending; i++) {
        final job = jobs[i];
        await _center.plugin.zonedSchedule(
          id: _idBase + i,
          title: job.title,
          body: job.body,
          scheduledDate: job.at,
          notificationDetails: job.details,
          payload: job.payload,
          androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: job.repeat,
        );
      }
    } catch (e) {
      debugPrint('Care reminders not scheduled: $e');
    }
  }

  static AndroidNotificationDetails _android(
    AppLocalizations l10n, {
    List<AndroidNotificationAction>? actions,
  }) =>
      AndroidNotificationDetails(
        channelId,
        l10n.careNotifChannelName,
        channelDescription: l10n.careNotifChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        icon: NotificationStyle.androidSmallIcon,
        color: NotificationStyle.careColor,
        actions: actions,
      );

  /// "Tomei" and "Adiar 15 min", both handled without opening the app.
  static NotificationDetails medicationDetails(AppLocalizations l10n) =>
      NotificationDetails(
        android: _android(l10n, actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            NotificationActionIds.medTaken,
            l10n.notifActionMedTaken,
          ),
          AndroidNotificationAction(
            NotificationActionIds.medSnooze,
            l10n.notifActionSnooze15,
          ),
        ]),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          categoryIdentifier: NotificationCategoryIds.careMedication,
        ),
      );

  /// "Ver detalhes", plus "Como chegar" when the appointment has a place.
  /// Both open the app.
  static NotificationDetails appointmentDetails(
    AppLocalizations l10n, {
    required bool hasPlace,
  }) =>
      NotificationDetails(
        android: _android(l10n, actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            NotificationActionIds.apptDetails,
            l10n.notifActionSeeDetails,
            showsUserInterface: true,
          ),
          if (hasPlace)
            AndroidNotificationAction(
              NotificationActionIds.apptDirections,
              l10n.notifActionDirections,
              showsUserInterface: true,
            ),
        ]),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          categoryIdentifier: hasPlace
              ? NotificationCategoryIds.careAppointmentPlace
              : NotificationCategoryIds.careAppointment,
        ),
      );

  /// "Ver vacinas" opens the app; "Lembrar amanhã" re-notifies in 24 h.
  static NotificationDetails vaccineDetails(AppLocalizations l10n) =>
      NotificationDetails(
        android: _android(l10n, actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            NotificationActionIds.vaccineOpen,
            l10n.notifActionSeeVaccines,
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            NotificationActionIds.vaccineTomorrow,
            l10n.notifActionRemindTomorrow,
          ),
        ]),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          categoryIdentifier: NotificationCategoryIds.careVaccine,
        ),
      );

  static String _hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _Job {
  final String title;
  final String body;
  final tz.TZDateTime at;
  final DateTimeComponents? repeat;
  final NotificationDetails details;
  final String? payload;
  const _Job(this.title, this.body, this.at, this.repeat, this.details, this.payload);
}

final careNotificationServiceProvider = Provider<CareNotificationService>((ref) {
  return CareNotificationService(
    ref.watch(appNotificationCenterProvider),
    () => resolveNotificationLocalizations(ref.read(localeProvider)),
  );
});
