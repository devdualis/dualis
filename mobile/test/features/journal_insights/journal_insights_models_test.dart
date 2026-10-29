import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/journal/presentation/journal_labels.dart';
import 'package:dualis_mobile/features/journal_insights/domain/journal_insights_models.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt'));

  JournalEntryView e(int day, List<JournalItemView> items,
          {List<String> triggers = const []}) =>
      JournalEntryView(
        id: 'e$day',
        recordedAt: DateTime(2026, 10, day, 12),
        items: items,
        triggers: triggers,
      );

  const head = JournalItemView(
      kind: 'physical', optionKey: 'cabeca.pressao.temporas', intensity: 3);
  const mind = JournalItemView(
      kind: 'emotional', optionKey: 'futuro.mente.antecipar', intensity: 4);

  test('parses entries, legacy rows and condition labels', () {
    final entry = JournalEntryView.fromJson({
      'id': 'x',
      'recordedAt': '2026-10-20T10:00:00.000Z',
      'mood': 'nao_tao_bem',
      'triggers': ['sono'],
      'items': [
        {'kind': 'condition', 'conditionId': 'c1', 'label': 'Enxaqueca', 'intensity': 2},
        {'kind': 'physical', 'optionKey': 'costas.custom', 'customLabel': 'Ombro travado', 'intensity': 4},
      ],
    });
    expect(entry.items[0].label(l10n), 'Enxaqueca');
    expect(entry.items[1].label(l10n), 'Ombro travado');
    expect(entry.items[1].region, 'costas');

    final legacy = JournalEntryView.fromJson({
      'id': 'l',
      'recordedAt': '2026-10-01T10:00:00.000Z',
      'legacy': true,
      'items': [
        {'kind': 'emotional', 'legacyLabel': 'Cansaço', 'intensity': 3},
      ],
    });
    expect(legacy.legacy, isTrue);
    expect(legacy.items.single.label(l10n), 'Cansaço');
  });

  test('local summary counts days per time, region and trigger', () {
    final summary = JournalSummary.compute([
      e(1, [head, mind], triggers: ['sono']),
      e(2, [head]),
      e(2, [mind]),
      e(3, [mind]),
    ]);
    expect(summary.byTime, {'futuro': 3});
    expect(summary.byRegion, {'cabeca': 2});
    expect(summary.byTrigger, {'sono': 1});
    final pair = summary.cooccurrence.firstWhere(
        (c) => {c.a, c.b}.containsAll(['cabeca', 'futuro.mente']));
    expect(pair.days, 2);
  });

  test('same local day counts once even with two entries', () {
    final summary = JournalSummary.compute([
      e(1, [head], triggers: ['sono']),
      e(1, [head, mind], triggers: ['sono']),
    ]);
    expect(summary.byRegion, {'cabeca': 1});
    expect(summary.byTime, {'futuro': 1});
    expect(summary.byTrigger, {'sono': 1});
  });

  test('local fallback emits the same markers as the server', () {
    final entry = e(1, [head, mind], triggers: ['sono']);
    expect(entry.markers, {'cabeca', 'futuro.mente', 'trigger:sono'});
    final written = e(1, [
      const JournalItemView(
          kind: 'emotional', optionKey: 'futuro.custom', customLabel: 'X'),
    ]);
    expect(written.markers, {'futuro'});
  });

  test('client resolves branch, bare region/time and trigger: markers', () {
    expect(JournalLabels.marker(l10n, 'futuro.mente'), 'Mente acelerada');
    expect(JournalLabels.marker(l10n, 'cabeca'), 'Cabeça e pescoço');
    expect(JournalLabels.marker(l10n, 'futuro'), 'O que vem pela frente');
    expect(JournalLabels.marker(l10n, 'trigger:sono'), 'Noite mal dormida');
  });
}
