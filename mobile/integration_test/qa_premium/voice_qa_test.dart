// QA: Premium voice commands, hands-free check-in and dictation on the iOS
// Simulator. The real app and UI; only the speech engine is scripted
// (ScriptedVoice "hears" fixed phrases), so runs are repeatable.
//
//   flutter test integration_test/qa_premium/voice_qa_test.dart -d <udid> \
//     --dart-define=PREMIUM_FEATURES=true      # Premium
//   flutter test integration_test/qa_premium/voice_qa_test.dart -d <udid>
//                                              # Free
import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/shared/widgets/urgent_help_button.dart';
import 'package:dualis_mobile/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_controller.dart';
import 'package:dualis_mobile/features/journal/presentation/journal_labels.dart';
import 'package:dualis_mobile/features/voice/presentation/voice_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_harness.dart';

final pt = AppLocalizationsPt();
final mic = byKey('voice_mic_button');
final banner = byKey('voice_status_banner');

final time = JournalKeys.emotionalTree.keys.first;
final branch = JournalKeys.emotionalTree[time]!.keys.first;
final option = JournalKeys.emotionalTree[time]![branch]!.first;
final optionKey = '$time.$branch.$option';
String get branchLabel => JournalLabels.branch(pt, '$time.$branch');
String get timeLabel => JournalLabels.root(pt, time);
String get optionLabel => JournalLabels.option(pt, optionKey);

VoiceState voiceState(QaApp app) => app.container.read(voiceControllerProvider);
VoiceController voiceCtl(QaApp app) =>
    app.container.read(voiceControllerProvider.notifier);

/// Taps the mic that is on screen now.
Future<void> tapMic(WidgetTester tester) async {
  await waitFor(tester, mic.hitTestable());
  await tester.tap(mic.hitTestable().first);
  await tester.pump(const Duration(milliseconds: 200));
}

