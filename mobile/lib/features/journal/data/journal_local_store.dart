import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/journal_models.dart';

final journalLocalStoreProvider = Provider<JournalLocalStore>((ref) {
  return JournalLocalStore(ref.watch(appDatabaseProvider));
});

/// Drift storage for journal v2: the entry outbox (offline-first, idempotent
/// by `clientId`) and the cached list of the user's conditions.
class JournalLocalStore {
  final AppDatabase _db;

  JournalLocalStore(this._db);

  /// Saves the entry for later sync. Saving the same `clientId` twice keeps a
  /// single row.
  Future<void> enqueue(JournalEntry entry, {String? profileId}) async {
    await _db
        .into(_db.journalOutbox)
        .insert(
          JournalOutboxCompanion.insert(
            clientId: entry.clientId,
            payloadJson: jsonEncode(entry.toLocalJson()),
            profileId: Value(profileId),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<List<JournalOutboxData>> pending({int limit = 50}) {
    return (_db.select(_db.journalOutbox)
          ..where((t) => t.status.equals('pending') | t.status.equals('failed'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Entries saved on the device that the server does not have yet.
  Future<List<JournalEntry>> pendingEntries({String? profileId}) async {
    final rows =
        await (_db.select(_db.journalOutbox)
              ..where((t) => t.status.isNotIn(['synced']))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return [
      for (final row in rows)
        if (profileId == null ||
            row.profileId == null ||
            row.profileId == profileId)
          decode(row).copyWith(pendingSync: true),
    ];
  }

  JournalEntry decode(JournalOutboxData row) => JournalEntry.fromJson(
    jsonDecode(row.payloadJson) as Map<String, dynamic>,
  );

  Future<void> markSyncing(int id) => _setStatus(id, 'syncing');

  Future<void> markSynced(int id) {
    return (_db.update(_db.journalOutbox)..where((t) => t.id.equals(id))).write(
      JournalOutboxCompanion(
        status: const Value('synced'),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markFailed(int id, String error) async {
    final row =
        await (_db.select(_db.journalOutbox)
          ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.journalOutbox)..where((t) => t.id.equals(id))).write(
      JournalOutboxCompanion(
        status: const Value('failed'),
        lastError: Value(error),
        attempts: Value(row.attempts + 1),
      ),
    );
  }

  Future<void> _setStatus(int id, String status) {
    return (_db.update(_db.journalOutbox)..where(
      (t) => t.id.equals(id),
    )).write(JournalOutboxCompanion(status: Value(status)));
  }

  Stream<int> pendingCountStream() {
    final count = _db.journalOutbox.id.count();
    final query =
        _db.selectOnly(_db.journalOutbox)
          ..addColumns([count])
          ..where(_db.journalOutbox.status.isNotIn(['synced']));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<List<UserCondition>> cachedConditions(String? profileId) async {
    final rows =
        await (_db.select(_db.localUserConditions)
              ..where((t) => t.profileId.equals(profileId ?? ''))
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
            .get();
    return [
      for (final r in rows)
        UserCondition(id: r.id, label: r.label, createdAt: r.createdAt),
    ];
  }

  Future<void> replaceConditions(
    String? profileId,
    List<UserCondition> conditions,
  ) async {
    final key = profileId ?? '';
    await _db.transaction(() async {
      await (_db.delete(_db.localUserConditions)
        ..where((t) => t.profileId.equals(key))).go();
      await _db.batch((b) {
        b.insertAll(_db.localUserConditions, [
          for (final c in conditions)
            LocalUserConditionsCompanion.insert(
              id: c.id,
              label: c.label,
              profileId: Value(key),
              createdAt: Value(c.createdAt),
            ),
        ]);
      });
    });
  }
}
