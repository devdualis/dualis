// QA: Phase 17 on the iOS Simulator (voice dialogue, multi-answer phrases,
// "Descrever com minhas palavras", AI consent, privacy policy section 8).
// The real app and UI; the speech input is scripted (ScriptedVoice), the
// read-aloud output is the in-memory FakeVoiceOutput (so the speaking phase
// can be held for a screenshot), and every API call goes to in-memory fakes.
// No network, no Vertex call, no production database.
//
// One extra test builds the real flutter_tts service (not the provider) and
// speaks one sentence, to prove the iOS plugin and audio session run.
//
// Screenshots go through host_helper.py (run it first, from mobile/):
//   python3 integration_test/qa_premium/host_helper.py <udid> \
//     com.dualischeckup.app.dualisMobile ../docs/qa-reports/phase-17
//
//   flutter test integration_test/qa_premium/phase17_qa_test.dart -d <udid> \
//     --dart-define=PREMIUM_FEATURES=true      # Premium
//   flutter test integration_test/qa_premium/phase17_qa_test.dart -d <udid>
//                                              # Free
import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/voice/voice_output_service.dart';
import 'package:dualis_mobile/features/consent/presentation/ai_consent_controller.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_controller.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:dualis_mobile/features/journal/presentation/journal_labels.dart';
import 'package:dualis_mobile/features/voice/presentation/voice_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:dualis_mobile/shared/widgets/urgent_help_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_harness.dart';

final pt = AppLocalizationsPt();
final mic = byKey('voice_mic_button');
final banner = byKey('voice_status_banner');
final help = find.byType(UrgentHelpButton);

final time = JournalKeys.emotionalTree.keys.first;
final branch = JournalKeys.emotionalTree[time]!.keys.first;
final options = JournalKeys.emotionalTree[time]![branch]!;
final optionKey = '$time.$branch.${options.first}';
final secondKey = '$time.$branch.${options[1]}';
String get timeLabel => JournalLabels.root(pt, time);
String get branchLabel => JournalLabels.branch(pt, '$time.$branch');
String get optionLabel => JournalLabels.option(pt, optionKey);

const describeText = 'Ando cansado e preocupado com o trabalho, durmo mal';

VoiceState voiceState(QaApp app) => app.container.read(voiceControllerProvider);
JournalFlowState flow(QaApp app) =>
    app.container.read(journalFlowControllerProvider);

Future<void> tapMic(WidgetTester tester) async {
  await waitFor(tester, mic.hitTestable());
  await tester.tap(mic.hitTestable().first);
  await tester.pump(const Duration(milliseconds: 200));
}

/// Opens the check-in from Home with a voice command, as a person would.
Future<void> openCheckInByVoice(WidgetTester tester, QaApp app) async {
  app.voice.say(['como me sinto']);
  await tapMic(tester);
  await waitFor(tester, byKey('jv2_mood_nao_tao_bem'));
  final end = DateTime.now().add(const Duration(seconds: 8));
  while (voiceState(app).listening && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settle(tester, ms: 800);
  expect(app.location, '/journal');
}

/// Opens the check-in by touch and goes to the time step ("Não tão bem").
Future<void> toTimeStep(WidgetTester tester, QaApp app) async {
  app.container.read(appRouterProvider).push(RoutePaths.journal);
  await tap(tester, byKey('jv2_mood_nao_tao_bem'));
  await waitFor(tester, byKey('jv2_time_$time'));
  await settle(tester, ms: 600);
}

/// Opens the describe sheet from the time step and types [text].
Future<void> openDescribe(WidgetTester tester, {String text = describeText}) async {
  await tap(tester, byKey('jv2_describe'));
  await waitFor(tester, byKey('jv2_describe_field'));
  await tester.enterText(byKey('jv2_describe_field'), text);
  // Hide the on-screen keyboard if the simulator shows it.
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester, ms: 900);
}

