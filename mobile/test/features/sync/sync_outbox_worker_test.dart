import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/features/sync/data/triage_outbox_repository.dart';
import 'package:dualis_mobile/features/sync/presentation/controllers/sync_outbox_worker.dart';
import 'package:dualis_mobile/features/sync/presentation/widgets/offline_indicator_banner.dart';
import 'package:dualis_mobile/features/triage_outcome/data/triage_outcome_remote_data_source.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class MockTriageOutcomeRemoteDataSource extends Mock
    implements TriageOutcomeRemoteDataSource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase db;
  late TriageOutboxRepository repository;
  late MockTriageOutcomeRemoteDataSource mockDataSource;
  late MockConnectivityService mockConnectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TriageOutboxRepository(db);
    mockDataSource = MockTriageOutcomeRemoteDataSource();
    mockConnectivity = MockConnectivityService();
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncOutboxWorker & Offline Sync Tests (SYNC-01)', () {
    test('drains pending items and marks them synced upon successful transmission', () async {
      await repository.enqueueTriageCheckIn(
        vertical: 'physical',
        answers: {0: 'cabeca', 1: 'ha_alguns_dias'},
        clientSessionId: 'session-1',
      );

      await repository.enqueueTriageCheckIn(
        vertical: 'emotional',
        answers: {0: 'ansiedade_agitacao', 1: 'comecou_hoje'},
        clientSessionId: 'session-2',
      );

      final dummyOutcome = TriageOutcome(
        id: 'out-1',
        vertical: 'physical',
        intensityScore: 3,
        primaryCategory: 'cabeca',
        categoryLabel: 'Cabeça',
        somaticMapping: 'Cabeça',
        recommendedArticles: [],
        recordedAt: DateTime.now(),
      );

      when(() => mockDataSource.submitTriage(
            vertical: any(named: 'vertical'),
            answers: any(named: 'answers'),
            narrative: any(named: 'narrative'),
            token: any(named: 'token'),
            clientSessionId: any(named: 'clientSessionId'),
          )).thenAnswer((_) async => dummyOutcome);

      when(() => mockConnectivity.isOnlineStream)
          .thenAnswer((_) => Stream.value(true));

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          triageOutboxRepositoryProvider.overrideWithValue(repository),
          triageOutcomeDataSourceProvider.overrideWithValue(mockDataSource),
          connectivityServiceProvider.overrideWithValue(mockConnectivity),
        ],
      );

      final worker = container.read(syncOutboxWorkerProvider.notifier);
      final syncedCount = await worker.syncPendingOutbox();

      expect(syncedCount, equals(2));

      final pendingAfter = await repository.getPendingOutboxItems();
      expect(pendingAfter, isEmpty);

      final allRecords = await db.select(db.triageOutbox).get();
      expect(allRecords.every((r) => r.status == 'synced'), isTrue);
    });

    test('marks item failed and increments attempts when transmission fails', () async {
      final item = await repository.enqueueTriageCheckIn(
        vertical: 'physical',
        answers: {0: 'costas'},
        clientSessionId: 'failing-session',
      );

      when(() => mockDataSource.submitTriage(
            vertical: any(named: 'vertical'),
            answers: any(named: 'answers'),
            narrative: any(named: 'narrative'),
            token: any(named: 'token'),
            clientSessionId: any(named: 'clientSessionId'),
          )).thenThrow(Exception('Simulated 503 Service Unavailable'));

      when(() => mockConnectivity.isOnlineStream)
          .thenAnswer((_) => Stream.value(true));

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          triageOutboxRepositoryProvider.overrideWithValue(repository),
          triageOutcomeDataSourceProvider.overrideWithValue(mockDataSource),
          connectivityServiceProvider.overrideWithValue(mockConnectivity),
        ],
      );

      final worker = container.read(syncOutboxWorkerProvider.notifier);
      final syncedCount = await worker.syncPendingOutbox();

      expect(syncedCount, equals(0));

      final updatedRecord = await (db.select(db.triageOutbox)
            ..where((tbl) => tbl.id.equals(item.id)))
          .getSingle();

      expect(updatedRecord.status, equals('failed'));
      expect(updatedRecord.attempts, equals(1));
      expect(updatedRecord.lastError, contains('503 Service Unavailable'));
    });

    test('sends stored profileId explicitly via submitTriageForProfile when outbox item has profileId', () async {
      await repository.enqueueTriageCheckIn(
        vertical: 'physical',
        answers: {0: 'dor_de_cabeca'},
        clientSessionId: 'session-profile-1',
        profileId: 'profile-dep-123',
      );

      final dummyOutcome = TriageOutcome(
        id: 'out-profile-1',
        vertical: 'physical',
        intensityScore: 3,
        primaryCategory: 'cabeca',
        categoryLabel: 'Cabeça',
        somaticMapping: 'Cabeça',
        recommendedArticles: [],
        recordedAt: DateTime.now(),
      );

      when(() => mockDataSource.submitTriageForProfile(
            vertical: any(named: 'vertical'),
            answers: any(named: 'answers'),
            narrative: any(named: 'narrative'),
            token: any(named: 'token'),
            clientSessionId: any(named: 'clientSessionId'),
            language: any(named: 'language'),
            profileId: any(named: 'profileId'),
          )).thenAnswer((_) async => dummyOutcome);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          triageOutboxRepositoryProvider.overrideWithValue(repository),
          triageOutcomeDataSourceProvider.overrideWithValue(mockDataSource),
          connectivityServiceProvider.overrideWithValue(mockConnectivity),
        ],
      );
      addTearDown(container.dispose);

      final worker = container.read(syncOutboxWorkerProvider.notifier);
      final count = await worker.syncPendingOutbox();
      expect(count, equals(1));

      verify(() => mockDataSource.submitTriageForProfile(
            vertical: 'physical',
            answers: {0: 'dor_de_cabeca'},
            narrative: null,
            clientSessionId: 'session-profile-1',
            profileId: 'profile-dep-123',
          )).called(1);

      final pending = await repository.getPendingOutboxItems();
      expect(pending, isEmpty);
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
