import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/features/sync/data/triage_outbox_repository.dart';

void main() {
  late AppDatabase db;
  late TriageOutboxRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TriageOutboxRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift AppDatabase & TriageOutboxRepository Tests', () {
    test('enqueues triage check-ins with correct pending status', () async {
      final item = await repository.enqueueTriageCheckIn(
        vertical: 'physical',
        answers: {0: 'cabeca', 1: 'ha_alguns_dias', 2: '3'},
        narrative: 'Dor frontal moderada',
        clientSessionId: 'test-session-123',
      );

      expect(item.id, isPositive);
      expect(item.clientSessionId, equals('test-session-123'));
      expect(item.vertical, equals('physical'));
      expect(item.status, equals('pending'));
      expect(item.attempts, equals(0));
      expect(item.narrative, equals('Dor frontal moderada'));
    });

    test('retrieves pending outbox items in FIFO order', () async {
      // Enqueue item 1
      await repository.enqueueTriageCheckIn(
        vertical: 'physical',
        answers: {0: 'cabeca', 1: 'comecou_agora', 2: '2'},
        clientSessionId: 'first-session',
      );

      // Small delay to ensure timestamp separation
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Enqueue item 2
      await repository.enqueueTriageCheckIn(
        vertical: 'emotional',
        answers: {0: 'ansiedade_agitacao', 1: 'comecou_hoje', 2: 'leve_controlavel'},
        clientSessionId: 'second-session',
      );

      final pending = await repository.getPendingOutboxItems();
      expect(pending.length, equals(2));
      expect(pending[0].clientSessionId, equals('first-session'));
      expect(pending[1].clientSessionId, equals('second-session'));
    });

    test('updates status and marks outbox item as synced', () async {
      final item = await repository.enqueueTriageCheckIn(
        vertical: 'physical',
        answers: {0: 'articulacoes', 1: 'ha_alguns_dias', 2: '4'},
        clientSessionId: 'sync-test-session',
      );

      // Update to syncing
      await repository.updateOutboxStatus(item.id, 'syncing');
      var pending = await repository.getPendingOutboxItems();
      expect(pending.where((i) => i.id == item.id), isEmpty);

      // Mark synced
      await repository.markOutboxItemSynced(item.id);

      final syncedItem = await (db.select(db.triageOutbox)
            ..where((tbl) => tbl.id.equals(item.id)))
          .getSingle();

      expect(syncedItem.status, equals('synced'));
      expect(syncedItem.syncedAt, isNotNull);
    });

    test('tracks pending count accurately through outbox lifecycle', () async {
      var initialPending = await repository.getPendingOutboxItems();
      expect(initialPending.length, equals(0));

      final item1 = await repository.enqueueTriageCheckIn(
        vertical: 'physical',
        answers: {0: 'costas'},
      );

      var afterFirst = await repository.getPendingOutboxItems();
      expect(afterFirst.length, equals(1));

      final item2 = await repository.enqueueTriageCheckIn(
        vertical: 'emotional',
        answers: {0: 'estresse_irritabilidade'},
      );

      var afterSecond = await repository.getPendingOutboxItems();
      expect(afterSecond.length, equals(2));

      await repository.markOutboxItemSynced(item1.id);

      var afterSync = await repository.getPendingOutboxItems();
      expect(afterSync.length, equals(1));
      expect(afterSync.first.id, equals(item2.id));
    });
  });
}
