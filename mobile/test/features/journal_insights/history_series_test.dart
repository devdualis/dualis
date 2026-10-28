import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/journal_insights/domain/history_series.dart';
import 'package:dualis_mobile/features/journal_insights/domain/journal_insights_models.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt'));
  final today = DateTime(2026, 10, 28, 9);

  JournalEntryView e(int daysAgo, List<JournalItemView> items) =>
      JournalEntryView(
        id: 'e$daysAgo-${items.length}',
        recordedAt: today.subtract(Duration(days: daysAgo)),
        items: items,
      );

  JournalItemView emo(String key, int intensity) =>
      JournalItemView(kind: 'emotional', optionKey: key, intensity: intensity);

  JournalItemView phy(String key, int intensity, {String? sensation}) =>
      JournalItemView(
        kind: 'physical',
        optionKey: key,
        intensity: intensity,
        sensation: sensation,
      );

  test('entriesInPeriod keeps only the last N calendar days', () {
    final entries = [e(0, const []), e(6, const []), e(7, const [])];
    expect(entriesInPeriod(entries, today: today, days: 7).length, 2);
    expect(entriesInPeriod(entries, today: today, days: 30).length, 3);
  });

  test('emotional lines group options by branch and keep the highest value',
      () {
    final lines = emotionalLines(
      l10n,
      [
        e(0, [emo('futuro.mente.antecipar', 2), emo('futuro.mente.cobranca', 4)]),
        e(1, [emo('passado.memoria.magoa', 3)]),
        e(2, [emo('futuro.mente.antecipar', 1)]),
        // Physical and condition items never reach the emotional tab.
        e(2, [phy('cabeca.pressao.temporas', 5)]),
        e(2, const [
          JournalItemView(kind: 'condition', conditionId: 'c1', intensity: 3),
        ]),
      ],
      today: today,
      days: 7,
    );
    expect(lines.map((l) => l.key), ['futuro.mente', 'passado.memoria']);
    expect(lines.first.label, 'Futuro · Mente acelerada');
    expect(lines.first.points, {6: 4, 4: 1});
  });

  test('physical lines split by sensation and tolerate missing fields', () {
    final lines = physicalLines(
      l10n,
      [
        e(0, [phy('cabeca.pressao.latejando', 4, sensation: 'dor')]),
        e(1, [phy('cabeca.pressao.temporas', 2)]),
        e(1, [phy('musculos.tensao.caibra', 3, sensation: 'incomodo')]),
        e(2, const [JournalItemView(kind: 'physical', legacyLabel: 'Dor antiga', intensity: 2)]),
        e(2, const [JournalItemView(kind: 'physical', optionKey: 'peito.respiracao.curta')]),
      ],
      today: today,
      days: 7,
    );
    final byKey = {for (final l in lines) l.key: l.label};
    expect(byKey['cabeca:dor'], 'Cabeça e pescoço · dor');
    expect(byKey['cabeca'], 'Cabeça e pescoço');
    expect(byKey['musculos:incomodo'], 'Músculos · incômodo');
    expect(byKey['legacy:dor antiga'], 'Dor antiga');
    // Items without intensity draw no line.
    expect(byKey.containsKey('peito'), isFalse);
  });

  test('timeRegionDays counts days with both a time and a region', () {
    final links = timeRegionDays([
      e(0, [phy('cabeca.pressao.temporas', 3)]),
      e(0, [emo('futuro.mente.antecipar', 2)]),
      e(1, [phy('cabeca.pressao.temporas', 3), emo('futuro.medo.desanimo', 2)]),
      e(1, [phy('pele.coceira.ardencia', 1, sensation: 'incomodo')]),
      e(2, [emo('passado.memoria.magoa', 2)]),
    ]);
    expect(links[('futuro', 'cabeca')], 2);
    expect(links[('futuro', 'pele')], 1);
    expect(links.containsKey(('passado', 'cabeca')), isFalse);
  });

  test('whole-body areas have lay labels', () {
    expect(historyRegions, containsAll(['pele', 'musculos', 'hormonios']));
    expect(historyRegionLabel(l10n, 'pele'), 'Pele');
    expect(historyRegionLabel(l10n, 'hormonios'), 'Hormônios e metabolismo');
    expect(historyMarkerLabel(l10n, 'musculos'), 'Músculos');
  });

  test('parses area and sensation from the API and tolerates their absence',
      () {
    final entry = JournalEntryView.fromJson({
      'id': 'x',
      'recordedAt': '2026-10-27T10:00:00.000Z',
      'area': 'physical',
      'items': [
        {'kind': 'physical', 'optionKey': 'cabeca.nuca.rigida', 'sensation': 'dor', 'intensity': 3},
      ],
    });
    expect(entry.area, 'physical');
    expect(entry.items.single.sensation, 'dor');

    final old = JournalEntryView.fromJson({
      'id': 'y',
      'recordedAt': '2026-10-27T10:00:00.000Z',
      'items': [
        {'kind': 'physical', 'optionKey': 'cabeca.pressao.temporas'},
      ],
    });
    expect(old.area, isNull);
    expect(old.items.single.sensation, isNull);
  });
}
