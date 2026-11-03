import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/features/journal/data/journal_repository.dart';
import 'package:dualis_mobile/features/sync/data/triage_outbox_repository.dart';
import 'package:dualis_mobile/features/sync/presentation/controllers/sync_outbox_worker.dart';
import 'package:dualis_mobile/features/sync/presentation/widgets/offline_indicator_banner.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class MockJournalRepository extends Mock implements JournalRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase db;
  late TriageOutboxRepository repository;
  late MockJournalRepository mockJournalRepo;
  late MockConnectivityService mockConnectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TriageOutboxRepository(db);
    mockJournalRepo = MockJournalRepository();
    mockConnectivity = MockConnectivityService();
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncOutboxWorker & Offline Sync Tests (SYNC-01)', () {
    test('legacy triage/daily-checkin outbox items are dropped permanently with no error loop', () async {
      await repository.enqueueTriageCheckIn(
        vertical: 'physical',
        answers: {0: 'cabeca', 1: 'ha_alguns_dias'},
        clientSessionId: 'legacy-session-1',
      );

      await repository.enqueueTriageCheckIn(
        vertical: 'emotional',
        answers: {0: 'ansiedade_agitacao', 1: 'comecou_hoje'},
        clientSessionId: 'legacy-session-2',
      );

      when(() => mockJournalRepo.syncPending()).thenAnswer((_) async => 0);
      when(() => mockConnectivity.isOnlineStream)
          .thenAnswer((_) => Stream.value(true));

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          triageOutboxRepositoryProvider.overrideWithValue(repository),
          journalRepositoryProvider.overrideWithValue(mockJournalRepo),
          connectivityServiceProvider.overrideWithValue(mockConnectivity),
        ],
      );
      addTearDown(container.dispose);

      final worker = container.read(syncOutboxWorkerProvider.notifier);
      final syncedCount = await worker.syncPendingOutbox();

      // Legacy items are discarded, not counted as synced journal entries.
      expect(syncedCount, equals(0));

      final pendingAfter = await repository.getPendingOutboxItems();
      expect(pendingAfter, isEmpty);

      final allRecords = await db.select(db.triageOutbox).get();
      expect(allRecords, isEmpty);
    });

    test('legacy outbox item is discarded and journal item still syncs', () async {
      await repository.enqueueTriageCheckIn(
        vertical: 'physical',
        answers: {0: 'costas'},
        clientSessionId: 'legacy-item',
      );

      when(() => mockJournalRepo.syncPending()).thenAnswer((_) async => 1);
      when(() => mockConnectivity.isOnlineStream)
          .thenAnswer((_) => Stream.value(true));

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          triageOutboxRepositoryProvider.overrideWithValue(repository),
          journalRepositoryProvider.overrideWithValue(mockJournalRepo),
          connectivityServiceProvider.overrideWithValue(mockConnectivity),
        ],
      );
      addTearDown(container.dispose);

      final worker = container.read(syncOutboxWorkerProvider.notifier);
      final syncedCount = await worker.syncPendingOutbox();

      // The journal entry synced successfully (count = 1).
      expect(syncedCount, equals(1));
      verify(() => mockJournalRepo.syncPending()).called(1);

      // The legacy outbox item was purged from the outbox.
      final pendingAfter = await repository.getPendingOutboxItems();
      expect(pendingAfter, isEmpty);
      final allLegacy = await db.select(db.triageOutbox).get();
      expect(allLegacy, isEmpty);
    });

    testWidgets('OfflineIndicatorBanner shows offline state and pending sync count', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => Stream.value(false)),
            pendingOutboxCountProvider.overrideWith((ref) => Stream.value(1)),
            rejectedOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('pt')],
            locale: Locale('pt'),
            home: Scaffold(
              body: OfflineIndicatorBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byKey(const Key('offline_indicator_banner')), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.textContaining('Modo Offline'), findsOneWidget);
      expect(find.textContaining('1 registro pendente'), findsOneWidget);
    });
  });
}
