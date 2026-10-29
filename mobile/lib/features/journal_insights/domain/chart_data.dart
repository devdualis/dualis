import '../../../l10n/app_localizations.dart';
import '../../hydration/domain/models/water_intake_log.dart';
import '../../journal/domain/journal_keys.dart';
import '../../journal/presentation/journal_labels.dart';
import 'journal_insights_models.dart';

/// Data behind the history charts of handoff "Dualis | Gráficos do
/// aplicativo" v2.0 (E1–E3, F1–F3, H1–H4, C1). Everything here counts or
/// places what the person recorded; nothing scores, averages intensities or
/// infers a cause.

/// The five regions drawn on the body map (F1), in display order.
const List<String> mapRegions = ['cabeca', 'peito', 'barriga', 'costas', 'membros'];

/// One emotional or physical item, placed at the moment it was recorded.
class RecordPoint {
  /// Entry id + item index: two items of one session stay distinct.
  final String id;
  final DateTime at;

  /// Time (`passado`…) for emotional items, region for physical ones.
  final String series;

  /// `<root>.<branch>` or null for written / old items.
  final String? branchKey;

  /// Position of the branch in its tree (0 = first fork), -1 when none.
  final int branchIndex;

  /// Final answer key (option key, or `custom:<text>` for written items).
  final String answerKey;

  /// What the person chose or wrote, in their words.
  final String answer;

  final int? intensity;

  /// `front`, `back` or null (not informed).
  final String? view;

  /// `dor` / `incomodo` for physical items of journal v2.1.
  final String? sensation;

  const RecordPoint({
    required this.id,
    required this.at,
    required this.series,
    required this.branchKey,
    required this.branchIndex,
    required this.answerKey,
    required this.answer,
    required this.intensity,
    this.view,
    this.sensation,
  });

  DateTime get day => DateTime(at.year, at.month, at.day);
}

String _answerKey(JournalItemView item) {
  if (item.isCustom) return 'custom:${(item.customLabel ?? '').toLowerCase()}';
  return item.optionKey ?? item.seriesKey;
}

String _answerText(AppLocalizations l10n, JournalItemView item) {
  if (item.customLabel?.isNotEmpty == true) return item.customLabel!;
  final key = item.optionKey;
  if (key == null) return item.label(l10n);
  final text = JournalLabels.option(l10n, key);
  return text == key ? item.label(l10n) : text;
}

List<RecordPoint> _points(
  AppLocalizations l10n,
  List<JournalEntryView> entries, {
  required String kind,
  required List<String> roots,
  required Map<String, Map<String, List<String>>> tree,
}) {
  final result = <RecordPoint>[];
  for (final entry in entries) {
    for (var i = 0; i < entry.items.length; i++) {
      final item = entry.items[i];
      if (item.kind != kind || item.legacyLabel != null) continue;
      final key = item.optionKey;
      if (key == null) continue;
      final parts = key.split('.');
      final root = parts.first;
      if (!roots.contains(root)) continue;
      final hasBranch = !item.isCustom && parts.length >= 3;
      final branches = tree[root]?.keys.toList() ?? const <String>[];
      result.add(RecordPoint(
        id: '${entry.id}#$i',
        at: entry.recordedAt,
        series: root,
        branchKey: hasBranch ? '${parts[0]}.${parts[1]}' : null,
        branchIndex: hasBranch ? branches.indexOf(parts[1]) : -1,
        answerKey: _answerKey(item),
        answer: _answerText(l10n, item),
        intensity: item.intensity,
        view: item.bodySide,
        sensation: item.sensation,
      ));
    }
  }
  result.sort((a, b) => a.at.compareTo(b.at));
  return result;
}

/// Emotional items with a temporal axis, oldest first.
List<RecordPoint> emotionalPoints(
  AppLocalizations l10n,
  List<JournalEntryView> entries,
) =>
    _points(l10n, entries,
        kind: JournalKeys.kindEmotional,
        roots: JournalLabels.times,
        tree: JournalKeys.emotionalTree);

/// Physical marks (body regions and whole-body areas), oldest first.
List<RecordPoint> physicalPoints(
  AppLocalizations l10n,
  List<JournalEntryView> entries,
) =>
    _points(l10n, entries,
        kind: JournalKeys.kindPhysical,
        roots: JournalLabels.regions,
        tree: JournalKeys.physicalTree);