Future<void> logHelpAndBanner(WidgetTester tester, String tag) async {
  final helpTop = help.hitTestable();
  final helpRect = helpTop.evaluate().isEmpty ? null : tester.getRect(helpTop.first);
  final bannerRect = banner.evaluate().isEmpty ? null : tester.getRect(banner.first);
  await hostLog('$tag help=$helpRect banner=$bannerRect '
      'screen=${tester.view.physicalSize / tester.view.devicePixelRatio}');
  expect(helpRect, isNotNull, reason: '$tag: help button can be tapped');
  if (bannerRect != null) {
    expect(bannerRect.overlaps(helpRect!), isFalse,
        reason: '$tag: the banner does not cover the help button');
    final micRect = mic.evaluate().isEmpty ? null : tester.getRect(mic.first);
    await hostLog('$tag mic=$micRect');
    if (micRect != null) {
      expect(bannerRect.overlaps(micRect), isFalse,
          reason: '$tag: the banner does not cover the mic it asks to tap');
    }
  }
}

/// [FlutterTtsEngine] that records what the real plugin reports.
class ObservedTtsEngine extends FlutterTtsEngine {
  final List<String> events = [];
  bool? ptBrAvailable;

  @override
  Future<bool> isLanguageAvailable(String languageTag) async {
    final ok = await super.isLanguageAvailable(languageTag);
    if (languageTag == 'pt-BR') ptBrAvailable = ok;
    events.add('available:$languageTag=$ok');
    return ok;
  }

  @override
  Future<void> setLanguage(String languageTag) {
    events.add('language:$languageTag');
    return super.setLanguage(languageTag);
  }

  @override
  Future<bool> speak(String text) async {
    final ok = await super.speak(text);
    events.add('speak:accepted=$ok');
    return ok;
  }

  @override
  void setStartHandler(VoidCallback handler) =>
      super.setStartHandler(() {
        events.add('start');
        handler();
      });

  @override
  void setCompletionHandler(VoidCallback handler) =>
      super.setCompletionHandler(() {
        events.add('completion');
        handler();
      });

  @override
  void setCancelHandler(VoidCallback handler) => super.setCancelHandler(() {
        events.add('cancel');
        handler();
      });

