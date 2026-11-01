import 'package:dualis_mobile/features/journal_insights/domain/journal_insights_models.dart';
import 'package:dualis_mobile/features/journal_insights/presentation/widgets/wellbeing_cards.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('Momentos bons: days per time and the most marked, counts only', (tester) async {
    await _pump(
      tester,
      const GoodMomentsSummary(
        summary: JournalSummary(
          positiveByTime: {'presente': 4, 'passado': 1},
          positiveByOptionKey: {
            'presente.calma.paz': 3,
            'presente.conexao.foco': 1,
            'passado.gratidao.alguem': 1,
            'futuro.animo.planos': 1,
          },
        ),
      ),
    );
    expect(find.textContaining('O momento atual · 4 dias'), findsOneWidget);
    expect(find.textContaining('O que já passou · 1 dia'), findsOneWidget);
    expect(find.text('Em paz, tranquilo(a) · 3 dias'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('good_moments_option_')),
      findsNWidgets(GoodMomentsSummary.topCount),
    );
  });

  testWidgets('O que te ajudou: "Você marcou … em N dias" and coping counts', (tester) async {
    await _pump(
      tester,
      const HelpedSummary(
        summary: JournalSummary(
          byHelper: {'pausa': 1, 'conversar': 4},
          byCoping: {'dificil': 2},
        ),
      ),
    );
    expect(find.text('Você marcou “Conversar com alguém” em 4 dias'), findsOneWidget);
    expect(find.text('Você marcou “Uma pausa para respirar” em 1 dia'), findsOneWidget);
    final first = tester.getTopLeft(find.byKey(const Key('helped_conversar')));
    final second = tester.getTopLeft(find.byKey(const Key('helped_pausa')));
    expect(first.dy, lessThan(second.dy));
    expect(find.textContaining('Foi difícil · 2 dias'), findsOneWidget);
  });
}
