import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a help line is for. Used to pick a localized label when the line has
/// no well-known proper name.
enum HelpLineKind { emergency, ambulance, fire, police, emotionalSupport, healthLine }

/// A phone line shown on the help resources screen.
class HelpLine {
  final String number;
  final HelpLineKind kind;

  /// Proper name of the service (e.g. 'SAMU', 'CVV', '988 Lifeline').
  /// Not translated. When null the UI uses a localized [kind] label.
  final String? serviceName;

  /// Whether the line is free and open 24 hours a day.
  final bool free24h;

  const HelpLine(
    this.number,
    this.kind, {
    this.serviceName,
    this.free24h = false,
  });

  /// Digits and '+' only, ready for a `tel:` URI.
  String get dialable => number.replaceAll(RegExp(r'[^0-9+]'), '');

  /// Short identifier sent as `channel` in safety audit events.
  String get channel => '${kind.name}_$dialable';
}

/// Static, offline table of help lines for the device region.
/// Same for every user in a region; never depends on what the user logged.
class RegionalHelpLines {
  /// ISO 3166-1 alpha-2 code this table was built for, or null for fallback.
  final String? regionCode;

  /// Main emergency number (ambulance or general emergency).
  final HelpLine emergency;

  /// Emotional support / crisis line, when a well-known one exists.
  final HelpLine? emotionalSupport;

  /// Other lines (fire, police, health line), in display order.
  final List<HelpLine> others;

  /// True when the region was not recognized and 112 is shown as a fallback.
  final bool isFallback;

  const RegionalHelpLines({
    required this.regionCode,
    required this.emergency,
    this.emotionalSupport,
    this.others = const [],
    this.isFallback = false,
  });

  /// All lines in display order: emergency, emotional support, then others.
  List<HelpLine> get all => [
        emergency,
        if (emotionalSupport != null) emotionalSupport!,
        ...others,
      ];
}

class EmergencyNumbers {
  const EmergencyNumbers._();

  static const HelpLine _eu112 = HelpLine('112', HelpLineKind.emergency);

  static const Map<String, RegionalHelpLines> _byRegion = {
    'BR': RegionalHelpLines(
      regionCode: 'BR',
      emergency: HelpLine('192', HelpLineKind.ambulance, serviceName: 'SAMU', free24h: true),
      emotionalSupport:
          HelpLine('188', HelpLineKind.emotionalSupport, serviceName: 'CVV', free24h: true),
      others: [
        HelpLine('193', HelpLineKind.fire),
        HelpLine('190', HelpLineKind.police),
      ],
    ),
    'US': RegionalHelpLines(
      regionCode: 'US',
      emergency: HelpLine('911', HelpLineKind.emergency),
      emotionalSupport: HelpLine('988', HelpLineKind.emotionalSupport,
          serviceName: '988 Lifeline', free24h: true),
    ),
    'CA': RegionalHelpLines(
      regionCode: 'CA',
      emergency: HelpLine('911', HelpLineKind.emergency),
      emotionalSupport: HelpLine('988', HelpLineKind.emotionalSupport,
          serviceName: '9-8-8', free24h: true),
    ),
    'MX': RegionalHelpLines(
      regionCode: 'MX',
      emergency: HelpLine('911', HelpLineKind.emergency),
      emotionalSupport: HelpLine('800 911 2000', HelpLineKind.emotionalSupport,
          serviceName: 'Línea de la Vida', free24h: true),
    ),
    'ES': RegionalHelpLines(
      regionCode: 'ES',
      emergency: _eu112,
      emotionalSupport: HelpLine('024', HelpLineKind.emotionalSupport,
          serviceName: 'Línea 024', free24h: true),
    ),
    'PT': RegionalHelpLines(
      regionCode: 'PT',
      emergency: _eu112,
      others: [
        HelpLine('808 24 24 24', HelpLineKind.healthLine, serviceName: 'SNS 24'),
      ],
    ),
    'FR': RegionalHelpLines(
      regionCode: 'FR',
      emergency: _eu112,
      emotionalSupport:
          HelpLine('3114', HelpLineKind.emotionalSupport, serviceName: '3114', free24h: true),
    ),
    'DE': RegionalHelpLines(
      regionCode: 'DE',
      emergency: _eu112,
      emotionalSupport: HelpLine('0800 111 0 111', HelpLineKind.emotionalSupport,
          serviceName: 'TelefonSeelsorge', free24h: true),
    ),
    'AT': RegionalHelpLines(
      regionCode: 'AT',
      emergency: _eu112,
      emotionalSupport: HelpLine('142', HelpLineKind.emotionalSupport,
          serviceName: 'TelefonSeelsorge', free24h: true),
    ),
    'CH': RegionalHelpLines(
      regionCode: 'CH',
      emergency: _eu112,
      emotionalSupport: HelpLine('143', HelpLineKind.emotionalSupport,
          serviceName: 'Die Dargebotene Hand', free24h: true),
    ),
    'NL': RegionalHelpLines(
      regionCode: 'NL',
      emergency: _eu112,
      emotionalSupport: HelpLine('0800 0113', HelpLineKind.emotionalSupport,
          serviceName: '113 Zelfmoordpreventie', free24h: true),
    ),
    'IE': RegionalHelpLines(
      regionCode: 'IE',
      emergency: _eu112,
      emotionalSupport: HelpLine('116 123', HelpLineKind.emotionalSupport,
          serviceName: 'Samaritans', free24h: true),
    ),
    'GB': RegionalHelpLines(
      regionCode: 'GB',
      emergency: HelpLine('999', HelpLineKind.emergency),
      emotionalSupport: HelpLine('116 123', HelpLineKind.emotionalSupport,
          serviceName: 'Samaritans', free24h: true),
    ),
    'AU': RegionalHelpLines(
      regionCode: 'AU',
      emergency: HelpLine('000', HelpLineKind.emergency),
      emotionalSupport: HelpLine('13 11 14', HelpLineKind.emotionalSupport,
          serviceName: 'Lifeline', free24h: true),
    ),
  };

  /// EU/EEA countries without a dedicated entry above: 112 only.
  static const Set<String> _eu112Only = {
    'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'GR', 'HU', 'IT', 'LV',
    'LT', 'LU', 'MT', 'PL', 'RO', 'SK', 'SI', 'SE', 'IS', 'LI', 'NO',
  };

  /// Returns the help lines for an ISO 3166-1 alpha-2 [regionCode].
  /// Unknown or missing regions fall back to 112 with [RegionalHelpLines.isFallback].
  static RegionalHelpLines forRegion(String? regionCode) {
    final code = regionCode?.toUpperCase();
    final known = _byRegion[code];
    if (known != null) return known;
    if (code != null && _eu112Only.contains(code)) {
      return RegionalHelpLines(regionCode: code, emergency: _eu112);
    }
    return const RegionalHelpLines(
      regionCode: null,
      emergency: _eu112,
      isFallback: true,
    );
  }

  /// Device region from the OS locale list (independent of the app language).
  static String? deviceRegion() {
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    for (final locale in locales) {
      final country = locale.countryCode;
      if (country != null && country.isNotEmpty) return country;
    }
    return null;
  }
}

/// Device region code. Override in tests.
final deviceRegionProvider = Provider<String?>((ref) => EmergencyNumbers.deviceRegion());

/// Help lines for the device region. Works offline.
final helpLinesProvider = Provider<RegionalHelpLines>(
  (ref) => EmergencyNumbers.forRegion(ref.watch(deviceRegionProvider)),
);
