import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../hydration/presentation/controllers/hydration_controller.dart';
import '../../domain/chart_data.dart';
import 'chart_tokens.dart';
import 'period_calendar.dart';
import 'record_series_chart.dart' show chartCaptionStyle, describeRecord;
import 'water_charts.dart' show formatLiters, formatMl, goalPercent;

/// C1: one cell per day with three areas in fixed order: head (emotions),
/// figure (body), drop (water). Head and figure grow with the reported
/// intensity (area ∝ intensity) and always carry the number; the drop has a
/// fixed size and the litres of the day. Several records stay separate: the
/// first one is drawn and "+N" says how many more; the day sheet lists all.
class CombinedCalendar extends StatelessWidget {
  final Map<DateTime, CalendarDay> days;
  final DateTime start;
  final int periodDays;
  final int? goalMl;

  const CombinedCalendar({
    super.key,
    required this.days,
    required this.start,
    required this.periodDays,
    required this.goalMl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Legend(),
        const SizedBox(height: 10),
        PeriodCalendar(
          keyPrefix: 'combined',
          start: start,
          days: periodDays,
          cellHeight: 88,
          onDayTap: (day) => showCalendarDaySheet(
            context,
            day: days[day] ?? CalendarDay(day: day),
            goalMl: goalMl,
          ),
          cellBuilder: (context, day) {
            final data = days[day];
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _VerticalRow(
                  points: data?.emotional ?? const [],
                  icon: (p, size) => HeadProfileIcon(
                    size: size,
                    color: ChartTokens.time(p.series),
                  ),
                  color: (p) => ChartTokens.time(p.series),
                ),
                _VerticalRow(
                  points: data?.physical ?? const [],
                  icon: (p, size) =>
                      BodyFigureIcon(size: size, color: ChartTokens.body),
                  color: (_) => ChartTokens.body,
                ),
                _WaterRow(ml: data?.waterMl, locale: locale),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(l10n.gxCalendarCaption, style: chartCaptionStyle),
      ],
    );
  }
}

/// Linear size for an icon whose area is proportional to [intensity].
double intensityIconSize(int intensity, {double maxSize = 18}) =>
    maxSize / math.sqrt(5) * math.sqrt(intensity.clamp(1, 5));

class _VerticalRow extends StatelessWidget {
  final List<RecordPoint> points;
  final Widget Function(RecordPoint p, double size) icon;
  final Color Function(RecordPoint p) color;

  const _VerticalRow({
    required this.points,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 8.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondaryLight,
    );
    if (points.isEmpty) {
      return SizedBox(height: 20, child: Center(child: Text('—', style: style)));
    }
    final first = points.first;
    final intensity = first.intensity;
    return SizedBox(
      height: 20,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: intensity == null
                    ? Opacity(
                        opacity: 0.45,
                        child: icon(first, intensityIconSize(3)),
                      )
                    : icon(first, intensityIconSize(intensity)),
              ),
            ),
            const SizedBox(width: 1),
            Semantics(
              label: intensity == null
                  ? l10n.gxIntensityNotInformed
                  : l10n.gxIntensityValue(intensity),
              excludeSemantics: true,
              child: Text(
                intensity?.toString() ?? '–',
                style: style.copyWith(color: color(first)),
              ),
            ),
            if (points.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 1),
                child: Text('+${points.length - 1}', style: style),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaterRow extends StatelessWidget {
  final int? ml;
  final String locale;

  const _WaterRow({required this.ml, required this.locale});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 8.5,
      fontWeight: FontWeight.w700,
      color: ml == null ? AppColors.textSecondaryLight : ChartTokens.water,
    );
    if (ml == null) {
      return SizedBox(height: 20, child: Center(child: Text('—', style: style)));
    }
    return SizedBox(
      height: 20,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.water_drop_rounded, size: 12, color: ChartTokens.water),
            Text(formatLiters(ml!, locale), style: style),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      color: AppColors.textPrimaryLight,
    );
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeadProfileIcon(size: 14, color: c),
            const SizedBox(width: 4),
            Text(label, style: style),
          ],
        );
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        dot(ChartTokens.passado, seriesLabel(l10n, 'passado')),
        dot(ChartTokens.presente, seriesLabel(l10n, 'presente')),
        dot(ChartTokens.futuro, seriesLabel(l10n, 'futuro')),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const BodyFigureIcon(size: 14, color: ChartTokens.body),
          const SizedBox(width: 4),
          Text(l10n.gxTabBody, style: style),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.water_drop_rounded, size: 14, color: ChartTokens.water),
          const SizedBox(width: 4),
          Text(l10n.gxWaterLogged, style: style),
        ]),
      ],
    );
  }
}

/// Neutral head in profile: no face, no expression.
class HeadProfileIcon extends StatelessWidget {
  final double size;
  final Color color;
  const HeadProfileIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _HeadPainter(color),
      );
}

