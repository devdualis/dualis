import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/period_report.dart';
import 'chart_tokens.dart';

/// One colour for every bar: the length is a count, never a grade.
const Color _barColor = AppColors.dualisNavy;
const Color _trackColor = ChartTokens.waterTrack;

TextStyle get _textStyle => GoogleFonts.inter(
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: AppColors.dualisNavy,
    );

TextStyle get _smallStyle => GoogleFonts.inter(
      fontSize: 11.5,
      color: ChartTokens.axisLabel,
    );

/// Seven bars, Monday first, with the number of records above each one.
class WeekdayBars extends StatelessWidget {
  final Map<int, int> counts;
  static const double maxBarHeight = 56;

  const WeekdayBars({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final short = DateFormat.E(locale);
    final max = counts.values.fold(0, (a, b) => a > b ? a : b);
    return Row(
      key: const Key('period_weekday_bars'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var d = DateTime.monday; d <= DateTime.sunday; d++)
          Expanded(
            child: Semantics(
              label: l10n.histWeekdayBar(
                // 2024-01-01 is a Monday.
                DateFormat.EEEE(locale).format(DateTime(2024, 1, d)),
                counts[d] ?? 0,
              ),
              excludeSemantics: true,
              child: Column(
                key: Key('period_weekday_$d'),
                children: [
                  Text('${counts[d] ?? 0}', style: _smallStyle),
                  const SizedBox(height: 4),
                  Container(
                    width: 20,
                    height: max == 0
                        ? 2
                        : 2 + (maxBarHeight - 2) * (counts[d] ?? 0) / max,
                    decoration: BoxDecoration(
                      color: (counts[d] ?? 0) == 0 ? _trackColor : _barColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    short.format(DateTime(2024, 1, d)),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: _smallStyle,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// D17: "Como você se sentiu", records per everyday feeling, fixed order.
class EverydayFeelingsSummary extends StatelessWidget {
  final EverydayFeelingCounts counts;

  const EverydayFeelingsSummary({super.key, required this.counts});

  static String label(AppLocalizations l10n, EverydayFeeling feeling) =>
      switch (feeling) {
        EverydayFeeling.pesado => l10n.histFeelingPesado,
        EverydayFeeling.agitado => l10n.histFeelingAgitado,
        EverydayFeeling.irritado => l10n.histFeelingIrritado,
        EverydayFeeling.tranquilo => l10n.histFeelingTranquilo,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final feeling in EverydayFeeling.values)
          Padding(
            key: Key('feeling_${feeling.name}'),
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label(l10n, feeling),
                        style: _textStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      l10n.histFeelingCount(
                          counts.records[feeling] ?? 0, counts.total),
                      key: Key('feeling_count_${feeling.name}'),
                      style: _smallStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: counts.total == 0
                        ? 0
                        : (counts.records[feeling] ?? 0) / counts.total,
                    minHeight: 8,
                    color: _barColor,
                    backgroundColor: _trackColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
