import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/habits/data/habits_remote_data_source.dart';
import 'package:dualis_mobile/features/habits/data/habits_repository.dart';
import 'package:dualis_mobile/features/habits/domain/models/habit_day.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHabitsRemoteDataSource extends Mock
    implements HabitsRemoteDataSource {}

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

final _testRefProvider = Provider((ref) => ref);

void main() {
  late MockHabitsRemoteDataSource remoteDataSource;
  late _MemStorage storage;
  late HabitsRepositoryImpl repository;
  late ProviderContainer container;

  setUp(() {
    remoteDataSource = MockHabitsRemoteDataSource();
    storage = _MemStorage();
    registerFallbackValue(const HabitDay(day: '2026-10-31'));
    container = ProviderContainer(
      overrides: [
        activeProfileControllerProvider.overrideWith(
          () => _TestActiveProfileController(),
        ),
      ],
    );
    repository = HabitsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      storage: storage,
      ref: container.read(_testRefProvider),
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('HabitsRepositoryImpl', () {
    test('getHabits fetches from remote and caches locally', () async {
      const habit = HabitDay(
        day: '2026-10-31',
        sleepQuality: HabitSleepQuality.bem,
      );

      when(() => remoteDataSource.getHabits(days: 30))
          .thenAnswer((_) async => [habit]);

      final list = await repository.getHabits(days: 30);
      expect(list.length, equals(1));
      expect(list.first.day, equals('2026-10-31'));
      expect(list.first.sleepQuality, equals(HabitSleepQuality.bem));

      // Verify cached in storage
      final local = await repository.getHabitForDay('2026-10-31');
      expect(local, isNotNull);
      expect(local!.day, equals('2026-10-31'));
    });

    test('getHabits falls back to local cache when remote returns null', () async {
      const habit = HabitDay(
        day: '2026-10-30',
        sleepQuality: HabitSleepQuality.regular,
      );

      // Save locally first with no remote
      when(() => remoteDataSource.saveHabitDay(any(), any()))
          .thenAnswer((_) async => null);

      await repository.saveHabitDay(habit);

      when(() => remoteDataSource.getHabits(days: 30))
          .thenAnswer((_) async => null);

      final list = await repository.getHabits(days: 30);
      expect(list.length, equals(1));
      expect(list.first.day, equals('2026-10-30'));
      expect(list.first.sleepQuality, equals(HabitSleepQuality.regular));
    });

    test('saveHabitDay queues offline when remote returns null, syncPending succeeds',
        () async {
      const habit = HabitDay(
        day: '2026-10-31',
        sleepQuality: HabitSleepQuality.mal,
        sleepHours: HabitSleepHours.menos5,
        moved: true,
        movementMinutes: HabitMovementMinutes.ate15,
      );

      when(() => remoteDataSource.saveHabitDay(any(), any()))
          .thenAnswer((_) async => null);

      // Save while offline
      await repository.saveHabitDay(habit);

      // Local store should have it
      final day = await repository.getHabitForDay('2026-10-31');
      expect(day, isNotNull);
      expect(day!.sleepQuality, equals(HabitSleepQuality.mal));

      // Pending queue should have '2026-10-31'
      final pendingBefore = await repository.getPendingDays();
      expect(pendingBefore.contains('2026-10-31'), isTrue);

      // Now network is back
      when(() => remoteDataSource.saveHabitDay(
            '2026-10-31',
            any(),
          )).thenAnswer((_) async => habit);

      await repository.syncPending();

      // Queue should now be empty
      final pendingAfter = await repository.getPendingDays();
      expect(pendingAfter, isEmpty);
      verify(() => remoteDataSource.saveHabitDay('2026-10-31', any()))
          .called(2); // 1 initial + 1 during sync
    });

    test('deleteHabitDay removes locally and from remote', () async {
      const habit = HabitDay(
        day: '2026-10-29',
        sleepQuality: HabitSleepQuality.bem,
      );
      when(() => remoteDataSource.saveHabitDay(any(), any()))
          .thenAnswer((_) async => habit);
      await repository.saveHabitDay(habit);

      when(() => remoteDataSource.deleteHabitDay('2026-10-29'))
          .thenAnswer((_) async => true);

      await repository.deleteHabitDay('2026-10-29');

      final day = await repository.getHabitForDay('2026-10-29');
      expect(day, isNull);

      final pending = await repository.getPendingDays();
      expect(pending.contains('2026-10-29'), isFalse);
    });
  });
}
