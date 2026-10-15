import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/features/profile/presentation/widgets/profile_app_bar_pill.dart';
import 'package:dualis_mobile/features/profile/presentation/widgets/profile_selection_sheet.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeActiveProfileController extends ActiveProfileController {
  FakeActiveProfileController(this._initialState);

  final ActiveProfileState _initialState;
  String? selectedId;
  String? renamedId;
  String? renamedNewName;
  String? deletedId;

  @override
  ActiveProfileState build() => _initialState;

  @override
  void selectProfile(String profileId) {
    selectedId = profileId;
    state = state.copyWith(activeProfileId: profileId);
  }

  @override
  Future<void> updateProfileName(String profileId, String name) async {
    renamedId = profileId;
    renamedNewName = name;
    final updatedProfiles = state.profiles.map((p) {
      if (p.id == profileId) {
        return Profile(
          id: p.id,
          name: name,
          profileType: p.profileType,
          ownership: p.ownership,
          accessLevel: p.accessLevel,
          dateOfBirth: p.dateOfBirth,
          gender: p.gender,
          avatarUrl: p.avatarUrl,
        );
      }
      return p;
    }).toList();
    state = state.copyWith(profiles: updatedProfiles);
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    deletedId = profileId;
    final remainingProfiles =
        state.profiles.where((p) => p.id != profileId).toList();
    final newActiveId = state.activeProfileId == profileId
        ? (remainingProfiles.any((p) => p.isPrimary)
            ? remainingProfiles.firstWhere((p) => p.isPrimary).id
            : (remainingProfiles.isNotEmpty ? remainingProfiles.first.id : null))
        : state.activeProfileId;
    state = state.copyWith(
      profiles: remainingProfiles,
      activeProfileId: newActiveId,
    );
  }
}

