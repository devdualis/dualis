import 'dart:async';

import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/habits/data/habits_repository.dart';
import 'package:dualis_mobile/features/habits/domain/models/habit_day.dart';
import 'package:dualis_mobile/features/habits/presentation/controllers/habits_controller.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
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

Profile _profile(String id) => Profile(
      id: id,
      name: id,
      profileType: ProfileType.primary,
      ownership: ProfileOwnership.own,
      accessLevel: ProfileAccessLevel.owner,
    );

/// Starts on profile A; [switchTo] changes the active profile like the
/// profile picker does.
class _SwitchableProfileController extends ActiveProfileController {
  @override
  ActiveProfileState build() => ActiveProfileState(
        profiles: [_profile('profile-a'), _profile('profile-b')],
        activeProfileId: 'profile-a',
      );

  void switchTo(String id) => state = state.copyWith(activeProfileId: id);
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
      test('a load still running for the previous profile is dropped on a switch',
        () async {
      final profiles = ProviderContainer(
        overrides: [
          habitsRepositoryProvider.overrideWithValue(repository),
          secureStorageServiceProvider.overrideWithValue(storage),
          homeClockProvider.overrideWithValue(() => fixedClock),
          activeProfileControllerProvider.overrideWith(
            _SwitchableProfileController.new,
          ),
          authControllerProvider.overrideWith(() => _TestAuthController()),
        ],
      );
      addTearDown(profiles.dispose);
      final profileALoad = Completer<List<HabitDay>>();
      when(() => repository.getHabits(days: 60, profileId: 'profile-a'))
          .thenAnswer((_) => profileALoad.future);
      when(() => repository.getHabits(days: 60, profileId: 'profile-b'))
          .thenAnswer((_) async => [
                const HabitDay(day: '2026-10-31', moved: false),
              ]);
      when(
        () => repository.getTrackMenstrualCycleSetting(
          profileId: any(named: 'profileId'),
        ),
      ).thenAnswer((_) async => false);

      profiles.listen(habitsControllerProvider, (_, __) {});
      await Future<void>.delayed(Duration.zero); // A's load starts

      (profiles.read(activeProfileControllerProvider.notifier)
              as _SwitchableProfileController)
          .switchTo('profile-b');
      await Future<void>.delayed(Duration.zero); // B's load runs
      profileALoad.complete([const HabitDay(day: '2026-10-31', moved: true)]);
      await Future<void>.delayed(Duration.zero);

      final state = profiles.read(habitsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.todayHabit.moved, isFalse, reason: "B's answer, not A's");
      verify(() => repository.getHabits(days: 60, profileId: 'profile-b'))
          .called(1);
    });

    test('a slow reply to an older tap does not undo the newer answer',
        () async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      final olderReply = Completer<HabitDay>();
      var calls = 0;
      when(() => repository.saveHabitDay(any())).thenAnswer((inv) {
        calls++;
        return calls == 1
            ? olderReply.future
            : Future.value(inv.positionalArguments.first as HabitDay);
      });

      final notifier = container.read(habitsControllerProvider.notifier);
      await notifier.loadData();

      final older = notifier.saveAnswer(
        day: '2026-10-31',
        sleepQuality: HabitSleepQuality.bem,
      );
      await notifier.saveAnswer(
        day: '2026-10-31',
        sleepQuality: HabitSleepQuality.mal,
      );
      olderReply.complete(
        const HabitDay(day: '2026-10-31', sleepQuality: HabitSleepQuality.bem),
      );
      await older;

      final state = container.read(habitsControllerProvider);
      expect(state.todayHabit.sleepQuality, HabitSleepQuality.mal);
      expect(state.isSaving, isFalse);
    });

    test('an answer given while a load runs survives that load', () async {
      final load = Completer<List<HabitDay>>();
      when(() => repository.getHabits(days: 60)).thenAnswer((_) => load.future);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.saveHabitDay(any())).thenAnswer(
        (inv) async => inv.positionalArguments.first as HabitDay,
      );

      final notifier = container.read(habitsControllerProvider.notifier);
      final loading = notifier.loadData();
      await notifier.saveAnswer(
        day: '2026-10-31',
        sleepQuality: HabitSleepQuality.mal,
      );
      // The load read the day before the tap.
      load.complete([
        const HabitDay(day: '2026-10-31', sleepQuality: HabitSleepQuality.bem),
        const HabitDay(day: '2026-10-30', moved: true),
      ]);
      await loading;

      final state = container.read(habitsControllerProvider);
      expect(state.todayHabit.sleepQuality, HabitSleepQuality.mal);
      expect(state.yesterdayHabit.moved, isTrue);
    });
  });

  group('HabitsController failures', () {
    test('a failed load keeps the error until a retry succeeds', () async {
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.getHabits(days: 60))
          .thenThrow(Exception('SocketException'));

      final notifier = container.read(habitsControllerProvider.notifier);
      await notifier.loadData();
      var state = container.read(habitsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.loadError, isNotNull);

      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      await notifier.loadData();
      state = container.read(habitsControllerProvider);
      expect(state.loadError, isNull);
    });

    test('a failed save puts the previous answer back and reports it', () async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => [
            const HabitDay(day: '2026-10-31', sleepQuality: HabitSleepQuality.bem),
          ]);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.saveHabitDay(any())).thenThrow(Exception('500'));

      final notifier = container.read(habitsControllerProvider.notifier);
      await notifier.loadData();
      await notifier.saveAnswer(day: '2026-10-31', sleepQuality: HabitSleepQuality.mal);

      final state = container.read(habitsControllerProvider);
      expect(state.todayHabit.sleepQuality, HabitSleepQuality.bem);
      expect(state.saveError, isNotNull);
      expect(state.isSaving, isFalse);
    });

    test('a failed cycle setting goes back to the previous value', () async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.setTrackMenstrualCycleSetting(true))
          .thenThrow(Exception('500'));

      final notifier = container.read(habitsControllerProvider.notifier);
      await notifier.loadData();
      await notifier.setTrackMenstrualCycle(true);

      final state = container.read(habitsControllerProvider);
      expect(state.trackMenstrualCycle, isFalse);
      expect(state.saveError, isNotNull);
    });
  });
}
