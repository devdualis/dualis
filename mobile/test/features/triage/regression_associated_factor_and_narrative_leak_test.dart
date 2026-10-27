import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
        primaryCategory: 'neurologico',
        categoryLabel: 'Neurológico',
        somaticMapping: 'Neurológico',
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
        primaryCategory: 'neurologico',
        categoryLabel: 'Neurológico',
        somaticMapping: 'Neurológico',
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
        primaryCategory: 'neurologico',
        categoryLabel: 'Neurológico',
        somaticMapping: 'Neurológico',
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
