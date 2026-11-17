import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/app_notification_center.dart';
import '../data/care_api.dart';
import '../domain/care_models.dart';
import 'care_routes.dart';
import 'open_in_maps.dart';

/// Where a care notification button takes the person.
sealed class CareNotificationDestination {
  const CareNotificationDestination();
}

final class CareScreenDestination extends CareNotificationDestination {
  const CareScreenDestination(this.path);
  final String path;
}

final class CareMapsDestination extends CareNotificationDestination {
  const CareMapsDestination(this.place, {this.lat, this.lng});
  final String place;
  final double? lat;
  final double? lng;
}

/// The three payloads dispatched by care buttons that open the app.
bool isCareRoutePayload(String payload) =>
    payload == NotificationPayloads.openCareAppointments ||
    payload == NotificationPayloads.openCareVaccines ||
    NotificationPayloads.careDirectionsId(payload) != null;

typedef MapsLauncher = Future<bool> Function(
  String place, {
  double? lat,
  double? lng,
});

/// Opens the screen (or maps) for "Ver detalhes", "Como chegar" and
/// "Ver vacinas". The appointment place is read from the record here, never
/// from the notification.
class CareNotificationRouter {
  CareNotificationRouter({
    required Future<CareRecord?> Function(String id) loadAppointment,
    required void Function(String path) navigate,
    MapsLauncher? openMaps,
    this.timeout = const Duration(seconds: 6),
  })  : _loadAppointment = loadAppointment,
        _navigate = navigate,
        _openMaps = openMaps ?? openPlaceInMaps;

  final Future<CareRecord?> Function(String id) _loadAppointment;
  final void Function(String path) _navigate;
  final MapsLauncher _openMaps;
  final Duration timeout;

  /// Null for payloads that are not care routes.
  Future<CareNotificationDestination?> destinationFor(String payload) async {
    if (payload == NotificationPayloads.openCareAppointments) {
      return const CareScreenDestination(CarePaths.appointments);
    }
    if (payload == NotificationPayloads.openCareVaccines) {
      return const CareScreenDestination(CarePaths.vaccines);
    }
    final id = NotificationPayloads.careDirectionsId(payload);
    if (id == null) return null;
    try {
      final record = await _loadAppointment(id).timeout(timeout);
      final place = record?.str('place');
      if (record != null && place != null && place.trim().isNotEmpty) {
        return CareMapsDestination(
          place,
          lat: record.number('placeLat'),
          lng: record.number('placeLng'),
        );
      }
    } catch (e) {
      debugPrint('Appointment place not loaded: $e');
    }
    return const CareScreenDestination(CarePaths.appointments);
  }

  Future<void> handle(String payload) async {
    final destination = await destinationFor(payload);
    switch (destination) {
      case null:
        return;
      case CareScreenDestination(:final path):
        _navigate(path);
      case CareMapsDestination(:final place, :final lat, :final lng):
        var opened = false;
        try {
          opened = await _openMaps(place, lat: lat, lng: lng);
        } catch (e) {
          debugPrint('Maps not opened: $e');
        }
        if (!opened) _navigate(CarePaths.appointments);
    }
  }
}

/// Default loader: the person's appointments from the API, by id.
Future<CareRecord?> Function(String id) appointmentLoader(WidgetRef ref) =>
    (id) async {
      final records = await ref.read(careApiProvider).list(CareKind.appointment);
      for (final record in records) {
        if (record.id == id) return record;
      }
      return null;
    };
