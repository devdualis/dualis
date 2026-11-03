// Phase 11 Wave 3 (11-03-01): T-11-08..11 on a running app.
// Phase 11.1 (11.1-13): T-11.1-A..D (legal representation of adults, invite
// relationship and categories, category-scoped grantee view, hand-over at 18).
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
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/care/presentation/screens/care_hub_screen.dart';
import 'package:dualis_mobile/features/habits/presentation/screens/habits_screen.dart';
import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/features/profile/presentation/screens/add_dependent_modal.dart';
import 'package:dualis_mobile/features/profile/presentation/screens/family_sharing_screen.dart';
import 'package:dualis_mobile/features/profile/presentation/widgets/claim_profile_sheet.dart';
import 'package:dualis_mobile/features/profile/presentation/widgets/profile_selection_sheet.dart';
import 'package:dualis_mobile/features/profile/domain/models/shared_access_grant.dart';
import 'package:dualis_mobile/features/sync/presentation/widgets/offline_indicator_banner.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
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

typedef _App =
    ({
      ProviderContainer container,
      FakeProfileBackend backend,
      AuthController auth,
    });

/// Boots the real DualisApp signed in as [user]. [seed] runs on the fake
/// backend before the app starts (pre-existing grants or dependents).
Future<_App> _boot(
  WidgetTester tester, {
  UserProfile user = userA,
  void Function(FakeProfileBackend backend)? seed,
}) async {
  expect(
    FeatureFlags.premiumProfiles,
    isTrue,
    reason: 'run with --dart-define=PREMIUM_FEATURES=true',
  );

  // In-memory keychain: no real tokens on the simulator.
  FlutterSecureStorage.setMockInitialValues({});
  final backend = FakeProfileBackend();
  seed?.call(backend);
  final db = AppDatabase(NativeDatabase.memory());
  final container = _container(backend, db);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });

  final auth = container.read(authControllerProvider.notifier);
  expect(await auth.login(email: user.email, password: 'x'), isTrue);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const DualisApp()),
  );
  await _waitFor(tester, _pillShowing(user.name));
  return (container: container, backend: backend, auth: auth);
}

ProviderContainer _container(FakeProfileBackend backend, AppDatabase db) =>
    ProviderContainer(
      overrides: [
        premiumProfilesEnabledProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        apiClientProvider.overrideWith(
          (ref) => offlineApiClient(ref.watch(secureStorageServiceProvider)),
        ),
        profileRepositoryProvider.overrideWith(
          (ref) => backend.repositoryFor(
            ref.watch(
              authControllerProvider.select(
                (s) => s.isAuthenticated ? s.user?.id : null,
              ),
            ),
          ),
        ),
        appNotificationCenterProvider.overrideWith(
          (ref) => AppNotificationCenter(
            plugin: FlutterLocalNotificationsPlugin(),
            permissionPromptStore: AlreadyPromptedStore(),
          ),
        ),
        appDatabaseProvider.overrideWithValue(db),
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
        pendingOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
      ],
    );

Future<void> _switchUser(
  WidgetTester tester,
  AuthController auth,
  UserProfile user,
) async {
  await auth.logout();
  expect(await auth.login(email: user.email, password: 'x'), isTrue);
  await _waitFor(tester, _pillShowing(user.name));
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Navigator).first));

