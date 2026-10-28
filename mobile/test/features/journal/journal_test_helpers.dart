import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/features/dashboard/presentation/screens/check_in_summary_screen.dart';
import 'package:dualis_mobile/features/journal/data/journal_local_store.dart';
import 'package:dualis_mobile/features/journal/data/journal_remote_data_source.dart';
import 'package:dualis_mobile/features/journal/data/journal_repository.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_controller.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/journal_flow_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// In-memory stand-in for the journal API.
class FakeJournalRemote implements JournalRemoteDataSource {
  final List<JournalEntry> created = [];
  final List<Map<String, dynamic>> requestBodies = [];
  List<UserCondition> conditions;
  bool fail = false;
  int? errorStatus;
  dynamic errorData;
  String? suggestedOptionKey;
  final List<Map<String, String?>> suggestRequests = [];

  FakeJournalRemote({this.conditions = const []});

  DioException _offline() => DioException(
        requestOptions: RequestOptions(path: JournalEndpoints.entries),
        type: DioExceptionType.connectionError,
      );

  @override
  Future<JournalEntry> createEntry(JournalEntry entry, {String? profileId}) async {
    if (fail) throw _offline();
    if (errorStatus != null) {
      final request = RequestOptions(path: JournalEndpoints.entries);
      throw DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: errorStatus,
          data: errorData,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    requestBodies.add(entry.toRequestJson());
    created.add(entry);
    return entry.copyWith(id: 'srv-${created.length}');
  }

  @override
  Future<List<JournalEntry>> listEntries({int days = 30}) async => created;

  @override
  Future<void> deleteEntry(String id) async {}

  @override
  Future<List<UserCondition>> listConditions() async {
    if (fail) throw _offline();
    return conditions;
  }

  @override
  Future<UserCondition> createCondition(String label) async {
    if (fail) throw _offline();
    final c = UserCondition(id: 'c${conditions.length + 1}', label: label);
    conditions = [...conditions, c];
    return c;
  }

  @override
  Future<void> archiveCondition(String id) async {
    if (fail) throw _offline();
    conditions = [for (final c in conditions) if (c.id != id) c];
  }

  @override
  Future<String?> suggestOption({
    required String text,
    required String kind,
    String? branch,
  }) async {
    if (fail) throw _offline();
    suggestRequests.add({'text': text, 'kind': kind, 'branch': branch});
    return suggestedOptionKey;
  }
}

class JournalHarness {
  final AppDatabase db;
  final FakeJournalRemote remote;
  final JournalLocalStore local;
  bool online;
  DateTime Function()? clock;
  late final JournalRepository repository;

  JournalHarness({List<UserCondition> conditions = const [], bool online = true})
      : this._(AppDatabase(NativeDatabase.memory()), conditions, online);

  JournalHarness._(this.db, List<UserCondition> conditions, this.online)
      : remote = FakeJournalRemote(conditions: conditions),
        local = JournalLocalStore(db) {
    addTearDown(db.close);
    repository = JournalRepository(
      remote: remote,
      local: local,
      isOnline: () async => online,
      activeProfileId: () => null,
    );
  }

  List<Override> get overrides => [
        journalRepositoryProvider.overrideWithValue(repository),
        journalRandomProvider.overrideWithValue(Random(7)),
        if (clock != null) homeClockProvider.overrideWithValue(clock!),
      ];
}

/// Pumps the journal flow with a stub summary route that shows what it got.
Future<GoRouter> pumpJournalFlow(
  WidgetTester tester,
  JournalHarness harness, {
  JournalFlowArgs args = const JournalFlowArgs(),
}) async {
  tester.view.physicalSize = const Size(1000, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: RoutePaths.journal,
    routes: [
      GoRoute(
        path: RoutePaths.journal,
        builder: (context, state) => JournalFlowScreen(args: args),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const Scaffold(body: Text('HOME')),
      ),
      GoRoute(
        path: RoutePaths.emergency,
        builder: (context, state) => const Scaffold(body: Text('HELP SCREEN')),
      ),
      GoRoute(
        path: RoutePaths.checkInSummary,
        builder: (context, state) {
          final args = state.extra as CheckInSummaryArgs?;
          final entry = args?.entry;
          return Scaffold(
            body: Text(
              'SUMMARY items=${entry?.items.length} pending=${entry?.pendingSync}',
              key: const Key('summary_stub'),
            ),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: harness.overrides,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