/// One voice command: tap the mic, the engine hears [phrase].
Future<void> command(WidgetTester tester, QaApp app, String phrase,
    {String? shotName}) async {
  app.voice.say([phrase]);
  await tapMic(tester);
  // Partial text shows after ~0.9 s, the final phrase ~0.5 s later.
  await settle(tester, ms: 1000);
  if (shotName != null) await shot(tester, '${shotName}_listening');
  final end = DateTime.now().add(const Duration(seconds: 8));
  while (voiceState(app).listening && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settle(tester, ms: 900);
  if (shotName != null) await shot(tester, shotName);
}

/// Acts as if [phrase] was heard (same entry point the engine result uses).
Future<void> heard(WidgetTester tester, QaApp app, String phrase) async {
  await voiceCtl(app).handlePhrase(phrase);
  await settle(tester, ms: 900);
}

Future<void> openCheckIn(WidgetTester tester, QaApp app) async {
  await command(tester, app, 'como me sinto');
  await waitFor(tester, byKey('jv2_mood_nao_tao_bem'));
  await settle(tester, ms: 600);
  expect(app.location, '/journal');
}

Future<void> waitIdle(WidgetTester tester, QaApp app,
    {Duration timeout = const Duration(seconds: 40)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    final s = voiceState(app);
    if (!s.listening && !s.handsFree) break;
  }
  await settle(tester, ms: 500);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetKeychain);

  if (!isPremium) {
    testWidgets('F-V1 Free: no mic on Home, under the help button, or in the '
        'check-in fields; voice never starts', (tester) async {
      final app = await bootApp(tester);
      await shot(tester, 'V_home_no_mic');
      expect(mic, findsNothing);

      await tap(tester, byKey('home_settings_button'));
      await settle(tester, ms: 800);
      await shot(tester, 'V_settings_no_mic');
      expect(mic, findsNothing);
      expect(find.byType(UrgentHelpButton), findsWidgets);
      app.container.read(appRouterProvider).pop();
      await settle(tester, ms: 800);

      // Check-in: no dictation icons in "Escrever o meu" or the note.
      app.container.read(appRouterProvider).push('/journal');
      await waitFor(tester, byKey('jv2_mood_nao_tao_bem'));
      expect(mic, findsNothing);
      await tap(tester, byKey('jv2_mood_nao_tao_bem'));
      await tap(tester, byKey('jv2_time_$time'));
      await tap(tester, byKey('jv2_branch_$time.$branch'));
      await tap(tester, byKey('jv2_write_mine'));
      await waitFor(tester, byKey('jv2_custom_field'));
      await shot(tester, 'V_write_mine_no_dictation');
      expect(find.byKey(const Key('voice_dictate_custom')), findsNothing);
      final field = tester.widget<TextField>(byKey('jv2_custom_field'));
      expect(field.decoration?.suffixIcon, isNull,
          reason: 'no empty icon space on Free');

      // On to the trigger note and the note, by touch.
      await tap(tester, byKey('jv2_option_$optionKey'));
      await tap(tester, find.text(pt.jv2Continue));
      await tap(tester, find.text(pt.jv2PersistenceHoje).first);
      await tap(tester, find.text('3').first);
      await tap(tester, find.text(pt.jv2Continue));
      await tap(tester, byKey('jv2_trigger_${JournalKeys.triggerOutro}'));
      await waitFor(tester, byKey('jv2_trigger_note'));
      await tester.ensureVisible(byKey('jv2_trigger_note'));
      await settle(tester);
      await shot(tester, 'V_trigger_note_no_dictation');
      expect(find.byKey(const Key('voice_dictate_trigger_note')), findsNothing);
      for (var i = 0; i < 4 && byKey('jv2_note_field').evaluate().isEmpty; i++) {
        final next = byKey('jv2_skip').evaluate().isNotEmpty
            ? byKey('jv2_skip')
            : find.text(pt.jv2Continue);
        await tap(tester, next);
      }
      await waitFor(tester, byKey('jv2_note_field'));
      await shot(tester, 'V_note_no_dictation');
      expect(find.byKey(const Key('voice_dictate_note')), findsNothing);
      expect(mic, findsNothing);

      // Nothing listens even if voice is asked to start.
      await voiceCtl(app).startCommands();
      await settle(tester);
      expect(app.voice.listens, isEmpty);
      expect(banner, findsNothing);
    });
    return;
  }

  testWidgets('P-V1 mic only on Home (app bar) and on the check-in (left of '
      'the help button); nothing covered', (tester) async {
    final app = await bootApp(tester);
    await shot(tester, 'V01_home_mic_in_app_bar');
    expect(mic.hitTestable(), findsOneWidget);

    // Settings: no mic; the biometric switch is clear of any overlay button.
    await tap(tester, byKey('home_settings_button'));
    await settle(tester, ms: 800);
    final bioSwitch = byKey('settings_biometric_lock_switch');
    await tester.ensureVisible(bioSwitch);
    await settle(tester);
    await shot(tester, 'V01_settings_no_mic_switch_visible');
    expect(app.location, '/settings');
    expect(mic, findsNothing, reason: 'no overlay mic outside the check-in');
    final help = find.byType(UrgentHelpButton).hitTestable();
    final switchRect = tester.getRect(
        find.descendant(of: bioSwitch, matching: find.byType(Switch)));
    expect(switchRect.overlaps(tester.getRect(help.first)), isFalse);
    // The switch itself receives a tap at its right edge.
    final hit = tester.hitTestOnBinding(switchRect.centerRight - const Offset(4, 0));
    expect(
        hit.path.any((e) =>
            e.target is RenderObject &&
            find.descendant(of: bioSwitch, matching: find.byType(Switch))
                .evaluate()
                .any((el) => el.renderObject == e.target ||
                    _isAncestor(el.renderObject!, e.target as RenderObject))),
        isTrue,
        reason: 'right edge of the switch is not covered');
    app.container.read(appRouterProvider).pop();
    await settle(tester, ms: 800);

    // Other screens: no mic.
    for (final path in ['/history', '/hydration', '/habits']) {
      app.container.read(appRouterProvider).push(path);
      await settle(tester, ms: 1200);
      expect(mic, findsNothing, reason: 'no mic on $path');
      if (path == '/hydration') await shot(tester, 'V01_hydration_no_mic');
      app.container.read(appRouterProvider).pop();
      await settle(tester, ms: 800);
    }

    // Check-in: mic left of the help button, step counter visible.
    await openCheckIn(tester, app);
    await heard(tester, app, 'não tão bem');
    await settle(tester, ms: 600);
    await shot(tester, 'V01_check_in_mic_and_counter');
    final micRect = tester.getRect(mic.hitTestable());
    final helpRect = tester.getRect(find.byType(UrgentHelpButton).hitTestable().first);
    final counter = find.textContaining(RegExp(r'^\d+ de \d+$'));
    expect(counter, findsOneWidget, reason: 'step counter shown');
    final counterRect = tester.getRect(counter);
    await hostLog('V01 mic=$micRect help=$helpRect counter=$counterRect');
    expect(micRect.right <= helpRect.left, isTrue, reason: 'mic left of help');
    expect(micRect.overlaps(counterRect), isFalse);
    expect(helpRect.overlaps(counterRect), isFalse);
    final top = tester.hitTestOnBinding(counterRect.center).path.first.target;
    expect(top is RenderParagraph || top is InlineSpan, isTrue,
        reason: 'counter text is the topmost thing (not covered)');
  });

  testWidgets('P-V2 voice commands from Home: histórico, água, registrar '
      'água, hábitos, configurações, ajuda', (tester) async {
    final app = await bootApp(tester);
    final router = app.container.read(appRouterProvider);
    await videoStart('V02_voice_commands');
    Future<void> backHome() async {
      router.pop();
      await settle(tester, ms: 900);
      expect(app.location, '/home');
    }

    await command(tester, app, 'histórico', shotName: 'V02_historico');
    expect(app.location, '/history');
    expect(mic, findsNothing);
    await backHome();

    await command(tester, app, 'água', shotName: 'V02_agua');
    expect(app.location, '/hydration');
    await backHome();

    final before =
        app.container.read(hydrationControllerProvider).todayTotalMl;
    await command(tester, app, 'registrar água', shotName: 'V02_registrar_agua');
    final after = app.container.read(hydrationControllerProvider).todayTotalMl;
    await hostLog('V02 water total $before -> $after');
    expect(after - before, VoiceController.glassMl);
    expect(voiceState(app).feedback?.kind, VoiceFeedbackKind.waterLogged);
    expect(app.location, '/home');

    await command(tester, app, 'hábitos', shotName: 'V02_habitos');
    expect(app.location, '/habits');
    await backHome();

    await command(tester, app, 'configurações', shotName: 'V02_configuracoes');
    expect(app.location, '/settings');
    await backHome();

    await command(tester, app, 'eu preciso de ajuda', shotName: 'V02_ajuda');
    expect(app.location, '/emergency');
    expect(find.byType(EmergencyScreen), findsOneWidget);
    expect(voiceState(app).listening, isFalse,
        reason: 'mic closes on the help screen');
    await videoStop();

    // On the help screen voice ignores commands.
    final listens = app.voice.listens.length;
    await heard(tester, app, 'histórico');
    expect(app.location, '/emergency', reason: 'no command on help screen');
    expect(app.voice.listens.length, listens);
    expect(mic.hitTestable(), findsNothing, reason: 'no mic on help screen');
  });

  testWidgets('P-V3 unknown phrase changes nothing and says so', (tester) async {
    final app = await bootApp(tester);
    await command(tester, app, 'abacaxi voador', shotName: 'V03_not_understood');
    expect(app.location, '/home');
    expect(voiceState(app).feedback?.kind, VoiceFeedbackKind.notUnderstood);
  });

  testWidgets('P-V4 hands-free daily check-in: one tap, answers by voice, '
      'saves, stops after leaving the flow', (tester) async {
    final app = await bootApp(tester);
    await openCheckIn(tester, app);
    await videoStart('V04_hands_free_check_in');
    app.voice.say([
      'não tão bem',
      timeLabel,
      branchLabel,
      optionLabel,
      'continuar',
      'começou hoje',
      'três',
      'continuar',
      'pular',
      'pular',
      'hoje foi um dia longo',
      'salvar',
    ]);
    final base = app.voice.listens.length; // "como me sinto" was one
    await tapMic(tester); // the only tap
    final shots = <int>{1, 3, 5, 6, 10};
    var n = 0;
    final end = DateTime.now().add(const Duration(seconds: 70));
    var lastLen = app.voice.queue.length;
    while (DateTime.now().isBefore(end) && app.location == '/journal') {
      await tester.pump(const Duration(milliseconds: 100));
      if (app.voice.queue.length != lastLen) {
        lastLen = app.voice.queue.length;
        n++;
        if (shots.contains(n)) {
          await settle(tester, ms: 500);
          await shot(tester, 'V04_step_${n.toString().padLeft(2, '0')}');
        }
      }
    }
    await settle(tester, ms: 2500);
    await shot(tester, 'V04_saved_summary');
    await videoStop();
    await hostLog('V04 location=${app.location} listens=${app.voice.listens.length} '
        'left=${app.voice.queue} created=${app.journal.remote.created.length}');
    expect(app.location, '/check-in-summary');
    expect(app.voice.queue, isEmpty);
    final saved = app.journal.remote.created.single;
    expect(saved.items.single.optionKey, optionKey);
    expect(saved.items.single.intensity, 3);
    expect(saved.items.single.persistence, JournalKeys.persistenceHoje);
    expect(saved.note, 'hoje foi um dia longo');
    expect(app.voice.listens.length - base, 11, reason: 'one listen per answer');
    await settle(tester, ms: 1500);
    expect(voiceState(app).listening, isFalse);
    expect(voiceState(app).handsFree, isFalse);
  });

  testWidgets('P-V5 hands-free stops on "parar"', (tester) async {
    final app = await bootApp(tester);
    await openCheckIn(tester, app);
    app.voice.say(['não tão bem', 'parar']);
    final base = app.voice.listens.length;
    await tapMic(tester);
    await waitIdle(tester, app);
    await shot(tester, 'V05_stopped_on_parar');
    expect(app.voice.listens.length - base, 2);
    expect(voiceState(app).handsFree, isFalse);
    expect(find.byKey(Key('jv2_time_$time')), findsOneWidget,
        reason: 'first answer applied');
  });

  testWidgets('P-V6 hands-free stops by itself after silences / '
      'unknown phrases in a row', (tester) async {
    final app = await bootApp(tester);
    await openCheckIn(tester, app);
    app.voice.say(['não tão bem', '', 'abacaxi voador', '']);
    final base = app.voice.listens.length;
    await tapMic(tester);
    await waitIdle(tester, app, timeout: const Duration(seconds: 30));
    await shot(tester, 'V06_stopped_after_misses');
    await hostLog('V06 listens=${app.voice.listens.length - base} '
        'maxMisses=${VoiceController.maxMisses}');
    expect(app.voice.listens.length - base, 1 + VoiceController.maxMisses);
    expect(voiceState(app).listening, isFalse);
    expect(voiceState(app).handsFree, isFalse);
  });

  testWidgets('P-V7 "ajuda" during the check-in opens help and stops',
      (tester) async {
    final app = await bootApp(tester);
    await openCheckIn(tester, app);
    app.voice.say(['não tão bem', 'socorro']);
    final base = app.voice.listens.length;
    await tapMic(tester);
    await waitFor(tester, find.byType(EmergencyScreen),
        timeout: const Duration(seconds: 15));
    await settle(tester, ms: 1500);
    await shot(tester, 'V07_help_from_check_in');
    expect(app.location, '/emergency');
    expect(voiceState(app).listening, isFalse);
    expect(app.voice.listens.length - base, 2);
  });

  testWidgets('P-V8 "voltar" inside the check-in goes one step back',
      (tester) async {
    final app = await bootApp(tester);
    await openCheckIn(tester, app);
    await heard(tester, app, 'não tão bem');
    await heard(tester, app, timeLabel);
    await heard(tester, app, branchLabel);
    expect(find.byKey(Key('jv2_option_$time.$branch.$option')), findsOneWidget);
    await heard(tester, app, 'voltar');
    await shot(tester, 'V08_voltar_in_check_in');
    expect(find.byKey(Key('jv2_branch_$time.$branch')), findsOneWidget);
    expect(app.location, '/journal');
  });

  testWidgets('P-V9 dictation: "Escrever o meu", trigger note and note '
      'fields', (tester) async {
    final app = await bootApp(tester);
    await openCheckIn(tester, app);
    await videoStart('V09_dictation');
    await heard(tester, app, 'não tão bem');
    await heard(tester, app, timeLabel);
    await heard(tester, app, branchLabel);

    // "Escrever o meu".
    await tap(tester, byKey('jv2_write_mine'));
    await waitFor(tester, byKey('voice_dictate_custom'));
    await shot(tester, 'V09_custom_field_mic');
    app.voice.say(['cansaço de tela']);
    await tap(tester, byKey('voice_dictate_custom'));
    await settle(tester, ms: 2500);
    await shot(tester, 'V09_custom_dictated');
    final custom = tester.widget<TextField>(byKey('jv2_custom_field'));
    expect(custom.controller!.text, 'cansaço de tela');
    expect(app.voice.listens.last, isTrue, reason: 'dictation mode');

    await heard(tester, app, pt.jv2WriteMineAdd);
    await heard(tester, app, optionLabel);
    await heard(tester, app, 'continuar');
    // Intensity step with two items: answer each card by voice.
    for (final p in ['começou hoje', 'três', 'começou hoje', 'três']) {
      await heard(tester, app, p);
    }
    await shot(tester, 'V09_two_items_by_voice');
    final s = app.container.read(journalFlowControllerProvider);
    await hostLog('V09 two items after voice: ${[
      for (final i in s.items) '${i.optionKey ?? i.customLabel}:${i.persistence}/${i.intensity}'
    ]}');
    await heard(tester, app, 'continuar');
    final stillThere = find.text(pt.jv2PersistenceHoje).evaluate().length;
    await hostLog('V09 after "continuar" on 2-item step: hoje labels on screen=$stillThere');
    if (stillThere > 0) {
      await shot(tester, 'V09_BUG_second_item_not_reachable_by_voice');
      // Finish the second card by touch to reach the next fields.
      await tap(tester, find.text(pt.jv2PersistenceHoje).last);
      await tap(tester, find.text('3').last);
      await tap(tester, find.text(pt.jv2Continue));
    }
    // Trigger step: "Outro" shows the trigger note field.
    await heard(tester, app, JournalLabels.trigger(pt, JournalKeys.triggerOutro));
    await waitFor(tester, byKey('voice_dictate_trigger_note'));
    await tester.ensureVisible(byKey('voice_dictate_trigger_note'));
    app.voice.say(['discussão no trabalho']);
    await tap(tester, byKey('voice_dictate_trigger_note'));
    await settle(tester, ms: 2500);
    await shot(tester, 'V09_trigger_note_dictated');
    expect(tester.widget<TextField>(byKey('jv2_trigger_note')).controller!.text,
        'discussão no trabalho');

    // On to the note.
    for (var i = 0; i < 4 && byKey('jv2_note_field').evaluate().isEmpty; i++) {
      await heard(tester, app, i == 0 ? 'continuar' : 'pular');
    }
    await waitFor(tester, byKey('voice_dictate_note'));
    app.voice.say(['dormi pouco']);
    await tap(tester, byKey('voice_dictate_note'));
    await settle(tester, ms: 2500);
    await shot(tester, 'V09_note_dictated');
    await videoStop();
    expect(tester.widget<TextField>(byKey('jv2_note_field')).controller!.text,
        'dormi pouco');
  });
}

bool _isAncestor(RenderObject ancestor, RenderObject node) {
  RenderObject? n = node;
  while (n != null) {
    if (identical(n, ancestor)) return true;
    n = n.parent;
  }
  return false;
}
