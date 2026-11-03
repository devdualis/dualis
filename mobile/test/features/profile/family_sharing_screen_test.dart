import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
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
  String? granteeName,
  String? granteeEmail,
  String? targetProfileId,
  GrantRelationship? relationship,
  List<ShareCategory> categories = const [],
}) =>
    SharedAccessGrant(
      id: id,
      direction: direction,
      targetProfileId: targetProfileId ?? 'target-$id',
      targetProfileName: name,
      accessLevel: ProfileShareLevel.viewOnly,
      status: status,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 72)),
      inviteCode: code,
      acceptedAt: status == GrantStatus.accepted ? DateTime(2026, 10, 1) : null,
      granteeName: granteeName,
      granteeEmail: granteeEmail,
      relationship: relationship,
      categories: categories,
    );

/// In-memory controller: records calls and mutates state like the real one.
class _FakeController extends ActiveProfileController {
  _FakeController(this._initial);
  final ActiveProfileState _initial;

  final List<String> acceptedCodes = [];
  final List<String> revokedIds = [];
  ({
    String targetProfileId,
    ProfileShareLevel accessLevel,
    GrantRelationship relationship,
    List<ShareCategory> categories,
    bool dependentShareConfirmed,
  })? lastInvite;
  Object? acceptError;
  Object? updateError;
  ({String grantId, List<ShareCategory>? categories, bool dependentShareConfirmed})?
      lastUpdate;

  @override
  ActiveProfileState build() => _initial;

  @override
  Future<void> refresh() async {}

  @override
  Future<SharedAccessGrant> createInvite({
    required String targetProfileId,
    required ProfileShareLevel accessLevel,
    required GrantRelationship relationship,
    required List<ShareCategory> categories,
    bool dependentShareConfirmed = false,
  }) async {
    lastInvite = (
      targetProfileId: targetProfileId,
      accessLevel: accessLevel,
      relationship: relationship,
      categories: categories,
      dependentShareConfirmed: dependentShareConfirmed,
    );
    final invite = SharedAccessGrant(
      id: 'g-new',
      direction: GrantDirection.outgoing,
      targetProfileId: targetProfileId,
      targetProfileName: 'Lucas',
      accessLevel: accessLevel,
      status: GrantStatus.pending,
      expiresAt: DateTime.now().add(const Duration(hours: 72)),
      inviteCode: 'AB12CD34EF',
      relationship: relationship,
      categories: categories,
    );
    state = state.copyWith(outgoingGrants: [...state.outgoingGrants, invite]);
    return invite;
  }

  @override
  Future<SharedAccessGrant> updateGrant(
    String grantId, {
    List<ShareCategory>? categories,
    GrantRelationship? relationship,
    bool dependentShareConfirmed = false,
  }) async {
    lastUpdate = (
      grantId: grantId,
      categories: categories,
      dependentShareConfirmed: dependentShareConfirmed,
    );
    if (updateError != null) throw updateError!;
    final old = state.outgoingGrants.firstWhere((g) => g.id == grantId);
    final updated = SharedAccessGrant(
      id: old.id,
      direction: old.direction,
      targetProfileId: old.targetProfileId,
      targetProfileName: old.targetProfileName,
      accessLevel: old.accessLevel,
      status: old.status,
      expiresAt: old.expiresAt,
      acceptedAt: old.acceptedAt,
      relationship: relationship ?? old.relationship,
      categories: categories ?? old.categories,
    );
    state = state.copyWith(outgoingGrants: [
      for (final g in state.outgoingGrants) g.id == grantId ? updated : g,
    ]);
    return updated;
  }

  @override
  Future<void> acceptInvite(String inviteCode) async {
    acceptedCodes.add(inviteCode);
    if (acceptError != null) throw acceptError!;
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

Future<void> _pickRelationship(WidgetTester tester, String apiValue) async {
  final field = find.byKey(const ValueKey('family-share-relationship'));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  // The menu copy of the item sits in the route overlay, after the button's.
  final item = find
      .descendant(
          of: find.byKey(ValueKey('family-share-relationship-$apiValue')).last,
          matching: find.byType(Text))
      .first;
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> _openInviteDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('family-share-invite-button')));
  await tester.pumpAndSettle();
}

