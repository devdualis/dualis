import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/notifications/daily_checkin_notification_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../dashboard/data/triage_history_remote_data_source.dart';
import '../../../dashboard/domain/models/triage_history_models.dart';
import '../../../triage/data/symptom_classification_remote_data_source.dart';
import '../../../triage/domain/triage_vertical.dart';
import '../../../triage_outcome/domain/triage_outcome_models.dart';
import '../../../triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import '../../domain/axis_intensity_resolver.dart';
import '../../domain/trigger_checkin_state.dart';

const Object _keepNarrative = Object();

final symptomClassificationDataSourceProvider =
    Provider<SymptomClassificationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return SymptomClassificationRemoteDataSource(
    apiClient: apiClient,
    secureStorage: secureStorage,
  );
});

class TriggerCheckInNotifier extends Notifier<TriggerCheckInState> {
  SecureStorageService get _storage => ref.read(secureStorageServiceProvider);
  TriageHistoryRemoteDataSource get _historyDataSource =>
      ref.read(triageHistoryDataSourceProvider);
  SymptomClassificationRemoteDataSource get _classificationDataSource =>
      ref.read(symptomClassificationDataSourceProvider);

  @override
  TriggerCheckInState build() {
    Future.microtask(() => loadTodayCheckIn());
    return const TriggerCheckInState();
  }

