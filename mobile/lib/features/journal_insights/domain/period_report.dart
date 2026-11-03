import '../../journal/domain/journal_keys.dart';
import 'journal_insights_models.dart';

/// Period report of the history screen (client spec D15–D17, contract
/// docs/bienestar/CONTRATO-JOURNAL-V2.md "Resumo do período").
///
/// Everything here counts what the person recorded about themself in the
/// selected period: records, days and weekdays. Nothing is scored, ranked
/// as better or worse, interpreted or used to trigger a message.

/// Everyday feelings of "Como você se sentiu". Fixed order, never ranked.
enum EverydayFeeling { pesado, agitado, irritado, tranquilo }

/// Emotional branch (`<time>.<branch>`) to its feeling. Fixed table, mirrored
/// in the contract. Branches not listed here are not counted.
const Map<String, EverydayFeeling> everydayFeelingByBranch = {
  'passado.tristeza': EverydayFeeling.pesado,
  'passado.memoria': EverydayFeeling.pesado,
  'presente.energia': EverydayFeeling.pesado,
  // Legacy branch (journal v2.2), kept so older entries still count.
  'presente.solidao': EverydayFeeling.pesado,
  'futuro.mente': EverydayFeeling.agitado,
  'futuro.medo': EverydayFeeling.agitado,
  'presente.sobrecarga': EverydayFeeling.irritado,
};

/// Feelings one record falls in: the branch of each emotional item, every
/// good moment and a "bem" mood count as "Tranquilo / bem". Written items
/// (`<time>.custom`), physical items and legacy text belong to no feeling.
Set<EverydayFeeling> everydayFeelingsOf(JournalEntryView entry) {
  final feelings = <EverydayFeeling>{};
  if (entry.mood == JournalKeys.moodBem) feelings.add(EverydayFeeling.tranquilo);
  for (final item in entry.items) {
    if (item.kind == JournalKeys.kindPositive) {
      feelings.add(EverydayFeeling.tranquilo);
      continue;
    }
    if (item.kind != JournalKeys.kindEmotional || item.isCustom) continue;
    final parts = (item.optionKey ?? '').split('.');
    if (parts.length < 2) continue;
    final feeling = everydayFeelingByBranch['${parts[0]}.${parts[1]}'];
    if (feeling != null) feelings.add(feeling);
  }
  return feelings;
}

/// Records per feeling and how many records fall in at least one feeling.
class EverydayFeelingCounts {
  final Map<EverydayFeeling, int> records;
  final int total;

  const EverydayFeelingCounts({required this.records, required this.total});

  factory EverydayFeelingCounts.compute(List<JournalEntryView> entries) {
    final records = {for (final g in EverydayFeeling.values) g: 0};
    var total = 0;
    for (final entry in entries) {
      final feelings = everydayFeelingsOf(entry);
      if (feelings.isEmpty) continue;
      total++;
      for (final g in feelings) {
        records[g] = records[g]! + 1;
      }
    }
    return EverydayFeelingCounts(records: records, total: total);
  }

  bool get isEmpty => total == 0;
}

/// Times of the emotional items of one record (`passado`, `presente`,
/// `futuro`), written items included.
Set<String> emotionalTimesOf(JournalEntryView entry) => {
      for (final item in entry.items)
        if (item.kind == JournalKeys.kindEmotional &&
            JournalKeys.times.contains(item.time))
          item.time!,
    };

/// "Nos últimos 14 dias, 6 de 10 registros de 'não tão bem' foram sobre o
/// futuro": the time(s) most present in "não tão bem" records.
class NotWellTimeSummary {
  /// "Não tão bem" records in the period.
  final int total;

  /// Records of the most present time.
  final int count;

  /// Most present times; more than one when tied, in passado → futuro order.
  final List<String> times;

  const NotWellTimeSummary({
    required this.total,
    required this.count,
    required this.times,
  });

  /// Null when no "não tão bem" record has a time.
  static NotWellTimeSummary? compute(List<JournalEntryView> entries) {
    final notWell = [
      for (final e in entries)
        if (e.mood == JournalKeys.moodNaoTaoBem) e,
    ];
    final byTime = {for (final t in JournalKeys.times) t: 0};
    for (final entry in notWell) {
      for (final t in emotionalTimesOf(entry)) {
        byTime[t] = byTime[t]! + 1;
      }
    }
    final max = byTime.values.fold(0, (a, b) => a > b ? a : b);
    if (max == 0) return null;
    return NotWellTimeSummary(
      total: notWell.length,
      count: max,
      times: [
        for (final t in JournalKeys.times)
          if (byTime[t] == max) t,
      ],
    );
  }
}

/// Records per weekday (`DateTime.monday` = 1 … `DateTime.sunday` = 7).
Map<int, int> recordsByWeekday(List<JournalEntryView> entries) {
  final counts = {for (var d = DateTime.monday; d <= DateTime.sunday; d++) d: 0};
  for (final entry in entries) {
    final day = entry.recordedAt.weekday;
    counts[day] = counts[day]! + 1;
  }
  return counts;
}

/// Weekdays with the most records. Empty when there are no records or when
/// every weekday has the same count (nothing stands out to describe).
List<int> mostRecordedWeekdays(Map<int, int> counts) {
  final max = counts.values.fold(0, (a, b) => a > b ? a : b);
  if (max == 0) return const [];
  final top = [
    for (final e in counts.entries)
      if (e.value == max) e.key,
  ]..sort();
  return top.length == counts.length ? const [] : top;
}

/// Days on which the person recorded an emotional choice and a body region.
class BodyMindCoincidence {
  /// Emotional branch (`futuro.mente`) or, for a written item, the time.
  final String emotional;

  /// Body region or whole-body area (`peito`, `pele`).
  final String region;
  final int days;

  const BodyMindCoincidence({
    required this.emotional,
    required this.region,
    required this.days,
  });
}

/// Pairs of an emotional choice and a body region recorded on the same day,
/// counted in days, most days first. Same day only: no order, no cause.
List<BodyMindCoincidence> bodyMindCoincidences(
  List<JournalEntryView> entries,
) {
  final emotionalDays = <String, Set<DateTime>>{};
  final regionDays = <String, Set<DateTime>>{};
  for (final entry in entries) {
    for (final item in entry.items) {
      final key = item.optionKey;
      if (key == null || key.isEmpty) continue;
      final parts = key.split('.');
      if (item.kind == JournalKeys.kindPhysical) {
        regionDays.putIfAbsent(parts.first, () => {}).add(entry.day);
      } else if (item.kind == JournalKeys.kindEmotional) {
        final marker = item.isCustom || parts.length < 2
            ? parts.first
            : '${parts[0]}.${parts[1]}';
        emotionalDays.putIfAbsent(marker, () => {}).add(entry.day);
      }
    }
  }
  final result = <BodyMindCoincidence>[];
  for (final e in emotionalDays.entries) {
    for (final r in regionDays.entries) {
      final days = e.value.intersection(r.value).length;
      if (days > 0) {
        result.add(BodyMindCoincidence(
          emotional: e.key,
          region: r.key,
          days: days,
        ));
      }
    }
  }
  result.sort((a, b) {
    final byDays = b.days.compareTo(a.days);
    if (byDays != 0) return byDays;
    final byEmotional = a.emotional.compareTo(b.emotional);
    return byEmotional != 0 ? byEmotional : a.region.compareTo(b.region);
  });
  return result;
}
