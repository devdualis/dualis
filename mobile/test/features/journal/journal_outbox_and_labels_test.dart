import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/utils/local_day.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';

import 'journal_test_helpers.dart';

JournalEntry _entry() => JournalEntry(
      clientId: 'c1',
      recordedAt: DateTime(2026, 10, 27, 12),
      mood: 'normal',
    );

void main() {
  test('customLabel truncation keeps a trailing emoji intact', () {
    final label = '${'a' * 39}🙂b';
    final clipped = JournalKeys.limitChars(label, 40);
    expect(clipped, '${'a' * 39}🙂');
  });

  test('tzOffset is minutes east of UTC', () {
    final now = DateTime.now();
    expect(localTzOffsetMinutes(now), now.timeZoneOffset.inMinutes);
  });

  test('stale syncing rows are retried after 5 minutes', () async {
    final h = JournalHarness();
    await h.local.enqueue(_entry());
    final row = (await h.db.select(h.db.journalOutbox).get()).single;
    await h.local.markSyncing(row.id);
    final fresh = await h.local.pending(now: DateTime.now());
    expect(fresh, isEmpty);
    final stale = await h.local.pending(
      now: DateTime.now().add(const Duration(minutes: 6)),
    );
    expect(stale, hasLength(1));
  });

  test('409 with existing entry is synced; 400 is rejected', () async {
    final ok = JournalHarness(online: true);
    await ok.local.enqueue(_entry());
    ok.remote.errorStatus = 409;
    ok.remote.errorData = {'id': 'srv-1', 'clientId': 'c1'};
    expect(await ok.repository.syncPending(), 1);
    expect(await ok.db.select(ok.db.journalOutbox).get(), isEmpty);

    final bad = JournalHarness(online: true);
    await bad.local.enqueue(_entry());
    bad.remote.errorStatus = 400;
    bad.remote.errorData = {'message': 'invalid'};
    expect(await bad.repository.syncPending(), 0);
    expect((await bad.db.select(bad.db.journalOutbox).get()).single.status, 'rejected');
  });

  test('409 without the existing entry is rejected', () async {
    final h = JournalHarness(online: true);
    await h.local.enqueue(_entry());
    h.remote.errorStatus = 409;
    h.remote.errorData = {'message': 'conflict'};
    expect(await h.repository.syncPending(), 0);
    expect((await h.db.select(h.db.journalOutbox).get()).single.status, 'rejected');
  });
}
