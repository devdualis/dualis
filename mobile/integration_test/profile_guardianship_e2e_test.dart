// Phase 11 Wave 3 (11-03-01): T-11-08..11 on a running app.
//
// Boots the real DualisApp (real router, HomeScreen, AuthController) with the
// premium flag on. The profile API is an in-memory fake with the Wave 1 rules
// and every other HTTP call fails as offline, so no backend is reached.
//
//   flutter test integration_test/profile_guardianship_e2e_test.dart \
//     -d <simulator> --dart-define=PREMIUM_FEATURES=true
import 'package:drift/native.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/core/notifications/app_notification_center.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/features/profile/presentation/screens/add_dependent_modal.dart';
import 'package:dualis_mobile/features/profile/presentation/screens/family_sharing_screen.dart';
import 'package:dualis_mobile/features/profile/presentation/widgets/profile_selection_sheet.dart';
import 'package:dualis_mobile/features/sync/presentation/widgets/offline_indicator_banner.dart';
import 'package:dualis_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/profile_fakes.dart';

const _dependentName = 'Lucas Teste';

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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
}

bool _submitEnabled(WidgetTester tester) => tester
    .widget<FilledButton>(find.descendant(
        of: _key('add-dependent-submit'), matching: find.byType(FilledButton)))
    .enabled;

Finder _pillShowing(String name) =>
    find.descendant(of: _key('profile-app-bar-pill'), matching: find.text(name));

Finder _inSwitcher(Finder matching) =>
    find.descendant(of: find.byType(ProfileSelectionSheet), matching: matching);

Future<void> _openSwitcher(WidgetTester tester) async {
  await _tap(tester, _key('profile-app-bar-pill'));
  await _waitFor(tester, find.byType(ProfileSelectionSheet));
}

Future<void> _closeSwitcher(WidgetTester tester) async {
  await _tap(tester, _inSwitcher(find.byIcon(Icons.close)));
  await _waitFor(tester, find.byType(ProfileSelectionSheet), present: false);
}

Future<void> _openFamilySharing(WidgetTester tester) async {
  await _openSwitcher(tester);
  await _tap(tester, _key('profile-manage-sharing'));
  await _waitFor(tester, find.byType(FamilySharingScreen));
}

