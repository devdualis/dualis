import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../widgets/care_widgets.dart';

/// Confirmed values of one item over time, as a table. No chart with bands:
/// each lab prints its own reference and the app does not compare them.
class ExamItemScreen extends ConsumerStatefulWidget {
  const ExamItemScreen({super.key, required this.item});
  final String item;

  @override
  ConsumerState<ExamItemScreen> createState() => _ExamItemScreenState();
}

class _ExamItemScreenState extends ConsumerState<ExamItemScreen> {
  /// Unit shown when the item has results in several units (e.g. % and /mm³).
  String? _unit;

  String get item => widget.item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(careDocumentsProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: careAppBar(context, item),
      body: CareAsync<List<CareDocument>>(
        value: async,
        onRetry: () => ref.invalidate(careDocumentsProvider),
        data: (docs) {
          final rows = [
            for (final d in docs.where((d) => d.kind == DocumentKind.lab && d.status == DocumentStatus.ready))
              for (final v in d.values.where((v) => v.item.toLowerCase() == item.toLowerCase()))
                (d.collectedOn ?? isoDay(d.createdAt), v, d.labName),
          ]..sort((a, b) => b.$1.compareTo(a.$1));
          // One chip per unit; values in different units are never listed together.
          final units = <String, String>{for (final r in rows) examUnitKey(r.$2.unit): r.$2.unit ?? '—'};
          final unit = units.containsKey(_unit) ? _unit! : (rows.isEmpty ? '' : examUnitKey(rows.first.$2.unit));
          final shown = units.length > 1 ? rows.where((r) => examUnitKey(r.$2.unit) == unit).toList() : rows;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(l10n.careExamItemIntro, style: careBody()),
              const SizedBox(height: 12),
              if (units.length > 1) ...[
                Wrap(spacing: 8, children: [
                  for (final MapEntry(:key, :value) in units.entries)
                    ChoiceChip(
                      key: Key('exam_unit_$key'),
                      label: Text(value),
                      selected: key == unit,
                      onSelected: (_) => setState(() => _unit = key),
                    ),
                ]),
                const SizedBox(height: 12),
              ],
              CareCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Table(
                  columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(3), 2: FlexColumnWidth(3), 3: FlexColumnWidth(3)},
                  children: [
                    TableRow(children: [
                      for (final h in [l10n.careExamDate, l10n.careExamValue, l10n.careExamReferencePrinted, l10n.careExamLab])
                        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(h, style: careBody(11))),
                    ]),
                    for (final (date, v, lab) in shown)
                      TableRow(children: [
                        _cell(careDate(context, careDay(date)!)),
                        _cell([v.value, v.unit].whereType<String>().join(' '), bold: true),
                        _cell(v.reference ?? '—'),
                        _cell(lab ?? '—'),
                      ]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CareNote(l10n.careExamNote),
            ],
          );
        },
      ),
    );
  }

  Widget _cell(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: bold ? careTitle(13) : careBody(12)),
      );
}
