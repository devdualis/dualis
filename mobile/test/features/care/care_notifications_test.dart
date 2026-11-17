import 'dart:ui' show Color, Locale;

import 'package:dualis_mobile/core/constants/app_colors.dart';
import 'package:dualis_mobile/core/notifications/app_notification_center.dart';
import 'package:dualis_mobile/features/care/data/care_notifications.dart';
import 'package:dualis_mobile/features/care/domain/care_models.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _FakeInitSettings extends Fake implements InitializationSettings {}

class _FakeTZDateTime extends Fake implements tz.TZDateTime {}

class _Harness {
  _Harness() {
    when(() => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
          onDidReceiveBackgroundNotificationResponse:
              any(named: 'onDidReceiveBackgroundNotificationResponse'),
        )).thenAnswer((_) async => true);
    when(() => plugin.getNotificationAppLaunchDetails())
        .thenAnswer((_) async => null);
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
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
    final center = AppNotificationCenter(
      plugin: plugin,
      timezoneResolver: () async => 'UTC',
    );
    service = CareNotificationService(
      center,
      () => lookupAppLocalizations(const Locale('pt')),
    );
  }

  final _MockPlugin plugin = _MockPlugin();
  late final CareNotificationService service;
  final List<Map<Symbol, dynamic>> scheduled = [];

  Future<void> run({
    List<Medication> medications = const [],
    List<CareRecord> appointments = const [],
    List<CareRecord> vaccineDoses = const [],
  }) =>
      service.reschedule(
        medications: medications,
        appointments: appointments,
        vaccineDoses: vaccineDoses,
      );
}

