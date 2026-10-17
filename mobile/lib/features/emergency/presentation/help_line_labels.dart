import '../../../core/safety/emergency_numbers.dart';
import '../../../l10n/app_localizations.dart';

/// Localized label for a help line kind.
String helpLineKindLabel(AppLocalizations loc, HelpLineKind kind) {
  switch (kind) {
    case HelpLineKind.emergency:
      return loc.safetyKindEmergency;
    case HelpLineKind.ambulance:
      return loc.safetyKindAmbulance;
    case HelpLineKind.fire:
      return loc.safetyKindFire;
    case HelpLineKind.police:
      return loc.safetyKindPolice;
    case HelpLineKind.emotionalSupport:
      return loc.safetyKindEmotionalSupport;
    case HelpLineKind.healthLine:
      return loc.safetyKindHealthLine;
  }
}

/// Display name: the service's proper name ("SAMU", "CVV") or the kind label.
/// Emotional support lines also say what they are ("CVV – Apoio emocional").
String helpLineName(AppLocalizations loc, HelpLine line) {
  final name = line.serviceName;
  if (name == null) return helpLineKindLabel(loc, line.kind);
  if (line.kind == HelpLineKind.emotionalSupport) {
    return '$name – ${helpLineKindLabel(loc, line.kind)}';
  }
  return name;
}

/// Sentence pointing to crisis resources, e.g. "…ligue 188 (CVV, 24h, gratuito) ou 192."
String crisisResourcesText(AppLocalizations loc, RegionalHelpLines lines) {
  final crisis = lines.emotionalSupport;
  if (crisis == null) {
    return loc.safetyCrisisNoLine(lines.emergency.number);
  }
  final details = [
    if (crisis.serviceName != null) crisis.serviceName!,
    if (crisis.free24h) loc.safetyFree24h,
  ].join(', ');
  final crisisLabel = details.isEmpty ? crisis.number : '${crisis.number} ($details)';
  return loc.safetyCrisisWithLine(crisisLabel, lines.emergency.number);
}
