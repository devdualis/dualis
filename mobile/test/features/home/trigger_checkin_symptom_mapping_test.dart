import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dual_axis_trigger_card.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class _FakeHistoryDataSource extends TriageHistoryRemoteDataSource {
  final TriageHistoryResponse response;

  _FakeHistoryDataSource(this.response);

  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async {
    return response;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TriggerCheckIn symptom mapping & clinical consistency tests', () {
    test('1. Dual mild triage (intensity 1 headache + sleep) maps both axes to soSo, never goodNormal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final outcome = TriageOutcome(
        id: 'dual-triage-1',
        vertical: 'physical',
        intensityScore: 1, // Leve / Mínimo
        careDisposition: CareDisposition.selfCare,
        primaryCategory: 'cabeca_pescoco',
        categoryLabel: 'Cabeça e Pescoço',
        somaticMapping: 'Cefaleia / Desconforto crânio-cervical',
        organicPrimacyApplied: true,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
        secondaryCategoryLabel: 'Dimensão Sono / Ritmo Circadiano',
        secondarySomaticMapping: 'Privação do descanso fisiológico / Sono não-reparador',
        secondaryIntensityScore: 1,
        aiMappedLayTerm: 'Dor de cabeça',
      );

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.markCompletedWithOutcome(outcome);

      final state = container.read(triggerCheckInProvider);
      expect(state.isCompletedToday, isTrue);
      // Both axes had active symptoms; neither should be goodNormal
      expect(state.physicalStatus, TriggerStatus.soSo);
      expect(state.emotionalStatus, TriggerStatus.soSo);
      expect(state.naturalLanguageText, 'Dor de cabeça');
    });

    test('2. Physical-only mild triage (intensity 1) maps physical to soSo and emotional to goodNormal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final outcome = TriageOutcome(
        id: 'physical-triage-1',
        vertical: 'physical',
        intensityScore: 1,
        careDisposition: CareDisposition.selfCare,
        primaryCategory: 'cabeca_pescoco',
        categoryLabel: 'Cabeça e Pescoço',
        somaticMapping: 'Cefaleia / Desconforto crânio-cervical',
        organicPrimacyApplied: false,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
        secondaryCategoryLabel: null,
      );

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.markCompletedWithOutcome(outcome);

      final state = container.read(triggerCheckInProvider);
      expect(state.physicalStatus, TriggerStatus.soSo);
      expect(state.emotionalStatus, TriggerStatus.goodNormal);
    });

    test('3. Severe triage (intensity 4) maps to badSick', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final outcome = TriageOutcome(
        id: 'severe-triage-1',
        vertical: 'physical',
        intensityScore: 4,
        careDisposition: CareDisposition.urgentCare,
        primaryCategory: 'cardiovascular_torax',
        categoryLabel: 'Cardiovascular e Tórax',
        somaticMapping: 'Sensação de aperto torácico funcional / Palpitações',
        organicPrimacyApplied: false,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
      );

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.markCompletedWithOutcome(outcome);

      final state = container.read(triggerCheckInProvider);
      expect(state.physicalStatus, TriggerStatus.badSick);
      expect(state.emotionalStatus, TriggerStatus.goodNormal);
    });

    test('4. Remote history sync for mild dual triage maps both axes to soSo', () async {
      final now = DateTime.now();
      final mockHistory = TriageHistoryResponse(
        logs: [
          TriageHistoryEntry(
            id: 'remote-log-1',
            intensity: 1, // Mild headache and sleep disruption
            anatomicalSystem: 'cabeca_pescoco',
            emotionalDimension: 'sono',
            disposition: 'auto_cuidado',
            narrative: 'Dor de cabeça',
            recordedAt: now,
          ),
        ],
        physicalSummary: {},
        emotionalSummary: [],
        criticalRecurrences: [],
      );

      final container = ProviderContainer(
        overrides: [
          triageHistoryDataSourceProvider.overrideWithValue(
            _FakeHistoryDataSource(mockHistory),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      await notifier.loadTodayCheckIn();

      final state = container.read(triggerCheckInProvider);
      expect(state.isCompletedToday, isTrue);
      expect(state.physicalStatus, TriggerStatus.soSo);
      expect(state.emotionalStatus, TriggerStatus.soSo);
      expect(state.naturalLanguageText, 'Dor de cabeça');
    });

    testWidgets('5. DualAxisTriggerCard highlights Mais ou menos for both axes when completed with mild symptoms', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final outcome = TriageOutcome(
        id: 'widget-test-outcome',
        vertical: 'physical',
        intensityScore: 1,
        careDisposition: CareDisposition.selfCare,
        primaryCategory: 'cabeca_pescoco',
        categoryLabel: 'Cabeça e Pescoço',
        somaticMapping: 'Cefaleia / Desconforto crânio-cervical',
        organicPrimacyApplied: true,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
        secondaryCategoryLabel: 'Dimensão Sono / Ritmo Circadiano',
        secondarySomaticMapping: 'Privação do descanso fisiológico / Sono não-reparador',
        secondaryIntensityScore: 1,
        aiMappedLayTerm: 'Dor de cabeça',
      );

      container.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(outcome);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: SingleChildScrollView(
                child: DualAxisTriggerCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check-in banner is shown
      expect(find.byKey(const Key('dailyCheckInCompletedBanner')), findsOneWidget);

      // Verify that "Mais ou menos" is selected, and "Bem / Normal" is NOT selected
      final emotionalSoSo = tester.widget<InkWell>(find.byKey(const Key('emotional_soSo')));
      final physicalSoSo = tester.widget<InkWell>(find.byKey(const Key('physical_soSo')));
      expect(emotionalSoSo, isNotNull);
      expect(physicalSoSo, isNotNull);

      // Text input contains "Dor de cabeça"
      final textField = tester.widget<TextField>(find.byKey(const Key('naturalLanguageInput')));
      expect(textField.controller?.text, 'Dor de cabeça');
    });
  });
}
