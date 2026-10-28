import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Water per day over the same window, with the person's own goal.
class WaterLine extends StatelessWidget {
  final Map<DateTime, int> dailyTotals;
  final int goalMl;
  final DateTime today;
  final int windowDays;

  const WaterLine({
    super.key,
    required this.dailyTotals,
    required this.goalMl,
    required this.today,
    required this.windowDays,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: windowDays - 1));
    final spots = <FlSpot>[];
    var maxMl = goalMl.toDouble();
    dailyTotals.forEach((day, ml) {
      final index =
          DateTime(day.year, day.month, day.day).difference(start).inDays;
      if (index < 0 || index >= windowDays) return;
      spots.add(FlSpot(index.toDouble(), ml.toDouble()));
      if (ml > maxMl) maxMl = ml.toDouble();
    });
    spots.sort((a, b) => a.x.compareTo(b.x));
    if (spots.every((s) => s.y == 0)) {
      return Text(
        l10n.xv2DashNoWater,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
        ),
      );
    }
    return SizedBox(
      key: const Key('water_line_chart'),
      height: 140,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (windowDays - 1).toDouble(),
          minY: 0,
          maxY: maxMl * 1.1,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (goalMl > 0)
                HorizontalLine(
                  y: goalMl.toDouble(),
                  color: AppColors.clinicalTeal.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: AppColors.clinicalTeal,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.clinicalTeal.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
