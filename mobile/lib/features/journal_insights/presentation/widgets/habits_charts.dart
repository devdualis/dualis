import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../habits/domain/models/habit_day.dart';
import '../../domain/chart_data.dart' show inPeriod;
import 'journal_overview_widgets.dart';

/// Charts for daily habits (docs/bienestar/CONTRATO-JOURNAL-V2.md section 6).
/// Free version = 30 days.
/// Texts are counts only (e.g., "Você dormiu mal em 6 dos últimos 30 dias",
/// "Você se mexeu em 12 dias").
/// No goals computed by the app, no advice, no relations between habits and feelings.

// Calm palette for sleep answers: no traffic-light red/amber, which would read as risk.
const Color _sleepRegularColor = Color(0xFF7CC4C9);
const Color _sleepBadColor = Color(0xFF64748B);

class HabitsChartsSection extends StatelessWidget {
  final List<HabitDay> habits;
  final int days;
  final DateTime today;
  final DateTime start;
  final bool showPeriod;

  const HabitsChartsSection({
    super.key,
    required this.habits,
    required this.days,
    required this.today,
    required this.start,
    this.showPeriod = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inWindow = _filterHabitsInWindow(habits, start, days);

    final badSleepCount =
        inWindow.where((h) => h.sleepQuality == HabitSleepQuality.mal).length;
    final movedCount = inWindow.where((h) => h.moved == true).length;
    final periodCount = inWindow.where((h) => h.period == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Sleep Quality & Hours Chart
        InsightsCard(
          title: l10n.habitsChartSleepQualityTitle,
          subtitle: l10n.habitsChartSleepBadCount(badSleepCount, days),
          child: HabitsSleepChart(habits: inWindow, start: start, days: days),
        ),

        // 2. Movement Chart
        InsightsCard(
          title: l10n.habitsChartMovementTitle,
          subtitle: l10n.habitsChartMovementCount(movedCount),
          child: HabitsMovementChart(
            habits: inWindow,
            start: start,
            days: days,
          ),
        ),

        // 3. Period Chart (if enabled or recorded in period)
        if (showPeriod || periodCount > 0)
          InsightsCard(
            title: l10n.habitsChartPeriodTitle,
            subtitle: l10n.habitsChartPeriodCount(periodCount),
            child: HabitsPeriodChart(
              habits: inWindow,
              start: start,
              days: days,
            ),
          ),
      ],
    );
  }

  List<HabitDay> _filterHabitsInWindow(
    List<HabitDay> all,
    DateTime start,
    int days,
  ) {
    return all.where((h) {
      final parsed = DateTime.tryParse(h.day);
      if (parsed == null) return false;
      return inPeriod(parsed, start, days);
    }).toList();
  }
}

class HabitsSleepChart extends StatelessWidget {
  final List<HabitDay> habits;
  final DateTime start;
  final int days;

  const HabitsSleepChart({
    super.key,
    required this.habits,
    required this.start,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final habitMap = <String, HabitDay>{for (final h in habits) h.day: h};

    return Column(
      key: const Key('habits_sleep_chart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SleepLegend(l10n: l10n),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true, // newest first on right, or left-to-right
            itemCount: days,
            itemBuilder: (context, index) {
              final date = start.add(Duration(days: days - 1 - index));
              final dayStr = DateFormat('yyyy-MM-dd').format(date);
              final habit = habitMap[dayStr];
              return _SleepDayBar(date: date, habit: habit, l10n: l10n);
            },
          ),
        ),
      ],
    );
  }
}

class _SleepLegend extends StatelessWidget {
  final AppLocalizations l10n;

