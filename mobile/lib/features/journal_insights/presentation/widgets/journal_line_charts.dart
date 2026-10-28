import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/journal_insights_models.dart';

/// One line per item: the intensity the person reported each day.
class ItemSeries {
  final String key;
  final String label;

  /// Day index in the window (0 = oldest) to reported intensity (1..5).
  final Map<int, int> points;

  const ItemSeries({
    required this.key,
    required this.label,
    required this.points,
  });
}

/// Builds the item lines for the [windowDays] days ending on [today],
/// ordered by how many days each item was recorded.
List<ItemSeries> buildItemSeries(
  AppLocalizations l10n,
  List<JournalEntryView> entries, {
  required DateTime today,
  required int windowDays,
}) {
  final start = DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: windowDays - 1));
  final labels = <String, String>{};
  final points = <String, Map<int, int>>{};
  for (final entry in entries) {
    final index = entry.day.difference(start).inDays;
    if (index < 0 || index >= windowDays) continue;
    for (final item in entry.items) {
      final intensity = item.intensity;
      if (intensity == null) continue;
      final key = item.seriesKey;
      labels.putIfAbsent(key, () => item.label(l10n));
      final byDay = points.putIfAbsent(key, () => <int, int>{});
      // Several entries on one day: keep the highest value reported.
      final previous = byDay[index];
      if (previous == null || intensity > previous) byDay[index] = intensity;
    }
  }
  final series = [
    for (final key in points.keys)
      if ((labels[key] ?? '').isNotEmpty)
        ItemSeries(key: key, label: labels[key]!, points: points[key]!),
  ];
  series.sort((a, b) {
    final byDays = b.points.length.compareTo(a.points.length);
    return byDays != 0 ? byDays : a.label.compareTo(b.label);
  });
  return series;
}

const List<Color> _seriesColors = [
  Color(0xFF2B4F86),
  Color(0xFF2E8B8B),
  Color(0xFF7A5BA6),
  Color(0xFFB07A2A),
  Color(0xFF5F6B7A),
];

/// Daily intensity lines, at most [maxVisible] items before "ver mais"
/// (strategy §18.2).
class ItemIntensityLines extends StatefulWidget {
  static const int maxVisible = 5;

  final List<ItemSeries> series;
  final int windowDays;

  const ItemIntensityLines({
    super.key,
    required this.series,
    required this.windowDays,
  });

  @override
  State<ItemIntensityLines> createState() => _ItemIntensityLinesState();
}

class _ItemIntensityLinesState extends State<ItemIntensityLines> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.series.isEmpty) {
      return Text(
        l10n.xv2DashNoItems,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
        ),
      );
    }
    final overflow = widget.series.length > ItemIntensityLines.maxVisible;
    final visible = _showAll || !overflow
        ? widget.series
        : widget.series.take(ItemIntensityLines.maxVisible).toList();

    return Column(
      key: const Key('item_intensity_lines'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (widget.windowDays - 1).toDouble(),
              minY: 0,
              maxY: 5,
              lineTouchData: const LineTouchData(enabled: false),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.outlineLight, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: _titles(widget.windowDays),
              lineBarsData: [
                for (var i = 0; i < visible.length; i++)
                  _line(visible[i], _seriesColors[i % _seriesColors.length]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < visible.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              key: Key('item_series_${visible[i].key}'),
              children: [
                Container(
                  width: 12,
                  height: 4,
                  color: _seriesColors[i % _seriesColors.length],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visible[i].label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Text(
                  l10n.xv2DashDaysCount(visible[i].points.length),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        if (overflow)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('item_lines_see_more'),
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(_showAll ? l10n.xv2DashSeeLess : l10n.xv2DashSeeMore),
            ),
          ),
      ],
    );
  }

  LineChartBarData _line(ItemSeries s, Color color) {
    final days = s.points.keys.toList()..sort();
    return LineChartBarData(
      spots: [for (final d in days) FlSpot(d.toDouble(), s.points[d]!.toDouble())],
      color: color,
      barWidth: 2,
      isCurved: false,
      dotData: const FlDotData(show: true),
    );
  }
}

FlTitlesData _titles(int windowDays) {
  return FlTitlesData(
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 24,
        interval: 1,
        getTitlesWidget: (value, meta) => value == 0
            ? const SizedBox.shrink()
            : Text(
                value.toInt().toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.textSecondaryLight,
                ),
              ),
      ),
    ),
  );
}

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
