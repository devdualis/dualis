import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/journal/data/journal_local_store.dart';
import 'package:dualis_mobile/features/journal/data/journal_remote_data_source.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';

class _EmptyStorage extends SecureStorageService {
  @override
  Future<String?> getUserId() async => 'user-a';
  @override
  Future<Map<String, dynamic>?> getDailyCheckIn(String userId) async => null;
  @override
  Future<void> saveDailyCheckIn({
    required String userId,
    required Map<String, dynamic> data,
  }) async {}
  @override
  Future<String?> getAccessToken() async => 'token';
}

class _NoHistory extends TriageHistoryRemoteDataSource {
  final bool offline;
  _NoHistory({this.offline = false});
  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async =>
      offline ? TriageHistoryResponse.failed() : TriageHistoryResponse.empty();
}

/// Device copy says today is done (e.g. an entry deleted on another device).
class _CachedDoneStorage extends _EmptyStorage {
  @override
  Future<Map<String, dynamic>?> getDailyCheckIn(String userId) async {
    final d = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return {
      'checkInDate': '${d.year}-${two(d.month)}-${two(d.day)}',
      'isCompletedToday': true,
      'isEmotionalCompleted': true,
      'emotionalStatus': 'goodNormal',
    };
  }

  @override
  Future<void> clearDailyCheckIn(String userId) async {}
}

class _FakeJournalRemote extends JournalRemoteDataSource {
  final List<JournalEntry> entries;
  final bool offline;
  _FakeJournalRemote(this.entries, {this.offline = false})
      : super(apiClient: ApiClient(), secureStorage: _EmptyStorage());

  @override
  Future<List<JournalEntry>> listEntries({
    int days = 30,
    String? profileId,
  }) async {
    if (offline) throw Exception('offline');
    return entries;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProviderContainer containerWith(
    List<JournalEntry> remote, {
    SecureStorageService? storage,
    bool offline = false,
  }) {
    final c = ProviderContainer(overrides: [
      secureStorageServiceProvider.overrideWithValue(storage ?? _EmptyStorage()),
      triageHistoryDataSourceProvider
          .overrideWithValue(_NoHistory(offline: offline)),
      journalRemoteDataSourceProvider
          .overrideWithValue(_FakeJournalRemote(remote, offline: offline)),
      journalLocalStoreProvider.overrideWithValue(JournalLocalStore(db)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('after a new login, today\'s journal entry marks Home as done', () async {
    final now = DateTime.now();
    final container = containerWith([
      JournalEntry(
        id: 'e1',
        clientId: 'c1',
        recordedAt: now.subtract(const Duration(minutes: 30)),
        mood: JournalKeys.moodNaoTaoBem,
        area: JournalKeys.areaPhysical,
        items: const [
          JournalItem(
            kind: JournalKeys.kindPhysical,
            customLabel: 'dor nas costas',
            intensity: 3,
          ),
        ],
      ),
    ]);

    await container.read(triggerCheckInProvider.notifier).loadTodayCheckIn(now);

    final state = container.read(triggerCheckInProvider);
    expect(state.isCompletedToday, isTrue);
    expect(state.isPhysicalCompleted, isTrue);
    expect(state.isEmotionalCompleted, isFalse);
    expect(state.physicalSummary, 'dor nas costas');
    expect(state.physicalIntensity, 3);
  });

  test('entries from yesterday do not mark today', () async {
    final now = DateTime.now();
    final container = containerWith([
      JournalEntry(
        id: 'e0',
        clientId: 'c0',
        recordedAt: DateTime(now.year, now.month, now.day)
            .subtract(const Duration(hours: 2)),
        mood: JournalKeys.moodBem,
      ),
    ]);

    await container.read(triggerCheckInProvider.notifier).loadTodayCheckIn(now);

    expect(container.read(triggerCheckInProvider).isCompletedToday, isFalse);
  });

  test('an entry still in the offline outbox also marks today', () async {
    final now = DateTime.now();
    final container = containerWith(const []);
    await JournalLocalStore(db).enqueue(JournalEntry(
      clientId: 'c2',
      recordedAt: now.subtract(const Duration(minutes: 5)),
      mood: JournalKeys.moodBem,
      area: JournalKeys.areaEmotional,
    ));

    await container.read(triggerCheckInProvider.notifier).loadTodayCheckIn(now);

    final state = container.read(triggerCheckInProvider);
    expect(state.isEmotionalCompleted, isTrue);
    expect(state.isPhysicalCompleted, isFalse);
  });

  test('the server wins over the device copy when it answers', () async {
    final container = containerWith(const [], storage: _CachedDoneStorage());

    await container.read(triggerCheckInProvider.notifier).loadTodayCheckIn();

    expect(container.read(triggerCheckInProvider).isCompletedToday, isFalse);
  });

  test('without connection the device copy is used', () async {
    final container = containerWith(
      const [],
      storage: _CachedDoneStorage(),
      offline: true,
    );

    await container.read(triggerCheckInProvider.notifier).loadTodayCheckIn();

    expect(container.read(triggerCheckInProvider).isCompletedToday, isTrue);
  });
}