FilledButton _generateButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.byKey(const ValueKey('family-share-invite-generate')));

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
    await _pickRelationship(tester, 'friend');
    final confirm =
        find.byKey(const ValueKey('family-share-dependent-confirm'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-invite-generate')));
    await tester.pumpAndSettle();

    expect(controller.lastInvite?.targetProfileId, 'p-kid');
    expect(controller.lastInvite?.accessLevel, ProfileShareLevel.coManage);
    expect(find.text('AB12CD34EF'), findsOneWidget);
    expect(find.textContaining('Válido até'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('family-share-invite-copy')));
    await tester.pumpAndSettle();
    expect(clipboard, 'AB12CD34EF');
    expect(find.text('Código copiado.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('family-share-invite-done')));
    await tester.pumpAndSettle();
    expect(find.textContaining('AB12CD34EF'), findsOneWidget); // pending row
  });

  testWidgets(
      'invite needs a relationship; default categories are habits only and '
      'the new grant lists relationship and category chips', (tester) async {
    final controller = _FakeController(_state());
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _openInviteDialog(tester);

    // Habits pre-checked, everything else (emotional journal included) not.
    for (final c in ShareCategory.values) {
      final tile = tester.widget<CheckboxListTile>(
          find.byKey(ValueKey('family-share-category-${c.apiValue}')));
      expect(tile.value, c == ShareCategory.habits, reason: c.apiValue);
    }
    expect(_generateButton(tester).onPressed, isNull,
        reason: 'relationship is required');

    await _pickRelationship(tester, 'sibling');
    expect(_generateButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('family-share-invite-generate')));
    await tester.pumpAndSettle();
    expect(controller.lastInvite?.targetProfileId, 'p-me');
    expect(controller.lastInvite?.relationship, GrantRelationship.sibling);
    expect(controller.lastInvite?.categories, [ShareCategory.habits]);

    await tester.tap(find.byKey(const ValueKey('family-share-invite-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('grant-relationship-g-new')),
        findsOneWidget);
    expect(find.text('Irmão ou irmã'), findsOneWidget);
    expect(find.byKey(const ValueKey('grant-category-g-new-habits')),
        findsOneWidget);
    expect(find.text('Hábitos (água, sono, movimento)'), findsOneWidget);
    expect(find.byKey(const ValueKey('grant-category-g-new-emotional_journal')),
        findsNothing);
  });

  testWidgets('unchecking every category blocks Generate', (tester) async {
    final controller = _FakeController(_state());
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _openInviteDialog(tester);
    await _pickRelationship(tester, 'friend');

    final habits = find.byKey(const ValueKey('family-share-category-habits'));
    await tester.ensureVisible(habits);
    await tester.pumpAndSettle();
    await tester.tap(habits);
    await tester.pumpAndSettle();

    expect(_generateButton(tester).onPressed, isNull);
    expect(find.text('Escolha ao menos uma categoria.'), findsOneWidget);
  });

  testWidgets('both lists show the relationship; legacy grants say Não informado',
      (tester) async {
    final controller = _FakeController(_state(
      outgoing: [
        _grant('g1', GrantDirection.outgoing, 'Ana',
            relationship: GrantRelationship.caregiver,
            categories: [ShareCategory.habits, ShareCategory.care]),
        _grant('g2', GrantDirection.outgoing, 'Pedro'),
      ],
      incoming: [
        _grant('g3', GrantDirection.incoming, 'Marta',
            relationship: GrantRelationship.parent,
            categories: [ShareCategory.physicalJournal]),
      ],
    ));
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.text('Cuidador(a)'), findsOneWidget);
    expect(find.text('Não informado'), findsOneWidget);
    expect(find.byKey(const ValueKey('grant-category-g1-habits')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('grant-category-g1-care')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('family-share-tab-incoming')));
    await tester.pumpAndSettle();
    expect(find.text('Pai ou mãe'), findsOneWidget);
    expect(find.byKey(const ValueKey('grant-category-g3-physical_journal')),
        findsOneWidget);
  });

  testWidgets('emotional journal is unchecked and explained; help never shared',
      (tester) async {
    final controller = _FakeController(_state());
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _openInviteDialog(tester);

    final emotional = tester.widget<CheckboxListTile>(find
        .byKey(const ValueKey('family-share-category-emotional_journal')));
    expect(emotional.value, isFalse);
    expect(find.byKey(const ValueKey('family-share-emotional-explanation')),
        findsOneWidget);
    expect(
        find.text('O diário emocional guarda o que você sente e escreve. '
            'Marque só se confia plenamente nessa pessoa.'),
        findsOneWidget);
    expect(find.text('Pedidos de ajuda nunca são compartilhados.'),
        findsOneWidget);
    // Primary profile: no guardian confirmation.
    expect(find.byKey(const ValueKey('family-share-dependent-confirm')),
        findsNothing);
  });

  testWidgets('dependent target blocks Generate until the guardian confirms',
      (tester) async {
    final controller = _FakeController(_state());
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _openInviteDialog(tester);

    await tester.tap(find.byKey(const ValueKey('family-share-invite-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lucas').last);
    await tester.pumpAndSettle();
    await _pickRelationship(tester, 'caregiver');

    final confirm =
        find.byKey(const ValueKey('family-share-dependent-confirm'));
    expect(confirm, findsOneWidget);
    expect(_generateButton(tester).onPressed, isNull);

    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(_generateButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('family-share-invite-generate')));
    await tester.pumpAndSettle();
    expect(controller.lastInvite?.targetProfileId, 'p-kid');
    expect(controller.lastInvite?.dependentShareConfirmed, isTrue);
  });

  testWidgets('owner edits categories of an active grant (PATCH)',
      (tester) async {
    final controller = _FakeController(_state(outgoing: [
      _grant('g1', GrantDirection.outgoing, 'Ricardo',
          targetProfileId: 'p-me',
          relationship: GrantRelationship.sibling,
          categories: [ShareCategory.habits]),
    ]));
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('grant-edit-categories-g1')));
    await tester.pumpAndSettle();
    expect(find.text('Editar o que é compartilhado'), findsWidgets);
    expect(
        tester
            .widget<CheckboxListTile>(
                find.byKey(const ValueKey('family-share-category-habits')))
            .value,
        isTrue);

    final care = find.byKey(const ValueKey('family-share-category-care'));
    await tester.ensureVisible(care);
    await tester.pumpAndSettle();
    await tester.tap(care);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-edit-save')));
    await tester.pumpAndSettle();

    expect(controller.lastUpdate?.grantId, 'g1');
    expect(controller.lastUpdate?.categories,
        [ShareCategory.habits, ShareCategory.care]);
    expect(controller.lastUpdate?.dependentShareConfirmed, isFalse);
    expect(find.byKey(const ValueKey('grant-category-g1-care')), findsOneWidget);
  });

  testWidgets('editing a dependent grant needs the confirmation; 409 shown',
      (tester) async {
    final controller = _FakeController(_state(outgoing: [
      _grant('g1', GrantDirection.outgoing, 'Lucas',
          targetProfileId: 'p-kid', categories: [ShareCategory.habits]),
    ]))
      ..updateError = const ProfileApiException(
          'Este compartilhamento não pode mais ser alterado.',
          statusCode: 409);
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('grant-edit-categories-g1')));
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('family-share-edit-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    final confirm =
        find.byKey(const ValueKey('family-share-dependent-confirm'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(controller.lastUpdate?.dependentShareConfirmed, isTrue);
    expect(find.text('Este compartilhamento não pode mais ser alterado.'),
        findsOneWidget);
  });

  testWidgets('incoming grants and expired invites have no edit action',
      (tester) async {
    final controller = _FakeController(_state(
      outgoing: [
        _grant('g2', GrantDirection.outgoing, 'Pedro',
            status: GrantStatus.pending,
            code: 'ZZ99YY',
            expiresAt: DateTime.now().subtract(const Duration(hours: 1))),
        _grant('g4', GrantDirection.outgoing, 'Ana',
            status: GrantStatus.pending, code: 'AA11BB22CC'),
      ],
      incoming: [
        _grant('g3', GrantDirection.incoming, 'Marta',
            categories: [ShareCategory.habits]),
      ],
    ));
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('grant-edit-categories-g2')), findsNothing);
    expect(find.byKey(const ValueKey('grant-edit-categories-g4')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('family-share-tab-incoming')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('grant-edit-categories-g3')), findsNothing);
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

    controller.acceptError = Exception('invalid');
    await tester.enterText(field, 'ab12cd34ef');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('invite-code-submit')));
    await tester.pumpAndSettle();
    expect(controller.acceptedCodes, ['AB12CD34EF']);
    expect(find.text('Código inválido ou expirado.'), findsOneWidget);

    controller.acceptError = null;
    await tester.tap(find.byKey(const ValueKey('invite-code-submit')));
    await tester.pumpAndSettle();
    expect(controller.acceptedCodes.last, 'AB12CD34EF');
    expect(field, findsNothing);
  });

  testWidgets('accept sheet waits for all 10 characters', (tester) async {
    final controller = _FakeController(_state());
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-tab-incoming')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-accept-button')));
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('invite-code-field'));
    final submit = find.byKey(const ValueKey('invite-code-submit'));
    await tester.enterText(field, 'AB12CD');
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(field, 'AB12CD34EF');
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });

  testWidgets('accept sheet explains the wait after too many attempts (429)',
      (tester) async {
    final controller = _FakeController(_state())
      ..acceptError = const ProfileApiException('Too many invite attempts.',
          statusCode: 429);
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-tab-incoming')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-accept-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('invite-code-field')), 'AB12CD34EF');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('invite-code-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Muitas tentativas. Aguarde 15 minutos e tente de novo.'),
        findsOneWidget);
    expect(find.text('Código inválido ou expirado.'), findsNothing);
  });

  testWidgets('accept sheet says when the code is the caller\'s own invite',
      (tester) async {
    final controller = _FakeController(_state())
      ..acceptError = const ProfileApiException('own',
          statusCode: 400, code: 'INVITE_OWN_PROFILE');
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-tab-incoming')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-accept-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('invite-code-field')), 'AB12CD34EF');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('invite-code-submit')));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Este código é seu. Envie-o para a pessoa que vai acompanhar você.'),
        findsOneWidget);
    expect(find.text('Código inválido ou expirado.'), findsNothing);
  });

  testWidgets('active outgoing grants name who accepted; incoming ones do not',
      (tester) async {
    final controller = _FakeController(_state(
      outgoing: [
        _grant('g1', GrantDirection.outgoing, 'Ana',
            granteeName: 'Maria Souza', granteeEmail: 'maria@example.com'),
        _grant('g2', GrantDirection.outgoing, 'Pedro',
            status: GrantStatus.pending, code: 'ZZ99YY88XX'),
      ],
      incoming: [
        _grant('g3', GrantDirection.incoming, 'Marta',
            granteeName: 'Eu Mesmo', granteeEmail: 'eu@example.com'),
      ],
    ));
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.text('Compartilhado com Maria Souza (maria@example.com)'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('family-share-grantee-g2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('family-share-tab-incoming')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('family-share-grantee-g3')), findsNothing);
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

  testWidgets('pending invite can be cancelled; expired one cannot',
      (tester) async {
    final controller = _FakeController(_state(outgoing: [
      _grant('p1', GrantDirection.outgoing, 'Ana',
          status: GrantStatus.pending, code: 'ABC234'),
      _grant('p2', GrantDirection.outgoing, 'Pedro',
          status: GrantStatus.pending,
          code: 'XYZ789',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1))),
    ]));
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('family-share-cancel-p2')), findsNothing);
    final cancel = find.byKey(const ValueKey('family-share-cancel-p1'));
    expect(cancel, findsOneWidget);

    await tester.tap(cancel);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-share-revoke-confirm')));
    await tester.pumpAndSettle();

    expect(controller.revokedIds, ['p1']);
  });
}
