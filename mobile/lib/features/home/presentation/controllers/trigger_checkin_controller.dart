import 'dart:async';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/daily_checkin_notification_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/data/triage_history_remote_data_source.dart';
import '../../../dashboard/domain/models/triage_history_models.dart';
import '../../../journal/data/journal_local_store.dart';
import '../../../journal/data/journal_remote_data_source.dart';
import '../../../journal/domain/journal_keys.dart';
import '../../../journal/domain/journal_models.dart';
import '../../../journal/presentation/journal_item_text.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../../triage/domain/triage_vertical.dart';
import '../../domain/axis_intensity_resolver.dart';
import '../../domain/trigger_checkin_state.dart';

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

  Future<void> _syncTodayCheckInFromRemote(
    TriageHistoryResponse history, [
    DateTime? now,
  ]) async {
    try {
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
          final status = rec.intensity > 0
              ? triggerStatusFromIntensity(rec.intensity)
              : (chkStatus ?? TriggerStatus.goodNormal);
          final intensity = rec.intensity > 0
              ? rec.intensity
              : chkStatus?.defaultIntensity;
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
      }
    } catch (_) {}
  }

  /// Remote first, like a chat app: the server decides what today looks
  /// like; the device's copy is shown while loading and used only when the
  /// server does not answer. Entries still waiting in the outbox are added
  /// on top, since the server does not have them yet.
  Future<void> loadTodayCheckIn([DateTime? now]) async {
    if (_isDisposed) return;
    // Abort only if the active profile changed mid-load; overlapping loads for
    // the same profile are idempotent and must all finish.
    final currentScope = _scopedUserId('');
    await _loadLocalTodayCheckIn(now);
    if (_isDisposed || _scopedUserId('') != currentScope) {
      return;
    }
    final history = await _historyDataSource.fetchHistory(days: 1);
    final journal = await _fetchTodayJournal(now);
    if (_isDisposed || _scopedUserId('') != currentScope) {
      return;
    }

    final remoteAnswered = !history.failed && journal.remoteOk;
    // Choices made on Home and not saved yet are kept.
    final hasLocalEdits = state.isModifiedAfterCompletion ||
        (!state.isCompletedToday &&
            (state.emotionalTouched ||
                state.physicalTouched ||
                state.textTouched));
    final rebuildFromServer = remoteAnswered && !hasLocalEdits;
    if (rebuildFromServer) {
      state = const TriggerCheckInState();
    }
    if (!history.failed) {
      await _syncTodayCheckInFromRemote(history, now);
    }
    _applyJournalEntries(
      journal.entries,
      historyAt: history.failed ? const {} : _historyAxisTimes(history, now),
    );
    if (rebuildFromServer && !state.isCompletedToday) {
      await _clearStorage();
    }
    if (_isDisposed) return;
    try {
      await ref
          .read(dailyCheckinNotificationServiceProvider)
          .scheduleDailyCheckInReminders(isCompletedToday: state.isCompletedToday);
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

  void completeStage({
    required TriageVertical vertical,
    required String summary,
    String? narrative,
    int? intensity,
    TriggerStatus? status,
    DateTime? at,
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
      completedAt: at ?? DateTime.now(),
      checkInDate: today,
      isModifiedAfterCompletion: false,
    );
    _persistCurrentState();
    _syncCheckInReminders();
  }

  /// Marks Home with a saved journal entry, in the user's own words. Only
  /// the entry's axis is marked; entries without one (older outbox items)
  /// mark both. Conditions get their own line and never fill an axis.
  /// [keepAxes] were answered later elsewhere and keep that newer answer.
  void applyJournalEntry(
    AppLocalizations l10n,
    JournalEntry entry, {
    Set<TriageVertical> keepAxes = const {},
  }) {
    final at = entry.recordedAt;
    final axes = switch (entry.area) {
      JournalKeys.areaEmotional => const [TriageVertical.psicoEmocional],
      JournalKeys.areaPhysical => const [TriageVertical.fisica],
      _ => TriageVertical.values,
    }.where((v) => !keepAxes.contains(v)).toList();
    if (entry.items.isEmpty) {
      final summary = JournalLabels.mood(l10n, entry.mood);
      for (final v in axes) {
        completeStage(
          vertical: v,
          summary: summary,
          status: TriggerStatus.goodNormal,
          intensity: 0,
          at: at,
        );
      }
      return;
    }
    void complete(TriageVertical vertical, Iterable<JournalItem> items) {
      if (items.isEmpty || !axes.contains(vertical)) return;
      completeStage(
        vertical: vertical,
        summary: items.map((i) => journalItemText(l10n, i)).join(' · '),
        narrative: entry.note,
        intensity: items
            .map((i) => i.intensity ?? 0)
            .reduce((a, b) => a > b ? a : b),
        at: at,
      );
    }

    complete(
      TriageVertical.fisica,
      entry.items.where((i) => i.kind == JournalKeys.kindPhysical),
    );
    complete(
      TriageVertical.psicoEmocional,
      entry.items.where((i) => i.kind == JournalKeys.kindEmotional),
    );
    // Good moments of a "Bem" entry (v2.2): done, in the person's words.
    final positive =
        entry.items.where((i) => i.kind == JournalKeys.kindPositive);
    if (positive.isNotEmpty && axes.contains(TriageVertical.psicoEmocional)) {
      completeStage(
        vertical: TriageVertical.psicoEmocional,
        summary: positive.map((i) => journalItemText(l10n, i)).join(' · '),
        status: TriggerStatus.goodNormal,
        intensity: 0,
        at: at,
      );
    }
    // "Bem" with condition readings only (v2.4): the axis is done, as a
    // plain "Bem" is; the readings show with the conditions.
    if (entry.mood == JournalKeys.moodBem &&
        entry.items.every((i) => i.kind == JournalKeys.kindCondition)) {
      final summary = JournalLabels.mood(l10n, entry.mood);
      for (final v in axes) {
        completeStage(
          vertical: v,
          summary: summary,
          status: TriggerStatus.goodNormal,
          intensity: 0,
          at: at,
        );
      }
    }
    final conditions =
        entry.items.where((i) => i.kind == JournalKeys.kindCondition);
    completeConditions(
      conditions.isEmpty
          ? null
          : conditions.map((i) => journalItemText(l10n, i)).join(' · '),
      at: at,
    );
  }

  /// Today's journal entries: the server's list (null-safe: `remoteOk` is
  /// false when it did not answer) plus entries still in the outbox.
  Future<({List<JournalEntry> entries, bool remoteOk})> _fetchTodayJournal([
    DateTime? now,
  ]) async {
    // No session, no journal: nothing to read for anyone.
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        return (entries: const <JournalEntry>[], remoteOk: false);
      }
    } catch (_) {
      return (entries: const <JournalEntry>[], remoteOk: false);
    }
    final profileId =
        ref.read(activeProfileControllerProvider).activeProfile?.id;
    var remoteOk = true;
    var remote = const <JournalEntry>[];
    try {
      remote = await ref
          .read(journalRemoteDataSourceProvider)
          .listEntries(days: 1, profileId: profileId);
    } catch (_) {
      remoteOk = false;
    }
    var pending = const <JournalEntry>[];
    try {
      pending = await ref
          .read(journalLocalStoreProvider)
          .pendingEntries(profileId: profileId);
    } catch (_) {}

    final today = _getTodayDateString(now);
    final byClientId = <String, JournalEntry>{};
    for (final e in [...remote, ...pending]) {
      // Legacy rows come from the triage history sync.
      if (e.legacy) continue;
      if (_getTodayDateString(e.recordedAt) != today) continue;
      byClientId[e.clientId.isEmpty ? (e.id ?? '') : e.clientId] = e;
    }
    final entries = byClientId.values.toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return (entries: entries, remoteOk: remoteOk);
  }

  /// When each axis was last answered in today's triage history. Journal
  /// entries and history records merge by time on each axis.
  Map<TriageVertical, DateTime> _historyAxisTimes(
    TriageHistoryResponse history, [
    DateTime? now,
  ]) {
    final today = _getTodayDateString(now);
    final todayLogs = history.logs
        .where((l) => _getTodayDateString(l.recordedAt.toLocal()) == today)
        .toList();
    final times = <TriageVertical, DateTime>{};
    for (final axis in CheckInAxis.values) {
      final statusKey =
          axis == CheckInAxis.emotional ? 'emotionalStatus' : 'physicalStatus';
      var latest = AxisIntensityResolver.latestRecordFor(axis, todayLogs)
          ?.recordedAt;
      for (final log in todayLogs) {
        if (!AxisIntensityResolver.isDailyCheckIn(log) ||
            _parseTriggerStatus(log.stepAnswers?[statusKey]) == null) {
          continue;
        }
        if (latest == null || log.recordedAt.isAfter(latest)) {
          latest = log.recordedAt;
        }
      }
      if (latest != null) {
        times[axis == CheckInAxis.emotional
            ? TriageVertical.psicoEmocional
            : TriageVertical.fisica] = latest;
      }
    }
    return times;
  }

  /// [historyAt]: when today's triage history last answered each axis. An
  /// entry older than that leaves the axis (and the completion time) alone.
  void _applyJournalEntries(
    List<JournalEntry> entries, {
    Map<TriageVertical, DateTime> historyAt = const {},
  }) {
    if (entries.isEmpty || _isDisposed || state.isModifiedAfterCompletion) {
      return;
    }
    try {
      final l10n = lookupAppLocalizations(ref.read(localeProvider));
      final completedBefore = state.completedAt;
      for (final e in entries) {
        applyJournalEntry(
          l10n,
          e,
          keepAxes: {
            for (final h in historyAt.entries)
              if (h.value.isAfter(e.recordedAt)) h.key,
          },
        );
      }
      final completedAt = state.completedAt;
      if (completedBefore != null &&
          completedAt != null &&
          completedBefore.isAfter(completedAt)) {
        state = state.copyWith(completedAt: completedBefore);
        _persistCurrentState();
      }
    } catch (_) {}
  }

  /// Records today's condition items on their own line of Home, without
  /// touching the emotional or physical axis.
  void completeConditions(String? summary, {DateTime? at}) {
    state = state.copyWith(
      isCompletedToday: (summary != null && summary.isNotEmpty) ||
          state.isCompletedToday,
      conditionsSummary: summary,
      completedAt: at ?? DateTime.now(),
      checkInDate: _getTodayDateString(),
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