/// Most registered final answer(s) and how many times; ties keep all.
class TopAnswer {
  final List<String> answers;
  final int count;
  const TopAnswer(this.answers, this.count);
}

TopAnswer? topAnswer(Iterable<RecordPoint> points) {
  final counts = <String, int>{};
  final labels = <String, String>{};
  for (final p in points) {
    counts[p.answerKey] = (counts[p.answerKey] ?? 0) + 1;
    labels.putIfAbsent(p.answerKey, () => p.answer);
  }
  if (counts.isEmpty) return null;
  final best = counts.values.reduce((a, b) => a > b ? a : b);
  final tied = [
    for (final e in counts.entries)
      if (e.value == best) labels[e.key]!,
  ]..sort();
  return TopAnswer(tied, best);
}

/// E1: share of emotional records per temporal axis. Intensity never
/// changes a slice; records without an axis are reported apart.
class TemporalPie {
  /// Axis -> number of records.
  final Map<String, int> counts;
  final Map<String, TopAnswer> top;

  /// Records (entries) saved with no emotional or physical choice
  /// ("Bem" without an axis). They never become Presente.
  final int withoutAxis;

  const TemporalPie({
    required this.counts,
    required this.top,
    required this.withoutAxis,
  });

  int get total => counts.values.fold(0, (a, b) => a + b);

  factory TemporalPie.compute(
    List<RecordPoint> emotional,
    List<JournalEntryView> entries,
  ) {
    final counts = <String, int>{};
    final top = <String, TopAnswer>{};
    for (final time in JournalLabels.times) {
      final ofTime = emotional.where((p) => p.series == time).toList();
      if (ofTime.isEmpty) continue;
      counts[time] = ofTime.length;
      final t = topAnswer(ofTime);
      if (t != null) top[time] = t;
    }
    final withoutAxis = entries
        .where((e) =>
            !e.legacy &&
            !e.items.any((i) =>
                i.kind == JournalKeys.kindEmotional ||
                i.kind == JournalKeys.kindPhysical))
        .length;
    return TemporalPie(counts: counts, top: top, withoutAxis: withoutAxis);
  }
}

/// F1: what was marked on one region in the period.
class RegionSummary {
  final String region;
  final List<RecordPoint> marks;

  const RegionSummary(this.region, this.marks);

  /// Distinct days with at least one mark (several marks on one day = 1).
  int get days => {for (final m in marks) m.day}.length;

  TopAnswer? get top => topAnswer(marks);

  /// Marks per view: `front`, `back`, null (not informed).
  Map<String?, int> get byView {
    final counts = <String?, int>{};
    for (final m in marks) {
      counts[m.view] = (counts[m.view] ?? 0) + 1;
    }
    return counts;
  }

  /// Silhouette that carries the marker. Costas is only on the back; a
  /// region marked only from the back goes there; otherwise the front.
  String get mapView {
    if (region == 'costas') return JournalKeys.sideBack;
    if (marks.isNotEmpty && marks.every((m) => m.view == JournalKeys.sideBack)) {
      return JournalKeys.sideBack;
    }
    return JournalKeys.sideFront;
  }
}

/// Regions with at least one mark, most days first.
List<RegionSummary> regionSummaries(List<RecordPoint> physical) {
  final byRegion = <String, List<RecordPoint>>{};
  for (final p in physical) {
    byRegion.putIfAbsent(p.series, () => []).add(p);
  }
  final result = [
    for (final region in JournalLabels.regions)
      if (byRegion[region] != null) RegionSummary(region, byRegion[region]!),
  ];
  result.sort((a, b) => b.days.compareTo(a.days));
  return result;
}

/// Splits points of one series into runs: the line breaks when a calendar
/// day without a record of that series lies between two points.
List<List<RecordPoint>> seriesRuns(List<RecordPoint> points) {
  final runs = <List<RecordPoint>>[];
  for (final p in points) {
    if (p.intensity == null) continue;
    if (runs.isNotEmpty) {
      final last = runs.last.last;
      if (p.day.difference(last.day).inDays <= 1) {
        runs.last.add(p);
        continue;
      }
    }
    runs.add([p]);
  }
  return runs;
}

/// Fractional day index of [at] in a period starting at [start] (midnight).
double dayPosition(DateTime at, DateTime start) =>
    at.difference(start).inMinutes / Duration.minutesPerDay;

/// C1: what was recorded on one day, kept item by item.
class CalendarDay {
  final DateTime day;
  final List<RecordPoint> emotional;
  final List<RecordPoint> physical;

