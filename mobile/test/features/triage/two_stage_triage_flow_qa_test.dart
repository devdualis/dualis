import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/journal_flow_screen.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createTwoStageQATestApp({
  ProviderContainer? container,
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.journal,
        builder: (context, state) {
          final args = state.extra as JournalFlowArgs?;
          return _MockTriageStep4Screen(
            vertical: args?.initialArea == JournalArea.physical
                ? TriageVertical.fisica
                : TriageVertical.psicoEmocional,
          );
        },
      ),
    ],
  );

  final app = MaterialApp.router(
    routerConfig: router,
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );

  return container != null
      ? UncontrolledProviderScope(container: container, child: app)
      : ProviderScope(child: app);
}

/// Simulated Step 4 Screen containing the optional narrative TextField and submit button
class _MockTriageStep4Screen extends ConsumerStatefulWidget {
  final TriageVertical vertical;
  const _MockTriageStep4Screen({required this.vertical});

  @override
  ConsumerState<_MockTriageStep4Screen> createState() => _MockTriageStep4ScreenState();
}

class _MockTriageStep4ScreenState extends ConsumerState<_MockTriageStep4Screen> {
  late final TextEditingController _narrativeController;

  @override
  void initState() {
    super.initState();
    _narrativeController = TextEditingController();
  }

  @override
  void dispose() {
    _narrativeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Triagem: ${widget.vertical.name}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Pré-visualização do Relatório'),
            TextField(
              key: const Key('triageOptionalNarrativeInput'),
              controller: _narrativeController,
              decoration: const InputDecoration(
                labelText: 'Descrição adicional (opcional)',
              ),
            ),
            const Spacer(),
            FilledButton(
              key: const Key('confirmAndFinishTriageButton'),
              onPressed: () {
                final text = _narrativeController.text.trim();
                ref.read(triggerCheckInProvider.notifier).completeStage(
                      vertical: widget.vertical,
                      summary: 'Bem / Ótimo',
                      narrative: text.isNotEmpty ? text : null,
                    );
                context.go(RoutePaths.home);
              },
              child: const Text('Confirmar e Finalizar'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QA Feature 3: Check-in em 2 etapas com narrativa opcional e resumo na Home', () {
    testWidgets('QA 3.1: Home renders Psicoemocional & Avaliação Física with direct action buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTwoStageQATestApp());
      await tester.pumpAndSettle();

      expect(find.text('Check-in Diário em 2 Etapas'), findsOneWidget);
      expect(find.text('Psicoemocional'), findsOneWidget);
      expect(find.text('Físico'), findsOneWidget);

      expect(find.byKey(const Key('start_psicoemocional_triage_button')), findsOneWidget);
      expect(find.byKey(const Key('start_fisica_triage_button')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('start_psicoemocional_triage_button')),
          matching: find.byIcon(Icons.psychology_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('start_fisica_triage_button')),
          matching: find.byIcon(Icons.accessibility_new_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('QA 3.2: Complete Psicoemocional with optional narrative returns to Home and updates its card',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTwoStageQATestApp());
      await tester.pumpAndSettle();

      // Tap start Psicoemocional
      await tester.tap(find.byKey(const Key('start_psicoemocional_triage_button')));
      await tester.pumpAndSettle();

      // Verify on triage preview with narrative field
      expect(find.byKey(const Key('triageOptionalNarrativeInput')), findsOneWidget);

      // Type narrative
      await tester.enterText(
        find.byKey(const Key('triageOptionalNarrativeInput')),
        'Dia produtivo porém com leve ansiedade à tarde',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('confirmAndFinishTriageButton')));
      await tester.pumpAndSettle();

      // Navigated back to Home
      expect(find.text('Check-in Diário em 2 Etapas'), findsOneWidget);

      // Psicoemocional card updated with summary, badge, narrative quote and Refazer
      expect(find.byKey(const Key('psicoemocional_completed_card')), findsOneWidget);
      expect(find.text('Bem / Ótimo'), findsWidgets);
      expect(find.text('“Dia produtivo porém com leve ansiedade à tarde”'), findsOneWidget);
      expect(find.byKey(const Key('retake_psicoemocional_button')), findsOneWidget);

      // Avaliação Física remains pending and untouched
      expect(find.byKey(const Key('start_fisica_triage_button')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('start_fisica_triage_button')),
          matching: find.byIcon(Icons.accessibility_new_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('QA 3.3: Complete both stages updates both cards without the redundant banner',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      // Complete emotional
      notifier.completeStage(
        vertical: TriageVertical.psicoEmocional,
        summary: 'Bem / Ótimo',
        narrative: 'Mente calma',
      );
      // Complete physical
      notifier.completeStage(
        vertical: TriageVertical.fisica,
        summary: 'Normal / Bom',
        narrative: 'Sem dores corporais',
      );

      await tester.pumpWidget(createTwoStageQATestApp(container: container));
      await tester.pumpAndSettle();

      // Redundant overall banner is gone; each axis card confirms itself
      expect(find.byKey(const Key('dailyCheckInCompletedBanner')), findsNothing);

      // Both cards display their respective summaries
      expect(find.byKey(const Key('psicoemocional_completed_card')), findsOneWidget);
      expect(find.byKey(const Key('fisica_completed_card')), findsOneWidget);
      expect(find.text('“Mente calma”'), findsOneWidget);
      expect(find.text('“Sem dores corporais”'), findsOneWidget);
    });
  });
}