class _HeadPainter extends CustomPainter {
  final Color color;
  _HeadPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final path = Path()
      ..moveTo(w * 0.30, h)
      ..lineTo(w * 0.30, h * 0.78)
      ..cubicTo(w * 0.08, h * 0.68, w * 0.05, h * 0.40, w * 0.15, h * 0.22)
      ..cubicTo(w * 0.28, h * 0.02, w * 0.62, h * -0.02, w * 0.78, h * 0.16)
      ..cubicTo(w * 0.86, h * 0.26, w * 0.86, h * 0.36, w * 0.86, h * 0.42)
      // Nose.
      ..lineTo(w * 0.97, h * 0.58)
      ..lineTo(w * 0.86, h * 0.62)
      ..lineTo(w * 0.86, h * 0.74)
      ..cubicTo(w * 0.86, h * 0.80, w * 0.80, h * 0.82, w * 0.70, h * 0.82)
      ..lineTo(w * 0.70, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HeadPainter old) => old.color != color;
}

/// Neutral full-body figure.
class BodyFigureIcon extends StatelessWidget {
  final double size;
  final Color color;
  const BodyFigureIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _FigurePainter(color),
      );
}

class _FigurePainter extends CustomPainter {
  final Color color;
  _FigurePainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final fill = Paint()..color = color;
    canvas.drawCircle(Offset(w * 0.5, h * 0.11), h * 0.11, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.33, h * 0.24, w * 0.34, h * 0.38),
        Radius.circular(w * 0.08),
      ),
      fill,
    );
    final limb = Paint()
      ..color = color
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.30, h * 0.30), Offset(w * 0.18, h * 0.58), limb);
    canvas.drawLine(Offset(w * 0.70, h * 0.30), Offset(w * 0.82, h * 0.58), limb);
    canvas.drawLine(Offset(w * 0.42, h * 0.62), Offset(w * 0.40, h * 0.94), limb);
    canvas.drawLine(Offset(w * 0.58, h * 0.62), Offset(w * 0.60, h * 0.94), limb);
  }

  @override
  bool shouldRepaint(covariant _FigurePainter old) => old.color != color;
}

/// Everything recorded on one day: emotional choices, body marks and water
/// events, each with its time. Same date never means the items are related.
Future<void> showCalendarDaySheet(
  BuildContext context, {
  required CalendarDay day,
  required int? goalMl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceLight,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          CalendarDayView(day: day, goalMl: goalMl, controller: controller),
    ),
  );
}

class CalendarDayView extends ConsumerWidget {
  final CalendarDay day;
  final int? goalMl;
  final ScrollController? controller;

  const CalendarDayView({
    super.key,
    required this.day,
    required this.goalMl,
    this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryLight,
    );
    final body = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      height: 1.4,
      color: AppColors.textPrimaryLight,
    );
    Widget item(RecordPoint p, Color color) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Text(describeRecord(l10n, locale, p), style: body),
        );
    final logs = day.waterMl == null
        ? null
        : ref.watch(waterLogsForDayProvider(day.day));
    return ListView(
      key: Key('calendar_day_${DateFormat('yyyyMMdd').format(day.day)}'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text(
          l10n.gxDayDetailTitle(DateFormat.yMMMMd(locale).format(day.day)),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        if (day.isEmpty) Text(l10n.gxDayNothing, style: body),
        if (day.emotional.isNotEmpty) ...[
          Text(l10n.gxTabEmotions, style: title),
          const SizedBox(height: 8),
          for (final p in day.emotional) item(p, ChartTokens.time(p.series)),
          const SizedBox(height: 8),
        ],
        if (day.physical.isNotEmpty) ...[
          Text(l10n.gxTabBody, style: title),
          const SizedBox(height: 8),
          for (final p in day.physical) item(p, ChartTokens.region(p.series)),
          const SizedBox(height: 8),
        ],
        if (day.waterMl != null) ...[
          Text(l10n.gxWaterLogged, style: title),
          const SizedBox(height: 4),
          Text(
            [
              formatMl(day.waterMl!, locale),
              if (goalPercent(day.waterMl!, goalMl) != null)
                l10n.gxGoalPercent(goalPercent(day.waterMl!, goalMl)!, goalMl!),
            ].join(' · '),
            style: body,
          ),
          const SizedBox(height: 6),
          ...?logs?.whenOrNull(
            data: (list) => [
              for (final log in list)
                Text(
                  '${DateFormat.Hm(locale).format(log.timestamp.toLocal())} · +${formatMl(log.amountMl, locale)}',
                  style: chartCaptionStyle,
                ),
            ],
          ),
        ],
        if (!day.isEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.gxSameDayNote, style: chartCaptionStyle),
        ],
      ],
    );
  }
}
