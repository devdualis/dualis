import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/habits/data/habits_repository.dart';
import 'package:dualis_mobile/features/habits/domain/models/habit_day.dart';
import 'package:dualis_mobile/features/habits/presentation/screens/habits_screen.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
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
  @override
  ActiveProfileState build() => const ActiveProfileState();
}

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.initial();
}

Widget createHabitsTestWidget({
  required HabitsRepository repository,
  required SecureStorageService storage,
  DateTime? clock,
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
      activeProfileControllerProvider.overrideWith(
        () => _TestActiveProfileController(),
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
}
