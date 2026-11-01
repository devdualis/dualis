import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/home_greeting.dart' show homeClockProvider;
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../data/habits_repository.dart';
import '../../domain/models/habit_day.dart';

String formatLocalDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class HabitsState {
  final bool isLoading;
  final bool isSaving;
  final HabitDay todayHabit;
  final HabitDay yesterdayHabit;
  final List<HabitDay> recentDays;
  final bool trackMenstrualCycle;
  final String? errorMessage;

  const HabitsState({
    this.isLoading = false,
    this.isSaving = false,
    required this.todayHabit,
    required this.yesterdayHabit,
    this.recentDays = const [],
    this.trackMenstrualCycle = false,
    this.errorMessage,
  });

  /// The period card is shown only when the person turned on
  /// "Acompanhar ciclo menstrual" or already has a period = true day in the
  /// last 60 days (docs/bienestar/CONTRATO-JOURNAL-V2.md section 6).
  bool get hasPeriodInLast60Days => recentDays.any((d) => d.period == true);

  bool get showPeriodCard => trackMenstrualCycle || hasPeriodInLast60Days;

  /// Counts for the free 30-day window.
  int badSleepCount(int days) {
    final sub = recentDays.take(days);
    return sub.where((d) => d.sleepQuality == HabitSleepQuality.mal).length;
  }

  int movementDaysCount(int days) {
    final sub = recentDays.take(days);
    return sub.where((d) => d.moved == true).length;
  }

  int periodDaysCount(int days) {
    final sub = recentDays.take(days);
    return sub.where((d) => d.period == true).length;
  }

  HabitsState copyWith({
    bool? isLoading,
    bool? isSaving,
    HabitDay? todayHabit,
    HabitDay? yesterdayHabit,
    List<HabitDay>? recentDays,
    bool? trackMenstrualCycle,
    String? errorMessage,
  }) {
    return HabitsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      todayHabit: todayHabit ?? this.todayHabit,
      yesterdayHabit: yesterdayHabit ?? this.yesterdayHabit,
      recentDays: recentDays ?? this.recentDays,
      trackMenstrualCycle: trackMenstrualCycle ?? this.trackMenstrualCycle,
      errorMessage: errorMessage,
    );
  }
}

class HabitsController extends Notifier<HabitsState> {
  int _loadSession = 0;
  Future<void>? _pendingLoad;

  DateTime get _now {
    try {
      return ref.read(homeClockProvider)();
    } catch (_) {
      return DateTime.now();
    }
  }

  String get todayDayString => formatLocalDay(_now);
  String get yesterdayDayString =>
      formatLocalDay(_now.subtract(const Duration(days: 1)));

  @override
  HabitsState build() {
    ref.watch(authControllerProvider.select((auth) => auth.user?.id));
    ref.watch(activeProfileControllerProvider.select((s) => s.activeProfile?.id));

    Future.microtask(() => loadData());

    return HabitsState(
      isLoading: true,
      todayHabit: HabitDay(day: todayDayString),
      yesterdayHabit: HabitDay(day: yesterdayDayString),
    );
  }

  HabitsRepository get _repository => ref.read(habitsRepositoryProvider);

  Future<void> loadData() {
    final existing = _pendingLoad;
    if (existing != null) return existing;
    final future = _performLoadData();
    _pendingLoad = future;
    return future.whenComplete(() {
      if (identical(_pendingLoad, future)) {
        _pendingLoad = null;
      }
    });
  }

  Future<void> _performLoadData() async {
    final session = ++_loadSession;
    state = state.copyWith(isLoading: true);

    try {
      final days = await _repository.getHabits(days: 60);
      final trackCycle = await _repository.getTrackMenstrualCycleSetting();

      if (!ref.mounted || session != _loadSession) return;

      final todayStr = todayDayString;
      final yesterdayStr = yesterdayDayString;

      final today = days.firstWhere(
        (d) => d.day == todayStr,
        orElse: () => HabitDay(day: todayStr),
      );
      final yesterday = days.firstWhere(
        (d) => d.day == yesterdayStr,
        orElse: () => HabitDay(day: yesterdayStr),
      );

      state = state.copyWith(
        isLoading: false,
        todayHabit: today,
        yesterdayHabit: yesterday,
        recentDays: days,
        trackMenstrualCycle: trackCycle,
      );
    } catch (e) {
      if (!ref.mounted || session != _loadSession) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar hábitos: $e',
      );
    }
  }

  Future<void> saveAnswer({
    required String day,
    String? sleepQuality,
    bool clearSleepQuality = false,
    String? sleepHours,
    bool clearSleepHours = false,
    bool? moved,
    bool clearMoved = false,
    String? movementMinutes,
    bool clearMovementMinutes = false,
    bool? period,
    bool clearPeriod = false,
  }) async {
    state = state.copyWith(isSaving: true);

    final current = day == todayDayString
        ? state.todayHabit
        : (day == yesterdayDayString
            ? state.yesterdayHabit
            : state.recentDays.firstWhere(
                (d) => d.day == day,
                orElse: () => HabitDay(day: day),
              ));

    final updated = current.copyWith(
      day: day,
      sleepQuality: sleepQuality,
      clearSleepQuality: clearSleepQuality,
      sleepHours: sleepHours,
      clearSleepHours: clearSleepHours,
      moved: moved,
      clearMoved: clearMoved,
      movementMinutes: movementMinutes,
      clearMovementMinutes: clearMovementMinutes,
      period: period,
      clearPeriod: clearPeriod,
    );

    // Save optimistically to state
    _applyLocalDay(updated);

    try {
      final saved = await _repository.saveHabitDay(updated);
      _applyLocalDay(saved);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Erro ao salvar hábito: $e',
      );
    }
  }

  void _applyLocalDay(HabitDay saved) {
    final list = List<HabitDay>.from(state.recentDays);
    final idx = list.indexWhere((d) => d.day == saved.day);
    if (idx >= 0) {
      list[idx] = saved;
    } else {
      list.insert(0, saved);
      list.sort((a, b) => b.day.compareTo(a.day));
    }

    state = state.copyWith(
      todayHabit: saved.day == todayDayString ? saved : state.todayHabit,
      yesterdayHabit: saved.day == yesterdayDayString ? saved : state.yesterdayHabit,
      recentDays: list,
    );
  }

  Future<void> setTrackMenstrualCycle(bool enabled) async {
    ++_loadSession;
    state = state.copyWith(trackMenstrualCycle: enabled);
    try {
      await _repository.setTrackMenstrualCycleSetting(enabled);
    } catch (_) {}
  }

  Future<void> deleteHabit(String day) async {
    try {
      await _repository.deleteHabitDay(day);
      final emptyDay = HabitDay(day: day);
      final list = state.recentDays.where((d) => d.day != day).toList();
      state = state.copyWith(
        todayHabit: day == todayDayString ? emptyDay : state.todayHabit,
        yesterdayHabit: day == yesterdayDayString ? emptyDay : state.yesterdayHabit,
        recentDays: list,
      );
    } catch (_) {}
  }
}

final habitsControllerProvider =
    NotifierProvider<HabitsController, HabitsState>(() {
  return HabitsController();
});
