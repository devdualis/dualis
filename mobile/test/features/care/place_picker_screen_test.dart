// The installed map/geocoder plugins expose their test interfaces separately.
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:dualis_mobile/features/care/presentation/screens/place_picker_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart'
    as maps;

class _MapPlatform extends maps.GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required maps.MapWidgetConfiguration widgetConfiguration,
    maps.MapConfiguration mapConfiguration = const maps.MapConfiguration(),
    maps.MapObjects mapObjects = const maps.MapObjects(),
  }) => const SizedBox.expand();
}

class _Geocoder extends geo.Geocoding {
  _Geocoder() : super.implementation(geo.GeocodingCreationParams());

  final requests = <(double, double, Completer<List<geo.Placemark>>)>[];

  @override
  Future<List<geo.Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    Locale? locale,
  }) {
    final result = Completer<List<geo.Placemark>>();
    requests.add((latitude, longitude, result));
    return result.future;
  }
}

class _GeocoderFactory extends geo.GeocodingPlatformFactory {
  _GeocoderFactory(this.geocoder);
  final _Geocoder geocoder;

  @override
  geo.Geocoding createGeocoding(geo.GeocodingCreationParams params) => geocoder;
}

void main() {
  late _Geocoder geocoder;

  setUp(() {
    final originalMap = maps.GoogleMapsFlutterPlatform.instance;
    final originalGeocoder = geo.GeocodingPlatformFactory.instance;
    maps.GoogleMapsFlutterPlatform.instance = _MapPlatform();
    geocoder = _Geocoder();
    geo.GeocodingPlatformFactory.instance = _GeocoderFactory(geocoder);
    addTearDown(() {
      maps.GoogleMapsFlutterPlatform.instance = originalMap;
      if (originalGeocoder != null) {
        geo.GeocodingPlatformFactory.instance = originalGeocoder;
      }
    });
  });

  const initial = PickedPlace('Old street', -23.56, -46.65);
  const moved = CameraPosition(target: LatLng(-23.59, -46.70), zoom: 17);
  const latest = CameraPosition(target: LatLng(-23.60, -46.71), zoom: 17);
  final usePlace = find.byKey(const Key('place_use'));

  Future<void> open(
    WidgetTester tester, {
    ValueChanged<PickedPlace?>? onPicked,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder:
              (context) => TextButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<PickedPlace>(
                    MaterialPageRoute(
                      builder: (_) => const PlacePickerScreen(initial: initial),
                    ),
                  );
                  onPicked?.call(result);
                },
                child: const Text('Open map'),
              ),
        ),
      ),
    );
    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
  }

  GoogleMap map(WidgetTester tester) =>
      tester.widget<GoogleMap>(find.byType(GoogleMap));
  VoidCallback? confirm(WidgetTester tester) =>
      tester.widget<FilledButton>(usePlace).onPressed;

  testWidgets(
    'moving the camera disables confirmation before the next idle lookup',
    (tester) async {
      await open(tester);
      expect(confirm(tester), isNotNull);
      map(tester).onCameraMove!(moved);
      await tester.pump();
      expect(confirm(tester), isNull);
      expect(find.text(initial.address), findsNothing);
    },
  );

  testWidgets(
    'camera movement starts invalidation before coordinates are delivered',
    (tester) async {
      await open(tester);
      map(tester).onCameraMoveStarted?.call();
      await tester.pump();
      expect(confirm(tester), isNull);
    },
  );

  testWidgets(
    'a stale address cannot re-enable confirmation or replace a newer selection',
    (tester) async {
      PickedPlace? saved;
      await open(tester, onPicked: (result) => saved = result);
      map(tester).onCameraMove!(moved);
      map(tester).onCameraIdle!();
      await tester.pump();
      expect(geocoder.requests.single.$1, moved.target.latitude);
      expect(geocoder.requests.single.$2, moved.target.longitude);

      map(tester).onCameraMove!(latest);
      geocoder.requests.first.$3.complete([
        const geo.Placemark(thoroughfare: 'Stale street'),
      ]);
      await tester.pump();
      expect(confirm(tester), isNull);
      expect(find.text('Stale street'), findsNothing);

      map(tester).onCameraIdle!();
      await tester.pump();
      geocoder.requests.last.$3.complete([
        const geo.Placemark(thoroughfare: 'Current street'),
      ]);
      await tester.pump();
      expect(confirm(tester), isNotNull);
      await tester.tap(usePlace);
      await tester.pumpAndSettle();
      expect(saved?.address, 'Current street');
      expect(saved?.lat, latest.target.latitude);
      expect(saved?.lng, latest.target.longitude);
    },
  );
}
