import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

class TriageOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientSessionId => text()();
  TextColumn get vertical => text()();
  TextColumn get stepAnswersJson => text()();
  TextColumn get narrative => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get profileId => text().nullable()();
}

class LocalSymptomDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get vertical => text()();
  IntColumn get currentStep => integer().withDefault(const Constant(0))();
  TextColumn get stepAnswersJson => text()();
  TextColumn get narrative => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get profileId => text().nullable()();
}

class WaterIntakeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get userId => text()();
  IntColumn get amountMl => integer()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get profileId => text().nullable()();
}

/// Journal v2 entries saved on the device until they reach the server.
/// [clientId] is the idempotency key sent with the entry.
class JournalOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get profileId => text().nullable()();
}

/// Last known list of the user's own conditions, so the daily entry works
/// offline.
class LocalUserConditions extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get profileId => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id, profileId};
}

@DriftDatabase(tables: [
  TriageOutbox,
  LocalSymptomDrafts,
  WaterIntakeLogs,
  JournalOutbox,
  LocalUserConditions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(waterIntakeLogs);
        }
        if (from < 3) {
          await m.addColumn(waterIntakeLogs, waterIntakeLogs.remoteId);
        }
        if (from < 4) {
          await m.addColumn(triageOutbox, triageOutbox.profileId);
          await m.addColumn(localSymptomDrafts, localSymptomDrafts.profileId);
          await m.addColumn(waterIntakeLogs, waterIntakeLogs.profileId);
        }
        if (from < 5) {
          await m.createTable(journalOutbox);
          await m.createTable(localUserConditions);
        }
      },
    );
  }

  Future<void> wipeAllLocalData() async {
    await delete(triageOutbox).go();
    await delete(localSymptomDrafts).go();
    await delete(waterIntakeLogs).go();
    await delete(journalOutbox).go();
    await delete(localUserConditions).go();
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'dualis_local_db');
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
