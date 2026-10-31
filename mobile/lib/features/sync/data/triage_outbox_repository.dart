import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../profile/presentation/controllers/active_profile_controller.dart';

final triageOutboxRepositoryProvider = Provider<TriageOutboxRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TriageOutboxRepository(db, ref: ref);
});

class TriageOutboxRepository {
  final AppDatabase _db;
  final Ref? _ref;
  final Uuid _uuid = const Uuid();

  TriageOutboxRepository(this._db, {Ref? ref}) : _ref = ref;

  Future<TriageOutboxData> enqueueTriageCheckIn({
    required String vertical,
    required Map<int, String> answers,
    String? narrative,
    String? clientSessionId,
    String? profileId,
  }) async {
    final effectiveProfileId = profileId ??
        _ref?.read(activeProfileControllerProvider).activeProfile?.id;
    final sessionId = clientSessionId ?? _uuid.v4();
    final jsonAnswers = jsonEncode(answers.map((k, v) => MapEntry(k.toString(), v)));

    final companion = TriageOutboxCompanion.insert(
      clientSessionId: sessionId,
      vertical: vertical,
      stepAnswersJson: jsonAnswers,
      narrative: Value(narrative),
      status: const Value('pending'),
      attempts: const Value(0),
      profileId: Value(effectiveProfileId),
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

  /// The server has the record now: drop the local copy (it holds free text).
  Future<void> markOutboxItemSynced(int id) {
    return (_db.delete(_db.triageOutbox)..where((tbl) => tbl.id.equals(id))).go();
  }

  Stream<int> getPendingCountStream() {
    final query = _db.selectOnly(_db.triageOutbox)
      ..addColumns([_db.triageOutbox.id.count()])
      ..where(_db.triageOutbox.status.equals('pending') | _db.triageOutbox.status.equals('syncing'));

    return query.map((row) => row.read(_db.triageOutbox.id.count()) ?? 0).watchSingle();
  }
}
