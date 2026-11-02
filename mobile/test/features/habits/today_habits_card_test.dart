import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/habits/data/habits_repository.dart';
import 'package:dualis_mobile/features/habits/domain/models/habit_day.dart';
import 'package:dualis_mobile/features/habits/presentation/widgets/today_habits_card.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockHabitsRepository extends Mock implements HabitsRepository {}

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

class _FakeHydrationController extends HydrationController {
  @override
  HydrationState build() => const HydrationState(todayTotalMl: 650);
  @override
  Future<void> loadData() async {}
}

class _TestActiveProfileController extends ActiveProfileController {
  @override
  ActiveProfileState build() => const ActiveProfileState();
}

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.initial();
}

Widget _app({required bool premium, required HabitsRepository repository}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          body: SingleChildScrollView(child: TodayHabitsCard()),
        ),
      ),
      GoRoute(
        path: RoutePaths.premiumPromo,
        builder: (_, __) => const Scaffold(body: Text('promo')),
      ),
      GoRoute(
        path: RoutePaths.habits,
        builder: (_, __) => const Scaffold(body: Text('habits')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      premiumProfilesEnabledProvider.overrideWithValue(premium),
      habitsRepositoryProvider.overrideWithValue(repository),
      secureStorageServiceProvider.overrideWithValue(_MemStorage()),
      hydrationControllerProvider.overrideWith(_FakeHydrationController.new),
      homeClockProvider.overrideWithValue(() => DateTime(2026, 11, 2, 12)),
      activeProfileControllerProvider.overrideWith(_TestActiveProfileController.new),
      authControllerProvider.overrideWith(_TestAuthController.new),
    ],
    child: MaterialApp.router(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  late _MockHabitsRepository repository;

  setUp(() {
    repository = _MockHabitsRepository();
    registerFallbackValue(const HabitDay(day: '2026-11-02'));
    when(() => repository.getHabits(days: 60)).thenAnswer((_) async => []);
    when(() => repository.getTrackMenstrualCycleSetting())
        .thenAnswer((_) async => false);
    when(() => repository.syncPending()).thenAnswer((_) async {});
    when(() => repository.saveHabitDay(any())).thenAnswer(
        (inv) async => inv.positionalArguments.first as HabitDay);
  });

  testWidgets('Premium shows sleep, movement and water tiles; movement saves inline',
      (tester) async {
    await tester.pumpWidget(_app(premium: true, repository: repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_habit_tile_sleep')), findsOneWidget);
    expect(find.byKey(const Key('home_habit_tile_movement')), findsOneWidget);
    expect(find.byKey(const Key('home_habit_tile_water')), findsOneWidget);
    expect(find.text('650 ml'), findsOneWidget);
    expect(find.byKey(const Key('home_habits_premium_teaser')), findsNothing);

    await tester.tap(find.byKey(const Key('home_habit_moved_yes')));
    await tester.pumpAndSettle();

    verify(() => repository.saveHabitDay(any(
          that: isA<HabitDay>()
              .having((h) => h.day, 'day', '2026-11-02')
              .having((h) => h.moved, 'moved', true),
        ))).called(1);
    expect(find.text('Se mexeu'), findsOneWidget);
  });

  testWidgets('Free shows water and a Premium teaser that opens the promo',
      (tester) async {
    await tester.pumpWidget(_app(premium: false, repository: repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_habit_tile_sleep')), findsNothing);
    expect(find.byKey(const Key('home_habit_tile_movement')), findsNothing);
    expect(find.byKey(const Key('home_habit_tile_water')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_habits_premium_teaser')));
    await tester.pumpAndSettle();
    expect(find.text('promo'), findsOneWidget);
    verifyNever(() => repository.getHabits(days: any(named: 'days')));
  });

  testWidgets('Free build: /habits opens the Premium promo', (tester) async {
    late GoRouter router;
    await tester.pumpWidget(ProviderScope(
      overrides: [premiumProfilesEnabledProvider.overrideWithValue(false)],
      child: Consumer(builder: (context, ref, _) {
        router = createRouter(initialLocation: RoutePaths.premiumPromo);
        return MaterialApp.router(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        );
      }),
    ));
    router.go(RoutePaths.habits);
    await tester.pump();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        RoutePaths.premiumPromo);
  });
}
