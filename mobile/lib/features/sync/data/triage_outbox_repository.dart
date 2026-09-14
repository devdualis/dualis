import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

final triageOutboxRepositoryProvider = Provider<TriageOutboxRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TriageOutboxRepository(db);
});

class TriageOutboxRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  TriageOutboxRepository(this._db);

  Future<TriageOutboxData> enqueueTriageCheckIn({
    required String vertical,
    required Map<int, String> answers,
    String? narrative,
    String? clientSessionId,
  }) async {
    final sessionId = clientSessionId ?? _uuid.v4();
    final jsonAnswers = jsonEncode(answers.map((k, v) => MapEntry(k.toString(), v)));

    final companion = TriageOutboxCompanion.insert(
      clientSessionId: sessionId,
      vertical: vertical,
      stepAnswersJson: jsonAnswers,
      narrative: Value(narrative),
      status: const Value('pending'),
      attempts: const Value(0),
    );

    final id = await _db.into(_db.triageOutbox).insert(companion);
    return (_db.select(_db.triageOutbox)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<List<TriageOutboxData>> getPendingOutboxItems({int limit = 50}) {
    return (_db.select(_db.triageOutbox)
          ..where((tbl) => tbl.status.equals('pending') | tbl.status.equals('failed'))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc)])
          ..limit(limit))
        .get();
  }

  Future<void> updateOutboxStatus(
    int id,
    String status, {
    String? lastError,
    bool incrementAttempt = false,
  }) async {
    final item = await (_db.select(_db.triageOutbox)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (item == null) return;

    await (_db.update(_db.triageOutbox)..where((tbl) => tbl.id.equals(id))).write(
      TriageOutboxCompanion(
        status: Value(status),
        lastError: Value(lastError),
        attempts: Value(incrementAttempt ? item.attempts + 1 : item.attempts),
      ),
    );
  }

  Future<void> markOutboxItemSynced(int id) {
    return (_db.update(_db.triageOutbox)..where((tbl) => tbl.id.equals(id))).write(
      TriageOutboxCompanion(
        status: const Value('synced'),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<int> getPendingCountStream() {
    final query = _db.selectOnly(_db.triageOutbox)
      ..addColumns([_db.triageOutbox.id.count()])
      ..where(_db.triageOutbox.status.equals('pending') | _db.triageOutbox.status.equals('syncing'));

    return query.map((row) => row.read(_db.triageOutbox.id.count()) ?? 0).watchSingle();
  }
}
