import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/screens/triage_outcome_screen.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/intensity_meter.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/disposition_card.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/organic_primacy_banner.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/article_card.dart';

void main() {
  Widget createWidgetForTesting(TriageOutcome outcome) {
    return ProviderScope(
      child: MaterialApp(
        home: TriageOutcomeScreen(outcome: outcome),
      ),
    );
  }

  group('Screen 6: Triage Outcome Screen Widget Tests', () {
    final physicalOutcome = TriageOutcome(
      id: 'test-physical-1',
      vertical: 'physical',
      intensityScore: 3,
      careDisposition: CareDisposition.routineConsultation,
      primaryCategory: 'coluna_dor_dorsal',
      categoryLabel: 'Coluna e Dor Dorsal',
      somaticMapping: 'Dor lombar / Tensão paravertebral postural',
      organicPrimacyApplied: false,
      recommendedArticles: const [
        RecommendedArticle(
          id: 'art-coluna-01',
          title: 'Ergonomia no Trabalho e Prevenção de Dores Lombares',
          category: 'coluna_dor_dorsal',
          author: 'Dr. Marcelo Mendes',
          authorRole: 'Ortopedista e Traumatologista',
          readTimeMinutes: 5,
          summary: 'Posturas preventivas e pausas ativas no home office.',
          url: 'https://dualis.health/artigos/coluna',
        ),
      ],
      recordedAt: DateTime.now(),
    );

    final emotionalOutcomeWithOrganicPrimacy = TriageOutcome(
      id: 'test-emotional-1',
      vertical: 'emotional',
      intensityScore: 3,
      careDisposition: CareDisposition.routineConsultation,
      primaryCategory: 'ansiosa_agitacao',
      categoryLabel: 'Dimensão Ansiosa / Agitação',
      somaticMapping: 'Ansiedade com manifestação somática torácica',
      organicPrimacyApplied: true,
      organicPrimacyNotice:
          'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem avaliação médica prioritária.',
      recommendedArticles: const [
        RecommendedArticle(
          id: 'art-ansiedade-01',
          title: 'Manejo da Ansiedade Aguda com Respiração Diafragmática',
          category: 'ansiosa_agitacao',
          author: 'Dra. Camila Prado',
          authorRole: 'Psiquiatra Clínica',
          readTimeMinutes: 4,
          summary: 'Exercício guiado para desaceleração do sistema simpático.',
          url: 'https://dualis.health/artigos/ansiedade',
        ),
      ],
      recordedAt: DateTime.now(),
    );

    testWidgets('1. Renders physical triage outcome with score 3, routine care disposition and specialist article',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetForTesting(physicalOutcome));
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Resultado da Triagem'), findsOneWidget);

      // Verify Category Label
      expect(find.text('Coluna e Dor Dorsal'), findsOneWidget);
      expect(find.text('Dor lombar / Tensão paravertebral postural'), findsOneWidget);

      // Verify Intensity Meter
      expect(find.byType(IntensityMeter), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);

      // Verify Disposition Card
      expect(find.byType(DispositionCard), findsOneWidget);
      expect(find.text('Consulta de Rotina'), findsOneWidget);

      // Verify Organic Primacy Banner is NOT shown
      expect(find.byType(OrganicPrimacyBanner), findsNothing);

      // Verify Specialist Article
      expect(find.byType(ArticleCard), findsOneWidget);
      expect(find.text('Ergonomia no Trabalho e Prevenção de Dores Lombares'), findsOneWidget);
      expect(find.textContaining('Dr. Marcelo Mendes'), findsOneWidget);

      // Verify Finish Button
      expect(find.text('Concluir e Voltar ao Início'), findsOneWidget);
    });

    testWidgets('2. Renders emotional triage outcome with Organic Primacy banner active (SOM-02)',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetForTesting(emotionalOutcomeWithOrganicPrimacy));
      await tester.pumpAndSettle();

      // Verify Emotional Category Label
      expect(find.text('Dimensão Ansiosa / Agitação'), findsOneWidget);

      // Verify Organic Primacy Banner IS displayed
      expect(find.byType(OrganicPrimacyBanner), findsOneWidget);
      expect(find.text('Atenção Clínica: Primazia Orgânica'), findsOneWidget);
      expect(
        find.textContaining('Sintomas físicos concorrentes exigem avaliação médica prioritária'),
        findsOneWidget,
      );

      // Verify Care Disposition
      expect(find.byType(DispositionCard), findsOneWidget);
      expect(find.text('Consulta de Rotina'), findsOneWidget);

      // Verify Specialist Article
      expect(find.text('Manejo da Ansiedade Aguda com Respiração Diafragmática'), findsOneWidget);
      expect(find.textContaining('Dra. Camila Prado'), findsOneWidget);
    });
  });
}
