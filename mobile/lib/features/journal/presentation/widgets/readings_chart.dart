import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal_insights/domain/chart_data.dart' show dayPosition;
import '../../../journal_insights/presentation/widgets/chart_tokens.dart';
import '../../domain/journal_keys.dart';
import '../../domain/journal_models.dart';

/// Neutral line colours: they tell two lines apart and never say anything
/// about the value (teal for the first line, slate for the second).
const Color readingsLineTeal = ChartTokens.presente;
const Color readingsLineSlate = ChartTokens.body;

/// Name of a reading kind (`blood_pressure`, `glucose`, `weight`).
String readingKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
      JournalKeys.trackingBloodPressure => l10n.chronicHistoryKindBloodPressure,
      JournalKeys.trackingGlucose => l10n.chronicHistoryKindGlucose,
      JournalKeys.trackingWeight => l10n.chronicHistoryKindWeight,
      _ => kind,
    };

/// Name of the glucose moment the person picked.
String? readingMomentLabel(AppLocalizations l10n, String? moment) =>
    switch (moment) {
      JournalKeys.momentJejum => l10n.chronicHistoryMomentJejum,
      JournalKeys.momentPreRefeicao => l10n.chronicHistoryMomentPreRefeicao,
      JournalKeys.momentPosRefeicao => l10n.chronicHistoryMomentPosRefeicao,
      JournalKeys.momentDormir => l10n.chronicHistoryMomentDormir,
      _ => null,
    };

/// Weight as typed, with the decimal mark of the locale ("72,5").
String readingKgText(String locale, double kg) =>
    (NumberFormat.decimalPattern(locale)
          ..minimumFractionDigits = 0
          ..maximumFractionDigits = JournalKeys.kgDecimals)
        .format(kg);

/// The values of one reading, raw, with units: "120/80 mmHg · pulso 72 bpm",
/// "98 mg/dL · Jejum", "72,5 kg". No label, range or comparison.
String readingValueText(
  AppLocalizations l10n,
  String locale,
  ConditionReading r,
) {
  switch (r.kind) {
    case JournalKeys.trackingBloodPressure:
      return [
        l10n.chronicHistoryValueBp(r.systolic ?? 0, r.diastolic ?? 0),
        if (r.pulse != null) l10n.chronicHistoryValuePulse(r.pulse!),
      ].join(' · ');
    case JournalKeys.trackingGlucose:
      final moment = readingMomentLabel(l10n, r.moment);
      return [
        l10n.chronicHistoryValueGlucose(r.mgdl ?? 0),
        if (moment != null) moment,
      ].join(' · ');
    case JournalKeys.trackingWeight:
      return l10n.chronicHistoryValueWeight(readingKgText(locale, r.kg ?? 0));
    default:
      return '';
  }
}

/// Tooltip text: values and time ("120/80 mmHg · 01/11 08:30").
String readingTooltipText(
  AppLocalizations l10n,
  String locale,
  ConditionReading r,
) =>
    '${readingValueText(l10n, locale, r)} · '
    '${DateFormat('dd/MM HH:mm', locale).format(r.measuredAt.toLocal())}';

/// One line of a reading chart: which value it plots and how it looks.
class _Line {
  final String label;
  final Color color;
  final List<int>? dash;
  final double? Function(ConditionReading) value;

  const _Line(this.label, this.color, this.value, {this.dash});
}

