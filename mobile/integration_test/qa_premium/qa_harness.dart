// Shared setup for the Premium QA runs (voice + biometric lock).
//
// Boots the real DualisApp (real router, screens, overlays, AuthController,
// BiometricLockController and the real local_auth BiometricService) with a
// fake signed-in account, an in-memory keychain and journal store, and no
// network. Voice uses a scripted speech service so the real UI is driven by
// fixed phrases. The Premium flag is NOT overridden: it comes from
// --dart-define=PREMIUM_FEATURES=true, exactly like the store builds.
//
// The Mac runs host_helper.py on 127.0.0.1:8999 for screenshots, videos,
// Face ID match / no-match and sending the app to the background.
import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/core/notifications/app_notification_center.dart';
import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/security/biometric_lock_controller.dart';
import 'package:dualis_mobile/core/security/biometric_service.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/core/voice/voice_input_service.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
import 'package:dualis_mobile/features/sync/presentation/widgets/offline_indicator_banner.dart';
import 'package:dualis_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/features/journal/journal_test_helpers.dart';
import '../helpers/profile_fakes.dart';

const qaPassword = 'Senha-QA-123';
bool get isPremium => FeatureFlags.premiumProfiles;
String get build => isPremium ? 'premium' : 'free';

// ---------------------------------------------------------------- host ----

Future<void> host(String path, [Map<String, String> q = const {}]) async {
  final uri = Uri.http('127.0.0.1:8999', path, q);
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final res = await (await client.getUrl(uri)).close();
    await res.drain<void>();
    client.close();
  } catch (e) {
    debugPrint('host helper $path failed: $e');
  }
}

Future<void> hostLog(String msg) => host('/log', {'msg': msg});

/// Screenshot of the simulator screen, named with the build.
Future<void> shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 250));
  await host('/shot', {'name': '${build}_$name'});
}

/// Screenshot taken by the Mac after [ms], while the app is blocked
/// (for the system Face ID sheet).
Future<void> shotLater(String name, int ms) =>
    host('/shot', {'name': '${build}_$name', 'delay': '$ms'});

Future<void> faceLater(bool match, int ms) =>
    host('/face', {'r': match ? 'match' : 'nomatch', 'delay': '$ms'});

Future<void> videoStart(String name) => host('/video/start', {'name': '${build}_$name'});
Future<void> videoStop() => host('/video/stop');

/// Puts the app in the background for [secs] (the Mac opens the Settings
/// app, then reopens Dualis) and waits until it is back.
Future<void> background(WidgetTester tester, int secs) async {
  await host('/bg', {'secs': '$secs'});
  // Dart is suspended while in the background; plain waiting is fine.
  await Future<void>.delayed(Duration(seconds: secs + 4));
  await settle(tester, ms: 1500);
}

// --------------------------------------------------------------- pumping --

Future<void> settle(WidgetTester tester, {int ms = 600}) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  bool present = true,
  Duration timeout = const Duration(seconds: 12),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty == present) return;
  }
  fail('Timed out waiting for $finder to be ${present ? 'shown' : 'gone'}');
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tap(finder.first, warnIfMissed: false);
  await settle(tester, ms: 500);
}

Finder byKey(String key) => find.byKey(Key(key));

// ----------------------------------------------------------------- fakes --

/// Fake auth backend that only accepts [qaPassword].
class QaAuthRepository extends FakeAuthRepository {
  int loginCalls = 0;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (password != qaPassword) {
      throw Exception('E-mail ou senha incorretos.');
    }
    return super.login(email: email, password: password);
  }
}

/// Speech service that "hears" queued phrases. Each listen() waits a bit,
/// shows the first word as partial text, then the full phrase as final.
/// An empty queue (or a '' entry) is a silence.
class ScriptedVoice implements VoiceInputService {
  final List<String> queue = [];
  final List<bool> listens = []; // dictation flag of each listen()
  VoiceStartError? startError;
  int cancels = 0;
  Duration delay = const Duration(milliseconds: 900);

  void say(List<String> phrases) => queue.addAll(phrases);

  @override
  Future<VoiceStartError?> prepare() async => startError;

