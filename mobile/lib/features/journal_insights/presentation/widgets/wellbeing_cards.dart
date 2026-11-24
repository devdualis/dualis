import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/domain/journal_keys.dart';
import '../../../journal/presentation/journal_marks.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../domain/journal_insights_models.dart';

/// Keys with a count, most days first; ties keep [order].
List<MapEntry<String, int>> _ranked(Map<String, int> counts, List<String> order) {
  final entries = [
    for (final e in counts.entries)
      if (e.value > 0) e,
  ];
  int rank(String key) {
    final i = order.indexOf(key);
    return i < 0 ? order.length : i;
  }

  entries.sort((a, b) {
    final byCount = b.value.compareTo(a.value);
    return byCount != 0 ? byCount : rank(a.key).compareTo(rank(b.key));
  });
  return entries;
}

TextStyle get _lineStyle => GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.dualisNavy,
    );

TextStyle get _labelStyle => GoogleFonts.inter(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondaryLight,
    );

/// One count line as a quiet brand-tinted row, so the cards read as a list of
/// recorded days rather than loose text.
Widget _line(String text, {Key? key, String? markKey}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        key: key,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.brandBgLightBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dualisNavy.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (JournalMarks.box(markKey, size: 18) case final mark?) ...[
              mark,
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(text, style: _lineStyle)),
          ],
        ),
      ),
    );

/// "Momentos bons": days per time and the most marked good moments.
/// Counts only.
class GoodMomentsSummary extends StatelessWidget {
  final JournalSummary summary;

  /// Most marked options shown.
  static const int topCount = 3;

  const GoodMomentsSummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final times = _ranked(summary.positiveByTime, JournalLabels.times);
    final top = _ranked(
      summary.positiveByOptionKey,
      JournalKeys.positiveOptionKeys.toList(),
    ).take(topCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in times)
          _line(
            '${JournalLabels.root(l10n, e.key)} · '
            '${l10n.xv2DashDaysCount(e.value)}',
            markKey: e.key,
            key: Key('good_moments_time_${e.key}'),
          ),
        if (top.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l10n.jv22GoodMomentsMost, style: _labelStyle),
          const SizedBox(height: 4),
          for (final e in top)
            _line(
              '${JournalLabels.option(l10n, e.key)} · ${l10n.xv2DashDaysCount(e.value)}',
              key: Key('good_moments_option_${e.key}'),
            ),
        ],
      ],
    );
  }
}

/// "O que te ajudou": days each helper and coping answer was marked.
class HelpedSummary extends StatelessWidget {
  final JournalSummary summary;

  const HelpedSummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final helpers = _ranked(summary.byHelper, JournalKeys.helpers);
    final copings = _ranked(summary.byCoping, JournalKeys.copings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in helpers)
          _line(
            l10n.jv22HelpedLine(JournalLabels.helper(l10n, e.key), e.value),
            key: Key('helped_${e.key}'),
          ),
        if (copings.isNotEmpty) ...[
          if (helpers.isNotEmpty) const SizedBox(height: 8),
          Text(l10n.jv22CopingQuestion, style: _labelStyle),
          const SizedBox(height: 4),
          for (final e in copings)
            _line(
              '${JournalLabels.coping(l10n, e.key)} · '
              '${l10n.xv2DashDaysCount(e.value)}',
              markKey: e.key,
              key: Key('coping_${e.key}'),
            ),
        ],
      ],
    );
  }
}