/// Runs of readings with no empty day between two neighbours, oldest first.
/// A day with no reading breaks the line.
List<List<ConditionReading>> readingRuns(List<ConditionReading> readings) {
  final sorted = [...readings]
    ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  final runs = <List<ConditionReading>>[];
  DateTime dayOf(ConditionReading r) {
    final l = r.measuredAt.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  for (final r in sorted) {
    if (runs.isNotEmpty &&
        dayOf(r).difference(dayOf(runs.last.last)).inDays <= 1) {
      runs.last.add(r);
    } else {
      runs.add([r]);
    }
  }
  return runs;
}

/// Raw values of one reading kind of a condition, placed at their date and
/// time. Every dot is one reading: several readings on one day stay separate
/// dots, the line breaks on days without a reading, and nothing is averaged,
/// smoothed or compared. No bands, target lines or value colours. Blood
/// pressure has two lines (systolic solid teal, diastolic dashed slate).
class ReadingsChart extends StatelessWidget {
  /// `blood_pressure` | `glucose` | `weight`.
  final String kind;

  /// Readings of [kind]; other kinds are ignored.
  final List<ConditionReading> readings;

  /// Local midnight of the first day shown.
  final DateTime start;
  final int days;

  const ReadingsChart({
    super.key,
    required this.kind,
    required this.readings,
    required this.start,
    required this.days,
  });

  List<_Line> _lines(AppLocalizations l10n) => switch (kind) {
        JournalKeys.trackingBloodPressure => [
            _Line(l10n.chronicHistorySystolic, readingsLineTeal,
                (r) => r.systolic?.toDouble()),
            _Line(l10n.chronicHistoryDiastolic, readingsLineSlate,
                (r) => r.diastolic?.toDouble(),
                dash: const [6, 4]),
          ],
        JournalKeys.trackingGlucose => [
            _Line(l10n.chronicHistoryKindGlucose, readingsLineTeal,
                (r) => r.mgdl?.toDouble()),
          ],
        _ => [
            _Line(l10n.chronicHistoryKindWeight, readingsLineTeal, (r) => r.kg),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final lines = _lines(l10n);
    final mine = [
      for (final r in readings)
        if (r.kind == kind) r,
    ];
    final runs = readingRuns(mine);

    final bars = <LineChartBarData>[];
    final barReadings = <List<ConditionReading>>[];
    final values = <double>[];
    for (final run in runs) {
      for (final line in lines) {
        final points = [
          for (final r in run)
            if (line.value(r) != null) r,
        ];
        if (points.isEmpty) continue;
        values.addAll(points.map((r) => line.value(r)!));
        barReadings.add(points);
        bars.add(LineChartBarData(
          spots: [
            for (final r in points)
              FlSpot(dayPosition(r.measuredAt.toLocal(), start), line.value(r)!),
          ],
          isCurved: false,
          color: line.color,
          barWidth: 2.2,
          dashArray: line.dash,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(show: false),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4,
              color: line.color,
              strokeWidth: 1.5,
              strokeColor: AppColors.surfaceLight,
            ),
          ),
        ));
      }
    }

    // Axis from the person's own values with some room; never a reference.
    final low = values.isEmpty ? 0.0 : values.reduce(math.min);
    final high = values.isEmpty ? 1.0 : values.reduce(math.max);
    final room = math.max((high - low) * 0.15, kind == JournalKeys.trackingWeight ? 1.0 : 5.0);
    final roughMin = math.max(0.0, (low - room).floorToDouble());
    final roughMax = (high + room).ceilToDouble();
    final interval = math.max(1.0, ((roughMax - roughMin) / 4).ceilToDouble());
    // Both ends on the grid, so the edge labels never sit on top of a grid
    // label (e.g. "74" under "78").
    final minY = (roughMin / interval).floorToDouble() * interval;
    final maxY = (roughMax / interval).ceilToDouble() * interval;
    final step = days <= 7 ? 1 : (days <= 30 ? 7 : 15);
    final axisStyle = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      color: AppColors.textSecondaryLight,
    );
    final axisNumber = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: days.toDouble(),
              minY: minY,
              maxY: maxY,
              // Values and times always sit inside the axis, so no clip: a
              // reading late today would otherwise lose half its dot.
              clipData: const FlClipData.none(),
              gridData: FlGridData(
                show: true,
                horizontalInterval: interval,
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
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      axisNumber.format(value),
                      style: axisStyle,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (value != index ||
                          index >= days ||
                          (days - 1 - index) % step != 0) {
                        return const SizedBox.shrink();
                      }
                      final day =
                          DateTime(start.year, start.month, start.day + index);
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
                  maxContentWidth: 240,
                  getTooltipItems: (spots) {
                    // Systolic and diastolic of one reading share a time:
                    // one tooltip line per reading.
                    final shown = <ConditionReading>{};
                    return [
                      for (final spot in spots)
                        if (shown.add(barReadings[spot.barIndex][spot.spotIndex]))
                          LineTooltipItem(
                            readingTooltipText(l10n, locale,
                                barReadings[spot.barIndex][spot.spotIndex]),
                            GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              height: 1.35,
                              color: AppColors.textPrimaryLight,
                            ),
                            textAlign: TextAlign.left,
                          )
                        else
                          null,
                    ];
                  },
                ),
              ),
              lineBarsData: bars,
            ),
          ),
        ),
        if (lines.length > 1) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final line in lines)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(18, 10),
                      painter: _LegendPainter(line.color, dashed: line.dash != null),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      line.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegendPainter extends CustomPainter {
  final Color color;
  final bool dashed;
  _LegendPainter(this.color, {required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2;
    if (dashed) {
      canvas.drawLine(Offset(0, y), Offset(6, y), paint);
      canvas.drawLine(Offset(10, y), Offset(size.width, y), paint);
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawCircle(Offset(size.width / 2, y), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LegendPainter old) =>
      old.color != color || old.dashed != dashed;
}
