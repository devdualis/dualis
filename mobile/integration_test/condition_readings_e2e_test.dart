// Phase 16 Wave 4 (16-04-05): chronic-condition readings on a running app.
//
// Boots the real DualisApp (router, HomeScreen, AuthController, journal
// repository and Drift outbox) with the premium flag on. The journal API is an
// in-memory fake with the Phase 16 rules (idempotent clientId, readings nested
// in condition items, PATCH tracking, readings history); every other HTTP
// call fails as offline, so no backend is reached. Network state is a fake the
// test flips, so the offline save and the sync on reconnect run for real.
//
//   flutter test integration_test/condition_readings_e2e_test.dart \
//     -d <simulator> --dart-define=PREMIUM_FEATURES=true
import 'package:drift/native.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/core/notifications/app_notification_center.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/care/presentation/screens/summary_screen.dart';
import 'package:dualis_mobile/features/journal/data/journal_remote_data_source.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/condition_readings_screen.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/my_conditions_screen.dart';
import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
import 'package:dualis_mobile/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/journal_fakes.dart';
import 'helpers/profile_fakes.dart';

const _conditionId = 'cond-hta';
const _conditionLabel = 'Hipertensão arterial';
const _card = 'chronicTrack_$_conditionId';

Finder _key(String key) => find.byKey(ValueKey(key));

/// Pumps frames until [finder] matches (pumpAndSettle can hang on the home
/// screen's progress indicators).
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  bool present = true,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty == present) return;
  }
  fail('Timed out waiting for $finder to be ${present ? 'shown' : 'gone'}');
}

Future<void> _waitUntil(WidgetTester tester, bool Function() done, String what) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (done()) return;
  }
  fail('Timed out waiting for $what');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  final field = find.descendant(of: _key(key), matching: find.byType(TextField));
  await _waitFor(tester, field);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 200));
}

