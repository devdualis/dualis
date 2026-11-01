import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/habits/data/habits_repository.dart';
import 'package:dualis_mobile/features/habits/domain/models/habit_day.dart';
import 'package:dualis_mobile/features/habits/presentation/controllers/habits_controller.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHabitsRepository extends Mock implements HabitsRepository {}

class _MemStorage extends SecureStorageService {
  final Map<String, String> values = {};
  @override
  Future<String?> read({required String key}) async => values[key];
  @override
  Future<void> write({required String key, required String value}) async =>
      values[key] = value;
  @override
  Future<void> delete({required String key}) async => values.remove(key);
}

class _TestActiveProfileController extends ActiveProfileController {
  @override
  ActiveProfileState build() => const ActiveProfileState();
}

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.initial();
}

void main() {
  late MockHabitsRepository repository;
  late _MemStorage storage;
  late ProviderContainer container;
  final fixedClock = DateTime(2026, 10, 31, 12, 0);

  setUp(() {
    repository = MockHabitsRepository();
    storage = _MemStorage();
    registerFallbackValue(const HabitDay(day: '2026-10-31'));

    container = ProviderContainer(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(repository),
        secureStorageServiceProvider.overrideWithValue(storage),
        homeClockProvider.overrideWithValue(() => fixedClock),
        activeProfileControllerProvider.overrideWith(
          () => _TestActiveProfileController(),
        ),
        authControllerProvider.overrideWith(
          () => _TestAuthController(),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('HabitsController', () {
    test('loadData populates todayHabit, yesterdayHabit, and evaluates showPeriodCard',
        () async {
      final days = [
        const HabitDay(
          day: '2026-10-31',
          sleepQuality: HabitSleepQuality.bem,
          sleepHours: HabitSleepHours.hours7To8,
        ),
        const HabitDay(
          day: '2026-10-30',
          moved: true,
          movementMinutes: HabitMovementMinutes.minutes15To30,
        ),
        const HabitDay(
          day: '2026-10-15',
          period: true,
        ),
      ];

      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => days);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.syncPending()).thenAnswer((_) async {});

      final notifier = container.read(habitsControllerProvider.notifier);
      await notifier.loadData();

      final state = container.read(habitsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.todayHabit.sleepQuality, equals(HabitSleepQuality.bem));
      expect(state.yesterdayHabit.moved, isTrue);
      // Has period in last 60 days -> showPeriodCard should be true
      expect(state.hasPeriodInLast60Days, isTrue);
      expect(state.showPeriodCard, isTrue);
    });

    test('todayDayString and yesterdayDayString follow homeClock', () async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.syncPending()).thenAnswer((_) async {});

      final notifier = container.read(habitsControllerProvider.notifier);
      expect(notifier.todayDayString, equals('2026-10-31'));
      expect(notifier.yesterdayDayString, equals('2026-10-30'));
    });

    test('saveAnswer updates state and invokes repository.saveHabitDay', () async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.syncPending()).thenAnswer((_) async {});
      when(() => repository.saveHabitDay(any())).thenAnswer((inv) async =>
          inv.positionalArguments.first as HabitDay);

      final notifier = container.read(habitsControllerProvider.notifier);
      await notifier.loadData();

      await notifier.saveAnswer(
        day: '2026-10-31',
        sleepQuality: HabitSleepQuality.regular,
        sleepHours: HabitSleepHours.hours5To6,
      );

      final state = container.read(habitsControllerProvider);
      expect(state.todayHabit.sleepQuality, equals(HabitSleepQuality.regular));
      expect(state.todayHabit.sleepHours, equals(HabitSleepHours.hours5To6));

      verify(() => repository.saveHabitDay(any(
            that: isA<HabitDay>()
                .having((h) => h.day, 'day', '2026-10-31')
                .having((h) => h.sleepQuality, 'sleepQuality',
                    HabitSleepQuality.regular),
          ))).called(1);
    });

    test('setTrackMenstrualCycle persists preference and updates showPeriodCard',
        () async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.setTrackMenstrualCycleSetting(any()))
          .thenAnswer((_) async {});
      when(() => repository.syncPending()).thenAnswer((_) async {});

      final notifier = container.read(habitsControllerProvider.notifier);
      await notifier.loadData();

      expect(container.read(habitsControllerProvider).trackMenstrualCycle, isFalse);
      expect(container.read(habitsControllerProvider).showPeriodCard, isFalse);

      await notifier.setTrackMenstrualCycle(true);

      final state = container.read(habitsControllerProvider);
      expect(state.trackMenstrualCycle, isTrue);
      expect(state.showPeriodCard, isTrue);

      verify(() => repository.setTrackMenstrualCycleSetting(true)).called(1);
    });
  });
}
