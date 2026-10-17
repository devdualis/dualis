import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/features/profile/presentation/widgets/active_profile_banner.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeActiveProfileController extends ActiveProfileController {
  _FakeActiveProfileController(this._initial);

  final ActiveProfileState _initial;
  String? lastSelectedId;

  @override
  ActiveProfileState build() => _initial;

  @override
  void selectProfile(String profileId) {
    lastSelectedId = profileId;
    state = state.copyWith(activeProfileId: profileId);
  }
}

Widget _host({
  required ActiveProfileController controller,
  bool premium = true,
}) {
  return ProviderScope(
    overrides: [
      premiumProfilesEnabledProvider.overrideWithValue(premium),
      activeProfileControllerProvider.overrideWith(() => controller),
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
      home: const Scaffold(
        body: Column(
          children: [
            ActiveProfileBanner(),
            ActiveProfileReadOnlyNote(),
          ],
        ),
      ),
    ),
  );
}

void main() {
  const primary = Profile(
    id: 'p-1',
    name: 'Maria Silva',
    profileType: ProfileType.primary,
    ownership: ProfileOwnership.own,
    accessLevel: ProfileAccessLevel.owner,
  );

  const dependent = Profile(
    id: 'dep-1',
    name: 'Lucas Guardiao',
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

  testWidgets('banner hidden for primary profile', (tester) async {
    final fake = _FakeActiveProfileController(
      const ActiveProfileState(
        profiles: [primary],
        activeProfileId: 'p-1',
      ),
    );

    await tester.pumpWidget(_host(controller: fake));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-profile-banner')), findsNothing);
  });

  testWidgets('banner visible for dependent and switches to primary on tap',
      (tester) async {
    final fake = _FakeActiveProfileController(
      const ActiveProfileState(
        profiles: [primary, dependent],
        activeProfileId: 'dep-1',
      ),
    );

    await tester.pumpWidget(_host(controller: fake));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-profile-banner')), findsOneWidget);
    expect(find.textContaining('Lucas Guardiao'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('active-profile-banner')));
    await tester.pumpAndSettle();

    expect(fake.lastSelectedId, 'p-1');
  });

  testWidgets('read-only note only for VIEW_ONLY shared profile', (tester) async {
    final fake = _FakeActiveProfileController(
      const ActiveProfileState(
        profiles: [primary, sharedViewOnly],
        activeProfileId: 'shared-view',
      ),
    );

    await tester.pumpWidget(_host(controller: fake));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-profile-readonly-note')), findsOneWidget);
    expect(find.text('Somente leitura'), findsOneWidget);
  });

  testWidgets('read-only note hidden for owned dependent', (tester) async {
    final fake = _FakeActiveProfileController(
      const ActiveProfileState(
        profiles: [primary, dependent],
        activeProfileId: 'dep-1',
      ),
    );

    await tester.pumpWidget(_host(controller: fake));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-profile-readonly-note')), findsNothing);
  });
}
