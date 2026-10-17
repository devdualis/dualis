import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/triage_history_models.dart';

class EmotionalTrendChart extends StatefulWidget {
  final List<EmotionalDayData> data;

  const EmotionalTrendChart({
    super.key,
    required this.data,
  });

  @override
  State<EmotionalTrendChart> createState() => _EmotionalTrendChartState();
}

class _EmotionalTrendChartState extends State<EmotionalTrendChart> {
  static const Map<String, ({String label, Color color})> dimensionMeta = {
    'ansiosa_agitacao': (label: 'Ansiedade', color: Color(0xFF7E57C2)),
    'depressiva_desanimo': (label: 'Desânimo', color: Color(0xFF5C6BC0)),
    'estresse_burnout': (label: 'Estresse', color: Color(0xFFFF7043)),
    'somatica': (label: 'Tensão no corpo', color: Color(0xFF26A69A)),
    'sono': (label: 'Sono', color: Color(0xFF3949AB)),
    'cognitiva_foco': (label: 'Foco / Atenção', color: Color(0xFF00ACC1)),
    'autoestima': (label: 'Autoestima', color: Color(0xFFEC407A)),
  };

  final Set<String> _hiddenDimensions = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.data.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final activeKeys = dimensionMeta.keys.where((key) {
      if (_hiddenDimensions.contains(key)) return false;
      return widget.data.any((day) => (day.dimensions[key] ?? 0) > 0);
    }).toList();

    final lineBarsData = activeKeys.map((key) {
      final meta = dimensionMeta[key]!;
      final spots = <FlSpot>[];

      for (int i = 0; i < widget.data.length; i++) {
        final val = widget.data[i].dimensions[key] ?? 0;
        spots.add(FlSpot(i.toDouble(), val.toDouble()));
      }

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: meta.color,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: meta.color,
              strokeWidth: 1.5,
              strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: meta.color.withValues(alpha: 0.08),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0.5,
          color: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.show_chart_rounded,
                      color: AppColors.softIndigo,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Evolução Emocional (Últimos 7 Dias)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (widget.data.length - 1).toDouble().clamp(1.0, 6.0),
                      minY: 0,
                      maxY: 5,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((barSpot) {
                              final key = activeKeys[barSpot.barIndex];
                              final meta = dimensionMeta[key]!;
                              final intensity = barSpot.y.toInt();
                              return LineTooltipItem(
                                '${meta.label}: $intensity/5',
                                GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= widget.data.length) {
                                return const SizedBox.shrink();
                              }
                              final dateStr = widget.data[idx].date;
                              final parts = dateStr.split('-');
                              final label = parts.length >= 3
                                  ? '${parts[2]}/${parts[1]}'
                                  : dateStr;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                value.toInt().toString(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                          strokeWidth: 1,
                        ),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
                          left: BorderSide(color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
                        ),
                      ),
                      lineBarsData: lineBarsData,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLegend(isDark),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Card(
      elevation: 0.5,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 44,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 12),
              Text(
                'Sem registros emocionais nesta semana',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Realize check-ins diários para visualizar o gráfico de tendências.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Wrap(
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      spacing: 6,
      runSpacing: 4,
      children: dimensionMeta.entries.map((entry) {
        final isHidden = _hiddenDimensions.contains(entry.key);
        return Semantics(
          button: true,
          label: '${entry.value.label}, ${isHidden ? 'oculto' : 'visível'}',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isHidden) {
                    _hiddenDimensions.remove(entry.key);
                  } else {
                    _hiddenDimensions.add(entry.key);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Center(
                widthFactor: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isHidden
                        ? (isDark ? AppColors.backgroundDark : Colors.grey.shade100)
                        : entry.value.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isHidden
                          ? (isDark ? AppColors.outlineDark : Colors.grey.shade300)
                          : entry.value.color,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isHidden ? Colors.grey : entry.value.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        entry.value.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isHidden
                              ? (isDark ? AppColors.textSecondaryDark : Colors.grey)
                              : (isDark ? AppColors.textPrimaryDark : Colors.black87),
                          decoration:
                              isHidden ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
