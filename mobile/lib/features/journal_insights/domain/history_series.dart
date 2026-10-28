import '../../../l10n/app_localizations.dart';
import '../../journal/domain/journal_keys.dart';
import '../../journal/presentation/journal_labels.dart';
import 'journal_insights_models.dart';

/// Periods offered on the history screen (chips 7 / 30 / 90 dias).
const List<int> historyPeriods = [7, 30, 90];

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

/// One line on a history chart: the highest intensity reported each day.
class HistoryLine {
  final String key;
  final String label;

  /// Day index in the period (0 = oldest) to reported intensity (1..5).
  final Map<int, int> points;

  const HistoryLine({
    required this.key,
    required this.label,
    required this.points,
  });

  /// Days with a value on this line.
  Set<int> get days => points.keys.toSet();
}

List<HistoryLine> _lines(
  List<JournalEntryView> entries, {
  required DateTime today,
  required int days,
  required String kind,
  required (String, String)? Function(JournalItemView item) identify,
}) {
  final start = periodStart(today, days);
  final labels = <String, String>{};
  final points = <String, Map<int, int>>{};
  for (final entry in entries) {
    final index = entry.day.difference(start).inDays;
    if (index < 0 || index >= days) continue;
    for (final item in entry.items) {
      if (item.kind != kind) continue;
      final intensity = item.intensity;
      if (intensity == null) continue;
      final id = identify(item);
      if (id == null || id.$2.isEmpty) continue;
      labels.putIfAbsent(id.$1, () => id.$2);
      final byDay = points.putIfAbsent(id.$1, () => <int, int>{});
      final previous = byDay[index];
      if (previous == null || intensity > previous) byDay[index] = intensity;
    }
  }
  final lines = [
    for (final key in points.keys)
      HistoryLine(key: key, label: labels[key]!, points: points[key]!),
  ];
  lines.sort((a, b) {
    final byDays = b.points.length.compareTo(a.points.length);
    return byDays != 0 ? byDays : a.label.compareTo(b.label);
  });
  return lines;
}

/// One line per emotional branch ("Futuro · Mente acelerada"). Written
/// items and old entries keep their own line, in the person's words.
List<HistoryLine> emotionalLines(
  AppLocalizations l10n,
  List<JournalEntryView> entries, {
  required DateTime today,
  required int days,
}) {
  return _lines(entries, today: today, days: days, kind: 'emotional',
      identify: (item) {
    final key = item.optionKey;
    final time = item.time;
    final timeText = time != null ? JournalLabels.timeShort(l10n, time) : null;
    if (item.legacyLabel != null || item.isCustom || key == null) {
      final text = item.label(l10n);
      return (item.seriesKey, timeText != null ? '$timeText · $text' : text);
    }
    final parts = key.split('.');
    if (parts.length < 2) {
      return (key, timeText ?? JournalLabels.root(l10n, key));
    }
    final branchKey = '${parts[0]}.${parts[1]}';
    final branch = JournalLabels.branch(l10n, branchKey);
    return (
      branchKey,
      timeText != null ? '$timeText · $branch' : branch,
    );
  });
}

/// One line per body region, split by sensation when the entry has one
/// ("Cabeça e pescoço · dor").
List<HistoryLine> physicalLines(
  AppLocalizations l10n,
  List<JournalEntryView> entries, {
  required DateTime today,
  required int days,
}) {
  return _lines(entries, today: today, days: days, kind: 'physical',
      identify: (item) {
    final region = item.region;
    if (item.legacyLabel != null || region == null) {
      return (item.seriesKey, item.label(l10n));
    }
    final regionText = historyRegionLabel(l10n, region) ?? region;
    final sensation = historySensationLabel(l10n, item.sensation);
    return sensation == null
        ? (region, regionText)
        : ('$region:${item.sensation}', '$regionText · $sensation');
  });
}

/// Number of days each emotional time and each body region were marked on
/// the same day, as `(time, region) -> days`. Counts only.
Map<(String, String), int> timeRegionDays(List<JournalEntryView> entries) {
  final timeDays = <String, Set<DateTime>>{};
  final regionDays = <String, Set<DateTime>>{};
  for (final entry in entries) {
    for (final item in entry.items) {
      final time = item.time;
      final region = item.region;
      if (time != null && JournalLabels.times.contains(time)) {
        timeDays.putIfAbsent(time, () => <DateTime>{}).add(entry.day);
      }
      if (region != null) {
        regionDays.putIfAbsent(region, () => <DateTime>{}).add(entry.day);
      }
    }
  }
  final result = <(String, String), int>{};
  for (final t in timeDays.entries) {
    for (final r in regionDays.entries) {
      final both = t.value.intersection(r.value).length;
      if (both > 0) result[(t.key, r.key)] = both;
    }
  }
  return result;
}
