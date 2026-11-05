import 'dart:async';

import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/biometric_lock_controller.dart';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/core/voice/voice_input_service.dart';
import 'package:dualis_mobile/core/voice/voice_matcher.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/dashboard/presentation/screens/check_in_summary_screen.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_controller.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
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

/// Plays queued phrases as if spoken; an empty queue is silence.
class FakeVoiceInput implements VoiceInputService {
  final List<String> phrases;
  VoiceStartError? startError;
  int listenCalls = 0;
  bool lastDictation = false;

  FakeVoiceInput([List<String>? phrases]) : phrases = phrases ?? [];

  @override
  Future<VoiceStartError?> prepare() async => startError;

  @override
  Future<void> listen({
    required String languageCode,
    required bool dictation,
    required void Function(String text, bool isFinal) onResult,
    required void Function() onDone,
  }) async {
    listenCalls++;
    lastDictation = dictation;
    scheduleMicrotask(() {
      if (phrases.isEmpty) {
        onDone();
        return;
      }
      final phrase = phrases.removeAt(0);
      onResult(phrase, false);
      onResult(phrase, true);
      // Like the platform: a "done" status always follows the final text.
      scheduleMicrotask(onDone);
    });
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

class LockedApp extends BiometricLockController {
  @override
  BiometricLockState build() => const BiometricLockState(enabled: true, locked: true);
}

class SignedIn extends AuthController {
  @override
  AuthState build() => const AuthState(isAuthenticated: true);
}

void main() {
  final pt = AppLocalizationsPt();

  group('VoiceMatcher', () {
    test('ignores accents, case and filler words', () {
      expect(VoiceMatcher.score('Estou CANSADA', 'Cansado'), greaterThanOrEqualTo(VoiceMatcher.strong));
      expect(VoiceMatcher.score('três', 'Tres'), 1);
      expect(VoiceMatcher.score('banana', 'Cansado'), 0);
    });

    test('exact label beats a label contained in the phrase', () {
      expect(
        VoiceMatcher.score('não tão bem', 'Não tão bem'),
        greaterThan(VoiceMatcher.score('não tão bem', 'Bem')),
      );
    });

    test('help words are found inside a sentence', () {
      final help = VoiceMatcher.aliases(pt.voiceAliasHelp);
      expect(VoiceMatcher.containsPhrase('eu preciso de ajuda agora', help), isTrue);
      expect(VoiceMatcher.containsPhrase('o que me ajudou foi dormir', help), isFalse);
    });

    test('splits multi-choice answers', () {
      expect(VoiceMatcher.segments('cansado e ansioso'), ['cansado', 'ansioso']);
    });
  });

  group('Voice in the daily check-in', () {
    late JournalHarness harness;
    late FakeVoiceInput voice;

    Future<GoRouter> pump(WidgetTester tester, {required bool premium, bool locked = false}) async {
      harness = JournalHarness()..premium = premium;
      tester.view.physicalSize = const Size(1000, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: RoutePaths.journal,
        routes: [
          GoRoute(
            path: RoutePaths.journal,
            builder: (context, state) => const JournalFlowScreen(),
          ),
          GoRoute(
            path: RoutePaths.emergency,
            builder: (context, state) => const Scaffold(body: Text('HELP SCREEN')),
          ),
          GoRoute(
            path: RoutePaths.checkInSummary,
            builder: (context, state) {
              final entry = (state.extra as CheckInSummaryArgs?)?.entry;
              return Scaffold(
                body: Text(
                  'SUMMARY items=${entry?.items.length} note=${entry?.note}',
                  key: const Key('summary_stub'),
                ),
              );
            },
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
            if (locked) biometricLockControllerProvider.overrideWith(LockedApp.new),
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

    Future<void> say(WidgetTester tester, String phrase) async {
      await containerOf(tester).read(voiceControllerProvider.notifier).handlePhrase(phrase);
      await tester.pumpAndSettle();
    }

    final time = JournalKeys.emotionalTree.keys.first;
    final branch = JournalKeys.emotionalTree[time]!.keys.first;
    final option = JournalKeys.emotionalTree[time]![branch]!.first;
    final optionKey = '$time.$branch.$option';

    testWidgets('Free build: no mic, no dictation and voice never starts', (tester) async {
      voice = FakeVoiceInput(['não tão bem']);
      await pump(tester, premium: false);
      expect(find.byKey(const Key('voice_mic_button')), findsNothing);

      await containerOf(tester).read(voiceControllerProvider.notifier).startCommands();
      await tester.pumpAndSettle();
      expect(voice.listenCalls, 0);
      expect(find.byKey(const Key('jv2_mood_nao_tao_bem')), findsOneWidget);

      // Saying an option does nothing: nothing is registered on Free.
      await say(tester, 'não tão bem');
      expect(find.byKey(const Key('jv2_mood_nao_tao_bem')), findsOneWidget);
    });

    testWidgets('Premium: whole check-in answered by voice, hands-free', (tester) async {
      voice = FakeVoiceInput([
        'não tão bem',
        JournalLabels.root(pt, time),
        JournalLabels.branch(pt, '$time.$branch'),
        JournalLabels.option(pt, optionKey),
        'próximo',
        'hoje',
        'três',
        'continuar',
        'pular',
        'pular',
        'hoje foi um dia longo',
        'salvar',
      ]);
      await pump(tester, premium: true);
      expect(find.byKey(const Key('voice_mic_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('voice_mic_button')));
      // Small steps, so each answer lands on the screen it was said on.
      for (var i = 0; i < 200 && find.byKey(const Key('summary_stub')).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
      }

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.textContaining('SUMMARY items=1 note=hoje foi um dia longo'), findsOneWidget);
      final saved = harness.remote.created.single;
      expect(saved.items.single.optionKey, optionKey);
      expect(saved.items.single.intensity, 3);
      expect(saved.items.single.persistence, JournalKeys.persistenceHoje);
      // Left the flow: hands-free stopped by itself.
      expect(containerOf(tester).read(voiceControllerProvider).listening, isFalse);
      expect(containerOf(tester).read(voiceControllerProvider).handsFree, isFalse);
    });

    testWidgets('"ajuda" opens the help screen from any step', (tester) async {
      voice = FakeVoiceInput();
      await pump(tester, premium: true);
      await say(tester, 'não tão bem');
      await say(tester, 'eu preciso de ajuda');
      expect(find.text('HELP SCREEN'), findsOneWidget);
    });

    testWidgets('several options in one answer, and "voltar"', (tester) async {
      voice = FakeVoiceInput();
      await pump(tester, premium: true);
      await say(tester, 'não tão bem');
      await say(tester, JournalLabels.root(pt, time));
      await say(tester, JournalLabels.branch(pt, '$time.$branch'));
      final options = JournalKeys.emotionalTree[time]![branch]!.take(2).toList();
      final labels = [for (final o in options) JournalLabels.option(pt, '$time.$branch.$o')];
      await say(tester, '${labels[0]} e ${labels[1]}');
      expect(
        containerOf(tester).read(journalFlowControllerProvider).selectedOptions,
        {for (final o in options) '$time.$branch.$o'},
      );
      await say(tester, 'voltar');
      expect(find.byKey(Key('jv2_branch_$time.$branch')), findsOneWidget);
    });

    testWidgets('unknown phrase changes nothing and says so', (tester) async {
      voice = FakeVoiceInput();
      await pump(tester, premium: true);
      await say(tester, 'abacaxi voador');
      expect(find.byKey(const Key('jv2_mood_nao_tao_bem')), findsOneWidget);
      expect(
        containerOf(tester).read(voiceControllerProvider).feedback?.kind,
        VoiceFeedbackKind.notUnderstood,
      );
    });

    testWidgets('silence changes nothing and says nothing was heard', (tester) async {
      voice = FakeVoiceInput();
      await pump(tester, premium: true);
      await say(tester, '  ');
      expect(find.byKey(const Key('jv2_mood_nao_tao_bem')), findsOneWidget);
      expect(
        containerOf(tester).read(voiceControllerProvider).feedback?.kind,
        VoiceFeedbackKind.notHeard,
      );
    });

    testWidgets('dictation writes into the note field', (tester) async {
      voice = FakeVoiceInput(['dormi pouco']);
      await pump(tester, premium: true);
      for (final phrase in ['não tão bem', JournalLabels.root(pt, time),
          JournalLabels.branch(pt, '$time.$branch'),
          JournalLabels.option(pt, optionKey), 'continuar', 'hoje', 'três', 'continuar',
          'pular', 'pular']) {
        await say(tester, phrase);
      }
      expect(find.byKey(const Key('voice_dictate_note')), findsOneWidget);
      await tester.tap(find.byKey(const Key('voice_dictate_note')));
      await tester.pumpAndSettle();
      expect(voice.lastDictation, isTrue);
      final field = tester.widget<TextField>(find.byKey(const Key('jv2_note_field')));
      expect(field.controller!.text, 'dormi pouco');
    });

    testWidgets('app locked: voice does not start and only "ajuda" acts', (tester) async {
      voice = FakeVoiceInput(['não tão bem']);
      await pump(tester, premium: true, locked: true);
      await containerOf(tester).read(voiceControllerProvider.notifier).startCommands();
      await tester.pumpAndSettle();
      expect(voice.listenCalls, 0);

      await say(tester, 'não tão bem');
      expect(containerOf(tester).read(journalFlowControllerProvider).mood, isNull);

      await say(tester, 'ajuda');
      expect(find.text('HELP SCREEN'), findsOneWidget);
    });

    testWidgets('a step sliding out no longer answers', (tester) async {
      voice = FakeVoiceInput();
      await pump(tester, premium: true);
      final notifier = containerOf(tester).read(voiceControllerProvider.notifier);
      await notifier.handlePhrase('não tão bem');
      await tester.pump(const Duration(milliseconds: 50)); // mid-transition
      // "Bem" is still painted (fading out) but must not be picked.
      await notifier.handlePhrase('bem');
      await tester.pumpAndSettle();
      final flow = containerOf(tester).read(journalFlowControllerProvider);
      expect(flow.mood, JournalKeys.moodNaoTaoBem);
      expect(flow.step, JournalStep.time);
    });

    testWidgets('hands-free stops after 3 phrases not understood', (tester) async {
      voice = FakeVoiceInput(['abacaxi', 'televisão ligada', 'conversa na sala', 'não tão bem']);
      await pump(tester, premium: true);
      await tester.tap(find.byKey(const Key('voice_mic_button')));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      final state = containerOf(tester).read(voiceControllerProvider);
      expect(state.listening, isFalse);
      expect(state.handsFree, isFalse);
      expect(voice.listenCalls, 3);
      expect(voice.phrases, ['não tão bem']);
    });

    testWidgets('on the help screen voice never closes it', (tester) async {
      voice = FakeVoiceInput();
      final router = await pump(tester, premium: true);
      router.push(RoutePaths.emergency);
      await tester.pumpAndSettle();
      await say(tester, 'voltar');
      expect(find.text('HELP SCREEN'), findsOneWidget);
    });

    testWidgets('permission denied shows the settings hint', (tester) async {
      voice = FakeVoiceInput()..startError = VoiceStartError.permissionDenied;
      await pump(tester, premium: true);
      await tester.tap(find.byKey(const Key('voice_mic_button')));
      await tester.pumpAndSettle();
      final state = containerOf(tester).read(voiceControllerProvider);
      expect(state.listening, isFalse);
      expect(state.feedback?.kind, VoiceFeedbackKind.permissionDenied);
    });
  });
}
