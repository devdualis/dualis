import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/screens/triage_outcome_screen.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/intensity_meter.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/article_card.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/wellness_guidance_block.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/dual_axis_static_note.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

void main() {
  Widget createWidgetForTesting(TriageOutcome outcome) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: TriageOutcomeScreen(outcome: outcome),
      ),
    );
  }

  group('Triage Outcome Screen (wellness)', () {
    final physicalOutcome = TriageOutcome(
      id: 'test-physical-1',
      vertical: 'physical',
      intensityScore: 3,
      primaryCategory: 'coluna_dor_dorsal',
      categoryLabel: 'Coluna e Dor Dorsal',
      somaticMapping: 'Desconforto nas costas',
      recommendedArticles: const [
        RecommendedArticle(
          id: 'art-coluna-01',
          title: 'Ergonomia e postura',
          category: 'coluna_dor_dorsal',
          author: 'Ministério da Saúde',
          authorRole: 'Fonte',
          readTimeMinutes: 5,
          summary: 'Conteúdo educativo geral.',
          url: 'https://www.gov.br/saude/',
        ),
      ],
      recordedAt: DateTime.now(),
    );

    final dualAxisOutcome = TriageOutcome(
      id: 'test-dual-1',
      vertical: 'emotional',
      intensityScore: 3,
      primaryCategory: 'ansiosa_agitacao',
      categoryLabel: 'Agitação',
      somaticMapping: 'Registro emocional',
      loggedBothAxesToday: true,
      recommendedArticles: const [],
      recordedAt: DateTime.now(),
      aiMappedLayTerm: 'cansaço',
      aiBodyAreaOrMood: 'Corpo todo',
    );

    testWidgets('shows summary, intensity, guidance and articles', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetForTesting(physicalOutcome));
      await tester.pumpAndSettle();

      expect(find.text('Resumo do seu registro'), findsOneWidget);
      expect(find.text('Coluna e Dor Dorsal'), findsOneWidget);
      expect(find.byType(IntensityMeter), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.byType(WellnessGuidanceBlock), findsOneWidget);
      expect(find.byType(ArticleCard), findsOneWidget);
      expect(find.text('Ergonomia e postura'), findsOneWidget);
    });

    testWidgets('shows dual-axis static note when both axes logged', (tester) async {
      await tester.pumpWidget(createWidgetForTesting(dualAxisOutcome));
      await tester.pumpAndSettle();

      expect(find.byType(DualAxisStaticNote), findsOneWidget);
      expect(find.textContaining('corpo e nas emoções'), findsOneWidget);
    });
  });
}