  @override
  Future<void> listen({
    required String languageCode,
    required bool dictation,
    required void Function(String text, bool isFinal) onResult,
    required void Function() onDone,
  }) async {
    listens.add(dictation);
    final n = listens.length;
    unawaited(() async {
      await Future<void>.delayed(delay);
      if (n != listens.length) return; // cancelled / replaced
      if (queue.isEmpty) {
        await Future<void>.delayed(delay);
        if (n == listens.length) onDone();
        return;
      }
      final phrase = queue.removeAt(0);
      if (phrase.isEmpty) {
        onDone();
        return;
      }
      onResult(phrase.split(' ').first, false);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      onResult(phrase, true);
    }());
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async => cancels++;
}

/// The real local_auth service. The only addition: [cancelNext] makes the
/// next N prompts end as if "Cancelar" was tapped on the system sheet. The
/// simulator's Face ID / passcode sheets cannot be tapped from automation
/// (no accessibility access to the Simulator window), and a no-match keeps
/// the sheet open until someone taps.
class QaBiometricService extends BiometricService {
  int cancelNext = 0;
  int calls = 0;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    calls++;
    if (cancelNext > 0) {
      cancelNext--;
      await hostLog('biometric prompt #$calls: simulated Cancelar');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return false;
    }
    final ok = await super.authenticate(localizedReason: localizedReason);
    await hostLog('biometric prompt #$calls: real local_auth -> $ok');
    return ok;
  }
}

/// Never shows the OS notification dialog (it would cover screenshots and
/// cannot be dismissed from the test).
class QaNotificationCenter extends AppNotificationCenter {
  QaNotificationCenter()
      : super(
          plugin: FlutterLocalNotificationsPlugin(),
          permissionPromptStore: AlreadyPromptedStore(),
        );

  @override
  Future<bool> requestPermissions() async => true;
}

class QaApp {
  QaApp(this.container, this.voice, this.auth, this._db, this.bio, this.journal);
  final JournalHarness journal;
  final ProviderContainer container;
  final QaBiometricService bio;
  final ScriptedVoice voice;
  final QaAuthRepository auth;
  final AppDatabase _db;
  bool _closed = false;

  /// Unmounts the app and drops all in-memory state (the keychain stays):
  /// the next [bootApp] is a cold start.
  Future<void> close(WidgetTester tester) async {
    if (_closed) return;
    _closed = true;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
    await _db.close();
  }

  String get location {
    final router = container.read(appRouterProvider);
    if (router.routerDelegate.currentConfiguration.isEmpty) return '';
    return router.state.matchedLocation;
  }
}

/// Fresh keychain for a new test (cold-start tests keep it).
void resetKeychain() => FlutterSecureStorage.setMockInitialValues({});

/// Boots the real app. [signIn] logs in before the first frame (a person
/// already signed in); otherwise the app restores the stored session on
/// its own, like a cold start.
Future<QaApp> bootApp(WidgetTester tester,
    {bool signIn = true, int settleMs = 1500}) async {
  final voice = ScriptedVoice();
  final auth = QaAuthRepository();
  final bio = QaBiometricService();
  final journal = JournalHarness();
  final backend = FakeProfileBackend();
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    ...journal.overrides,
    authRepositoryProvider.overrideWithValue(auth),
    apiClientProvider.overrideWith(
        (ref) => offlineApiClient(ref.watch(secureStorageServiceProvider))),
    profileRepositoryProvider.overrideWith((ref) => backend.repositoryFor(
        ref.watch(authControllerProvider
            .select((s) => s.isAuthenticated ? s.user?.id : null)))),
    appNotificationCenterProvider.overrideWith((ref) => QaNotificationCenter()),
    appDatabaseProvider.overrideWithValue(db),
    isOnlineProvider.overrideWith((ref) => Stream.value(true)),
    pendingOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
    voiceInputServiceProvider.overrideWithValue(voice),
    biometricServiceProvider.overrideWithValue(bio),
  ]);
  final app = QaApp(container, voice, auth, db, bio, journal);
  addTearDown(() => app.close(tester));
  if (signIn) {
    final ok = await container
        .read(authControllerProvider.notifier)
        .login(email: userA.email, password: qaPassword);
    expect(ok, isTrue, reason: 'fake sign-in');
  }
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const DualisApp(),
  ));
  if (settleMs > 0) await settle(tester, ms: settleMs);
  return app;
}
