import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class WaterConsumptionChart extends StatelessWidget {
  final Map<DateTime, int> last7DaysTotals;
  final int dailyTargetMl;

  const WaterConsumptionChart({
    super.key,
    required this.last7DaysTotals,
    this.dailyTargetMl = 2000,
  });

  @override
  Widget build(BuildContext context) {
    if (last7DaysTotals.isEmpty) {
      return _buildEmptyState();
    }

    final entries =
        last7DaysTotals.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    final totalMlSum = entries.fold<int>(0, (sum, e) => sum + e.value);
    final averageMl =
        entries.isNotEmpty ? (totalMlSum / entries.length).round() : 0;
    final daysGoalMet = entries.where((e) => e.value >= dailyTargetMl).length;

    final maxVal = entries.fold<int>(
      dailyTargetMl,
      (max, e) => e.value > max ? e.value : max,
    );
    final maxY = ((maxVal * 1.2) / 500).ceil() * 500.0;

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < entries.length; i++) {
      final item = entries[i];
      final isMet = item.value >= dailyTargetMl;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: item.value.toDouble(),
              color:
                  isMet
                      ? AppColors.clinicalTealDark
                      : AppColors.clinicalTeal.withValues(alpha: 0.75),
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card container
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: AppColors.surfaceLight,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.clinicalTeal.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              color: AppColors.clinicalTealDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Consumo de Água (7 Dias)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  'Meta diária: $dailyTargetMl ml',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: AppColors.softIndigo,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$daysGoalMet/7 metas',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.softIndigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Chart Canvas
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      minY: 0,
                      barGroups: barGroups,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 500,
                        getDrawingHorizontalLine: (value) {
                          if ((value - dailyTargetMl).abs() < 50) {
                            return const FlLine(
                              color: AppColors.clinicalTealDark,
                              strokeWidth: 1.5,
                              dashArray: [6, 4],
                            );
                          }
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 1000,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppColors.textSecondaryLight,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= entries.length) {
                                return const SizedBox.shrink();
                              }
                              final date = entries[idx].key;
                              const ptWeekdays = [
                                'Seg',
                                'Ter',
                                'Qua',
                                'Qui',
                                'Sex',
                                'Sáb',
                                'Dom',
                              ];
                              final dayName =
                                  ptWeekdays[(date.weekday - 1).clamp(0, 6)];
                              final dayNum = date.day.toString().padLeft(
                                2,
                                '0',
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '$dayName $dayNum',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight:
                                        idx == entries.length - 1
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        idx == entries.length - 1
                                            ? AppColors.clinicalTealDark
                                            : AppColors.textSecondaryLight,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => AppColors.surfaceDark,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final date = entries[group.x].key;
                            final dateFormatted =
                                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
                            final val = rod.toY.toInt();
                            final percentage =
                                ((val / dailyTargetMl) * 100).round();
                            return BarTooltipItem(
                              '$dateFormatted\n$val ml ($percentage%)',
                              GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildMetricCol(
                        'Hoje',
                        '${entries.isNotEmpty ? entries.last.value : 0} ml',
                      ),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _buildMetricCol('Média 7 dias', '$averageMl ml'),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _buildMetricCol('Meta', '$dailyTargetMl ml'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.water_drop_outlined,
                size: 40,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                'Nenhum registro de consumo de água ainda.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
