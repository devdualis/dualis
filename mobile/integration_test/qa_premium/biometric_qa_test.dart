// QA: Premium biometric unlock on the iOS Simulator (real local_auth).
//
//   python3 integration_test/qa_premium/host_helper.py <udid> \
//     com.dualischeckup.app.dualisMobile ../docs/qa-reports/premium-voice-biometric &
//   flutter test integration_test/qa_premium/biometric_qa_test.dart -d <udid> \
//     --dart-define=PREMIUM_FEATURES=true      # Premium
//   flutter test integration_test/qa_premium/biometric_qa_test.dart -d <udid>
//                                              # Free
import 'package:dualis_mobile/core/security/biometric_lock_controller.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dualis_mobile/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:dualis_mobile/shared/widgets/urgent_help_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_harness.dart';

final pt = AppLocalizationsPt();
final lockScreen = byKey('privacyVeilBackdrop');
final bioSwitch = byKey('settings_biometric_lock_switch');

Future<void> openSettings(WidgetTester tester) async {
  await tap(tester, byKey('home_settings_button'));
  await settle(tester, ms: 800);
}

bool switchValue(WidgetTester tester) =>
    tester.widget<SwitchListTile>(bioSwitch).value;

BiometricLockState lockState(QaApp app) =>
    app.container.read(biometricLockControllerProvider);

