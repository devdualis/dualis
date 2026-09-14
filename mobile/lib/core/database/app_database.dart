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
}

class LocalSymptomDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get vertical => text()();
  IntColumn get currentStep => integer().withDefault(const Constant(0))();
  TextColumn get stepAnswersJson => text()();
  TextColumn get narrative => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [TriageOutbox, LocalSymptomDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> wipeAllLocalData() async {
    await delete(triageOutbox).go();
    await delete(localSymptomDrafts).go();
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
