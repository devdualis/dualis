import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../domain/chart_data.dart';
import 'chart_tokens.dart';
import 'record_series_chart.dart' show chartCaptionStyle;

/// E1: Passado · Presente · Futuro as slices of the emotional records of the
/// period. Slice = records of that time / records with a time. Each slice
/// lists its count, percent and the most recorded final answer (ties all
/// shown). Records without a time are reported below, outside the pie.
class TemporalPieChart extends StatelessWidget {
  final TemporalPie pie;

  const TemporalPieChart({super.key, required this.pie});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = pie.total;
    final times = [
      for (final t in JournalLabels.times)
        if ((pie.counts[t] ?? 0) > 0) t,
    ];
    return Column(
      key: const Key('temporal_pie'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (total == 0)
          Text(l10n.xv2DashNoEmotional, style: chartCaptionStyle)
        else ...[
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Semantics(
                label: [
                  for (final t in times)
                    '${seriesLabel(l10n, t)} ${_percent(pie.counts[t]!, total)}%',
                ].join(', '),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(enabled: false),
                    sections: [
                      for (final t in times)
                        PieChartSectionData(
                          value: pie.counts[t]!.toDouble(),
                          color: ChartTokens.time(t),
                          radius: 82,
                          title: '${_percent(pie.counts[t]!, total)}%',
                          titlePositionPercentageOffset: 0.62,
                          titleStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final t in times) _SliceRow(time: t, pie: pie),
        ],
        if (pie.withoutAxis > 0) ...[
          const SizedBox(height: 4),
          Text(
            l10n.gxPieWithoutAxis(pie.withoutAxis),
            key: const Key('temporal_pie_without_axis'),
            style: chartCaptionStyle,
          ),
        ],
      ],
    );
  }
}

/// Display rounding only; the counts stay absolute.
int _percent(int count, int total) => (count * 100 / total).round();

class _SliceRow extends StatelessWidget {
  final String time;
  final TemporalPie pie;

  const _SliceRow({required this.time, required this.pie});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = pie.counts[time]!;
    final top = pie.top[time];
    final strong = GoogleFonts.plusJakartaSans(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryLight,
    );
    final body = GoogleFonts.plusJakartaSans(
      fontSize: 12.5,
      height: 1.4,
      color: AppColors.textPrimaryLight,
    );
    return Container(
      key: Key('temporal_pie_row_$time'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: ChartTokens.time(time), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${seriesLabel(l10n, time)} · ${l10n.gxRecords(count)} · ${_percent(count, pie.total)}%',
            style: strong,
          ),
          if (top != null) ...[
            const SizedBox(height: 4),
            if (top.answers.length == 1)
              Text(l10n.gxPieTop(top.answers.first, top.count, count), style: body)
            else ...[
              Text(l10n.gxPieTied(top.count, count), style: body),
              for (final a in top.answers) Text('· “$a”', style: body),
            ],
          ],
        ],
      ),
    );
  }
}
