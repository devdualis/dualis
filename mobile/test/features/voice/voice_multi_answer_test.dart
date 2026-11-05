import 'dart:async';

import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/biometric_lock_controller.dart';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/core/voice/voice_input_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

/// Unlocked until the test engages the lock.
class _TestLock extends BiometricLockController {
  @override
  BiometricLockState build() => const BiometricLockState(enabled: true);

  void engage() => state = state.copyWith(locked: true);
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

  Future<void> pump(
    WidgetTester tester, {
    List<UserCondition> conditions = const [],
    JournalFlowArgs args = const JournalFlowArgs(),
  }) async {
    harness = JournalHarness(conditions: conditions)..premium = true;
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: RoutePaths.journal,
      routes: [
        GoRoute(
          path: RoutePaths.journal,
          builder: (context, state) => JournalFlowScreen(args: args),
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
          biometricLockControllerProvider.overrideWith(_TestLock.new),
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

  setUp(() {
    voice = _QueuedVoiceInput();
    FlutterSecureStorage.setMockInitialValues({});
  });

  VoiceController controller(WidgetTester tester) =>
      containerOf(tester).read(voiceControllerProvider.notifier);

  /// From the options step to the triggers step, one answer at a time.
  Future<void> toTriggers(WidgetTester tester) async {
    await toOptions(tester);
    for (final phrase in [optionLabel, 'continuar', 'hoje', 'três', 'continuar']) {
      await say(tester, phrase);
    }
    expect(flow(tester).step, JournalStep.triggers);
  }

  final triggerLabel = JournalLabels.trigger(pt, JournalKeys.triggerTopics.values.first.first);

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

  group('Safety rules', () {
    testWidgets('two items: the first gets "Começou hoje", the flow stops on the second',
        (tester) async {
      await pump(tester);
      await toOptions(tester);
      final keys = [for (final o in options.take(2)) '$time.$branch.$o'];
      final labels = [for (final k in keys) JournalLabels.option(pt, k)];

      await say(tester, '${labels[0]} e ${labels[1]}, começou hoje, intensidade três');

      final state = flow(tester);
      expect(state.step, JournalStep.persistence);
      expect(state.items.map((i) => i.optionKey), keys);
      expect(state.items[0].persistence, JournalKeys.persistenceHoje);
      expect(state.items[1].persistence, isNull);
      expect(state.items.every((i) => i.intensity == null), isTrue);
      expect(feedback(tester)?.kind, VoiceFeedbackKind.notUnderstood);
      expect(feedback(tester)?.text, 'intensidade tres');
    });

    testWidgets('triggers: "<trigger>, pular" picks the trigger and never skips', (tester) async {
      await pump(tester);
      await toTriggers(tester);

      await say(tester, '$triggerLabel, pular');

      final state = flow(tester);
      expect(state.step, JournalStep.triggers);
      expect(state.triggers, {JournalKeys.triggerTopics.values.first.first});
      expect(feedback(tester)?.kind, VoiceFeedbackKind.notUnderstood);
      expect(feedback(tester)?.text, 'pular');
    });

    testWidgets('note: "hoje foi longo, salvar" is written as a note and nothing is saved',
        (tester) async {
      await pump(tester);
      await toTriggers(tester);
      await say(tester, 'pular');
      await say(tester, 'pular');
      expect(flow(tester).step, JournalStep.note);

      await say(tester, 'hoje foi longo, salvar');

      expect(harness.remote.created, isEmpty);
      expect(flow(tester).step, JournalStep.note);
      final field = tester.widget<TextField>(find.byKey(const Key('jv2_note_field')));
      expect(field.controller!.text, 'hoje foi longo, salvar');
      expect(feedback(tester)?.kind, VoiceFeedbackKind.noted);
    });

    testWidgets('words the next step does not know: "not understood", picks stay', (tester) async {
      await pump(tester);
      await toOptions(tester);

      await say(tester, '$optionLabel, abacaxi voador');

      final state = flow(tester);
      expect(state.step, JournalStep.persistence);
      expect(state.items.single.optionKey, optionKey);
      expect(state.items.single.persistence, isNull);
      expect(feedback(tester)?.kind, VoiceFeedbackKind.notUnderstood);
      expect(feedback(tester)?.text, 'abacaxi voador');
    });

    testWidgets('"<option>, ajuda" opens help and nothing else happens', (tester) async {
      await pump(tester);
      await toOptions(tester);

      await say(tester, '$optionLabel, começou hoje, ajuda');

      expect(find.text('HELP SCREEN'), findsOneWidget);
      final state = flow(tester);
      expect(state.step, JournalStep.options);
      expect(state.selectedOptions, isEmpty);
      expect(state.items, isEmpty);
    });

    testWidgets('help opened while a phrase is carried: the queue is dropped', (tester) async {
      await pump(tester);
      await toOptions(tester);

      await controller(tester).handlePhrase('$optionLabel, começou hoje, intensidade três');
      await controller(tester).handlePhrase('ajuda');
      await tester.pumpAndSettle();

      expect(find.text('HELP SCREEN'), findsOneWidget);
      expect(flow(tester).items, isEmpty);
    });

    testWidgets('the mic (stop) drops the queue', (tester) async {
      await pump(tester);
      await toOptions(tester);

      await controller(tester).handlePhrase('$optionLabel, começou hoje, intensidade três');
      await controller(tester).stop();
      await tester.pumpAndSettle();

      final state = flow(tester);
      expect(state.step, JournalStep.options);
      expect(state.selectedOptions, {optionKey});
      expect(state.items, isEmpty);
    });

    testWidgets('the app lock drops the queue', (tester) async {
      await pump(tester);
      await toOptions(tester);

      await controller(tester).handlePhrase('$optionLabel, começou hoje, intensidade três');
      (containerOf(tester).read(biometricLockControllerProvider.notifier) as _TestLock).engage();
      await tester.pumpAndSettle();

      expect(flow(tester).step, JournalStep.options);
      expect(flow(tester).items, isEmpty);
    });

    testWidgets('"voltar" as a new phrase drops the queue', (tester) async {
      await pump(tester);
      await toOptions(tester);

      await controller(tester).handlePhrase('$optionLabel, começou hoje, intensidade três');
      await controller(tester).handlePhrase('voltar');
      await tester.pumpAndSettle();

      final state = flow(tester);
      expect(state.step, JournalStep.branch);
      expect(state.items, isEmpty);
    });

    testWidgets('a new phrase replaces the queue', (tester) async {
      await pump(tester);
      await toOptions(tester);
      final second = '$time.$branch.${options[1]}';

      await controller(tester).handlePhrase('$optionLabel, começou hoje, intensidade três');
      await controller(tester).handlePhrase(JournalLabels.option(pt, second));
      await tester.pumpAndSettle();

      final state = flow(tester);
      expect(state.step, JournalStep.options);
      expect(state.selectedOptions, {optionKey, second});
      expect(state.items, isEmpty);
    });

    testWidgets('"pular" alone on the triggers step still skips', (tester) async {
      await pump(tester);
      await toTriggers(tester);

      await say(tester, 'pular');

      expect(flow(tester).step, JournalStep.closing);
    });

    testWidgets('hands-free: the carried steps play out before listening again', (tester) async {
      voice = _QueuedVoiceInput([
        'não tão bem',
        JournalLabels.root(pt, time),
        JournalLabels.branch(pt, '$time.$branch'),
        '$optionLabel, começou hoje, intensidade três',
      ]);
      await pump(tester);
      await tester.tap(find.byKey(const Key('voice_mic_button')));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      final state = flow(tester);
      expect(state.step, JournalStep.intensity);
      expect(state.items.single.persistence, JournalKeys.persistenceHoje);
      expect(state.items.single.intensity, 3);
      final spoken = harness.voiceOutput.spoken;
      // The persistence step was answered by the phrase, never read; the
      // intensity step it stopped on was read once.
      expect(spoken.where((t) => t.contains(pt.jv2PersistenceQuestion)), isEmpty);
      expect(spoken.where((t) => t.contains(pt.jv2IntensityQuestion)), hasLength(1));
      expect(harness.remote.created, isEmpty);
    });
  });
  group('Carried words pick only what they name exactly (CR-02)', () {
    /// Says [phrase] on the options step; the flow must stop on intensity
    /// with no level set and the words in "not understood".
    Future<void> expectNoIntensity(WidgetTester tester, String phrase, String rest) async {
      await pump(tester);
      await toOptions(tester);

      await say(tester, phrase);

      final state = flow(tester);
      expect(state.step, JournalStep.intensity);
      expect(state.items.single.persistence, JournalKeys.persistenceHoje);
      expect(state.items.single.intensity, isNull);
      expect(feedback(tester)?.kind, VoiceFeedbackKind.notUnderstood);
      expect(feedback(tester)?.text, rest);
      expect(harness.remote.created, isEmpty);
    }

    testWidgets('"<option>, começou hoje muito cedo": "muito" is not "Muito forte"',
        (tester) async {
      await expectNoIntensity(tester, '$optionLabel, começou hoje muito cedo', 'muito cedo');
    });

    testWidgets('"<option>, começou hoje, forte": a level name is not a number', (tester) async {
      await expectNoIntensity(tester, '$optionLabel, começou hoje, forte', 'forte');
    });

    testWidgets('"<option>, começou hoje, dor forte": no level from a description',
        (tester) async {
      await expectNoIntensity(tester, '$optionLabel, começou hoje, dor forte', 'dor forte');
    });

    testWidgets('"<option>, começou hoje, dois dias": a number inside other words is no level',
        (tester) async {
      await expectNoIntensity(tester, '$optionLabel, começou hoje, dois dias', 'dois dias');
    });

    testWidgets('"<option>, começou hoje, um pouco": "um" as an article is no level',
        (tester) async {
      await expectNoIntensity(tester, '$optionLabel, começou hoje, um pouco', 'um pouco');
    });

    testWidgets('"<option>, hoje, intensidade três": "hoje" alone is not "Começou hoje"',
        (tester) async {
      await pump(tester);
      await toOptions(tester);

      await say(tester, '$optionLabel, hoje, intensidade três');

      final state = flow(tester);
      expect(state.step, JournalStep.persistence);
      expect(state.items.single.persistence, isNull);
      expect(state.items.single.intensity, isNull);
      expect(feedback(tester)?.kind, VoiceFeedbackKind.notUnderstood);
    });

    testWidgets('"<option>, começou hoje, 4" sets the number said', (tester) async {
      await pump(tester);
      await toOptions(tester);

      await say(tester, '$optionLabel, começou hoje, 4');

      final state = flow(tester);
      expect(state.step, JournalStep.intensity);
      expect(state.items.single.intensity, 4);
    });

    testWidgets('"hoje" said alone on the persistence step still answers it', (tester) async {
      await pump(tester);
      await toOptions(tester);
      await say(tester, optionLabel);
      await say(tester, 'continuar');
      expect(flow(tester).step, JournalStep.persistence);

      await say(tester, 'hoje');

      expect(flow(tester).items.single.persistence, JournalKeys.persistenceHoje);
    });
  });

  group('Buttons that save (CR-01, WR-05)', () {
    const bp = UserCondition(
      id: 'c1',
      label: 'Hipertensão',
      tracking: [JournalKeys.trackingBloodPressure],
    );
    const physical = JournalFlowArgs(initialArea: JournalArea.physical);

    /// Physical "Bem" with a tracked condition, readings typed in.
    Future<void> toConditionsWithReadings(WidgetTester tester) async {
      await pump(tester, conditions: const [bp], args: physical);
      await say(tester, 'bem');
      expect(flow(tester).step, JournalStep.conditions);
      await tester.enterText(find.byKey(const Key('chronicTrack_c1_0_systolic')), '120');
      await tester.enterText(find.byKey(const Key('chronicTrack_c1_0_diastolic')), '80');
      await tester.pumpAndSettle();
      expect(flow(tester).hasReadings, isTrue);
    }

    testWidgets('conditions step: "<condition>, abacaxi" never presses "Só registrar medições"',
        (tester) async {
      await toConditionsWithReadings(tester);

      await say(tester, '${bp.label}, abacaxi');

      expect(harness.remote.created, isEmpty);
      expect(find.text('SUMMARY'), findsNothing);
      expect(flow(tester).step, JournalStep.conditions);
    });

    testWidgets('conditions step: "<condition>, registrar medições" saves nothing', (tester) async {
      await toConditionsWithReadings(tester);

      await say(tester, '${bp.label}, registrar medições');

      expect(harness.remote.created, isEmpty);
      expect(flow(tester).step, JournalStep.conditions);
    });

    testWidgets('physical "Bem, mas com dor nas costas" saves nothing', (tester) async {
      await pump(tester, args: physical);

      await say(tester, 'bem, mas com dor nas costas');

      expect(harness.remote.created, isEmpty);
      expect(find.text('SUMMARY'), findsNothing);
      expect(flow(tester).step, JournalStep.mood);
    });

    testWidgets('physical "Bem" said alone still saves at once', (tester) async {
      await pump(tester, args: physical);

      await say(tester, 'bem');

      expect(harness.remote.created, hasLength(1));
      expect(find.text('SUMMARY'), findsOneWidget);
    });

    testWidgets('"Só registrar medições" said alone still saves', (tester) async {
      await toConditionsWithReadings(tester);

      await say(tester, pt.chronicTrackJustLog);

      expect(harness.remote.created, hasLength(1));
      expect(find.text('SUMMARY'), findsOneWidget);
    });
  });
}
