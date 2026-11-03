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

    test('names the weekdays with the most records, ties included', () {
      final counts = recordsByWeekday([
        e(1, const []), // Tuesday
        e(6, const []), // Thursday
        e(8, const []), // Tuesday
        e(13, const []), // Thursday
        e(0, const []), // Wednesday
      ]);
      expect(mostRecordedWeekdays(counts),
          [DateTime.tuesday, DateTime.thursday]);
    });

    test('names nothing when empty or when every weekday is the same', () {
      expect(mostRecordedWeekdays(recordsByWeekday(const [])), isEmpty);
      final everyDay = [for (var i = 0; i < 7; i++) e(i, const [])];
      expect(mostRecordedWeekdays(recordsByWeekday(everyDay)), isEmpty);
    });
  });

  group('"não tão bem" sentence', () {
    test('counts records per time among "não tão bem" records', () {
      final summary = NotWellTimeSummary.compute([
        e(0, [emo('futuro.mente.antecipar'), emo('futuro.medo.evitar')]),
        e(1, [emo('futuro.custom')]),
        e(2, [emo('passado.memoria.magoa')]),
        e(3, [body('peito.respiracao.curta')]),
        // Not counted: other moods.
        e(4, [good('futuro.animo.planos')], mood: 'bem'),
        e(5, [emo('passado.tristeza.culpa')], mood: null),
      ])!;
      expect(summary.total, 4);
      expect(summary.count, 2);
      expect(summary.times, ['futuro']);
    });

    test('keeps tied times in passado → futuro order', () {
      final summary = NotWellTimeSummary.compute([
        e(0, [emo('futuro.mente.antecipar')]),
        e(1, [emo('passado.memoria.magoa')]),
      ])!;
      expect(summary.times, ['passado', 'futuro']);
      expect(summary.count, 1);
    });

    test('is null without emotional "não tão bem" records', () {
      expect(NotWellTimeSummary.compute(const []), isNull);
      expect(
        NotWellTimeSummary.compute([e(0, [body('cabeca.nuca.rigida')])]),
        isNull,
      );
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

  group('body–mind coincidences', () {
    test('counts days with an emotional branch and a region, most first', () {
      final list = bodyMindCoincidences([
        e(0, [emo('futuro.mente.antecipar'), body('peito.respiracao.curta')]),
        // Same day, another record: still the same day.
        e(1, [emo('futuro.mente.cobranca')]),
        e(1, [body('peito.incomodo.batedeira', sensation: 'incomodo')]),
        // Same day twice counts once.
        e(1, [body('peito.respiracao.tosse')]),
        e(2, [emo('passado.memoria.magoa'), body('cabeca.pressao.temporas')]),
        // Different days: no pair.
        e(3, [emo('presente.energia.corpo')]),
        e(4, [body('costas.rigidez.ombros')]),
      ]);
      expect(list.first.emotional, 'futuro.mente');
      expect(list.first.region, 'peito');
      expect(list.first.days, 2);
      expect(
        list.map((c) => '${c.emotional}|${c.region}|${c.days}'),
        ['futuro.mente|peito|2', 'passado.memoria|cabeca|1'],
      );
    });

    test('uses the time for written items and skips triggers and legacy', () {
      final list = bodyMindCoincidences([
        JournalEntryView(
          id: 'x',
          recordedAt: today,
          triggers: const ['trabalho'],
          items: [
            emo('presente.custom'),
            body('pele.coceira.coceira'),
            const JournalItemView(kind: 'physical', legacyLabel: 'Dor antiga'),
          ],
        ),
      ]);
      expect(list.single.emotional, 'presente');
      expect(list.single.region, 'pele');
    });

    test('is empty without both sides', () {
      expect(bodyMindCoincidences(const []), isEmpty);
      expect(
        bodyMindCoincidences([e(0, [emo('futuro.mente.antecipar')])]),
        isEmpty,
      );
    });
  });
}
