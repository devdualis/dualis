import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/today_triage_result_tab.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/screens/triage_outcome_screen.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/article_card.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/dual_axis_static_note.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/wellness_guidance_block.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createDualEquivalenceWrapper({
  required Widget child,
  required TriageOutcome outcome,
  TriggerCheckInState? triggerCheckInState,
}) {
  return ProviderScope(
    overrides: [
      triageOutcomeProvider.overrideWith(
        () => _StaticTriageOutcomeNotifier(
          TriageOutcomeState(outcome: outcome),
        ),
      ),
      if (triggerCheckInState != null)
        triggerCheckInProvider.overrideWith(
          () => _StaticTriggerCheckInNotifier(triggerCheckInState),
        ),
    ],
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

class _StaticTriageOutcomeNotifier extends TriageOutcomeNotifier {
  final TriageOutcomeState _initial;
  _StaticTriageOutcomeNotifier(this._initial);

  @override
  TriageOutcomeState build() => _initial;
}

class _StaticTriggerCheckInNotifier extends TriggerCheckInNotifier {
  final TriggerCheckInState _initial;
  _StaticTriggerCheckInNotifier(this._initial);

  @override
  TriggerCheckInState build() => _initial;
}

TriageOutcome createBaseMockOutcome({
  String id = 'out-base',
  String vertical = 'physical',
  int intensityScore = 2,
  String primaryCategory = 'cabeca_pescoco',
  String categoryLabel = 'Cabeça e pescoço',
  String somaticMapping = 'Dor de cabeça e tensão no pescoço',
  bool loggedBothAxesToday = false,
  String? secondaryCategoryLabel,
  String? secondarySomaticMapping,
  int? secondaryIntensityScore,
  String? aiMappedLayTerm,
  String? aiBodyAreaOrMood,
  String? aiSource,
  bool isCrossVerticalSomatic = false,
  String? crossVerticalContextNote,
  List<RecommendedArticle>? recommendedArticles,
  DateTime? recordedAt,
}) {
  return TriageOutcome(
    id: id,
    vertical: vertical,
    intensityScore: intensityScore,
    primaryCategory: primaryCategory,
    categoryLabel: categoryLabel,
    somaticMapping: somaticMapping,
    loggedBothAxesToday: loggedBothAxesToday,
    secondaryCategoryLabel: secondaryCategoryLabel,
    secondarySomaticMapping: secondarySomaticMapping,
    secondaryIntensityScore: secondaryIntensityScore,
    aiMappedLayTerm: aiMappedLayTerm,
    aiBodyAreaOrMood: aiBodyAreaOrMood,
    aiSource: aiSource,
    isCrossVerticalSomatic: isCrossVerticalSomatic,
    crossVerticalContextNote: crossVerticalContextNote,
    recommendedArticles: recommendedArticles ??
        const [
          RecommendedArticle(
            id: 'art-1',
            title: 'Prevenção de Cefaleias Tensionais',
            category: 'cabeca_pescoco',
            author: 'Sociedade Brasileira de Cefaleia',
            authorRole: 'Fonte',
            readTimeMinutes: 4,
            summary: 'Orientações para alívio de cefaleias',
            url: 'https://sbcefaleia.com.br/noticias.php?id=350',
          ),
        ],
    recordedAt: recordedAt ?? DateTime(2026, 9, 17, 10, 30),
  );
}

final AppLocalizations _pt = lookupAppLocalizations(const Locale('pt'));

/// Care recommendations that existed before the wellness repositioning. None
/// of them may appear anywhere now.
const List<String> _removedDispositionLabels = [
  'Auto-cuidado Monitorado',
  'Consulta de Rotina',
  'Pronto Atendimento (24h)',
  'Atendimento de Emergência',
];

void _expectStaticGuidanceOnly(WidgetTester tester) {
  expect(find.byType(WellnessGuidanceBlock), findsOneWidget);
  expect(find.text(_pt.outcomeStaticGuidance), findsOneWidget);
  for (final label in _removedDispositionLabels) {
    expect(find.text(label), findsNothing, reason: '"$label" is a care recommendation');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Triage Outcome vs Daily Result Equivalence Battery (36 Tests)', () {
    // -------------------------------------------------------------
    // BLOCK 1: SELF-REPORTED INTENSITY (Tests 1 to 5)
    // The IntensityMeter card is redundant on "Meu Dia" now that each axis
    // card already carries its own tier badge (Leve/Moderada/Intensa), so it
    // was removed there on purpose. TriageOutcomeScreen (the immediate,
    // single-axis result right after a triage) has no such per-axis badge,
    // so it keeps the meter as the only place conveying the self-reported
    // score.
    // -------------------------------------------------------------
    testWidgets('1. Self-reported intensity 1: no longer duplicated on "Meu Dia", still shown on TriageOutcomeScreen',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(intensityScore: 1);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('1 / 5'), findsNothing);
      expect(find.text(_pt.outcomeIntensityTitle), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('1 / 5'), findsOneWidget);
      expect(find.text(_pt.outcomeIntensityTitle), findsOneWidget);
    });

    testWidgets('2. Self-reported intensity 2: no longer duplicated on "Meu Dia", still shown on TriageOutcomeScreen',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(intensityScore: 2);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('2 / 5'), findsNothing);
      expect(find.text(_pt.outcomeIntensityTitle), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('2 / 5'), findsOneWidget);
      expect(find.text(_pt.outcomeIntensityTitle), findsOneWidget);
    });

    testWidgets('3. Self-reported intensity 3: no longer duplicated on "Meu Dia", still shown on TriageOutcomeScreen',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(intensityScore: 3);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('3 / 5'), findsNothing);
      expect(find.text(_pt.outcomeIntensityTitle), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.text(_pt.outcomeIntensityTitle), findsOneWidget);
    });

    testWidgets('4. Self-reported intensity 4: no longer duplicated on "Meu Dia", still shown on TriageOutcomeScreen',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(intensityScore: 4);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('4 / 5'), findsNothing);
      expect(find.text(_pt.outcomeIntensityTitle), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('4 / 5'), findsOneWidget);
      expect(find.text(_pt.outcomeIntensityTitle), findsOneWidget);
    });

    testWidgets('5. Self-reported intensity 5: no longer duplicated on "Meu Dia", still shown on TriageOutcomeScreen',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(intensityScore: 5);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('5 / 5'), findsNothing);
      expect(find.text(_pt.outcomeIntensityTitle), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('5 / 5'), findsOneWidget);
      expect(find.text(_pt.outcomeIntensityTitle), findsOneWidget);
    });

    // -------------------------------------------------------------
    // BLOCK 2: STATIC GUIDANCE, SAME FOR EVERYONE (Tests 6 to 9)
    // The care recommendation (self-care / routine / urgent / emergency) was
    // removed on purpose: every intensity shows the same static block.
    // -------------------------------------------------------------
    testWidgets('6. Intensity 1: same static guidance block and no care recommendation on both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(intensityScore: 1);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      _expectStaticGuidanceOnly(tester);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      _expectStaticGuidanceOnly(tester);
    });

    testWidgets('7. Intensity 3: same static guidance block and no care recommendation on both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(intensityScore: 3);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      _expectStaticGuidanceOnly(tester);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      _expectStaticGuidanceOnly(tester);
    });

    testWidgets('8. Intensity 4: same static guidance block and no care recommendation on both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(intensityScore: 4);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      _expectStaticGuidanceOnly(tester);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      _expectStaticGuidanceOnly(tester);
    });

    testWidgets('9. Intensity 5: same static guidance block and no care recommendation on both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(intensityScore: 5);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      _expectStaticGuidanceOnly(tester);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      _expectStaticGuidanceOnly(tester);
    });

    // -------------------------------------------------------------
    // BLOCK 3: PHYSICAL CATEGORY & SOMATIC MAPPING (Tests 10 to 14)
    // -------------------------------------------------------------
    testWidgets('10. Cabeça e Pescoço category and somatic description match',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'cabeca_pescoco',
        categoryLabel: 'Cabeça e pescoço',
        somaticMapping: 'Dor de cabeça e tensão no pescoço',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cabeça e pescoço'), findsOneWidget);
      expect(find.text('Dor de cabeça e tensão no pescoço'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cabeça e pescoço'), findsOneWidget);
      expect(find.text('Dor de cabeça e tensão no pescoço'), findsOneWidget);
    });

    testWidgets('11. Peito category and somatic description match',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'cardiovascular_torax',
        categoryLabel: 'Peito',
        somaticMapping: 'Aperto no peito e coração acelerado',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Peito'), findsOneWidget);
      expect(find.text('Aperto no peito e coração acelerado'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Peito'), findsOneWidget);
      expect(find.text('Aperto no peito e coração acelerado'), findsOneWidget);
    });

    testWidgets('12. Costas category and somatic description match',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'coluna_dor_lombar',
        categoryLabel: 'Costas',
        somaticMapping: 'Dor nas costas ao sentar',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Costas'), findsOneWidget);
      expect(find.text('Dor nas costas ao sentar'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Costas'), findsOneWidget);
      expect(find.text('Dor nas costas ao sentar'), findsOneWidget);
    });

    testWidgets('13. Pele category and somatic description match',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'dermatologico',
        categoryLabel: 'Pele',
        somaticMapping: 'Coceira e incômodo na pele',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Pele'), findsOneWidget);
      expect(find.text('Coceira e incômodo na pele'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Pele'), findsOneWidget);
      expect(find.text('Coceira e incômodo na pele'), findsOneWidget);
    });

    testWidgets('14. Braços e mãos category and somatic description match',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'membros_superiores',
        categoryLabel: 'Braços e mãos',
        somaticMapping: 'Dor nos braços e ombros',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Braços e mãos'), findsOneWidget);
      expect(find.text('Dor nos braços e ombros'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Braços e mãos'), findsOneWidget);
      expect(find.text('Dor nos braços e ombros'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // BLOCK 4: PSYCHO-EMOTIONAL DIMENSIONS (Tests 15 to 18)
    // -------------------------------------------------------------
    testWidgets('15. Ansiedade e agitação matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'ansiosa_agitacao',
        categoryLabel: 'Ansiedade e agitação',
        somaticMapping: 'Inquietação e preocupação',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Ansiedade e agitação'), findsOneWidget);
      expect(find.text('Inquietação e preocupação'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Ansiedade e agitação'), findsOneWidget);
      expect(find.text('Inquietação e preocupação'), findsOneWidget);
    });

    testWidgets('16. Pra baixo matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'depressiva_desanimo',
        categoryLabel: 'Pra baixo',
        somaticMapping: 'Desânimo e pouca energia',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Pra baixo'), findsOneWidget);
      expect(find.text('Desânimo e pouca energia'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Pra baixo'), findsOneWidget);
      expect(find.text('Desânimo e pouca energia'), findsOneWidget);
    });

    testWidgets('17. Estressado(a) ou esgotado(a) matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'estresse_burnout',
        categoryLabel: 'Estressado(a) ou esgotado(a)',
        somaticMapping: 'Cansaço e sobrecarga',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Estressado(a) ou esgotado(a)'), findsOneWidget);
      expect(find.text('Cansaço e sobrecarga'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Estressado(a) ou esgotado(a)'), findsOneWidget);
      expect(find.text('Cansaço e sobrecarga'), findsOneWidget);
    });

    testWidgets('18. Cansaço mental e foco matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'cognitiva_foco',
        categoryLabel: 'Cansaço mental e foco',
        somaticMapping: 'Dificuldade de concentração',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cansaço mental e foco'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cansaço mental e foco'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // BLOCK 5: DUAL COMPONENT & SOMATIC MAPPING (Tests 19 to 21)
    // -------------------------------------------------------------
    testWidgets('19. Secondary category label matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'cabeca_pescoco',
        categoryLabel: 'Cabeça e pescoço',
        secondaryCategoryLabel: 'Estressado(a) ou esgotado(a)',
        secondarySomaticMapping: 'Cansaço e sobrecarga no dia',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('2. Eixo Avaliação Psico-emocional'), findsOneWidget);
      expect(find.text('Estressado(a) ou esgotado(a)'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Estressado(a) ou esgotado(a)'), findsOneWidget);
    });

    testWidgets('20. Secondary somatic mapping matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'cabeca_pescoco',
        categoryLabel: 'Cabeça e pescoço',
        secondaryCategoryLabel: 'Ansiedade e agitação',
        secondarySomaticMapping: 'Inquietação e preocupação',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Inquietação e preocupação'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Inquietação e preocupação'), findsOneWidget);
    });

    testWidgets('21. Dual triage without secondary component renders cleanly on both',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        secondaryCategoryLabel: null,
        secondarySomaticMapping: null,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Componente Associado:'), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Componente Associado:'), findsNothing);
    });

    // -------------------------------------------------------------
    // BLOCK 6: DUAL-AXIS STATIC NOTE (Tests 22 to 24)
    // Replaces the removed "organic primacy" reasoning with a static note.
    // -------------------------------------------------------------
    testWidgets('22. Static dual-axis note is shown on both screens when both axes were logged',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(loggedBothAxesToday: true);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(DualAxisStaticNote), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(DualAxisStaticNote), findsOneWidget);
    });

    testWidgets('23. Dual-axis note is absent on both when only one axis was logged',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(loggedBothAxesToday: false);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(DualAxisStaticNote), findsNothing);
      expect(find.textContaining('Primazia Orgânica'), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(DualAxisStaticNote), findsNothing);
      expect(find.textContaining('Primazia Orgânica'), findsNothing);
    });

    testWidgets('24. Dual-axis note text is the same static copy on both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(loggedBothAxesToday: true);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(_pt.outcomeDualAxisNote), findsOneWidget);
      expect(find.textContaining(RegExp('orgânica|somatiza', caseSensitive: false)), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(_pt.outcomeDualAxisNote), findsOneWidget);
      expect(find.textContaining(RegExp('orgânica|somatiza', caseSensitive: false)), findsNothing);
    });

    // -------------------------------------------------------------
    // BLOCK 7: REDUNDANT ORGANIZATION CARD REMOVED (Tests 25 to 27)
    // -------------------------------------------------------------
    testWidgets('25. AI tags do not add redundant lay-term text to either result screen',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        aiMappedLayTerm: 'dor de cabeça latejante',
        aiBodyAreaOrMood: 'Cabeça',
        aiSource: 'gemini',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(_pt.outcomeAiInsightLayTerm('dor de cabeça latejante')), findsNothing);
      expect(find.text(outcome.categoryLabel), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(_pt.outcomeAiInsightLayTerm('dor de cabeça latejante')), findsNothing);
      expect(find.text(outcome.categoryLabel), findsOneWidget);
    });

    testWidgets('26. Organization title and area are omitted on both screens even with AI tags',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        aiMappedLayTerm: 'dor nas costas ao sentar',
        aiBodyAreaOrMood: 'Costas',
        aiSource: 'gemini',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(_pt.outcomeAiInsightTitle), findsNothing);
      expect(find.text(_pt.outcomeAiInsightArea('Costas')), findsNothing);
      expect(find.text('Informação Clínica Complementar'), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(_pt.outcomeAiInsightTitle), findsNothing);
      expect(find.text(_pt.outcomeAiInsightArea('Costas')), findsNothing);
      expect(find.text('Informação Clínica Complementar'), findsNothing);
    });

    testWidgets('27. Organization card is omitted on both screens when there are no AI tags',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        aiMappedLayTerm: null,
        aiBodyAreaOrMood: null,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(_pt.outcomeAiInsightTitle), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(_pt.outcomeAiInsightTitle), findsNothing);
      expect(find.text('Informação Clínica Complementar'), findsNothing);
    });

    // -------------------------------------------------------------
    // BLOCK 8: RECOMMENDED ARTICLES PARITY (Tests 28 to 30)
    // -------------------------------------------------------------
    testWidgets('28. Both screens show the same general readings, not entry-based ones',
        (WidgetTester tester) async {
      const List<RecommendedArticle> testArticles = [
        RecommendedArticle(
          id: 'art-coluna',
          title: 'Guia de Saúde da Coluna Lombar',
          category: 'coluna',
          author: 'Ministério da Saúde',
          authorRole: 'Fonte',
          readTimeMinutes: 5,
          summary: 'Cuidados para a coluna lombar',
          url: 'https://exemplo.com/coluna',
        ),
      ];
      final outcome = createBaseMockOutcome(
        recommendedArticles: testArticles,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      // Readings never follow the entry: the general list is shown instead.
      expect(find.text('Guia de Saúde da Coluna Lombar'), findsNothing);
      expect(find.text('Higiene do Sono e Repouso Restaurador'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Guia de Saúde da Coluna Lombar'), findsNothing);
      expect(find.text('Higiene do Sono e Repouso Restaurador'), findsOneWidget);
    });

    testWidgets('29. Multiple article counts match on both screens',
        (WidgetTester tester) async {
      const List<RecommendedArticle> multipleArticles = [
        RecommendedArticle(
          id: 'art-ansiedade',
          title: 'Artigo Um: Respiração Consciente',
          category: 'ansiedade',
          author: 'Ministério da Saúde',
          authorRole: 'Fonte',
          readTimeMinutes: 3,
          summary: 'Técnicas de respiração',
          url: 'https://exemplo.com/1',
        ),
        RecommendedArticle(
          id: 'art-sono',
          title: 'Artigo Dois: Higiene do Sono',
          category: 'sono',
          author: 'Associação Brasileira do Sono',
          authorRole: 'Fonte',
          readTimeMinutes: 4,
          summary: 'Orientações para sono reparador',
          url: 'https://exemplo.com/2',
        ),
      ];
      final outcome = createBaseMockOutcome(
        recommendedArticles: multipleArticles,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      final todayCount = find.byType(ArticleCard).evaluate().length;
      expect(find.text('Artigo Um: Respiração Consciente'), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Artigo Um: Respiração Consciente'), findsNothing);
      expect(find.byType(ArticleCard).evaluate().length, todayCount);
    });

    testWidgets('30. Empty article list: both screens show the general catalog',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'cabeca_pescoco',
        recommendedArticles: const [], // empty list
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(_pt.outcomeWellnessReadingsTitle), findsOneWidget);
      expect(find.byType(ArticleCard), findsWidgets);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(_pt.outcomeWellnessReadingsTitle), findsOneWidget);
      expect(find.byType(ArticleCard), findsWidgets);
    });

    // -------------------------------------------------------------
    // BLOCK 9: UPDATE FLOWS & STATE SYNCHRONIZATION (Tests 31 to 35)
    // -------------------------------------------------------------
    test('31. markCompletedWithOutcome synchronizes TriggerCheckInState perfectly with TriageOutcome',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockOutcome = createBaseMockOutcome(
        intensityScore: 4,
        primaryCategory: 'cardiovascular_torax',
        categoryLabel: 'Peito',
        aiMappedLayTerm: 'aperto no peito',
      );

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.markCompletedWithOutcome(mockOutcome, narrative: 'aperto no peito');

      final checkInState = container.read(triggerCheckInProvider);
      expect(checkInState.isCompletedToday, isTrue);
      expect(checkInState.physicalStatus, TriggerStatus.badSick);
      expect(checkInState.naturalLanguageText, 'aperto no peito');
      expect(checkInState.isModifiedAfterCompletion, isFalse);
    });

    test('32. Updating triage outcome updates Daily Result without clobbering by daily check-in',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial mild triage
      final initialOutcome = createBaseMockOutcome(
        id: 'triage-1',
        intensityScore: 2,
        categoryLabel: 'Cabeça e pescoço',
      );

      container.read(triageOutcomeProvider.notifier).setOutcome(initialOutcome);
      container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(initialOutcome);

      expect(container.read(triageOutcomeProvider).outcome?.intensityScore, 2);
      expect(container.read(triageOutcomeProvider).outcome?.categoryLabel, 'Cabeça e pescoço');

      // User updates triage to severe cardiovascular
      final updatedOutcome = createBaseMockOutcome(
        id: 'triage-2',
        intensityScore: 4,
        primaryCategory: 'cardiovascular_torax',
        categoryLabel: 'Peito',
      );

      container.read(triageOutcomeProvider.notifier).setOutcome(updatedOutcome);
      container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(updatedOutcome);

      final activeOutcome = container.read(triageOutcomeProvider).outcome;
      expect(activeOutcome?.id, 'triage-2');
      expect(activeOutcome?.intensityScore, 4);
      expect(activeOutcome?.categoryLabel, 'Peito');

      // Calling markCompletedToday does not overwrite activeOutcome with generic check-in
      container.read(triggerCheckInProvider.notifier).markCompletedToday();
      expect(container.read(triageOutcomeProvider).outcome?.id, 'triage-2');
      expect(container.read(triageOutcomeProvider).outcome?.intensityScore, 4);
    });

    test('33. Updating from physical triage to emotional triage updates Daily Result category',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final physicalOutcome = createBaseMockOutcome(
        vertical: 'physical',
        primaryCategory: 'dermatologico',
        categoryLabel: 'Pele',
      );
      container.read(triageOutcomeProvider.notifier).setOutcome(physicalOutcome);
      container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(physicalOutcome);

      expect(container.read(triageOutcomeProvider).outcome?.categoryLabel, 'Pele');

      final emotionalOutcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'estresse_burnout',
        categoryLabel: 'Estressado(a) ou esgotado(a)',
      );
      container.read(triageOutcomeProvider.notifier).setOutcome(emotionalOutcome);
      container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(emotionalOutcome);

      expect(container.read(triageOutcomeProvider).outcome?.categoryLabel, 'Estressado(a) ou esgotado(a)');
      expect(container.read(triggerCheckInProvider).isCompletedToday, isTrue);
    });

    testWidgets('34. prepareForUpdate is triggered when tapping Atualizar registro de hoje',
        (WidgetTester tester) async {
      bool calledGoToCheckIn = false;
      final outcome = createBaseMockOutcome(intensityScore: 3);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: TodayTriageResultTab(
                onGoToCheckIn: () => calledGoToCheckIn = true,
              ),
            ),
          ),
        ),
      );

      container.read(triageOutcomeProvider.notifier).setOutcome(outcome);
      container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(outcome);
      await tester.pumpAndSettle();

      expect(container.read(triggerCheckInProvider).isModifiedAfterCompletion, isFalse);

      final buttonFinder = find.byKey(const Key('today_retake_triage_button'));
      expect(buttonFinder, findsOneWidget);

      await tester.scrollUntilVisible(buttonFinder, 100);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(calledGoToCheckIn, isTrue);
      expect(container.read(triggerCheckInProvider).isModifiedAfterCompletion, isTrue);
    });

    test('35. TriageOutcome serialization round-trip maintains exact values', () {
      final original = createBaseMockOutcome(
        id: 'round-trip-test',
        vertical: 'physical',
        intensityScore: 3,
        primaryCategory: 'respiratorio',
        categoryLabel: 'Respiração',
        somaticMapping: 'Falta de ar ao subir escadas',
        loggedBothAxesToday: true,
        secondaryCategoryLabel: 'Estressado(a) ou esgotado(a)',
        secondarySomaticMapping: 'Cansaço e sobrecarga',
        secondaryIntensityScore: 3,
        aiMappedLayTerm: 'falta de ar ao cansar',
        aiBodyAreaOrMood: 'Respiração',
        aiSource: 'gemini',
        isCrossVerticalSomatic: true,
        crossVerticalContextNote: 'Nota de contexto cruzado',
      );

      final json = original.toJson();
      for (final removed in ['careDisposition', 'organicPrimacyApplied', 'organicPrimacyNotice', 'aiClinicalConcept', 'urgencyScore', 'isEmergencyCandidate']) {
        expect(json.containsKey(removed), isFalse, reason: '$removed was removed from the contract');
      }
      final restored = TriageOutcome.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.vertical, original.vertical);
      expect(restored.intensityScore, original.intensityScore);
      expect(restored.primaryCategory, original.primaryCategory);
      expect(restored.categoryLabel, original.categoryLabel);
      expect(restored.somaticMapping, original.somaticMapping);
      expect(restored.loggedBothAxesToday, original.loggedBothAxesToday);
      expect(restored.secondaryCategoryLabel, original.secondaryCategoryLabel);
      expect(restored.secondarySomaticMapping, original.secondarySomaticMapping);
      expect(restored.secondaryIntensityScore, original.secondaryIntensityScore);
      expect(restored.aiMappedLayTerm, original.aiMappedLayTerm);
      expect(restored.aiBodyAreaOrMood, original.aiBodyAreaOrMood);
      expect(restored.aiSource, original.aiSource);
      expect(restored.isCrossVerticalSomatic, original.isCrossVerticalSomatic);
      expect(restored.crossVerticalContextNote, original.crossVerticalContextNote);
      expect(restored.recommendedArticles.length, original.recommendedArticles.length);
      expect(restored.recordedAt.toIso8601String(), original.recordedAt.toIso8601String());
    });

    testWidgets('36. Legacy cross-vertical somatic note is never rendered on either screen',
        (WidgetTester tester) async {
      const legacyNote = 'A cefaleia foi identificada como manifestação somática concomitante à tensão psicomotora.';
      final outcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'ansiosa_agitacao',
        categoryLabel: 'Ansiedade e agitação',
        somaticMapping: 'Inquietação e preocupação',
        aiMappedLayTerm: 'dor de cabeça',
        aiSource: 'gemini',
        isCrossVerticalSomatic: true,
        crossVerticalContextNote: legacyNote,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Manifestação Somática Concomitante'), findsNothing);
      expect(find.text(legacyNote), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Manifestação Somática Concomitante'), findsNothing);
      expect(find.text(legacyNote), findsNothing);
    });
  });
}
