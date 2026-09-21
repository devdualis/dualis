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
  CareDisposition careDisposition = CareDisposition.selfCare,
  String primaryCategory = 'cabeca_pescoco',
  String categoryLabel = 'Cabeça e Pescoço',
  String somaticMapping = 'Cefaleia / Desconforto crânio-cervical',
  bool organicPrimacyApplied = false,
  String? organicPrimacyNotice,
  String? secondaryCategoryLabel,
  String? secondarySomaticMapping,
  int? secondaryIntensityScore,
  String? aiMappedLayTerm,
  String? aiClinicalConcept,
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
    careDisposition: careDisposition,
    primaryCategory: primaryCategory,
    categoryLabel: categoryLabel,
    somaticMapping: somaticMapping,
    organicPrimacyApplied: organicPrimacyApplied,
    organicPrimacyNotice: organicPrimacyNotice,
    secondaryCategoryLabel: secondaryCategoryLabel,
    secondarySomaticMapping: secondarySomaticMapping,
    secondaryIntensityScore: secondaryIntensityScore,
    aiMappedLayTerm: aiMappedLayTerm,
    aiClinicalConcept: aiClinicalConcept,
    aiSource: aiSource,
    isCrossVerticalSomatic: isCrossVerticalSomatic,
    crossVerticalContextNote: crossVerticalContextNote,
    recommendedArticles: recommendedArticles ??
        const [
          RecommendedArticle(
            id: 'art-1',
            title: 'Prevenção de Cefaleias Tensionais',
            category: 'cabeca_pescoco',
            author: 'Dr. Silva',
            authorRole: 'Neurologista',
            readTimeMinutes: 4,
            summary: 'Orientações para alívio de cefaleias',
            url: 'https://sbcefaleia.com.br/noticias.php?id=350',
          ),
        ],
    recordedAt: recordedAt ?? DateTime(2026, 9, 17, 10, 30),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Triage Outcome vs Daily Result Equivalence Battery (35 Tests)', () {
    // -------------------------------------------------------------
    // BLOCK 1: INTENSITY SCORE PARITY (Tests 1 to 5)
    // -------------------------------------------------------------
    testWidgets('1. Level 1 intensity score is identical in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        intensityScore: 1,
        careDisposition: CareDisposition.selfCare,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('1 / 5'), findsOneWidget);
      expect(find.text('Leve / Mínimo'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('1 / 5'), findsOneWidget);
      expect(find.text('Leve / Mínimo'), findsOneWidget);
    });

    testWidgets('2. Level 2 intensity score is identical in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        intensityScore: 2,
        careDisposition: CareDisposition.selfCare,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('2 / 5'), findsOneWidget);
      expect(find.text('Moderado Baixo'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('2 / 5'), findsOneWidget);
      expect(find.text('Moderado Baixo'), findsOneWidget);
    });

    testWidgets('3. Level 3 intensity score is identical in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        intensityScore: 3,
        careDisposition: CareDisposition.routineConsultation,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.text('Moderado / Atenção'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.text('Moderado / Atenção'), findsOneWidget);
    });

    testWidgets('4. Level 4 intensity score is identical in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        intensityScore: 4,
        careDisposition: CareDisposition.urgentCare,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('4 / 5'), findsOneWidget);
      expect(find.text('Significativo / Agudo'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('4 / 5'), findsOneWidget);
      expect(find.text('Significativo / Agudo'), findsOneWidget);
    });

    testWidgets('5. Level 5 intensity score is identical in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        intensityScore: 5,
        careDisposition: CareDisposition.emergency,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('5 / 5'), findsOneWidget);
      expect(find.text('Crítico / Alerta'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('5 / 5'), findsOneWidget);
      expect(find.text('Crítico / Alerta'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // BLOCK 2: CARE DISPOSITION PARITY (Tests 6 to 9)
    // -------------------------------------------------------------
    testWidgets('6. Self-care disposition is identical in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        careDisposition: CareDisposition.selfCare,
        intensityScore: 1,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Auto-cuidado Monitorado'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Auto-cuidado Monitorado'), findsOneWidget);
    });

    testWidgets('7. Routine consultation disposition is identical in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        careDisposition: CareDisposition.routineConsultation,
        intensityScore: 3,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Consulta de Rotina'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Consulta de Rotina'), findsOneWidget);
    });

    testWidgets('8. Urgent care disposition is identical in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        careDisposition: CareDisposition.urgentCare,
        intensityScore: 4,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Pronto Atendimento (24h)'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Pronto Atendimento (24h)'), findsOneWidget);
    });

    testWidgets('9. Emergency disposition is identical in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        careDisposition: CareDisposition.emergency,
        intensityScore: 5,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Atendimento de Emergência'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Atendimento de Emergência'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // BLOCK 3: PHYSICAL CATEGORY & SOMATIC MAPPING (Tests 10 to 14)
    // -------------------------------------------------------------
    testWidgets('10. Cabeça e Pescoço category and somatic description match',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'cabeca_pescoco',
        categoryLabel: 'Cabeça e Pescoço',
        somaticMapping: 'Cefaleia / Desconforto crânio-cervical',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cabeça e Pescoço'), findsOneWidget);
      expect(find.text('Cefaleia / Desconforto crânio-cervical'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cabeça e Pescoço'), findsOneWidget);
      expect(find.text('Cefaleia / Desconforto crânio-cervical'), findsOneWidget);
    });

    testWidgets('11. Cardiovascular e Tórax category and somatic description match',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'cardiovascular_torax',
        categoryLabel: 'Cardiovascular e Tórax',
        somaticMapping: 'Sensação de aperto torácico funcional / Palpitações',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cardiovascular e Tórax'), findsOneWidget);
      expect(find.text('Sensação de aperto torácico funcional / Palpitações'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cardiovascular e Tórax'), findsOneWidget);
      expect(find.text('Sensação de aperto torácico funcional / Palpitações'), findsOneWidget);
    });

    testWidgets('12. Coluna e Dor Lombar category and somatic description match',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'coluna_dor_lombar',
        categoryLabel: 'Coluna e Dor Lombar',
        somaticMapping: 'Desconforto na coluna / Lombalgia tensional',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Coluna e Dor Lombar'), findsOneWidget);
      expect(find.text('Desconforto na coluna / Lombalgia tensional'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Coluna e Dor Lombar'), findsOneWidget);
      expect(find.text('Desconforto na coluna / Lombalgia tensional'), findsOneWidget);
    });

    testWidgets('13. Dermatológico category and somatic description match',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'dermatologico',
        categoryLabel: 'Dermatológico / Pele',
        somaticMapping: 'Prurido cutâneo / Desconforto na pele',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dermatológico / Pele'), findsOneWidget);
      expect(find.text('Prurido cutâneo / Desconforto na pele'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dermatológico / Pele'), findsOneWidget);
      expect(find.text('Prurido cutâneo / Desconforto na pele'), findsOneWidget);
    });

    testWidgets('14. Membros Superiores category and somatic description match',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'membros_superiores',
        categoryLabel: 'Membros Superiores e Articulações',
        somaticMapping: 'Desconforto musculoesquelético nos braços e ombros',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Membros Superiores e Articulações'), findsOneWidget);
      expect(find.text('Desconforto musculoesquelético nos braços e ombros'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Membros Superiores e Articulações'), findsOneWidget);
      expect(find.text('Desconforto musculoesquelético nos braços e ombros'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // BLOCK 4: PSYCHO-EMOTIONAL DIMENSIONS (Tests 15 to 18)
    // -------------------------------------------------------------
    testWidgets('15. Dimensão Ansiosa / Agitação matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'ansiosa_agitacao',
        categoryLabel: 'Dimensão Ansiosa / Agitação',
        somaticMapping: 'Tensão psicomotora / Ansiedade antecipatória',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dimensão Ansiosa / Agitação'), findsOneWidget);
      expect(find.text('Tensão psicomotora / Ansiedade antecipatória'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dimensão Ansiosa / Agitação'), findsOneWidget);
      expect(find.text('Tensão psicomotora / Ansiedade antecipatória'), findsOneWidget);
    });

    testWidgets('16. Dimensão Depressiva / Desânimo matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'depressiva_desanimo',
        categoryLabel: 'Dimensão Depressiva / Desânimo',
        somaticMapping: 'Desânimo / Fadiga emocional transitória',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dimensão Depressiva / Desânimo'), findsOneWidget);
      expect(find.text('Desânimo / Fadiga emocional transitória'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dimensão Depressiva / Desânimo'), findsOneWidget);
      expect(find.text('Desânimo / Fadiga emocional transitória'), findsOneWidget);
    });

    testWidgets('17. Estresse e Burnout matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'estresse_burnout',
        categoryLabel: 'Estresse e Burnout',
        somaticMapping: 'Exaustão emocional / Sobrecarga de estresse',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Estresse e Burnout'), findsOneWidget);
      expect(find.text('Exaustão emocional / Sobrecarga de estresse'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Estresse e Burnout'), findsOneWidget);
      expect(find.text('Exaustão emocional / Sobrecarga de estresse'), findsOneWidget);
    });

    testWidgets('18. Cognição e Foco matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'cognitiva_foco',
        categoryLabel: 'Cognição e Foco',
        somaticMapping: 'Fadiga mental / Névoa cognitiva e dispersão',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cognição e Foco'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cognição e Foco'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // BLOCK 5: DUAL COMPONENT & SOMATIC MAPPING (Tests 19 to 21)
    // -------------------------------------------------------------
    testWidgets('19. Secondary category label matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'cabeca_pescoco',
        categoryLabel: 'Cabeça e Pescoço',
        secondaryCategoryLabel: 'Estresse e Burnout',
        secondarySomaticMapping: 'Sobrecarga de estresse associada',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Componente Associado: Estresse e Burnout'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Estresse e Burnout'), findsOneWidget);
    });

    testWidgets('20. Secondary somatic mapping matches in both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'cabeca_pescoco',
        categoryLabel: 'Cabeça e Pescoço',
        secondaryCategoryLabel: 'Dimensão Ansiosa / Agitação',
        secondarySomaticMapping: 'Tensão psicomotora / Ansiedade antecipatória',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Tensão psicomotora / Ansiedade antecipatória'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Tensão psicomotora / Ansiedade antecipatória'), findsOneWidget);
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
    // BLOCK 6: ORGANIC PRIMACY NOTICE & BANNER (Tests 22 to 24)
    // -------------------------------------------------------------
    testWidgets('22. Organic Primacy banner is displayed on both screens when applied',
        (WidgetTester tester) async {
      const noticeText =
          'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem avaliação médica presencial.';
      final outcome = createBaseMockOutcome(
        organicPrimacyApplied: true,
        organicPrimacyNotice: noticeText,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(noticeText), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(noticeText), findsOneWidget);
    });

    testWidgets('23. Organic Primacy banner is absent on both when not applied',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        organicPrimacyApplied: false,
        organicPrimacyNotice: null,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Primazia Orgânica'), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Primazia Orgânica'), findsNothing);
    });

    testWidgets('24. Organic primacy notice text matches character-for-character',
        (WidgetTester tester) async {
      const exactNotice = 'Nota clínica de teste para validação de primazia orgânica.';
      final outcome = createBaseMockOutcome(
        organicPrimacyApplied: true,
        organicPrimacyNotice: exactNotice,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(exactNotice), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text(exactNotice), findsOneWidget);
    });

    // -------------------------------------------------------------
    // BLOCK 7: AI CLINICAL INSIGHT CARD (Tests 25 to 27)
    // -------------------------------------------------------------
    testWidgets('25. AiInsightCard clinical concept renders on both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        aiClinicalConcept: 'Cefaleia Tensional Episódica',
        aiMappedLayTerm: 'dor de cabeça latejante',
        aiSource: 'gemini',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cefaleia Tensional Episódica'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cefaleia Tensional Episódica'), findsOneWidget);
    });

    testWidgets('26. AiInsightCard lay term and source render on both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        aiClinicalConcept: 'Lombalgia Mecânica',
        aiMappedLayTerm: 'dor nas costas ao sentar',
        aiSource: 'gemini',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Lombalgia Mecânica'), findsOneWidget);
      expect(find.text('Informação Clínica Complementar'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Lombalgia Mecânica'), findsOneWidget);
      expect(find.text('Informação Clínica Complementar'), findsOneWidget);
    });

    testWidgets('27. AiInsightCard is omitted on both screens when clinicalConcept is null',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        aiClinicalConcept: null,
        aiMappedLayTerm: null,
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Informação Clínica Complementar'), findsNothing);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Informação Clínica Complementar'), findsNothing);
    });

    // -------------------------------------------------------------
    // BLOCK 8: RECOMMENDED ARTICLES PARITY (Tests 28 to 30)
    // -------------------------------------------------------------
    testWidgets('28. Article titles match exactly on both screens',
        (WidgetTester tester) async {
      const List<RecommendedArticle> testArticles = [
        RecommendedArticle(
          id: 'art-coluna',
          title: 'Guia de Saúde da Coluna Lombar',
          category: 'coluna',
          author: 'Dra. Santos',
          authorRole: 'Ortopedista',
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
      expect(find.text('Guia de Saúde da Coluna Lombar'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Guia de Saúde da Coluna Lombar'), findsOneWidget);
    });

    testWidgets('29. Multiple article counts match on both screens',
        (WidgetTester tester) async {
      const List<RecommendedArticle> multipleArticles = [
        RecommendedArticle(
          id: 'art-ansiedade',
          title: 'Artigo Um: Respiração Consciente',
          category: 'ansiedade',
          author: 'Dra. Costa',
          authorRole: 'Psicóloga',
          readTimeMinutes: 3,
          summary: 'Técnicas de respiração',
          url: 'https://exemplo.com/1',
        ),
        RecommendedArticle(
          id: 'art-sono',
          title: 'Artigo Dois: Higiene do Sono',
          category: 'sono',
          author: 'Dr. Lima',
          authorRole: 'Médico do Sono',
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
      expect(find.text('Artigo Um: Respiração Consciente'), findsOneWidget);
      expect(find.text('Artigo Dois: Higiene do Sono'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Artigo Um: Respiração Consciente'), findsOneWidget);
      expect(find.text('Artigo Dois: Higiene do Sono'), findsOneWidget);
    });

    testWidgets('30. Fallback curated catalog produces matching articles on both',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        primaryCategory: 'cabeca_pescoco',
        recommendedArticles: const [], // empty list forces fallback catalog
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cefaleia'), findsWidgets);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cefaleia'), findsWidgets);
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
        careDisposition: CareDisposition.urgentCare,
        primaryCategory: 'cardiovascular_torax',
        categoryLabel: 'Cardiovascular e Tórax',
        aiMappedLayTerm: 'aperto no peito',
      );

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.markCompletedWithOutcome(mockOutcome);

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
        careDisposition: CareDisposition.selfCare,
        categoryLabel: 'Cabeça e Pescoço',
      );

      container.read(triageOutcomeProvider.notifier).setOutcome(initialOutcome);
      container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(initialOutcome);

      expect(container.read(triageOutcomeProvider).outcome?.intensityScore, 2);
      expect(container.read(triageOutcomeProvider).outcome?.categoryLabel, 'Cabeça e Pescoço');

      // User updates triage to severe cardiovascular
      final updatedOutcome = createBaseMockOutcome(
        id: 'triage-2',
        intensityScore: 4,
        careDisposition: CareDisposition.urgentCare,
        primaryCategory: 'cardiovascular_torax',
        categoryLabel: 'Cardiovascular e Tórax',
      );

      container.read(triageOutcomeProvider.notifier).setOutcome(updatedOutcome);
      container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(updatedOutcome);

      final activeOutcome = container.read(triageOutcomeProvider).outcome;
      expect(activeOutcome?.id, 'triage-2');
      expect(activeOutcome?.intensityScore, 4);
      expect(activeOutcome?.categoryLabel, 'Cardiovascular e Tórax');
      expect(activeOutcome?.careDisposition, CareDisposition.urgentCare);

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
        categoryLabel: 'Dermatológico / Pele',
      );
      container.read(triageOutcomeProvider.notifier).setOutcome(physicalOutcome);
      container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(physicalOutcome);

      expect(container.read(triageOutcomeProvider).outcome?.categoryLabel, 'Dermatológico / Pele');

      final emotionalOutcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'estresse_burnout',
        categoryLabel: 'Estresse e Burnout',
      );
      container.read(triageOutcomeProvider.notifier).setOutcome(emotionalOutcome);
      container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(emotionalOutcome);

      expect(container.read(triageOutcomeProvider).outcome?.categoryLabel, 'Estresse e Burnout');
      expect(container.read(triggerCheckInProvider).isCompletedToday, isTrue);
    });

    testWidgets('34. prepareForUpdate is triggered when tapping Atualizar Triagem de Hoje',
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
        careDisposition: CareDisposition.routineConsultation,
        primaryCategory: 'respiratorio',
        categoryLabel: 'Sistema Respiratório',
        somaticMapping: 'Desconforto respiratório funcional',
        organicPrimacyApplied: true,
        organicPrimacyNotice: 'Nota de primazia para round-trip',
        secondaryCategoryLabel: 'Estresse e Burnout',
        secondarySomaticMapping: 'Sobrecarga de estresse',
        secondaryIntensityScore: 3,
        aiClinicalConcept: 'Broncoespasmo Funcional Leve',
        aiMappedLayTerm: 'falta de ar ao cansar',
        aiSource: 'gemini',
        isCrossVerticalSomatic: true,
        crossVerticalContextNote: 'Nota de contexto cruzado',
      );

      final json = original.toJson();
      final restored = TriageOutcome.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.vertical, original.vertical);
      expect(restored.intensityScore, original.intensityScore);
      expect(restored.careDisposition, original.careDisposition);
      expect(restored.primaryCategory, original.primaryCategory);
      expect(restored.categoryLabel, original.categoryLabel);
      expect(restored.somaticMapping, original.somaticMapping);
      expect(restored.organicPrimacyApplied, original.organicPrimacyApplied);
      expect(restored.organicPrimacyNotice, original.organicPrimacyNotice);
      expect(restored.secondaryCategoryLabel, original.secondaryCategoryLabel);
      expect(restored.secondarySomaticMapping, original.secondarySomaticMapping);
      expect(restored.secondaryIntensityScore, original.secondaryIntensityScore);
      expect(restored.aiClinicalConcept, original.aiClinicalConcept);
      expect(restored.aiMappedLayTerm, original.aiMappedLayTerm);
      expect(restored.aiSource, original.aiSource);
      expect(restored.isCrossVerticalSomatic, original.isCrossVerticalSomatic);
      expect(restored.crossVerticalContextNote, original.crossVerticalContextNote);
      expect(restored.recommendedArticles.length, original.recommendedArticles.length);
      expect(restored.recordedAt.toIso8601String(), original.recordedAt.toIso8601String());
    });

    testWidgets(
        '36. AiInsightCard renders Manifestação Somática Concomitante and crossVerticalContextNote when isCrossVerticalSomatic is true on both screens',
        (WidgetTester tester) async {
      final outcome = createBaseMockOutcome(
        vertical: 'emotional',
        primaryCategory: 'ansiedade_agitacao',
        categoryLabel: 'Dimensão Ansiosa / Agitação',
        somaticMapping: 'Ansiedade antecipatória / Tensão psicomotora',
        aiClinicalConcept: 'cefaleia tensional / migrânea',
        aiMappedLayTerm: 'dor de cabeça',
        aiSource: 'gemini',
        isCrossVerticalSomatic: true,
        crossVerticalContextNote:
            'A cefaleia foi identificada como manifestação somática concomitante à tensão psicomotora.',
      );

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TodayTriageResultTab(onGoToCheckIn: () {}),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Manifestação Somática Concomitante'), findsOneWidget);
      expect(
        find.text(
            'A cefaleia foi identificada como manifestação somática concomitante à tensão psicomotora.'),
        findsOneWidget,
      );
      expect(find.text('Sintoma físico relatado no check-in'), findsOneWidget);

      await tester.pumpWidget(createDualEquivalenceWrapper(
        child: TriageOutcomeScreen(outcome: outcome),
        outcome: outcome,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Manifestação Somática Concomitante'), findsOneWidget);
      expect(
        find.text(
            'A cefaleia foi identificada como manifestação somática concomitante à tensão psicomotora.'),
        findsOneWidget,
      );
      expect(find.text('Sintoma físico relatado no check-in'), findsOneWidget);
    });
  });
}
