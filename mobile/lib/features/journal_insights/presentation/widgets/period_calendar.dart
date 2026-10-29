import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chart_data.dart';

/// Monday-first grid of the weeks covering the period (C1, H4). Days outside
/// the period are greyed out and labelled, so they never read as empty days.
class PeriodCalendar extends StatelessWidget {
  final DateTime start;
  final int days;
  final double cellHeight;
  final DateTime? selected;
  final Widget Function(BuildContext context, DateTime day) cellBuilder;
  final ValueChanged<DateTime>? onDayTap;
  final String keyPrefix;

  const PeriodCalendar({
    super.key,
    required this.start,
    required this.days,
    required this.cellBuilder,
    required this.keyPrefix,
    this.cellHeight = 84,
    this.selected,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weeks = calendarWeeks(start, days);
    final end = DateTime(start.year, start.month, start.day + days - 1);
    final small = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondaryLight,
    );
    return Column(
      key: Key('${keyPrefix}_calendar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.gxPeriodRange(
            DateFormat('dd/MM/yyyy', locale).format(start),
            DateFormat('dd/MM/yyyy', locale).format(end),
          ),
          style: small.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final d in weeks.first)
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat.E(locale).format(d).replaceAll('.', '').toUpperCase(),
                    style: small,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (final week in weeks)
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: SizedBox(
                      height: cellHeight,
                      child: inPeriod(day, start, days)
                          ? _DayCell(
                              key: Key('${keyPrefix}_day_${DateFormat('yyyyMMdd').format(day)}'),
                              day: day,
                              selected: selected != null &&
                                  DateUtils.isSameDay(selected, day),
                              onTap: onDayTap == null ? null : () => onDayTap!(day),
                              child: cellBuilder(context, day),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: AppColors.outlineLight.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(2),
                              child: Semantics(
                                label: l10n.gxOutOfPeriod,
                                child: Text(
                                  '${day.day}',
                                  style: small.copyWith(
                                    color: AppColors.textSecondaryLight
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  const _DayCell({
    super.key,
    required this.day,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.clinicalTeal : AppColors.outlineLight,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${day.day}'.padLeft(2, '0'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
