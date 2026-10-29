import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/hydration/domain/models/water_intake_log.dart';
import 'package:dualis_mobile/features/journal_insights/domain/chart_data.dart';
import 'package:dualis_mobile/features/journal_insights/domain/journal_insights_models.dart';
import 'package:dualis_mobile/features/journal_insights/presentation/widgets/water_charts.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

/// Acceptance criteria of handoff "Dualis | Gráficos do aplicativo" v2.0 §7.
void main() {
  final l10n = lookupAppLocalizations(const Locale('pt'));

  JournalEntryView e(String id, DateTime at, List<JournalItemView> items,
          {String? mood}) =>
      JournalEntryView(id: id, recordedAt: at, items: items, mood: mood);

  JournalItemView emo(String key, int? intensity) =>
      JournalItemView(kind: 'emotional', optionKey: key, intensity: intensity);

  JournalItemView phy(String key, int? intensity, {String? side}) =>
      JournalItemView(
          kind: 'physical', optionKey: key, intensity: intensity, bodySide: side);

  DateTime at(int day, [int hour = 10]) => DateTime(2026, 10, day, hour);

  group('E1 · pizza temporal', () {
    test('2 Passado + 1 Presente + 1 Futuro + 2 sem eixo = 50/25/25 over 4',
        () {
      final entries = [
        e('a', at(1), [emo('passado.memoria.magoa', 5)]),
        e('b', at(2), [emo('passado.memoria.magoa', 1)]),
        e('c', at(3), [emo('presente.energia.desligado', 3)]),
        e('d', at(4), [emo('futuro.mente.cobranca', null)]),
        e('e', at(5), const [], mood: 'bem'),
        e('f', at(6), const [], mood: 'normal'),
      ];
      final pie = TemporalPie.compute(emotionalPoints(l10n, entries), entries);
      expect(pie.counts, {'passado': 2, 'presente': 1, 'futuro': 1});
      expect(pie.total, 4);
      expect(pie.withoutAxis, 2);
      expect(pie.counts.containsKey('presente') && pie.counts['presente'] == 1,
          isTrue, reason: 'Bem/Normal without axis never becomes Presente');
      expect(pie.top['passado']!.count, 2);
      expect(pie.top['passado']!.answers, ['Fico remoendo mágoas antigas']);
    });

    test('ties list every tied answer', () {
      final entries = [
        e('a', at(1), [emo('futuro.mente.cobranca', 2)]),
        e('b', at(2), [emo('futuro.mente.antecipar', 4)]),
      ];
      final pie = TemporalPie.compute(emotionalPoints(l10n, entries), entries);
      expect(pie.top['futuro']!.answers.length, 2);
      expect(pie.top['futuro']!.count, 1);
    });
  });

  group('E2/E3/F2/F3 · séries', () {
    test('two records of one day stay apart; a day without record breaks the line',
        () {
      final points = emotionalPoints(l10n, [
        e('a', at(1, 9), [emo('futuro.mente.cobranca', 2)]),
        e('b', at(1, 18), [emo('futuro.medo.desanimo', 4)]),
        e('c', at(2), [emo('futuro.mente.cobranca', 3)]),
        e('d', at(4), [emo('futuro.mente.cobranca', 1)]),
        e('e', at(5), [emo('futuro.mente.cobranca', null)]),
      ]);
      final runs = seriesRuns(points);
      expect(runs.map((r) => r.length), [3, 1]);
      expect(runs.first[0].at.hour, 9);
      expect(runs.first[1].at.hour, 18);
      // Missing intensity never becomes a point.
      expect(runs.expand((r) => r).any((p) => p.intensity == null), isFalse);
    });

    test('branch index drives the symbol: first fork circle, second square', () {
      final points = physicalPoints(l10n, [
        e('a', at(1), [
          phy('costas.rigidez.ombros', 4),
          phy('costas.fisgada.ao_mexer', 2),
        ]),
      ]);
      expect(points.map((p) => p.branchIndex), [0, 1]);
      expect(points.map((p) => p.id).toSet().length, 2);
    });
  });

  group('F1 · mapa corporal', () {
    test('three Costas marks on one day: one day on the marker, three marks',
        () {
      final summaries = regionSummaries(physicalPoints(l10n, [
        e('a', at(3, 8), [phy('costas.rigidez.ombros', 4, side: 'back')]),
        e('b', at(3, 12), [phy('costas.rigidez.ombros', 3, side: 'back')]),
        e('c', at(3, 20), [phy('costas.fisgada.irradia', 2)]),
      ]));
      final costas = summaries.single;
      expect(costas.days, 1);
      expect(costas.marks.length, 3);
      expect(costas.byView, {'back': 2, null: 1});
      expect(costas.top!.count, 2);
      expect(costas.mapView, 'back');
    });

    test('a region in both views counts the union of days', () {
      final summaries = regionSummaries(physicalPoints(l10n, [
        e('a', at(1), [phy('cabeca.pressao.temporas', 2, side: 'front')]),
        e('b', at(1), [phy('cabeca.nuca.rigida', 3, side: 'back')]),
        e('c', at(2), [phy('cabeca.nuca.rigida', 3, side: 'back')]),
      ]));
      expect(summaries.single.days, 2);
      expect(summaries.single.mapView, 'front');
    });
  });

  group('C1 · calendário combinado', () {
    test('head 4 and body 5 stay two values; water sums the day', () {
      final days = calendarDays(
        emotional: emotionalPoints(l10n, [
          e('a', at(15), [emo('presente.energia.desligado', 4)]),
        ]),
        physical: physicalPoints(l10n, [
          e('b', at(15), [phy('costas.rigidez.ombros', 5)]),
        ]),
        waterTotals: {DateTime(2026, 10, 15): 1600, DateTime(2026, 10, 16): 0},
      );
      final day = days[DateTime(2026, 10, 15)]!;
      expect(day.emotional.single.intensity, 4);
      expect(day.physical.single.intensity, 5);
      expect(day.waterMl, 1600);
      expect(formatLiters(day.waterMl!, 'pt-BR'), '1,6 L');
      expect(goalPercent(1600, 2000), 80);
      // A day with 0 ml is a day without a log.
      expect(days.containsKey(DateTime(2026, 10, 16)), isFalse);
    });

    test('weeks start on Monday and days outside the period are flagged', () {
      final start = DateTime(2026, 10, 1); // Thursday
      final weeks = calendarWeeks(start, 30);
      expect(weeks.first.first, DateTime(2026, 9, 28));
      expect(weeks.first.first.weekday, DateTime.monday);
      expect(inPeriod(DateTime(2026, 9, 30), start, 30), isFalse);
      expect(inPeriod(DateTime(2026, 10, 30), start, 30), isTrue);
      expect(inPeriod(DateTime(2026, 10, 31), start, 30), isFalse);
    });
  });

  group('H1–H4 · água', () {
    WaterIntakeEntry log(int ml, int hour) => WaterIntakeEntry(
        userId: 'u', amountMl: ml, timestamp: DateTime(2026, 10, 15, hour));

    test('200 + 500 + 300 = 1.000 ml, 50% of 2.000; 2.400 keeps 120%', () {
      final steps = waterSteps([log(300, 13), log(200, 8), log(500, 10)]);
      expect(steps.map((s) => s.cumulativeMl), [200, 700, 1000]);
      expect(goalPercent(1000, 2000), 50);
      expect(goalPercent(2400, 2000), 120);
      expect(goalPercent(1000, null), isNull);
    });

    test('three days 1.000 / none / 2.000: total 3.000, average 1.500', () {
      final stats = WaterPeriodStats.compute(
        {DateTime(2026, 10, 1): 1000, DateTime(2026, 10, 3): 2000},
        start: DateTime(2026, 10, 1),
        days: 3,
        goalMl: 2000,
      );
      expect(stats.totalMl, 3000);
      expect(stats.daysWithRecord, 2);
      expect(stats.averageMl, 1500);
      expect(stats.daysReachedGoal, 1);
    });
  });

}
