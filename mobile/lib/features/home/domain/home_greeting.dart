import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

/// Clock used by the Home greeting. Tests override it to pin the hour.
final homeClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

enum DayPeriod { morning, afternoon, evening }

/// Local hour to period: 5:00-11:59 morning, 12:00-17:59 afternoon,
/// otherwise evening ("Boa noite").
DayPeriod dayPeriodFor(DateTime localTime) {
  final hour = localTime.hour;
  if (hour >= 5 && hour < 12) return DayPeriod.morning;
  if (hour >= 12 && hour < 18) return DayPeriod.afternoon;
  return DayPeriod.evening;
}

/// First word of the name the person typed, or '' when empty.
String firstNameOf(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}

/// "Olá, Ana! Bom dia" (strategy §13).
String homeGreetingText(AppLocalizations l10n, String fullName, DateTime now) {
  final name = firstNameOf(fullName);
  final period = dayPeriodFor(now);
  if (name.isEmpty) {
    return switch (period) {
      DayPeriod.morning => l10n.xv2GreetingMorningNoName,
      DayPeriod.afternoon => l10n.xv2GreetingAfternoonNoName,
      DayPeriod.evening => l10n.xv2GreetingEveningNoName,
    };
  }
  return switch (period) {
    DayPeriod.morning => l10n.xv2GreetingMorning(name),
    DayPeriod.afternoon => l10n.xv2GreetingAfternoon(name),
    DayPeriod.evening => l10n.xv2GreetingEvening(name),
  };
}
