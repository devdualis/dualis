import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:dualis_mobile/features/journal/presentation/journal_labels.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/journal_flow_screen.dart';
import 'package:dualis_mobile/features/journal/presentation/widgets/body_region_map.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Persistence "hoje" + intensity [level] for every row on the screen.
  Future<void> fillIntensity(WidgetTester tester, int count, int level) async {
    for (var i = 0; i < count; i++) {
      await tapKey(tester, 'jv2_persistence_${i}_hoje');
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
    // Icons, no emoji.
    expect(find.text('😊'), findsNothing);
    expect(find.text('😕'), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.sentiment_dissatisfied_rounded), findsOneWidget);
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

  testWidgets('Bem saves right away and opens the summary', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);

    await tapKey(tester, 'jv2_mood_bem');

    expect(find.textContaining('SUMMARY items=0 pending=false'), findsOneWidget);
    final body = h.remote.requestBodies.single;
    expect(body['mood'], 'bem');
    expect(body['area'], 'emotional');
    expect(body['items'], isEmpty);
    expect(body['triggers'], isEmpty);
    expect(body['clientId'], isNotEmpty);
    // Only the emotional axis is done on Home.
    final home = containerOf(tester).read(triggerCheckInProvider);
    expect(home.isEmotionalCompleted, isTrue);
    expect(home.isPhysicalCompleted, isFalse);
  });

  testWidgets('Bem from the physical card completes only the physical axis', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h, args: physical);

    await tapKey(tester, 'jv2_mood_bem');

    expect(h.remote.requestBodies.single['area'], 'physical');
    final home = containerOf(tester).read(triggerCheckInProvider);
    expect(home.isPhysicalCompleted, isTrue);
    expect(home.isEmotionalCompleted, isFalse);
  });

  testWidgets('emotional path: time, branch, multi-select, custom, triggers, note', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);

    // Straight to the time question: no "what to record" screen.
    expect(find.text(pt.jv2TimeQuestion), findsOneWidget);
    await tapKey(tester, 'jv2_time_futuro');
    expect(find.text(pt.jv2BranchFuturoMente), findsOneWidget);
    await tapKey(tester, 'jv2_branch_futuro.mente');

    await tapKey(tester, 'jv2_option_futuro.mente.antecipar');
    await tapKey(tester, 'jv2_option_futuro.mente.cobranca');
    await tapKey(tester, 'jv2_write_mine');
    await tester.enterText(find.byKey(const Key('jv2_custom_field')), 'Cansaço do trânsito');
    await tapKey(tester, 'jv2_custom_add');
    expect(find.byKey(const Key('jv2_custom_chip_Cansaço do trânsito')), findsOneWidget);
    await tapKey(tester, 'jv2_continue');

    expect(find.text(pt.jv2MoreQuestion), findsOneWidget);
    await tapKey(tester, 'jv2_more_no');

    // Compact screen: one row per item.
    expect(find.text(pt.jv2IntensityCompactQuestion), findsOneWidget);
    expect(find.byKey(const Key('jv2_item_row_2')), findsOneWidget);
    final cont = find.byKey(const Key('jv2_continue'));
    expect(tester.widget<FilledButton>(cont).onPressed, isNull);
    await fillIntensity(tester, 3, 3);
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

    await tester.enterText(find.byKey(const Key('jv2_note_field')), 'Dia corrido');
    await tester.pumpAndSettle();
    await tapKey(tester, 'jv2_save');

    expect(find.textContaining('SUMMARY items=3'), findsOneWidget);
    final body = h.remote.requestBodies.single;
    expect(body['mood'], 'nao_tao_bem');
    expect(body['area'], 'emotional');
    expect(body['triggers'], ['trabalho', 'outro']);
    expect(body['triggerNote'], 'Reunião longa');
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

  testWidgets('"Quer registrar mais alguma coisa?" goes back to the time screen', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await tapKey(tester, 'jv2_time_passado');
    await tapKey(tester, 'jv2_branch_passado.tristeza');
    await tapKey(tester, 'jv2_option_passado.tristeza.saudade');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_more_yes');

    expect(find.text(pt.jv2TimeQuestion), findsOneWidget);
    await tapKey(tester, 'jv2_time_presente');
    await tapKey(tester, 'jv2_branch_presente.energia');
    await tapKey(tester, 'jv2_option_presente.energia.corpo');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_more_no');

    expect(find.byKey(const Key('jv2_item_row_1')), findsOneWidget);
  });

  testWidgets('physical path: regions on both sides, sensation, per-region options', (tester) async {
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

    // Region 1: cabeça (front). Sensation first, branches wait for it.
    expect(find.text(pt.jv2SensationQuestion), findsOneWidget);
    expect(find.text('${pt.jv2RegionCabeca} · ${pt.jv2BodyFront}'), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_cabeca.sentidos')), findsOneWidget);
    expect(find.byKey(const Key('jv2_branch_cabeca.nuca')), findsNothing);
    await tapKey(tester, 'jv2_branch_cabeca.pressao');
    expect(find.text(pt.jv2SensationQuestion), findsOneWidget);
    await tapKey(tester, 'jv2_sensation_dor');
    await tapKey(tester, 'jv2_branch_cabeca.pressao');
    await tapKey(tester, 'jv2_option_cabeca.pressao.temporas');
    await tapKey(tester, 'jv2_continue');
    // Region 2: costas (back). Sensation is asked again.
    final branch = find.byKey(const Key('jv2_branch_costas.rigidez'));
    await tapKey(tester, 'jv2_branch_costas.rigidez');
    expect(branch, findsOneWidget);
    await tapKey(tester, 'jv2_sensation_incomodo');
    await tapKey(tester, 'jv2_branch_costas.rigidez');
    await tapKey(tester, 'jv2_option_costas.rigidez.lombar');
    await tapKey(tester, 'jv2_write_mine');
    await tester.enterText(find.byKey(const Key('jv2_custom_field')), 'Peso no cóccix');
    await tapKey(tester, 'jv2_custom_add');
    await tapKey(tester, 'jv2_continue');

    expect(find.text(pt.jv2MoreBodyQuestion), findsOneWidget);
    await tapKey(tester, 'jv2_more_no');

    expect(find.textContaining(pt.jv2RegionCostas), findsWidgets);
    await fillIntensity(tester, 3, 2);
    await tapKey(tester, 'jv2_continue');

    // Physical item present: every trigger is offered. Skip clears choices.
    for (final t in JournalKeys.triggers) {
      expect(find.byKey(Key('jv2_trigger_$t')), findsOneWidget);
    }
    await tapKey(tester, 'jv2_trigger_esforco');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv2_save');

    final body = h.remote.requestBodies.single;
    expect(body['area'], 'physical');
    expect(body['triggers'], isEmpty);
    final items = (body['items'] as List).cast<Map<String, dynamic>>();
    expect(items.map((i) => [i['optionKey'], i['bodySide'], i['sensation']]), [
      ['cabeca.pressao.temporas', 'front', 'dor'],
      ['costas.rigidez.lombar', 'back', 'incomodo'],
      ['costas.custom', 'back', 'incomodo'],
    ]);
    expect(items.last['customLabel'], 'Peso no cóccix');
    expect(items.every((i) => i['kind'] == 'physical'), isTrue);
    final home = containerOf(tester).read(triggerCheckInProvider);
    expect(home.isPhysicalCompleted, isTrue);
    expect(home.isEmotionalCompleted, isFalse);
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
    await tapKey(tester, 'jv2_sensation_dor');
    await tapKey(tester, 'jv2_branch_cabeca.nuca');
    expect(find.text(pt.jv2OptCabecaNucaRigida), findsOneWidget);
    expect(find.text(pt.jv2OptCabecaNucaPontada), findsOneWidget);
    await tapKey(tester, 'jv2_option_cabeca.nuca.rigida');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_more_no');
    await fillIntensity(tester, 1, 2);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv2_save');

    final item = (h.remote.requestBodies.single['items'] as List).single as Map;
    expect(item['optionKey'], 'cabeca.nuca.rigida');
    expect(item['bodySide'], 'back');
    expect(item['sensation'], 'dor');
  });

  testWidgets('whole-body areas are recorded without a side', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h, args: physical);
    await startNotSoGood(tester);

    expect(find.text(pt.jv2WholeBody), findsOneWidget);
    for (final area in JournalKeys.wholeBodyAreas) {
      expect(find.byKey(Key('jv2_region_$area')), findsOneWidget);
    }
    await tapKey(tester, 'jv2_region_hormonios');
    await tapKey(tester, 'jv2_continue');

    expect(find.text(pt.jv2RegionHormonios), findsWidgets);
    await tapKey(tester, 'jv2_sensation_incomodo');
    await tapKey(tester, 'jv2_branch_hormonios.temperatura');
    await tapKey(tester, 'jv2_option_hormonios.temperatura.calorao');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_more_no');
    await fillIntensity(tester, 1, 3);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv2_save');

    final item = (h.remote.requestBodies.single['items'] as List).single as Map;
    expect(item['optionKey'], 'hormonios.temperatura.calorao');
    expect(item.containsKey('bodySide'), isFalse);
    expect(item['sensation'], 'incomodo');
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

    final chip = tester.widget<FilterChip>(find.byKey(const Key('jv2_region_cabeca')));
    expect(chip.selected, isTrue);
  });

  testWidgets('a condition is a chip on the body screen and uses the full intensity screen',
      (tester) async {
    final h = JournalHarness(
      conditions: const [UserCondition(id: 'c1', label: 'Enxaqueca')],
    );
    await pumpJournalFlow(tester, h, args: physical);
    await startNotSoGood(tester);

    expect(find.text(pt.jv2AreaConditions), findsOneWidget);
    expect(find.byKey(const Key('jv2_condition_add')), findsOneWidget);
    expect(
      tester.widget<FilterChip>(find.byKey(const Key('jv2_condition_c1'))).label,
      isA<Text>().having((t) => t.data, 'data', 'Enxaqueca'),
    );
    final cont = find.byKey(const Key('jv2_continue'));
    expect(tester.widget<FilledButton>(cont).onPressed, isNull);
    await tapKey(tester, 'jv2_condition_c1');
    await tapKey(tester, 'jv2_continue');

    // Single item: full §8 scale with every level described.
    expect(find.text(pt.jv2ConditionCardQuestion('Enxaqueca')), findsOneWidget);
    expect(find.text(pt.jv2IntensityEmotional5), findsOneWidget);
    expect(find.text(pt.jv2PersistenceOptional), findsOneWidget);
    await tapKey(tester, 'jv2_intensity_0_4');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv2_save');

    final body = h.remote.requestBodies.single;
    final item = (body['items'] as List).single as Map<String, dynamic>;
    expect(item, {'kind': 'condition', 'conditionId': 'c1', 'intensity': 4});
    // The condition name never leaves in the request body.
    expect(body.toString(), isNot(contains('Enxaqueca')));
  });

  testWidgets('offline save goes to the outbox and syncs once online', (tester) async {
    final h = JournalHarness(online: false);
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await tapKey(tester, 'jv2_time_presente');
    await tapKey(tester, 'jv2_branch_presente.sobrecarga');
    await tapKey(tester, 'jv2_option_presente.sobrecarga.paciencia');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_more_no');
    await fillIntensity(tester, 1, 3);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
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
    await tapKey(tester, 'jv2_time_presente');
    await tapKey(tester, 'jv2_branch_presente.sobrecarga');
    await tapKey(tester, 'jv2_option_presente.sobrecarga.aperto');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_more_no');

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
    await tapKey(tester, 'jv2_time_futuro');
    await tapKey(tester, 'jv2_branch_futuro.mente');
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
    await tapKey(tester, 'jv2_more_no');
    await fillIntensity(tester, 1, 2);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv2_save');
    final items = (h.remote.requestBodies.single['items'] as List)
        .cast<Map<String, dynamic>>();
    expect(items.single['optionKey'], 'futuro.mente.antecipar');
    expect(items.single['customLabel'], isNull);
  });

  testWidgets('back returns to the previous screen with its answers', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h, args: physical);
    await startNotSoGood(tester);
    await tapKey(tester, 'jv2_region_cabeca');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_back');

    expect(find.text(pt.jv2BodyQuestion), findsOneWidget);
    final chip = tester.widget<FilterChip>(find.byKey(const Key('jv2_region_cabeca')));
    expect(chip.selected, isTrue);
    await tapKey(tester, 'jv2_back');
    expect(find.text(pt.jv2MoodQuestion), findsOneWidget);
  });
}
