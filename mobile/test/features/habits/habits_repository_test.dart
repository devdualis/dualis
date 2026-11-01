import 'package:dio/dio.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/habits/data/habits_remote_data_source.dart';
import 'package:dualis_mobile/features/habits/data/habits_repository.dart';
import 'package:dualis_mobile/features/habits/domain/models/habit_day.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart'
    show homeClockProvider;
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
  final fixedClock = DateTime(2026, 10, 31, 12, 0);

  setUp(() {
    remoteDataSource = MockHabitsRemoteDataSource();
    storage = _MemStorage();
    registerFallbackValue(const HabitDay(day: '2026-10-31'));
    container = ProviderContainer(
      overrides: [
        homeClockProvider.overrideWithValue(() => fixedClock),
        activeProfileControllerProvider.overrideWith(
          () => _TestActiveProfileController(),
        ),
      ],
    );
    repository = HabitsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      storage: storage,
      ref: container.read(_testRefProvider),
      clock: () => fixedClock,
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

      when(
        () => remoteDataSource.getHabits(days: 30),
      ).thenAnswer((_) async => [habit]);

      final list = await repository.getHabits(days: 30);
      expect(list.length, equals(1));
      expect(list.first.day, equals('2026-10-31'));
      expect(list.first.sleepQuality, equals(HabitSleepQuality.bem));

      // Verify cached in storage
      final local = await repository.getHabitForDay('2026-10-31');
      expect(local, isNotNull);
      expect(local!.day, equals('2026-10-31'));
    });

    test(
      'getHabits falls back to local cache when remote returns null',
      () async {
        const habit = HabitDay(
          day: '2026-10-30',
          sleepQuality: HabitSleepQuality.regular,
        );

        // Save locally first with no remote
        when(
          () => remoteDataSource.saveHabitDay(any(), any()),
        ).thenAnswer((_) async => null);

        await repository.saveHabitDay(habit);

        when(
          () => remoteDataSource.getHabits(days: 30),
        ).thenAnswer((_) async => null);

        final list = await repository.getHabits(days: 30);
        expect(list.length, equals(1));
        expect(list.first.day, equals('2026-10-30'));
        expect(list.first.sleepQuality, equals(HabitSleepQuality.regular));
      },
    );

    test(
      'saveHabitDay queues offline when remote returns null, syncPending succeeds',
      () async {
        const habit = HabitDay(
          day: '2026-10-31',
          sleepQuality: HabitSleepQuality.mal,
          sleepHours: HabitSleepHours.menos5,
          moved: true,
          movementMinutes: HabitMovementMinutes.ate15,
        );

        when(
          () => remoteDataSource.saveHabitDay(any(), any()),
        ).thenAnswer((_) async => null);

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
        when(
          () => remoteDataSource.saveHabitDay('2026-10-31', any()),
        ).thenAnswer((_) async => habit);

        await repository.syncPending();

        // Queue should now be empty
        final pendingAfter = await repository.getPendingDays();
        expect(pendingAfter, isEmpty);
        verify(
          () => remoteDataSource.saveHabitDay('2026-10-31', any()),
        ).called(2); // 1 initial + 1 during sync
      },
    );

    test('deleteHabitDay removes locally and from remote', () async {
      const habit = HabitDay(
        day: '2026-10-29',
        sleepQuality: HabitSleepQuality.bem,
      );
      when(
        () => remoteDataSource.saveHabitDay(any(), any()),
      ).thenAnswer((_) async => habit);
      await repository.saveHabitDay(habit);

      when(
        () => remoteDataSource.deleteHabitDay('2026-10-29'),
      ).thenAnswer((_) async => true);

      await repository.deleteHabitDay('2026-10-29');

      final day = await repository.getHabitForDay('2026-10-29');
      expect(day, isNull);

      final pending = await repository.getPendingDays();
      expect(pending.contains('2026-10-29'), isFalse);
    });

    // Orchestrator review note case 1:
    // getHabits must return only days inside the window (day >= local today minus (days-1)), not newest N
    test(
      'getHabits returns only days inside the window (day >= local today minus (days-1)), not newest N',
      () async {
        // today is 2026-10-31. A 30-day window starts at 2026-10-02 (31 - 29).
        final insideDays = [
          const HabitDay(
            day: '2026-10-31',
            sleepQuality: HabitSleepQuality.bem,
          ),
          const HabitDay(
            day: '2026-10-15',
            sleepQuality: HabitSleepQuality.regular,
          ),
          const HabitDay(
            day: '2026-10-02',
            sleepQuality: HabitSleepQuality.bem,
          ),
        ];
        final outsideDays = [
          const HabitDay(
            day: '2026-10-01',
            sleepQuality: HabitSleepQuality.mal,
          ),
          const HabitDay(
            day: '2026-09-15',
            sleepQuality: HabitSleepQuality.mal,
          ),
        ];

        when(
          () => remoteDataSource.getHabits(days: 30),
        ).thenAnswer((_) async => [...insideDays, ...outsideDays]);

        final result = await repository.getHabits(days: 30);

        expect(
          result.map((h) => h.day).toList(),
          equals(['2026-10-31', '2026-10-15', '2026-10-02']),
        );
        expect(result.any((h) => h.day == '2026-10-01'), isFalse);
        expect(result.any((h) => h.day == '2026-09-15'), isFalse);
      },
    );

    // Orchestrator review note case 2:
    // Server is source of truth: rebuild local store from server days plus locally pending days only
    test(
      'rebuilds local store from server days plus locally pending days only (deleted day disappears)',
      () async {
        // Pre-populate local cache with 2 days
        // 1) 2026-10-25 (synced)
        // 2) 2026-10-26 (pending offline change)
        when(
          () => remoteDataSource.saveHabitDay('2026-10-25', any()),
        ).thenAnswer((_) async => const HabitDay(day: '2026-10-25'));
        when(
          () => remoteDataSource.saveHabitDay('2026-10-26', any()),
        ).thenAnswer((_) async => null); // offline

        await repository.saveHabitDay(
          const HabitDay(
            day: '2026-10-25',
            sleepQuality: HabitSleepQuality.bem,
          ),
        );
        await repository.saveHabitDay(
          const HabitDay(
            day: '2026-10-26',
            sleepQuality: HabitSleepQuality.mal,
          ),
        );

        final pending = await repository.getPendingDays();
        expect(pending.contains('2026-10-26'), isTrue);
        expect(pending.contains('2026-10-25'), isFalse);

        // Now server is read. On another device, 2026-10-25 was deleted.
        // Server returns only 2026-10-31 and 2026-10-30.
        when(
          () => remoteDataSource.saveHabitDay('2026-10-26', any()),
        ).thenAnswer((_) async => null); // still offline for 2026-10-26 sync
        when(() => remoteDataSource.getHabits(days: 30)).thenAnswer(
          (_) async => [
            const HabitDay(
              day: '2026-10-31',
              sleepQuality: HabitSleepQuality.bem,
            ),
            const HabitDay(
              day: '2026-10-30',
              sleepQuality: HabitSleepQuality.regular,
            ),
          ],
        );

        final habits = await repository.getHabits(days: 30);

        // 2026-10-25 was deleted on server and not pending locally -> disappeared!
        expect(await repository.getHabitForDay('2026-10-25'), isNull);
        expect(habits.any((h) => h.day == '2026-10-25'), isFalse);

        // 2026-10-26 was pending locally -> retained!
        expect(await repository.getHabitForDay('2026-10-26'), isNotNull);

        // Server days are present
        expect(await repository.getHabitForDay('2026-10-31'), isNotNull);
        expect(await repository.getHabitForDay('2026-10-30'), isNotNull);
      },
    );

    // Orchestrator review note case 3:
    // A 4xx answer from PUT (validation) must not stay pending forever: drop from pending and keep server state
    test(
      'a 4xx answer from PUT drops day from pending and keeps server state',
      () async {
        // 1. Initial state from server
        const serverHabit = HabitDay(
          day: '2026-10-30',
          sleepQuality: HabitSleepQuality.bem,
        );
        when(
          () => remoteDataSource.getHabits(days: 30),
        ).thenAnswer((_) async => [serverHabit]);
        await repository.getHabits(days: 30);

        expect(
          (await repository.getHabitForDay('2026-10-30'))?.sleepQuality,
          equals(HabitSleepQuality.bem),
        );

        // 2. User tries to save an invalid habit that triggers 4xx validation error
        const invalidHabit = HabitDay(
          day: '2026-10-30',
          sleepQuality: HabitSleepQuality.mal,
        );
        when(
          () => remoteDataSource.saveHabitDay('2026-10-30', any()),
        ).thenThrow(HabitClientException(400, 'Invalid parameters'));

        final returned = await repository.saveHabitDay(invalidHabit);

        // 3. Must be dropped from pending (never retried forever)
        final pending = await repository.getPendingDays();
        expect(pending.contains('2026-10-30'), isFalse);

        // 4. Server state is retained
        expect(returned.sleepQuality, equals(HabitSleepQuality.bem));
        final stored = await repository.getHabitForDay('2026-10-30');
        expect(stored?.sleepQuality, equals(HabitSleepQuality.bem));
      },
    );

    test('a 401 or 429 answer keeps the write pending to send again', () async {
      for (final status in [401, 429]) {
        when(
          () => remoteDataSource.saveHabitDay('2026-10-30', any()),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/v1/habits/2026-10-30'),
            response: Response(
              requestOptions: RequestOptions(path: '/v1/habits/2026-10-30'),
              statusCode: status,
            ),
          ),
        );

        final returned = await repository.saveHabitDay(
          const HabitDay(
            day: '2026-10-30',
            sleepQuality: HabitSleepQuality.mal,
          ),
        );

        expect(returned.sleepQuality, equals(HabitSleepQuality.mal));
        expect(
          (await repository.getPendingDays()).contains('2026-10-30'),
          isTrue,
          reason: 'status $status',
        );
      }
    });

    test('syncPending drops 4xx rejected day from pending queue', () async {
      // Save offline first
      when(
        () => remoteDataSource.saveHabitDay('2026-10-30', any()),
      ).thenAnswer((_) async => null);

      await repository.saveHabitDay(
        const HabitDay(day: '2026-10-30', sleepQuality: HabitSleepQuality.mal),
      );

      expect(
        (await repository.getPendingDays()).contains('2026-10-30'),
        isTrue,
      );

      // On sync, server rejects with 422
      when(() => remoteDataSource.saveHabitDay('2026-10-30', any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/habits/2026-10-30'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/habits/2026-10-30'),
            statusCode: 422,
          ),
        ),
      );

      await repository.syncPending();

      // Dropped from pending
      expect(
        (await repository.getPendingDays()).contains('2026-10-30'),
        isFalse,
      );
    });
  });
}
