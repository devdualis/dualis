import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/domain/journal_keys.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../domain/chart_data.dart';
import 'chart_tokens.dart';
import 'history_widgets.dart' show LineToggleChip;

/// One series on a [RecordSeriesChart]: a time (E2/E3) or a region (F2/F3).
class ChartSeries {
  final String key;
  final String label;
  final Color color;
  final List<RecordPoint> points;

  const ChartSeries({
    required this.key,
    required this.label,
    required this.color,
    required this.points,
  });
}

/// Intensity (1..5) of each record, placed at its date and time. Every dot is
/// one record: several records on one day stay separate dots, the line breaks
/// on days without a record of that series, and nothing is averaged,
/// interpolated or smoothed. Tapping a dot shows the record.
class RecordSeriesChart extends StatelessWidget {
  final List<ChartSeries> series;
  final DateTime start;
  final int days;

  /// E3/F3: dot shape follows the fork chosen (circle, square, cross).
  final bool shapeByBranch;

  const RecordSeriesChart({
    super.key,
    required this.series,
    required this.start,
    required this.days,
    this.shapeByBranch = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final step = days <= 7 ? 1 : 7;
    final bars = <LineChartBarData>[];
    final barPoints = <List<RecordPoint>>[];
    final barSeries = <ChartSeries>[];
    for (final s in series) {
      for (final run in seriesRuns(s.points)) {
        bars.add(_bar(s, run));
        barPoints.add(run);
        barSeries.add(s);
      }
    }
    final axisStyle = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      color: AppColors.textSecondaryLight,
    );
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: days.toDouble(),
          minY: 0,
          maxY: 5.4,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            drawVerticalLine: true,
            verticalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.outlineLight, strokeWidth: 1),
            getDrawingVerticalLine: (_) => FlLine(
                color: AppColors.outlineLight.withValues(alpha: 0.5),
                strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              axisNameSize: 16,
              axisNameWidget: Text(l10n.gxIntensityAxis, style: axisStyle),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                interval: 1,
                getTitlesWidget: (value, meta) => value > 5 || value != value.roundToDouble()
                    ? const SizedBox.shrink()
                    : Text(value.toInt().toString(), style: axisStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (value != index || index >= days || (days - 1 - index) % step != 0) {
                    return const SizedBox.shrink();
                  }
                  final day = DateTime(start.year, start.month, start.day + index);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('dd/MM', locale).format(day),
                        style: axisStyle),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (bar, indexes) => [
              for (final _ in indexes)
                const TouchedSpotIndicatorData(
                  FlLine(color: Colors.transparent),
                  FlDotData(show: true),
                ),
            ],
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceLight,
              tooltipBorder: const BorderSide(color: AppColors.outlineLight),
              tooltipBorderRadius: BorderRadius.circular(10),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              maxContentWidth: 220,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    describeRecord(l10n, locale,
                        barPoints[spot.barIndex][spot.spotIndex]),
                    GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      height: 1.35,
                      color: AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.left,
                  ),
              ],
            ),
          ),
          lineBarsData: bars,
        ),
      ),
    );
  }

  LineChartBarData _bar(ChartSeries s, List<RecordPoint> run) {
    return LineChartBarData(
      spots: [
        for (final p in run)
          FlSpot(dayPosition(p.at, start), p.intensity!.toDouble()),
      ],
      color: s.color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) =>
            shapeByBranch ? branchDot(run[index], s.color) : _circle(s.color),
      ),
    );
  }

  static FlDotPainter _circle(Color color) => FlDotCirclePainter(
        radius: 4,
        color: color,
        strokeWidth: 1.5,
        strokeColor: AppColors.surfaceLight,
      );

  /// Circle = first fork, square = second, cross = third; written answers
  /// are a hollow circle.
  static FlDotPainter branchDot(RecordPoint p, Color color) {
    switch (p.branchIndex) {
      case 0:
        return _circle(color);
      case 1:
        return FlDotSquarePainter(
          size: 8.5,
          color: color,
          strokeWidth: 1.5,
          strokeColor: AppColors.surfaceLight,
        );
      case 2:
        return FlDotCrossPainter(size: 9, color: color, width: 2.5);
      default:
        return FlDotCirclePainter(
          radius: 4,
          color: AppColors.surfaceLight,
          strokeWidth: 2,
          strokeColor: color,
        );
    }
  }
}

/// Date, time, fork, answer and intensity of one record.
String describeRecord(AppLocalizations l10n, String locale, RecordPoint p) {
  final when = DateFormat('dd/MM · HH:mm', locale).format(p.at);
  final root = seriesLabel(l10n, p.series);
  final branch =
      p.branchKey != null ? JournalLabels.branch(l10n, p.branchKey!) : null;
  final lines = [
    when,
    branch != null ? '$root · $branch' : root,
    '“${p.answer}”',
    p.intensity != null
        ? l10n.gxIntensityValue(p.intensity!)
        : l10n.gxIntensityNotInformed,
  ];
  return lines.join('\n');
}

/// E2/F2: one line per series with a legend that shows or hides each one.
class SeriesLinesCard extends StatefulWidget {
  final List<ChartSeries> series;
  final DateTime start;
  final int days;
  final String keyPrefix;

  const SeriesLinesCard({
    super.key,
    required this.series,
    required this.start,
    required this.days,
    required this.keyPrefix,
  });

  @override
  State<SeriesLinesCard> createState() => _SeriesLinesCardState();
}

