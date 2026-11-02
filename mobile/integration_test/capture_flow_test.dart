import 'dart:io';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/habits/data/habits_repository.dart';
import 'package:dualis_mobile/features/habits/presentation/screens/habits_screen.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/journal_flow_screen.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import '../test/features/journal/journal_test_helpers.dart';

class _MaleActiveProfileNotifier extends ActiveProfileController {
  @override
  ActiveProfileState build() => const ActiveProfileState(
        profiles: [
          Profile(
            id: 'p-male',
            name: 'Carlos',
            profileType: ProfileType.primary,
            ownership: ProfileOwnership.own,
            accessLevel: ProfileAccessLevel.owner,
            gender: 'masculino',
          ),
        ],
        activeProfileId: 'p-male',
      );
}

class _FemaleActiveProfileNotifier extends ActiveProfileController {
  @override
  ActiveProfileState build() => const ActiveProfileState(
        profiles: [
          Profile(
            id: 'p-female',
            name: 'Ana',
            profileType: ProfileType.primary,
            ownership: ProfileOwnership.own,
            accessLevel: ProfileAccessLevel.owner,
            gender: 'feminino',
          ),
        ],
        activeProfileId: 'p-female',
      );
}

class _MockHabitsRepo extends Mock implements HabitsRepository {}

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

