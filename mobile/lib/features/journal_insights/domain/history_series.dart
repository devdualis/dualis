import '../../../l10n/app_localizations.dart';
import '../../journal/domain/journal_keys.dart';
import '../../journal/presentation/journal_labels.dart';
import 'journal_insights_models.dart';

/// Periods offered on the history screen (chips 7 / 30 dias; Free shows
/// up to 30 days).
const List<int> historyPeriods = [7, 30];

/// Body regions and whole-body areas, in display order.
List<String> get historyRegions => JournalLabels.regions;

/// Name of a body region or whole-body area, or null for unknown keys.
String? historyRegionLabel(AppLocalizations l10n, String key) =>
    JournalLabels.region(l10n, key);

/// Sensation in lower case, as it reads after the region ("· dor").
String? historySensationLabel(AppLocalizations l10n, String? key) =>
    JournalKeys.sensations.contains(key)
        ? JournalLabels.sensation(l10n, key!).toLowerCase()
        : null;

/// Any marker: option, branch, region, area, time or trigger.
String? historyMarkerLabel(AppLocalizations l10n, String key) =>
    JournalLabels.marker(l10n, key);

/// First day (local midnight) of the [days]-day period ending on [today].
DateTime periodStart(DateTime today, int days) =>
    DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));

/// Entries recorded in the [days]-day period ending on [today].
List<JournalEntryView> entriesInPeriod(
  List<JournalEntryView> entries, {
  required DateTime today,
  required int days,
}) {
  final start = periodStart(today, days);
  return [
    for (final entry in entries)
      if (!entry.day.isBefore(start) &&
          entry.day.difference(start).inDays < days)
        entry,
  ];
}