Future<void> _leaveFamilySharing(WidgetTester tester) async {
  await _tap(tester, find.byType(BackButton));
  await _waitFor(tester, find.byType(FamilySharingScreen), present: false);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('T-11-08..11: consent gate, dependent, view-only share, revoke',
      (tester) async {
    expect(FeatureFlags.premiumProfiles, isTrue,
        reason: 'run with --dart-define=PREMIUM_FEATURES=true');

    // In-memory keychain: no real tokens on the simulator.
    FlutterSecureStorage.setMockInitialValues({});
    final backend = FakeProfileBackend();
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      premiumProfilesEnabledProvider.overrideWithValue(true),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      apiClientProvider.overrideWith(
          (ref) => offlineApiClient(ref.watch(secureStorageServiceProvider))),
      profileRepositoryProvider.overrideWith((ref) => backend.repositoryFor(
          ref.watch(authControllerProvider
              .select((s) => s.isAuthenticated ? s.user?.id : null)))),
      appNotificationCenterProvider.overrideWith((ref) => AppNotificationCenter(
            plugin: FlutterLocalNotificationsPlugin(),
            permissionPromptStore: AlreadyPromptedStore(),
          )),
      appDatabaseProvider.overrideWithValue(db),
      isOnlineProvider.overrideWith((ref) => Stream.value(true)),
      pendingOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final auth = container.read(authControllerProvider.notifier);
    expect(await auth.login(email: userA.email, password: 'x'), isTrue);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const DualisApp(),
    ));
    await _waitFor(tester, _pillShowing(userA.name));

    // ---- Beat 1 (T-11-08): submit stays disabled until Art. 14 consent ----
    await _openSwitcher(tester);
    await _tap(tester, _key('profile-add-dependent'));
    await _waitFor(tester, find.byType(AddDependentModal));

    final modalFields = find.descendant(
        of: find.byType(AddDependentModal), matching: find.byType(TextField));
    await tester.enterText(modalFields.first, _dependentName);
    await tester.enterText(
        find.descendant(
            of: _key('add-dependent-dob'), matching: find.byType(TextField)),
        '15032018');
    await tester.pump();
    await _tap(
        tester,
        find
            .descendant(
                of: _key('add-dependent-relationship'),
                matching: find.byType(InkWell))
            .first);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));

    expect(_submitEnabled(tester), isFalse,
        reason: 'name, date and relationship filled, consent still off');
    await _tap(tester, _key('add-dependent-submit'));
    expect(find.byType(AddDependentModal), findsOneWidget);
    expect(container.read(activeProfileControllerProvider).ownProfiles,
        hasLength(1),
        reason: 'blocked tap must not create a dependent');

    await _tap(tester, _key('lgpd-art14-consent'));
    expect(_submitEnabled(tester), isTrue);

    // ---- Beat 2 (T-11-09): submit, pill shows the dependent ----
    await _tap(tester, _key('add-dependent-submit'));
    await _waitFor(tester, find.byType(AddDependentModal), present: false);
    await _waitFor(tester, find.byType(ProfileSelectionSheet), present: false);
    await _waitFor(tester, _pillShowing(_dependentName));
    final dependentId =
        container.read(activeProfileControllerProvider).activeProfile!.id;

    // ---- Beat 3 (T-11-10): A invites VIEW_ONLY, B accepts, no edit/delete ----
    await _openFamilySharing(tester);
    await _tap(tester, _key('family-share-invite-button'));
    await _waitFor(tester, _key('family-share-invite-profile'));
    expect(
        find.descendant(
            of: _key('family-share-invite-profile'),
            matching: find.text(_dependentName)),
        findsOneWidget,
        reason: 'invite defaults to the active (dependent) profile');
    await _tap(tester, _key('family-share-scope-viewOnly'));
    await _tap(tester, _key('family-share-invite-generate'));
    await _waitFor(tester, _key('family-share-invite-code'));
    final code =
        tester.widget<SelectableText>(_key('family-share-invite-code')).data!;
    expect(code, backend.issuedCodes.single);
    await _tap(tester, _key('family-share-invite-done'));
    await _leaveFamilySharing(tester);

    // Switch the session to user B (fake auth backend).
    await auth.logout();
    expect(await auth.login(email: userB.email, password: 'x'), isTrue);
    await _waitFor(tester, _pillShowing(userB.name));

    await _openFamilySharing(tester);
    await _tap(tester, _key('family-share-tab-incoming'));
    await _tap(tester, _key('family-share-accept-button'));
    await _waitFor(tester, _key('invite-code-field'));
    await tester.enterText(_key('invite-code-field'), code);
    await tester.pump();
    await _tap(tester, _key('invite-code-submit'));
    await _waitFor(tester, _key('invite-code-field'), present: false);
    await _waitFor(tester, _key('family-share-revoke'));
    await _leaveFamilySharing(tester);

    await _openSwitcher(tester);
    await _waitFor(tester, _inSwitcher(find.text(_dependentName)));
    final ownPrimaryId = 'profile-${userB.id}';
    expect(_key('profile-edit-$ownPrimaryId'), findsOneWidget,
        reason: 'sanity: edit key renders for profiles B can edit');
    expect(_key('profile-edit-$dependentId'), findsNothing);
    expect(_key('profile-delete-$dependentId'), findsNothing);
    await _closeSwitcher(tester);

    // ---- Beat 4 (T-11-11): B revokes, profile leaves switcher same session --
    await _openFamilySharing(tester);
    await _tap(tester, _key('family-share-tab-incoming'));
    await _tap(tester, _key('family-share-revoke'));
    await _tap(tester, _key('family-share-revoke-confirm'));
    await _waitFor(tester, _key('family-share-revoke'), present: false);
    await _leaveFamilySharing(tester);

    await _openSwitcher(tester);
    expect(_inSwitcher(find.text(_dependentName)), findsNothing);
    expect(container.read(activeProfileControllerProvider).sharedProfiles,
        isEmpty);
    expect(container.read(authControllerProvider).user?.id, userB.id,
        reason: 'revoke happened without a new sign-in');
    await _closeSwitcher(tester);
  });
}
