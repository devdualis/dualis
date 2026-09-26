import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/triage_history_detail_modal.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dual_axis_trigger_card.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/today_triage_result_tab.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class _FakeTriggerCheckInNotifier extends TriggerCheckInNotifier {
  final TriggerCheckInState _initial;
  _FakeTriggerCheckInNotifier(this._initial);

  @override
  TriggerCheckInState build() => _initial;
}

class _FakeTriageOutcomeNotifier extends TriageOutcomeNotifier {
  final TriageOutcomeState _initial;
  _FakeTriageOutcomeNotifier(this._initial);

  @override
  TriageOutcomeState build() => _initial;
}

void main() {
  group('Regression Test Battery: Bug 1 - TriageHistoryDetailModal Associated Factor & Narrative Sanitization', () {
    testWidgets('1.1 Step 3 numeric intensity (e.g. 1..5) is NEVER rendered as Fator Associado / Sintoma', (tester) async {
      for (final score in ['1', '2', '3', '4', '5']) {
        final entry = TriageHistoryEntry(
          id: 'log-intensity-$score',
          intensity: int.parse(score),
          anatomicalSystem: 'neurologico',
          disposition: 'auto_cuidado',
          narrative: null,
          stepAnswers: {
            '0': 'neurologico',
            '1': 'comecou_agora',
            // Note: No step 2 factor answered, only step 3 intensity
            '3': score,
          },
          recordedAt: DateTime.parse('2026-09-25T10:00:00.000Z'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => TriageHistoryDetailModal.show(context, entry),
                  child: Text('Open-$score'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open-$score'));
        await tester.pumpAndSettle();

        // Must not render Fator Associado / Sintoma with numeric score
        expect(find.text('Fator Associado / Sintoma'), findsNothing,
            reason: 'Step 3 intensity score $score must not be displayed as an associated factor');
        expect(find.widgetWithText(Row, score), findsNothing);

        // Close modal
        await tester.tap(find.byKey(const Key('modal_dismiss_button')));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('1.2 Correctly formats Step 2 associated factors across systems and emotional dimensions', (tester) async {
      final factorsToTest = <String, String>{
        'sim_levantar_rapido': 'Ao levantar rápido / postural',
        'sim_carregou_peso': 'Carregamento de peso excessivo',
        'sim_exercicio_intenso': 'Exercício físico intenso',
        'sim_sofri_queda': 'Queda ou trauma recente',
        'nao_comecou_do_nada': 'Início espontâneo (sem causa aparente)',
        'sim_postura_prolongada': 'Postura prolongada ou má postura',
        'sim_telas_esforco_visual': 'Uso prolongado de telas / esforço visual',
        'sim_baixa_ingestao_urina': 'Pouca ingestão de água / segurar urina',
        'trabalho_estudos': 'Trabalho / Estudos',
        'familia_relacionamentos': 'Família / Relacionamentos',
        'noite_ruim_sono': 'Noite ruim de sono',
        'sim_cobranca_prazos': 'Pressão no trabalho / prazos',
        'sim_pressao_trabalho': 'Pressão profissional / sobrecarga',
      };

      for (final entry in factorsToTest.entries) {
        final factorKey = entry.key;
        final expectedLabel = entry.value;

        final logEntry = TriageHistoryEntry(
          id: 'log-factor-$factorKey',
          intensity: 2,
          anatomicalSystem: 'muscular_geral',
          disposition: 'auto_cuidado',
          narrative: null,
          stepAnswers: {
            '0': 'muscular_geral',
            '1': 'comecou_hoje',
            '2': factorKey,
            '3': '2', // Intensity 2 in step 3
          },
          recordedAt: DateTime.parse('2026-09-25T11:00:00.000Z'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => TriageHistoryDetailModal.show(context, logEntry),
                  child: Text('Open-$factorKey'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open-$factorKey'));
        await tester.pumpAndSettle();

        expect(find.text('Fator Associado / Sintoma'), findsOneWidget);
        expect(find.text(expectedLabel), findsOneWidget,
            reason: 'Factor $factorKey should format to $expectedLabel');
        expect(find.widgetWithText(Row, '2'), findsNothing,
            reason: 'Numeric intensity must not be rendered in place of the factor');

        await tester.tap(find.byKey(const Key('modal_dismiss_button')));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('1.3 Unmapped snake_case factors are formatted nicely with spaces and capitalized', (tester) async {
      final logEntry = TriageHistoryEntry(
        id: 'log-custom-factor',
        intensity: 3,
        anatomicalSystem: 'dermatologico',
        disposition: 'consulta_rotina',
        narrative: null,
        stepAnswers: {
          '0': 'dermatologico',
          '1': 'ha_alguns_dias',
          '2': 'contato_planta_desconhecida',
          '3': '3',
        },
        recordedAt: DateTime.parse('2026-09-25T11:30:00.000Z'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TriageHistoryDetailModal.show(context, logEntry),
                child: const Text('Open-Custom'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open-Custom'));
      await tester.pumpAndSettle();

      expect(find.text('Fator Associado / Sintoma'), findsOneWidget);
      expect(find.text('Contato planta desconhecida'), findsOneWidget);

      await tester.tap(find.byKey(const Key('modal_dismiss_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('1.4 Numeric narrative strings ("5", "2", etc.) are rejected in modal narrative section', (tester) async {
      for (final dirtyNarrative in ['5', '2', '   4   ', '10']) {
        final logEntry = TriageHistoryEntry(
          id: 'log-dirty-narrative-$dirtyNarrative',
          intensity: 3,
          anatomicalSystem: 'neurologico',
          disposition: 'auto_cuidado',
          narrative: dirtyNarrative,
          stepAnswers: {
            '0': 'neurologico',
            '1': 'comecou_agora',
            '2': 'sim_levantar_rapido',
            '3': '3',
            'naturalLanguageText': dirtyNarrative,
          },
          recordedAt: DateTime.parse('2026-09-25T12:00:00.000Z'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => TriageHistoryDetailModal.show(context, logEntry),
                  child: Text('Open-$dirtyNarrative'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open-$dirtyNarrative'));
        await tester.pumpAndSettle();

        expect(find.text('5'), findsNothing);
        expect(find.text('2'), findsNothing);
        expect(find.text('4'), findsNothing);
        expect(find.text('10'), findsNothing);
        expect(
          find.text('Nenhuma descrição adicional relatada pelo paciente nesta triagem.'),
          findsOneWidget,
          reason: 'A numeric string must be treated as no narrative provided',
        );

        await tester.tap(find.byKey(const Key('modal_dismiss_button')));
        await tester.pumpAndSettle();
      }
    });
  });

  group('Regression Test Battery: Bug 2 - Narrative Leak Prevention & UI Box Removal', () {
    test('2.1 TriggerCheckInState.fromJson strips numeric strings from all narrative fields', () {
      final dirtyJson = {
        'isCompletedToday': true,
        'isPhysicalCompleted': true,
        'isEmotionalCompleted': true,
        'physicalStatus': 'soSo',
        'emotionalStatus': 'badSick',
        'physicalSummary': 'Avaliação Física',
        'emotionalSummary': 'Psicoemocional',
        'physicalNarrative': '5',
        'emotionalNarrative': '2',
        'naturalLanguageText': '5',
      };

      final sanitized = TriggerCheckInState.fromJson(dirtyJson);

      expect(sanitized.physicalNarrative, isNull, reason: 'physicalNarrative must be null when value is "5"');
      expect(sanitized.emotionalNarrative, isNull, reason: 'emotionalNarrative must be null when value is "2"');
      expect(sanitized.naturalLanguageText, isEmpty, reason: 'naturalLanguageText must be empty when value is "5"');
    });

    test('2.2 TriggerCheckInState.fromJson preserves genuine medical narratives', () {
      final validJson = {
        'isCompletedToday': true,
        'isPhysicalCompleted': true,
        'physicalStatus': 'soSo',
        'physicalSummary': 'Avaliação Física',
        'physicalNarrative': 'Dor de cabeça pulsátil na fronte',
        'emotionalNarrative': 'Ansiedade devido a prazos no trabalho',
        'naturalLanguageText': 'Dor de cabeça pulsátil na fronte',
      };

      final parsed = TriggerCheckInState.fromJson(validJson);

      expect(parsed.physicalNarrative, 'Dor de cabeça pulsátil na fronte');
      expect(parsed.emotionalNarrative, 'Ansiedade devido a prazos no trabalho');
      expect(parsed.naturalLanguageText, 'Dor de cabeça pulsátil na fronte');
    });

    test('2.3 TriggerCheckInNotifier.markCompletedWithOutcome does not leak naturalLanguageText when narrative is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);

      // Pre-set some naturalLanguageText
      notifier.setNaturalLanguageText('5');

      final outcome = TriageOutcome(
        id: 'out-1',
        vertical: 'physical',
        intensityScore: 2,
        careDisposition: CareDisposition.selfCare,
        primaryCategory: 'neurologico',
        categoryLabel: 'Neurológico',
        somaticMapping: 'Neurológico',
        organicPrimacyApplied: false,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
        // No AI mapped lay term
        aiMappedLayTerm: null,
      );

      // User submits triage with empty narrative (patient provided no description)
      notifier.markCompletedWithOutcome(outcome, narrative: null);

      final state = container.read(triggerCheckInProvider);

      expect(state.physicalNarrative, isNull,
          reason: 'physicalNarrative must be null when user entered no narrative');
      expect(state.physicalSummary, 'Neurológico');
      expect(state.isPhysicalCompleted, isTrue);
    });

    test('2.4 TriggerCheckInNotifier.markCompletedWithOutcome rejects numeric narrative', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);

      final outcome = TriageOutcome(
        id: 'out-2',
        vertical: 'physical',
        intensityScore: 3,
        careDisposition: CareDisposition.routineConsultation,
        primaryCategory: 'neurologico',
        categoryLabel: 'Neurológico',
        somaticMapping: 'Neurológico',
        organicPrimacyApplied: false,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
        aiMappedLayTerm: '5', // Dirty AI term
      );

      notifier.markCompletedWithOutcome(outcome, narrative: '5');

      final state = container.read(triggerCheckInProvider);

      expect(state.physicalNarrative, isNull,
          reason: 'physicalNarrative must be null when narrative is "5"');
    });

    testWidgets('2.5 DualAxisTriggerCard does NOT render narrative box when physicalNarrative is null', (tester) async {
      final container = ProviderContainer(
        overrides: [
          triggerCheckInProvider.overrideWith(
            () => _FakeTriggerCheckInNotifier(
              const TriggerCheckInState(
                isCompletedToday: true,
                isPhysicalCompleted: true,
                physicalStatus: TriggerStatus.soSo,
                physicalSummary: 'Avaliação Física Registrada',
                physicalNarrative: null, // No description
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: DualAxisTriggerCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('“'), findsNothing,
          reason: 'Quotation narrative box must not appear when physicalNarrative is null');
      expect(find.text('5'), findsNothing);
    });

    testWidgets('2.6 DualAxisTriggerCard does NOT render narrative box when physicalNarrative is "5"', (tester) async {
      final container = ProviderContainer(
        overrides: [
          triggerCheckInProvider.overrideWith(
            () => _FakeTriggerCheckInNotifier(
              const TriggerCheckInState(
                isCompletedToday: true,
                isPhysicalCompleted: true,
                physicalStatus: TriggerStatus.soSo,
                physicalSummary: 'Avaliação Física Registrada',
                physicalNarrative: '5', // Dirty numeric narrative
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: DualAxisTriggerCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('“5”'), findsNothing,
          reason: 'Box with "5" must NEVER be rendered on the main screen');
      expect(find.text('5'), findsNothing);
    });

    testWidgets('2.7 DualAxisTriggerCard DOES render narrative box when physicalNarrative is a genuine description', (tester) async {
      const genuineText = 'Sensação de queimação na lombar após treino';
      final container = ProviderContainer(
        overrides: [
          triggerCheckInProvider.overrideWith(
            () => _FakeTriggerCheckInNotifier(
              const TriggerCheckInState(
                isCompletedToday: true,
                isPhysicalCompleted: true,
                physicalStatus: TriggerStatus.soSo,
                physicalSummary: 'Avaliação Física Registrada',
                physicalNarrative: genuineText,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: DualAxisTriggerCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('“$genuineText”'), findsOneWidget,
          reason: 'Legitimate text narrative should be displayed in the quote card');
    });

    testWidgets('2.8 TodayTriageResultTab does NOT display Relato when naturalLanguageText is "5"', (tester) async {
      final outcome = TriageOutcome(
        id: 'out-today',
        vertical: 'physical',
        intensityScore: 2,
        careDisposition: CareDisposition.selfCare,
        primaryCategory: 'neurologico',
        categoryLabel: 'Neurológico',
        somaticMapping: 'Neurológico',
        organicPrimacyApplied: false,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          triageOutcomeProvider.overrideWith(
            () => _FakeTriageOutcomeNotifier(
              TriageOutcomeState(outcome: outcome),
            ),
          ),
          triggerCheckInProvider.overrideWith(
            () => _FakeTriggerCheckInNotifier(
              const TriggerCheckInState(
                isCompletedToday: true,
                isPhysicalCompleted: true,
                physicalStatus: TriggerStatus.soSo,
                naturalLanguageText: '5', // Dirty text
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: TodayTriageResultTab(onGoToCheckIn: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Relato: "5"'), findsNothing,
          reason: 'Result tab must not show Relato: "5"');
    });
  });
}