bool _enabled(WidgetTester tester, String key) {
  final button = find.descendant(
    of: _key(key),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(button.first).enabled;
}

/// Scrolls the readings history until [finder] is built (the day list sits
/// below the charts in a lazy ListView).
Future<void> _scrollHistoryTo(WidgetTester tester, Finder finder) async {
  final list = _key('chronic_history_list');
  for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
    await tester.drag(list, const Offset(0, -250));
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _openMyConditions(WidgetTester tester) async {
  await _tap(tester, _key('home_settings_button'));
  await _tap(tester, _key('settings_my_conditions_tile'));
  await _waitFor(tester, find.byType(MyConditionsScreen));
}

Future<void> _backToHome(WidgetTester tester) async {
  // Minhas condições (or its history) -> Ajustes -> Home.
  while (find.byType(BackButton).evaluate().isNotEmpty) {
    await _tap(tester, find.byType(BackButton));
  }
  await _tap(tester, find.byIcon(Icons.arrow_back_ios_new_rounded));
  await _waitFor(tester, _key('home_settings_button'));
}

/// Physical check-in from Home, "Bem", reading cards open.
Future<void> _startPhysicalBem(WidgetTester tester) async {
  final start = _key('start_fisica_triage_button');
  final retake = _key('retake_fisica_button');
  await _waitUntil(
    tester,
    () => start.evaluate().isNotEmpty || retake.evaluate().isNotEmpty,
    'the physical check-in card',
  );
  await _tap(tester, start.evaluate().isNotEmpty ? start : retake);
  await _tap(tester, _key('jv2_mood_${JournalKeys.moodBem}'));
  await _waitFor(tester, _key('chronicTrack_bem_banner'));
  await _waitFor(tester, _key('${_card}_card'));
}

Future<void> _finishOnSummary(WidgetTester tester) async {
  await _tap(tester, _key('check_in_summary_home_button'));
  await _waitFor(tester, _key('home_settings_button'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('T-16-11: tracking, Bem readings, history chart, summary, offline sync',
      (tester) async {
    expect(FeatureFlags.premiumProfiles, isTrue,
        reason: 'run with --dart-define=PREMIUM_FEATURES=true');

    FlutterSecureStorage.setMockInitialValues({});
    final net = FakeConnectivity();
    final journal = FakeJournalBackend(net, conditions: const [
      UserCondition(id: _conditionId, label: _conditionLabel),
    ]);
    final profiles = FakeProfileBackend();
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      premiumProfilesEnabledProvider.overrideWithValue(true),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      apiClientProvider.overrideWith(
          (ref) => offlineApiClient(ref.watch(secureStorageServiceProvider))),
      profileRepositoryProvider.overrideWith((ref) => profiles.repositoryFor(
          ref.watch(authControllerProvider
              .select((s) => s.isAuthenticated ? s.user?.id : null)))),
      journalRemoteDataSourceProvider.overrideWithValue(journal),
      connectivityServiceProvider.overrideWithValue(net),
      appNotificationCenterProvider.overrideWith((ref) => AppNotificationCenter(
            plugin: FlutterLocalNotificationsPlugin(),
            permissionPromptStore: AlreadyPromptedStore(),
          )),
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() async {
      container.dispose();
      await net.close();
      await db.close();
    });

    final auth = container.read(authControllerProvider.notifier);
    expect(await auth.login(email: userA.email, password: 'x'), isTrue);

    // ---- 1. Launch -------------------------------------------------------
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const DualisApp(),
    ));
    await _waitFor(tester, _key('home_settings_button'));

    // ---- 2. Minhas condições: switch on blood pressure + glucose ---------
    await _openMyConditions(tester);
    await _waitFor(tester, _key('jv2_condition_row_$_conditionId'));
    expect(_key('chronicTrack_view_readings_$_conditionId'), findsNothing);
    await _tap(tester, _key('chronicTrack_edit_$_conditionId'));
    // The add form behind the sheet has its own switch: use the sheet's.
    Finder inSheet(String key) =>
        find.descendant(of: find.byType(BottomSheet), matching: _key(key));
    await _tap(tester, inSheet('chronicTrack_toggle'));
    await _tap(tester, inSheet('chronicTrack_kind_${JournalKeys.trackingBloodPressure}'));
    await _tap(tester, inSheet('chronicTrack_kind_${JournalKeys.trackingGlucose}'));
    await _tap(tester, inSheet('chronicTrack_edit_save'));
    await _waitFor(tester, _key('chronicTrack_kinds_$_conditionId'));
    expect(journal.patchRequests.last, {
      'id': _conditionId,
      'tracking': [JournalKeys.trackingBloodPressure, JournalKeys.trackingGlucose],
    });
    expect(_key('chronicTrack_view_readings_$_conditionId'), findsOneWidget);
    await _backToHome(tester);

    // ---- 3. Physical check-in, Bem: readings screen ----------------------
    await _startPhysicalBem(tester);
    expect(_key('chronicTrack_just_log'), findsOneWidget);
    expect(_key('chronicTrack_save_without'), findsOneWidget);
    // Nothing typed yet: "Só registrar medições" waits for a reading.
    expect(_enabled(tester, 'chronicTrack_just_log'), isFalse);

    // ---- 4. 120/80 pulse 72 and glucose 98 (jejum), Só registrar ---------
    await _type(tester, '${_card}_0_systolic', '120');
    await _type(tester, '${_card}_0_diastolic', '80');
    await _type(tester, '${_card}_0_pulse', '72');
    await _type(tester, '${_card}_1_mgdl', '98');
    await _tap(tester, _key('${_card}_1_moment_${JournalKeys.momentJejum}'));
    expect(_enabled(tester, 'chronicTrack_just_log'), isTrue);
    await _tap(tester, _key('chronicTrack_just_log'));

    // ---- 5. Saved online with both readings ------------------------------
    await _waitFor(tester, _key('check_in_summary_home_button'));
    expect(journal.entries, hasLength(1));
    final saved = journal.entries.single;
    expect(saved.mood, JournalKeys.moodBem);
    final item = saved.items.single;
    expect(item.kind, JournalKeys.kindCondition);
    expect(item.conditionId, _conditionId);
    final bp = item.readings.firstWhere((r) => r.kind == JournalKeys.trackingBloodPressure);
    final glucose = item.readings.firstWhere((r) => r.kind == JournalKeys.trackingGlucose);
    expect((bp.systolic, bp.diastolic, bp.pulse), (120, 80, 72));
    expect((glucose.mgdl, glucose.moment), (98, JournalKeys.momentJejum));
    await _finishOnSummary(tester);

    // ---- 6. Ver medições: list by day and raw chart points ----------------
    await _openMyConditions(tester);
    await _tap(tester, _key('chronicTrack_view_readings_$_conditionId'));
    await _waitFor(tester, find.byType(ConditionReadingsScreen));
    await _waitFor(tester, _key('chronic_history_chart_${JournalKeys.trackingBloodPressure}'));
    expect(_key('chronic_history_chart_${JournalKeys.trackingGlucose}'), findsOneWidget);
    expect(_key('chronic_history_offline'), findsNothing);
    final charts = tester.widgetList<LineChart>(find.byType(LineChart)).toList();
    expect(charts, isNotEmpty);
    for (final chart in charts) {
      for (final bar in chart.data.lineBarsData) {
        expect(bar.isCurved, isFalse, reason: 'raw values, no smoothing');
      }
    }
    final spots = [
      for (final chart in charts)
        for (final bar in chart.data.lineBarsData) ...bar.spots,
    ];
    expect(spots.map((s) => s.y), containsAll(<double>[120, 80, 98]));
    final today = DateTime.now();
    final dayKey = '${today.year}${today.month.toString().padLeft(2, '0')}'
        '${today.day.toString().padLeft(2, '0')}';
    await _scrollHistoryTo(tester, _key('chronic_history_day_$dayKey'));
    await _scrollHistoryTo(tester, find.textContaining('120/80 mmHg'));
    expect(find.textContaining('pulso 72 bpm'), findsWidgets);
    await _scrollHistoryTo(tester, find.textContaining('98 mg/dL'));
    await _backToHome(tester);

    // ---- Summary screen lists the readings -------------------------------
    await _tap(tester, _key('nav_destination_care'));
    await _tap(tester, _key('care_hub_summary'));
    await _waitFor(tester, find.byType(SummaryScreen));
    await _waitFor(tester, find.textContaining('120/80 mmHg'));
    expect(find.textContaining('98 mg/dL'), findsWidgets);
    await _tap(tester, find.byType(BackButton));
    await _tap(tester, _key('nav_destination_home'));

    // ---- Offline save, then sync once on reconnect ------------------------
    net.setOnline(false);
    await tester.pump(const Duration(milliseconds: 300));
    await _startPhysicalBem(tester);
    await _type(tester, '${_card}_0_systolic', '130');
    await _type(tester, '${_card}_0_diastolic', '85');
    await _tap(tester, _key('chronicTrack_just_log'));
    await _waitFor(tester, _key('check_in_summary_home_button'));
    expect(journal.entries, hasLength(1), reason: 'offline save stays on the device');
    expect(await db.select(db.journalOutbox).get(), hasLength(1));
    // "Registro salvo no aparelho" covers the Home button until it hides.
    expect(find.byType(SnackBar), findsOneWidget);
    await _waitFor(tester, find.byType(SnackBar), present: false);
    await _finishOnSummary(tester);

    // History while offline: the queued reading shows, marked as partial.
    await _openMyConditions(tester);
    await _tap(tester, _key('chronicTrack_view_readings_$_conditionId'));
    await _waitFor(tester, _key('chronic_history_offline'));
    await _scrollHistoryTo(tester, find.textContaining('130/85 mmHg'));
    await _backToHome(tester);

    net.setOnline(true);
    await _waitUntil(tester, () => journal.entries.length == 2, 'the outbox sync');
    final offlineEntry = journal.entries.last;
    expect(journal.createCalls[offlineEntry.clientId], 1);
    expect(
      offlineEntry.items.single.readings.single,
      isA<ConditionReading>()
          .having((r) => r.systolic, 'systolic', 130)
          .having((r) => r.diastolic, 'diastolic', 85),
    );
    // A second reconnect sends nothing again.
    net.setOnline(false);
    net.setOnline(true);
    await tester.pump(const Duration(seconds: 1));
    expect(journal.createCalls[offlineEntry.clientId], 1);
    expect(journal.entries, hasLength(2));

    // History online again: both entries' readings, no offline banner.
    await _openMyConditions(tester);
    await _tap(tester, _key('chronicTrack_view_readings_$_conditionId'));
    await _waitFor(tester, _key('chronic_history_chart_${JournalKeys.trackingBloodPressure}'));
    expect(_key('chronic_history_offline'), findsNothing);
    await _scrollHistoryTo(tester, find.textContaining('130/85 mmHg'));
    await _scrollHistoryTo(tester, find.textContaining('120/80 mmHg'));
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing,
        reason: 'synced readings are no longer marked as waiting');

    // ---- 7. No framework errors during the run ---------------------------
    expect(tester.takeException(), isNull);
  });
}
