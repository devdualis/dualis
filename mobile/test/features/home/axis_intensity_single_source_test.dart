import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/home/domain/axis_intensity_resolver.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dual_axis_trigger_card.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/today_triage_result_tab.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeSecureStorage extends SecureStorageService {
  Map<String, dynamic>? checkIn;
  Map<String, dynamic>? outcome;

  _FakeSecureStorage({this.checkIn, this.outcome});

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<Map<String, dynamic>?> getDailyCheckIn(String userId) async => checkIn;

  @override
  Future<void> saveDailyCheckIn({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    checkIn = data;
  }

  @override
  Future<void> clearDailyCheckIn(String userId) async {
    checkIn = null;
  }

  @override
  Future<Map<String, dynamic>?> getTodayTriageOutcome(String userId) async =>
      outcome;

  @override
  Future<void> saveTodayTriageOutcome({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    outcome = data;
  }

  @override
  Future<void> clearTodayTriageOutcome(String userId) async {
    outcome = null;
  }
}

class _FakeHistoryDataSource extends TriageHistoryRemoteDataSource {
  final List<TriageHistoryEntry> logs;
  _FakeHistoryDataSource(this.logs);

  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async =>
      TriageHistoryResponse(
        logs: List.of(logs),
        physicalSummary: const {},
        emotionalSummary: const [],
        criticalRecurrences: const [],
      );
}

// ---------------------------------------------------------------------------
// Bug-scenario fixtures (all records share today's local date)
// ---------------------------------------------------------------------------

DateTime _todayAt(int minutes) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).add(Duration(minutes: minutes));
}

String _todayStr() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Emotional estresse_burnout record, intensity 3, cross-vertically tagged
/// with a physical system (organic primacy applied by the backend).
TriageHistoryEntry _e(String id, int minutes) => TriageHistoryEntry(
      id: id,
      intensity: 3,
      emotionalDimension: 'estresse_burnout',
      anatomicalSystem: 'neurologico',
      organicPrimacyApplied: true,
      disposition: 'consulta_rotina',
      narrative: 'muito estresse no trabalho',
      recordedAt: _todayAt(minutes),
    );

/// Physical neurologico record, intensity 2 (newest).
TriageHistoryEntry _p1({bool withEmotionalTag = true}) => TriageHistoryEntry(
      id: 'p1',
      intensity: 2,
      anatomicalSystem: 'neurologico',
      emotionalDimension: withEmotionalTag ? 'estresse_burnout' : null,
      organicPrimacyApplied: false,
      disposition: 'auto_cuidado',
      narrative: 'tontura',
      recordedAt: _todayAt(12),
    );

TriageHistoryEntry get _e1 => _e('e1', 10);
TriageHistoryEntry get _e2 => _e('e2', 11);

TriageOutcome _stalePhysicalOutcome() => TriageOutcome(
      id: 'p1',
      vertical: 'physical',
      intensityScore: 2,
      careDisposition: CareDisposition.selfCare,
      primaryCategory: 'neurologico',
      categoryLabel: 'Sistema Neurológico',
      somaticMapping: 'Tontura / Instabilidade postural e equilíbrio',
      organicPrimacyApplied: false,
      recommendedArticles: const [],
      recordedAt: _todayAt(12),
      secondaryCategoryLabel: 'Estresse e Burnout',
      secondaryIntensityScore: 4,
    );

Map<String, dynamic> _staleCheckInJson() => TriggerCheckInState(
      isCompletedToday: true,
      isEmotionalCompleted: true,
      isPhysicalCompleted: true,
      emotionalStatus: TriggerStatus.badSick,
      emotionalIntensity: 4,
      physicalStatus: TriggerStatus.soSo,
      physicalIntensity: 2,
      checkInDate: _todayStr(),
      completedAt: _todayAt(12),
    ).toJson();

