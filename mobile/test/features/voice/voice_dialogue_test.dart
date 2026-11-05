import 'dart:async';

import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/core/voice/voice_input_service.dart';
import 'package:dualis_mobile/core/voice/voice_output_service.dart';
import 'package:dualis_mobile/core/voice/voice_targets.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/presentation/journal_labels.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/journal_flow_screen.dart';
import 'package:dualis_mobile/features/voice/presentation/voice_controller.dart';
import 'package:dualis_mobile/features/voice/presentation/voice_widgets.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../journal/journal_test_helpers.dart';

/// Plays queued phrases as if spoken (an empty queue is silence) and writes
/// `listen` into the same log as [FakeVoiceOutput], to prove the order.
class LoggedVoiceInput implements VoiceInputService {
  LoggedVoiceInput(this.log, [List<String>? phrases]) : phrases = phrases ?? [];

  final List<String> log;
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
    log.add('listen');
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

class SignedIn extends AuthController {
  @override
  AuthState build() => const AuthState(isAuthenticated: true);
}

/// A step with more options than are read aloud.
class _ManyOptions extends StatelessWidget {
  const _ManyOptions();

  static const labels = ['Um', 'Dois', 'Três', 'Quatro', 'Cinco', 'Seis', 'Sete', 'Oito'];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            const VoicePrompt(text: 'Escolha um número', child: Text('Escolha um número')),
            for (final l in labels)
              VoiceTarget(labels: [l], onSelect: () {}, child: Text(l)),
            VoiceTarget(
              labels: const ['Continuar'],
              onSelect: () {},
              role: VoiceTargetRole.advance,
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
}

void main() {
  final pt = AppLocalizationsPt();
  late JournalHarness harness;
  late LoggedVoiceInput voice;

  FakeVoiceOutput output() => harness.voiceOutput;

  Future<GoRouter> pump(
    WidgetTester tester, {
    List<String> phrases = const [],
    Widget? journal,
  }) async {
    harness = JournalHarness()..premium = true;
    voice = LoggedVoiceInput(harness.voiceOutput.log, [...phrases]);
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: RoutePaths.journal,
      routes: [
        GoRoute(
          path: RoutePaths.journal,
          builder: (context, state) => journal ?? const JournalFlowScreen(),
        ),
        GoRoute(
          path: RoutePaths.emergency,
          builder: (context, state) => const Scaffold(body: Text('HELP SCREEN')),
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
          appRouterProvider.overrideWithValue(router),
          voiceInputServiceProvider.overrideWithValue(voice),
          authControllerProvider.overrideWith(SignedIn.new),
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

  /// Lets hands-free run: reading, gaps and listen sessions.
  Future<void> run(WidgetTester tester, {int steps = 40}) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  final moodRead = composeReadOut(
    pt,
    pt.jv2MoodQuestion,
    [for (final m in JournalKeys.newEntryMoods) JournalLabels.mood(pt, m)],
  );
  final timeRead = composeReadOut(
    pt,
    pt.jv2TimeQuestion,
    [for (final t in JournalKeys.times) JournalLabels.root(pt, t)],
  );

  group('Hands-free check-in reads, then listens', () {
    testWidgets('the mood question and its options are read before the mic opens',
        (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('voice_mic_button')));
      await run(tester);

      expect(output().spoken.first, moodRead);
      expect(output().spoken.first, contains(JournalLabels.mood(pt, JournalKeys.moodBem)));
      // Never listening while speaking: speak, done, then listen.
      expect(output().log.take(4).toList(), ['prepare:pt', 'speak', 'done', 'listen']);
    });

    testWidgets('an answer that moves on reads the next step once, then listens',
        (tester) async {
      await pump(tester, phrases: [JournalLabels.mood(pt, JournalKeys.moodNaoTaoBem)]);
      await tester.tap(find.byKey(const Key('voice_mic_button')));
      await run(tester);

      expect(output().spoken, [moodRead, timeRead]);
      expect(
        output().log.take(8).toList(),
        ['prepare:pt', 'speak', 'done', 'listen', 'prepare:pt', 'speak', 'done', 'listen'],
      );
    });

    testWidgets('a phrase not understood keeps the step and is not read again',
        (tester) async {
      await pump(tester, phrases: ['abacaxi voador']);
      await tester.tap(find.byKey(const Key('voice_mic_button')));
      await run(tester);

      expect(output().spoken, [moodRead]);
      final log = output().log;
      expect(log.take(5).toList(), ['prepare:pt', 'speak', 'done', 'listen', 'listen']);
      expect(log.where((e) => e == 'speak'), hasLength(1));
      expect(find.byKey(const Key('jv2_mood_nao_tao_bem')), findsOneWidget);
    });

    testWidgets('a step with more than 6 options reads exactly 6', (tester) async {
      await pump(tester, journal: const _ManyOptions());
      await tester.tap(find.byKey(const Key('voice_mic_button')));
      await run(tester);

      expect(
        output().spoken.single,
        composeReadOut(pt, 'Escolha um número', _ManyOptions.labels),
      );
      expect(output().spoken.single, 'Escolha um número. Um, Dois, Três, Quatro, Cinco, Seis.');
      expect(output().spoken.single, isNot(contains('Sete')));
      expect(output().spoken.single, isNot(contains('Continuar')));
    });
  });

  test('composeReadOut keeps the question punctuation and reads nothing else', () {
    expect(composeReadOut(pt, 'Como está?', ['Bem', 'Mal']), 'Como está? Bem, Mal.');
    expect(composeReadOut(pt, 'Marque', ['A', ' ', 'B']), 'Marque. A, B.');
    expect(composeReadOut(pt, 'Só a pergunta?', const []), 'Só a pergunta?');
  });
}
