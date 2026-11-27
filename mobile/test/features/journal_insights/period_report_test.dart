import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/journal_insights/domain/history_series.dart';
import 'package:dualis_mobile/features/journal_insights/domain/journal_insights_models.dart';
import 'package:dualis_mobile/features/journal_insights/domain/period_report.dart';

void main() {
  // Wednesday.
  final today = DateTime(2026, 10, 28, 9);
  var seq = 0;

  JournalEntryView e(
    int daysAgo,
    List<JournalItemView> items, {
    String? mood = 'nao_tao_bem',
  }) =>
      JournalEntryView(
        id: 'e${seq++}',
        recordedAt: today.subtract(Duration(days: daysAgo)),
        mood: mood,
        items: items,
      );

  JournalItemView emo(String key) =>
      JournalItemView(kind: 'emotional', optionKey: key);
  JournalItemView body(String key, {String? sensation}) =>
      JournalItemView(kind: 'physical', optionKey: key, sensation: sensation);
  JournalItemView good(String key) =>
      JournalItemView(kind: 'positive', optionKey: key);

  group('14-day period', () {
    test('is offered between 7 and 30 days and is the default', () {
      expect(historyPeriods, [7, 14, 30]);
      expect(defaultHistoryPeriod, 14);
      expect(historyPeriods, contains(defaultHistoryPeriod));
    });

    test('keeps today and the 13 days before it', () {
      final entries = [e(0, const []), e(13, const []), e(14, const [])];
      final inside = entriesInPeriod(entries, today: today, days: 14);
      expect(inside.map((x) => x.id), [entries[0].id, entries[1].id]);
      expect(periodStart(today, 14), DateTime(2026, 10, 15));
    });
  });

  group('weekday count', () {
    test('counts records per weekday, Monday = 1', () {
      final counts = recordsByWeekday([
        e(0, const []), // Wednesday
        e(0, const []), // Wednesday
        e(1, const []), // Tuesday
        e(7, const []), // Wednesday
      ]);
      expect(counts.keys, [1, 2, 3, 4, 5, 6, 7]);
      expect(counts[DateTime.wednesday], 3);
      expect(counts[DateTime.tuesday], 1);
      expect(counts[DateTime.sunday], 0);
    });
  });

  group('"Como você se sentiu" groups', () {
    test('maps branches with the fixed table', () {
      expect(everydayFeelingByBranch, {
        'passado.tristeza': EverydayFeeling.pesado,
        'passado.memoria': EverydayFeeling.pesado,
        'presente.energia': EverydayFeeling.pesado,
        'presente.solidao': EverydayFeeling.pesado,
        'futuro.mente': EverydayFeeling.agitado,
        'futuro.medo': EverydayFeeling.agitado,
        'presente.sobrecarga': EverydayFeeling.irritado,
      });
    });

    test('one record per feeling, a record can be in more than one', () {
      final counts = EverydayFeelingCounts.compute([
        e(0, [emo('passado.tristeza.culpa'), emo('passado.memoria.magoa')]),
        e(1, [emo('futuro.mente.antecipar'), emo('presente.sobrecarga.paciencia')]),
        e(2, [emo('presente.solidao.sozinho')]), // legacy branch
        e(3, const [], mood: 'bem'),
        e(4, [good('presente.calma.paz'), good('futuro.animo.planos')], mood: 'bem'),
      ]);
      expect(counts.total, 5);
      expect(counts.records, {
        EverydayFeeling.pesado: 2,
        EverydayFeeling.agitado: 1,
        EverydayFeeling.irritado: 1,
        EverydayFeeling.tranquilo: 2,
      });
    });

    test('ignores written items, physical items, unknown and old keys', () {
      final counts = EverydayFeelingCounts.compute([
        e(0, [emo('futuro.custom')]),
        e(1, [body('peito.respiracao.curta', sensation: 'dor')]),
        e(2, [emo('presente.ramo_novo.opcao')]),
        e(3, const [JournalItemView(kind: 'emotional', legacyLabel: 'Triste')]),
        e(4, const [], mood: 'normal'),
        e(5, const [JournalItemView(kind: 'emotional')]),
      ]);
      expect(counts.isEmpty, isTrue);
      expect(counts.records.values.every((v) => v == 0), isTrue);
    });
  });
}
