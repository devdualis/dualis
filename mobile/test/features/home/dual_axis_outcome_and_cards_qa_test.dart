import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/constants/app_colors.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dual_axis_trigger_card.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/today_triage_result_tab.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget _createTestHarness({
  required Widget child,
  TriageOutcome? outcome,
  TriggerCheckInState? triggerState,
  Locale locale = const Locale('pt', 'BR'),
}) {
  return ProviderScope(
    overrides: [
      if (outcome != null)
        triageOutcomeProvider.overrideWith(
          () => _QAOutcomeNotifier(TriageOutcomeState(outcome: outcome)),
        ),
      if (triggerState != null)
        triggerCheckInProvider.overrideWith(
          () => _QATriggerNotifier(triggerState),
        ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

class _QAOutcomeNotifier extends TriageOutcomeNotifier {
  final TriageOutcomeState _state;
  _QAOutcomeNotifier(this._state);
  @override
  TriageOutcomeState build() => _state;
}

class _QATriggerNotifier extends TriggerCheckInNotifier {
  final TriggerCheckInState _state;
  _QATriggerNotifier(this._state);
  @override
  TriggerCheckInState build() => _state;
}

void main() {
  group('Dual Axis Outcome & Cards QA Tests', () {
    testWidgets('DualAxisTriggerCard displays full summary without clipping when stages are completed',
        (WidgetTester tester) async {
      final triggerState = const TriggerCheckInState(
        isCompletedToday: true,
        isEmotionalCompleted: true,
        emotionalStatus: TriggerStatus.soSo,
        emotionalSummary: 'Ansiedade e agitação',
        emotionalNarrative: 'Muita correria no trabalho hoje',
        isPhysicalCompleted: true,
        physicalStatus: TriggerStatus.soSo,
        physicalSummary: 'Mão e dedos (direita)',
        physicalNarrative: 'Dor ao digitar no teclado',
      );

      await tester.pumpWidget(
        _createTestHarness(
          child: const DualAxisTriggerCard(),
          triggerState: triggerState,
        ),
      );
      await tester.pumpAndSettle();

      // Check titles
      expect(find.text('Psicoemocional'), findsOneWidget);
      expect(find.text('Físico'), findsOneWidget);
      expect(find.text('Moderada (3)'), findsNothing);

      // Chip removed: the completed card's background/border color is now the
      // only tier signal. Both axes are Moderada (3) here.
      final psychoCard = tester.widget<Container>(
        find.byKey(const Key('psicoemocional_completed_card')),
      );
      expect(
        (psychoCard.decoration as BoxDecoration).color,
        AppColors.intensityModerateBg,
      );
      final physCard = tester.widget<Container>(
        find.byKey(const Key('fisica_completed_card')),
      );
      expect(
        (physCard.decoration as BoxDecoration).color,
        AppColors.intensityModerateBg,
      );

      // Check that full summaries are rendered
      expect(find.text('Ansiedade e agitação'), findsOneWidget);
      expect(find.text('Mão e dedos (direita)'), findsOneWidget);

      // Check narratives
      expect(find.text('“Muita correria no trabalho hoje”'), findsOneWidget);
      expect(find.text('“Dor ao digitar no teclado”'), findsOneWidget);

      // Check update buttons
      expect(find.text('Atualizar'), findsNWidgets(2));

      // Verify brand icon colors
      final psychoIcon = tester.widget<Icon>(find.byIcon(Icons.psychology_rounded));
      expect(psychoIcon.color, equals(AppColors.dualisSymbolGreen));

      final physIcon = tester.widget<Icon>(find.byIcon(Icons.accessibility_new_rounded));
      expect(physIcon.color, equals(AppColors.dualisSymbolBlue));
    });

    testWidgets('TodayTriageResultTab reflects BOTH physical and emotional outcomes with articles for both domains',
        (WidgetTester tester) async {
      final physicalOutcome = TriageOutcome(
        id: 'qa-phys-1',
        vertical: 'physical',
        intensityScore: 3,
        primaryCategory: 'membros_superiores',
        categoryLabel: 'Mão e dedos (direita)',
        somaticMapping: 'Dor ao digitar no teclado e desconforto articular no punho',
        recommendedArticles: const [
          RecommendedArticle(
            id: 'art-membros-sup-01',
            title: 'Sobrecarga Musculoesquelética em Braços e Ombros',
            category: 'membros_superiores',
            author: 'Portal Drauzio Varella',
            authorRole: 'Fonte',
            readTimeMinutes: 4,
            summary: 'Identificação de tensões mecânicas e orientações posturais.',
            url: 'https://drauziovarella.uol.com.br/podcasts/tendinite/',
          ),
        ],
        recordedAt: DateTime.now(),
      );

      final triggerState = const TriggerCheckInState(
        isCompletedToday: true,
        isEmotionalCompleted: true,
        emotionalStatus: TriggerStatus.soSo,
        emotionalSummary: 'Ansiedade e agitação',
        emotionalNarrative: 'Ansiedade moderada e agitação',
        isPhysicalCompleted: true,
        physicalStatus: TriggerStatus.soSo,
        physicalSummary: 'Mão e dedos (direita)',
        physicalNarrative: 'Dor ao digitar no teclado',
      );

      await tester.pumpWidget(
        _createTestHarness(
          child: TodayTriageResultTab(onGoToCheckIn: () {}),
          outcome: physicalOutcome,
          triggerState: triggerState,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Both axes must be rendered
      expect(find.text('1. Eixo Avaliação Física'), findsOneWidget);
      expect(find.text('Mão e dedos (direita)'), findsOneWidget);
      expect(find.text('2. Eixo Avaliação Psico-emocional'), findsOneWidget);
      expect(find.text('Ansiedade e agitação'), findsOneWidget);

      // 2. Both cards convey their level through color, without chips.
      expect(find.text('Moderada (3)'), findsNothing);
      for (final label in ['1. Eixo Avaliação Física', '2. Eixo Avaliação Psico-emocional']) {
        final card = tester.widget<Container>(find.ancestor(
          of: find.text(label),
          matching: find.byType(Container),
        ).first);
        expect((card.decoration as BoxDecoration).color, AppColors.intensityModerateBg);
      }

      // 3. Articles section must contain both Physical and Emotional articles
      expect(find.text('Leituras sobre bem-estar'), findsOneWidget);

      // Verify physical article
      expect(find.text('Sobrecarga Musculoesquelética em Braços e Ombros'), findsOneWidget);
      expect(find.text('Portal Drauzio Varella • Fonte'), findsWidgets);
      expect(find.text('Saúde Física'), findsWidgets);

      // Verify emotional article (anxiety management or breathing technique)
      expect(find.text('Manejo da Ansiedade Aguda e Agitação Psicomotora'), findsOneWidget);
      expect(find.text('Saúde Emocional'), findsWidgets);
    });

    testWidgets('TodayTriageResultTab outcome axis cards match ClinicalIntensityTier for physical (2) and associated emotional (4)',
        (WidgetTester tester) async {
      final physicalOutcome = TriageOutcome(
        id: 'qa-neurological-1',
        vertical: 'physical',
        intensityScore: 2,
        primaryCategory: 'neurologico',
        categoryLabel: 'Tontura e equilíbrio',
        somaticMapping: 'Tontura ao levantar',
        secondaryCategoryLabel: 'Estressado(a) ou esgotado(a)',
        secondaryIntensityScore: 4,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
      );

      final triggerState = const TriggerCheckInState(
        isCompletedToday: true,
        isPhysicalCompleted: true,
        physicalStatus: TriggerStatus.soSo,
        physicalIntensity: 2,
        physicalNarrative: 'dor de cabeça',
        isEmotionalCompleted: true,
        emotionalStatus: TriggerStatus.badSick,
        emotionalIntensity: 4,
        emotionalNarrative: 'dor de cabeça',
      );

      await tester.pumpWidget(
        _createTestHarness(
          child: TodayTriageResultTab(onGoToCheckIn: () {}),
          outcome: physicalOutcome,
          triggerState: triggerState,
        ),
      );
      await tester.pumpAndSettle();

      // Each axis uses its own level color, without visible level chips.
      expect(find.text('Leve (1-2)'), findsNothing);
      expect(find.text('Intensa (4-5)'), findsNothing);
      for (final entry in {
        '1. Eixo Avaliação Física': AppColors.intensityMildBg,
        '2. Eixo Avaliação Psico-emocional': AppColors.intensityIntenseBg,
      }.entries) {
        final card = tester.widget<Container>(find.ancestor(
          of: find.text(entry.key),
          matching: find.byType(Container),
        ).first);
        expect((card.decoration as BoxDecoration).color, entry.value);
      }

      // Verify categories
      expect(find.text('Tontura e equilíbrio'), findsOneWidget);
      expect(find.text('2. Eixo Avaliação Psico-emocional'), findsOneWidget);
      expect(find.text('Estressado(a) ou esgotado(a)'), findsOneWidget);
      expect(find.textContaining('Componente Associado'), findsNothing);
    });

    testWidgets(
        'TodayTriageResultTab emotional axis title uses the trigger state summary, not the stale outcome.secondaryCategoryLabel',
        (WidgetTester tester) async {
      // Reproduces the "Meu Dia" bug: a dual check-in where the physical
      // axis was submitted last (outcome.vertical == 'physical') carries a
      // stale secondaryCategoryLabel from an earlier submission. The
      // psico-emocional card title must reflect what the user actually
      // typed for that axis (triggerState.emotionalSummary), matching the
      // home screen and the "Você registrou" line below it — never the
      // physical axis's own label.
      final physicalOutcome = TriageOutcome(
        id: 'qa-stale-secondary-1',
        vertical: 'physical',
        intensityScore: 4,
        primaryCategory: 'geniturinario',
        categoryLabel: 'Baixo ventre e urina',
        somaticMapping: 'Desconforto na região abdominal baixa',
        secondaryCategoryLabel: 'Baixo ventre e urina',
        secondaryIntensityScore: 2,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
      );

      final triggerState = const TriggerCheckInState(
        isCompletedToday: true,
        isPhysicalCompleted: true,
        physicalStatus: TriggerStatus.badSick,
        physicalIntensity: 4,
        physicalSummary: 'Baixo ventre e urina',
        isEmotionalCompleted: true,
        emotionalStatus: TriggerStatus.soSo,
        emotionalIntensity: 2,
        emotionalSummary: 'Pra baixo',
      );

      await tester.pumpWidget(
        _createTestHarness(
          child: TodayTriageResultTab(onGoToCheckIn: () {}),
          outcome: physicalOutcome,
          triggerState: triggerState,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2. Eixo Avaliação Psico-emocional'), findsOneWidget);
      expect(find.text('Pra baixo'), findsOneWidget);
    });

    for (final (locale, physicalLabel, emotionalLabel) in const [
      (Locale('pt', 'BR'), '1. Eixo Avaliação Física', '2. Eixo Avaliação Psico-emocional'),
      (Locale('es'), '1. Eje de Evaluación Física', '2. Eje de Evaluación Psicoemocional'),
      (Locale('en'), '1. Physical Assessment Axis', '2. Psycho-emotional Assessment Axis'),
    ]) {
      testWidgets('dual view axis labels are localized (${locale.languageCode}), associated component card included',
          (WidgetTester tester) async {
        final physicalOutcome = TriageOutcome(
          id: 'qa-l10n-${locale.languageCode}',
          vertical: 'physical',
          intensityScore: 2,
          primaryCategory: 'neurologico',
          categoryLabel: 'Tontura e equilíbrio',
          somaticMapping: 'Tontura ao levantar',
          secondaryCategoryLabel: 'Estressado(a) ou esgotado(a)',
          secondaryIntensityScore: 4,
          recommendedArticles: const [],
          recordedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          _createTestHarness(
            child: TodayTriageResultTab(onGoToCheckIn: () {}),
            outcome: physicalOutcome,
            triggerState: const TriggerCheckInState(
              isCompletedToday: true,
              isPhysicalCompleted: true,
              physicalStatus: TriggerStatus.soSo,
              physicalIntensity: 2,
              isEmotionalCompleted: true,
              emotionalStatus: TriggerStatus.badSick,
              emotionalIntensity: 4,
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(physicalLabel), findsOneWidget);
        expect(find.text(emotionalLabel), findsOneWidget);
        expect(find.text('Estressado(a) ou esgotado(a)'), findsOneWidget);
        expect(find.textContaining('Componente Associado'), findsNothing);
      });
    }
  });
}
