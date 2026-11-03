import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/features/care/data/care_api.dart';
import 'package:dualis_mobile/features/care/data/care_notifications.dart';
import 'package:dualis_mobile/features/care/domain/care_models.dart';
import 'package:dualis_mobile/features/care/presentation/screens/care_hub_screen.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/features/house_ads/data/house_ads_repository.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/features/hydration/presentation/screens/hydration_dashboard_screen.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_controller.dart'
    show userConditionsProvider;
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../care/care_screens_test.dart' show FakeCareApi;
import '../hydration/hydration_interactive_screen_test.dart'
    show FakeAdsRepository, FakeHydration;

class _NoopNotifications implements CareNotificationService {
  @override
  Future<void> reschedule({
    required List<Medication> medications,
    required List<CareRecord> appointments,
    required List<CareRecord> vaccineDoses,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles extends ActiveProfileController {
  _Profiles(this._initial);
  final ActiveProfileState _initial;

  @override
  ActiveProfileState build() => _initial;
}

const _primary = Profile(
  id: 'p-1',
  name: 'Ana',
  profileType: ProfileType.primary,
  ownership: ProfileOwnership.own,
  accessLevel: ProfileAccessLevel.owner,
);

/// Ana viewing Carlos's shared profile, categories as sent by GET /v1/profiles.
ActiveProfileState _sharedState({
  required String accessLevel,
  required List<String> readable,
  required List<String> writable,
}) =>
    ActiveProfileState(
      profiles: [
        _primary,
        Profile.fromJson({
          'id': 'shared-1',
          'name': 'Carlos',
          'profileType': 'primary',
          'ownership': 'shared',
          'accessLevel': accessLevel,
          'readableCategories': readable,
          'writableCategories': writable,
        }),
      ],
      activeProfileId: 'shared-1',
    );

const _ownState = ActiveProfileState(profiles: [_primary], activeProfileId: 'p-1');

void main() {
  final pt = AppLocalizationsPt();

  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    ActiveProfileState profiles, {
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        premiumProfilesEnabledProvider.overrideWithValue(true),
        activeProfileControllerProvider.overrideWith(() => _Profiles(profiles)),
        ...extra,
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: screen),
      ),
    ));
    await tester.pumpAndSettle();
  }

  void expectNotShared() {
    expect(find.byKey(const ValueKey('category-not-shared')), findsOneWidget);
    expect(find.text(pt.profileCategoryNotSharedTitle), findsOneWidget);
    expect(find.text(pt.profileCategoryNotSharedBody('Carlos')), findsOneWidget);
  }

  group('hydration (habits category)', () {
    List<Override> hydration() => [
          hydrationControllerProvider.overrideWith(() => FakeHydration(
                const HydrationState(
                  settings: HydrationSettings(
                    dailyTargetMl: 2000,
                    reminderEnabled: false,
                  ),
                ),
              )),
          houseAdsRepositoryProvider.overrideWithValue(FakeAdsRepository()),
          homeClockProvider.overrideWithValue(() => DateTime(2026, 10, 27, 10)),
        ];

    testWidgets('habits not shared: placeholder, no water controls',
        (tester) async {
      await pump(
        tester,
        const HydrationDashboardScreen(isEmbedded: true),
        _sharedState(accessLevel: 'CO_MANAGE', readable: ['care'], writable: ['care']),
        extra: hydration(),
      );
      expectNotShared();
      expect(find.byKey(const Key('hydration_glass')), findsNothing);
      expect(find.byKey(const Key('hydration_quick_add_200')), findsNothing);
    });

    testWidgets('habits readable, not writable: content without write actions',
        (tester) async {
      await pump(
        tester,
        const HydrationDashboardScreen(isEmbedded: true),
        _sharedState(
          accessLevel: 'CO_MANAGE',
          readable: ['habits', 'care'],
          writable: ['care'],
        ),
        extra: hydration(),
      );
      expect(find.byKey(const ValueKey('category-not-shared')), findsNothing);
      expect(find.byKey(const Key('hydration_glass')), findsOneWidget);
      expect(find.byKey(const Key('hydration_quick_add_200')), findsNothing);
      expect(find.byKey(const Key('dashboard_add_water_button')), findsNothing);
    });

    testWidgets('own profile: unchanged, water controls shown', (tester) async {
      await pump(
        tester,
        const HydrationDashboardScreen(isEmbedded: true),
        _ownState,
        extra: hydration(),
      );
      expect(find.byKey(const ValueKey('category-not-shared')), findsNothing);
      expect(find.byKey(const Key('hydration_quick_add_200')), findsOneWidget);
    });
  });

  group('care hub (care category)', () {
    List<Override> care() => [
          careApiProvider.overrideWithValue(FakeCareApi()
            ..add(CareKind.allergy, {
              'type': 'food',
              'name': 'Camarão',
              'showOnProfile': true,
            })),
          careNotificationServiceProvider.overrideWithValue(_NoopNotifications()),
          userConditionsProvider.overrideWith(
            (ref) async => const [UserCondition(id: 'c1', label: 'Hipertensão')],
          ),
        ];

    testWidgets('care and conditions not shared: placeholder only',
        (tester) async {
      await pump(
        tester,
        const CareHubScreen(),
        _sharedState(accessLevel: 'VIEW_ONLY', readable: ['habits'], writable: []),
        extra: care(),
      );
      expectNotShared();
      expect(find.byKey(const Key('care_hub_medications')), findsNothing);
      expect(find.byKey(const Key('care_hub_conditions')), findsNothing);
    });

    testWidgets('only conditions shared: placeholder for care, conditions row',
        (tester) async {
      await pump(
        tester,
        const CareHubScreen(),
        _sharedState(
          accessLevel: 'VIEW_ONLY',
          readable: ['conditions'],
          writable: [],
        ),
        extra: care(),
      );
      expectNotShared();
      expect(find.byKey(const Key('care_hub_conditions')), findsOneWidget);
      expect(find.byKey(const Key('care_hub_medications')), findsNothing);
      expect(find.text('Camarão'), findsNothing);
    });

    testWidgets('care shared VIEW_ONLY: entries visible', (tester) async {
      await pump(
        tester,
        const CareHubScreen(),
        _sharedState(accessLevel: 'VIEW_ONLY', readable: ['care'], writable: []),
        extra: care(),
      );
      expect(find.byKey(const ValueKey('category-not-shared')), findsNothing);
      expect(find.byKey(const Key('care_hub_medications')), findsOneWidget);
      expect(find.text('Camarão'), findsOneWidget);
      expect(find.byKey(const Key('care_hub_conditions')), findsNothing);
    });

    testWidgets('own profile: every entry, no placeholder', (tester) async {
      await pump(tester, const CareHubScreen(), _ownState, extra: care());
      expect(find.byKey(const ValueKey('category-not-shared')), findsNothing);
      for (final key in [
        'vaccines',
        'allergies',
        'conditions',
        'medications',
        'appointments',
        'exams',
        'summary',
      ]) {
        expect(find.byKey(Key('care_hub_$key')), findsOneWidget);
      }
    });
  });
}
