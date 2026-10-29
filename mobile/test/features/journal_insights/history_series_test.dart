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

  test('entriesInPeriod keeps only the last N calendar days', () {
    final entries = [e(0, const []), e(6, const []), e(7, const [])];
    expect(entriesInPeriod(entries, today: today, days: 7).length, 2);
    expect(entriesInPeriod(entries, today: today, days: 30).length, 3);
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
