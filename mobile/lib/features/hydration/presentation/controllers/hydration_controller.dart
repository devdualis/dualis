import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/hydration_notification_service.dart';
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

  Future<void> loadData() async {
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

      state = state.copyWith(
        isLoading: false,
        settings: settings,
        todayLogs: todayLogs,
        todayTotalMl: todayTotal,
        last7DaysTotals: last7Days,
      );

      // Reagendar notificações com as configurações atuais
      if (settings.reminderEnabled) {
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
    await updateSettings(updated);
  }

  Future<void> toggleTracking(bool enabled) async {
    final updated = state.settings.copyWith(trackingEnabled: enabled);
    await updateSettings(updated);
  }

  Future<void> setSoundStyle(ReminderSoundStyle style) async {
    final updated = state.settings.copyWith(reminderSoundStyle: style);
    await updateSettings(updated);
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
