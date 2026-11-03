import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/constants/app_colors.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/home/domain/axis_intensity_resolver.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dual_axis_trigger_card.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeSecureStorage extends SecureStorageService {
  Map<String, dynamic>? checkIn;

  _FakeSecureStorage({this.checkIn});

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
        journalPatterns: const [],
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
/// with a physical system; the backend returns the submitted vertical.
TriageHistoryEntry _e(String id, int minutes) => TriageHistoryEntry(
      id: id,
      intensity: 3,
      emotionalDimension: 'estresse_burnout',
      anatomicalSystem: 'neurologico',
      vertical: 'emotional',
      narrative: 'muito estresse no trabalho',
      recordedAt: _todayAt(minutes),
    );

/// Physical neurologico record, intensity 2 (newest).
TriageHistoryEntry _p1({bool withEmotionalTag = true}) => TriageHistoryEntry(
      id: 'p1',
      intensity: 2,
      anatomicalSystem: 'neurologico',
      emotionalDimension: withEmotionalTag ? 'estresse_burnout' : null,
      vertical: 'physical',
      narrative: 'tontura',
      recordedAt: _todayAt(12),
    );

TriageHistoryEntry get _e1 => _e('e1', 10);
TriageHistoryEntry get _e2 => _e('e2', 11);

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

  group('triggerStatusFromStepAnswer', () {
    test('parses enum names and declared-state labels', () {
      expect(triggerStatusFromStepAnswer('badSick'), TriggerStatus.badSick);
      expect(triggerStatusFromStepAnswer('mal'), TriggerStatus.badSick);
      expect(triggerStatusFromStepAnswer('soSo'), TriggerStatus.soSo);
      expect(triggerStatusFromStepAnswer('mais ou menos'), TriggerStatus.soSo);
      expect(triggerStatusFromStepAnswer('goodNormal'), TriggerStatus.goodNormal);
      expect(triggerStatusFromStepAnswer('bem'), TriggerStatus.goodNormal);
    });

    test('reads axis status from daily check-in stepAnswers', () {
      final log = TriageHistoryEntry(
        id: 'dc-1',
        intensity: 0,
        stepAnswers: const {
          'type': 'daily_checkin',
          'emotionalStatus': 'badSick',
          'physicalStatus': 'goodNormal',
        },
        recordedAt: DateTime.now(),
      );
      expect(
        declaredStatusOnLog(log, CheckInAxis.emotional),
        TriggerStatus.badSick,
      );
      expect(
        declaredStatusOnLog(log, CheckInAxis.physical),
        TriggerStatus.goodNormal,
      );
    });
  });

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
      String? vertical,
      Map<String, dynamic>? stepAnswers,
    }) =>
        TriageHistoryEntry(
          id: 'x',
          intensity: 3,
          anatomicalSystem: anatomical,
          emotionalDimension: emotional,
          organicPrimacyApplied: organic,
          vertical: vertical,
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
    test('both + vertical emotional -> emotional', () {
      expect(
        AxisIntensityResolver.primaryAxisOf(
            log(anatomical: 'neurologico', emotional: 'sono', vertical: 'emotional')),
        CheckInAxis.emotional,
      );
    });
    test('both + vertical physical -> physical (vertical beats legacy flag)', () {
      expect(
        AxisIntensityResolver.primaryAxisOf(log(
            anatomical: 'neurologico',
            emotional: 'sono',
            organic: true,
            vertical: 'physical')),
        CheckInAxis.physical,
      );
    });
    test('legacy row: both + organicPrimacyApplied -> emotional', () {
      expect(
        AxisIntensityResolver.primaryAxisOf(
            log(anatomical: 'neurologico', emotional: 'sono', organic: true)),
        CheckInAxis.emotional,
      );
    });
    test('legacy row: both without vertical or flag -> physical', () {
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
    test('state per-axis intensity is returned', () {
      const state = TriggerCheckInState(
        emotionalIntensity: 3,
        physicalIntensity: 2,
      );
      expect(
        AxisIntensityResolver.resolveDisplayIntensity(
          axis: CheckInAxis.emotional,
          state: state,
        ),
        3,
      );
      expect(
        AxisIntensityResolver.resolveDisplayIntensity(
          axis: CheckInAxis.physical,
          state: state,
        ),
        2,
      );
    });

    test('status default is the fallback', () {
      expect(
        AxisIntensityResolver.resolveDisplayIntensity(
          axis: CheckInAxis.emotional,
          state: const TriggerCheckInState(emotionalStatus: TriggerStatus.soSo),
        ),
        3,
      );
    });
  });

  group('TriggerCheckInNotifier single-source regression', () {
    test('remote records override stale local per-axis intensity', () async {
      final storage = _FakeSecureStorage(
        checkIn: _staleCheckInJson(),
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
  });

  group('Home DualAxisTriggerCard end-to-end', () {
    testWidgets('shows Moderada (3) emotional and Leve (1-2) physical in the bug scenario',
        (tester) async {
      final storage = _FakeSecureStorage(
        checkIn: _staleCheckInJson(),
      );
      final container =
          _container(storage, [_p1(withEmotionalTag: false), _e1, _e2]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_harness(container, const DualAxisTriggerCard()));
      await tester.pumpAndSettle();

      final emotionalCard = tester.widget<Container>(
        find.byKey(const Key('psicoemocional_completed_card')),
      );
      expect(
        (emotionalCard.decoration as BoxDecoration).color,
        AppColors.intensityModerateBg,
      );

      final physicalCard = tester.widget<Container>(
        find.byKey(const Key('fisica_completed_card')),
      );
      expect(
        (physicalCard.decoration as BoxDecoration).color,
        AppColors.intensityMildBg,
      );
    });
  });
}
