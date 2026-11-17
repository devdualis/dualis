import 'dart:async';

import 'package:dualis_mobile/core/notifications/app_notification_center.dart';
import 'package:dualis_mobile/features/care/domain/care_models.dart';
import 'package:dualis_mobile/features/care/presentation/care_notification_router.dart';
import 'package:dualis_mobile/features/care/presentation/care_routes.dart';
import 'package:flutter_test/flutter_test.dart';

CareRecord _appt(Map<String, dynamic> data) => CareRecord(
      id: 'appt-1',
      kind: CareKind.appointment,
      data: data,
      createdAt: DateTime(2026, 11, 17),
    );

class _Harness {
  _Harness(this.loader, {this.mapsResult = true});

  final Future<CareRecord?> Function(String id) loader;
  final bool mapsResult;
  final List<String> pushed = [];
  final List<(String, double?, double?)> maps = [];

  late final router = CareNotificationRouter(
    loadAppointment: loader,
    navigate: pushed.add,
    timeout: const Duration(milliseconds: 50),
    openMaps: (place, {lat, lng}) async {
      maps.add((place, lat, lng));
      return mapsResult;
    },
  );
}

void main() {
  test('isCareRoutePayload matches only the three care routes', () {
    expect(isCareRoutePayload(NotificationPayloads.openCareAppointments), isTrue);
    expect(isCareRoutePayload(NotificationPayloads.openCareVaccines), isTrue);
    expect(isCareRoutePayload(NotificationPayloads.careDirections('appt-1')), isTrue);
    for (final other in ['open_checkin', 'open_water_modal', 'care_appt|x',
        'care_vaccine', 'open_care_directions|', 'open_care_directions|a b']) {
      expect(isCareRoutePayload(other), isFalse, reason: other);
    }
  });

  test('appointments and vaccines payloads push their screens', () async {
    final h = _Harness((_) async => null);
    await h.router.handle(NotificationPayloads.openCareAppointments);
    await h.router.handle(NotificationPayloads.openCareVaccines);
    expect(h.pushed, [CarePaths.appointments, CarePaths.vaccines]);
    expect(h.maps, isEmpty);
  });

  test('directions open maps with the record place and coordinates', () async {
    final h = _Harness((id) async => id == 'appt-1'
        ? _appt({'place': 'Clinica Centro', 'placeLat': -23.5, 'placeLng': -46.6})
        : null);
    await h.router.handle(NotificationPayloads.careDirections('appt-1'));
    expect(h.maps, [('Clinica Centro', -23.5, -46.6)]);
    expect(h.pushed, isEmpty);
  });

  test('directions fall back to the appointments list', () async {
    final cases = <String, Future<CareRecord?> Function(String)>{
      'missing': (_) async => null,
      'no place': (_) async => _appt({'reminder': '1d'}),
      'throws': (_) async => throw Exception('offline'),
      'times out': (_) => Completer<CareRecord?>().future,
    };
    for (final entry in cases.entries) {
      final h = _Harness(entry.value);
      final destination = await h.router
          .destinationFor(NotificationPayloads.careDirections('appt-1'));
      expect(destination, isA<CareScreenDestination>(), reason: entry.key);
      expect((destination as CareScreenDestination).path, CarePaths.appointments);
    }
  });

  test('maps that cannot open fall back to the appointments list', () async {
    final h = _Harness((_) async => _appt({'place': 'X'}), mapsResult: false);
    await h.router.handle(NotificationPayloads.careDirections('appt-1'));
    expect(h.pushed, [CarePaths.appointments]);
  });

  test('other payloads go nowhere', () async {
    final h = _Harness((_) async => null);
    expect(await h.router.destinationFor('open_checkin'), isNull);
    await h.router.handle('open_water_modal');
    expect(h.pushed, isEmpty);
  });
}
