import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/habits/data/habits_repository.dart';
import 'package:dualis_mobile/features/habits/domain/models/habit_day.dart';
import 'package:dualis_mobile/features/habits/presentation/screens/habits_screen.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/domain/models/share_category.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/shared/widgets/urgent_help_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockHabitsRepository extends Mock implements HabitsRepository {}

class _MemStorage extends SecureStorageService {
  final Map<String, String> values = {};
  @override
  Future<String?> read({required String key}) async => values[key];
  @override
  Future<void> write({required String key, required String value}) async =>
      values[key] = value;
  @override
  Future<void> delete({required String key}) async => values.remove(key);
}

class _TestActiveProfileController extends ActiveProfileController {
  _TestActiveProfileController([this._initial = const ActiveProfileState()]);

  final ActiveProfileState _initial;

  @override
  ActiveProfileState build() => _initial;
}

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.initial();
}

Widget createHabitsTestWidget({
  required HabitsRepository repository,
  required SecureStorageService storage,
  DateTime? clock,
  ActiveProfileState? profiles,
}) {
  final router = GoRouter(
    initialLocation: '/habits',
    routes: [
      GoRoute(
        path: '/habits',
        builder: (_, __) => const HabitsScreen(),
      ),
      GoRoute(
        path: RoutePaths.emergency,
        builder: (_, __) => const Scaffold(body: Text('Emergency Screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      habitsRepositoryProvider.overrideWithValue(repository),
      secureStorageServiceProvider.overrideWithValue(storage),
      homeClockProvider.overrideWithValue(() => clock ?? DateTime(2026, 10, 31, 12, 0)),
      if (profiles != null) premiumProfilesEnabledProvider.overrideWithValue(true),
      activeProfileControllerProvider.overrideWith(
        () => profiles == null
            ? _TestActiveProfileController()
            : _TestActiveProfileController(profiles),
      ),
      authControllerProvider.overrideWith(
        () => _TestAuthController(),
      ),
    ],
    child: MaterialApp.router(
      locale: const Locale('pt'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt'),
        Locale('en'),
        Locale('es'),
      ],
      routerConfig: router,
      builder: (context, child) => UrgentHelpOverlay(
        router: router,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

void main() {
  late MockHabitsRepository repository;
  late _MemStorage storage;

  setUp(() {
    repository = MockHabitsRepository();
    storage = _MemStorage();
    registerFallbackValue(const HabitDay(day: '2026-10-31'));
  });

  group('HabitsScreen widget tests', () {
    testWidgets('tap a sleep quality option saves habit', (tester) async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.syncPending()).thenAnswer((_) async {});
      when(() => repository.saveHabitDay(any())).thenAnswer((inv) async =>
          inv.positionalArguments.first as HabitDay);

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
      ));
      await tester.pumpAndSettle();

      // Find sleep option "Dormi bem"
      final bemFinder = find.byKey(const Key('habits_sleep_bem'));
      expect(bemFinder, findsOneWidget);

      await tester.tap(bemFinder);
      await tester.pumpAndSettle();

      verify(() => repository.saveHabitDay(any(
            that: isA<HabitDay>()
                .having((h) => h.day, 'day', '2026-10-31')
                .having((h) => h.sleepQuality, 'sleepQuality',
                    HabitSleepQuality.bem),
          ))).called(1);
    });

    testWidgets('Ontem asks in the past tense and answered cards show Salvo',
        (tester) async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.syncPending()).thenAnswer((_) async {});
      when(() => repository.saveHabitDay(any())).thenAnswer((inv) async =>
          inv.positionalArguments.first as HabitDay);

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Como você dormiu esta noite?'), findsOneWidget);
      expect(find.text('Mexeu o corpo hoje?'), findsOneWidget);
      expect(find.text('Salvo'), findsNothing);

      await tester.tap(find.byKey(const Key('habits_sleep_bem')));
      await tester.pumpAndSettle();
      expect(find.text('Salvo'), findsOneWidget);

      await tester.tap(find.byKey(const Key('habits_tab_yesterday')));
      await tester.pumpAndSettle();
      expect(find.text('Como você dormiu na noite anterior?'), findsOneWidget);
      expect(find.text('Mexeu o corpo ontem?'), findsOneWidget);
      expect(find.text('Salvo'), findsNothing);
    });

    testWidgets('movement minutes chips only appear after selecting Sim',
        (tester) async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.syncPending()).thenAnswer((_) async {});
      when(() => repository.saveHabitDay(any())).thenAnswer((inv) async =>
          inv.positionalArguments.first as HabitDay);

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
      ));
      await tester.pumpAndSettle();

      // Minutes chips should not be present initially
      expect(find.byKey(const Key('habits_minutes_ate_15')), findsNothing);

      // Tap Sim
      final simFinder = find.byKey(const Key('habits_moved_sim'));
      expect(simFinder, findsOneWidget);
      await tester.tap(simFinder);
      await tester.pumpAndSettle();

      // Now minutes chips appear
      expect(find.byKey(const Key('habits_minutes_ate_15')), findsOneWidget);
      expect(find.byKey(const Key('habits_minutes_15_30')), findsOneWidget);

      // Tap 15 a 30 min
      await tester.tap(find.byKey(const Key('habits_minutes_15_30')));
      await tester.pumpAndSettle();

      verify(() => repository.saveHabitDay(any(
            that: isA<HabitDay>()
                .having((h) => h.moved, 'moved', isTrue)
                .having((h) => h.movementMinutes, 'movementMinutes',
                    HabitMovementMinutes.minutes15To30),
          ))).called(1);
    });

    testWidgets('period card hidden by default and shown when switch is toggled',
        (tester) async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.setTrackMenstrualCycleSetting(any()))
          .thenAnswer((_) async {});
      when(() => repository.syncPending()).thenAnswer((_) async {});
      when(() => repository.saveHabitDay(any())).thenAnswer((inv) async =>
          inv.positionalArguments.first as HabitDay);

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
      ));
      await tester.pumpAndSettle();

      // Period card should NOT be visible
      expect(find.byKey(const Key('habits_period_card')), findsNothing);

      // Find tracking switch
      final switchFinder = find.byKey(const Key('habits_cycle_switch'));
      expect(switchFinder, findsOneWidget);

      // Toggle switch ON
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Period card should now be visible
      final periodCard = find.byKey(const Key('habits_period_card'));
      expect(periodCard, findsOneWidget);

      // Tap Sim on period card
      final periodYesFinder = find.byKey(const Key('habits_period_sim'));
      expect(periodYesFinder, findsOneWidget);
      await tester.ensureVisible(periodYesFinder);
      await tester.pumpAndSettle();
      await tester.tap(periodYesFinder);
      await tester.pumpAndSettle();

      verify(() => repository.saveHabitDay(any(
            that: isA<HabitDay>().having((h) => h.period, 'period', isTrue),
          ))).called(1);
    });

    testWidgets('help button reachable in 1 tap', (tester) async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.syncPending()).thenAnswer((_) async {});

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
      ));
      await tester.pumpAndSettle();

      final helpBtn = find.byKey(const Key('urgent_help_button'));
      expect(helpBtn, findsOneWidget);

      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Emergency Screen'), findsOneWidget);
    });
  });

  group('HabitsScreen failure states', () {
    testWidgets('load failure shows retry, and retry loads the habits', (tester) async {
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.getHabits(days: 60))
          .thenThrow(Exception('SocketException: Failed host lookup'));

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar'), findsOneWidget);
      expect(find.byKey(const Key('habits_sleep_bem')), findsNothing);
      // The urgent-help button stays reachable on the error state.
      expect(find.byType(UrgentHelpButton), findsOneWidget);

      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      await tester.tap(find.byKey(const Key('load_error_retry')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habits_sleep_bem')), findsOneWidget);
    });

    testWidgets('save failure shows a snackbar', (tester) async {
      when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting())
          .thenAnswer((_) async => false);
      when(() => repository.saveHabitDay(any())).thenThrow(Exception('500'));

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('habits_sleep_bem')));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível salvar. Tente de novo.'), findsOneWidget);
    });
  });
  group('HabitsScreen on a shared profile', () {
    const primary = Profile(
      id: 'p-1',
      name: 'Maria Silva',
      profileType: ProfileType.primary,
      ownership: ProfileOwnership.own,
      accessLevel: ProfileAccessLevel.owner,
    );

    ActiveProfileState sharedWith(Profile shared) => ActiveProfileState(
          profiles: [primary, shared],
          activeProfileId: shared.id,
        );

    void stubRepository() {
      when(() => repository.getHabits(
          days: 60, profileId: any(named: 'profileId')))
          .thenAnswer((_) async => []);
      when(() => repository.getTrackMenstrualCycleSetting(
          profileId: any(named: 'profileId'))).thenAnswer((_) async => false);
      when(() => repository.syncPending(profileId: any(named: 'profileId')))
          .thenAnswer((_) async {});
      when(() => repository.saveHabitDay(any(),
              profileId: any(named: 'profileId')))
          .thenAnswer((inv) async => inv.positionalArguments.first as HabitDay);
    }

    testWidgets('habits not shared: placeholder, no habit controls',
        (tester) async {
      stubRepository();
      final shared = Profile.fromJson(const {
        'id': 'shared-1',
        'name': 'Carlos Oliveira',
        'profileType': 'primary',
        'ownership': 'shared',
        'accessLevel': 'CO_MANAGE',
        'readableCategories': ['care'],
        'writableCategories': ['care'],
      });

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
        profiles: sharedWith(shared),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('category-not-shared')), findsOneWidget);
      expect(find.text('Não compartilhado com você'), findsOneWidget);
      expect(
        find.text('Carlos Oliveira não compartilhou esta área com você.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('habits_sleep_bem')), findsNothing);
      expect(find.byKey(const Key('habits_tab_today')), findsNothing);
      expect(find.byKey(const Key('urgent_help_button')), findsOneWidget);
    });

    testWidgets('habits shared VIEW_ONLY: content visible, saving disabled',
        (tester) async {
      stubRepository();
      final shared = Profile.fromJson(const {
        'id': 'shared-1',
        'name': 'Carlos Oliveira',
        'profileType': 'primary',
        'ownership': 'shared',
        'accessLevel': 'VIEW_ONLY',
        'readableCategories': ['habits'],
        'writableCategories': <String>[],
      });
      expect(shared.canRead(ShareCategory.habits), isTrue);
      expect(shared.canWrite(ShareCategory.habits), isFalse);

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
        profiles: sharedWith(shared),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('category-not-shared')), findsNothing);
      final bem = find.byKey(const Key('habits_sleep_bem'));
      expect(bem, findsOneWidget);
      await tester.tap(bem);
      await tester.pumpAndSettle();
      verifyNever(() => repository.saveHabitDay(any(),
          profileId: any(named: 'profileId')));
    });

    testWidgets('CO_MANAGE without habits writable: saving disabled',
        (tester) async {
      stubRepository();
      final shared = Profile.fromJson(const {
        'id': 'shared-1',
        'name': 'Carlos Oliveira',
        'profileType': 'primary',
        'ownership': 'shared',
        'accessLevel': 'CO_MANAGE',
        'readableCategories': ['habits', 'care'],
        'writableCategories': ['care'],
      });

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
        profiles: sharedWith(shared),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('habits_sleep_bem')));
      await tester.pumpAndSettle();
      verifyNever(() => repository.saveHabitDay(any(),
          profileId: any(named: 'profileId')));
    });

    testWidgets('own primary profile: unchanged, saving works', (tester) async {
      stubRepository();

      await tester.pumpWidget(createHabitsTestWidget(
        repository: repository,
        storage: storage,
        profiles: const ActiveProfileState(
          profiles: [primary],
          activeProfileId: 'p-1',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('category-not-shared')), findsNothing);
      await tester.tap(find.byKey(const Key('habits_sleep_bem')));
      await tester.pumpAndSettle();
      verify(() => repository.saveHabitDay(any(),
          profileId: any(named: 'profileId'))).called(1);
    });

    test('missing category keys: owners get every area, grantees none', () {
      final owned = Profile.fromJson(const {
        'id': 'd-1',
        'profileType': 'dependent_minor',
        'ownership': 'dependent',
        'accessLevel': 'OWNER',
      });
      final shared = Profile.fromJson(const {
        'id': 's-1',
        'ownership': 'shared',
        'accessLevel': 'CO_MANAGE',
      });
      for (final c in ShareCategory.values) {
        expect(owned.canRead(c), isTrue);
        expect(owned.canWrite(c), isTrue);
        expect(shared.canRead(c), isFalse);
        expect(shared.canWrite(c), isFalse);
      }
    });
  });
}