Widget _harness(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

ProviderContainer _container(
  _FakeSecureStorage storage,
  List<TriageHistoryEntry> logs,
) {
  return ProviderContainer(
    overrides: [
      secureStorageServiceProvider.overrideWithValue(storage),
      triageHistoryDataSourceProvider
          .overrideWithValue(_FakeHistoryDataSource(logs)),
    ],
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('triggerStatusFromIntensity', () {
    test('maps scores to statuses', () {
      expect(triggerStatusFromIntensity(null), TriggerStatus.goodNormal);
      expect(triggerStatusFromIntensity(0), TriggerStatus.goodNormal);
      expect(triggerStatusFromIntensity(-1), TriggerStatus.goodNormal);
      expect(triggerStatusFromIntensity(1), TriggerStatus.soSo);
      expect(triggerStatusFromIntensity(2), TriggerStatus.soSo);
      expect(triggerStatusFromIntensity(3), TriggerStatus.soSo);
      expect(triggerStatusFromIntensity(4), TriggerStatus.badSick);
      expect(triggerStatusFromIntensity(5), TriggerStatus.badSick);
    });
  });

  group('AxisIntensityResolver.primaryAxisOf', () {
    TriageHistoryEntry log({
      String? anatomical,
      String? emotional,
      bool organic = false,
      Map<String, dynamic>? stepAnswers,
    }) =>
        TriageHistoryEntry(
          id: 'x',
          intensity: 3,
          anatomicalSystem: anatomical,
          emotionalDimension: emotional,
          organicPrimacyApplied: organic,
          stepAnswers: stepAnswers,
          recordedAt: _todayAt(1),
        );

    test('daily_checkin -> null', () {
      expect(
        AxisIntensityResolver.primaryAxisOf(
            log(stepAnswers: {'type': 'daily_checkin'})),
        isNull,
      );
    });
    test('geral_emocional -> emotional', () {
      expect(AxisIntensityResolver.primaryAxisOf(log(anatomical: 'geral_emocional')),
          CheckInAxis.emotional);
    });
    test('only emotionalDimension -> emotional', () {
      expect(AxisIntensityResolver.primaryAxisOf(log(emotional: 'sono')),
          CheckInAxis.emotional);
    });
    test('only anatomicalSystem -> physical', () {
      expect(AxisIntensityResolver.primaryAxisOf(log(anatomical: 'neurologico')),
          CheckInAxis.physical);
    });
    test('both + organicPrimacyApplied -> emotional', () {
      expect(
        AxisIntensityResolver.primaryAxisOf(
            log(anatomical: 'neurologico', emotional: 'sono', organic: true)),
        CheckInAxis.emotional,
      );
    });
    test('both without organicPrimacyApplied -> physical', () {
      expect(
        AxisIntensityResolver.primaryAxisOf(
            log(anatomical: 'neurologico', emotional: 'sono')),
        CheckInAxis.physical,
      );
    });
    test('neither -> null', () {
      expect(AxisIntensityResolver.primaryAxisOf(log()), isNull);
    });
  });

  group('AxisIntensityResolver.latestRecordFor', () {
    test('own-axis record beats a newer cross-vertically tagged record', () {
      final logs = [_p1(), _e1, _e2];
      final emo = AxisIntensityResolver.latestRecordFor(CheckInAxis.emotional, logs);
      final phys = AxisIntensityResolver.latestRecordFor(CheckInAxis.physical, logs);
      expect(emo, isNotNull);
      expect(emo!.id, anyOf('e1', 'e2'));
      expect(emo.intensity, 3);
      expect(phys!.id, 'p1');
      expect(phys.intensity, 2);
    });

    test('falls back to the cross-vertical tag when no own-axis record exists', () {
      final emo = AxisIntensityResolver.latestRecordFor(
          CheckInAxis.emotional, [_p1()]);
      expect(emo!.id, 'p1');
    });

    test('never returns daily_checkin logs', () {
      final checkIn = TriageHistoryEntry(
        id: 'chk',
        intensity: 3,
        emotionalDimension: 'sono',
        anatomicalSystem: 'neurologico',
        stepAnswers: const {'type': 'daily_checkin', 'emotionalStatus': 'soSo'},
        recordedAt: _todayAt(30),
      );
      expect(
          AxisIntensityResolver.latestRecordFor(CheckInAxis.emotional, [checkIn]),
          isNull);
      expect(
          AxisIntensityResolver.latestRecordFor(CheckInAxis.physical, [checkIn]),
          isNull);
    });
  });

  group('AxisIntensityResolver.resolveDisplayIntensity', () {
    test('state per-axis intensity beats the derived secondary score', () {
      final outcome = _stalePhysicalOutcome();
      const state = TriggerCheckInState(emotionalIntensity: 3);
      expect(
          AxisIntensityResolver.resolveDisplayIntensity(
              axis: CheckInAxis.emotional, state: state, outcome: outcome),
          3);
      expect(
          AxisIntensityResolver.resolveDisplayIntensity(
              axis: CheckInAxis.physical, state: state, outcome: outcome),
          2);
    });

    test('derived secondary is the fallback with an empty state', () {
      expect(
          AxisIntensityResolver.resolveDisplayIntensity(
              axis: CheckInAxis.emotional,
              state: const TriggerCheckInState(),
              outcome: _stalePhysicalOutcome()),
          4);
    });

    test('status default is the last fallback', () {
      expect(
          AxisIntensityResolver.resolveDisplayIntensity(
              axis: CheckInAxis.emotional,
              state: const TriggerCheckInState(emotionalStatus: TriggerStatus.soSo)),
          3);
    });

    test('own-axis outcome score wins', () {
      final outcome = TriageOutcome(
        id: 'e1',
        vertical: 'emotional',
        intensityScore: 3,
        careDisposition: CareDisposition.routineConsultation,
        primaryCategory: 'estresse_burnout',
        categoryLabel: 'Estresse e Burnout',
        somaticMapping: '',
        organicPrimacyApplied: true,
        recommendedArticles: const [],
        recordedAt: _todayAt(10),
      );
      expect(
          AxisIntensityResolver.resolveDisplayIntensity(
              axis: CheckInAxis.emotional,
              state: const TriggerCheckInState(emotionalIntensity: 5),
              outcome: outcome),
          3);
    });
  });

  group('TriggerCheckInNotifier single-source regression', () {
    test('remote records override stale local per-axis intensity', () async {
      final storage = _FakeSecureStorage(
        checkIn: _staleCheckInJson(),
        outcome: _stalePhysicalOutcome().toJson(),
      );
      final container =
          _container(storage, [_p1(withEmotionalTag: false), _e1, _e2]);
      addTearDown(container.dispose);

      await container.read(triggerCheckInProvider.notifier).loadTodayCheckIn();
      await _flush();

      final state = container.read(triggerCheckInProvider);
      expect(state.emotionalIntensity, 3);
      expect(state.emotionalStatus, TriggerStatus.soSo);
      expect(state.physicalIntensity, 2);
      expect(state.isEmotionalCompleted, isTrue);
      expect(state.isPhysicalCompleted, isTrue);
    });

    test('markCompletedWithOutcome keeps an already-completed other axis', () {
      final container = _container(_FakeSecureStorage(), const []);
      addTearDown(container.dispose);
      final notifier = container.read(triggerCheckInProvider.notifier);

      notifier.markCompletedWithOutcome(TriageOutcome(
        id: 'e1',
        vertical: 'emotional',
        intensityScore: 3,
        careDisposition: CareDisposition.routineConsultation,
        primaryCategory: 'estresse_burnout',
        categoryLabel: 'Estresse e Burnout',
        somaticMapping: '',
        organicPrimacyApplied: false,
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
      ));
      notifier.markCompletedWithOutcome(_stalePhysicalOutcome());

      final state = container.read(triggerCheckInProvider);
      expect(state.emotionalIntensity, 3);
      expect(state.emotionalStatus, TriggerStatus.soSo);
      expect(state.physicalIntensity, 2);
    });

    test('markCompletedWithOutcome still seeds the other axis from secondary on a fresh state', () {
      final container = _container(_FakeSecureStorage(), const []);
      addTearDown(container.dispose);
      final notifier = container.read(triggerCheckInProvider.notifier);

      notifier.markCompletedWithOutcome(_stalePhysicalOutcome());

      final state = container.read(triggerCheckInProvider);
      expect(state.emotionalIntensity, 4);
      expect(state.emotionalStatus, TriggerStatus.badSick);
    });
  });

  group('Home DualAxisTriggerCard end-to-end', () {
    testWidgets('shows Moderada (3) emotional and Leve (1-2) physical in the bug scenario',
        (tester) async {
      final storage = _FakeSecureStorage(
        checkIn: _staleCheckInJson(),
        outcome: _stalePhysicalOutcome().toJson(),
      );
      final container =
          _container(storage, [_p1(withEmotionalTag: false), _e1, _e2]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_harness(container, const DualAxisTriggerCard()));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('psicoemocional_completed_card')),
          matching: find.text('Moderada (3)'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('fisica_completed_card')),
          matching: find.text('Leve (1-2)'),
        ),
        findsOneWidget,
      );
      expect(find.text('Intensa (4-5)'), findsNothing);
    });
  });

  group('Resultado do Dia (TodayTriageResultTab) end-to-end', () {
    testWidgets('associated emotional card shows Moderada (3), physical shows Leve (1-2)',
        (tester) async {
      final storage = _FakeSecureStorage(
        checkIn: _staleCheckInJson(),
        outcome: _stalePhysicalOutcome().toJson(),
      );
      final container =
          _container(storage, [_p1(withEmotionalTag: false), _e1, _e2]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _harness(container, TodayTriageResultTab(onGoToCheckIn: () {})),
      );
      await tester.pumpAndSettle();

      expect(container.read(triageOutcomeProvider).outcome?.intensityScore, 2);
      expect(find.text('2. Eixo Avaliação Psico-emocional'), findsOneWidget);
      expect(find.text('Estresse e Burnout'), findsOneWidget);
      expect(find.text('Moderada (3)'), findsOneWidget);
      expect(find.text('Leve (1-2)'), findsOneWidget);
      expect(find.text('Intensa (4-5)'), findsNothing);
    });
  });

  group('TriageOutcomeNotifier rebuild from history', () {
    test('emotional cross-vertical record rebuilds as an emotional outcome', () async {
      final container = _container(_FakeSecureStorage(), [_e1]);
      addTearDown(container.dispose);

      await container.read(triageOutcomeProvider.notifier).loadTodayOutcome();
      await _flush();

      final outcome = container.read(triageOutcomeProvider).outcome;
      expect(outcome, isNotNull);
      expect(outcome!.vertical, 'emotional');
      expect(outcome.primaryCategory, 'estresse_burnout');
      expect(outcome.secondaryCategoryLabel, mapCategoryLabel('neurologico'));
    });

    test('secondary score comes from the other axis own record', () async {
      final container = _container(_FakeSecureStorage(), [_p1(), _e1]);
      addTearDown(container.dispose);

      await container.read(triageOutcomeProvider.notifier).loadTodayOutcome();
      await _flush();

      final outcome = container.read(triageOutcomeProvider).outcome;
      expect(outcome, isNotNull);
      expect(outcome!.vertical, 'physical');
      expect(outcome.intensityScore, 2);
      expect(outcome.secondaryIntensityScore, 3);
    });
  });
}
