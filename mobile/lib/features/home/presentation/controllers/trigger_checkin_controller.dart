import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/notifications/daily_checkin_notification_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/data/triage_history_remote_data_source.dart';
import '../../../dashboard/domain/models/triage_history_models.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
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

  bool _isDisposed = false;
  String? _lastProfileId;

  String _scopedUserId(String userId) {
    if (_isDisposed) return userId;
    try {
      final profileId = ref.read(activeProfileControllerProvider).activeProfile?.id;
      return (profileId != null && profileId.isNotEmpty) ? '${userId}_$profileId' : userId;
    } catch (_) {
      return userId;
    }
  }

  @override
  TriggerCheckInState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
    });

    final activeProfileId = ref.watch(
      activeProfileControllerProvider.select((s) => s.activeProfile?.id),
    );
    if (_lastProfileId != activeProfileId) {
      _lastProfileId = activeProfileId;
      Future.microtask(() {
        if (_isDisposed) return;
        try {
          if (ref.exists(triageOutcomeProvider)) {
            ref.read(triageOutcomeProvider.notifier).reset();
            ref.read(triageOutcomeProvider.notifier).loadTodayOutcome();
          }
        } catch (_) {}
      });
    }

    // Pending reminders carry the language they were scheduled in: re-arm
    // them when the app language changes (only while someone is signed in).
    ref.listen<Locale>(localeProvider, (previous, next) {
      if (_isDisposed) return;
      if (previous == next) return;
      try {
        if (!ref.read(authControllerProvider).isAuthenticated) return;
        _syncCheckInReminders();
      } catch (_) {}
    });
    Future.microtask(() {
      if (!_isDisposed) {
        loadTodayCheckIn();
      }
    });
    return const TriggerCheckInState();
  }

  /// Re-arms the check-in reminders for the current completion state. When
  /// today is already done, today's remaining slots are skipped but the
  /// following days keep their reminders — a bare cancel would silence every
  /// future day until the app happened to be opened again.
  void _syncCheckInReminders() {
    try {
      unawaited(ref
          .read(dailyCheckinNotificationServiceProvider)
          .scheduleDailyCheckInReminders(isCompletedToday: state.isCompletedToday)
          .catchError((Object _) {}));
    } catch (_) {}
  }

  String _getTodayDateString([DateTime? now]) {
    final d = now ?? DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  TriggerStatus? _parseTriggerStatus(dynamic value) =>
      triggerStatusFromStepAnswer(value);

  Future<void> _loadLocalTodayCheckIn([DateTime? now]) async {
    try {
      final baseUserId = await _storage.getUserId() ?? 'anonymous';
      final userId = _scopedUserId(baseUserId);
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
          final declaredOnRec = declaredStatusOnLog(rec, axis);
          final code = AxisIntensityResolver.categoryCodeFor(rec, axis);
          final status = declaredOnRec ??
              (rec.intensity > 0
                  ? triggerStatusFromIntensity(rec.intensity)
                  : (chkStatus ?? TriggerStatus.goodNormal));
          final intensity = rec.intensity > 0
              ? rec.intensity
              : (declaredOnRec ?? chkStatus)?.defaultIntensity;
          return (
            status: status,
            intensity: intensity,
            completed: true,
            summary: currentSummary ??
                (code != null
                    ? mapCategoryLabel(code)
                    : (isEmotional ? 'Psicoemocional' : 'Registro físico')),
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
    if (_isDisposed) return;
    // Abort only if the active profile changed mid-load; overlapping loads for
    // the same profile are idempotent and must all finish.
    final currentScope = _scopedUserId('');
    await _loadLocalTodayCheckIn(now);
    if (_isDisposed || _scopedUserId('') != currentScope) {
      return;
    }
    await _syncTodayCheckInFromRemote(now);
    if (_isDisposed || _scopedUserId('') != currentScope) {
      return;
    }
    try {
      if (!_isDisposed) {
        await ref
            .read(dailyCheckinNotificationServiceProvider)
            .scheduleDailyCheckInReminders(isCompletedToday: state.isCompletedToday);
      }
    } catch (_) {}
  }

  Future<void> _persistCurrentState() async {
    try {
      final baseUserId = await _storage.getUserId() ?? 'anonymous';
      final userId = _scopedUserId(baseUserId);
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
    final int intensity = status.defaultIntensity;
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
    final int intensity = status.defaultIntensity;
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

  /// [narrative] is the free text the user typed in the triage that produced
  /// [outcome]. Pass it — even as `null` — only when submitting that triage.
  /// Omitting it (replaying a stored or remote outcome) keeps the axis's
  /// current narrative, which the history sync owns.
  void markCompletedWithOutcome(
    TriageOutcome outcome, {
    Object? narrative = _keepNarrative,
  }) {
    // Quick daily check-ins persist intensity 0; axis state lives in stepAnswers.
    if (outcome.intensityScore <= 0) {
      return;
    }

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
      } else if (outcome.secondaryCategoryLabel != null) {
        final secScore = outcome.secondaryIntensityScore ?? outcome.intensityScore;
        physicalIntensity = secScore;
        physicalStatus = triggerStatusFromIntensity(secScore);
      } else {
        physicalIntensity = state.physicalIntensity;
        physicalStatus = state.physicalStatus ?? TriggerStatus.goodNormal;
      }
    }

    final summary = outcome.categoryLabel.isNotEmpty ? outcome.categoryLabel : (isPhysical ? 'Registro físico' : 'Psicoemocional');
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
    _syncCheckInReminders();
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
    _syncCheckInReminders();
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
    _syncCheckInReminders();

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
      ref.read(triageOutcomeProvider.notifier).setOutcomeFromCheckIn(
            id: 'checkin-${DateTime.now().millisecondsSinceEpoch}',
            intensity: intensity,
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
      final baseUserId = await _storage.getUserId() ?? 'anonymous';
      final userId = _scopedUserId(baseUserId);
      await _storage.clearDailyCheckIn(userId);
    } catch (_) {}
  }
}

final triggerCheckInProvider =
    NotifierProvider<TriggerCheckInNotifier, TriggerCheckInState>(
  TriggerCheckInNotifier.new,
);
