import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/habits/data/habits_repository.dart';
import 'package:dualis_mobile/features/habits/domain/models/habit_day.dart';
import 'package:dualis_mobile/features/habits/presentation/widgets/movement_modal.dart';
import 'package:dualis_mobile/features/habits/presentation/widgets/sleep_modal.dart';
import 'package:dualis_mobile/features/habits/presentation/widgets/today_habits_card.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

Widget _testApp({
  required HabitsRepository repository,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      premiumProfilesEnabledProvider.overrideWithValue(true),
      habitsRepositoryProvider.overrideWithValue(repository),
      secureStorageServiceProvider.overrideWithValue(_MemStorage()),
      hydrationControllerProvider.overrideWith(_FakeHydrationController.new),
      homeClockProvider.overrideWithValue(() => DateTime(2026, 11, 2, 12)),
      activeProfileControllerProvider.overrideWith(_TestActiveProfileController.new),
      authControllerProvider.overrideWith(_TestAuthController.new),
    ],
    child: MaterialApp(
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
      home: Scaffold(body: child),
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
      (inv) async => inv.positionalArguments.first as HabitDay,
    );
  });

  group('SleepModal & MovementModal', () {
    testWidgets('SleepModal shows sleep questions only and saves quality & hours',
        (tester) async {
      await tester.pumpWidget(_testApp(
        repository: repository,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SleepModal.show(context),
            child: const Text('Open Sleep'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sleep'));
      await tester.pumpAndSettle();

      // Only sleep options are present
      expect(find.byKey(const Key('habits_sleep_bem')), findsOneWidget);
      expect(find.byKey(const Key('habits_sleep_regular')), findsOneWidget);
      expect(find.byKey(const Key('habits_sleep_mal')), findsOneWidget);
      expect(find.byKey(const Key('habits_hours_7_8')), findsOneWidget);

      // Movement options must NOT be in the sleep modal
      expect(find.byKey(const Key('habits_moved_sim')), findsNothing);
      expect(find.byKey(const Key('habits_moved_nao')), findsNothing);

      // Tap 'Dormi bem'
      await tester.tap(find.byKey(const Key('habits_sleep_bem')));
      await tester.pumpAndSettle();

      verify(() => repository.saveHabitDay(any(
            that: isA<HabitDay>()
                .having((h) => h.day, 'day', '2026-11-02')
                .having((h) => h.sleepQuality, 'sleepQuality', HabitSleepQuality.bem),
          ))).called(1);

      // Tap '7 a 8 h'
      await tester.tap(find.byKey(const Key('habits_hours_7_8')));
      await tester.pumpAndSettle();

      verify(() => repository.saveHabitDay(any(
            that: isA<HabitDay>()
                .having((h) => h.day, 'day', '2026-11-02')
                .having((h) => h.sleepHours, 'sleepHours', HabitSleepHours.hours7To8),
          ))).called(1);

      // Close modal
      await tester.tap(find.byKey(const Key('sleep_modal_done')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habits_sleep_bem')), findsNothing);
    });

    testWidgets('MovementModal shows movement questions only and manages duration chips',
        (tester) async {
      await tester.pumpWidget(_testApp(
        repository: repository,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MovementModal.show(context),
            child: const Text('Open Movement'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Movement'));
      await tester.pumpAndSettle();

      // Only movement options are present
      expect(find.byKey(const Key('habits_moved_sim')), findsOneWidget);
      expect(find.byKey(const Key('habits_moved_nao')), findsOneWidget);

      // Sleep options must NOT be in the movement modal
      expect(find.byKey(const Key('habits_sleep_bem')), findsNothing);
      expect(find.byKey(const Key('habits_hours_7_8')), findsNothing);

      // Duration chips initially hidden when moved is not true
      expect(find.byKey(const Key('habits_minutes_15_30')), findsNothing);

      // Tap 'Sim'
      await tester.tap(find.byKey(const Key('habits_moved_sim')));
      await tester.pumpAndSettle();

      verify(() => repository.saveHabitDay(any(
            that: isA<HabitDay>()
                .having((h) => h.day, 'day', '2026-11-02')
                .having((h) => h.moved, 'moved', true),
          ))).called(1);

      // Duration chips now visible
      expect(find.byKey(const Key('habits_minutes_15_30')), findsOneWidget);

      // Tap '15 a 30 min'
      await tester.tap(find.byKey(const Key('habits_minutes_15_30')));
      await tester.pumpAndSettle();

      verify(() => repository.saveHabitDay(any(
            that: isA<HabitDay>()
                .having((h) => h.day, 'day', '2026-11-02')
                .having((h) => h.movementMinutes, 'movementMinutes',
                    HabitMovementMinutes.minutes15To30),
          ))).called(1);

      // Close modal
      await tester.tap(find.byKey(const Key('movement_modal_done')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habits_moved_sim')), findsNothing);
    });

    testWidgets('TodayHabitsCard opens SleepModal when tapping sleep tile or action',
        (tester) async {
      await tester.pumpWidget(_testApp(
        repository: repository,
        child: const SingleChildScrollView(child: TodayHabitsCard()),
      ));
      await tester.pumpAndSettle();

      // Tap Sleep action pill
      await tester.tap(find.byKey(const Key('home_habit_sleep_action')));
      await tester.pumpAndSettle();

      // Sleep modal opened, no movement options inside
      expect(find.byKey(const Key('habits_sleep_bem')), findsOneWidget);
      expect(find.byKey(const Key('habits_moved_sim')), findsNothing);

      // Close sleep modal
      await tester.tap(find.byKey(const Key('sleep_modal_done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('habits_sleep_bem')), findsNothing);

      // Tap Sleep tile directly
      await tester.tap(find.byKey(const Key('home_habit_tile_sleep')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('habits_sleep_bem')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sleep_modal_done')));
      await tester.pumpAndSettle();
    });

    testWidgets('TodayHabitsCard opens MovementModal when tapping movement tile',
        (tester) async {
      await tester.pumpWidget(_testApp(
        repository: repository,
        child: const SingleChildScrollView(child: TodayHabitsCard()),
      ));
      await tester.pumpAndSettle();

      // Tap Movement tile
      await tester.tap(find.byKey(const Key('home_habit_tile_movement')));
      await tester.pumpAndSettle();

      // Movement modal opened, no sleep options inside
      expect(find.byKey(const Key('habits_moved_sim')), findsOneWidget);
      expect(find.byKey(const Key('habits_sleep_bem')), findsNothing);

      // Close movement modal
      await tester.tap(find.byKey(const Key('movement_modal_done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('habits_moved_sim')), findsNothing);
    });
  });
}
