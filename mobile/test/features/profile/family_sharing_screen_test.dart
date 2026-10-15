import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/domain/models/shared_access_grant.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/features/profile/presentation/screens/family_sharing_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

const _me = Profile(
  id: 'p-me',
  name: 'Ricardo',
  profileType: ProfileType.primary,
  ownership: ProfileOwnership.own,
  accessLevel: ProfileAccessLevel.owner,
);

const _kid = Profile(
  id: 'p-kid',
  name: 'Lucas',
  profileType: ProfileType.dependentMinor,
  ownership: ProfileOwnership.dependent,
  accessLevel: ProfileAccessLevel.owner,
);

SharedAccessGrant _grant(
  String id,
  GrantDirection direction,
  String name, {
  GrantStatus status = GrantStatus.accepted,
  DateTime? expiresAt,
  String? code,
}) =>
    SharedAccessGrant(
      id: id,
      direction: direction,
      targetProfileId: 'target-$id',
      targetProfileName: name,
      accessLevel: ProfileShareLevel.viewOnly,
      status: status,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 72)),
      inviteCode: code,
      acceptedAt: status == GrantStatus.accepted ? DateTime(2026, 10, 1) : null,
    );

/// In-memory controller: records calls and mutates state like the real one.
class _FakeController extends ActiveProfileController {
  _FakeController(this._initial);
  final ActiveProfileState _initial;

  final List<String> acceptedCodes = [];
  final List<String> revokedIds = [];
  ({String targetProfileId, ProfileShareLevel accessLevel})? lastInvite;
  bool failAccept = false;

  @override
  ActiveProfileState build() => _initial;

  @override
  Future<void> refresh() async {}

  @override
  Future<SharedAccessGrant> createInvite({
    required String targetProfileId,
    required ProfileShareLevel accessLevel,
  }) async {
    lastInvite = (targetProfileId: targetProfileId, accessLevel: accessLevel);
    final invite = SharedAccessGrant(
      id: 'g-new',
      direction: GrantDirection.outgoing,
      targetProfileId: targetProfileId,
      targetProfileName: 'Lucas',
      accessLevel: accessLevel,
      status: GrantStatus.pending,
      expiresAt: DateTime.now().add(const Duration(hours: 72)),
      inviteCode: 'AB12CD',
    );
    state = state.copyWith(outgoingGrants: [...state.outgoingGrants, invite]);
    return invite;
  }

  @override
  Future<void> acceptInvite(String inviteCode) async {
    acceptedCodes.add(inviteCode);
    if (failAccept) throw Exception('invalid');
  }

  @override
  Future<void> revokeGrant(String grantId) async {
    revokedIds.add(grantId);
    state = state.copyWith(
      outgoingGrants: state.outgoingGrants.where((g) => g.id != grantId).toList(),
      incomingGrants: state.incomingGrants.where((g) => g.id != grantId).toList(),
    );
  }
}

Widget _app(_FakeController controller, {bool premium = true}) => ProviderScope(
      overrides: [
        premiumProfilesEnabledProvider.overrideWithValue(premium),
        activeProfileControllerProvider.overrideWith(() => controller),
      ],
      child: const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: FamilySharingScreen(),
      ),
    );

ActiveProfileState _state({
  List<SharedAccessGrant> outgoing = const [],
  List<SharedAccessGrant> incoming = const [],
}) =>
    ActiveProfileState(
      profiles: const [_me, _kid],
      activeProfileId: _me.id,
      outgoingGrants: outgoing,
      incomingGrants: incoming,
    );

