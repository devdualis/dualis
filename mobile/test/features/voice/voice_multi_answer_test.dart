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
class _QueuedVoiceInput implements VoiceInputService {
  _QueuedVoiceInput([List<String>? phrases]) : phrases = phrases ?? [];

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
      onResult(phrases.removeAt(0), true);
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
  final pt = AppLocalizationsPt();
  late JournalHarness harness;
  late _QueuedVoiceInput voice;

  final time = JournalKeys.emotionalTree.keys.first;
  final branch = JournalKeys.emotionalTree[time]!.keys.first;
  final options = JournalKeys.emotionalTree[time]![branch]!;
  final optionKey = '$time.$branch.${options.first}';
  final optionLabel = JournalLabels.option(pt, optionKey);

  Future<void> pump(WidgetTester tester) async {
    harness = JournalHarness()..premium = true;
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
          builder: (context, state) => const Scaffold(body: Text('SUMMARY')),
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
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  JournalFlowState flow(WidgetTester tester) =>
      containerOf(tester).read(journalFlowControllerProvider);

  VoiceFeedback? feedback(WidgetTester tester) =>
      containerOf(tester).read(voiceControllerProvider).feedback;

  /// Says [phrase] and lets every carried step play out.
  Future<void> say(WidgetTester tester, String phrase) async {
    await containerOf(tester).read(voiceControllerProvider.notifier).handlePhrase(phrase);
    await tester.pumpAndSettle();
  }

  /// Emotional check-in up to the options of the first time and branch.
  Future<void> toOptions(WidgetTester tester) async {
    await say(tester, 'não tão bem');
    await say(tester, JournalLabels.root(pt, time));
    await say(tester, JournalLabels.branch(pt, '$time.$branch'));
    expect(flow(tester).step, JournalStep.options);
  }

  setUp(() => voice = _QueuedVoiceInput());

  testWidgets('"<option>, começou hoje, intensidade três" fills three steps and stops on intensity',
      (tester) async {
    await pump(tester);
    await toOptions(tester);

    await say(tester, '$optionLabel, começou hoje, intensidade três');

    final state = flow(tester);
    expect(state.step, JournalStep.intensity);
    final item = state.items.single;
    expect(item.optionKey, optionKey);
    expect(item.persistence, JournalKeys.persistenceHoje);
    expect(item.intensity, 3);
    // Continuar on the intensity step is left for the person.
    expect(feedback(tester)?.kind, VoiceFeedbackKind.heard);
    expect(harness.remote.created, isEmpty);
  });

  testWidgets('the same phrase without commas reaches the same end state', (tester) async {
    await pump(tester);
    await toOptions(tester);

    await say(tester, '$optionLabel começou hoje intensidade três');

    final state = flow(tester);
    expect(state.step, JournalStep.intensity);
    final item = state.items.single;
    expect(item.optionKey, optionKey);
    expect(item.persistence, JournalKeys.persistenceHoje);
    expect(item.intensity, 3);
    expect(harness.remote.created, isEmpty);
  });

  testWidgets('"<labelA> e <labelB>" still selects both options and stays on the step',
      (tester) async {
    await pump(tester);
    await toOptions(tester);
    final keys = [for (final o in options.take(2)) '$time.$branch.$o'];

    await say(tester, '${JournalLabels.option(pt, keys[0])} e ${JournalLabels.option(pt, keys[1])}');

    final state = flow(tester);
    expect(state.step, JournalStep.options);
    expect(state.selectedOptions, keys.toSet());
  });

  testWidgets('one answer with a single extra word keeps the one-answer behavior', (tester) async {
    await pump(tester);
    await toOptions(tester);

    await say(tester, '$optionLabel demais');

    final state = flow(tester);
    expect(state.step, JournalStep.options);
    expect(state.selectedOptions, {optionKey});
  });
}