  @override
  void setErrorHandler(void Function(dynamic message) handler) =>
      super.setErrorHandler((m) {
        events.add('error:$m');
        handler(m);
      });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetKeychain);

  if (!isPremium) {
    testWidgets('F17-8 Free: the time step has no "Descrever com minhas '
        'palavras"', (tester) async {
      final app = await bootApp(tester);
      await toTimeStep(tester, app);
      await shot(tester, '08_sin_describir');
      expect(byKey('jv2_describe'), findsNothing);
      expect(find.text(pt.jv2DescribeTile), findsNothing);
      expect(help.hitTestable(), findsWidgets);
    });

    testWidgets('F17-9 Free: Settings has the AI consent tile and no '
        'read-aloud switch', (tester) async {
      final app = await bootApp(tester);
      app.container.read(appRouterProvider).push(RoutePaths.settings);
      await waitFor(tester, byKey('settings_ai_consent_tile'));
      await tester.ensureVisible(byKey('settings_ai_consent_tile'));
      await settle(tester, ms: 900);
      await shot(tester, '09_ajustes');
      expect(byKey('settings_ai_consent_tile'), findsOneWidget);
      expect(byKey('settings_voice_read_aloud_switch'), findsNothing);
      expect(mic, findsNothing);
    });
    return;
  }

  testWidgets('P17-1 voice dialogue: the app reads the question, the banner '
      'says so, the mic stops it', (tester) async {
    final app = await bootApp(tester);
    await openCheckInByVoice(tester, app);
    app.journal.voiceOutput.hold = const Duration(seconds: 4);
    final spokenBefore = app.journal.voiceOutput.spoken.length;
    await tapMic(tester); // hands-free: read the step, then listen
    await waitFor(tester, find.text(pt.voiceSpeaking));
    await settle(tester, ms: 400);
    await shot(tester, '01_dialogo_voz_leyendo');
    expect(voiceState(app).speaking, isTrue);
    final read = app.journal.voiceOutput.spoken.skip(spokenBefore).join(' | ');
    await hostLog('P17-1 read aloud: $read');
    expect(read, isNotEmpty);
    await logHelpAndBanner(tester, 'P17-1');

    // The mic stops the reading at once.
    await tapMic(tester);
    await settle(tester, ms: 800);
    expect(voiceState(app).speaking, isFalse);
    expect(voiceState(app).handsFree, isFalse);
    expect(find.text(pt.voiceSpeaking), findsNothing);
    app.journal.voiceOutput.hold = Duration.zero;
  });

  testWidgets('P17-2 one phrase answers several steps: option, persistence '
      'and intensity', (tester) async {
    final app = await bootApp(tester);
    await openCheckInByVoice(tester, app);
    final phrase = '$optionLabel, começou hoje, intensidade três';
    app.voice.say(['não tão bem', timeLabel, branchLabel, phrase, 'parar']);
    await tapMic(tester);
    final end = DateTime.now().add(const Duration(seconds: 40));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      final s = flow(app);
      if (s.step == JournalStep.intensity &&
          s.items.isNotEmpty &&
          s.items.first.intensity == 3) {
        break;
      }
    }
    await settle(tester, ms: 1200);
    final s = flow(app);
    await hostLog('P17-2 phrase="$phrase" step=${s.step} items=${[
      for (final i in s.items) '${i.optionKey}:${i.persistence}/${i.intensity}'
    ]} read=${app.journal.voiceOutput.spoken.length}');
    final level3 = byKey('jv2_intensity_0_3');
    if (level3.evaluate().isNotEmpty) await tester.ensureVisible(level3);
    await settle(tester, ms: 400);
    await shot(tester, '02_frase_varias_respuestas');
    expect(s.step, JournalStep.intensity);
    final item = s.items.single;
    expect(item.optionKey, optionKey);
    expect(item.persistence, JournalKeys.persistenceHoje);
    expect(item.intensity, 3);
    expect(app.journal.remote.created, isEmpty,
        reason: 'a phrase never saves the entry');

    // "parar" ends hands-free.
    final stop = DateTime.now().add(const Duration(seconds: 20));
    while (voiceState(app).handsFree && DateTime.now().isBefore(stop)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester, ms: 600);
    expect(voiceState(app).handsFree, isFalse);
  });

  testWidgets('P17-3/4 describe in my own words → review (all off) → use the '
      'selected one', (tester) async {
    final app = await bootApp(tester);
    app.journal.consent.granted = true;
    app.journal.remote.suggestedEntryKeys = [optionKey, secondKey];
    await toTimeStep(tester, app);
    await openDescribe(tester);
    await shot(tester, '03_describir_con_mis_palabras');
    await logHelpAndBanner(tester, 'P17-3 describe sheet');

    await tap(tester, byKey('jv2_describe_suggest'));
    await waitFor(tester, byKey('jv2_describe_review'));
    await settle(tester, ms: 600);
    expect(app.journal.remote.suggestEntryRequests.single,
        {'text': describeText, 'area': 'emotional'});
    final first = byKey('jv2_describe_option_$optionKey');
    final second = byKey('jv2_describe_option_$secondKey');
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(tester.widget<SwitchListTile>(first).value, isFalse,
        reason: 'every suggestion starts off');
    expect(tester.widget<SwitchListTile>(second).value, isFalse);
    await tap(tester, first);
    expect(tester.widget<SwitchListTile>(first).value, isTrue);
    await shot(tester, '04_revision_sugerencias');
    await logHelpAndBanner(tester, 'P17-4 review');

    await tap(tester, byKey('jv2_describe_use'));
    await waitFor(tester, byKey('jv2_describe_sheet'), present: false);
    await settle(tester, ms: 800);
    final s = flow(app);
    await hostLog('P17-4 after Usar: step=${s.step} '
        'items=${[for (final i in s.items) i.optionKey]}');
    expect(s.step, anyOf(JournalStep.persistence, JournalStep.intensity),
        reason: 'the flow continues at the persistence step');
    expect([for (final i in s.items) i.optionKey], [optionKey]);
    expect(app.journal.remote.created, isEmpty);
  });

  testWidgets('P17-5/6 consent dialog before the first description, then the '
      'Settings tile shows it on', (tester) async {
    final app = await bootApp(tester);
    app.journal.consent.granted = false;
    app.journal.remote.suggestedEntryKeys = [optionKey];
    await app.container.read(aiConsentControllerProvider.notifier).refresh();
    await toTimeStep(tester, app);
    await openDescribe(tester);
    await tap(tester, byKey('jv2_describe_suggest'));
    await waitFor(tester, byKey('ai_consent_dialog'));
    await settle(tester, ms: 800);
    await shot(tester, '05_dialogo_consentimiento');
    expect(app.journal.remote.suggestEntryRequests, isEmpty,
        reason: 'nothing is sent before "Permitir"');
    await logHelpAndBanner(tester, 'P17-5 consent dialog');

    await tap(tester, byKey('ai_consent_accept'));
    await waitFor(tester, byKey('jv2_describe_review'));
    expect(app.journal.consent.granted, isTrue);
    expect(app.journal.remote.suggestEntryRequests, hasLength(1));
    await hostLog('P17-5 consent calls=${app.journal.consent.calls}');

    // Leave the sheet without using anything, then open Settings.
    await tap(tester, byKey('jv2_describe_manual'));
    await waitFor(tester, byKey('jv2_describe_sheet'), present: false);
    app.container.read(appRouterProvider).push(RoutePaths.settings);
    await waitFor(tester, byKey('settings_ai_consent_tile'));
    await tester.ensureVisible(byKey('settings_ai_consent_tile'));
    await settle(tester, ms: 900);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 160));
    await settle(tester, ms: 900);
    await shot(tester, '06_ajustes_consentimiento');
    expect(byKey('settings_voice_read_aloud_switch'), findsOneWidget);
    final sw = tester.widget<Switch>(find.descendant(
        of: byKey('settings_ai_consent_switch'), matching: find.byType(Switch)));
    expect(sw.value, isTrue);
    expect(find.textContaining('05/11/2026'), findsOneWidget,
        reason: 'the tile shows the consent date');
  });

  testWidgets('P17-7 privacy policy: section 8 on AI suggestions',
      (tester) async {
    final app = await bootApp(tester);
    app.container.read(appRouterProvider).push(RoutePaths.privacyPolicy);
    await settle(tester, ms: 1200);
    final title = find.text(pt.privacyPolicySection8Title);
    await tester.scrollUntilVisible(title, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(title);
    await settle(tester, ms: 900);
    await shot(tester, '07_politica_privacidad_ia');
    expect(title, findsOneWidget);
  });

  testWidgets('P17-TTS the real flutter_tts plugin speaks on iOS and reports '
      'the end', (tester) async {
    final engine = ObservedTtsEngine();
    final service = FlutterTtsVoiceOutputService(engine);
    final watch = Stopwatch()..start();
    await service.prepare('pt');
    await service.speak('Como você está hoje?').timeout(const Duration(seconds: 15));
    watch.stop();
    await hostLog('P17-TTS ${watch.elapsedMilliseconds} ms events=${engine.events}');
    expect(engine.events, contains('speak:accepted=true'));
    expect(engine.events, contains('start'),
        reason: 'the plugin started speaking');
    expect(engine.events, contains('completion'),
        reason: 'the plugin reported the end (not the safety timer)');
    await service.stop();
  });
}
