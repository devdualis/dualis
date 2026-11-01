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
  /// Bumped on every rebuild (sign-in, sign-out, profile switch). A load or a
  /// save started for the previous user or profile never reaches this state.
  int _generation = 0;
  String? _profileId;
  int _loadSession = 0;
  Future<void>? _pendingLoad;

  /// Number of the newest edit of each day. A save reply is shown only while
  /// its edit is still the newest one of that day.
  final Map<String, int> _latestEdit = {};
  int _editCount = 0;
  int _savesInFlight = 0;

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
    _profileId = ref.watch(
      activeProfileControllerProvider.select((s) => s.activeProfile?.id),
    );
    _generation++;
    _pendingLoad = null;
    _latestEdit.clear();
    _savesInFlight = 0;

    Future.microtask(() => loadData());

    return HabitsState(
      isLoading: true,
      todayHabit: HabitDay(day: todayDayString),
      yesterdayHabit: HabitDay(day: yesterdayDayString),
    );
  }

  HabitsRepository get _repository => ref.read(habitsRepositoryProvider);

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

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
    final generation = _generation;
    final profileId = _profileId;
    final editsBefore = _editCount;
    final session = ++_loadSession;
    state = state.copyWith(isLoading: true);

    try {
      final loaded = await _repository.getHabits(
        days: 60,
        profileId: profileId,
      );
      final trackCycle = await _repository.getTrackMenstrualCycleSetting(
        profileId: profileId,
      );

      if (!_isCurrent(generation) || session != _loadSession) return;

      // A day edited while this load ran keeps its newer answer.
      final editedDays = {
        for (final edit in _latestEdit.entries)
          if (edit.value > editsBefore) edit.key,
      };
      final days = [
        for (final d in loaded)
          if (!editedDays.contains(d.day)) d,
        for (final d in state.recentDays)
          if (editedDays.contains(d.day)) d,
      ]..sort((a, b) => b.day.compareTo(a.day));

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
      if (!_isCurrent(generation) || session != _loadSession) return;
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
    final generation = _generation;
    final profileId = _profileId;
    final edit = ++_editCount;
    _latestEdit[day] = edit;
    _savesInFlight++;
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
      // The repository sends saves one at a time, in tap order.
      final saved = await _repository.saveHabitDay(
        updated,
        profileId: profileId,
      );
      if (!_isCurrent(generation)) return;
      _savesInFlight--;
      // A newer edit of this day is on its way: its reply wins.
      if (_latestEdit[day] == edit) _applyLocalDay(saved);
      state = state.copyWith(isSaving: _savesInFlight > 0);
    } catch (e) {
      if (!_isCurrent(generation)) return;
      _savesInFlight--;
      state = state.copyWith(
        isSaving: _savesInFlight > 0,
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
      await _repository.setTrackMenstrualCycleSetting(
        enabled,
        profileId: _profileId,
      );
    } catch (_) {}
  }

  Future<void> deleteHabit(String day) async {
    final generation = _generation;
    final edit = ++_editCount;
    _latestEdit[day] = edit;
    try {
      await _repository.deleteHabitDay(day, profileId: _profileId);
      if (!_isCurrent(generation) || _latestEdit[day] != edit) return;
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
