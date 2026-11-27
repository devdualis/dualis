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

  Future<void> pump(WidgetTester tester, Widget child, {String locale = 'pt'}) =>
      tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ));

  group('WeekdayBars', () {
    testWidgets('shows seven bars and no sentence', (tester) async {
      await pump(
        tester,
        WeekdayBars(
          counts: recordsByWeekday([e(0, const []), e(1, const [])]),
        ),
      );
      for (var d = 1; d <= 7; d++) {
        expect(find.byKey(Key('period_weekday_$d')), findsOneWidget);
      }
      expect(find.byKey(const Key('period_weekday_most')), findsNothing);
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
}