  String _getTodayDateString([DateTime? now]) {
    final d = now ?? DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  TriggerStatus? _parseTriggerStatus(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    for (final s in TriggerStatus.values) {
      if (s.name == str) return s;
    }
    return null;
  }

  Future<void> _loadLocalTodayCheckIn([DateTime? now]) async {
    try {
      final userId = await _storage.getUserId() ?? 'anonymous';
      final saved = await _storage.getDailyCheckIn(userId);
      if (saved == null) {
        final today = _getTodayDateString(now);
        if (state.checkInDate != null && state.checkInDate != today) {
          state = const TriggerCheckInState();
        }
        return;
      }

      final today = _getTodayDateString(now);
      final savedDate = saved['checkInDate'] as String?;

      if (savedDate == today) {
        state = TriggerCheckInState.fromJson(saved);
      } else {
        await _storage.clearDailyCheckIn(userId);
        state = const TriggerCheckInState();
      }
    } catch (_) {}
  }

  Future<void> _syncTodayCheckInFromRemote([DateTime? now]) async {
    try {
      final history = await _historyDataSource.fetchHistory(days: 1);
      if (history.logs.isEmpty) return;

      final todayStr = _getTodayDateString(now);
      final todayLogs = history.logs.where((log) {
        final localDate = log.recordedAt.toLocal();
        return _getTodayDateString(localDate) == todayStr;
      }).toList();

      if (todayLogs.isEmpty) return;

      todayLogs.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      final latestLog = todayLogs.first;

      String naturalLanguageText = state.naturalLanguageText;

      String? cleanNarrative(String? text) {
        if (text == null) return null;
        final trimmed = text.trim();
        if (trimmed.isEmpty || int.tryParse(trimmed) != null) return null;
        return trimmed;
      }

      if (AxisIntensityResolver.isDailyCheckIn(latestLog)) {
        final answers = latestLog.stepAnswers;
        if (answers != null &&
            answers['naturalLanguageText'] is String &&
            (answers['naturalLanguageText'] as String).isNotEmpty) {
          naturalLanguageText = answers['naturalLanguageText'] as String;
        }
      } else {
        // The most recent record today is a full clinical triage
        final logNarrative = cleanNarrative(latestLog.narrative) ??
            cleanNarrative(latestLog.stepAnswers?['naturalLanguageText'] as String?);
        if (logNarrative != null) {
          naturalLanguageText = logNarrative;
        }
      }

      // Per-axis derivation: the latest real record for the axis is the single
      // source of truth for its intensity and status, overriding stale local
      // state. A newer daily check-in answer for the axis wins over it.
      ({
        TriggerStatus status,
        int? intensity,
        bool completed,
        String? summary,
        String? narrative,
      }) resolveAxis(CheckInAxis axis) {
        final isEmotional = axis == CheckInAxis.emotional;
        final statusKey = isEmotional ? 'emotionalStatus' : 'physicalStatus';
        final currentStatus =
            isEmotional ? state.emotionalStatus : state.physicalStatus;
        final currentIntensity =
            isEmotional ? state.emotionalIntensity : state.physicalIntensity;
        final currentCompleted =
            isEmotional ? state.isEmotionalCompleted : state.isPhysicalCompleted;
        final currentSummary =
            isEmotional ? state.emotionalSummary : state.physicalSummary;
        final currentNarrative =
            isEmotional ? state.emotionalNarrative : state.physicalNarrative;

        final rec = AxisIntensityResolver.latestRecordFor(axis, todayLogs);

        TriageHistoryEntry? chk;
        TriggerStatus? chkStatus;
        for (final log in todayLogs) {
          if (!AxisIntensityResolver.isDailyCheckIn(log)) continue;
          final parsed = _parseTriggerStatus(log.stepAnswers?[statusKey]);
          if (parsed != null) {
            chk = log;
            chkStatus = parsed;
            break;
          }
        }

        if (rec != null &&
            (chk == null || !rec.recordedAt.isBefore(chk.recordedAt))) {
          final code = AxisIntensityResolver.categoryCodeFor(rec, axis);
          return (
            status: triggerStatusFromIntensity(rec.intensity),
            intensity: rec.intensity,
            completed: true,
            summary: currentSummary ??
                (code != null
                    ? mapCategoryLabel(code)
                    : (isEmotional ? 'Psicoemocional' : 'Avaliação Física')),
            // A description belongs to the triage it was typed in: only the
            // axis's own record supplies it, and the record wins over local
            // state so an older triage's text never lingers.
            narrative: AxisIntensityResolver.primaryAxisOf(rec) == axis
                ? cleanNarrative(rec.narrative) ??
                    cleanNarrative(rec.stepAnswers?['naturalLanguageText'] as String?)
                : null,
          );
        }
        if (chk != null && chkStatus != null) {
          return (
            status: chkStatus,
            intensity: chkStatus.defaultIntensity,
            completed: true,
            summary: currentSummary ?? 'Check-in Diário',
            narrative: currentNarrative,
          );
        }
        return (
          status: currentStatus ?? TriggerStatus.goodNormal,
          intensity: currentIntensity,
          completed: currentCompleted,
          summary: currentSummary,
          narrative: currentNarrative,
        );
      }

      final emotional = resolveAxis(CheckInAxis.emotional);
      final physical = resolveAxis(CheckInAxis.physical);

      final emotionalStatus = emotional.status;
      final physicalStatus = physical.status;
      final emotionalIntensity = emotional.intensity;
      final physicalIntensity = physical.intensity;
      final isEmotionalCompleted = emotional.completed;
      final isPhysicalCompleted = physical.completed;
      final emotionalSummary = emotional.summary;
      final physicalSummary = physical.summary;
      final emotionalNarrative = emotional.narrative;
      final physicalNarrative = physical.narrative;

      if (!state.isModifiedAfterCompletion) {
        state = state.copyWith(
          isCompletedToday: true,
          completedAt: latestLog.recordedAt.toLocal(),
          checkInDate: todayStr,
          emotionalStatus: emotionalStatus,
          physicalStatus: physicalStatus,
          emotionalIntensity: emotionalIntensity,
          physicalIntensity: physicalIntensity,
          naturalLanguageText: naturalLanguageText,
          isPhysicalCompleted: isPhysicalCompleted,
          isEmotionalCompleted: isEmotionalCompleted,
          physicalSummary: physicalSummary,
          emotionalSummary: emotionalSummary,
          physicalNarrative: physicalNarrative,
          emotionalNarrative: emotionalNarrative,
          isModifiedAfterCompletion: false,
          emotionalTouched: false,
          physicalTouched: false,
          textTouched: false,
        );
        await _persistCurrentState();
        ref.read(triageOutcomeProvider.notifier).loadTodayOutcome();
      }
    } catch (_) {}
  }

  Future<void> loadTodayCheckIn([DateTime? now]) async {
    await _loadLocalTodayCheckIn(now);
    await _syncTodayCheckInFromRemote(now);
    try {
      await ref
          .read(dailyCheckinNotificationServiceProvider)
          .scheduleDailyCheckInReminders(isCompletedToday: state.isCompletedToday);
    } catch (_) {}
  }

  Future<void> _persistCurrentState() async {
    try {
      final userId = await _storage.getUserId() ?? 'anonymous';
      final today = _getTodayDateString();
      final toSave = state.copyWith(checkInDate: today);
      await _storage.saveDailyCheckIn(
        userId: userId,
        data: toSave.toJson(),
      );
    } catch (_) {}
  }

  void setEmotionalStatus(TriggerStatus status) {
    final modified = state.isCompletedToday && status != state.emotionalStatus;
    final int? intensity = status.defaultIntensity;
    state = state.copyWith(
      emotionalStatus: status,
      emotionalIntensity: intensity,
      isModifiedAfterCompletion: modified || state.isModifiedAfterCompletion,
      emotionalTouched: true,
      checkInDate: _getTodayDateString(),
    );
    _persistCurrentState();
  }

  void setPhysicalStatus(TriggerStatus status) {
    final modified = state.isCompletedToday && status != state.physicalStatus;
    final int? intensity = status.defaultIntensity;
    state = state.copyWith(
      physicalStatus: status,
      physicalIntensity: intensity,
      isModifiedAfterCompletion: modified || state.isModifiedAfterCompletion,
      physicalTouched: true,
      checkInDate: _getTodayDateString(),
    );
    _persistCurrentState();
  }

  void setNaturalLanguageText(String text) {
    final modified = state.isCompletedToday && text.trim() != state.naturalLanguageText.trim();
    state = state.copyWith(
      naturalLanguageText: text,
      textTouched: true,
      isModifiedAfterCompletion: modified || state.isModifiedAfterCompletion,
      checkInDate: _getTodayDateString(),
    );
    _persistCurrentState();
  }

  /// Classifies the typed symptom text and builds navigation args to open the
  /// triage wizard pre-set to the right vertical/category, so free text always
  /// reaches the onset/severity questions instead of being silently discarded.
  ///
  /// Returns `null` when there is no text to classify, or when classification
  /// fails (offline, error) — callers should fall back to axis-only routing.
  Future<TriageNavigationArgs?> resolveTextDrivenNavigation() async {
    final text = state.naturalLanguageText.trim();
    if (text.isEmpty) return null;

    try {
      final classification = await _classificationDataSource.classify(text);
      final vertical = classification.primaryVertical == 'emotional'
          ? TriageVertical.psicoEmocional
          : TriageVertical.fisica;
      final hasCrossVertical = (classification.primaryVertical == 'physical' &&
              state.emotionalStatus != null &&
              state.emotionalStatus != TriggerStatus.goodNormal) ||
          (classification.primaryVertical == 'emotional' &&
              state.physicalStatus != null &&
              state.physicalStatus != TriggerStatus.goodNormal);

      final isDual = (state.emotionalStatus != TriggerStatus.goodNormal &&
              state.physicalStatus != TriggerStatus.goodNormal) ||
          hasCrossVertical;

      return TriageNavigationArgs(
        initialVertical: vertical,
        isDual: isDual,
        naturalLanguageText: state.naturalLanguageText,
        preselectedCategoryKey: classification.wizardCategoryKey,
        isOffTopic: classification.isOffTopic,
      );
    } catch (_) {
      return null;
    }
  }

  /// [narrative] is the free text the user typed in the triage that produced
  /// [outcome]. Pass it — even as `null` — only when submitting that triage.
  /// Omitting it (replaying a stored or remote outcome) keeps the axis's
  /// current narrative, which the history sync owns.
  void markCompletedWithOutcome(
    TriageOutcome outcome, {
    Object? narrative = _keepNarrative,
  }) {
    final today = _getTodayDateString(outcome.recordedAt);
    final isPhysical = outcome.vertical == 'physical';

    TriggerStatus emotionalStatus;
    TriggerStatus physicalStatus;
    int? emotionalIntensity;
    int? physicalIntensity;

    // The derived secondary score must never overwrite the other axis when it
    // is already completed today with a known (record-backed) intensity.
    final keepEmotional =
        state.isEmotionalCompleted && state.emotionalIntensity != null;
    final keepPhysical =
        state.isPhysicalCompleted && state.physicalIntensity != null;

    if (isPhysical) {
      physicalIntensity = outcome.intensityScore;
      physicalStatus = triggerStatusFromIntensity(outcome.intensityScore);
      if (keepEmotional) {
        emotionalIntensity = state.emotionalIntensity;
        emotionalStatus = state.emotionalStatus ??
            triggerStatusFromIntensity(state.emotionalIntensity);
      } else if (outcome.secondaryCategoryLabel != null) {
        final secScore = outcome.secondaryIntensityScore ?? outcome.intensityScore;
        emotionalIntensity = secScore;
        emotionalStatus = triggerStatusFromIntensity(secScore);
      } else {
        emotionalIntensity = state.emotionalIntensity;
        emotionalStatus = state.emotionalStatus ?? TriggerStatus.goodNormal;
      }
    } else {
      emotionalIntensity = outcome.intensityScore;
      emotionalStatus = triggerStatusFromIntensity(outcome.intensityScore);
      if (keepPhysical) {
        physicalIntensity = state.physicalIntensity;
        physicalStatus = state.physicalStatus ??
            triggerStatusFromIntensity(state.physicalIntensity);
      } else if (outcome.organicPrimacyApplied || outcome.secondaryCategoryLabel != null) {
        final secScore = outcome.secondaryIntensityScore ?? outcome.intensityScore;
        physicalIntensity = secScore;
        physicalStatus = triggerStatusFromIntensity(secScore);
      } else {
        physicalIntensity = state.physicalIntensity;
        physicalStatus = state.physicalStatus ?? TriggerStatus.goodNormal;
      }
    }

    final summary = outcome.categoryLabel.isNotEmpty ? outcome.categoryLabel : (isPhysical ? 'Avaliação Física' : 'Psicoemocional');
    // The AI's mapped lay term is never used here: it is not the user's text.
    final isSubmission = !identical(narrative, _keepNarrative);
    final typed = isSubmission ? (narrative as String?)?.trim() : null;
    final cleanNarrative =
        (typed != null && typed.isNotEmpty && int.tryParse(typed) == null)
            ? typed
            : null;
    final axisNarrative = isSubmission
        ? cleanNarrative
        : (isPhysical ? state.physicalNarrative : state.emotionalNarrative);

    state = state.copyWith(
      isCompletedToday: true,
      isEmotionalCompleted: isPhysical ? state.isEmotionalCompleted : true,
      isPhysicalCompleted: isPhysical ? true : state.isPhysicalCompleted,
      emotionalSummary: isPhysical ? state.emotionalSummary : summary,
      physicalSummary: isPhysical ? summary : state.physicalSummary,
      emotionalNarrative: isPhysical ? state.emotionalNarrative : axisNarrative,
      physicalNarrative: isPhysical ? axisNarrative : state.physicalNarrative,
      completedAt: outcome.recordedAt,
      checkInDate: today,
      isModifiedAfterCompletion: false,
      emotionalStatus: emotionalStatus,
      physicalStatus: physicalStatus,
      emotionalIntensity: emotionalIntensity,
      physicalIntensity: physicalIntensity,
      naturalLanguageText: cleanNarrative ??
          (int.tryParse(state.naturalLanguageText.trim()) == null
              ? state.naturalLanguageText
              : ''),
      emotionalTouched: false,
      physicalTouched: false,
      textTouched: false,
    );
    _persistCurrentState();
    try {
      ref.read(dailyCheckinNotificationServiceProvider).cancelAllCheckInReminders();
    } catch (_) {}
  }

  void completeStage({
    required TriageVertical vertical,
    required String summary,
    String? narrative,
    int? intensity,
    TriggerStatus? status,
  }) {
    final isPhysical = vertical == TriageVertical.fisica;
    final today = _getTodayDateString();
    final cleanNarrative = (narrative != null &&
            narrative.trim().isNotEmpty &&
            int.tryParse(narrative.trim()) == null)
        ? narrative.trim()
        : null;
    final resolvedIntensity = intensity ?? status?.defaultIntensity;
    state = state.copyWith(
      isCompletedToday: true,
      isEmotionalCompleted: isPhysical ? state.isEmotionalCompleted : true,
      isPhysicalCompleted: isPhysical ? true : state.isPhysicalCompleted,
      emotionalSummary: isPhysical ? state.emotionalSummary : summary,
      physicalSummary: isPhysical ? summary : state.physicalSummary,
      emotionalNarrative: isPhysical ? state.emotionalNarrative : cleanNarrative,
      physicalNarrative: isPhysical ? cleanNarrative : state.physicalNarrative,
      emotionalIntensity: isPhysical ? state.emotionalIntensity : resolvedIntensity,
      physicalIntensity: isPhysical ? resolvedIntensity : state.physicalIntensity,
      emotionalStatus: isPhysical ? state.emotionalStatus : (status ?? state.emotionalStatus),
      physicalStatus: isPhysical ? (status ?? state.physicalStatus) : state.physicalStatus,
      completedAt: DateTime.now(),
      checkInDate: today,
      isModifiedAfterCompletion: false,
    );
    _persistCurrentState();
    try {
      ref.read(dailyCheckinNotificationServiceProvider).cancelAllCheckInReminders();
    } catch (_) {}
  }

  void prepareForUpdate() {
    state = state.copyWith(
      isModifiedAfterCompletion: true,
    );
  }

  void markCompletedToday() {
    final today = _getTodayDateString();
    state = state.copyWith(
      isCompletedToday: true,
      isEmotionalCompleted: true,
      isPhysicalCompleted: true,
      completedAt: DateTime.now(),
      checkInDate: today,
      isModifiedAfterCompletion: false,
      emotionalTouched: false,
      physicalTouched: false,
      textTouched: false,
    );
    _persistCurrentState();
    try {
      ref.read(dailyCheckinNotificationServiceProvider).cancelAllCheckInReminders();
    } catch (_) {}

    final isSymptomCheckIn = state.emotionalStatus != TriggerStatus.goodNormal ||
        state.physicalStatus != TriggerStatus.goodNormal ||
        state.naturalLanguageText.trim().isNotEmpty;

    final existingOutcome = ref.read(triageOutcomeProvider).outcome;
    if (isSymptomCheckIn && existingOutcome == null) {
      final intensity = (state.emotionalStatus == TriggerStatus.badSick ||
              state.physicalStatus == TriggerStatus.badSick)
          ? 4
          : ((state.emotionalStatus == TriggerStatus.soSo ||
                  state.physicalStatus == TriggerStatus.soSo)
              ? 3
              : 1);
      final disposition = intensity == 4
          ? 'pronto_atendimento'
          : (intensity == 3 ? 'consulta_rotina' : 'auto_cuidado');

      ref.read(triageOutcomeProvider.notifier).setOutcomeFromCheckIn(
            id: 'checkin-${DateTime.now().millisecondsSinceEpoch}',
            intensity: intensity,
            disposition: disposition,
            emotionalStatus: state.emotionalStatus?.name ?? 'goodNormal',
            physicalStatus: state.physicalStatus?.name ?? 'goodNormal',
            naturalLanguageText: state.naturalLanguageText,
          );
    }

    _syncCheckInToRemote();
  }

  Future<void> _syncCheckInToRemote() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) return;
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiEndpoints.dailyCheckIn,
        data: {
          'emotionalStatus': state.emotionalStatus?.name ?? 'goodNormal',
          'physicalStatus': state.physicalStatus?.name ?? 'goodNormal',
          if (state.naturalLanguageText.isNotEmpty)
            'naturalLanguageText': state.naturalLanguageText,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final id = data['id'] as String? ?? 'checkin-${DateTime.now().millisecondsSinceEpoch}';
        final intensity = (data['intensity'] as num?)?.toInt() ?? 1;
        final disposition = data['disposition'] as String? ?? 'auto_cuidado';
        List<RecommendedArticle>? articles;
        if (data['recommendedArticles'] is List) {
          articles = (data['recommendedArticles'] as List)
              .map((e) => RecommendedArticle.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        final isSymptomCheckIn = state.emotionalStatus != TriggerStatus.goodNormal ||
            state.physicalStatus != TriggerStatus.goodNormal ||
            state.naturalLanguageText.trim().isNotEmpty;

        final existingOutcome = ref.read(triageOutcomeProvider).outcome;
        if (isSymptomCheckIn && existingOutcome == null) {
          ref.read(triageOutcomeProvider.notifier).setOutcomeFromCheckIn(
                id: id,
                intensity: intensity,
                disposition: disposition,
                emotionalStatus: state.emotionalStatus?.name ?? 'goodNormal',
                physicalStatus: state.physicalStatus?.name ?? 'goodNormal',
                naturalLanguageText: state.naturalLanguageText,
                articles: articles,
              );
        }
      }
    } catch (_) {}
  }

