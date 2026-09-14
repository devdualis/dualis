import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../domain/trigger_checkin_state.dart';

class TriggerCheckInNotifier extends Notifier<TriggerCheckInState> {
  SecureStorageService get _storage => ref.read(secureStorageServiceProvider);

  @override
  TriggerCheckInState build() {
    _loadTodayCheckIn();
    return const TriggerCheckInState();
  }

  String _getTodayDateString([DateTime? now]) {
    final d = now ?? DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _loadTodayCheckIn() async {
    try {
      final userId = await _storage.getUserId() ?? 'anonymous';
      final saved = await _storage.getDailyCheckIn(userId);
      if (saved == null) return;

      final today = _getTodayDateString();
      final savedDate = saved['checkInDate'] as String?;

      if (savedDate == today) {
        state = TriggerCheckInState.fromJson(saved);
      } else {
        await _storage.clearDailyCheckIn(userId);
        state = const TriggerCheckInState();
      }
    } catch (_) {}
  }

  Future<void> loadTodayCheckIn([DateTime? now]) async {
    try {
      final userId = await _storage.getUserId() ?? 'anonymous';
      final saved = await _storage.getDailyCheckIn(userId);
      final today = _getTodayDateString(now);

      if (saved == null) {
        if (state.checkInDate != null && state.checkInDate != today) {
          state = const TriggerCheckInState();
        }
        return;
      }

      final savedDate = saved['checkInDate'] as String?;
      if (savedDate == today) {
        state = TriggerCheckInState.fromJson(saved);
      } else {
        await _storage.clearDailyCheckIn(userId);
        state = const TriggerCheckInState();
      }
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
    state = state.copyWith(
      emotionalStatus: status,
      isModifiedAfterCompletion: modified || state.isModifiedAfterCompletion,
      checkInDate: _getTodayDateString(),
    );
    _persistCurrentState();
  }

  void setPhysicalStatus(TriggerStatus status) {
    final modified = state.isCompletedToday && status != state.physicalStatus;
    state = state.copyWith(
      physicalStatus: status,
      isModifiedAfterCompletion: modified || state.isModifiedAfterCompletion,
      checkInDate: _getTodayDateString(),
    );
    _persistCurrentState();
  }

  void setNaturalLanguageText(String text) {
    state = state.copyWith(
      naturalLanguageText: text,
      checkInDate: _getTodayDateString(),
    );
    _persistCurrentState();
  }

  void markCompletedToday() {
    final today = _getTodayDateString();
    state = state.copyWith(
      isCompletedToday: true,
      completedAt: DateTime.now(),
      checkInDate: today,
      isModifiedAfterCompletion: false,
    );
    _persistCurrentState();
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
