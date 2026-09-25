import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dual_axis_trigger_card.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class _FakeHistoryDataSource extends TriageHistoryRemoteDataSource {
  final TriageHistoryResponse response;

  _FakeHistoryDataSource(this.response);

  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async => response;
}

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

TriageOutcome _physicalOutcome({String id = 'phys', String? aiMappedLayTerm}) {
  return TriageOutcome(
    id: id,
    vertical: 'physical',
    intensityScore: 2,
    careDisposition: CareDisposition.selfCare,
    primaryCategory: 'neurologico',
    categoryLabel: 'Sistema Neurológico',
    somaticMapping: 'Tontura / Instabilidade postural e equilíbrio',
    organicPrimacyApplied: false,
    recommendedArticles: const [],
    recordedAt: DateTime.now(),
    aiMappedLayTerm: aiMappedLayTerm,
  );
}

TriageHistoryResponse _history(List<TriageHistoryEntry> logs) {
  return TriageHistoryResponse(
    logs: logs,
    physicalSummary: const {},
    emotionalSummary: const [],
    criticalRecurrences: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stage description comes only from the text typed in that triage', () {
    test('a new triage without description clears the previous one for that axis', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(triggerCheckInProvider.notifier);

      notifier.markCompletedWithOutcome(
        _physicalOutcome(id: 'first', aiMappedLayTerm: 'dor de cabeça'),
        narrative: 'dor de cabeça',
      );
      expect(container.read(triggerCheckInProvider).physicalNarrative, 'dor de cabeça');

      // "Atualizar", then the wizard submits a triage with an empty description:
      // setOutcome replays the outcome first, then the wizard passes the narrative.
      notifier.resetStage(isPhysical: true);
      final second = _physicalOutcome(id: 'second');
      notifier.markCompletedWithOutcome(second);
      notifier.markCompletedWithOutcome(second, narrative: null);

      expect(container.read(triggerCheckInProvider).physicalNarrative, isNull);
    });

    test('a stale description is cleared even without resetStage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(triggerCheckInProvider.notifier);

      notifier.markCompletedWithOutcome(_physicalOutcome(id: 'first'), narrative: 'dor de cabeça');
      notifier.markCompletedWithOutcome(_physicalOutcome(id: 'second'), narrative: null);

      expect(container.read(triggerCheckInProvider).physicalNarrative, isNull);
    });

    test('replaying a stored outcome keeps the description the user typed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(triggerCheckInProvider.notifier);
      final outcome = _physicalOutcome();

      notifier.markCompletedWithOutcome(outcome, narrative: 'tontura ao levantar');
      notifier.markCompletedWithOutcome(outcome);

      expect(container.read(triggerCheckInProvider).physicalNarrative, 'tontura ao levantar');
    });

    test('the AI mapped lay term is never used as the description', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(triggerCheckInProvider.notifier);
      final outcome = _physicalOutcome(aiMappedLayTerm: 'dor de cabeça');

      notifier.markCompletedWithOutcome(outcome);
      expect(container.read(triggerCheckInProvider).physicalNarrative, isNull);

      notifier.markCompletedWithOutcome(outcome, narrative: null);
      final state = container.read(triggerCheckInProvider);
      expect(state.physicalNarrative, isNull);
      expect(state.naturalLanguageText, isEmpty);
    });

    test('resetStage clears the stage description', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(triggerCheckInProvider.notifier);

      notifier.completeStage(
        vertical: TriageVertical.fisica,
        summary: 'Sistema Neurológico',
        narrative: 'dor de cabeça',
      );
      notifier.resetStage(isPhysical: true);

      expect(container.read(triggerCheckInProvider).physicalNarrative, isNull);
    });
  });

  group('History sync: the record owns the description', () {
    test('latest record without description replaces a stale local one', () async {
      final now = DateTime.now();
      final emotional = TriageHistoryEntry(
        id: 'emo',
        intensity: 3,
        anatomicalSystem: 'neurologico',
        emotionalDimension: 'estresse_burnout',
        organicPrimacyApplied: true,
        disposition: 'consulta_rotina',
        narrative: 'dor de cabeça',
        recordedAt: now.subtract(const Duration(minutes: 20)),
      );
      final physical = TriageHistoryEntry(
        id: 'phys',
        intensity: 2,
        anatomicalSystem: 'neurologico',
        disposition: 'auto_cuidado',
        recordedAt: now.subtract(const Duration(minutes: 5)),
      );

      final container = ProviderContainer(
        overrides: [
          triageHistoryDataSourceProvider
              .overrideWithValue(_FakeHistoryDataSource(_history([physical, emotional]))),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(triggerCheckInProvider.notifier);

      notifier.markCompletedWithOutcome(_physicalOutcome(), narrative: 'dor de cabeça');
      await notifier.loadTodayCheckIn(now);

      final state = container.read(triggerCheckInProvider);
      expect(state.physicalNarrative, isNull);
      expect(state.emotionalNarrative, 'dor de cabeça');
    });

    test('a cross-vertical tag does not lend its description to the other axis', () async {
      final now = DateTime.now();
      final emotional = TriageHistoryEntry(
        id: 'emo',
        intensity: 3,
        anatomicalSystem: 'neurologico',
        emotionalDimension: 'estresse_burnout',
        organicPrimacyApplied: true,
        disposition: 'consulta_rotina',
        narrative: 'dor de cabeça',
        recordedAt: now.subtract(const Duration(minutes: 5)),
      );

      final container = ProviderContainer(
        overrides: [
          triageHistoryDataSourceProvider
              .overrideWithValue(_FakeHistoryDataSource(_history([emotional]))),
        ],
      );
      addTearDown(container.dispose);

      await container.read(triggerCheckInProvider.notifier).loadTodayCheckIn(now);

      final state = container.read(triggerCheckInProvider);
      expect(state.isPhysicalCompleted, isTrue);
      expect(state.physicalNarrative, isNull);
      expect(state.emotionalNarrative, 'dor de cabeça');
    });
  });

  testWidgets('card shows no quote when the stage has no description, even if the outcome has an AI lay term',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        triggerCheckInProvider.overrideWith(
          () => _FakeTriggerCheckInNotifier(
            const TriggerCheckInState(
              isCompletedToday: true,
              isPhysicalCompleted: true,
              physicalStatus: TriggerStatus.soSo,
              physicalIntensity: 2,
              physicalSummary: 'Sistema Neurológico',
            ),
          ),
        ),
        triageOutcomeProvider.overrideWith(
          () => _FakeTriageOutcomeNotifier(
            TriageOutcomeState(outcome: _physicalOutcome(aiMappedLayTerm: 'dor de cabeça')),
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
            body: SingleChildScrollView(child: DualAxisTriggerCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fisica_completed_card')), findsOneWidget);
    expect(find.textContaining('“'), findsNothing);
  });
}
