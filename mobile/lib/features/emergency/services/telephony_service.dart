import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service responsible for dispatching external telephony and navigation intents
/// for emergency hotlines (SAMU 192, CVV 188, Bombeiros 193, Polícia 190) and
/// emergency room map queries.
class TelephonyService {
  const TelephonyService();

  /// Verifies whether the current device is capable of launching telephony dialers.
  Future<bool> canMakeCalls() async {
    final testUri = Uri(scheme: 'tel', path: '192');
    return canLaunchUrl(testUri);
  }

  /// Dispatches SAMU emergency hotline (192).
  Future<bool> callSamu() => callNumber('192');

  /// Dispatches Bombeiros emergency rescue hotline (193).
  Future<bool> callBombeiros() => callNumber('193');

  /// Dispatches Centro de Valorização da Vida (CVV) emotional crisis hotline (188).
  Future<bool> callCvv() => callNumber('188');

  /// Dispatches Polícia Militar emergency hotline (190).
  Future<bool> callPolicia() => callNumber('190');

  /// Dispatches a phone call intent for any specified phone number string.
  Future<bool> callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Opens native maps application searching for the nearest emergency room.
  /// Falls back to Google Maps web search if geo URI scheme is not supported.
  Future<bool> openNearestEmergencyRoom() async {
    final geoUri = Uri.parse('geo:0,0?q=pronto+socorro');
    final webUri = Uri.parse('https://www.google.com/maps/search/pronto+socorro');

    if (await canLaunchUrl(geoUri)) {
      return launchUrl(geoUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      return launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

/// Riverpod provider exposing the singleton [TelephonyService].
final telephonyServiceProvider = Provider<TelephonyService>((ref) {
  return const TelephonyService();
});
