import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/journal_insights/domain/journal_insights_models.dart';
import 'package:dualis_mobile/features/journal_insights/domain/period_report.dart';
import 'package:dualis_mobile/features/journal_insights/presentation/widgets/period_report_widgets.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

void main() {
  // Wednesday.
  final today = DateTime(2026, 10, 28, 9);
  var seq = 0;

  JournalEntryView e(
    int daysAgo,
    List<JournalItemView> items, {
    String mood = 'nao_tao_bem',
  }) =>
      JournalEntryView(
        id: 'w${seq++}',
        recordedAt: today.subtract(Duration(days: daysAgo)),
        mood: mood,
        items: items,
      );

  JournalItemView emo(String key) =>
      JournalItemView(kind: 'emotional', optionKey: key);
  JournalItemView body(String key) =>
      JournalItemView(kind: 'physical', optionKey: key);

  Future<void> pump(WidgetTester tester, Widget child, {String locale = 'pt'}) =>
      tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ));

  group('PeriodSummary', () {
    testWidgets('states the "não tão bem" share and the busiest weekdays',
        (tester) async {
      await pump(
        tester,
        PeriodSummary(days: 14, entries: [
          e(1, [emo('futuro.mente.antecipar')]), // Tuesday
          e(6, [emo('futuro.medo.evitar')]), // Thursday
          e(8, [emo('passado.memoria.magoa')]), // Tuesday
          e(13, [body('peito.respiracao.curta')]), // Thursday
          e(0, const [], mood: 'bem'), // Wednesday
        ]),
      );
      expect(
        find.text('Nos últimos 14 dias, 2 de 4 registros de “não tão bem” '
            'foram sobre o futuro.'),
        findsOneWidget,
      );
      expect(
        find.text('Você registrou mais nas terças e nas quintas.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('period_weekday_bars')), findsOneWidget);
      for (var d = 1; d <= 7; d++) {
        expect(find.byKey(Key('period_weekday_$d')), findsOneWidget);
      }
    });

    testWidgets('one sentence per tied time, singular verb for one record',
        (tester) async {
      await pump(
        tester,
        PeriodSummary(days: 7, entries: [
          e(0, [emo('futuro.mente.antecipar')]),
          e(1, [emo('passado.memoria.magoa')]),
        ]),
      );
      expect(find.byKey(const Key('period_not_well_passado')), findsOneWidget);
      expect(find.byKey(const Key('period_not_well_futuro')), findsOneWidget);
      expect(
        find.text('Nos últimos 7 dias, 1 de 2 registros de “não tão bem” '
            'foi sobre o passado.'),
        findsOneWidget,
      );
    });

    testWidgets('only "bem" records: no sentence, bars still shown',
        (tester) async {
      await pump(
        tester,
        PeriodSummary(days: 14, entries: [e(0, const [], mood: 'bem')]),
      );
      expect(find.byKey(const Key('period_not_well_futuro')), findsNothing);
      // One weekday only: it is the most recorded one.
      expect(find.text('Você registrou mais nas quartas.'), findsOneWidget);
      expect(find.byKey(const Key('period_weekday_bars')), findsOneWidget);
    });

    testWidgets('English and Spanish read naturally', (tester) async {
      final entries = [
        e(1, [emo('futuro.mente.antecipar')]),
        e(8, [emo('futuro.medo.evitar')]),
      ];
      await pump(tester, PeriodSummary(days: 14, entries: entries),
          locale: 'en');
      expect(
        find.text('In the last 14 days, 2 of your 2 “not so good” records '
            'were about the future.'),
        findsOneWidget,
      );
      expect(find.text('You recorded most on Tuesdays.'), findsOneWidget);

      await pump(tester, PeriodSummary(days: 14, entries: entries),
          locale: 'es');
      expect(find.text('Registraste más los martes.'), findsOneWidget);
    });
  });

  group('EverydayFeelingsSummary', () {
    testWidgets('shows the four feelings in fixed order with counts',
        (tester) async {
      final counts = EverydayFeelingCounts.compute([
        e(0, [emo('passado.tristeza.culpa')]),
        e(1, [emo('futuro.mente.antecipar'), emo('presente.sobrecarga.aperto')]),
        e(2, const [], mood: 'bem'),
      ]);
      await pump(tester, EverydayFeelingsSummary(counts: counts));

      final labels = [
        'Pesado / desanimado',
        'Agitado / preocupado',
        'Irritado / sem paciência',
        'Tranquilo / bem',
      ];
      final ys = [
        for (final l in labels) tester.getTopLeft(find.text(l)).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(find.text('1 de 3 registros'), findsNWidgets(4));
    });

    testWidgets('a feeling with no records shows 0, not hidden', (tester) async {
      final counts = EverydayFeelingCounts.compute([
        e(0, const [], mood: 'bem'),
      ]);
      await pump(tester, EverydayFeelingsSummary(counts: counts));
      expect(find.byKey(const Key('feeling_pesado')), findsOneWidget);
      expect(find.text('0 de 1 registro'), findsNWidgets(3));
      expect(find.text('1 de 1 registro'), findsOneWidget);
    });
  });

  group('BodyMindCoincidenceList', () {
    testWidgets('describes days only and adds the same-day note',
        (tester) async {
      final list = bodyMindCoincidences([
        e(0, [emo('futuro.mente.antecipar'), body('peito.respiracao.curta')]),
        e(3, [emo('futuro.mente.cobranca'), body('peito.incomodo.costelas')]),
        e(5, [emo('futuro.mente.indecisao'), body('peito.respiracao.tosse')]),
      ]);
      await pump(tester, BodyMindCoincidenceList(coincidences: list, days: 14));
      expect(
        find.text('Em 3 dos últimos 14 dias você registrou, no mesmo dia, '
            '“Mente acelerada” e “Peito”.'),
        findsOneWidget,
      );
      expect(
        find.text('Estar no mesmo dia não indica relação entre os itens.'),
        findsOneWidget,
      );
    });

    testWidgets('shows at most five lines and sums up the rest',
        (tester) async {
      final list = bodyMindCoincidences([
        e(0, [
          emo('futuro.mente.antecipar'),
          emo('passado.memoria.magoa'),
          body('peito.respiracao.curta'),
          body('cabeca.pressao.temporas'),
          body('costas.rigidez.ombros'),
        ]),
      ]);
      expect(list.length, 6);
      await pump(tester, BodyMindCoincidenceList(coincidences: list, days: 7));
      expect(find.textContaining('Em 1 dos últimos 7 dias'), findsNWidgets(5));
      expect(find.text('e mais 1 combinação'), findsOneWidget);
    });

    testWidgets('skips pairs whose keys have no text', (tester) async {
      const list = [
        BodyMindCoincidence(emotional: 'futuro.ramo_novo', region: 'peito', days: 2),
      ];
      await tester.pumpWidget(const SizedBox());
      final l10n = lookupAppLocalizations(const Locale('pt'));
      expect(BodyMindCoincidenceList.labelled(l10n, list), isEmpty);
    });
  });
}
