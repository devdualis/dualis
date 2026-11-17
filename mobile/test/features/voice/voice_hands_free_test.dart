import 'dart:async';

import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/core/voice/voice_input_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_controller.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/journal_flow_screen.dart';
import 'package:dualis_mobile/features/voice/presentation/voice_controller.dart';
import 'package:dualis_mobile/features/voice/presentation/voice_widgets.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../journal/journal_test_helpers.dart';

/// Plays queued phrases as if spoken; an empty queue is silence.
class _FakeVoiceInput implements VoiceInputService {
  _FakeVoiceInput([List<String>? phrases]) : phrases = phrases ?? [];

  final List<String> phrases;
  int listenCalls = 0;

  @override
  Future<VoiceStartError?> prepare() async => null;

  @override
  Future<void> listen({
    required String languageCode,
    required bool dictation,
    required void Function(String text, bool isFinal) onResult,
    required void Function() onDone,
  }) async {
    listenCalls++;
    scheduleMicrotask(() {
      if (phrases.isEmpty) {
        onDone();
        return;
      }
      final phrase = phrases.removeAt(0);
      onResult(phrase, true);
      scheduleMicrotask(onDone);
    });
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

class _SignedIn extends AuthController {
  @override
  AuthState build() => const AuthState(isAuthenticated: true);
}

void main() {
  late JournalHarness harness;
  late _FakeVoiceInput voice;

  /// Home stub with the mic, and the real check-in. [stubJournal] records
  /// the area the check-in was opened with instead.
  Future<GoRouter> pump(
    WidgetTester tester, {
    String initial = RoutePaths.home,
    List<JournalArea?>? stubJournal,
  }) async {
    harness = JournalHarness()..premium = true;
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: RoutePaths.journal,
          builder: (context, state) {
            final args = state.extra as JournalFlowArgs? ?? const JournalFlowArgs();
            if (stubJournal != null) {
              stubJournal.add(args.initialArea);
              return const Scaffold(body: Text('JOURNAL'));
            }
            return JournalFlowScreen(args: args);
          },
        ),
        GoRoute(
          path: RoutePaths.emergency,
          builder: (context, state) => const Scaffold(body: Text('HELP SCREEN')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...harness.overrides,
          appRouterProvider.overrideWithValue(router),
          voiceInputServiceProvider.overrideWithValue(voice),
          authControllerProvider.overrideWith(_SignedIn.new),
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
          builder: (context, child) => Stack(
            children: [child!, const Positioned(top: 0, right: 0, child: VoiceMicButton())],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  Future<void> run(WidgetTester tester, {int steps = 60}) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  group('Phrases that open the check-in from Home', () {
    const emotional = [
      'quero fazer o check-in',
      'fazer meu checkin',
      'fazer a verificação',
      'atualizar meu estado de hoje',
      'como estou hoje',
      'novo registro',
      'registrar meu dia',
      'vamos começar',
      'registrar humor',
    ];
    const physical = [
      'check-in do corpo',
      'atualizar meu estado físico',
      'como está meu corpo',
      'estou com dor',
    ];

    for (final phrase in [...emotional, ...physical]) {
      testWidgets('"$phrase"', (tester) async {
        voice = _FakeVoiceInput();
        final opened = <JournalArea?>[];
        final router = await pump(tester, stubJournal: opened);
        await containerOf(tester).read(voiceControllerProvider.notifier).handlePhrase(phrase);
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, RoutePaths.journal);
        expect(
          opened.single,
          physical.contains(phrase) ? JournalArea.physical : JournalArea.emotional,
        );
      });
    }
  });

  testWidgets('check-in opened by voice on Home stays hands-free', (tester) async {
    voice = _FakeVoiceInput(['quero fazer o check-in', 'não tão bem']);
    final router = await pump(tester);
    await tester.tap(find.byKey(const Key('voice_mic_button')));
    await run(tester);

    expect(router.state.matchedLocation, RoutePaths.journal);
    final flow = containerOf(tester).read(journalFlowControllerProvider);
    expect(flow.mood, JournalKeys.moodNaoTaoBem);
    // The mic opened again after each answer without a tap.
    expect(voice.listenCalls, greaterThanOrEqualTo(3));
    expect(voice.phrases, isEmpty);
  });

  testWidgets('a few silences do not end hands-free mode', (tester) async {
    voice = _FakeVoiceInput();
    await pump(tester, initial: RoutePaths.journal);
    await tester.tap(find.byKey(const Key('voice_mic_button')));
    await run(tester, steps: 80);

    final state = containerOf(tester).read(voiceControllerProvider);
    // Silence after silence: stops only after maxSilences, not after 3.
    expect(voice.listenCalls, VoiceController.maxSilences);
    expect(state.handsFree, isFalse);
    expect(state.listening, isFalse);
  });
}
