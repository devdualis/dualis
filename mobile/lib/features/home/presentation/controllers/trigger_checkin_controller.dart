import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../dashboard/data/triage_history_remote_data_source.dart';
import '../../../dashboard/domain/models/triage_history_models.dart';
import '../../../triage/data/symptom_classification_remote_data_source.dart';
import '../../../triage/domain/triage_vertical.dart';
import '../../domain/trigger_checkin_state.dart';

final symptomClassificationDataSourceProvider =
    Provider<SymptomClassificationRemoteDataSource>((ref) {
  return SymptomClassificationRemoteDataSource();
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

      TriggerStatus? emotionalStatus;
      TriggerStatus? physicalStatus;
      String naturalLanguageText = state.naturalLanguageText;

      for (final log in todayLogs) {
        final answers = log.stepAnswers;
        if (answers != null && answers['type'] == 'daily_checkin') {
          emotionalStatus ??= _parseTriggerStatus(answers['emotionalStatus']);
          physicalStatus ??= _parseTriggerStatus(answers['physicalStatus']);
          if (answers['naturalLanguageText'] is String &&
              (answers['naturalLanguageText'] as String).isNotEmpty) {
            naturalLanguageText = answers['naturalLanguageText'] as String;
          }
        }
      }

      if (emotionalStatus == null || physicalStatus == null) {
        TriageHistoryEntry? emotionalLog;
        TriageHistoryEntry? physicalLog;

        for (final log in todayLogs) {
          if (log.emotionalDimension != null && emotionalLog == null) {
            emotionalLog = log;
          }
          if (log.anatomicalSystem != null && physicalLog == null) {
            physicalLog = log;
          }
        }

        TriggerStatus intensityToStatus(int intensity) {
          if (intensity <= 2) return TriggerStatus.goodNormal;
          if (intensity == 3) return TriggerStatus.soSo;
          return TriggerStatus.badSick;
        }

        if (emotionalStatus == null) {
          if (emotionalLog != null) {
            emotionalStatus = intensityToStatus(emotionalLog.intensity);
          } else {
            emotionalStatus = TriggerStatus.goodNormal;
          }
        }

        if (physicalStatus == null) {
          if (physicalLog != null) {
            physicalStatus = intensityToStatus(physicalLog.intensity);
          } else {
            physicalStatus = TriggerStatus.goodNormal;
          }
        }
      }

      if (!state.isModifiedAfterCompletion) {
        state = state.copyWith(
          isCompletedToday: true,
          completedAt: latestLog.recordedAt.toLocal(),
          checkInDate: todayStr,
          emotionalStatus: emotionalStatus,
          physicalStatus: physicalStatus,
          naturalLanguageText: naturalLanguageText,
          isModifiedAfterCompletion: false,
          emotionalTouched: false,
          physicalTouched: false,
          textTouched: false,
        );
        await _persistCurrentState();
      }
    } catch (_) {}
  }

  Future<void> loadTodayCheckIn([DateTime? now]) async {
    await _loadLocalTodayCheckIn(now);
    await _syncTodayCheckInFromRemote(now);
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
    state = state.copyWith(
      emotionalStatus: status,
      isModifiedAfterCompletion: modified || state.isModifiedAfterCompletion,
      emotionalTouched: true,
      checkInDate: _getTodayDateString(),
    );
    _persistCurrentState();
  }

  void setPhysicalStatus(TriggerStatus status) {
    final modified = state.isCompletedToday && status != state.physicalStatus;
    state = state.copyWith(
      physicalStatus: status,
      isModifiedAfterCompletion: modified || state.isModifiedAfterCompletion,
      physicalTouched: true,
      checkInDate: _getTodayDateString(),
    );
    _persistCurrentState();
  }

  void setNaturalLanguageText(String text) {
    state = state.copyWith(
      naturalLanguageText: text,
      textTouched: true,
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
      final isDual = state.emotionalStatus != TriggerStatus.goodNormal &&
          state.physicalStatus != TriggerStatus.goodNormal;

      return TriageNavigationArgs(
        initialVertical: vertical,
        isDual: isDual,
        naturalLanguageText: state.naturalLanguageText,
        preselectedCategoryKey: classification.wizardCategoryKey,
      );
    } catch (_) {
      return null;
    }
  }

  void markCompletedToday() {
    final today = _getTodayDateString();
    state = state.copyWith(
      isCompletedToday: true,
      completedAt: DateTime.now(),
      checkInDate: today,
      isModifiedAfterCompletion: false,
      emotionalTouched: false,
      physicalTouched: false,
      textTouched: false,
    );
    _persistCurrentState();
    _syncCheckInToRemote();
  }

  Future<void> _syncCheckInToRemote() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) return;
      final apiClient = ApiClient();
      await apiClient.post(
        ApiEndpoints.dailyCheckIn,
        data: {
          'emotionalStatus': state.emotionalStatus?.name ?? 'goodNormal',
          'physicalStatus': state.physicalStatus?.name ?? 'goodNormal',
          if (state.naturalLanguageText.isNotEmpty)
            'naturalLanguageText': state.naturalLanguageText,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
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
