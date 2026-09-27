import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/hydration/data/hydration_remote_data_source.dart';
import 'package:dualis_mobile/features/hydration/data/hydration_repository.dart';
import 'package:dualis_mobile/features/hydration/domain/models/water_intake_log.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockHydrationRemoteDataSource extends Mock implements HydrationRemoteDataSource {}

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

    test('getLast7DaysTotals includes all 7 days with correct sums', () async {
      const userId = 'user-123';
      final now = DateTime.now();

      when(() => remoteDataSource.logWater(
            amountMl: any(named: 'amountMl'),
            source: any(named: 'source'),
            timestamp: any(named: 'timestamp'),
          )).thenAnswer((_) async => null);
      when(() => remoteDataSource.getHistoryTotals(
            days: 7,
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

      final totals = await repository.getLast7DaysTotals(userId: userId, referenceDate: now);
      expect(totals.length, equals(7));

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
  });
}
