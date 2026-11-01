import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/domain/journal_keys.dart';
import '../../../journal/presentation/journal_item_text.dart';
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

TextStyle get _lineStyle => GoogleFonts.plusJakartaSans(
      fontSize: 13,
      color: AppColors.textPrimaryLight,
    );

TextStyle get _labelStyle => GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryLight,
    );

Widget _line(String text, {Key? key}) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, key: key, style: _lineStyle),
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
            '${journalEmojis[e.key] ?? ''} ${JournalLabels.root(l10n, e.key)} · '
            '${l10n.xv2DashDaysCount(e.value)}',
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
              '${journalEmojis[e.key] ?? ''} ${JournalLabels.coping(l10n, e.key)} · '
              '${l10n.xv2DashDaysCount(e.value)}',
              key: Key('coping_${e.key}'),
            ),
        ],
      ],
    );
  }
}
