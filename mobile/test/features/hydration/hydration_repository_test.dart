import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/hydration/data/hydration_remote_data_source.dart';
import 'package:dualis_mobile/features/hydration/data/hydration_repository.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/hydration/domain/models/water_intake_log.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockHydrationRemoteDataSource extends Mock implements HydrationRemoteDataSource {}

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
  final ActiveProfileState _testState;
  _TestActiveProfileController(this._testState);
  @override
  ActiveProfileState build() => _testState;
}

void main() {
  late AppDatabase db;
  late MockSecureStorageService storage;
  late MockHydrationRemoteDataSource remoteDataSource;
  late HydrationRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    storage = MockSecureStorageService();
    remoteDataSource = MockHydrationRemoteDataSource();
    repository = HydrationRepositoryImpl(
      db: db,
      storage: storage,
      remoteDataSource: remoteDataSource,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('HydrationRepositoryImpl DB operations', () {
    test('inserts and retrieves water intake log for user today and calls remote', () async {
      const userId = 'user-123';
      final now = DateTime.now();

      when(() => remoteDataSource.logWater(
            amountMl: 250,
            source: 'manual',
            timestamp: now,
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => WaterIntakeEntry(
            remoteId: 'remote-uuid-1',
            userId: userId,
            amountMl: 250,
            timestamp: now,
            source: 'manual',
          ));

      final entry = await repository.logWaterIntake(
        userId: userId,
        amountMl: 250,
        source: 'manual',
        timestamp: now,
      );

      expect(entry.id, isPositive);
      expect(entry.remoteId, equals('remote-uuid-1'));
      expect(entry.userId, equals(userId));
      expect(entry.amountMl, equals(250));

      verify(() => remoteDataSource.logWater(
            amountMl: 250,
            source: 'manual',
            timestamp: now,
            clientId: any(named: 'clientId'),
          )).called(1);

      when(() => remoteDataSource.getTodayLogs(date: any(named: 'date')))
          .thenAnswer((_) async => null);

      final logs = await repository.getLogsForDay(userId: userId, day: now);
      expect(logs.length, equals(1));
      expect(logs.first.amountMl, equals(250));

      final todayTotal = await repository.getTodayTotalMl(userId: userId);
      expect(todayTotal, equals(250));
    });

    test('isolates logs between different users', () async {
      final now = DateTime.now();
      when(() => remoteDataSource.logWater(
            amountMl: any(named: 'amountMl'),
            source: any(named: 'source'),
            timestamp: any(named: 'timestamp'),
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => null);
      when(() => remoteDataSource.getTodayLogs(date: any(named: 'date')))
          .thenAnswer((_) async => null);

      await repository.logWaterIntake(
        userId: 'user-A',
        amountMl: 300,
        timestamp: now,
      );
      await repository.logWaterIntake(
        userId: 'user-B',
        amountMl: 500,
        timestamp: now,
      );

      final logsA = await repository.getLogsForDay(userId: 'user-A', day: now);
      final logsB = await repository.getLogsForDay(userId: 'user-B', day: now);

      expect(logsA.length, equals(1));
      expect(logsA.first.amountMl, equals(300));
      expect(logsB.length, equals(1));
      expect(logsB.first.amountMl, equals(500));
    });

    test('getDailyTotals includes all 30 days with correct sums', () async {
      const userId = 'user-123';
      final now = DateTime.now();

      when(() => remoteDataSource.logWater(
            amountMl: any(named: 'amountMl'),
            source: any(named: 'source'),
            timestamp: any(named: 'timestamp'),
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => null);
      when(() => remoteDataSource.getHistoryTotals(
            days: 30,
            referenceDate: any(named: 'referenceDate'),
          )).thenAnswer((_) async => null);
      when(() => remoteDataSource.getTodayLogs(date: any(named: 'date')))
          .thenAnswer((_) async => null);

      await repository.logWaterIntake(
        userId: userId,
        amountMl: 250,
        timestamp: now,
      );
      await repository.logWaterIntake(
        userId: userId,
        amountMl: 500,
        timestamp: now,
      );

      final totals = await repository.getDailyTotals(userId: userId, referenceDate: now);
      expect(totals.length, equals(30));

      final todayKey = DateTime(now.year, now.month, now.day);
      expect(totals[todayKey], equals(750));
    });

    test('deletes log locally and remotely', () async {
      const userId = 'user-123';
      final now = DateTime.now();

      when(() => remoteDataSource.logWater(
            amountMl: any(named: 'amountMl'),
            source: any(named: 'source'),
            timestamp: any(named: 'timestamp'),
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => null);
      when(() => remoteDataSource.deleteLog('rem-123')).thenAnswer((_) async => true);

      final entry = await repository.logWaterIntake(
        userId: userId,
        amountMl: 250,
        timestamp: now,
      );

      await repository.deleteLog(entry.id!);
      await repository.deleteRemoteLog('rem-123');

      verify(() => remoteDataSource.deleteLog('rem-123')).called(1);
    });

    test('deleting via deleteRemoteLog removes from local Drift database as well', () async {
      const userId = 'user-123';
      final now = DateTime.now();

      when(() => remoteDataSource.logWater(
            amountMl: any(named: 'amountMl'),
            source: any(named: 'source'),
            timestamp: any(named: 'timestamp'),
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => WaterIntakeEntry(
            remoteId: 'uuid-to-delete',
            userId: userId,
            amountMl: 300,
            timestamp: now,
          ));
      when(() => remoteDataSource.deleteLog('uuid-to-delete')).thenAnswer((_) async => true);
      when(() => remoteDataSource.getTodayLogs(date: any(named: 'date'))).thenAnswer((_) async => null);

      final entry = await repository.logWaterIntake(
        userId: userId,
        amountMl: 300,
        timestamp: now,
      );
      expect(entry.remoteId, equals('uuid-to-delete'));

      // Delete by remoteId only
      await repository.deleteRemoteLog('uuid-to-delete');

      final logs = await repository.getLogsForDay(userId: userId, day: now);
      expect(logs, isEmpty);
      verify(() => remoteDataSource.deleteLog('uuid-to-delete')).called(1);
    });

    test('reconciles deletions when server returns empty remote logs list', () async {
      const userId = 'user-123';
      final now = DateTime.now();

      when(() => remoteDataSource.logWater(
            amountMl: any(named: 'amountMl'),
            source: any(named: 'source'),
            timestamp: any(named: 'timestamp'),
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => WaterIntakeEntry(
            remoteId: 'uuid-server-1',
            userId: userId,
            amountMl: 500,
            timestamp: now,
          ));

      await repository.logWaterIntake(
        userId: userId,
        amountMl: 500,
        timestamp: now,
      );

      // Now server says 0 logs (deleted elsewhere or through API)
      when(() => remoteDataSource.getTodayLogs(date: any(named: 'date')))
          .thenAnswer((_) async => <WaterIntakeEntry>[]);

      final logsAfterServerEmpty = await repository.getLogsForDay(userId: userId, day: now);
      expect(logsAfterServerEmpty, isEmpty);
    });

    test('filters local logs by active profile: primary includes legacy nulls, non-primary is isolated', () async {
      const userId = 'user-123';
      final now = DateTime.now();

      when(() => remoteDataSource.logWater(
            amountMl: any(named: 'amountMl'),
            source: any(named: 'source'),
            timestamp: any(named: 'timestamp'),
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => null);
      when(() => remoteDataSource.getTodayLogs(date: any(named: 'date')))
          .thenAnswer((_) async => null);

      await db.into(db.waterIntakeLogs).insert(
            WaterIntakeLogsCompanion.insert(
              userId: userId,
              amountMl: 200,
            ),
          );

      const primaryProfile = Profile(
        id: 'prof-primary-1',
        name: 'Primary User',
        profileType: ProfileType.primary,
        ownership: ProfileOwnership.own,
        accessLevel: ProfileAccessLevel.owner,
      );

      const childProfile = Profile(
        id: 'prof-child-2',
        name: 'Child User',
        profileType: ProfileType.dependentMinor,
        ownership: ProfileOwnership.dependent,
        accessLevel: ProfileAccessLevel.owner,
      );

      final containerPrimary = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          secureStorageServiceProvider.overrideWithValue(storage),
          hydrationRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
          activeProfileControllerProvider.overrideWith(
            () => _TestActiveProfileController(
              const ActiveProfileState(
                profiles: [primaryProfile, childProfile],
                activeProfileId: 'prof-primary-1',
              ),
            ),
          ),
        ],
      );
      addTearDown(containerPrimary.dispose);

      final primaryRepo = containerPrimary.read(hydrationRepositoryProvider);

      await primaryRepo.logWaterIntake(userId: userId, amountMl: 300, timestamp: now);

      final primaryTotal = await primaryRepo.getTodayTotalMl(userId: userId);
      expect(primaryTotal, equals(500));

      final containerChild = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          secureStorageServiceProvider.overrideWithValue(storage),
          hydrationRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
          activeProfileControllerProvider.overrideWith(
            () => _TestActiveProfileController(
              const ActiveProfileState(
                profiles: [primaryProfile, childProfile],
                activeProfileId: 'prof-child-2',
              ),
            ),
          ),
        ],
      );
      addTearDown(containerChild.dispose);

      final childRepo = containerChild.read(hydrationRepositoryProvider);

      final childTotalBefore = await childRepo.getTodayTotalMl(userId: userId);
      expect(childTotalBefore, equals(0));

      await childRepo.logWaterIntake(userId: userId, amountMl: 150, timestamp: now);

      final childTotalAfter = await childRepo.getTodayTotalMl(userId: userId);
      expect(childTotalAfter, equals(150));

      final primaryTotalAfter = await primaryRepo.getTodayTotalMl(userId: userId);
      expect(primaryTotalAfter, equals(500));
    });
      test('re-login: server logs are not counted twice across profile loads', () async {
      const userId = 'user-123';
      final now = DateTime.now();
      when(() => remoteDataSource.getTodayLogs(
            date: any(named: 'date'),
            profileId: any(named: 'profileId'),
          )).thenAnswer((_) async => [
            WaterIntakeEntry(
              remoteId: 'r1',
              userId: userId,
              amountMl: 500,
              timestamp: now,
              source: 'manual',
            ),
          ]);
      // Logged before logout, with the profile known.
      await db.into(db.waterIntakeLogs).insert(WaterIntakeLogsCompanion.insert(
            userId: userId,
            amountMl: 500,
            remoteId: const Value('r1'),
            timestamp: Value(now),
            profileId: const Value('prof-primary-1'),
          ));
      // Duplicate left by the old code (load before the profile was known).
      await db.into(db.waterIntakeLogs).insert(WaterIntakeLogsCompanion.insert(
            userId: userId,
            amountMl: 500,
            remoteId: const Value('r1'),
            timestamp: Value(now),
          ));

      const primary = Profile(
        id: 'prof-primary-1',
        name: 'Primary User',
        profileType: ProfileType.primary,
        ownership: ProfileOwnership.own,
        accessLevel: ProfileAccessLevel.owner,
      );
      Future<int> totalWith(ActiveProfileState s) async {
        final c = ProviderContainer(overrides: [
          appDatabaseProvider.overrideWithValue(db),
          secureStorageServiceProvider.overrideWithValue(storage),
          hydrationRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
          activeProfileControllerProvider
              .overrideWith(() => _TestActiveProfileController(s)),
        ]);
        addTearDown(c.dispose);
        return c.read(hydrationRepositoryProvider).getTodayTotalMl(userId: userId);
      }

      expect(await totalWith(const ActiveProfileState(isLoading: true)), 500);
      expect(
        await totalWith(const ActiveProfileState(
          profiles: [primary],
          activeProfileId: 'prof-primary-1',
        )),
        500,
      );
      final rows = await db.select(db.waterIntakeLogs).get();
      expect(rows, hasLength(1));
      expect(rows.single.profileId, 'prof-primary-1');
    });
  });

  group('Hydration settings: server first', () {
    late _MemStorage mem;
    late HydrationRepositoryImpl repo;
    const local = HydrationSettings(dailyTargetMl: 1800, reminderEnabled: true);
    const server = HydrationSettings(dailyTargetMl: 2600, reminderEnabled: false);

    setUpAll(() => registerFallbackValue(const HydrationSettings()));

    setUp(() {
      mem = _MemStorage();
      repo = HydrationRepositoryImpl(
        db: db,
        storage: mem,
        remoteDataSource: remoteDataSource,
      );
    });

    test('the server copy wins and is cached on the device', () async {
      await mem.write(
        key: SecureStorageService.keyHydrationSettings,
        value: '{"dailyTargetMl":1800}',
      );
      when(() => remoteDataSource.getSettings())
          .thenAnswer((_) async => (answered: true, settings: server));

      final got = await repo.getSettings();

      expect(got.dailyTargetMl, 2600);
      expect(got.reminderEnabled, isFalse);
      expect(mem.values[SecureStorageService.keyHydrationSettings], contains('2600'));
    });

    test('offline: the device copy is used', () async {
      when(() => remoteDataSource.getSettings())
          .thenAnswer((_) async => (answered: false, settings: null));
      when(() => remoteDataSource.saveSettings(any()))
          .thenAnswer((_) async => false);
      await repo.saveSettings(local);

      expect((await repo.getSettings()).dailyTargetMl, 1800);
    });

    test('a change saved offline is sent before the server is read', () async {
      when(() => remoteDataSource.saveSettings(any()))
          .thenAnswer((_) async => false);
      await repo.saveSettings(local);
      expect(mem.values[SecureStorageService.keyHydrationSettingsPending], '1');

      when(() => remoteDataSource.saveSettings(any()))
          .thenAnswer((_) async => true);
      when(() => remoteDataSource.getSettings())
          .thenAnswer((_) async => (answered: true, settings: server));

      expect((await repo.getSettings()).dailyTargetMl, 1800);
      verify(() => remoteDataSource.saveSettings(any())).called(2);
      expect(mem.values.containsKey(SecureStorageService.keyHydrationSettingsPending), isFalse);
    });
  });

  test('water logged offline is sent to the server on the next load', () async {
    const userId = 'user-123';
    final now = DateTime.now();
    await db.into(db.waterIntakeLogs).insert(WaterIntakeLogsCompanion.insert(
          userId: userId,
          amountMl: 300,
          timestamp: Value(now),
        ));
    when(() => remoteDataSource.logWater(
          amountMl: 300,
          source: any(named: 'source'),
          timestamp: any(named: 'timestamp'),
          profileId: any(named: 'profileId'),
          clientId: any(named: 'clientId'),
        )).thenAnswer((_) async => WaterIntakeEntry(
          remoteId: 'r-up',
          userId: userId,
          amountMl: 300,
          timestamp: now,
          source: 'manual',
        ));
    when(() => remoteDataSource.getTodayLogs(
          date: any(named: 'date'),
          profileId: any(named: 'profileId'),
        )).thenAnswer((_) async => [
          WaterIntakeEntry(
            remoteId: 'r-up',
            userId: userId,
            amountMl: 300,
            timestamp: now,
            source: 'manual',
          ),
        ]);

    final logs = await repository.getLogsForDay(userId: userId, day: now);

    expect(logs, hasLength(1));
    expect(logs.single.remoteId, 'r-up');
  });

  group('a lost answer never counts the same water twice', () {
    const userId = 'user-123';

    WaterIntakeEntry serverLog(String id, DateTime at) => WaterIntakeEntry(
          remoteId: id,
          userId: userId,
          amountMl: 300,
          timestamp: at,
          source: 'manual',
        );

    test('the retry sends the same client id and the server log is kept once',
        () async {
      final now = DateTime.now();
      final sentIds = <String?>[];
      var serverSaved = false;
      when(() => remoteDataSource.logWater(
            amountMl: any(named: 'amountMl'),
            source: any(named: 'source'),
            timestamp: any(named: 'timestamp'),
            profileId: any(named: 'profileId'),
            clientId: any(named: 'clientId'),
          )).thenAnswer((inv) async {
        final id = inv.namedArguments[#clientId] as String?;
        sentIds.add(id);
        // The first try is saved on the server, but its answer is lost.
        if (!serverSaved) {
          serverSaved = true;
          return null;
        }
        return serverLog(id!, now);
      });

      await repository.logWaterIntake(userId: userId, amountMl: 300, timestamp: now);
      when(() => remoteDataSource.getTodayLogs(
            date: any(named: 'date'),
            profileId: any(named: 'profileId'),
          )).thenAnswer((_) async => [serverLog(sentIds.first!, now)]);

      final logs = await repository.getLogsForDay(userId: userId, day: now);

      expect(sentIds, hasLength(2));
      expect(sentIds.first, isNotNull);
      expect(sentIds.last, sentIds.first);
      expect(logs, hasLength(1));
      expect(logs.single.remoteId, sentIds.first);
      expect(await repository.getTodayTotalMl(userId: userId), 300);
    });

    test('a server log under a waiting row\'s client id is that row, not a new one',
        () async {
      final now = DateTime.now();
      String? clientId;
      when(() => remoteDataSource.logWater(
            amountMl: any(named: 'amountMl'),
            source: any(named: 'source'),
            timestamp: any(named: 'timestamp'),
            profileId: any(named: 'profileId'),
            clientId: any(named: 'clientId'),
          )).thenAnswer((inv) async {
        clientId ??= inv.namedArguments[#clientId] as String?;
        return null; // every answer is lost
      });
      await repository.logWaterIntake(userId: userId, amountMl: 300, timestamp: now);
      when(() => remoteDataSource.getTodayLogs(
            date: any(named: 'date'),
            profileId: any(named: 'profileId'),
          )).thenAnswer((_) async => [serverLog(clientId!, now)]);

      final logs = await repository.getLogsForDay(userId: userId, day: now);

      expect(logs, hasLength(1));
      expect(logs.single.remoteId, clientId);
      final rows = await db.select(db.waterIntakeLogs).get();
      expect(rows, hasLength(1));
      expect(rows.single.remoteId, clientId);
    });

    test('a log saved before client ids existed gets one and keeps it', () async {
      final now = DateTime.now();
      await db.into(db.waterIntakeLogs).insert(WaterIntakeLogsCompanion.insert(
            userId: userId,
            amountMl: 300,
            timestamp: Value(now),
          ));
      final sentIds = <String?>[];
      when(() => remoteDataSource.logWater(
            amountMl: any(named: 'amountMl'),
            source: any(named: 'source'),
            timestamp: any(named: 'timestamp'),
            profileId: any(named: 'profileId'),
            clientId: any(named: 'clientId'),
          )).thenAnswer((inv) async {
        sentIds.add(inv.namedArguments[#clientId] as String?);
        return null;
      });
      when(() => remoteDataSource.getTodayLogs(
            date: any(named: 'date'),
            profileId: any(named: 'profileId'),
          )).thenAnswer((_) async => null);

      await repository.getLogsForDay(userId: userId, day: now);
      await repository.getLogsForDay(userId: userId, day: now);

      final row = await db.select(db.waterIntakeLogs).getSingle();
      expect(row.clientId, isNotNull);
      expect(sentIds, [row.clientId, row.clientId]);
    });
  });
}
