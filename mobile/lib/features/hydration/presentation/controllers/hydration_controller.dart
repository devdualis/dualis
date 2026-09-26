import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/hydration_notification_service.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/hydration_repository.dart';
import '../../domain/models/hydration_settings.dart';
import '../../domain/models/water_intake_log.dart';

class HydrationState {
  final bool isLoading;
  final int todayTotalMl;
  final List<WaterIntakeEntry> todayLogs;
  final Map<DateTime, int> last7DaysTotals;
  final HydrationSettings settings;
  final String? errorMessage;

  const HydrationState({
    this.isLoading = false,
    this.todayTotalMl = 0,
    this.todayLogs = const [],
    this.last7DaysTotals = const {},
    this.settings = const HydrationSettings(),
    this.errorMessage,
  });

  int get dailyTargetMl => settings.dailyTargetMl;

  double get progressRatio =>
      dailyTargetMl > 0 ? (todayTotalMl / dailyTargetMl).clamp(0.0, 1.5) : 0.0;

  int get progressPercent =>
      dailyTargetMl > 0 ? ((todayTotalMl / dailyTargetMl) * 100).round() : 0;

  bool get isGoalReached => todayTotalMl >= dailyTargetMl && dailyTargetMl > 0;

  HydrationState copyWith({
    bool? isLoading,
    int? todayTotalMl,
    List<WaterIntakeEntry>? todayLogs,
    Map<DateTime, int>? last7DaysTotals,
    HydrationSettings? settings,
    String? errorMessage,
  }) {
    return HydrationState(
      isLoading: isLoading ?? this.isLoading,
      todayTotalMl: todayTotalMl ?? this.todayTotalMl,
      todayLogs: todayLogs ?? this.todayLogs,
      last7DaysTotals: last7DaysTotals ?? this.last7DaysTotals,
      settings: settings ?? this.settings,
      errorMessage: errorMessage,
    );
  }
}

class HydrationController extends Notifier<HydrationState> {
  @override
  HydrationState build() {
    // Fresh state per signed-in user: logout (user -> null) resets hydration
    // data instead of leaking the previous user's logs into the next session.
    ref.watch(authControllerProvider.select((auth) => auth.user?.id));
    // Pending reminders carry the language they were scheduled in.
    ref.listen<Locale>(localeProvider, (previous, next) {
      if (previous != next) _rescheduleRemindersForLocale();
    });
    Future.microtask(() => loadData());
    return const HydrationState(isLoading: true);
  }

  HydrationRepository get _repository => ref.read(hydrationRepositoryProvider);
  HydrationNotificationService get _notificationService =>
      ref.read(hydrationNotificationServiceProvider);

  String get _currentUserId {
    final user = ref.read(authControllerProvider).user;
    return user?.id ?? 'guest_user';
  }

  bool get _isSignedIn => ref.read(authControllerProvider).isAuthenticated;

  Future<void> loadData() async {
    final userId = _currentUserId;
    state = state.copyWith(isLoading: true);
    try {
      final settings = await _repository.getSettings();
      final todayLogs = await _repository.getLogsForDay(
        userId: _currentUserId,
        day: DateTime.now(),
      );
      final todayTotal = todayLogs.fold<int>(0, (int sum, WaterIntakeEntry l) => sum + l.amountMl);
      final last7Days = await _repository.getLast7DaysTotals(
        userId: _currentUserId,
      );

      // The signed-in user changed mid-load: that user's own load wins.
      if (_currentUserId != userId) return;

      state = state.copyWith(
        isLoading: false,
        settings: settings,
        todayLogs: todayLogs,
        todayTotalMl: todayTotal,
        last7DaysTotals: last7Days,
      );

      // Reagendar notificações com as configurações atuais (nunca sem sessão:
      // o logout cancela os lembretes e eles não podem voltar sozinhos).
      if (settings.reminderEnabled && _isSignedIn) {
        await _notificationService.scheduleHydrationReminders(settings);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dados de hidratação: $e',
      );
    }
  }

  Future<bool> logWater({
    required int amountMl,
    String source = 'manual',
    DateTime? timestamp,
  }) async {
    if (amountMl <= 0) return false;

    try {
      final newLog = await _repository.logWaterIntake(
        userId: _currentUserId,
        amountMl: amountMl,
        source: source,
        timestamp: timestamp,
      );

      final updatedLogs = [...state.todayLogs, newLog];
      final updatedTotal = state.todayTotalMl + amountMl;

      // Atualiza também o mapa dos últimos 7 dias para refletir imediatamente no gráfico
      final today = DateTime.now();
      final todayKey = DateTime(today.year, today.month, today.day);
      final updatedLast7 = Map<DateTime, int>.from(state.last7DaysTotals);
      updatedLast7[todayKey] = (updatedLast7[todayKey] ?? 0) + amountMl;

      state = state.copyWith(
        todayLogs: updatedLogs,
        todayTotalMl: updatedTotal,
        last7DaysTotals: updatedLast7,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erro ao registrar consumo de água: $e',
      );
      return false;
    }
  }

  Future<void> deleteLog(int id) async {
    try {
      await _repository.deleteLog(id);
      await loadData();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erro ao excluir registro: $e',
      );
    }
  }

  Future<void> updateSettings(HydrationSettings newSettings) async {
    try {
      await _repository.saveSettings(newSettings);
      state = state.copyWith(settings: newSettings);

      if (newSettings.reminderEnabled) {
        await _notificationService.scheduleHydrationReminders(newSettings);
      } else {
        await _notificationService.cancelAllReminders();
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erro ao atualizar configurações: $e',
      );
    }
  }

  Future<void> toggleReminders(bool enabled) async {
    final updated = state.settings.copyWith(reminderEnabled: enabled);
    if (enabled) await _requestExactAlarmsIfMissing();
    await updateSettings(updated);
  }

  Future<void> toggleTracking(bool enabled) async {
    final updated = state.settings.copyWith(trackingEnabled: enabled);
    await updateSettings(updated);
  }

  Future<void> setSoundStyle(ReminderSoundStyle style) async {
    final updated = state.settings.copyWith(reminderSoundStyle: style);
    if (style == ReminderSoundStyle.phoneAlarm && updated.reminderEnabled) {
      await _requestExactAlarmsIfMissing();
    }
    await updateSettings(updated);
  }

  /// Android 12+ denies exact alarms by default, making reminders drift.
  /// Asked only on explicit user actions (enabling reminders / picking the
  /// alarm style) and only when missing — never on every reschedule.
  Future<void> _requestExactAlarmsIfMissing() async {
    try {
      await _notificationService.ensureExactAlarmsPermission();
    } catch (_) {}
  }

  Future<void> _rescheduleRemindersForLocale() async {
    if (state.isLoading || !_isSignedIn || !state.settings.reminderEnabled) {
      return;
    }
    try {
      await _notificationService.scheduleHydrationReminders(state.settings);
    } catch (_) {}
  }

  Future<void> setDailyTarget(int targetMl) async {
    final updated = state.settings.copyWith(dailyTargetMl: targetMl);
    await updateSettings(updated);
  }
}

final hydrationControllerProvider =
    NotifierProvider<HydrationController, HydrationState>(
  HydrationController.new,
);
