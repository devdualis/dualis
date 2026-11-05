import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/core/voice/voice_output_service.dart';
import 'package:dualis_mobile/features/consent/data/ai_consent_repository.dart';
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

import '../consent/fake_ai_consent_repository.dart';

/// In-memory stand-in for the journal API.
class FakeJournalRemote implements JournalRemoteDataSource {
  final List<JournalEntry> created = [];
  final List<Map<String, dynamic>> requestBodies = [];
  List<UserCondition> conditions;
  bool fail = false;
  int? errorStatus;
  dynamic errorData;
  String? suggestedOptionKey;

  /// Thrown by [suggestOption] after recording the request (the server
  /// answered with an error, for example 403 AI_CONSENT_REQUIRED).
  DioException? suggestOptionError;
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
  Future<List<JournalEntry>> listEntries({
    int days = 30,
    String? profileId,
  }) async =>
      created;

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

  final List<Map<String, dynamic>> patchRequests = [];
  List<ConditionReading> readings = const [];
  final List<Map<String, Object?>> readingRequests = [];

  @override
  Future<UserCondition> patchCondition(
    String id, {
    List<String>? tracking,
    String? label,
    String? profileId,
  }) async {
    if (fail) throw _offline();
    patchRequests.add({
      'id': id,
      if (tracking != null) 'tracking': tracking,
      if (label != null) 'label': label,
    });
    final current = conditions.firstWhere((c) => c.id == id);
    final updated = current.copyWith(label: label, tracking: tracking);
    conditions = [for (final c in conditions) c.id == id ? updated : c];
    return updated;
  }

  @override
  Future<List<ConditionReading>> getConditionReadings(
    String conditionId, {
    int days = 90,
    String? profileId,
  }) async {
    if (fail) throw _offline();
    readingRequests.add({'conditionId': conditionId, 'days': days, 'profileId': profileId});
    return [for (final r in readings) if (r.conditionId == conditionId) r];
  }

  @override
  Future<String?> suggestOption({
    required String text,
    required String kind,
    String? branch,
  }) async {
    if (fail) throw _offline();
    suggestRequests.add({'text': text, 'kind': kind, 'branch': branch});
    final error = suggestOptionError;
    if (error != null) throw error;
    return suggestedOptionKey;
  }
}

/// Records what would be read aloud. Log entries: `prepare:<lang>`,
/// `speak`, `done`, `stop`; [log] can be shared with a fake mic to check
/// the order. With [hold] > 0 speak() stays pending (until [stop] or the
/// hold passes), to observe the speaking phase.
class FakeVoiceOutput implements VoiceOutputService {
  FakeVoiceOutput({List<String>? log}) : log = log ?? [];

  final List<String> spoken = [];
  final List<String> log;
  Duration hold = Duration.zero;
  Completer<void>? _pending;
  Timer? _timer;

  bool get speaking => _pending != null;

  @override
  Future<void> prepare(String languageCode) async => log.add('prepare:$languageCode');

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    log.add('speak');
    if (hold > Duration.zero) {
      final pending = _pending = Completer<void>();
      _timer = Timer(hold, _release);
      await pending.future;
    }
    log.add('done');
  }

  void _release() {
    final pending = _pending;
    _pending = null;
    _timer?.cancel();
    _timer = null;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  @override
  Future<void> stop() async {
    log.add('stop');
    _release();
  }
}

class JournalHarness {
  final AppDatabase db;
  final FakeJournalRemote remote;
  final JournalLocalStore local;
  bool online;
  DateTime Function()? clock;

  /// Premium build (`premiumProfilesEnabledProvider`) when set; null keeps
  /// the compile-time flag (Free in tests) and adds no override.
  bool? premium;
  late final JournalRepository repository;

  /// Replaces text to speech in every journal and voice test.
  final FakeVoiceOutput voiceOutput = FakeVoiceOutput();

  /// AI-processing consent server; granted by default so suggestion tests
  /// run as before. Set `consent.granted = false` to test the consent gate.
  final FakeAiConsentRepository consent = FakeAiConsentRepository(granted: true);

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
        if (premium != null) premiumProfilesEnabledProvider.overrideWithValue(premium!),
        voiceOutputServiceProvider.overrideWithValue(voiceOutput),
        aiConsentRepositoryProvider.overrideWithValue(consent),
      ];
}

/// A 403 answer from the suggestion endpoint with the stable [code]
/// (for example `AI_CONSENT_REQUIRED`).
DioException suggestForbidden(String code) {
  final request = RequestOptions(path: JournalEndpoints.suggestOption);
  return DioException(
    requestOptions: request,
    response: Response(
      requestOptions: request,
      statusCode: 403,
      data: {'statusCode': 403, 'error': 'Forbidden', 'code': code},
    ),
    type: DioExceptionType.badResponse,
  );
}

/// Pumps the journal flow with a stub summary route that shows what it got.
Future<GoRouter> pumpJournalFlow(
  WidgetTester tester,
  JournalHarness harness, {
  JournalFlowArgs args = const JournalFlowArgs(),
  List<Override> extraOverrides = const [],
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
      overrides: [...harness.overrides, ...extraOverrides],
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

/// "Não tão bem" emotional path: the time (screen 1), then its branch
/// (screen 2).
Future<void> pickFeeling(WidgetTester tester, String time, String branch) async {
  await tapKey(tester, 'jv2_time_$time');
  await tapKey(tester, 'jv2_branch_$time.$branch');
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
