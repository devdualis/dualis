import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_controller.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journal_test_helpers.dart';

/// "Descrever com minhas palavras" (phase 17, D3): a free description gives
/// existing options, every one OFF, and only the ones the person turns on
/// reach the entry.
void main() {
  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  JournalFlowState flowState(WidgetTester tester) =>
      containerOf(tester).read(journalFlowControllerProvider);

  bool switchOn(WidgetTester tester, String key) => tester
      .widget<SwitchListTile>(find.byKey(Key('jv2_describe_option_$key')))
      .value;

  bool enabled(WidgetTester tester, String key) =>
      tester.widget<FilledButton>(find.byKey(Key(key))).onPressed != null;

  group('emotional describe flow', () {
    testWidgets(
        'describe -> review with every option OFF -> turn one on -> '
        '"Usar as selecionadas" -> persistence; Back returns to the time step',
        (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const [
        'presente.sobrecarga.aperto',
        'futuro.mente.antecipar',
      ];
      await pumpJournalFlow(tester, h);
      await tapKey(tester, 'jv2_mood_nao_tao_bem');

      expect(find.byKey(const Key('jv2_describe')), findsOneWidget);
      await tapKey(tester, 'jv2_describe');
      expect(find.byKey(const Key('jv2_describe_field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('jv2_describe_field')),
        'Estou com o peito apertado pensando na semana',
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'jv2_describe_suggest');

      expect(find.byKey(const Key('jv2_describe_review')), findsOneWidget);
      expect(switchOn(tester, 'presente.sobrecarga.aperto'), isFalse);
      expect(switchOn(tester, 'futuro.mente.antecipar'), isFalse);
      expect(enabled(tester, 'jv2_describe_use'), isFalse);

      await tapKey(tester, 'jv2_describe_option_presente.sobrecarga.aperto');
      expect(switchOn(tester, 'presente.sobrecarga.aperto'), isTrue);
      expect(enabled(tester, 'jv2_describe_use'), isTrue);
      await tapKey(tester, 'jv2_describe_use');

      expect(find.byKey(const Key('jv2_describe_sheet')), findsNothing);
      final state = flowState(tester);
      expect(state.step, JournalStep.persistence);
      expect(state.items, hasLength(1));
      expect(state.items.single.kind, JournalKeys.kindEmotional);
      expect(state.items.single.optionKey, 'presente.sobrecarga.aperto');
      expect(find.byKey(const Key('jv2_persistence_0_hoje')), findsOneWidget);

      expect(h.remote.suggestEntryRequests, [
        {
          'text': 'Estou com o peito apertado pensando na semana',
          'area': 'emotional',
        },
      ]);
      // The description is not the note unless the person asked.
      expect(state.note, isEmpty);

      await tapKey(tester, 'jv2_back');
      expect(flowState(tester).step, JournalStep.time);
      expect(flowState(tester).items, isEmpty);
      expect(find.byKey(const Key('jv2_describe')), findsOneWidget);
    });
  });
}
