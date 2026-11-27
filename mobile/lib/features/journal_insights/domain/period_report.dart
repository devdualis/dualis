import '../../journal/domain/journal_keys.dart';
import 'journal_insights_models.dart';

/// Period report of the history screen (client spec D16–D17, contract
/// docs/bienestar/CONTRATO-JOURNAL-V2.md "Resumo do período").
///
/// Everything here counts what the person recorded about themself in the
/// selected period: records and weekdays. Nothing is scored, ranked
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

/// Records per weekday (`DateTime.monday` = 1 … `DateTime.sunday` = 7).
Map<int, int> recordsByWeekday(List<JournalEntryView> entries) {
  final counts = {for (var d = DateTime.monday; d <= DateTime.sunday; d++) d: 0};
  for (final entry in entries) {
    final day = entry.recordedAt.weekday;
    counts[day] = counts[day]! + 1;
  }
  return counts;
}
