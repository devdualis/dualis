import 'dart:io';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/journal_flow_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/journal/journal_test_helpers.dart';

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
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture Emotional flow', (tester) async {
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

    // 1. Mood Screen (Tarjetas grandes B)
    await _capture('01_humor_cards');

    // Tap "Não tão bem"
    await _tapKey(tester, 'jv2_mood_nao_tao_bem');

    // 2. O que pesa mais agora? (Filas A + tiempo unificado)
    await _capture('02_o_que_pesa_filas');

    // Pick branch
    await _tapKey(tester, 'jv2_branch_futuro.mente');

    // 3. Marque o que combina com você (Filas con casillas + escrever com minhas palavras)
    await _capture('03_marque_opcoes');

    // Pick option
    await _tapKey(tester, 'jv2_option_futuro.mente.antecipar');
    await _capture('03b_opcao_marcada');

    await _tapKey(tester, 'jv2_continue');

    // 4. Intensidad (1 ítem: tarjetas B de duración + escala 1 a 5 con frase)
    await _capture('04_intensidade_1_item');

    // Select duration "Começou hoje" and intensity 4
    await _tapKey(tester, 'jv2_persistence_0_hoje');
    await _tapKey(tester, 'jv2_intensity_0_4');
    await _capture('04b_intensidade_marcada');

    await _tapKey(tester, 'jv2_continue');

    // 5. Factores (Pestañas Seu dia / Pessoas / Corpo + Não sei / Outro)
    await _capture('05_fatores_abas_dia');

    // Select trigger in 'dia'
    await _tapKey(tester, 'jv2_trigger_trabalho');

    // Switch to Pessoas tab
    await _tapKey(tester, 'jv2_topic_pessoas');
    await _capture('05b_fatores_abas_pessoas');

    // Switch to Corpo tab
    await _tapKey(tester, 'jv2_topic_corpo');
    await _capture('05c_fatores_abas_corpo');

    await _tapKey(tester, 'jv2_continue');

    // 6. Cierre (Como foi lidar + O que te ajudou con la misma tarjeta B)
    await _capture('06_fechamento_cartoes');

    // Select coping and helpers
    await _tapKey(tester, 'jv22_coping_esperei');
    await _tapKey(tester, 'jv22_helper_pausa');
    await _capture('06b_fechamento_marcado');

    await _tapKey(tester, 'jv2_continue');

    // 7. Resumen / Nota opcional
    await _capture('07_resumo_nota');
  });

  testWidgets('Capture Physical flow', (tester) async {
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

    // Physical Mood Screen (Axis label FÍSICO)
    await _capture('08_humor_fisico');
    await _tapKey(tester, 'jv2_mood_nao_tao_bem');

    // Body map screen
    await _capture('09_mapa_corpo_frente');
    await _tapKey(tester, 'jv2_region_cabeca');
    await _tapKey(tester, 'jv2_side_back');
    await _capture('10_mapa_corpo_dorso');
    await _tapKey(tester, 'jv2_region_costas');
    await _tapKey(tester, 'jv2_continue');

    // Region 1: cabeça - Sensation first (Dor ou Incômodo cards B)
    await _capture('11_sensacao_dor_incomodo');
    await _tapKey(tester, 'jv2_sensation_dor');
    await _tapKey(tester, 'jv2_branch_cabeca.pressao');
    await _capture('11b_cabeca_opcoes');
    await _tapKey(tester, 'jv2_option_cabeca.pressao.temporas');
    await _tapKey(tester, 'jv2_continue');

    // Region 2: costas
    await _tapKey(tester, 'jv2_sensation_incomodo');
    await _tapKey(tester, 'jv2_branch_costas.rigidez');
    await _tapKey(tester, 'jv2_option_costas.rigidez.lombar');
    await _tapKey(tester, 'jv2_continue');

    // Multi-item compact intensity screen! (Tarjetas compactas con selector de duración y 5 números)
    await _capture('12_intensidade_compacta_2_itens');
  });
}