  const _SleepLegend({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _LegendDot(
          color: AppColors.clinicalTeal,
          label: l10n.habitsSleepQualityBem,
        ),
        _LegendDot(
          color: _sleepRegularColor,
          label: l10n.habitsSleepQualityRegular,
        ),
        _LegendDot(color: _sleepBadColor, label: l10n.habitsSleepQualityMal),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
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

class _SleepDayBar extends StatelessWidget {
  final DateTime date;
  final HabitDay? habit;
  final AppLocalizations l10n;

  const _SleepDayBar({
    required this.date,
    required this.habit,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    Color barColor;
    double heightFactor;

    switch (habit?.sleepQuality) {
      case HabitSleepQuality.bem:
        barColor = AppColors.clinicalTeal;
        heightFactor = 0.85;
        break;
      case HabitSleepQuality.regular:
        barColor = _sleepRegularColor;
        heightFactor = 0.55;
        break;
      case HabitSleepQuality.mal:
        barColor = _sleepBadColor;
        heightFactor = 0.35;
        break;
      default:
        barColor = AppColors.outlineLight.withValues(alpha: 0.4);
        heightFactor = 0.15;
    }

    final hoursChip = _shortHours(habit?.sleepHours);

    return Container(
      width: 32,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (hoursChip.isNotEmpty)
            Text(
              hoursChip,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryLight,
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 14,
                height: 50 * heightFactor,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${date.day}'.padLeft(2, '0'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  String _shortHours(String? key) {
    switch (key) {
      case HabitSleepHours.menos5:
        return '<5h';
      case HabitSleepHours.hours5To6:
        return '5-6h';
      case HabitSleepHours.hours7To8:
        return '7-8h';
      case HabitSleepHours.hours9Mais:
        return '9h+';
      default:
        return '';
    }
  }
}

class HabitsMovementChart extends StatelessWidget {
  final List<HabitDay> habits;
  final DateTime start;
  final int days;

  const HabitsMovementChart({
    super.key,
    required this.habits,
    required this.start,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final habitMap = <String, HabitDay>{for (final h in habits) h.day: h};

    return Column(
      key: const Key('habits_movement_chart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: days,
            itemBuilder: (context, index) {
              final date = start.add(Duration(days: days - 1 - index));
              final dayStr = DateFormat('yyyy-MM-dd').format(date);
              final habit = habitMap[dayStr];
              final moved = habit?.moved;

              return Container(
                width: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (habit?.movementMinutes != null)
                      Text(
                        _shortMinutes(habit!.movementMinutes!),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.clinicalTealDark,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Center(
                        child:
                            moved == true
                                ? Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppColors.clinicalTeal,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                )
                                : Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color:
                                        moved == false
                                            ? AppColors.outlineLight
                                            : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.outlineLight,
                                    ),
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${date.day}'.padLeft(2, '0'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _shortMinutes(String key) {
    switch (key) {
      case HabitMovementMinutes.ate15:
        return '15m';
      case HabitMovementMinutes.minutes15To30:
        return '30m';
      case HabitMovementMinutes.minutes30To60:
        return '1h';
      case HabitMovementMinutes.mais60:
        return '>1h';
      default:
        return '';
    }
  }
}

class HabitsPeriodChart extends StatelessWidget {
  final List<HabitDay> habits;
  final DateTime start;
  final int days;

  const HabitsPeriodChart({
    super.key,
    required this.habits,
    required this.start,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final habitMap = <String, HabitDay>{for (final h in habits) h.day: h};

    return Column(
      key: const Key('habits_period_chart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: days,
            itemBuilder: (context, index) {
              final date = start.add(Duration(days: days - 1 - index));
              final dayStr = DateFormat('yyyy-MM-dd').format(date);
              final habit = habitMap[dayStr];
              final hasPeriod = habit?.period == true;

              return Container(
                width: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Center(
                        child:
                            hasPeriod
                                ? const Icon(
                                  Icons.water_drop,
                                  size: 18,
                                  color: Color(0xFFEC407A),
                                )
                                : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.outlineLight.withValues(
                                      alpha: 0.5,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${date.day}'.padLeft(2, '0'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color:
                            hasPeriod
                                ? const Color(0xFFEC407A)
                                : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
