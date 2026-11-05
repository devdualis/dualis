import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/domain/models/share_category.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuth extends AuthController {
  @override
  AuthState build() => const AuthState(
        isAuthenticated: true,
        user: UserProfile(
          id: 'u-1',
          email: 'maria@example.com',
          name: 'Maria Silva',
          gender: Gender.masculino,
        ),
        accessToken: 'token',
      );
}

class _FakeProfiles extends ActiveProfileController {
  _FakeProfiles(this._initial);

  final ActiveProfileState _initial;
  static int refreshCalls = 0;

  @override
  ActiveProfileState build() => _initial;

  @override
  Future<void> refresh() async => refreshCalls++;
}

void main() {
  const primary = Profile(
    id: 'p-1',
    name: 'Maria Silva',
    profileType: ProfileType.primary,
    ownership: ProfileOwnership.own,
    accessLevel: ProfileAccessLevel.owner,
  );

  const sharedViewOnly = Profile(
    id: 'shared-view',
    name: 'Carlos Oliveira',
    profileType: ProfileType.primary,
    ownership: ProfileOwnership.shared,
    accessLevel: ProfileAccessLevel.viewOnly,
  );

  Widget buildApp(ActiveProfileState profileState) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (_, __) => const HomeScreen(),
        ),
      ],
      initialLocation: RoutePaths.home,
    );

    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuth.new),
        premiumProfilesEnabledProvider.overrideWithValue(true),
        activeProfileControllerProvider.overrideWith(
          () => _FakeProfiles(profileState),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets('home greeting uses active dependent and hides triage starts when VIEW_ONLY',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        const ActiveProfileState(
          profiles: [primary, sharedViewOnly],
          activeProfileId: 'shared-view',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perfil de Carlos Oliveira'), findsOneWidget);
    expect(find.text('Somente leitura'), findsWidgets);
    expect(find.text('maria@example.com'), findsNothing);
    expect(find.byKey(const Key('start_psicoemocional_triage_button')), findsNothing);
    expect(find.byKey(const Key('start_fisica_triage_button')), findsNothing);
    expect(find.byKey(const ValueKey('active-profile-banner')), findsOneWidget);
    expect(find.byKey(const Key('nav_destination_emergency')), findsOneWidget);
  });

  testWidgets('Premium build shows the discreet Premium label on the Home card',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        const ActiveProfileState(
          profiles: [primary, sharedViewOnly],
          activeProfileId: 'shared-view',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final label = find.byKey(const Key('home_premium_label'));
    expect(label, findsOneWidget);
    expect(
      find.descendant(of: label, matching: find.text('Premium')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home_profile_card')),
        matching: label,
      ),
      findsOneWidget,
    );
  });

  testWidgets('history refresh button also reloads profiles and grants',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        const ActiveProfileState(
          profiles: [primary, sharedViewOnly],
          activeProfileId: 'shared-view',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_destination_history')));
    // The history tab keeps a loading animation running: no pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 500));
    _FakeProfiles.refreshCalls = 0;

    await tester.tap(find.byKey(const Key('home_refresh_history_button')));
    await tester.pump();

    expect(_FakeProfiles.refreshCalls, 1);
  });

  testWidgets('primary active profile keeps legacy greeting and triage buttons',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        const ActiveProfileState(
          profiles: [primary],
          activeProfileId: 'p-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Olá, Maria!'), findsOneWidget);
    expect(find.text('maria@example.com'), findsOneWidget);
    expect(find.byKey(const Key('start_psicoemocional_triage_button')), findsOneWidget);
    expect(find.byKey(const Key('start_fisica_triage_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('active-profile-banner')), findsNothing);
    expect(find.byKey(const ValueKey('home-area-not-shared-emotional')), findsNothing);
    expect(find.byKey(const ValueKey('home-area-not-shared-physical')), findsNothing);
    expect(find.byKey(const Key('nav_destination_emergency')), findsOneWidget);
  });

  testWidgets('grantee with only the physical journal sees only the physical start',
      (tester) async {
    const physicalOnly = Profile(
      id: 'shared-physical',
      name: 'Carlos Oliveira',
      profileType: ProfileType.primary,
      ownership: ProfileOwnership.shared,
      accessLevel: ProfileAccessLevel.coManage,
      readableCategories: [ShareCategory.habits, ShareCategory.physicalJournal],
      writableCategories: [ShareCategory.habits, ShareCategory.physicalJournal],
    );
    await tester.pumpWidget(
      buildApp(
        const ActiveProfileState(
          profiles: [primary, physicalOnly],
          activeProfileId: 'shared-physical',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start_fisica_triage_button')), findsOneWidget);
    expect(find.byKey(const Key('start_psicoemocional_triage_button')), findsNothing);
    expect(find.byKey(const ValueKey('home-area-not-shared-emotional')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-area-not-shared-physical')), findsNothing);
    expect(find.text('Não compartilhado com você'), findsOneWidget);
    expect(find.byKey(const Key('nav_destination_emergency')), findsOneWidget);
  });

  testWidgets('grantee with neither journal sees both areas as not shared',
      (tester) async {
    const habitsOnly = Profile(
      id: 'shared-habits',
      name: 'Carlos Oliveira',
      profileType: ProfileType.primary,
      ownership: ProfileOwnership.shared,
      accessLevel: ProfileAccessLevel.coManage,
      readableCategories: [ShareCategory.habits],
      writableCategories: [ShareCategory.habits],
    );
    await tester.pumpWidget(
      buildApp(
        const ActiveProfileState(
          profiles: [primary, habitsOnly],
          activeProfileId: 'shared-habits',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start_fisica_triage_button')), findsNothing);
    expect(find.byKey(const Key('start_psicoemocional_triage_button')), findsNothing);
    expect(find.byKey(const ValueKey('home-area-not-shared-emotional')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-area-not-shared-physical')), findsOneWidget);
    expect(find.byKey(const Key('nav_destination_emergency')), findsOneWidget);
  });

  testWidgets('readable but not writable journal shows the area without a start',
      (tester) async {
    const readNoWrite = Profile(
      id: 'shared-read',
      name: 'Carlos Oliveira',
      profileType: ProfileType.primary,
      ownership: ProfileOwnership.shared,
      accessLevel: ProfileAccessLevel.coManage,
      readableCategories: [
        ShareCategory.physicalJournal,
        ShareCategory.emotionalJournal,
      ],
      writableCategories: [ShareCategory.emotionalJournal],
    );
    await tester.pumpWidget(
      buildApp(
        const ActiveProfileState(
          profiles: [primary, readNoWrite],
          activeProfileId: 'shared-read',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start_psicoemocional_triage_button')), findsOneWidget);
    expect(find.byKey(const Key('start_fisica_triage_button')), findsNothing);
    expect(find.byKey(const ValueKey('home-area-not-shared-physical')), findsNothing);
    expect(find.byKey(const Key('nav_destination_emergency')), findsOneWidget);
  });
}