/// The urgent-help entry reachable with one tap. On /home the bottom bar's
/// emergency destination replaces the floating button (UrgentHelpOverlay
/// hides it there), elsewhere the floating button is shown.
Finder _oneTapHelp() =>
    find
        .byWidgetPredicate(
          (w) =>
              w.key == const Key('urgent_help_button') ||
              w.key == const Key('nav_destination_emergency'),
        )
        .hitTestable();

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
    await _tap(tester, _key('family-share-relationship'));
    await _tap(tester, _key('family-share-relationship-caregiver').last);
    // The invite is for the dependent: the guardian confirms (gap 9).
    await _tap(tester, _key('family-share-dependent-confirm'));
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

  testWidgets('T-11.1-A: adult under supported decision', (tester) async {
    final app = await _boot(tester);
    final container = app.container;
    final l10n = _l10n(tester);
    const name = 'Marta Apoio';
    const notes = 'Processo 0001234-56.2025.8.26.0100';

    await _openSwitcher(tester);
    await _tap(tester, _key('profile-add-dependent'));
    await _waitFor(tester, find.byType(AddDependentModal));
    final modalFields = find.descendant(
      of: find.byType(AddDependentModal),
      matching: find.byType(TextField),
    );
    await tester.enterText(modalFields.first, name);
    // 40 years ago: only the adult representation types are offered.
    await tester.enterText(
      find.descendant(
        of: _key('add-dependent-dob'),
        matching: find.byType(TextField),
      ),
      '1503${DateTime.now().year - 40}',
    );
    await tester.pump();
    await _waitFor(tester, _key('relationship-supported_decision'));
    expect(_key('relationship-curator'), findsOneWidget);
    expect(_key('relationship-parent'), findsNothing);
    expect(_key('relationship-legal_guardian'), findsNothing);
    await _tap(tester, _key('relationship-supported_decision'));

    // Adult: LGPD Art. 11, I consent, never the Art. 14 (minors) text.
    expect(_key('lgpd-art11-consent'), findsOneWidget);
    expect(_key('lgpd-art14-consent'), findsNothing);
    await tester.enterText(_key('add-dependent-notes'), notes);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_submitEnabled(tester), isFalse, reason: 'consent still off');
    await _tap(tester, _key('lgpd-art11-consent'));
    expect(_submitEnabled(tester), isTrue);

    await _tap(tester, _key('add-dependent-submit'));
    await _waitFor(tester, find.byType(AddDependentModal), present: false);
    await _waitFor(tester, find.byType(ProfileSelectionSheet), present: false);
    await _waitFor(tester, _pillShowing(name));
    final id =
        container.read(activeProfileControllerProvider).activeProfile!.id;
    expect(app.backend.legalBasisOf(id), 'lgpd_art_11_i');
    expect(app.backend.notesOf(id), notes);

    await _openSwitcher(tester);
    await _waitFor(tester, _inSwitcher(find.text(name)));
    expect(
      _inSwitcher(find.text(l10n.profileSwitcherBadgeAdult)),
      findsOneWidget,
    );
    expect(
      _key('legal-basis-banner-$id'),
      findsNothing,
      reason: 'registered under Art. 11, I: nothing to re-confirm',
    );
    expect(_key('handover-banner-$id'), findsNothing);
    await _closeSwitcher(tester);
  });

  testWidgets('T-11.1-B: invite with relationship and categories', (
    tester,
  ) async {
    final app = await _boot(tester);
    final l10n = _l10n(tester);

    await _openFamilySharing(tester);
    await _tap(tester, _key('family-share-invite-button'));
    await _waitFor(tester, _key('family-share-invite-profile'));
    expect(
      find.descendant(
        of: _key('family-share-invite-profile'),
        matching: find.text(userA.name),
      ),
      findsOneWidget,
      reason: 'invite defaults to the active (primary) profile',
    );
    await _tap(tester, _key('family-share-relationship'));
    await _tap(tester, _key('family-share-relationship-sibling').last);

    // Defaults (D2): habits only; the emotional journal is opt-in and
    // explained.
    bool checked(ShareCategory c) =>
        tester
            .widget<CheckboxListTile>(
              _key('family-share-category-${c.apiValue}'),
            )
            .value!;
    expect(
      [
        for (final c in ShareCategory.values)
          if (checked(c)) c,
      ],
      [ShareCategory.habits],
    );
    expect(_key('family-share-emotional-explanation'), findsOneWidget);
    expect(
      _key('family-share-dependent-confirm'),
      findsNothing,
      reason: 'own primary profile: no guardian confirmation',
    );

    await _tap(tester, _key('family-share-invite-generate'));
    await _waitFor(tester, _key('family-share-invite-code'));
    expect(
      tester.widget<SelectableText>(_key('family-share-invite-code')).data,
      app.backend.issuedCodes.single,
    );
    await _tap(tester, _key('family-share-invite-done'));

    final grantId =
        (await app.container.read(profileRepositoryProvider).fetchGrants())
            .outgoing
            .single
            .id;
    await _waitFor(tester, _key('grant-relationship-$grantId'));
    expect(
      tester.widget<Text>(_key('grant-relationship-$grantId')).data,
      l10n.familySharingRelationshipSibling,
    );
    expect(_key('grant-category-$grantId-habits'), findsOneWidget);
    expect(
      find.descendant(
        of: _key('grant-category-$grantId-habits'),
        matching: find.text(l10n.familySharingCategoryHabits),
      ),
      findsOneWidget,
    );
    for (final c in ShareCategory.values.where(
      (c) => c != ShareCategory.habits,
    )) {
      expect(_key('grant-category-$grantId-${c.apiValue}'), findsNothing);
    }
    await _leaveFamilySharing(tester);
  });

  testWidgets('T-11.1-C: grantee sees only granted areas', (tester) async {
    final app = await _boot(
      tester,
      user: userB,
      seed:
          (backend) => backend.seedAcceptedGrant(
            ownerUserId: userA.id,
            granteeUserId: userB.id,
            level: ProfileShareLevel.viewOnly,
            relationship: GrantRelationship.sibling,
            categories: const [ShareCategory.habits],
          ),
    );

    await _openSwitcher(tester);
    await _tap(tester, _inSwitcher(find.text(userA.name)));
    await _waitFor(tester, find.byType(ProfileSelectionSheet), present: false);
    await _waitFor(tester, _pillShowing(userA.name));
    final active =
        app.container.read(activeProfileControllerProvider).activeProfile!;
    expect(active.id, 'profile-${userA.id}');

    // Habits: shared, so the screen shows its content, not the placeholder.
    await _tap(tester, _key('nav_destination_habits'));
    await _waitFor(tester, find.byType(HabitsScreen));
    await _waitFor(
        tester,
        find.descendant(
            of: find.byType(HabitsScreen),
            matching: find.text(_l10n(tester).habitsTabToday)));
    expect(_key('category-not-shared'), findsNothing);
    expect(_oneTapHelp(), findsOneWidget);

    // Care: not in the grant, so the care hub shows the placeholder, and help
    // is still one tap away.
    await _tap(tester, _key('nav_destination_care'));
    await _waitFor(tester, find.byType(CareHubScreen));
    await _waitFor(tester, _key('category-not-shared'));
    expect(_oneTapHelp(), findsOneWidget);
  });

  testWidgets('T-11.1-D: hand-over at 18', (tester) async {
    late String dependentId;
    const name = 'Clara Jovem';
    final app = await _boot(
      tester,
      seed:
          (backend) =>
              dependentId = backend.seedHandoverDueDependent(userA.id, name),
    );
    final container = app.container;
    final l10n = _l10n(tester);

    // Guardian keeps access until the claim: make the dependent active.
    await _openSwitcher(tester);
    await _tap(tester, _inSwitcher(find.text(name)));
    await _waitFor(tester, _pillShowing(name));

    await _openSwitcher(tester);
    await _waitFor(tester, _key('handover-banner-$dependentId'));
    await _tap(tester, _key('handover-generate-$dependentId'));
    await _waitFor(tester, _key('handover-code-value'));
    final code =
        tester.widget<SelectableText>(_key('handover-code-value')).data!;
    expect(code, hasLength(10));
    await _tap(
      tester,
      find.descendant(
        of: _key('handover-code-dialog'),
        matching: find.text(l10n.profileSwitcherClose),
      ),
    );
    await _waitFor(tester, _key('handover-code-dialog'), present: false);
    await _closeSwitcher(tester);

    // The young adult signs in with their own account and claims it.
    await _switchUser(tester, app.auth, userC);
    await _openSwitcher(tester);
    await _tap(tester, _key('profile-claim-entry'));
    await _waitFor(tester, find.byType(ClaimProfileSheet));
    // Help stays one tap away with the claim sheet open (CONTEXT §4).
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('urgent_help_button')), findsOneWidget);
    expect(
      find.byKey(const Key('urgent_help_button')).hitTestable(),
      findsOneWidget,
    );
    await tester.enterText(_key('claim-code-field'), code);
    await tester.pump();
    await _tap(tester, _key('claim-code-submit'));
    await _waitFor(tester, find.byType(ClaimProfileSheet), present: false);
    await _waitFor(tester, find.byType(ProfileSelectionSheet), present: false);
    var state = container.read(activeProfileControllerProvider);
    expect(state.activeProfile?.id, dependentId);
    expect(
      state.activeProfile?.isPrimary,
      isTrue,
      reason: 'the claimed profile is now this account\'s own profile',
    );
    await _waitFor(tester, _pillShowing(name));

    // Back as the guardian: the profile is gone and the primary is active.
    await _switchUser(tester, app.auth, userA);
    state = container.read(activeProfileControllerProvider);
    expect(state.ownProfiles.map((p) => p.id), isNot(contains(dependentId)));
    expect(state.activeProfile?.id, 'profile-${userA.id}');
    await _openSwitcher(tester);
    expect(_inSwitcher(find.text(name)), findsNothing);
    expect(_key('handover-banner-$dependentId'), findsNothing);
    await _closeSwitcher(tester);
  });
}
