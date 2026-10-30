import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/care_widgets.dart';

/// A place the person picked on the map: the address shown in the field and its point.
class PickedPlace {
  const PickedPlace(this.address, this.lat, this.lng);
  final String address;
  final double lat;
  final double lng;
}

/// Opens the map picker. Overridable in tests (the map is a native view).
typedef PlacePicker = Future<PickedPlace?> Function(BuildContext context, {String query, PickedPlace? initial});

final placePickerProvider = Provider<PlacePicker>(
  (ref) => (context, {query = '', initial}) => Navigator.of(context).push<PickedPlace>(
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => PlacePickerScreen(query: query, initial: initial)),
      ),
);

/// Below this zoom the pin covers whole neighbourhoods, so no address is offered.
const _streetZoom = 15.0;

/// Brazil, zoomed out, when there is nothing to search for yet.
const _fallback = CameraPosition(target: LatLng(-14.2, -51.9), zoom: 4);

/// "Rua X, 123 – Bairro, Cidade" from what the phone's geocoder returns.
String placemarkAddress(Placemark p) {
  final street = [p.thoroughfare, p.subThoroughfare].where((s) => s != null && s.isNotEmpty).join(', ');
  final area = [p.subLocality, p.locality ?? p.subAdministrativeArea].where((s) => s != null && s.isNotEmpty).join(', ');
  final first = street.isNotEmpty ? street : (p.name ?? '');
  return [first, area].where((s) => s.isNotEmpty).join(' – ');
}

/// Full-screen map: the pin stays in the middle, the person moves the map (or taps a spot)
/// and confirms the address under the pin. No device location is read.
class PlacePickerScreen extends StatefulWidget {
  const PlacePickerScreen({super.key, this.query = '', this.initial});
  final String query;
  final PickedPlace? initial;

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  late final _search = TextEditingController(text: widget.initial == null ? widget.query : '');
  GoogleMapController? _map;
  late LatLng _center = widget.initial == null ? _fallback.target : LatLng(widget.initial!.lat, widget.initial!.lng);
  late double _zoom = widget.initial == null ? _fallback.zoom : 17;
  late String? _address = widget.initial?.address;
  bool _looking = false;
  int _lookup = 0;
  Geocoding? _geo;

  Geocoding get _geocoder => _geo ??= Geocoding(locale: Localizations.localeOf(context));

  @override
  void dispose() {
    _search.dispose();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _map = controller;
    if (widget.initial == null && widget.query.trim().isNotEmpty) await _goTo(widget.query.trim());
  }

  Future<void> _goTo(String query) async {
    FocusScope.of(context).unfocus();
    try {
      final found = await _geocoder.locationFromAddress(query);
      if (!mounted || found.isEmpty) throw Exception('no result');
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(found.first.latitude, found.first.longitude), 17));
    } catch (_) {
      if (mounted) careSnack(context, AppLocalizations.of(context).careMapNotFound);
    }
  }

  Future<void> _describeCenter() async {
    final id = ++_lookup;
    // onCameraMove is not reported for animated moves on every platform; ask the map.
    final map = _map;
    if (map != null) {
      final region = await map.getVisibleRegion();
      _zoom = await map.getZoomLevel();
      _center = LatLng(
        (region.northeast.latitude + region.southwest.latitude) / 2,
        (region.northeast.longitude + region.southwest.longitude) / 2,
      );
      if (!mounted || id != _lookup) return;
    }
    if (_zoom < _streetZoom) {
      setState(() {
        _looking = false;
        _address = null;
      });
      return;
    }
    setState(() => _looking = true);
    String? address;
    try {
      final marks = await _geocoder.placemarkFromCoordinates(_center.latitude, _center.longitude);
      if (marks.isNotEmpty) address = placemarkAddress(marks.first);
    } catch (_) {}
    if (!mounted || id != _lookup) return;
    setState(() {
      _looking = false;
      _address = (address == null || address.isEmpty) ? null : address;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initial = widget.initial == null ? _fallback : CameraPosition(target: _center, zoom: 17);
    return Scaffold(
      appBar: careAppBar(context, l10n.careMapTitle),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initial,
            onMapCreated: _onMapCreated,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: (p) {
              _center = p.target;
              _zoom = p.zoom;
            },
            onCameraIdle: _describeCenter,
            onTap: (point) => _map?.animateCamera(
              _zoom < _streetZoom ? CameraUpdate.newLatLngZoom(point, _streetZoom + 2) : CameraUpdate.newLatLng(point),
            ),
          ),
          // The pin's tip sits on the map centre.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: Icon(Icons.location_on, size: 48, color: AppColors.dualisNavy),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surfaceLight,
              child: TextField(
                key: const Key('place_search'),
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (q) => q.trim().isEmpty ? null : _goTo(q.trim()),
                decoration: InputDecoration(
                  hintText: l10n.careMapSearchHint,
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(18),
                color: AppColors.surfaceLight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _looking ? l10n.careMapLooking : (_address ?? (_zoom < _streetZoom ? l10n.careMapZoomHint : l10n.careMapMoveHint)),
                        style: careTitle(15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('place_use'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(50)),
                        onPressed: _looking || _address == null
                            ? null
                            : () => Navigator.pop(context, PickedPlace(_address!, _center.latitude, _center.longitude)),
                        child: Text(l10n.careMapUsePlace),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
