import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:dualis_mobile/features/journal/presentation/journal_labels.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/journal_flow_screen.dart';
import 'package:dualis_mobile/features/journal/presentation/widgets/body_region_map.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journal_test_helpers.dart';

void main() {
  final pt = AppLocalizationsPt();

  Future<void> startNotSoGood(WidgetTester tester) async {
    await tapKey(tester, 'jv2_mood_nao_tao_bem');
  }

  /// Persistence "hoje" + intensity [level] for every row on the screen.
  Future<void> fillIntensity(WidgetTester tester, int count, int level) async {
    for (var i = 0; i < count; i++) {
      await tapKey(tester, 'jv2_persistence_${i}_hoje');
      await tapKey(tester, 'jv2_intensity_${i}_$level');
    }
  }

  testWidgets('mood screen offers Bem, Normal and Não tão bem with emoji', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);

    expect(find.text(pt.jv2MoodQuestion), findsOneWidget);
    for (final mood in JournalKeys.moods) {
      expect(find.byKey(Key('jv2_mood_$mood')), findsOneWidget);
    }
    expect(find.text('😊'), findsOneWidget);
    expect(find.text('😕'), findsOneWidget);
  });

  testWidgets('Bem saves right away and opens the summary', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);

    await tapKey(tester, 'jv2_mood_bem');

    expect(find.textContaining('SUMMARY items=0 pending=false'), findsOneWidget);
    final body = h.remote.requestBodies.single;
    expect(body['mood'], 'bem');
    expect(body['items'], isEmpty);
    expect(body['triggers'], isEmpty);
    expect(body['clientId'], isNotEmpty);
  });

  testWidgets('emotional path: time, branch, multi-select, custom, triggers, note', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);

    await tapKey(tester, 'jv2_area_emotional');
    await tapKey(tester, 'jv2_continue');

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
    await tapKey(tester, 'jv2_area_emotional');
    await tapKey(tester, 'jv2_continue');
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

  testWidgets('physical path: several regions on both sides, per-region options', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(
      tester,
      h,
      args: const JournalFlowArgs(initialArea: JournalArea.physical),
    );
    await startNotSoGood(tester);
    // The Home shortcut pre-selected "Meu corpo".
    await tapKey(tester, 'jv2_continue');

    expect(find.text(pt.jv2BodyQuestion), findsOneWidget);
    expect(find.byKey(const Key('jv2_region_costas')), findsNothing);
    await tapKey(tester, 'jv2_region_cabeca');
    await tapKey(tester, 'jv2_side_back');
    await tapKey(tester, 'jv2_region_costas');
    await tapKey(tester, 'jv2_continue');

    // Region 1: cabeça (front).
    expect(find.text(pt.jv2RegionCabeca), findsWidgets);
    await tapKey(tester, 'jv2_branch_cabeca.pressao');
    await tapKey(tester, 'jv2_option_cabeca.pressao.temporas');
    await tapKey(tester, 'jv2_continue');
    // Region 2: costas (back).
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
    expect(body['triggers'], isEmpty);
    final items = (body['items'] as List).cast<Map<String, dynamic>>();
    expect(items.map((i) => [i['optionKey'], i['bodySide']]), [
      ['cabeca.pressao.temporas', 'front'],
      ['costas.rigidez.lombar', 'back'],
      ['costas.custom', 'back'],
    ]);
    expect(items.last['customLabel'], 'Peso no cóccix');
    expect(items.every((i) => i['kind'] == 'physical'), isTrue);
  });

  testWidgets('tapping the body map toggles the region', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await tapKey(tester, 'jv2_area_physical');
    await tapKey(tester, 'jv2_continue');

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

  testWidgets('a condition appears as a card and uses the full intensity screen', (tester) async {
    final h = JournalHarness(
      conditions: const [UserCondition(id: 'c1', label: 'Enxaqueca')],
    );
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);

    expect(find.text(pt.jv2ConditionCardQuestion('Enxaqueca')), findsOneWidget);
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
    await tapKey(tester, 'jv2_area_emotional');
    await tapKey(tester, 'jv2_continue');
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
    await tapKey(tester, 'jv2_area_emotional');
    await tapKey(tester, 'jv2_continue');
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
    h.remote.suggestedOptionKey = 'futuro.medo.desanimo';
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await tapKey(tester, 'jv2_area_emotional');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_time_futuro');
    await tapKey(tester, 'jv2_branch_futuro.mente');
    await tapKey(tester, 'jv2_write_mine');
    await tester.enterText(
      find.byKey(const Key('jv2_custom_field')),
      'estou muito chateado com a vida',
    );
    await tapKey(tester, 'jv2_custom_add');
    expect(find.byKey(const Key('jv2_suggest_dialog')), findsOneWidget);
    expect(find.textContaining(pt.jv2OptFuturoMedoDesanimo), findsOneWidget);
    await tapKey(tester, 'jv2_suggest_yes');
    expect(find.byKey(const Key('jv2_custom_chip_estou muito chateado com a vida')), findsNothing);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_more_no');
    await fillIntensity(tester, 1, 2);
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_skip');
    await tapKey(tester, 'jv2_save');
    final items = (h.remote.requestBodies.single['items'] as List)
        .cast<Map<String, dynamic>>();
    expect(items.single['optionKey'], 'futuro.medo.desanimo');
    expect(items.single['customLabel'], isNull);
  });

  testWidgets('back returns to the previous screen with its answers', (tester) async {
    final h = JournalHarness();
    await pumpJournalFlow(tester, h);
    await startNotSoGood(tester);
    await tapKey(tester, 'jv2_area_emotional');
    await tapKey(tester, 'jv2_continue');
    await tapKey(tester, 'jv2_back');

    expect(find.text(pt.jv2AreaQuestion), findsOneWidget);
    final tile = find.byKey(const Key('jv2_area_emotional'));
    expect(
      find.descendant(of: tile, matching: find.byIcon(Icons.check_circle_rounded)),
      findsOneWidget,
    );
  });
}