class _SeriesLinesCardState extends State<SeriesLinesCard> {
  final Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: Key('${widget.keyPrefix}_lines'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecordSeriesChart(
          series: [
            for (final s in widget.series)
              if (!_hidden.contains(s.key)) s,
          ],
          start: widget.start,
          days: widget.days,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final s in widget.series)
              LineToggleChip(
                key: Key('${widget.keyPrefix}_chip_${s.key}'),
                label: '${s.label} · ${s.points.where((p) => p.intensity != null).length}',
                color: s.color,
                shown: !_hidden.contains(s.key),
                onTap: () => setState(() => _hidden.contains(s.key)
                    ? _hidden.remove(s.key)
                    : _hidden.add(s.key)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(l10n.gxLegendHint, style: chartCaptionStyle),
      ],
    );
  }
}

/// E3/F3: one series at a time, picked with a filter. The dot shape tells
/// which fork of that series was chosen; the legend names each shape.
class SeriesAnswersCard extends StatefulWidget {
  final List<ChartSeries> series;
  final DateTime start;
  final int days;
  final String keyPrefix;

  /// Physical tree for regions, emotional tree for times.
  final Map<String, Map<String, List<String>>> tree;

  /// Series picked from outside ("Ver evolução" on the body map).
  final String? selected;

  const SeriesAnswersCard({
    super.key,
    required this.series,
    required this.start,
    required this.days,
    required this.keyPrefix,
    required this.tree,
    this.selected,
  });

  @override
  State<SeriesAnswersCard> createState() => _SeriesAnswersCardState();
}

class _SeriesAnswersCardState extends State<SeriesAnswersCard> {
  String? _picked;

  @override
  void didUpdateWidget(covariant SeriesAnswersCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && widget.selected != null) {
      _picked = widget.selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.series.isEmpty) return const SizedBox.shrink();
    final current = widget.series.firstWhere(
      (s) => s.key == (_picked ?? widget.selected),
      orElse: () => widget.series.first,
    );
    final branches = widget.tree[current.key]?.keys.toList() ?? const <String>[];
    final hasWritten = current.points.any((p) => p.branchIndex < 0);
    final withIntensity = current.points.where((p) => p.intensity != null);
    return Column(
      key: Key('${widget.keyPrefix}_answers'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in widget.series)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('${widget.keyPrefix}_filter_${s.key}'),
                    label: Text(s.label),
                    selected: s.key == current.key,
                    showCheckmark: false,
                    selectedColor: s.color.withValues(alpha: 0.14),
                    backgroundColor: AppColors.surfaceLight,
                    side: BorderSide(
                      color: s.key == current.key ? s.color : AppColors.outlineLight,
                      width: 1.4,
                    ),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                    onSelected: (_) => setState(() => _picked = s.key),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (withIntensity.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.gxNoIntensityPoints, style: chartCaptionStyle),
          )
        else
          RecordSeriesChart(
            series: [current],
            start: widget.start,
            days: widget.days,
            shapeByBranch: true,
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (var i = 0; i < branches.length && i < 3; i++)
              _ShapeLegend(
                index: i,
                color: current.color,
                label: JournalLabels.branch(l10n, '${current.key}.${branches[i]}'),
              ),
            if (hasWritten)
              _ShapeLegend(index: -1, color: current.color, label: l10n.gxWrittenByYou),
          ],
        ),
      ],
    );
  }
}

class _ShapeLegend extends StatelessWidget {
  final int index;
  final Color color;
  final String label;

  const _ShapeLegend({required this.index, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: const Size(12, 12), painter: _ShapePainter(index, color)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

class _ShapePainter extends CustomPainter {
  final int index;
  final Color color;
  _ShapePainter(this.index, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final fill = Paint()..color = color;
    switch (index) {
      case 0:
        canvas.drawCircle(c, size.width / 2.4, fill);
      case 1:
        canvas.drawRect(Rect.fromCenter(center: c, width: 9, height: 9), fill);
      case 2:
        final p = Paint()
          ..color = color
          ..strokeWidth = 2.4;
        canvas.drawLine(c + const Offset(-4.5, -4.5), c + const Offset(4.5, 4.5), p);
        canvas.drawLine(c + const Offset(-4.5, 4.5), c + const Offset(4.5, -4.5), p);
      default:
        canvas.drawCircle(
          c,
          size.width / 2.6,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) =>
      old.index != index || old.color != color;
}

final TextStyle chartCaptionStyle = GoogleFonts.plusJakartaSans(
  fontSize: 12,
  color: AppColors.textSecondaryLight,
);

/// Series of the emotional charts, in Passado · Presente · Futuro order.
List<ChartSeries> emotionalSeries(AppLocalizations l10n, List<RecordPoint> points) => [
      for (final time in JournalLabels.times)
        if (points.any((p) => p.series == time))
          ChartSeries(
            key: time,
            label: seriesLabel(l10n, time),
            color: ChartTokens.time(time),
            points: [for (final p in points) if (p.series == time) p],
          ),
    ];

/// Series of the body charts, in body order.
List<ChartSeries> physicalSeries(AppLocalizations l10n, List<RecordPoint> points) => [
      for (final region in JournalKeys.regions)
        if (points.any((p) => p.series == region))
          ChartSeries(
            key: region,
            label: seriesLabel(l10n, region),
            color: ChartTokens.region(region),
            points: [for (final p in points) if (p.series == region) p],
          ),
    ];