void main() {
  testWidgets('shows not-available state when premium flag is off',
      (tester) async {
    await tester.pumpWidget(_app(_FakeController(_state()), premium: false));
    await tester.pumpAndSettle();

    expect(find.text('Recurso ainda não disponível'), findsOneWidget);
    expect(find.byKey(const ValueKey('family-share-invite-button')),
        findsNothing);
  });

  testWidgets('tabs render outgoing and incoming lists; expired invites flagged',
      (tester) async {
    final controller = _FakeController(_state(
      outgoing: [
        _grant('g1', GrantDirection.outgoing, 'Ana'),
        _grant('g2', GrantDirection.outgoing, 'Pedro',
            status: GrantStatus.pending,
            code: 'ZZ99YY',
            expiresAt: DateTime.now().subtract(const Duration(hours: 1))),
      ],
      incoming: [_grant('g3', GrantDirection.incoming, 'Marta')],
    ));
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.text('Quem acessa meus dados'), findsOneWidget);
    expect(find.text('Dados compartilhados comigo'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Pedro'), findsOneWidget);
    expect(find.text('Convite expirado'), findsOneWidget);
    expect(find.text('Marta'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('family-share-tab-incoming')));
    await tester.pumpAndSettle();

    expect(find.text('Marta'), findsOneWidget);
    expect(find.text('Ana'), findsNothing);
  });

  testWidgets('invite dialog creates a co-manage invite and shows the code',
      (tester) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final controller = _FakeController(_state());
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('family-share-invite-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('family-share-invite-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lucas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-scope-coManage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-invite-generate')));
    await tester.pumpAndSettle();

    expect(controller.lastInvite?.targetProfileId, 'p-kid');
    expect(controller.lastInvite?.accessLevel, ProfileShareLevel.coManage);
    expect(find.text('AB12CD'), findsOneWidget);
    expect(find.textContaining('Válido até'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('family-share-invite-copy')));
    await tester.pumpAndSettle();
    expect(clipboard, 'AB12CD');
    expect(find.text('Código copiado.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('family-share-invite-done')));
    await tester.pumpAndSettle();
    expect(find.textContaining('AB12CD'), findsOneWidget); // pending row
  });

  testWidgets('accept sheet uppercases the code and calls acceptInvite',
      (tester) async {
    final controller = _FakeController(_state());
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('family-share-tab-incoming')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-accept-button')));
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('invite-code-field'));
    expect(field, findsOneWidget);

    controller.failAccept = true;
    await tester.enterText(field, 'ab12cd');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('invite-code-submit')));
    await tester.pumpAndSettle();
    expect(controller.acceptedCodes, ['AB12CD']);
    expect(find.text('Código inválido ou expirado.'), findsOneWidget);

    controller.failAccept = false;
    await tester.tap(find.byKey(const ValueKey('invite-code-submit')));
    await tester.pumpAndSettle();
    expect(controller.acceptedCodes.last, 'AB12CD');
    expect(field, findsNothing);
  });

  testWidgets('single active grant uses family-share-revoke and row disappears',
      (tester) async {
    final controller = _FakeController(
        _state(outgoing: [_grant('g1', GrantDirection.outgoing, 'Ana')]));
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    final revoke = find.byKey(const ValueKey('family-share-revoke'));
    expect(revoke, findsOneWidget);

    await tester.tap(revoke);
    await tester.pumpAndSettle();
    expect(find.text('Tem certeza? O acesso será interrompido imediatamente.'),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('family-share-revoke-confirm')));
    await tester.pumpAndSettle();

    expect(controller.revokedIds, ['g1']);
    expect(find.text('Ana'), findsNothing);
    expect(revoke, findsNothing);
  });

  testWidgets('several active grants get per-grant revoke keys',
      (tester) async {
    final controller = _FakeController(_state(outgoing: [
      _grant('g1', GrantDirection.outgoing, 'Ana'),
      _grant('g2', GrantDirection.outgoing, 'Pedro'),
    ]));
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('family-share-revoke')), findsNothing);
    expect(find.byKey(const ValueKey('family-share-revoke-g1')), findsOneWidget);
    expect(find.byKey(const ValueKey('family-share-revoke-g2')), findsOneWidget);
  });
}
