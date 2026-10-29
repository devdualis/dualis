import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chart_data.dart';
import 'chart_tokens.dart';
import 'period_calendar.dart';
import 'record_series_chart.dart' show chartCaptionStyle;

/// Water charts H1–H4. They show volume logged and progress towards the goal
/// the person chose; never hydration, need or benefit.

String formatLiters(int ml, String locale) =>
    '${NumberFormat('0.0', locale).format(ml / 1000)} L';

String formatMl(int ml, String locale) =>
    '${NumberFormat.decimalPattern(locale).format(ml)} ml';

/// Round axis steps (500 ml up to 2 L, then 1 L).
double _tick(double maxY) => maxY <= 2000 ? 500 : 1000;

int? goalPercent(int ml, int? goalMl) =>
    goalMl == null || goalMl <= 0 ? null : (ml * 100 / goalMl).round();

/// H1: ring with the total logged and the share of the chosen goal. The
/// ring is full at 100%; the numbers keep any excess (2.400/2.000 = 120%).
class WaterDayRing extends StatelessWidget {
  final int totalMl;
  final int? goalMl;
  final double size;

  const WaterDayRing({
    super.key,
    required this.totalMl,
    required this.goalMl,
    this.size = 148,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final percent = goalPercent(totalMl, goalMl);
    final fill = percent == null ? 0.0 : math.min(totalMl / goalMl!, 1.0);
    return SizedBox(
      key: const Key('water_day_ring'),
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fill),
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: value,
              strokeWidth: 12,
              backgroundColor: ChartTokens.waterTrack,
              valueColor: const AlwaysStoppedAnimation(ChartTokens.water),
              strokeCap: StrokeCap.round,
            ),
            Center(child: child),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: totalMl == 0
              ? Text(
                  l10n.gxNoWaterRecord,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.textSecondaryLight,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      child: Text(
                        formatMl(totalMl, locale),
                        key: const Key('water_day_ring_total'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    if (percent != null)
                      Text(
                        '$percent%',
                        key: const Key('water_day_ring_percent'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

/// H2: running sum through the day, one step per water event. Today ends
/// now; a finished day carries the last value to midnight.
class WaterStepChart extends StatelessWidget {
  final List<WaterStep> steps;
  final int? goalMl;

  /// Hour (0..24) where the line ends.
  final double endHour;

  const WaterStepChart({
    super.key,
    required this.steps,
    required this.goalMl,
    required this.endHour,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (steps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(l10n.gxNoWaterRecord, style: chartCaptionStyle),
      );
    }
    final last = steps.last.cumulativeMl;
    final top = math.max(last, goalMl ?? 0);
    final maxY = (top * 1.15 / 500).ceil() * 500.0;
    final end = math.max(endHour, steps.last.hour);
    final spots = <FlSpot>[
      const FlSpot(0, 0),
      for (final s in steps) FlSpot(s.hour, s.cumulativeMl.toDouble()),
      FlSpot(end, last.toDouble()),
    ];
    final axis = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      color: AppColors.textSecondaryLight,
    );
    return SizedBox(
      key: const Key('water_step_chart'),
      height: 190,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 24,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            verticalInterval: 4,
            horizontalInterval: _tick(maxY),
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.outlineLight, strokeWidth: 1),
            getDrawingVerticalLine: (_) =>
                const FlLine(color: AppColors.outlineLight, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: _tick(maxY),
                getTitlesWidget: (v, _) =>
                    Text(NumberFormat.decimalPattern(locale).format(v.round()), style: axis),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 4,
                getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: axis),
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [
            if (goalMl != null && goalMl! > 0)
              HorizontalLine(
                y: goalMl!.toDouble(),
                color: AppColors.textSecondaryLight,
                strokeWidth: 1,
                dashArray: [5, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: axis,
                  labelResolver: (_) => l10n.gxWaterGoalLine(goalMl!),
                ),
              ),
          ]),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceLight,
              tooltipBorder: const BorderSide(color: AppColors.outlineLight),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  spot.spotIndex == 0 || spot.spotIndex > steps.length
                      ? null
                      : LineTooltipItem(
                          l10n.gxWaterStepTooltip(
                            DateFormat.Hm(locale).format(steps[spot.spotIndex - 1].at),
                            steps[spot.spotIndex - 1].addedMl,
                            steps[spot.spotIndex - 1].cumulativeMl,
                          ),
                          GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isStepLineChart: true,
              // The sum jumps at the moment of each event.
              lineChartStepData: const LineChartStepData(
                stepDirection: LineChartStepData.stepDirectionForward,
              ),
              color: ChartTokens.water,
              barWidth: 2.5,
              belowBarData: BarAreaData(
                show: true,
                color: ChartTokens.water.withValues(alpha: 0.08),
              ),
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, bar) {
                  final i = bar.spots.indexOf(spot);
                  return i > 0 && i <= steps.length;
                },
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: ChartTokens.water,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// H3: one bar per day with water logged, the chosen goal as a dashed line,
/// and the period cards. A day without a log is a short grey dash, not a
/// zero bar.
class WaterPeriodBars extends StatelessWidget {
  final Map<DateTime, int> totals;
  final DateTime start;
  final int days;
  final int? goalMl;
  final DateTime today;
  final DateTime? selected;
  final ValueChanged<DateTime>? onDayTap;

  const WaterPeriodBars({
    super.key,
    required this.totals,
    required this.start,
    required this.days,
    required this.goalMl,
    required this.today,
    this.selected,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final water = normalizeWaterTotals(totals);
    final stats = WaterPeriodStats.compute(water,
        start: start, days: days, goalMl: goalMl);
    final top = math.max(
      water.values.fold<int>(0, math.max),
      goalMl ?? 0,
    );
    final maxY = math.max(500.0, (top * 1.15 / 500).ceil() * 500.0);
    final step = days <= 7 ? 1 : 5;
    final axis = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      color: AppColors.textSecondaryLight,
    );
    DateTime dayAt(int i) => DateTime(start.year, start.month, start.day + i);
    return Column(
      key: const Key('water_period_bars'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatGrid(stats: stats, locale: locale),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceBetween,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _tick(maxY),
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.outlineLight, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(horizontalLines: [
                if (goalMl != null && goalMl! > 0)
                  HorizontalLine(
                    y: goalMl!.toDouble(),
                    color: AppColors.textSecondaryLight,
                    strokeWidth: 1,
                    dashArray: [5, 4],
                  ),
              ]),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: _tick(maxY),
                    getTitlesWidget: (v, _) => Text(
                        NumberFormat.decimalPattern(locale).format(v.round()),
                        style: axis),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if ((days - 1 - i) % step != 0) return const SizedBox.shrink();
                      return Text(DateFormat('dd/MM', locale).format(dayAt(i)),
                          style: axis);
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchCallback: (event, response) {
                  final i = response?.spot?.touchedBarGroupIndex;
                  if (i != null && event is FlTapUpEvent && onDayTap != null) {
                    onDayTap!(dayAt(i));
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceLight,
                  tooltipBorder: const BorderSide(color: AppColors.outlineLight),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, _, __, ___) {
                    final day = dayAt(group.x);
                    final ml = water[day];
                    return BarTooltipItem(
                      '${DateFormat('dd/MM', locale).format(day)}\n'
                      '${ml == null ? l10n.gxNoRecord : formatMl(ml, locale)}',
                      GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.textPrimaryLight,
                      ),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < days; i++)
                  BarChartGroupData(x: i, barRods: [
                    water[dayAt(i)] != null
                        ? BarChartRodData(
                            toY: water[dayAt(i)]!.toDouble(),
                            width: days <= 7 ? 22 : 6,
                            color: selected != null &&
                                    DateUtils.isSameDay(selected, dayAt(i))
                                ? AppColors.dualisNavy
                                : ChartTokens.water,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3)),
                          )
                        : BarChartRodData(
                            toY: maxY * 0.012,
                            width: days <= 7 ? 12 : 5,
                            color: AppColors.outlineLight,
                            borderRadius: BorderRadius.zero,
                          ),
                  ]),
              ],
            ),
          ),
        ),
        if (inPeriod(today, start, days)) ...[
          const SizedBox(height: 6),
          Text(l10n.gxTodayInProgress, style: chartCaptionStyle),
        ],
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  final WaterPeriodStats stats;
  final String locale;

  const _StatGrid({required this.stats, required this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avg = stats.averageMl;
    final cards = [
      (l10n.gxWaterCardTotal, formatLiters(stats.totalMl, locale)),
      (l10n.gxWaterCardDays, l10n.gxOfN(stats.daysWithRecord, stats.periodDays)),
      (l10n.gxWaterCardAverage, avg == null ? '—' : formatLiters(avg, locale)),
      if (stats.goalMl != null)
        (l10n.gxWaterCardGoal, l10n.gxOfN(stats.daysReachedGoal, stats.daysWithRecord)),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, value) in cards)
            Container(
              width: width,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: chartCaptionStyle.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
        ],
      );
    });
  }
}

/// H4: volume of each day, a small bar towards the chosen goal (capped at
/// 100%; the number keeps any excess). Tapping a day opens it in H1/H2.
class WaterCalendar extends StatelessWidget {
  final Map<DateTime, int> totals;
  final DateTime start;
  final int days;
  final int? goalMl;
  final DateTime? selected;
  final ValueChanged<DateTime> onDayTap;

  const WaterCalendar({
    super.key,
    required this.totals,
    required this.start,
    required this.days,
    required this.goalMl,
    required this.onDayTap,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final water = normalizeWaterTotals(totals);
    return PeriodCalendar(
      keyPrefix: 'water',
      start: start,
      days: days,
      cellHeight: 62,
      selected: selected,
      onDayTap: onDayTap,
      cellBuilder: (context, day) {
        final ml = water[DateTime(day.year, day.month, day.day)];
        if (ml == null) {
          return Center(
            child: Text(
              l10n.gxNoRecord,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5,
                color: AppColors.textSecondaryLight,
              ),
            ),
          );
        }
        final percent = goalPercent(ml, goalMl);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              child: Text(
                formatLiters(ml, locale),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            if (percent != null) ...[
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: math.min(percent / 100, 1),
                  minHeight: 4,
                  backgroundColor: ChartTokens.waterTrack,
                  valueColor: const AlwaysStoppedAnimation(ChartTokens.water),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(
                  '$percent%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
