import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer and the maps app for the help resources screen.
class TelephonyService {
  const TelephonyService();

  /// Starts a phone call intent for [number] (spaces allowed).
  Future<bool> callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^0-9+]'), ''));
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Opens the maps app searching for [query] (e.g. 'pronto-socorro').
  /// Falls back to a Google Maps web search.
  Future<bool> openNearestEmergencyRoom(String query) async {
    final geoUri = Uri.parse('geo:0,0?q=${Uri.encodeQueryComponent(query)}');
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/${Uri.encodeComponent(query)}',
    );

    if (await canLaunchUrl(geoUri)) {
      return launchUrl(geoUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      return launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

final telephonyServiceProvider = Provider<TelephonyService>((ref) {
  return const TelephonyService();
});