  /// Sum of water events that day, null when there was none.
  final int? waterMl;

  const CalendarDay({
    required this.day,
    this.emotional = const [],
    this.physical = const [],
    this.waterMl,
  });

  bool get isEmpty => emotional.isEmpty && physical.isEmpty && waterMl == null;
}

Map<DateTime, CalendarDay> calendarDays({
  required List<RecordPoint> emotional,
  required List<RecordPoint> physical,
  required Map<DateTime, int> waterTotals,
}) {
  final emo = <DateTime, List<RecordPoint>>{};
  final phy = <DateTime, List<RecordPoint>>{};
  for (final p in emotional) {
    emo.putIfAbsent(p.day, () => []).add(p);
  }
  for (final p in physical) {
    phy.putIfAbsent(p.day, () => []).add(p);
  }
  final water = normalizeWaterTotals(waterTotals);
  final days = {...emo.keys, ...phy.keys, ...water.keys};
  return {
    for (final d in days)
      d: CalendarDay(
        day: d,
        emotional: emo[d] ?? const [],
        physical: phy[d] ?? const [],
        waterMl: water[d],
      ),
  };
}

/// Local-midnight keys, dropping days without water (0 is "no record").
Map<DateTime, int> normalizeWaterTotals(Map<DateTime, int> totals) => {
      for (final e in totals.entries)
        if (e.value > 0) DateTime(e.key.year, e.key.month, e.key.day): e.value,
    };

/// H3 cards: counts over the days of the period.
class WaterPeriodStats {
  final int totalMl;
  final int daysWithRecord;
  final int periodDays;

  /// Days with a record and a goal that reached it.
  final int daysReachedGoal;
  final int? goalMl;

  const WaterPeriodStats({
    required this.totalMl,
    required this.daysWithRecord,
    required this.periodDays,
    required this.daysReachedGoal,
    required this.goalMl,
  });

  /// Average per day with a record (denominator = [daysWithRecord]).
  int? get averageMl =>
      daysWithRecord == 0 ? null : (totalMl / daysWithRecord).round();

  factory WaterPeriodStats.compute(
    Map<DateTime, int> totals, {
    required DateTime start,
    required int days,
    required int? goalMl,
  }) {
    final water = normalizeWaterTotals(totals);
    var total = 0;
    var withRecord = 0;
    var reached = 0;
    for (var i = 0; i < days; i++) {
      final ml = water[DateTime(start.year, start.month, start.day + i)];
      if (ml == null) continue;
      total += ml;
      withRecord++;
      if (goalMl != null && goalMl > 0 && ml >= goalMl) reached++;
    }
    return WaterPeriodStats(
      totalMl: total,
      daysWithRecord: withRecord,
      periodDays: days,
      daysReachedGoal: reached,
      goalMl: goalMl,
    );
  }
}

/// H2: one step per water event, in local hours (0..24) and running sum.
class WaterStep {
  final double hour;
  final int addedMl;
  final int cumulativeMl;
  final DateTime at;
  const WaterStep(this.hour, this.addedMl, this.cumulativeMl, this.at);
}

List<WaterStep> waterSteps(List<WaterIntakeEntry> logs) {
  final sorted = [...logs]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  var sum = 0;
  return [
    for (final log in sorted)
      if (log.amountMl > 0)
        () {
          final at = log.timestamp.toLocal();
          sum += log.amountMl;
          return WaterStep(at.hour + at.minute / 60, log.amountMl, sum, at);
        }(),
  ];
}

/// Mondays-first weeks covering the period, for the calendars (C1, H4).
List<List<DateTime>> calendarWeeks(DateTime start, int days) {
  final first = DateTime(start.year, start.month, start.day - (start.weekday - 1));
  final end = DateTime(start.year, start.month, start.day + days - 1);
  final weeks = <List<DateTime>>[];
  var cursor = first;
  while (!cursor.isAfter(end)) {
    weeks.add([
      for (var i = 0; i < 7; i++)
        DateTime(cursor.year, cursor.month, cursor.day + i),
    ]);
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 7);
  }
  return weeks;
}

/// True when [day] is inside the [days]-day period starting at [start].
bool inPeriod(DateTime day, DateTime start, int days) {
  final d = DateTime(day.year, day.month, day.day);
  final index = DateTime.utc(d.year, d.month, d.day)
      .difference(DateTime.utc(start.year, start.month, start.day))
      .inDays;
  return index >= 0 && index < days;
}
