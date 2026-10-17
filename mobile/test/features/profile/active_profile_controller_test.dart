import 'dart:async';

import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/domain/models/shared_access_grant.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class FakeAuthController extends AuthController {
  final AuthState initial;
  FakeAuthController(this.initial);

  @override
  AuthState build() => initial;

  void set(AuthState next) => state = next;
}

AuthState signedIn(String userId) => AuthState(
      isAuthenticated: true,
      user: UserProfile(
        id: userId,
        name: 'User $userId',
        email: '$userId@test.com',
        gender: Gender.outro,
      ),
    );

const primary = Profile(
  id: 'primary',
  name: 'Titular',
  profileType: ProfileType.primary,
  ownership: ProfileOwnership.own,
  accessLevel: ProfileAccessLevel.owner,
);
const child = Profile(
  id: 'child',
  name: 'Ana',
  profileType: ProfileType.dependentMinor,
  ownership: ProfileOwnership.dependent,
  accessLevel: ProfileAccessLevel.owner,
);
const sharedGrandma = Profile(
  id: 'grandma',
  name: 'Vovó',
  profileType: ProfileType.primary,
  ownership: ProfileOwnership.shared,
  accessLevel: ProfileAccessLevel.viewOnly,
);

final incomingGrant = SharedAccessGrant(
  id: 'g-in',
  direction: GrantDirection.incoming,
  targetProfileId: 'grandma',
  targetProfileName: 'Vovó',
  accessLevel: ProfileShareLevel.viewOnly,
  status: GrantStatus.accepted,
  expiresAt: DateTime(2026, 10, 16),
);
final outgoingGrant = SharedAccessGrant(
  id: 'g-out',
  direction: GrantDirection.outgoing,
  targetProfileId: 'child',
  targetProfileName: 'Ana',
  accessLevel: ProfileShareLevel.coManage,
  status: GrantStatus.accepted,
  expiresAt: DateTime(2026, 10, 16),
  inviteCode: 'ABC123',
);

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late MockProfileRepository repo;
  late FakeAuthController auth;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(ProfileShareLevel.viewOnly);
  });

  ActiveProfileController notifier() =>
      container.read(activeProfileControllerProvider.notifier);
  ActiveProfileState current() => container.read(activeProfileControllerProvider);

  void serve(List<Profile> profiles,
      {List<SharedAccessGrant> outgoing = const [],
      List<SharedAccessGrant> incoming = const []}) {
    when(() => repo.fetchProfiles()).thenAnswer((_) async => profiles);
    when(() => repo.fetchGrants()).thenAnswer((_) async =>
        FamilySharingGrants(outgoing: outgoing, incoming: incoming));
  }

  Future<void> start(AuthState authState) async {
    auth = FakeAuthController(authState);
    container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(() => auth),
      profileRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    container.listen(activeProfileControllerProvider, (_, _) {});
    await settle();
  }

  setUp(() {
    repo = MockProfileRepository();
    when(() => repo.readActiveProfileId(any())).thenAnswer((_) async => null);
    when(() => repo.saveActiveProfileId(any(), any())).thenAnswer((_) async {});
  });

  test('signed out: empty state and no API calls', () async {
    await start(const AuthState.initial());

    expect(current().profiles, isEmpty);
    expect(current().activeProfile, isNull);
    verifyNever(() => repo.fetchProfiles());
  });

  test('signed in: loads profiles and grants, falls back to primary', () async {
    serve([primary, child, sharedGrandma],
        outgoing: [outgoingGrant], incoming: [incomingGrant]);
    await start(signedIn('u1'));

    final s = current();
    expect(s.isLoading, isFalse);
    expect(s.profiles, hasLength(3));
    expect(s.ownProfiles.map((p) => p.id), ['primary', 'child']);
    expect(s.sharedProfiles.single.id, 'grandma');
    expect(s.outgoingGrants.single.id, 'g-out');
    expect(s.incomingGrants.single.id, 'g-in');
    expect(s.activeProfile?.id, 'primary');
  });

  test('restores the stored selection for this user', () async {
    when(() => repo.readActiveProfileId('u1'))
        .thenAnswer((_) async => 'child');
    serve([primary, child]);
    await start(signedIn('u1'));

    expect(current().activeProfileId, 'child');
  });

  test('ignores a stored selection that is no longer accessible', () async {
    when(() => repo.readActiveProfileId('u1'))
        .thenAnswer((_) async => 'gone');
    serve([primary, child]);
    await start(signedIn('u1'));

    expect(current().activeProfileId, isNull);
    expect(current().activeProfile?.id, 'primary');
    verify(() => repo.saveActiveProfileId('u1', null)).called(1);
  });

  test('selectProfile switches and persists per user; unknown ids ignored',
      () async {
    serve([primary, child]);
    await start(signedIn('u1'));

    notifier().selectProfile('child');
    expect(current().activeProfile?.id, 'child');
    verify(() => repo.saveActiveProfileId('u1', 'child')).called(1);

    notifier().selectProfile('nope');
    expect(current().activeProfile?.id, 'child');
  });

  test('logout clears all profile data; another user starts fresh', () async {
    serve([primary, child, sharedGrandma], incoming: [incomingGrant]);
    await start(signedIn('u1'));
    notifier().selectProfile('child');

    auth.set(const AuthState.initial());
    await settle();
    expect(current().profiles, isEmpty);
    expect(current().incomingGrants, isEmpty);
    expect(current().activeProfileId, isNull);

    serve([primary]);
    auth.set(signedIn('u2'));
    await settle();
    expect(current().profiles.single.id, 'primary');
    expect(current().activeProfileId, isNull);
    verify(() => repo.readActiveProfileId('u2')).called(1);
  });

  test('a response for a logged-out session is dropped', () async {
    final pending = Completer<List<Profile>>();
    when(() => repo.fetchProfiles()).thenAnswer((_) => pending.future);
    when(() => repo.fetchGrants())
        .thenAnswer((_) async => const FamilySharingGrants());
    await start(signedIn('u1'));

    auth.set(const AuthState.initial());
    await settle();
    pending.complete([primary, child]);
    await settle();

    expect(current().profiles, isEmpty);
  });

  test('refresh failure lands in errorMessage', () async {
    when(() => repo.fetchProfiles()).thenThrow(
        const ProfileApiException('Falhou', statusCode: 500));
    when(() => repo.fetchGrants())
        .thenAnswer((_) async => const FamilySharingGrants());
    await start(signedIn('u1'));

    expect(current().isLoading, isFalse);
    expect(current().errorMessage, 'Falhou');
  });

  test('createDependent makes the new dependent active', () async {
    serve([primary]);
    await start(signedIn('u1'));
    when(() => repo.createDependent(
          name: any(named: 'name'),
          dateOfBirth: any(named: 'dateOfBirth'),
          gender: any(named: 'gender'),
          relationshipType: any(named: 'relationshipType'),
          lgpdConsent: any(named: 'lgpdConsent'),
        )).thenAnswer((_) async => child);
    serve([primary, child]);

    final created = await notifier().createDependent(
      name: 'Ana',
      dateOfBirth: DateTime(2018, 3, 9),
      gender: 'feminino',
      relationshipType: 'parent',
      lgpdConsent: true,
    );

    expect(created.id, 'child');
    expect(current().profiles.map((p) => p.id), ['primary', 'child']);
    expect(current().activeProfile?.id, 'child');
    verify(() => repo.saveActiveProfileId('u1', 'child')).called(1);
  });

  test('mutation errors are rethrown with the backend message', () async {
    serve([primary, child]);
    await start(signedIn('u1'));
    when(() => repo.deleteProfile('primary')).thenThrow(const ProfileApiException(
        'O perfil principal não pode ser excluído.',
        statusCode: 400));

    await expectLater(
      notifier().deleteProfile('primary'),
      throwsA(isA<ProfileApiException>().having((e) => e.message, 'message',
          'O perfil principal não pode ser excluído.')),
    );
    expect(current().profiles, hasLength(2));
  });

  test('deleteProfile of the active dependent falls back to primary', () async {
    when(() => repo.readActiveProfileId('u1'))
        .thenAnswer((_) async => 'child');
    serve([primary, child]);
    await start(signedIn('u1'));
    when(() => repo.deleteProfile('child')).thenAnswer((_) async {});
    serve([primary]);

    await notifier().deleteProfile('child');

    expect(current().profiles.single.id, 'primary');
    expect(current().activeProfile?.id, 'primary');
  });

  test('updateProfileName replaces the profile in state', () async {
    serve([primary, child]);
    await start(signedIn('u1'));
    when(() => repo.updateProfileName('child', 'Ana Clara')).thenAnswer(
        (_) async => const Profile(
              id: 'child',
              name: 'Ana Clara',
              profileType: ProfileType.dependentMinor,
              ownership: ProfileOwnership.dependent,
              accessLevel: ProfileAccessLevel.owner,
            ));

    await notifier().updateProfileName('child', 'Ana Clara');

    expect(current().profiles[1].name, 'Ana Clara');
  });

  test('createInvite adds the pending grant with the profile name', () async {
    serve([primary, child]);
    await start(signedIn('u1'));
    final pendingGrant = SharedAccessGrant(
      id: 'g-new',
      direction: GrantDirection.outgoing,
      targetProfileId: 'child',
      targetProfileName: 'Ana',
      accessLevel: ProfileShareLevel.viewOnly,
      status: GrantStatus.pending,
      expiresAt: DateTime(2026, 10, 16),
      inviteCode: 'NEW123',
    );
    when(() => repo.createInvite(
          targetProfileId: 'child',
          accessLevel: ProfileShareLevel.viewOnly,
          targetProfileName: 'Ana',
        )).thenAnswer((_) async => pendingGrant);

    final grant = await notifier().createInvite(
        targetProfileId: 'child', accessLevel: ProfileShareLevel.viewOnly);

    expect(grant.inviteCode, 'NEW123');
    expect(current().outgoingGrants.first.id, 'g-new');
  });

  test('acceptInvite refreshes so the shared profile appears', () async {
    serve([primary]);
    await start(signedIn('u1'));
    when(() => repo.acceptInvite('ABC123')).thenAnswer((_) async {});
    serve([primary, sharedGrandma], incoming: [incomingGrant]);

    await notifier().acceptInvite(' ABC123 ');

    expect(current().sharedProfiles.single.id, 'grandma');
    expect(current().incomingGrants.single.id, 'g-in');
  });

  test('revoking an incoming grant removes the shared profile at once',
      () async {
    serve([primary, sharedGrandma], incoming: [incomingGrant]);
    await start(signedIn('u1'));
    notifier().selectProfile('grandma');
    when(() => repo.revokeGrant('g-in')).thenAnswer((_) async {});
    // The follow-up refresh never completes: state must already be updated.
    when(() => repo.fetchProfiles())
        .thenAnswer((_) => Completer<List<Profile>>().future);

    unawaited(notifier().revokeGrant('g-in'));
    await settle();

    expect(current().sharedProfiles, isEmpty);
    expect(current().incomingGrants, isEmpty);
    expect(current().activeProfile?.id, 'primary');
    verify(() => repo.saveActiveProfileId('u1', null)).called(1);
  });

  test('revoking an outgoing grant marks it revoked', () async {
    serve([primary, child], outgoing: [outgoingGrant]);
    await start(signedIn('u1'));
    when(() => repo.revokeGrant('g-out')).thenAnswer((_) async {});
    when(() => repo.fetchProfiles())
        .thenAnswer((_) => Completer<List<Profile>>().future);

    unawaited(notifier().revokeGrant('g-out'));
    await settle();

    expect(current().outgoingGrants.single.status, GrantStatus.revoked);
    expect(current().outgoingGrants.single.isActive, isFalse);
    expect(current().profiles, hasLength(2));
  });
}