  void checkAndResetIfNewDay([DateTime? currentDateTime]) {
    final today = _getTodayDateString(currentDateTime);
    if (state.checkInDate != null && state.checkInDate != today) {
      reset();
    }
  }

  void reset() {
    state = const TriggerCheckInState();
    _clearStorage();
    try {
      ref
          .read(dailyCheckinNotificationServiceProvider)
          .scheduleDailyCheckInReminders(isCompletedToday: false);
    } catch (_) {}
  }

  void resetStage({required bool isPhysical}) {
    if (isPhysical) {
      state = state.copyWith(
        isPhysicalCompleted: false,
        physicalStatus: null,
        physicalIntensity: null,
        physicalSummary: null,
        physicalNarrative: null,
        isCompletedToday: state.isEmotionalCompleted,
      );
    } else {
      state = state.copyWith(
        isEmotionalCompleted: false,
        emotionalStatus: null,
        emotionalIntensity: null,
        emotionalSummary: null,
        emotionalNarrative: null,
        isCompletedToday: state.isPhysicalCompleted,
      );
    }
    _persistCurrentState();
  }

  Future<void> _clearStorage() async {
    try {
      final userId = await _storage.getUserId() ?? 'anonymous';
      await _storage.clearDailyCheckIn(userId);
    } catch (_) {}
  }
}

final triggerCheckInProvider =
    NotifierProvider<TriggerCheckInNotifier, TriggerCheckInState>(
  TriggerCheckInNotifier.new,
);
