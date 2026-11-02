import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/features/journal/data/journal_local_store.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Schema v6 as shipped (before `local_user_conditions.tracking`), frozen so
/// the upgrade path is tested against the real old layout.
const _v6Schema = [
  '''CREATE TABLE "triage_outbox" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "client_session_id" TEXT NOT NULL, "vertical" TEXT NOT NULL, "step_answers_json" TEXT NOT NULL, "narrative" TEXT NULL, "status" TEXT NOT NULL DEFAULT 'pending', "attempts" INTEGER NOT NULL DEFAULT 0, "last_error" TEXT NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "synced_at" INTEGER NULL, "profile_id" TEXT NULL)''',
  '''CREATE TABLE "local_symptom_drafts" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "vertical" TEXT NOT NULL, "current_step" INTEGER NOT NULL DEFAULT 0, "step_answers_json" TEXT NOT NULL, "narrative" TEXT NULL, "updated_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "profile_id" TEXT NULL)''',
  '''CREATE TABLE "water_intake_logs" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "remote_id" TEXT NULL, "user_id" TEXT NOT NULL, "amount_ml" INTEGER NOT NULL, "timestamp" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "source" TEXT NOT NULL DEFAULT 'manual', "profile_id" TEXT NULL, "client_id" TEXT NULL)''',
  '''CREATE TABLE "journal_outbox" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "client_id" TEXT NOT NULL UNIQUE, "payload_json" TEXT NOT NULL, "status" TEXT NOT NULL DEFAULT 'pending', "attempts" INTEGER NOT NULL DEFAULT 0, "last_error" TEXT NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "synced_at" INTEGER NULL, "profile_id" TEXT NULL)''',
  '''CREATE TABLE "local_user_conditions" ("id" TEXT NOT NULL, "label" TEXT NOT NULL, "profile_id" TEXT NOT NULL DEFAULT '', "created_at" INTEGER NULL, PRIMARY KEY ("id", "profile_id"))''',
];

final _payload = jsonEncode({
  'clientId': 'old-entry',
  'recordedAt': '2026-10-30T12:00:00.000Z',
  'mood': 'nao_tao_bem',
  'area': 'physical',
  'triggers': <String>[],
  'transitionVariantIds': <String>[],
  'items': [
    {'kind': 'condition', 'conditionId': 'c1', 'intensity': 3, 'label': 'Pressão'},
  ],
});

AppDatabase _openV6WithData() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (raw) {
        for (final sql in _v6Schema) {
          raw.execute(sql);
        }
        raw.execute(
          "INSERT INTO local_user_conditions (id, label, profile_id, created_at) "
          "VALUES ('c1', 'Pressão', 'p1', 1790000000), ('c2', 'Sono', '', NULL)",
        );
        raw.execute(
          'INSERT INTO journal_outbox (client_id, payload_json, profile_id) VALUES (?, ?, ?)',
          ['old-entry', _payload, 'p1'],
        );
        raw.execute(
          "INSERT INTO water_intake_logs (user_id, amount_ml, client_id) VALUES ('u1', 250, 'w1')",
        );
        raw.userVersion = 6;
      },
    ),
  );
}

void main() {
  test('schema version is 7', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 7);
  });

  test('upgrade from v6 adds tracking and keeps every row', () async {
    final db = _openV6WithData();
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 7);

    final conditions = await (db.select(db.localUserConditions)
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
    expect(conditions.map((c) => c.id), ['c1', 'c2']);
    expect(conditions.map((c) => c.label), ['Pressão', 'Sono']);
    expect(conditions.map((c) => c.profileId), ['p1', '']);
    expect(conditions.map((c) => c.tracking), ['[]', '[]']);

    final outbox = await db.select(db.journalOutbox).getSingle();
    expect(outbox.clientId, 'old-entry');
    expect(outbox.payloadJson, _payload);
    expect(outbox.status, 'pending');

    final water = await db.select(db.waterIntakeLogs).getSingle();
    expect(water.amountMl, 250);
    expect(water.clientId, 'w1');
  });

  test('upgraded cache reads as untracked and stores tracking after', () async {
    final db = _openV6WithData();
    addTearDown(db.close);
    final store = JournalLocalStore(db);

    final cached = await store.cachedConditions('p1');
    expect(cached.single.label, 'Pressão');
    expect(cached.single.tracking, isEmpty);
    expect(cached.single.isTracked, isFalse);

    await store.replaceConditions('p1', [
      cached.single.copyWith(tracking: ['glucose', 'blood_pressure']),
    ]);
    final again = await store.cachedConditions('p1');
    expect(again.single.tracking, ['blood_pressure', 'glucose']);

    final pending = await store.pendingEntries(profileId: 'p1');
    expect(pending.single.items.single.conditionId, 'c1');
    expect(pending.single.items.single.readings, isEmpty);
  });

  test('a broken tracking value reads as untracked', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.localUserConditions).insert(
          LocalUserConditionsCompanion.insert(
            id: 'c9',
            label: 'X',
            tracking: const Value('not json'),
          ),
        );
    final cached = await JournalLocalStore(db).cachedConditions(null);
    expect(cached.single.tracking, isEmpty);
    expect(UserCondition.cleanTracking(['weight', 'nope', 'weight']), ['weight']);
  });
}