CareRecord _record(
  CareKind kind,
  Map<String, dynamic> data, {
  DateTime? occursAt,
}) =>
    CareRecord(
      id: 'r-${kind.apiName}',
      kind: kind,
      data: data,
      createdAt: DateTime.now(),
      occursAt: occursAt,
    );

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(_FakeInitSettings());
    registerFallbackValue(_FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(DateTimeComponents.time);
  });

  test('medication reminder never shows name, strength or amount', () async {
    final h = _Harness();
    await h.run(medications: [
      Medication(_record(CareKind.medication, {
        'name': 'Losartana',
        'strength': '50 mg',
        'amountPerIntake': '2 comprimidos',
        'times': ['08:00'],
        'weekdays': <int>[],
      })),
    ]);
    expect(h.scheduled, hasLength(1));
    final call = h.scheduled.single;
    expect(call[#title], 'Hora do seu medicamento');
    expect(call[#body], 'Toque para ver o lembrete.');
    final text = '${call[#title]} ${call[#body]}';
    for (final secret in ['Losartana', '50 mg', 'comprimidos']) {
      expect(text, isNot(contains(secret)));
    }
    // The payload holds the record id and HH:mm only.
    final payload = call[#payload] as String;
    expect(payload, 'care_med|r-medication|08:00');
    for (final secret in ['Losartana', '50 mg', 'comprimidos']) {
      expect(payload, isNot(contains(secret)));
    }
  });

  test('medication reminder carries Tomei and Adiar 15 min in the background',
      () async {
    final h = _Harness();
    await h.run(medications: [
      Medication(_record(CareKind.medication, {
        'name': 'X',
        'times': ['8:05'],
        'weekdays': <int>[1, 3],
      })),
    ]);
    expect(h.scheduled, hasLength(2));
    for (final call in h.scheduled) {
      expect(call[#payload], 'care_med|r-medication|08:05');
      final details = call[#notificationDetails] as NotificationDetails;
      final actions = details.android!.actions!;
      expect(actions.map((a) => a.id), ['med_taken', 'med_snooze']);
      expect(actions.map((a) => a.title), ['Tomei', 'Adiar 15 min']);
      expect(actions.every((a) => !a.showsUserInterface), isTrue);
      expect(details.iOS!.categoryIdentifier, 'dualis_care_medication');
      expect(call[#title], 'Hora do seu medicamento');
      expect(call[#body], 'Toque para ver o lembrete.');
    }
  });

  test('appointment reminder says Tomorrow for 1d and Today for 2h, no names',
      () async {
    final h = _Harness();
    final now = DateTime.now();
    final startsAt = DateTime(now.year, now.month, now.day + 3, 14, 30);
    CareRecord appt(String reminder) => _record(
          CareKind.appointment,
          {
            'professional': 'Dra. Helena Souza',
            'specialty': 'Cardiologia',
            'reminder': reminder,
          },
          occursAt: startsAt,
        );
    await h.run(appointments: [appt('1d')]);
    expect(h.scheduled.single[#body], 'Amanhã às 14:30');

    h.scheduled.clear();
    await h.run(appointments: [appt('2h')]);
    expect(h.scheduled.single[#body], 'Hoje às 14:30');

    final text = '${h.scheduled.single[#title]} ${h.scheduled.single[#body]}';
    expect(text, isNot(contains('Helena')));
    expect(text, isNot(contains('Cardiologia')));
  });

  test('vaccine booster reminder never shows the vaccine name', () async {
    final h = _Harness();
    final booster = DateTime.now().add(const Duration(days: 10));
    await h.run(vaccineDoses: [
      _record(CareKind.vaccineDose, {
        'customName': 'Vacina Secreta XYZ',
        'boosterOn': _ymd(booster),
      }),
    ]);
    final call = h.scheduled.single;
    expect(call[#title], 'Lembrete de vacina');
    expect(call[#body], 'Hoje é a data que você escolheu.');
    expect('${call[#title]} ${call[#body]}', isNot(contains('Secreta')));
  });

  test('every care notification uses the care channel, icon and green color',
      () async {
    final h = _Harness();
    final now = DateTime.now();
    await h.run(
      medications: [
        Medication(_record(CareKind.medication, {
          'name': 'X',
          'times': ['09:00'],
        })),
      ],
      appointments: [
        _record(
          CareKind.appointment,
          {'reminder': '1d'},
          occursAt: DateTime(now.year, now.month, now.day + 3, 10),
        ),
      ],
      vaccineDoses: [
        _record(CareKind.vaccineDose, {
          'boosterOn': _ymd(now.add(const Duration(days: 10))),
        }),
      ],
    );
    expect(h.scheduled, hasLength(3));
    for (final call in h.scheduled) {
      final android = (call[#notificationDetails] as NotificationDetails).android!;
      expect(android.channelId, CareNotificationService.channelId);
      expect(android.icon, 'ic_stat_dualis');
      expect(android.color, AppColors.dualisCareGreen);
      expect(android.color, const Color(0xFF3E8E4A));
      expect(android.importance, Importance.high);
    }
  });

  test('no notification copy contains an emoji in pt, es or en', () {
    final emoji = RegExp('[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    for (final code in ['pt', 'es', 'en']) {
      final l = lookupAppLocalizations(Locale(code));
      final strings = <String>[
        l.notifCheckinTitle,
        l.notifCheckinBody,
        l.notifCheckinChannelName,
        l.notifCheckinChannelDescription,
        l.notifWaterTitle,
        l.notifWaterBodyTracking,
        l.notifWaterBodyReminder,
        l.notifWaterAlarmTitle,
        l.notifWaterAlarmBody,
        l.notifWaterChimeChannelName,
        l.notifWaterChimeChannelDescription,
        l.notifWaterAlarmChannelName,
        l.notifWaterAlarmChannelDescription,
        l.careNotifChannelName,
        l.careNotifChannelDescription,
        l.careNotifMedTitle,
        l.careNotifMedBody,
        l.careNotifAppointmentTitle,
        l.careNotifAppointmentBodyToday('14:30'),
        l.careNotifAppointmentBodyTomorrow('14:30'),
        l.careNotifBoosterTitle,
        l.careNotifBoosterBody,
      ];
      for (final s in strings) {
        expect(emoji.hasMatch(s), isFalse, reason: '$code: $s');
      }
    }
  });
}