Future<void> _capture(String name) async {
  try {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:8999/screenshot?name=$name'));
    final res = await req.close();
    await res.drain();
  } catch (e) {
    debugPrint('Capture error for $name: $e');
  }
  await Future.delayed(const Duration(milliseconds: 300));
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await Future.delayed(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flow 1: Capture Physical Male flow with urination additions and male filtering', (tester) async {
    final harness = JournalHarness();
    final router = GoRouter(
      initialLocation: RoutePaths.journal,
      routes: [
        GoRoute(
          path: RoutePaths.journal,
          builder: (context, state) => const JournalFlowScreen(
            args: JournalFlowArgs(initialArea: JournalArea.physical),
          ),
        ),
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: RoutePaths.emergency,
          builder: (context, state) => const Scaffold(body: Text('HELP SCREEN')),
        ),
        GoRoute(
          path: RoutePaths.checkInSummary,
          builder: (context, state) => const Scaffold(body: Text('SUMMARY')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...harness.overrides,
          activeProfileControllerProvider.overrideWith(_MaleActiveProfileNotifier.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
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
      ),
    );
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 400));

    // 01. Physical Mood Screen (Carlos, Masculino)
    await _capture('01_male_humor_fisico');

    // Tap "Não tão bem"
    await _tapKey(tester, 'jv2_mood_nao_tao_bem');

    // 02. Body map: select Barriga and Pelve
    await _capture('02_male_mapa_corpo_frente');
    await _tapKey(tester, 'jv2_region_barriga');
    await _tapKey(tester, 'jv2_region_pelve');
    await _capture('02b_male_mapa_corpo_selecionado');
    await _tapKey(tester, 'jv2_continue');

    // 03. Region 1: Barriga -> Sensation: Dor -> Branch: Cólica
    await _tapKey(tester, 'jv2_sensation_dor');
    await _tapKey(tester, 'jv2_branch_barriga.colica');
    // Notice: menstrual is NOT present! only gases!
    await _capture('03_male_barriga_colica_sem_menstrual');
    await _tapKey(tester, 'jv2_option_barriga.colica.gases');
    await _tapKey(tester, 'jv2_continue');

    // 04. Region 2: Pelve -> Sensation: Incômodo -> Branch: Urina
    await _tapKey(tester, 'jv2_sensation_incomodo');
    await _tapKey(tester, 'jv2_branch_pelve.urina');
    // Notice: ardencia, vontade, AND new options dificuldade, cor_odor are visible!
    await _capture('04_male_pelve_urina_novas_opcoes');
    await _tapKey(tester, 'jv2_option_pelve.urina.dificuldade');
    await _tapKey(tester, 'jv2_continue');

    // 05. Intensity screen: 2 items
    await _capture('05_male_intensidade_dois_itens');
    await _tapKey(tester, 'jv2_persistence_0_hoje');
    await _tapKey(tester, 'jv2_persistence_1_hoje');
    await _tapKey(tester, 'jv2_continue');
    await _tapKey(tester, 'jv2_intensity_0_3');
    await _tapKey(tester, 'jv2_intensity_1_4');
    await _capture('05b_male_intensidade_preenchida');
    await _tapKey(tester, 'jv2_continue');

    // 06. Triggers / Fatores: Corpo tab (ciclo is NOT present for male!)
    await _tapKey(tester, 'jv2_topic_corpo');
    await _capture('06_male_fatores_corpo_sem_ciclo');
    await _tapKey(tester, 'jv2_continue');

    // 07. Fechamento Físico: physical coping question + physical relief helpers
    await _capture('07_male_fechamento_fisico_opcoes');
    await _tapKey(tester, 'jv22_coping_consegui');
    await _tapKey(tester, 'jv22_helper_beber_agua');
    await _tapKey(tester, 'jv22_helper_remedio');
    await _capture('07b_male_fechamento_fisico_marcado');
    await _tapKey(tester, 'jv2_continue');

    // 08. Resumo / Nota
    await _capture('08_male_resumo_nota');
  });

  testWidgets('Flow 2: Capture Female comparison (menstrual branch and ciclo trigger present)', (tester) async {
    final harness = JournalHarness();
    final router = GoRouter(
      initialLocation: RoutePaths.journal,
      routes: [
        GoRoute(
          path: RoutePaths.journal,
          builder: (context, state) => const JournalFlowScreen(
            args: JournalFlowArgs(initialArea: JournalArea.physical),
          ),
        ),
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...harness.overrides,
          activeProfileControllerProvider.overrideWith(_FemaleActiveProfileNotifier.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
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
      ),
    );
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 400));

    await _tapKey(tester, 'jv2_mood_nao_tao_bem');
    await _tapKey(tester, 'jv2_region_barriga');
    await _tapKey(tester, 'jv2_continue');

    await _tapKey(tester, 'jv2_sensation_dor');
    await _tapKey(tester, 'jv2_branch_barriga.colica');
    // Notice: menstrual IS present for female!
    await _capture('09_female_barriga_colica_com_menstrual');
    await _tapKey(tester, 'jv2_option_barriga.colica.menstrual');
    await _tapKey(tester, 'jv2_continue');

    await _tapKey(tester, 'jv2_persistence_0_hoje');
    await _tapKey(tester, 'jv2_intensity_0_3');
    await _tapKey(tester, 'jv2_continue');

    // Corpo tab has Ciclo menstrual trigger!
    await _tapKey(tester, 'jv2_topic_corpo');
    await _capture('10_female_fatores_corpo_com_ciclo');
  });

  testWidgets('Flow 3: Capture Emotional flow and emotional closing helpers', (tester) async {
    final harness = JournalHarness();
    final router = GoRouter(
      initialLocation: RoutePaths.journal,
      routes: [
        GoRoute(
          path: RoutePaths.journal,
          builder: (context, state) => const JournalFlowScreen(),
        ),
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: harness.overrides,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
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
      ),
    );
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 400));

    // Emotional Mood Screen
    await _capture('11_emotional_humor');
    await _tapKey(tester, 'jv2_mood_nao_tao_bem');

    // Emotional times, then branches
    await _capture('12_emotional_o_que_pesa');
    await _tapKey(tester, 'jv2_time_futuro');
    await _capture('12b_emotional_bifurcacao');
    await _tapKey(tester, 'jv2_branch_futuro.mente');

    // Emotional options
    await _capture('13_emotional_opcoes');
    await _tapKey(tester, 'jv2_option_futuro.mente.antecipar');
    await _tapKey(tester, 'jv2_continue');

    // Intensity
    await _tapKey(tester, 'jv2_persistence_0_hoje');
    await _tapKey(tester, 'jv2_intensity_0_4');
    await _capture('14_emotional_intensidade');
    await _tapKey(tester, 'jv2_continue');

    // Skip factors
    await _tapKey(tester, 'jv2_skip');

    // Emotional Fechamento (O que te ajudou hoje? + emotional helpers: mover o corpo, respirar, conversar...)
    await _capture('15_emotional_fechamento_opcoes');
    await _tapKey(tester, 'jv22_coping_esperei');
    await _tapKey(tester, 'jv22_helper_pausa');
    await _capture('15b_emotional_fechamento_marcado');
    await _tapKey(tester, 'jv2_continue');

    await _capture('16_emotional_resumo_nota');
  });

  testWidgets('Flow 4: Capture Habits screen comparison (Male vs Female menstrual cycle)', (tester) async {
    final repo = _MockHabitsRepo();
    final storage = _MemStorage();
    when(() => repo.getHabits(
          days: any(named: 'days'),
          profileId: any(named: 'profileId'),
        )).thenAnswer((_) async => []);
    when(() => repo.getTrackMenstrualCycleSetting(
          profileId: any(named: 'profileId'),
        )).thenAnswer((_) async => true);
    when(() => repo.syncPending(
          profileId: any(named: 'profileId'),
        )).thenAnswer((_) async {});

    final routerMale = GoRouter(
      initialLocation: '/habits',
      routes: [
        GoRoute(
          path: '/habits',
          builder: (_, __) => const HabitsScreen(),
        ),
      ],
    );

    // Male Habits Screen (top)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsRepositoryProvider.overrideWithValue(repo),
          secureStorageServiceProvider.overrideWithValue(storage),
          activeProfileControllerProvider.overrideWith(_MaleActiveProfileNotifier.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: routerMale,
          locale: const Locale('pt'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 500));
    await _capture('17_habits_male_sem_menstruacao');

    // Male Habits Screen (scrolled: shows end of cards with NO menstrual card)
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 300));
    await _capture('17b_habits_male_sem_menstruacao_scrolled');

    // Female Habits Screen (top)
    final routerFemale = GoRouter(
      initialLocation: '/habits',
      routes: [
        GoRoute(
          path: '/habits',
          builder: (_, __) => const HabitsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsRepositoryProvider.overrideWithValue(repo),
          secureStorageServiceProvider.overrideWithValue(storage),
          activeProfileControllerProvider.overrideWith(_FemaleActiveProfileNotifier.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: routerFemale,
          locale: const Locale('pt'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 500));
    await _capture('18_habits_female_com_menstruacao');

    // Female Habits Screen (scrolled: shows menstrual tracking switch AND menstrual card)
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 300));
    await _capture('18b_habits_female_com_menstruacao_scrolled');
  });
}
