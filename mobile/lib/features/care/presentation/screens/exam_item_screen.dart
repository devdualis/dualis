import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../widgets/care_widgets.dart';

/// Confirmed values of one item over time, as a table. No chart with bands:
/// each lab prints its own reference and the app does not compare them.
class ExamItemScreen extends ConsumerWidget {
  const ExamItemScreen({super.key, required this.item});
  final String item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(l10n.careExamItemIntro, style: careBody()),
              const SizedBox(height: 12),
              CareCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Table(
                  columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(3), 2: FlexColumnWidth(3), 3: FlexColumnWidth(3)},
                  children: [
                    TableRow(children: [
                      for (final h in [l10n.careExamDate, l10n.careExamValue, l10n.careExamReferencePrinted, l10n.careExamLab])
                        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(h, style: careBody(11))),
                    ]),
                    for (final (date, v, lab) in rows)
                      TableRow(children: [
                        _cell(careDate(context, DateTime.parse(date))),
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