Widget _buildHost({
  required FakeActiveProfileController fakeController,
  bool premiumEnabled = true,
  Widget child = const Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(56),
      child: SafeArea(
        child: Row(
          children: [
            Spacer(),
            ProfileAppBarPill(),
          ],
        ),
      ),
    ),
    body: Center(child: Text('Host Body')),
  ),
}) {
  return ProviderScope(
    overrides: [
      premiumProfilesEnabledProvider.overrideWithValue(premiumEnabled),
      activeProfileControllerProvider.overrideWith(() => fakeController),
    ],
    child: MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  const primaryProfile = Profile(
    id: 'p-1',
    name: 'Maria Silva',
    profileType: ProfileType.primary,
    ownership: ProfileOwnership.own,
    accessLevel: ProfileAccessLevel.owner,
  );

  const dependentMinor = Profile(
    id: 'dep-1',
    name: 'Enzo Silva',
    profileType: ProfileType.dependentMinor,
    ownership: ProfileOwnership.dependent,
    accessLevel: ProfileAccessLevel.owner,
  );

  const sharedViewOnly = Profile(
    id: 'shared-view',
    name: 'Carlos Oliveira',
    profileType: ProfileType.primary,
    ownership: ProfileOwnership.shared,
    accessLevel: ProfileAccessLevel.viewOnly,
  );

  const sharedCoManage = Profile(
    id: 'shared-co',
    name: 'Ana Santos',
    profileType: ProfileType.primary,
    ownership: ProfileOwnership.shared,
    accessLevel: ProfileAccessLevel.coManage,
  );

  group('ProfileAppBarPill', () {
    testWidgets('pill hidden when flag is false', (tester) async {
      final fake = FakeActiveProfileController(
        const ActiveProfileState(
          profiles: [primaryProfile],
          activeProfileId: 'p-1',
        ),
      );

      await tester.pumpWidget(
        _buildHost(fakeController: fake, premiumEnabled: false),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('profile-app-bar-pill')), findsNothing);
    });

    testWidgets('pill visible and displays active profile name when flag is true',
        (tester) async {
      final fake = FakeActiveProfileController(
        const ActiveProfileState(
          profiles: [primaryProfile],
          activeProfileId: 'p-1',
        ),
      );

      await tester.pumpWidget(
        _buildHost(fakeController: fake, premiumEnabled: true),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('profile-app-bar-pill')),
        findsOneWidget,
      );
      expect(find.text('Maria Silva'), findsOneWidget);
    });

    testWidgets('pill shows dependent badge when dependent is active',
        (tester) async {
      final fake = FakeActiveProfileController(
        const ActiveProfileState(
          profiles: [primaryProfile, dependentMinor],
          activeProfileId: 'dep-1',
        ),
      );

      await tester.pumpWidget(
        _buildHost(fakeController: fake, premiumEnabled: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enzo Silva'), findsOneWidget);
      expect(find.byIcon(Icons.family_restroom), findsOneWidget);
    });

    testWidgets('pill shows read-only badge when view-only shared profile is active',
        (tester) async {
      final fake = FakeActiveProfileController(
        const ActiveProfileState(
          profiles: [primaryProfile, sharedViewOnly],
          activeProfileId: 'shared-view',
        ),
      );

      await tester.pumpWidget(
        _buildHost(fakeController: fake, premiumEnabled: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Carlos Oliveira'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('ProfileSelectionSheet & Switcher interactions', () {
    testWidgets('opening the sheet, selecting a dependent updates the pill',
        (tester) async {
      final fake = FakeActiveProfileController(
        const ActiveProfileState(
          profiles: [primaryProfile, dependentMinor],
          activeProfileId: 'p-1',
        ),
      );

      await tester.pumpWidget(
        _buildHost(fakeController: fake, premiumEnabled: true),
      );
      await tester.pumpAndSettle();

      // Pill shows primary profile initially
      expect(find.text('Maria Silva'), findsOneWidget);

      // Tap pill to open sheet
      await tester.tap(find.byKey(const ValueKey('profile-app-bar-pill')));
      await tester.pumpAndSettle();

      // Sheet is open: header and profiles are visible
      expect(find.text('Perfis de Saúde'), findsOneWidget);
      expect(find.text('Enzo Silva'), findsOneWidget);

      // Tap dependent profile to select
      await tester.tap(find.text('Enzo Silva'));
      await tester.pumpAndSettle();

      // Sheet is closed, controller updated, pill displays Enzo Silva
      expect(fake.selectedId, equals('dep-1'));
      expect(find.text('Perfis de Saúde'), findsNothing);
      expect(find.text('Enzo Silva'), findsOneWidget);
      expect(find.byIcon(Icons.family_restroom), findsOneWidget);
    });

    testWidgets(
        'edit/delete absent for VIEW_ONLY shared profile and present for own dependent',
        (tester) async {
      final fake = FakeActiveProfileController(
        const ActiveProfileState(
          profiles: [
            primaryProfile,
            dependentMinor,
            sharedViewOnly,
            sharedCoManage,
          ],
          activeProfileId: 'p-1',
        ),
      );

      await tester.pumpWidget(
        _buildHost(
          fakeController: fake,
          child: const Scaffold(
            body: ProfileSelectionSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Own dependent has both edit and delete
      expect(
        find.byKey(const ValueKey('profile-edit-dep-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-delete-dep-1')),
        findsOneWidget,
      );

      // VIEW_ONLY shared profile has NEITHER edit nor delete
      expect(
        find.byKey(const ValueKey('profile-edit-shared-view')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('profile-delete-shared-view')),
        findsNothing,
      );

      // CO_MANAGE shared profile has edit, but not delete
      expect(
        find.byKey(const ValueKey('profile-edit-shared-co')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-delete-shared-co')),
        findsNothing,
      );

      // Primary profile has edit, but not delete
      expect(
        find.byKey(const ValueKey('profile-edit-p-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-delete-p-1')),
        findsNothing,
      );
    });

    testWidgets('the two driver keys exist: add-dependent and manage-sharing',
        (tester) async {
      final fake = FakeActiveProfileController(
        const ActiveProfileState(
          profiles: [primaryProfile],
          activeProfileId: 'p-1',
        ),
      );

      await tester.pumpWidget(
        _buildHost(
          fakeController: fake,
          child: const Scaffold(
            body: ProfileSelectionSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('profile-add-dependent')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-manage-sharing')),
        findsOneWidget,
      );
      expect(find.text('+ Adicionar Dependente (Legal)'), findsOneWidget);
      expect(find.text('Gerenciar Compartilhamento Familiar'), findsOneWidget);
    });

    testWidgets('renaming profile calls updateProfileName', (tester) async {
      final fake = FakeActiveProfileController(
        const ActiveProfileState(
          profiles: [primaryProfile, dependentMinor],
          activeProfileId: 'p-1',
        ),
      );

      await tester.pumpWidget(
        _buildHost(
          fakeController: fake,
          child: const Scaffold(
            body: ProfileSelectionSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('profile-edit-dep-1')));
      await tester.pumpAndSettle();

      expect(find.text('Renomear Perfil'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Enzo Gabriel');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(fake.renamedId, equals('dep-1'));
      expect(fake.renamedNewName, equals('Enzo Gabriel'));
    });

    testWidgets('deleting profile opens confirmation and calls deleteProfile',
        (tester) async {
      final fake = FakeActiveProfileController(
        const ActiveProfileState(
          profiles: [primaryProfile, dependentMinor],
          activeProfileId: 'dep-1',
        ),
      );

      await tester.pumpWidget(
        _buildHost(
          fakeController: fake,
          child: const Scaffold(
            body: ProfileSelectionSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('profile-delete-dep-1')));
      await tester.pumpAndSettle();

      expect(find.text('Excluir Perfil?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(fake.deletedId, equals('dep-1'));
    });
  });
}