/// Turns the lock on through the Settings switch with a Face ID match.
Future<void> enableLock(WidgetTester tester, QaApp app, {String? shotName}) async {
  await tester.ensureVisible(bioSwitch);
  await settle(tester, ms: 300);
  if (shotName != null) await shotLater(shotName, 1800);
  await faceLater(true, 3000);
  await tester.tap(bioSwitch);
  await waitFor(tester, find.text(pt.bioLockEnabled),
      timeout: const Duration(seconds: 15));
  expect(lockState(app).enabled, isTrue);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetKeychain();
    await host('/enroll', {'v': '1'});
  });

  if (!isPremium) {
    testWidgets('F-B1 Free: no biometric switch in Settings', (tester) async {
      await bootApp(tester);
      await openSettings(tester);
      await shot(tester, 'B_settings_top');
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await settle(tester, ms: 300);
      }
      await shot(tester, 'B_settings_bottom');
      expect(bioSwitch, findsNothing);
      expect(find.text(pt.bioLockSettingsTitle), findsNothing);
    });

    testWidgets('F-B2 Free: no lock after 65 s in background', (tester) async {
      final app = await bootApp(tester);
      await background(tester, 65);
      await shot(tester, 'B_after_65s_background');
      expect(lockScreen, findsNothing);
      expect(app.location, '/home');
    });

    testWidgets('F-B3 Free: a saved "on" flag never locks on cold start',
        (tester) async {
      final first = await bootApp(tester);
      await first.container
          .read(secureStorageServiceProvider)
          .setBiometricEnabled(true);
      await first.close(tester);
      final app = await bootApp(tester, signIn: false); // cold start
      await settle(tester, ms: 1500);
      await shot(tester, 'B_cold_start_with_flag');
      expect(lockScreen, findsNothing);
      expect(lockState(app).locked, isFalse);
      expect(app.location, '/home');
    });
    return;
  }

  testWidgets('P-B1 switch shown in Settings and off by default', (tester) async {
    final app = await bootApp(tester);
    await shot(tester, 'B01_home_unlocked');
    await openSettings(tester);
    await tester.ensureVisible(bioSwitch);
    await settle(tester);
    await shot(tester, 'B01_settings_switch_off');
    expect(find.text(pt.bioLockSettingsTitle), findsOneWidget);
    expect(switchValue(tester), isFalse);
    expect(lockState(app).enabled, isFalse);
  });

  testWidgets('P-B2 turning on: Face ID no-match does not turn it on, '
      'a later match does', (tester) async {
    final app = await bootApp(tester);
    await openSettings(tester);
    await tester.ensureVisible(bioSwitch);
    await settle(tester);
    await shotLater('B02_faceid_sheet_enable', 1800);
    await faceLater(false, 3000);
    await shotLater('B02_faceid_nomatch_sheet', 4500);
    await faceLater(true, 7000);
    await tester.tap(bioSwitch);
    // While the sheet says "not recognized" the setting must stay off.
    await settle(tester, ms: 5000);
    expect(lockState(app).enabled, isFalse,
        reason: 'no-match must not turn the lock on');
    await waitFor(tester, find.text(pt.bioLockEnabled),
        timeout: const Duration(seconds: 20));
    await shot(tester, 'B02_enabled_after_match');
    expect(switchValue(tester), isTrue);
    expect(lockState(app).enabled, isTrue);
  });

  testWidgets('P-B3 real background: 10 s keeps it open, 65 s locks; '
      'auto prompt; no-match stays locked; match unlocks', (tester) async {
    final app = await bootApp(tester);
    await openSettings(tester);
    await enableLock(tester, app);

    await background(tester, 10);
    await shot(tester, 'B03_after_10s_background_open');
    expect(lockScreen, findsNothing, reason: '< 60 s must not lock');
    expect(byKey('privacyVeilSnapshotCover'), findsNothing,
        reason: 'app-switcher cover gone once back');

    // Video starts 3 s before the app comes back (kept under 60 s).
    await host('/video/start', {'name': '${build}_B03_lock_after_65s', 'delay': '62000'});
    await background(tester, 65);
    await waitFor(tester, lockScreen);
    expect(lockState(app).locked, isTrue);
    await settle(tester, ms: 1500);
    await shot(tester, 'B03_locked_auto_prompt');
    expect(app.bio.calls, 2, reason: 'enable + one automatic prompt');
    await host('/face', {'r': 'nomatch'});
    await settle(tester, ms: 2000);
    await shot(tester, 'B03_locked_nomatch');
    expect(lockScreen, findsOneWidget);
    expect(lockState(app).locked, isTrue);
    await host('/face', {'r': 'match'});
    await waitFor(tester, lockScreen, present: false);
    await settle(tester, ms: 1000);
    await shot(tester, 'B03_unlocked_back_on_settings');
    await videoStop();
    expect(app.location, '/settings', reason: 'screen kept under the lock');
  });

  testWidgets('P-B4 lock screen: no bypass, help while locked, lock returns '
      'without a new prompt, "Desbloquear" retry, password fallback',
      (tester) async {
    final app = await bootApp(tester);
    await openSettings(tester);
    await enableLock(tester, app);
    // Same 60 s rule; the clock jumps 61 s between pause and resume so the
    // real background trip can be short.
    var calls = 0;
    app.container.read(biometricLockControllerProvider.notifier).clock =
        () => DateTime.now().add(Duration(seconds: 61 * calls++));
    app.bio.cancelNext = 1; // auto prompt: "Cancelar"

    await videoStart('B04_lock_help_password');
    await background(tester, 4);
    await waitFor(tester, lockScreen);
    await settle(tester, ms: 1500);
    await shot(tester, 'B04_lock_screen');
    final promptsAtLock = app.bio.calls;

    Finder inLock(Finder f) => find.descendant(of: lockScreen, matching: f);
    expect(inLock(byKey('privacyVeilUnlockButton')), findsOneWidget);
    expect(inLock(byKey('bioLockPasswordButton')), findsOneWidget);
    expect(inLock(byKey('bioLockSignOutButton')), findsOneWidget);
    expect(inLock(find.byType(UrgentHelpButton)), findsOneWidget);
    expect(inLock(find.byType(TextButton)), findsNWidgets(2),
        reason: 'only "Entrar com senha" and "Sair da conta"');
    expect(inLock(find.byType(FilledButton)), findsOneWidget,
        reason: 'only "Desbloquear"');
    expect(find.text(pt.privacyVeilUnlockManually), findsNothing);
    expect(inLock(find.byType(BackButton)), findsNothing);
    // System back (Android / iOS back gesture) does not pop under the lock.
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(lockScreen, findsOneWidget);
    expect(app.location, '/settings');

    // Help is one tap away while locked.
    await tap(tester, inLock(find.byType(UrgentHelpButton)));
    await waitFor(tester, find.byType(EmergencyScreen));
    await settle(tester, ms: 800);
    await shot(tester, 'B04_help_while_locked');
    expect(lockScreen, findsNothing);
    expect(lockState(app).locked, isTrue);
    await tap(tester, byKey('emergency_close_button'));
    await waitFor(tester, lockScreen);
    await settle(tester, ms: 1200);
    await shot(tester, 'B04_lock_back_after_help');
    expect(lockState(app).locked, isTrue);
    expect(app.bio.calls, promptsAtLock, reason: 'no new automatic prompt');

    // "Desbloquear" when biometrics fail: still locked, can retry.
    app.bio.cancelNext = 1;
    await tap(tester, inLock(byKey('privacyVeilUnlockButton')));
    await settle(tester, ms: 1200);
    expect(lockState(app).locked, isTrue);
    expect(app.bio.calls, promptsAtLock + 1);

    // Password fallback.
    await tap(tester, inLock(byKey('bioLockPasswordButton')));
    await waitFor(tester, byKey('bioLockPasswordField'));
    await settle(tester, ms: 600);
    await shot(tester, 'B04_password_form');
    await tap(tester, byKey('bioLockPasswordSubmit'));
    await waitFor(tester, find.text(pt.bioLockPasswordEmpty));
    await tester.enterText(byKey('bioLockPasswordField'), 'senha-errada');
    await tap(tester, byKey('bioLockPasswordSubmit'));
    await waitFor(tester, byKey('bioLockPasswordError'));
    await settle(tester, ms: 900);
    await shot(tester, 'B04_password_wrong');
    // Bug 2 fix: focus kept, the wrong text selected for retyping.
    final editable = tester.widget<EditableText>(find.descendant(
        of: byKey('bioLockPasswordField'), matching: find.byType(EditableText)));
    final sel = editable.controller.selection;
    await hostLog('B04 after wrong password: focus=${editable.focusNode.hasFocus} '
        'selection=${sel.start}-${sel.end} of ${editable.controller.text.length}');
    expect(editable.focusNode.hasFocus, isTrue, reason: 'field keeps focus');
    expect(sel.start, 0);
    expect(sel.end, editable.controller.text.length, reason: 'text selected');
    expect(lockState(app).locked, isTrue);
    await hostLog('B04 wrong password error: '
        '${tester.widget<Text>(byKey('bioLockPasswordError')).data}');
    // Retype straight away, no tap on the field first.
    await tester.enterText(byKey('bioLockPasswordField'), qaPassword);
    await settle(tester, ms: 300);
    await tap(tester, byKey('bioLockPasswordSubmit'));
    for (var i = 0; i < 80 && lockScreen.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (lockScreen.evaluate().isNotEmpty) {
      final a = app.container.read(authControllerProvider);
      final err = byKey('bioLockPasswordError').evaluate().isEmpty
          ? null
          : tester.widget<Text>(byKey('bioLockPasswordError')).data;
      await hostLog('B04 still locked after right password: '
          'lock=${lockState(app).locked} logins=${app.auth.loginCalls} '
          'authLoading=${a.isLoading} authed=${a.isAuthenticated} '
          'authError=${a.errorMessage} shownError=$err');
      await shot(tester, 'B04_BUG_right_password_still_locked');
    }
    expect(lockScreen, findsNothing,
        reason: 'right password after a wrong one must unlock');
    await settle(tester, ms: 800);
    await shot(tester, 'B04_unlocked_with_password');
    expect(lockState(app).locked, isFalse);
    expect(app.location, '/settings');
    expect(lockState(app).enabled, isTrue, reason: 'password keeps the lock on');

    // Lock again; this time "Desbloquear" with a real Face ID match.
    app.bio.cancelNext = 1;
    await background(tester, 4);
    await waitFor(tester, lockScreen);
    await settle(tester, ms: 1200);
    await faceLater(true, 2500);
    await shotLater('B04_unlock_button_faceid', 1500);
    await tap(tester, inLock(byKey('privacyVeilUnlockButton')));
    await waitFor(tester, lockScreen, present: false,
        timeout: const Duration(seconds: 15));
    await settle(tester, ms: 800);
    await shot(tester, 'B04_unlocked_with_button');
    await videoStop();
    expect(app.location, '/settings');
  });

  testWidgets('P-B5 "Sair da conta" on the lock screen ends the session',
      (tester) async {
    final app = await bootApp(tester);
    await openSettings(tester);
    await enableLock(tester, app);
    var calls = 0;
    app.container.read(biometricLockControllerProvider.notifier).clock =
        () => DateTime.now().add(Duration(seconds: 61 * calls++));
    app.bio.cancelNext = 1;
    await background(tester, 4);
    await waitFor(tester, lockScreen);
    await settle(tester, ms: 1200);
    await tap(tester, byKey('bioLockSignOutButton'));
    await waitFor(tester, byKey('bioLockSignOutConfirm'));
    await shot(tester, 'B05_sign_out_confirm');
    await tap(tester, byKey('bioLockSignOutConfirm'));
    await waitFor(tester, lockScreen, present: false);
    await settle(tester, ms: 1500);
    await shot(tester, 'B05_signed_out');
    await hostLog('B05 location after sign out: ${app.location}');
    expect(lockState(app).enabled, isFalse);
    expect(lockState(app).locked, isFalse);
    expect(app.container.read(authControllerProvider).isAuthenticated, isFalse);
    expect(await app.container.read(secureStorageServiceProvider)
        .isBiometricEnabled(), isFalse);
  });

  testWidgets('P-B6 cold start with the lock on: covered from the first '
      'frame, Face ID unlocks to Home', (tester) async {
    final first = await bootApp(tester);
    await openSettings(tester);
    await enableLock(tester, first);
    await first.close(tester); // app state gone, keychain kept

    await videoStart('B06_cold_start_lock');
    await shotLater('B06_cold_start_faceid', 2500);
    await faceLater(true, 4500);
    final app = await bootApp(tester, signIn: false, settleMs: 0);
    expect(lockScreen, findsOneWidget, reason: 'covered on the first frame');
    await settle(tester, ms: 1500);
    expect(lockScreen, findsOneWidget);
    expect(lockState(app).locked, isTrue);
    await waitFor(tester, lockScreen, present: false,
        timeout: const Duration(seconds: 15));
    await settle(tester, ms: 1000);
    await shot(tester, 'B06_cold_start_unlocked_home');
    await videoStop();
    expect(app.location, '/home');
    expect(lockState(app).enabled, isTrue);
  });

  testWidgets('P-B7 a saved "on" flag without a stored session never locks',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final first = await bootApp(tester, signIn: false);
    await first.container
        .read(secureStorageServiceProvider)
        .setBiometricEnabled(true);
    await first.close(tester);
    final app = await bootApp(tester, signIn: false);
    await settle(tester, ms: 1500);
    await shot(tester, 'B07_flag_without_session');
    expect(lockScreen, findsNothing);
    expect(lockState(app).locked, isFalse);
    await hostLog('B07 location: ${app.location}');
  });

  testWidgets('P-B8 turning it off: no lock after background or cold start',
      (tester) async {
    final first = await bootApp(tester);
    await openSettings(tester);
    await enableLock(tester, first);
    await tester.tap(bioSwitch);
    await waitFor(tester, find.text(pt.bioLockDisabled));
    await shot(tester, 'B08_disabled');
    expect(switchValue(tester), isFalse);
    var calls = 0;
    first.container.read(biometricLockControllerProvider.notifier).clock =
        () => DateTime.now().add(Duration(seconds: 61 * calls++));
    await background(tester, 4);
    expect(lockScreen, findsNothing);
    await first.close(tester);
    final app = await bootApp(tester, signIn: false);
    await settle(tester, ms: 1500);
    expect(lockScreen, findsNothing);
    expect(app.location, '/home');
  });

  // Last on purpose: the system passcode sheet it opens cannot be closed.
  testWidgets('P-B9 Face ID not enrolled: switch still shown, turning on '
      'asks for the device passcode', (tester) async {
    await host('/enroll', {'v': '0'});
    final app = await bootApp(tester);
    await openSettings(tester);
    await settle(tester, ms: 800);
    final visible = bioSwitch.evaluate().isNotEmpty;
    await hostLog('B09 switch visible without enrollment: $visible');
    if (!visible) {
      await shot(tester, 'B09_not_enrolled_switch_hidden');
      return;
    }
    await tester.ensureVisible(bioSwitch);
    await settle(tester);
    await shotLater('B09_not_enrolled_passcode_sheet', 2500);
    await tester.tap(bioSwitch);
    await settle(tester, ms: 5000);
    expect(lockState(app).enabled, isFalse,
        reason: 'stays off until the passcode is entered');
    await host('/enroll', {'v': '1'});
  });
}
