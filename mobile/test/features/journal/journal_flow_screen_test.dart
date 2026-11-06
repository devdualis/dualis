import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_controller.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:dualis_mobile/features/journal/presentation/journal_labels.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/journal_flow_screen.dart';
import 'package:dualis_mobile/features/journal/presentation/widgets/body_region_map.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journal_test_helpers.dart';

void main() {
  final pt = AppLocalizationsPt();

  Future<void> startNotSoGood(WidgetTester tester) async {
    await tapKey(tester, 'jv2_mood_nao_tao_bem');
  }

  const physical = JournalFlowArgs(initialArea: JournalArea.physical);

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  bool isCardSelected(WidgetTester tester, String key) => find
      .descendant(
        of: find.byKey(Key(key)),
        matching: find.byIcon(Icons.check_circle_rounded),
      )
      .evaluate()
      .isNotEmpty;

  /// Keys of the trigger options, in screen order.
  List<String> triggerKeysOnScreen(WidgetTester tester) => [
        for (final w in tester.widgetList(find.byWidgetPredicate((w) =>
            (w.key is ValueKey<String>) &&
            (w.key as ValueKey<String>).value.startsWith('jv2_trigger_'))))
          (w.key as ValueKey<String>).value.substring('jv2_trigger_'.length),
      ];

  /// Every trigger, tab by tab, then "Não sei" and "Outro". Leaves the last
  /// tab open.
  Future<List<String>> allTriggerKeys(WidgetTester tester) async {
    final keys = <String>[];
    for (final topic in JournalKeys.triggerTopics.keys) {
      if (find.byKey(Key('jv2_topic_$topic')).evaluate().isEmpty) continue;
      await tapKey(tester, 'jv2_topic_$topic');
      keys.addAll(triggerKeysOnScreen(tester).where((k) => k != 'nao_sei' && k != 'outro'));
    }
    return [...keys, 'nao_sei', 'outro'];
  }

  bool isMarked(WidgetTester tester, String region) =>
      find.byKey(Key('jv2_marked_$region')).evaluate().isNotEmpty;

  /// Persistence "hoje" for every row (its own screen; one item moves on by
  /// itself), then intensity [level] for every row.
  Future<void> fillIntensity(WidgetTester tester, int count, int level) async {
    for (var i = 0; i < count; i++) {
      await tapKey(tester, 'jv2_persistence_${i}_hoje');
    }
    if (count > 1) await tapKey(tester, 'jv2_continue');
    for (var i = 0; i < count; i++) {
      await tapKey(tester, 'jv2_intensity_${i}_$level');
    }
  }

  testWidgets('mood screen offers only Bem and Não tão bem, with icons and the axis', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);

    expect(find.text(pt.jv2MoodQuestion), findsOneWidget);
    expect(find.byKey(const Key('jv2_mood_bem')), findsOneWidget);
    expect(find.byKey(const Key('jv2_mood_nao_tao_bem')), findsOneWidget);
    expect(find.byKey(const Key('jv2_mood_normal')), findsNothing);
    expect(find.text(pt.jv2MoodNormal), findsNothing);
    // Emoji faces (client spec 2.4), no Material icons.
    expect(find.text('😊'), findsOneWidget);
    expect(find.text('😕'), findsOneWidget);
    expect(find.byIcon(Icons.sentiment_satisfied_rounded), findsNothing);
    expect(find.byIcon(Icons.sentiment_dissatisfied_rounded), findsNothing);
    // Opened without an area: emotional axis.
    expect(find.text(pt.jv2AxisEmotional), findsOneWidget);
  });

  testWidgets('physical card shows the Físico axis above the question', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h, args: physical);

    final axisLabel = tester.widget<Text>(find.byKey(const Key('jv2_axis_label')));
    expect(axisLabel.data, pt.jv2AxisPhysical);
  });

  testWidgets('mood greeting uses the Home periods (00:48 is Boa noite)', (tester) async {
    final h = JournalHarness()..clock = () => DateTime(2026, 10, 28, 0, 48);
    await pumpJournalFlow(tester, h);

    expect(find.textContaining(pt.jv2GoodEvening), findsOneWidget);
    expect(find.textContaining(pt.jv2GoodMorning), findsNothing);
  });

  testWidgets('Bem then "Só registrar" saves in one tap and opens the summary', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);

    await tapKey(tester, 'jv2_mood_bem');
    expect(find.text(pt.jv22PositiveQuestion), findsOneWidget);
    expect(h.remote.requestBodies, isEmpty);
    await tapKey(tester, 'jv22_just_save');

    expect(find.textContaining('SUMMARY items=0 pending=false'), findsOneWidget);
    final body = h.remote.requestBodies.single;
    expect(body['mood'], 'bem');
    expect(body['area'], 'emotional');
    expect(body['items'], isEmpty);
    expect(body['triggers'], isEmpty);
    expect(body['clientId'], isNotEmpty);
    expect(body.containsKey('coping'), isFalse);
    expect(body.containsKey('helpers'), isFalse);

  });

  testWidgets('Bem from the physical card completes only the physical axis', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h, args: physical);

    await tapKey(tester, 'jv2_mood_bem');

    expect(h.remote.requestBodies.single['area'], 'physical');

  });

  testWidgets('emotional path: time, branch, multi-select, custom, triggers, note', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);

    // Screen 1: the three times with their emojis and the client question.
    expect(find.text(pt.jv2TimeQuestion), findsOneWidget);
    for (final time in JournalKeys.times) {
      expect(find.byKey(Key('jv2_time_$time')), findsOneWidget);
    }
    expect(find.text('⏳'), findsOneWidget);
    expect(find.text('📍'), findsOneWidget);
    expect(find.text('🚀'), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_futuro.mente')), findsNothing);
    await tapKey(tester, 'jv2_time_futuro');

    // Screen 2: only the branches of that time, with its own question.
    expect(find.text(pt.jv24BranchQuestionFuturo), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_futuro.mente')), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_futuro.medo')), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_passado.tristeza')), findsNothing);
    await tapKey(tester, 'jv2_branch_futuro.mente');

    // Screen 3: the options.

    await tapKey(tester, 'jv2_option_futuro.mente.antecipar');
    await tapKey(tester, 'jv2_option_futuro.mente.cobranca');
    await tapKey(tester, 'jv2_write_mine');
    await tester.enterText(find.byKey(const Key('jv2_custom_field')), 'Cansaço do trânsito');
    await tapKey(tester, 'jv2_custom_add');
    expect(find.byKey(const Key('jv2_custom_chip_Cansaço do trânsito')), findsOneWidget);
    await tapKey(tester, 'jv2_continue');

    // Persistence on its own screen, one row per item; then intensity.
    expect(find.text(pt.jv24PersistenceCompactQuestion), findsOneWidget);
    expect(find.byKey(const Key('jv2_item_row_2')), findsOneWidget);
    expect(find.byKey(const Key('jv2_intensity_0_3')), findsNothing);
    final cont = find.byKey(const Key('jv2_continue'));
    expect(tester.widget<FilledButton>(cont).onPressed, isNull);
    await fillIntensity(tester, 3, 3);
    expect(find.text(pt.jv2IntensityCompactQuestion), findsOneWidget);
    expect(tester.widget<FilledButton>(cont).onPressed, isNotNull);
    await tapKey(tester, 'jv2_continue');

    // No physical item: physical-only triggers are not offered.
    expect(find.text(pt.jv2TriggersQuestion), findsOneWidget);
    for (final t in JournalKeys.physicalOnlyTriggers) {
      expect(find.byKey(Key('jv2_trigger_$t')), findsNothing);
    }
    await tapKey(tester, 'jv2_trigger_trabalho');
    await tapKey(tester, 'jv2_trigger_outro');
    await tester.enterText(find.byKey(const Key('jv2_trigger_note')), 'Reunião longa');
    await tester.pumpAndSettle();
    await tapKey(tester, 'jv2_continue');

    // Closing questions (v2.2): one coping, several helpers.
    expect(find.text(pt.jv22CopingQuestion), findsOneWidget);
    await tapKey(tester, 'jv22_coping_esperei');
    await tapKey(tester, 'jv22_helper_pausa');
    await tapKey(tester, 'jv22_helper_conversar');
    await tapKey(tester, 'jv2_continue');

    await tester.enterText(find.byKey(const Key('jv2_note_field')), 'Dia corrido');
    await tester.pumpAndSettle();
    await tapKey(tester, 'jv2_save');

    expect(find.textContaining('SUMMARY items=3'), findsOneWidget);
    final body = h.remote.requestBodies.single;
    expect(body['mood'], 'nao_tao_bem');
    expect(body['area'], 'emotional');
    expect(body['triggers'], ['trabalho', 'outro']);
    expect(body['triggerNote'], 'Reunião longa');
    expect(body['coping'], 'esperei');
    expect(body['helpers'], ['conversar', 'pausa']);
    expect(body['note'], 'Dia corrido');
    final items = (body['items'] as List).cast<Map<String, dynamic>>();
    expect(items.map((i) => i['optionKey']), [
      'futuro.mente.antecipar',
      'futuro.mente.cobranca',
      'futuro.custom',
    ]);
    expect(items.last['customLabel'], 'Cansaço do trânsito');
    expect(items.every((i) => i['kind'] == 'emotional'), isTrue);
    expect(items.every((i) => i['sensation'] == null), isTrue);
    expect(items.every((i) => i['intensity'] == 3 && i['persistence'] == 'hoje'), isTrue);
    // Variant ids of the phrases that were shown (UX analytics only).
    final variants = (body['transitionVariantIds'] as List).cast<String>();
    expect(variants, isNotEmpty);
    for (final id in variants) {
      expect(JournalLabels.phrase(pt, id), isNot(id));
    }
  });

  testWidgets('"+ Registrar outra coisa" goes back to the feelings screen', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await pickFeeling(tester, 'passado', 'tristeza');
    await tapKey(tester, 'jv2_option_passado.tristeza.saudade');
    await tapKey(tester, 'jv23_more');

    expect(find.text(pt.jv2TimeQuestion), findsOneWidget);
    await pickFeeling(tester, 'presente', 'energia');
    await tapKey(tester, 'jv2_option_presente.energia.corpo');
    await tapKey(tester, 'jv2_continue');

    expect(find.byKey(const Key('jv2_item_row_1')), findsOneWidget);
  });

  testWidgets('phrases: own pool per time, per branch and per region; thank-you before the scale',
      (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await tapKey(tester, 'jv2_time_passado');
    var id = containerOf(tester).read(journalFlowControllerProvider).phraseId!;
    expect(id, startsWith('passado.'));
    expect(find.text(JournalLabels.phrase(pt, id)), findsOneWidget);
    await tapKey(tester, 'jv2_branch_passado.tristeza');
    id = containerOf(tester).read(journalFlowControllerProvider).phraseId!;
    expect(id, startsWith('passado.tristeza.'));
    expect(find.text(JournalLabels.phrase(pt, id)), findsOneWidget);
    await tapKey(tester, 'jv2_option_passado.tristeza.culpa');
    await tapKey(tester, 'jv2_continue');

    // Persistence alone, after the thank-you line; one tap moves on.
    expect(find.text(pt.jv2PhraseThanks1), findsOneWidget);
    expect(find.text(pt.jv2PersistenceQuestion), findsOneWidget);
    expect(find.byKey(const Key('jv2_intensity_0_3')), findsNothing);
    expect(find.byKey(const Key('jv2_emergency_line')), findsOneWidget);
    await tapKey(tester, 'jv2_persistence_0_dias_semanas');

    // Then intensity alone.
    expect(find.text(pt.jv2IntensityQuestion), findsOneWidget);
    expect(find.byKey(const Key('jv2_persistence_0_hoje')), findsNothing);
    expect(find.byKey(const Key('jv2_emergency_line')), findsOneWidget);
    await tapKey(tester, 'jv2_back');
    expect(isCardSelected(tester, 'jv2_persistence_0_dias_semanas'), isTrue);
  });

  testWidgets('transition phrase types in, then shows whole', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await tester.tap(find.byKey(const Key('jv2_time_futuro')));
    await tester.pump();
    // Past the screen fade (280 ms), still typing.
    await tester.pump(const Duration(milliseconds: 350));
    String typed() {
      final text = tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('jv2_phrase')),
        matching: find.byType(Text),
      ));
      return (text.textSpan! as TextSpan).children!.first.toPlainText();
    }

    final id = containerOf(tester).read(journalFlowControllerProvider).phraseId!;
    final full = JournalLabels.phrase(pt, id);
    expect(typed().length, lessThan(full.length));
    await tester.pumpAndSettle();
    expect(typed(), full);
  });

  test('a screen never shows the same phrase twice in a row', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(journalFlowControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final flow = container.read(journalFlowControllerProvider.notifier);
    String? last;
    for (var i = 0; i < 40; i++) {
      flow.chooseMood(JournalKeys.moodNaoTaoBem);
      flow.chooseTime('futuro');
      final id = container.read(journalFlowControllerProvider).phraseId;
      expect(id, startsWith('futuro.'));
      expect(id, isNot(last));
      last = id;
    }
    // Over 40 entries all 7 variants show up.
    expect(
      container.read(journalFlowControllerProvider).shownPhraseIds.where((i) => RegExp(r'^futuro\.\d$').hasMatch(i)).toSet(),
      hasLength(7),
    );
  });

  testWidgets('physical path: regions on both sides, no sensation step, per-region options', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h, args: physical);
    await startNotSoGood(tester);

    // Straight to the body screen.
    expect(find.text(pt.jv2BodyQuestion), findsOneWidget);
    expect(pt.jv2BodyQuestion, 'Onde você sente dor ou incômodo?');
    expect(find.byKey(const Key('jv2_region_costas')), findsNothing);
    await tapKey(tester, 'jv2_region_cabeca');
    await tapKey(tester, 'jv2_side_back');
    await tapKey(tester, 'jv2_region_costas');
    await tapKey(tester, 'jv2_continue');

    // Region 1: cabeça (front). Straight to its 2 branches (v2.5): no
    // "É dor ou incômodo?" and no Rosto branch.
    expect(find.text(pt.jv23WhereExactly), findsOneWidget);
    expect(find.byKey(const Key('jv2_sensation_dor')), findsNothing);
    expect(find.text('${pt.jv2RegionCabeca} · ${pt.jv2BodyFront}'), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_cabeca.sentidos')), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_cabeca.rosto')), findsNothing);
    expect(find.byKey(const Key('jv2_branch_cabeca.nuca')), findsNothing);
    await tapKey(tester, 'jv2_branch_cabeca.pressao');
    // Tontura and mandíbula moved here from Rosto.
    expect(find.byKey(const Key('jv2_option_cabeca.pressao.tontura')), findsOneWidget);
    expect(find.byKey(const Key('jv2_option_cabeca.pressao.mandibula')), findsOneWidget);
    await tapKey(tester, 'jv2_option_cabeca.pressao.temporas');
    await tapKey(tester, 'jv2_option_cabeca.pressao.tontura');
    await tapKey(tester, 'jv2_continue');
    // Region 2: costas (back).
    expect(find.byKey(const Key('jv2_branch_costas.rigidez')), findsOneWidget);
    await tapKey(tester, 'jv2_branch_costas.rigidez');
    await tapKey(tester, 'jv2_option_costas.rigidez.lombar');
    await tapKey(tester, 'jv2_write_mine');
    await tester.enterText(find.byKey(const Key('jv2_custom_field')), 'Peso no cóccix');
    await tapKey(tester, 'jv2_custom_add');
    await tapKey(tester, 'jv2_continue');

    expect(find.textContaining(pt.jv2RegionCostas), findsWidgets);
    await fillIntensity(tester, 4, 2);
    await tapKey(tester, 'jv2_continue');

    // Temples, dizziness, lower back and a written back item: together
    // they reach every factor. Skip clears choices.
    expect((await allTriggerKeys(tester)).toSet(), JournalKeys.triggers.toSet());
    await tapKey(tester, 'jv2_trigger_esforco');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv22_closing_skip');
    await tapKey(tester, 'jv2_save');

    final body = h.remote.requestBodies.single;
    expect(body['area'], 'physical');
    expect(body['triggers'], isEmpty);
    final items = (body['items'] as List).cast<Map<String, dynamic>>();
    expect(items.map((i) => [i['optionKey'], i['bodySide']]), [
      ['cabeca.pressao.temporas', 'front'],
      ['cabeca.pressao.tontura', 'front'],
      ['costas.rigidez.lombar', 'back'],
      ['costas.custom', 'back'],
    ]);
    expect(items.every((i) => !i.containsKey('sensation')), isTrue);
    expect(items.last['customLabel'], 'Peso no cóccix');
    expect(items.every((i) => i['kind'] == 'physical'), isTrue);

  });

  testWidgets('head on the back side: pressão and nuca, never eyes/mouth/throat', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h, args: physical);
    await startNotSoGood(tester);
    await tapKey(tester, 'jv2_side_back');
    await tapKey(tester, 'jv2_region_cabeca');
    await tapKey(tester, 'jv2_continue');

    expect(find.text('${pt.jv2RegionCabeca} · ${pt.jv2BodyBack}'), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_cabeca.pressao')), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_cabeca.nuca')), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_cabeca.sentidos')), findsNothing);
    await tapKey(tester, 'jv2_branch_cabeca.nuca');
    expect(find.text(pt.jv2OptCabecaNucaRigida), findsOneWidget);
    expect(find.text(pt.jv2OptCabecaNucaPontada), findsOneWidget);
    await tapKey(tester, 'jv2_option_cabeca.nuca.rigida');
    await tapKey(tester, 'jv2_continue');
    await fillIntensity(tester, 1, 2);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv22_closing_skip');
    await tapKey(tester, 'jv2_save');

    final item = (h.remote.requestBodies.single['items'] as List).single as Map;
    expect(item['optionKey'], 'cabeca.nuca.rigida');
    expect(item['bodySide'], 'back');
    expect(item.containsKey('sensation'), isFalse);
  });

  testWidgets('whole-body areas are recorded without a side', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h, args: physical);
    await startNotSoGood(tester);

    expect(find.text(pt.jv2WholeBody), findsOneWidget);
    expect(find.byKey(const Key('jv2_region_pele')), findsNothing);
    await tapKey(tester, 'jv2_topic_whole_body');
    for (final area in JournalKeys.wholeBodyAreas) {
      expect(find.byKey(Key('jv2_region_$area')), findsOneWidget);
    }
    await tapKey(tester, 'jv2_region_hormonios');
    await tapKey(tester, 'jv2_continue');

    expect(find.text(pt.jv2RegionHormonios), findsWidgets);
    await tapKey(tester, 'jv2_branch_hormonios.temperatura');
    await tapKey(tester, 'jv2_option_hormonios.temperatura.calorao');
    await tapKey(tester, 'jv2_continue');
    await fillIntensity(tester, 1, 3);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv22_closing_skip');
    await tapKey(tester, 'jv2_save');

    final item = (h.remote.requestBodies.single['items'] as List).single as Map;
    expect(item['optionKey'], 'hormonios.temperatura.calorao');
    expect(item.containsKey('bodySide'), isFalse);
    expect(item.containsKey('sensation'), isFalse);
  });

  testWidgets('tapping the body map toggles the region', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h, args: physical);
    await startNotSoGood(tester);

    final map = find.byKey(const Key('jv2_body_map_front'));
    final rect = tester.getRect(map);
    final head = BodyRegionMap.shapesOf('cabeca', 'front').first.center;
    await tester.tapAt(Offset(
      rect.left + head.dx * rect.width,
      rect.top + head.dy * rect.height,
    ));
    await tester.pumpAndSettle();

    expect(isMarked(tester, 'cabeca'), isTrue);
    // The "Marcado" pill takes it off again.
    await tapKey(tester, 'jv2_marked_cabeca');
    expect(isMarked(tester, 'cabeca'), isFalse);
  });

  testWidgets('conditions are a list above the body map and use the full intensity screen',
      (tester) async {
    final h = JournalHarness(
      conditions: const [UserCondition(id: 'c1', label: 'Enxaqueca')],
    );
    await pumpJournalFlow(tester, h, args: physical);
    await startNotSoGood(tester);

    expect(find.text(pt.jv2AreaConditions), findsOneWidget);
    expect(find.byKey(const Key('jv2_condition_add')), findsNothing);
    // First on the screen, above the map (Phase 16).
    expect(
      tester.getTopLeft(find.byKey(const Key('jv2_condition_c1'))).dy,
      lessThan(tester.getTopLeft(find.byType(BodyRegionMap)).dy),
    );
    expect(find.byType(FilterChip), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('jv2_condition_c1')),
        matching: find.text('Enxaqueca'),
      ),
      findsOneWidget,
    );
    final cont = find.byKey(const Key('jv2_continue'));
    expect(tester.widget<FilledButton>(cont).onPressed, isNull);
    await tapKey(tester, 'jv2_condition_c1');
    await tapKey(tester, 'jv2_continue');

    // Single item: big 1-5 scale; the chosen level's §8 text shows below.
    expect(find.text(pt.jv2ConditionCardQuestion('Enxaqueca')), findsOneWidget);
    expect(find.text(pt.jv23IntensityPickHint), findsOneWidget);
    expect(find.text(pt.jv2PersistenceOptional), findsOneWidget);
    await tapKey(tester, 'jv2_intensity_0_4');
    // D10: the level shows its name before the description.
    expect(find.text('4 · ${pt.jv25IntensityName4} — ${pt.jv2IntensityEmotional4}'), findsOneWidget);
    expect(pt.jv25IntensityName4, 'Forte');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv22_closing_skip');
    await tapKey(tester, 'jv2_save');

    final body = h.remote.requestBodies.single;
    final item = (body['items'] as List).single as Map<String, dynamic>;
    expect(item, {'kind': 'condition', 'conditionId': 'c1', 'intensity': 4});
    // The condition name never leaves in the request body.
    expect(body.toString(), isNot(contains('Enxaqueca')));
  });

  testWidgets('when conditions list is empty, conditions section is completely omitted from check-in',
      (tester) async {
    final h = JournalHarness(conditions: const []);
    await pumpJournalFlow(tester, h, args: physical);
    await startNotSoGood(tester);

    expect(find.text(pt.jv2AreaConditions), findsNothing);
    expect(find.byKey(const Key('jv2_condition_add')), findsNothing);
  });

  testWidgets('offline save goes to the outbox and syncs once online', (tester) async {
    final h = JournalHarness(online: false);
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await pickFeeling(tester, 'presente', 'sobrecarga');
    await tapKey(tester, 'jv2_option_presente.sobrecarga.paciencia');
    await tapKey(tester, 'jv2_continue');
    await fillIntensity(tester, 1, 3);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv22_closing_skip');
    await tapKey(tester, 'jv2_save');

    expect(find.textContaining('pending=true'), findsOneWidget);
    expect(h.remote.created, isEmpty);
    final pending = await h.local.pending();
    expect(pending, hasLength(1));

    h.online = true;
    expect(await h.repository.syncPending(), 1);
    expect(h.remote.created.single.clientId, pending.single.clientId);
    expect(await h.local.pending(), isEmpty);
    expect(await h.repository.syncPending(), 0);
  });

  testWidgets('help never depends on content: same static line, no notice, no redirect',
      (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await pickFeeling(tester, 'presente', 'sobrecarga');
    await tapKey(tester, 'jv2_option_presente.sobrecarga.aperto');
    await tapKey(tester, 'jv2_continue');

    final line = find.byKey(const Key('jv2_emergency_line'));
    expect(line, findsOneWidget);
    expect(find.text(pt.jv2EmergencyLine), findsOneWidget);

    // The highest level changes nothing on screen besides the selection.
    await tapKey(tester, 'jv2_persistence_0_hoje');
    await tapKey(tester, 'jv2_intensity_0_5');
    expect(find.text(pt.jv2EmergencyLine), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(MaterialBanner), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv22_closing_skip');

    await tester.enterText(
      find.byKey(const Key('jv2_note_field')),
      'não consigo respirar, dor no peito, quero sumir',
    );
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    await tapKey(tester, 'jv2_save');

    expect(find.text('HELP SCREEN'), findsNothing);
    expect(find.byKey(const Key('summary_stub')), findsOneWidget);
  });

  testWidgets('Gemini catalog suggestion can replace the written label', (tester) async {
    final h = JournalHarness();
    h.remote.suggestedOptionKey = 'futuro.mente.antecipar';
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await pickFeeling(tester, 'futuro', 'mente');
    await tapKey(tester, 'jv2_write_mine');
    await tester.enterText(
      find.byKey(const Key('jv2_custom_field')),
      'estou muito chateado com a vida',
    );
    await tapKey(tester, 'jv2_custom_add');
    expect(h.remote.suggestRequests.single,
        {'text': 'estou muito chateado com a vida', 'kind': 'emotional', 'branch': 'futuro.mente'});
    expect(find.byKey(const Key('jv2_suggest_dialog')), findsOneWidget);
    expect(find.textContaining(pt.jv2OptFuturoMenteAntecipar), findsWidgets);
    await tapKey(tester, 'jv2_suggest_yes');
    expect(find.byKey(const Key('jv2_custom_chip_estou muito chateado com a vida')), findsNothing);
    // The accepted option belongs to the branch on screen, so it shows as selected here.
    final dynamic chosen =
        tester.widget(find.byKey(const Key('jv2_option_futuro.mente.antecipar')));
    expect(chosen.selected, isTrue);
    await tapKey(tester, 'jv2_continue');
    await fillIntensity(tester, 1, 2);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv22_closing_skip');
    await tapKey(tester, 'jv2_save');
    final items = (h.remote.requestBodies.single['items'] as List)
        .cast<Map<String, dynamic>>();
    expect(items.single['optionKey'], 'futuro.mente.antecipar');
    expect(items.single['customLabel'], isNull);
  });

  group('AI consent before "Escrever o meu" suggestions', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    Future<void> writeMine(WidgetTester tester, String text) async {
      await tapKey(tester, 'jv2_write_mine');
      await tester.enterText(find.byKey(const Key('jv2_custom_field')), text);
      await tapKey(tester, 'jv2_custom_add');
    }

    testWidgets('a profile shared by another account: no consent dialog, nothing sent',
        (tester) async {
      final h = JournalHarness();
      h.consent.granted = false;
      h.remote.suggestedOptionKey = 'futuro.mente.antecipar';
      await pumpJournalFlow(
        tester,
        h,
        extraOverrides: [activeProfileControllerProvider.overrideWith(_SharedByOther.new)],
      );
      await startNotSoGood(tester);
      await pickFeeling(tester, 'futuro', 'mente');

      await writeMine(tester, 'penso demais no amanhã');

      expect(find.byKey(const Key('ai_consent_dialog')), findsNothing);
      expect(find.byKey(const Key('jv2_custom_chip_penso demais no amanhã')), findsOneWidget);
      expect(h.remote.suggestRequests, isEmpty);
      expect(h.consent.calls, isEmpty);
    });

    testWidgets('without consent the dialog comes first; "Agora não" keeps the label and sends nothing',
        (tester) async {
      final h = JournalHarness();
      h.consent.granted = false;
      h.remote.suggestedOptionKey = 'futuro.mente.antecipar';
      await pumpJournalFlow(tester, h);
      await startNotSoGood(tester);
      await pickFeeling(tester, 'futuro', 'mente');

      await writeMine(tester, 'penso demais no amanhã');
      expect(find.byKey(const Key('ai_consent_dialog')), findsOneWidget);
      expect(h.remote.suggestRequests, isEmpty);
      await tapKey(tester, 'ai_consent_decline');

      expect(find.byKey(const Key('jv2_custom_chip_penso demais no amanhã')), findsOneWidget);
      expect(find.byKey(const Key('jv2_suggest_dialog')), findsNothing);
      expect(h.remote.suggestRequests, isEmpty);
      expect(h.consent.calls.where((c) => c.startsWith('grant')), isEmpty);

      // The decline is remembered: a second label goes straight in.
      await writeMine(tester, 'não durmo direito');
      expect(find.byKey(const Key('ai_consent_dialog')), findsNothing);
      expect(find.byKey(const Key('jv2_custom_chip_não durmo direito')), findsOneWidget);
      expect(h.remote.suggestRequests, isEmpty);
    });

    testWidgets('accepting grants the consent, then the suggestion is asked as before',
        (tester) async {
      final h = JournalHarness();
      h.consent.granted = false;
      h.remote.suggestedOptionKey = 'futuro.mente.antecipar';
      await pumpJournalFlow(tester, h);
      await startNotSoGood(tester);
      await pickFeeling(tester, 'futuro', 'mente');

      await writeMine(tester, 'penso demais no amanhã');
      expect(h.remote.suggestRequests, isEmpty);
      await tapKey(tester, 'ai_consent_accept');

      expect(h.consent.granted, isTrue);
      expect(h.consent.calls, contains('grant:2026.1'));
      expect(h.remote.suggestRequests.single['text'], 'penso demais no amanhã');
      expect(find.byKey(const Key('jv2_suggest_dialog')), findsOneWidget);
      await tapKey(tester, 'jv2_suggest_no');
      expect(find.byKey(const Key('jv2_custom_chip_penso demais no amanhã')), findsOneWidget);
    });

    testWidgets('server 403 AI_CONSENT_REQUIRED keeps the typed label and reads the consent again',
        (tester) async {
      final h = JournalHarness();
      h.remote.suggestOptionError = suggestForbidden('AI_CONSENT_REQUIRED');
      await pumpJournalFlow(tester, h);
      await startNotSoGood(tester);
      await pickFeeling(tester, 'futuro', 'mente');
      final readsBefore = h.consent.calls.where((c) => c == 'status').length;

      await writeMine(tester, 'penso demais no amanhã');
      expect(find.byKey(const Key('jv2_custom_chip_penso demais no amanhã')), findsOneWidget);
      expect(find.byKey(const Key('jv2_suggest_dialog')), findsNothing);
      expect(find.byKey(const Key('ai_consent_dialog')), findsNothing);
      // One read by the gate, one more after the server said no.
      expect(h.consent.calls.where((c) => c == 'status').length, readsBefore + 2);
    });

    testWidgets('server 403 AI_PROFILE_NOT_ALLOWED keeps the typed label', (tester) async {
      final h = JournalHarness();
      h.remote.suggestOptionError = suggestForbidden('AI_PROFILE_NOT_ALLOWED');
      await pumpJournalFlow(tester, h);
      await startNotSoGood(tester);
      await pickFeeling(tester, 'futuro', 'mente');

      await writeMine(tester, 'penso demais no amanhã');
      expect(find.byKey(const Key('jv2_custom_chip_penso demais no amanhã')), findsOneWidget);
      expect(find.byKey(const Key('jv2_suggest_dialog')), findsNothing);
    });

    testWidgets('offline keeps the typed label with no consent dialog and no request',
        (tester) async {
      final h = JournalHarness(online: false);
      h.consent.granted = false;
      h.remote.suggestedOptionKey = 'futuro.mente.antecipar';
      await pumpJournalFlow(tester, h);
      await startNotSoGood(tester);
      await pickFeeling(tester, 'futuro', 'mente');

      await writeMine(tester, 'penso demais no amanhã');
      expect(find.byKey(const Key('jv2_custom_chip_penso demais no amanhã')), findsOneWidget);
      expect(find.byKey(const Key('ai_consent_dialog')), findsNothing);
      expect(find.byKey(const Key('jv2_suggest_dialog')), findsNothing);
      expect(h.remote.suggestRequests, isEmpty);
      expect(h.consent.calls, isEmpty);
    });

    testWidgets('good moments never ask for consent and are never sent', (tester) async {
      final h = JournalHarness();
      h.consent.granted = false;
      h.remote.suggestedOptionKey = 'presente.calma.paz';
      await pumpJournalFlow(tester, h);
      await tapKey(tester, 'jv2_mood_bem');
      await tapKey(tester, 'jv2_branch_presente.calma');

      await writeMine(tester, 'Almoço com a avó');
      expect(find.byKey(const Key('ai_consent_dialog')), findsNothing);
      expect(find.byKey(const Key('jv2_custom_chip_Almoço com a avó')), findsOneWidget);
      expect(h.remote.suggestRequests, isEmpty);
      expect(h.consent.calls, isEmpty);
    });
  });

  testWidgets('back returns to the previous screen with its answers', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h, args: physical);
    await startNotSoGood(tester);
    await tapKey(tester, 'jv2_region_cabeca');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_back');

    expect(find.text(pt.jv2BodyQuestion), findsOneWidget);
    expect(isMarked(tester, 'cabeca'), isTrue);
    await tapKey(tester, 'jv2_back');
    expect(find.text(pt.jv2MoodQuestion), findsOneWidget);
  });

  group('v2.2', () {
    testWidgets('Bem then a good moment and a written one: positive items only, no AI',
        (tester) async {
      final h = JournalHarness();
      h.remote.suggestedOptionKey = 'presente.calma.paz';
      await pumpJournalFlow(tester, h);

      await tapKey(tester, 'jv2_mood_bem');
      expect(find.byKey(const Key('jv2_branch_presente.calma')), findsOneWidget);
      expect(find.byKey(const Key('jv2_branch_presente.conexao')), findsOneWidget);
      expect(find.byKey(const Key('jv2_branch_presente.energia')), findsNothing);
      await tapKey(tester, 'jv2_branch_presente.calma');
      expect(find.text(pt.jv22OptPresenteCalmaPaz), findsOneWidget);
      await tapKey(tester, 'jv2_option_presente.calma.paz');
      await tapKey(tester, 'jv2_write_mine');
      await tester.enterText(find.byKey(const Key('jv2_custom_field')), 'Almoço com a avó');
      await tapKey(tester, 'jv2_custom_add');
      expect(h.remote.suggestRequests, isEmpty);
      expect(find.byKey(const Key('jv2_suggest_dialog')), findsNothing);
      await tapKey(tester, 'jv2_save');

      expect(find.textContaining('SUMMARY items=2'), findsOneWidget);
      final body = h.remote.requestBodies.single;
      expect(body['mood'], 'bem');
      expect(body['area'], 'emotional');
      expect(body['triggers'], isEmpty);
      expect(body.containsKey('coping'), isFalse);
      expect(body.containsKey('helpers'), isFalse);
      final items = (body['items'] as List).cast<Map<String, dynamic>>();
      expect(items, [
        {'kind': 'positive', 'optionKey': 'presente.calma.paz'},
        {'kind': 'positive', 'optionKey': 'presente.custom', 'customLabel': 'Almoço com a avó'},
      ]);

    });

    testWidgets('back from the good-moments question returns to the mood screen', (tester) async {
      final h = JournalHarness();
      await pumpJournalFlow(tester, h);
      await tapKey(tester, 'jv2_mood_bem');
      await tapKey(tester, 'jv2_back');
      expect(find.text(pt.jv2MoodQuestion), findsOneWidget);
      expect(h.remote.requestBodies, isEmpty);
    });

    testWidgets('presente has 2 branches (no solidão since v2.5), max 4 options per screen', (tester) async {
      final h = JournalHarness();
      await pumpJournalFlow(tester, h);
      await startNotSoGood(tester);
      await tapKey(tester, 'jv2_time_presente');
      for (final b in ['energia', 'sobrecarga']) {
        expect(find.byKey(Key('jv2_branch_presente.$b')), findsOneWidget);
      }
      expect(find.byKey(const Key('jv2_branch_presente.solidao')), findsNothing);
      expect(find.text(pt.jv22BranchPresenteSolidao), findsNothing);
      await tapKey(tester, 'jv2_branch_presente.sobrecarga');
      expect(
        find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('jv2_option_')),
        findsNWidgets(4),
      );
      await tapKey(tester, 'jv2_option_presente.sobrecarga.inquieto');
      await tapKey(tester, 'jv2_continue');
      await fillIntensity(tester, 1, 2);
      await tapKey(tester, 'jv2_continue');

      // Emotional entry: new triggers offered, in topic order.
      expect(await allTriggerKeys(tester),
          ['trabalho', 'sono', 'telas', 'familia', 'dinheiro', 'ciclo', 'nao_sei', 'outro']);
      await tapKey(tester, 'jv2_topic_dia');
      await tapKey(tester, 'jv2_trigger_telas');
      await tapKey(tester, 'jv2_trigger_trabalho');
      await tapKey(tester, 'jv2_continue');
      await tapKey(tester, 'jv22_closing_skip');
      await tapKey(tester, 'jv2_save');

      final body = h.remote.requestBodies.single;
      expect(body['triggers'], ['trabalho', 'telas']);
      expect((body['items'] as List).single['optionKey'], 'presente.sobrecarga.inquieto');
    });

    testWidgets('front head: nariz and ouvido under sentidos; barriga: intestino under cólica',
        (tester) async {
      final h = JournalHarness();
      await pumpJournalFlow(tester, h, args: physical);
      await startNotSoGood(tester);
      await tapKey(tester, 'jv2_region_cabeca');
      await tapKey(tester, 'jv2_region_barriga');
      await tapKey(tester, 'jv2_continue');

      expect(find.byKey(const Key('jv2_branch_cabeca.rosto')), findsNothing);
      expect(find.byKey(const Key('jv2_branch_cabeca.nuca')), findsNothing);
      expect(find.text(pt.jv2BranchCabecaSentidos), findsOneWidget);
      await tapKey(tester, 'jv2_branch_cabeca.sentidos');
      for (final o in ['garganta', 'olhos', 'nariz', 'ouvido']) {
        expect(find.byKey(Key('jv2_option_cabeca.sentidos.$o')), findsOneWidget);
      }
      expect(find.text('Garganta arranhando, seca ou dificuldade de engolir'), findsOneWidget);
      await tapKey(tester, 'jv2_option_cabeca.sentidos.nariz');
      await tapKey(tester, 'jv2_continue');

      expect(find.byKey(const Key('jv2_branch_barriga.intestino')), findsNothing);
      expect(find.text('Cólica, gases ou intestino'), findsOneWidget);
      await tapKey(tester, 'jv2_branch_barriga.colica');
      for (final o in ['gases', 'pontadas', 'preso', 'solto', 'menstrual']) {
        expect(find.byKey(Key('jv2_option_barriga.colica.$o')), findsOneWidget);
      }
      // A merged branch still opens with its region's phrase.
      expect(containerOf(tester).read(journalFlowControllerProvider).shownPhraseIds
          .where((id) => id.startsWith('region.barriga.')), isNotEmpty);
      await tapKey(tester, 'jv2_option_barriga.colica.solto');
      await tapKey(tester, 'jv2_option_barriga.colica.menstrual');
      await tapKey(tester, 'jv2_continue');
      await fillIntensity(tester, 3, 3);
      await tapKey(tester, 'jv2_continue');

      // Physical entry: only the factors of the chosen options, in topic
      // order (no sleep, screens, effort or fall for nose and bowels).
      expect(await allTriggerKeys(tester), [
        'trabalho', 'alimentacao', 'familia', 'dinheiro',
        'ciclo', 'medicamento', 'clima', 'nao_sei', 'outro',
      ]);
      await tapKey(tester, 'jv2_trigger_ciclo');
      await tapKey(tester, 'jv2_continue');
      await tapKey(tester, 'jv22_closing_skip');
      await tapKey(tester, 'jv2_save');

      final body = h.remote.requestBodies.single;
      expect(body['triggers'], ['ciclo']);
      final items = (body['items'] as List).cast<Map<String, dynamic>>();
      expect(items.map((i) => [i['optionKey'], i['bodySide']]), [
        ['cabeca.sentidos.nariz', 'front'],
        ['barriga.colica.solto', 'front'],
        ['barriga.colica.menstrual', 'front'],
      ]);
    });

    testWidgets('back side head keeps pressão and nuca only', (tester) async {
      final h = JournalHarness();
      await pumpJournalFlow(tester, h, args: physical);
      await startNotSoGood(tester);
      await tapKey(tester, 'jv2_side_back');
      await tapKey(tester, 'jv2_region_cabeca');
      await tapKey(tester, 'jv2_continue');
      expect(find.byKey(const Key('jv2_branch_cabeca.rosto')), findsNothing);
    });

    testWidgets('closing screen: nada_ainda is exclusive, coping is single choice', (tester) async {
      final h = JournalHarness();
      await pumpJournalFlow(tester, h);
      await startNotSoGood(tester);
      await pickFeeling(tester, 'futuro', 'mente');
      await tapKey(tester, 'jv2_option_futuro.mente.indecisao');
      await tapKey(tester, 'jv2_continue');
      await fillIntensity(tester, 1, 2);
      await tapKey(tester, 'jv2_continue');
      await tapKey(tester, 'jv2_skip');

      expect(find.byKey(const Key('jv22_closing_skip')), findsOneWidget);
      bool selected(String h) =>
          isCardSelected(tester, 'jv22_helper_$h');
      await tapKey(tester, 'jv22_helper_lazer');
      await tapKey(tester, 'jv22_helper_descansar');
      await tapKey(tester, 'jv22_helper_nada_ainda');
      expect(selected('nada_ainda'), isTrue);
      expect(selected('lazer'), isFalse);
      expect(selected('descansar'), isFalse);
      await tapKey(tester, 'jv22_helper_mexer_corpo');
      expect(selected('nada_ainda'), isFalse);
      expect(selected('mexer_corpo'), isTrue);
      // Coping is single choice; tapping it again clears it.
      await tapKey(tester, 'jv22_coping_consegui');
      await tapKey(tester, 'jv22_coping_dificil');
      await tapKey(tester, 'jv22_coping_dificil');
      await tapKey(tester, 'jv22_coping_consegui');

      // Back from the note keeps the answers of the closing screen.
      await tapKey(tester, 'jv22_closing_skip');
      await tapKey(tester, 'jv2_back');
      expect(selected('mexer_corpo'), isTrue);
      await tapKey(tester, 'jv2_continue');
      await tapKey(tester, 'jv2_save');
      final body = h.remote.requestBodies.single;
      expect(body['coping'], 'consegui');
      expect(body['helpers'], ['mexer_corpo']);
    });

    testWidgets('closing skip sends no coping and no helpers', (tester) async {
      final h = JournalHarness();
      await pumpJournalFlow(tester, h);
      await startNotSoGood(tester);
      await pickFeeling(tester, 'passado', 'memoria');
      await tapKey(tester, 'jv2_option_passado.memoria.vergonha');
      await tapKey(tester, 'jv2_continue');
      await fillIntensity(tester, 1, 2);
      await tapKey(tester, 'jv2_continue');
      await tapKey(tester, 'jv2_skip');
      await tapKey(tester, 'jv22_helper_conversar');
      await tapKey(tester, 'jv22_coping_esperei');
      await tapKey(tester, 'jv22_closing_skip');
      await tapKey(tester, 'jv2_save');
      final body = h.remote.requestBodies.single;
      expect(body.containsKey('coping'), isFalse);
      expect(body.containsKey('helpers'), isFalse);
    });

    testWidgets('offline good moment goes to the outbox and syncs as is', (tester) async {
      final h = JournalHarness(online: false);
      await pumpJournalFlow(tester, h);
      await tapKey(tester, 'jv2_mood_bem');
      await tapKey(tester, 'jv2_branch_futuro.animo');
      await tapKey(tester, 'jv2_option_futuro.animo.planos');
      await tapKey(tester, 'jv2_save');

      expect(find.textContaining('pending=true'), findsOneWidget);
      final queued = await h.local.pendingEntries();
      expect(queued.single.items.single.kind, 'positive');
      expect(queued.single.items.single.optionKey, 'futuro.animo.planos');
      h.online = true;
      expect(await h.repository.syncPending(), 1);
      expect(h.remote.requestBodies.single['items'],
          [{'kind': 'positive', 'optionKey': 'futuro.animo.planos'}]);
    });
  });

  group('v2.3', () {
    testWidgets('barriga and pelve are separate parts of the map, for everyone',
        (tester) async {
      final h = JournalHarness();
      await pumpJournalFlow(tester, h, args: physical);
      await startNotSoGood(tester);

      // No region chips under the map any more.
      expect(find.byType(FilterChip), findsNothing);
      await tapKey(tester, 'jv2_region_barriga');
      expect(isMarked(tester, 'barriga'), isTrue);
      expect(isMarked(tester, 'pelve'), isFalse);
      await tapKey(tester, 'jv2_region_pelve');
      expect(isMarked(tester, 'pelve'), isTrue);
      await tapKey(tester, 'jv2_region_barriga');
      expect(isMarked(tester, 'barriga'), isFalse);
      // Pelvis is front only.
      await tapKey(tester, 'jv2_side_back');
      expect(find.byKey(const Key('jv2_region_pelve')), findsNothing);
      await tapKey(tester, 'jv2_side_front');
      await tapKey(tester, 'jv2_continue');

      expect(find.text('${pt.jv23RegionPelve} · ${pt.jv2BodyFront}'), findsOneWidget);
      for (final b in ['xixi_intima', 'baixo_ventre']) {
        expect(find.byKey(Key('jv2_branch_pelve.$b')), findsOneWidget);
      }
      expect(find.byKey(const Key('jv2_branch_pelve.urina')), findsNothing);
      expect(find.byKey(const Key('jv2_branch_pelve.intima')), findsNothing);
      expect(find.text('Xixi ou região íntima'), findsOneWidget);
      await tapKey(tester, 'jv2_branch_pelve.xixi_intima');
      expect(find.text(pt.jv23OptPelveUrinaArdencia), findsOneWidget);
      for (final o in ['ardencia', 'vontade', 'coceira', 'inchaco']) {
        expect(find.byKey(Key('jv2_option_pelve.xixi_intima.$o')), findsOneWidget);
      }
      // D12: the two unrequested urinary options are gone.
      expect(find.text(pt.jv23OptPelveUrinaDificuldade), findsNothing);
      expect(find.text(pt.jv23OptPelveUrinaCorOdor), findsNothing);
      await tapKey(tester, 'jv2_option_pelve.xixi_intima.ardencia');
      await tapKey(tester, 'jv2_continue');
      await fillIntensity(tester, 1, 2);
      await tapKey(tester, 'jv2_continue');
      await tapKey(tester, 'jv2_skip');
      await tapKey(tester, 'jv22_closing_skip');
      await tapKey(tester, 'jv2_save');

      final item = (h.remote.requestBodies.single['items'] as List).single as Map;
      expect(item['optionKey'], 'pelve.xixi_intima.ardencia');
      expect(item['bodySide'], 'front');
      expect(item.containsKey('sensation'), isFalse);
    });

    testWidgets('triggers: tabs keep their answers, Não sei goes alone', (tester) async {
      final h = JournalHarness();
      await pumpJournalFlow(tester, h);
      await startNotSoGood(tester);
      await pickFeeling(tester, 'futuro', 'mente');
      await tapKey(tester, 'jv2_option_futuro.mente.indecisao');
      await tapKey(tester, 'jv2_continue');
      await fillIntensity(tester, 1, 2);
      await tapKey(tester, 'jv2_continue');

      expect(find.text(pt.jv23TriggerTopicDia), findsOneWidget);
      expect(find.byKey(const Key('jv2_trigger_trabalho')), findsOneWidget);
      expect(find.byKey(const Key('jv2_trigger_familia')), findsNothing);
      await tapKey(tester, 'jv2_trigger_trabalho');
      await tapKey(tester, 'jv2_topic_pessoas');
      expect(find.byKey(const Key('jv2_trigger_trabalho')), findsNothing);
      await tapKey(tester, 'jv2_trigger_familia');
      // Back on the first tab, its answer is still marked.
      await tapKey(tester, 'jv2_topic_dia');
      expect(isCardSelected(tester, 'jv2_trigger_trabalho'), isTrue);

      await tapKey(tester, 'jv2_trigger_nao_sei');
      expect(isCardSelected(tester, 'jv2_trigger_trabalho'), isFalse);
      await tapKey(tester, 'jv2_trigger_sono');
      await tapKey(tester, 'jv2_trigger_nao_sei');
      await tapKey(tester, 'jv2_continue');
      await tapKey(tester, 'jv22_closing_skip');
      await tapKey(tester, 'jv2_save');

      expect(h.remote.requestBodies.single['triggers'], ['nao_sei']);
    });
  });

  group('Phase 16 readings', () {
    const bp = UserCondition(
      id: 'c1',
      label: 'Hipertensão',
      tracking: [JournalKeys.trackingBloodPressure],
    );
    const weight = UserCondition(
      id: 'c2',
      label: 'Peso',
      tracking: [JournalKeys.trackingWeight],
    );

    testWidgets('Premium: Bem with a tracked condition opens the readings list; '
        '"Só registrar medições" saves them', (tester) async {
      final h = JournalHarness(conditions: const [bp])..premium = true;
      await pumpJournalFlow(tester, h, args: physical);
      await tapKey(tester, 'jv2_mood_bem');

      expect(h.remote.requestBodies, isEmpty);
      expect(find.byKey(const Key('chronicTrack_bem_banner')), findsOneWidget);
      expect(find.text(pt.chronicTrackBemBanner), findsOneWidget);
      expect(find.byType(BodyRegionMap), findsNothing);
      final justLog = find.descendant(
        of: find.byKey(const Key('chronicTrack_just_log')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(justLog).onPressed, isNull);

      // The card starts open.
      await tester.enterText(find.byKey(const Key('chronicTrack_c1_0_systolic')), '120');
      await tester.enterText(find.byKey(const Key('chronicTrack_c1_0_diastolic')), '80');
      await tester.pumpAndSettle();
      expect(find.text(pt.chronicTrackReadingsCount(1)), findsOneWidget);
      await tapKey(tester, 'chronicTrack_just_log');

      expect(find.textContaining('SUMMARY items=1'), findsOneWidget);
      final body = h.remote.requestBodies.single;
      expect(body['mood'], 'bem');
      expect(body['area'], 'physical');
      expect(body['triggers'], isEmpty);
      final item = (body['items'] as List).single as Map<String, dynamic>;
      expect(item['kind'], 'condition');
      expect(item['conditionId'], 'c1');
      expect(item.containsKey('intensity'), isFalse);
      final reading = (item['readings'] as List).single as Map<String, dynamic>;
      expect(reading['kind'], JournalKeys.trackingBloodPressure);
      expect(reading['systolic'], 120);
      expect(reading['diastolic'], 80);
      expect(reading['measuredAt'], isA<String>());
      expect(body.toString(), isNot(contains('Hipertensão')));

    });

    testWidgets('Premium: "Salvar sem medições" saves Bem with no items', (tester) async {
      final h = JournalHarness(conditions: const [bp])..premium = true;
      await pumpJournalFlow(tester, h, args: physical);
      await tapKey(tester, 'jv2_mood_bem');
      await tester.enterText(find.byKey(const Key('chronicTrack_c1_0_systolic')), '120');
      await tester.enterText(find.byKey(const Key('chronicTrack_c1_0_diastolic')), '80');
      await tester.pumpAndSettle();
      await tapKey(tester, 'chronicTrack_save_without');

      final body = h.remote.requestBodies.single;
      expect(body['mood'], 'bem');
      expect(body['items'], isEmpty);
    });

    testWidgets('Premium: Bem without tracked conditions still saves at once', (tester) async {
      final h = JournalHarness(conditions: const [UserCondition(id: 'c9', label: 'Asma')])
        ..premium = true;
      await pumpJournalFlow(tester, h, args: physical);
      await tapKey(tester, 'jv2_mood_bem');
      expect(h.remote.requestBodies.single['items'], isEmpty);
    });

    testWidgets('Free: Bem saves at once even with a tracked condition', (tester) async {
      final h = JournalHarness(conditions: const [bp]);
      await pumpJournalFlow(tester, h, args: physical);
      await tapKey(tester, 'jv2_mood_bem');
      expect(h.remote.requestBodies.single['items'], isEmpty);
    });

    testWidgets('Free: a tracked condition uses the 1-5 card', (tester) async {
      final h2 = JournalHarness(conditions: const [bp]);
      await pumpJournalFlow(tester, h2, args: physical);
      await startNotSoGood(tester);
      await tapKey(tester, 'jv2_condition_c1');
      expect(find.byKey(const Key('chronicTrack_c1_card')), findsNothing);
      await tapKey(tester, 'jv2_continue');
      expect(find.text(pt.jv2ConditionCardQuestion('Hipertensão')), findsOneWidget);
    });

    testWidgets('Premium: Não tão bem, a tracked condition opens its card; readings skip '
        'the 1-5 step and an untracked one keeps it', (tester) async {
      final h = JournalHarness(conditions: const [
        weight,
        UserCondition(id: 'c3', label: 'Enxaqueca'),
      ])..premium = true;
      await pumpJournalFlow(tester, h, args: physical);
      await startNotSoGood(tester);

      expect(find.byKey(const Key('chronicTrack_c2_card')), findsNothing);
      expect(find.text(pt.chronicTrackTapToLog), findsOneWidget);
      await tapKey(tester, 'jv2_condition_c2');
      expect(find.byKey(const Key('chronicTrack_c2_card')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('chronicTrack_c2_0_kg')), '72,5');
      await tester.pumpAndSettle();
      await tapKey(tester, 'jv2_condition_c3');
      await tapKey(tester, 'jv2_continue');

      // Only the untracked condition is asked for 1-5.
      expect(find.text(pt.jv2ConditionCardQuestion('Enxaqueca')), findsOneWidget);
      expect(find.text(pt.jv2ConditionCardQuestion('Peso')), findsNothing);
      await tapKey(tester, 'jv2_intensity_0_3');
      await tapKey(tester, 'jv2_continue');
      await tapKey(tester, 'jv2_skip');
      await tapKey(tester, 'jv22_closing_skip');
      await tapKey(tester, 'jv2_save');

      final items = (h.remote.requestBodies.single['items'] as List).cast<Map<String, dynamic>>();
      final tracked = items.firstWhere((i) => i['conditionId'] == 'c2');
      expect(tracked.containsKey('intensity'), isFalse);
      expect((tracked['readings'] as List).single['kg'], 72.5);
      final plain = items.firstWhere((i) => i['conditionId'] == 'c3');
      expect(plain['intensity'], 3);
      expect(plain.containsKey('readings'), isFalse);
    });

    testWidgets('Premium: readings only go straight past the 1-5 step', (tester) async {
      final h = JournalHarness(conditions: const [weight])..premium = true;
      await pumpJournalFlow(tester, h, args: physical);
      await startNotSoGood(tester);
      await tapKey(tester, 'jv2_condition_c2');
      await tester.enterText(find.byKey(const Key('chronicTrack_c2_0_kg')), '80');
      await tester.pumpAndSettle();
      await tapKey(tester, 'jv2_continue');
      expect(find.text(pt.jv2TriggersQuestion), findsOneWidget);
    });
  });


  group('Gender filtering and contextual closing', () {
    testWidgets('Male profile does not see menstrual options or ciclo trigger, and physical closing shows physical helpers', (tester) async {
      final h = JournalHarness();
      await pumpJournalFlow(
        tester,
        h,
        args: physical,
        extraOverrides: [
          activeProfileControllerProvider.overrideWith(_MaleActiveProfileNotifier.new),
        ],
      );
      await startNotSoGood(tester);

      await tapKey(tester, 'jv2_region_barriga');
      await tapKey(tester, 'jv2_region_pelve');
      await tapKey(tester, 'jv2_continue');

      // Region 1: barriga
      await tapKey(tester, 'jv2_branch_barriga.colica');
      expect(find.byKey(const Key('jv2_option_barriga.colica.menstrual')), findsNothing);
      expect(find.byKey(const Key('jv2_option_barriga.colica.gases')), findsOneWidget);
      await tapKey(tester, 'jv2_option_barriga.colica.gases');
      await tapKey(tester, 'jv2_continue');

      // Region 2: pelve. Menstrual is hidden under baixo ventre too.
      await tapKey(tester, 'jv2_branch_pelve.baixo_ventre');
      expect(find.byKey(const Key('jv2_option_pelve.baixo_ventre.menstrual')), findsNothing);
      await tapKey(tester, 'jv2_option_pelve.baixo_ventre.peso');
      await tapKey(tester, 'jv2_continue');

      // Intensity
      await fillIntensity(tester, 2, 3);
      await tapKey(tester, 'jv2_continue');

      // Triggers: ciclo is NOT offered
      expect(find.byKey(const Key('jv2_trigger_ciclo')), findsNothing);
      await tapKey(tester, 'jv2_skip');

      // Closing: physical helpers
      expect(find.byKey(const Key('jv22_helper_beber_agua')), findsOneWidget);
      expect(find.byKey(const Key('jv22_helper_remedio')), findsOneWidget);
      expect(find.byKey(const Key('jv22_helper_repouso')), findsOneWidget);
      expect(find.byKey(const Key('jv22_helper_mexer_corpo')), findsNothing);
      expect(find.byKey(const Key('jv22_helper_conversar')), findsNothing);

      await tapKey(tester, 'jv22_helper_beber_agua');
      await tapKey(tester, 'jv22_coping_consegui');
      await tapKey(tester, 'jv2_continue');
      await tapKey(tester, 'jv2_save');

      final body = h.remote.requestBodies.single;
      expect(body['coping'], 'consegui');
      expect(body['helpers'], ['beber_agua']);
    });

    testWidgets('Emotional check-in closing shows emotional helpers and not physical helpers', (tester) async {
      final h = JournalHarness();
      await pumpJournalFlow(tester, h);
      await startNotSoGood(tester);
      await pickFeeling(tester, 'passado', 'tristeza');
      await tapKey(tester, 'jv2_option_passado.tristeza.culpa');
      await tapKey(tester, 'jv2_continue');
      await fillIntensity(tester, 1, 2);
      await tapKey(tester, 'jv2_continue');
      await tapKey(tester, 'jv2_skip');

      expect(find.byKey(const Key('jv22_helper_mexer_corpo')), findsOneWidget);
      expect(find.byKey(const Key('jv22_helper_conversar')), findsOneWidget);
      expect(find.byKey(const Key('jv22_helper_beber_agua')), findsNothing);
      expect(find.byKey(const Key('jv22_helper_remedio')), findsNothing);
    });
  });
}

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
      );
}

/// Ana is signed in with Carlos's profile, shared by Carlos, active.
class _SharedByOther extends ActiveProfileController {
  @override
  ActiveProfileState build() => ActiveProfileState(
        profiles: [
          const Profile(
            id: 'p1',
            name: 'Ana',
            profileType: ProfileType.primary,
            ownership: ProfileOwnership.own,
            accessLevel: ProfileAccessLevel.owner,
          ),
          Profile.fromJson(const {
            'id': 'shared-1',
            'name': 'Carlos',
            'profileType': 'primary',
            'ownership': 'shared',
            'accessLevel': 'CO_MANAGE',
            'readableCategories': ['journal'],
            'writableCategories': ['journal'],
          }),
        ],
        activeProfileId: 'shared-1',
      );
}
