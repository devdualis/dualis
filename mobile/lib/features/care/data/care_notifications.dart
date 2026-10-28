import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/notifications/app_notification_center.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/locale_provider.dart';
import '../domain/care_models.dart';
import '../domain/pni_calendar.dart';

/// Local reminders for "Meus cuidados": the medication times, appointment
/// reminders and vaccine boosters the person chose. Texts only repeat what the
/// person typed; they never advise a dose.
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
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          l10n.careNotifChannelName,
          channelDescription: l10n.careNotifChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );
      final now = tz.TZDateTime.now(tz.local);
      final jobs = <_Job>[];

      for (final med in medications.where((m) => m.active)) {
        final body = [med.title, if (med.amountPerIntake != null) med.amountPerIntake!].join(' · ');
        for (final time in med.times) {
          final parts = time.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          if (med.weekdays.isEmpty) {
            var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
            if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
            jobs.add(_Job(l10n.careNotifMedTitle, body, at, DateTimeComponents.time));
          } else {
            for (final weekday in med.weekdays) {
              var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
              while (at.weekday != weekday || !at.isAfter(now)) {
                at = at.add(const Duration(days: 1));
              }
              jobs.add(_Job(l10n.careNotifMedTitle, body, at, DateTimeComponents.dayOfWeekAndTime));
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
        final who = appt.str('professional') ?? appt.str('specialty') ?? '';
        jobs.add(_Job(l10n.careNotifAppointmentTitle, l10n.careNotifAppointmentBody(who, _hhmm(startsAt)), tz.TZDateTime.from(at, tz.local), null));
      }

      for (final dose in vaccineDoses) {
        final booster = DateTime.tryParse(dose.str('boosterOn') ?? '');
        if (booster == null) continue;
        final at = tz.TZDateTime(tz.local, booster.year, booster.month, booster.day, 9);
        if (!at.isAfter(now)) continue;
        final name = dose.str('customName') ?? pniVaccineByKey(dose.str('vaccineKey'))?.name ?? '';
        jobs.add(_Job(l10n.careNotifBoosterTitle, l10n.careNotifBoosterBody(name), at, null));
      }

      final exact = await _center.canScheduleExactAlarms();
      for (var i = 0; i < jobs.length && i < maxPending; i++) {
        final job = jobs[i];
        await _center.plugin.zonedSchedule(
          id: _idBase + i,
          title: job.title,
          body: job.body,
          scheduledDate: job.at,
          notificationDetails: details,
          androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: job.repeat,
        );
      }
    } catch (e) {
      debugPrint('Care reminders not scheduled: $e');
    }
  }

  static String _hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _Job {
  final String title;
  final String body;
  final tz.TZDateTime at;
  final DateTimeComponents? repeat;
  const _Job(this.title, this.body, this.at, this.repeat);
}

final careNotificationServiceProvider = Provider<CareNotificationService>((ref) {
  return CareNotificationService(
    ref.watch(appNotificationCenterProvider),
    () => resolveNotificationLocalizations(ref.read(localeProvider)),
  );
});
