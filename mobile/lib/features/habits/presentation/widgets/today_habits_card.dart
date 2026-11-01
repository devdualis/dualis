import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/habits_controller.dart';
import '../../domain/models/habit_day.dart';

class TodayHabitsCard extends ConsumerWidget {
  const TodayHabitsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsState = ref.watch(habitsControllerProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = habitsState.todayHabit;

    return Container(
      key: const Key('home_habits_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.clinicalTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.clinicalTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.habitsTitleToday,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      today.isEmpty
                          ? l10n.habitsNoRecordsToday
                          : _summaryText(today, l10n),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                key: const Key('home_habits_register_button'),
                onPressed: () => context.push(RoutePaths.habits),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.habitsRegisterAction,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!today.isEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (today.sleepQuality != null)
                  _TagChip(
                    icon: Icons.nightlight_round,
                    label: _sleepLabel(today, l10n),
                  ),
                if (today.moved != null)
                  _TagChip(
                    icon: Icons.directions_walk_rounded,
                    label: _movementLabel(today, l10n),
                  ),
                if (today.period != null)
                  _TagChip(
                    icon: Icons.water_drop_outlined,
                    label: '${l10n.habitsPeriodLabel}: ${today.period == true ? l10n.habitsPeriodYes : l10n.habitsPeriodNo}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _summaryText(HabitDay today, AppLocalizations l10n) {
    final parts = <String>[];
    if (today.sleepQuality != null) {
      parts.add(_sleepLabel(today, l10n));
    }
    if (today.moved != null) {
      parts.add(_movementLabel(today, l10n));
    }
    if (today.period != null) {
      parts.add('${l10n.habitsPeriodLabel}: ${today.period == true ? l10n.habitsPeriodYes : l10n.habitsPeriodNo}');
    }
    return parts.join(' • ');
  }

  String _sleepLabel(HabitDay today, AppLocalizations l10n) {
    String q;
    switch (today.sleepQuality) {
      case HabitSleepQuality.bem:
        q = l10n.habitsSleepQualityBem;
        break;
      case HabitSleepQuality.regular:
        q = l10n.habitsSleepQualityRegular;
        break;
      case HabitSleepQuality.mal:
        q = l10n.habitsSleepQualityMal;
        break;
      default:
        q = today.sleepQuality ?? '';
    }
    if (today.sleepHours != null) {
      q = '$q (${_hoursLabel(today.sleepHours!, l10n)})';
    }
    return q;
  }

  String _hoursLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case HabitSleepHours.menos5:
        return l10n.habitsSleepHoursMenos5;
      case HabitSleepHours.hours5To6:
        return l10n.habitsSleepHours5To6;
      case HabitSleepHours.hours7To8:
        return l10n.habitsSleepHours7To8;
      case HabitSleepHours.hours9Mais:
        return l10n.habitsSleepHours9Mais;
      default:
        return key;
    }
  }

  String _movementLabel(HabitDay today, AppLocalizations l10n) {
    if (today.moved == true) {
      var text = '${l10n.habitsChartMovementTitle}: ${l10n.habitsMovedYes}';
      if (today.movementMinutes != null) {
        text = '$text (${_minutesLabel(today.movementMinutes!, l10n)})';
      }
      return text;
    }
    return '${l10n.habitsChartMovementTitle}: ${l10n.habitsMovedNo}';
  }

  String _minutesLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case HabitMovementMinutes.ate15:
        return l10n.habitsMovementMinutesAte15;
      case HabitMovementMinutes.minutes15To30:
        return l10n.habitsMovementMinutes15To30;
      case HabitMovementMinutes.minutes30To60:
        return l10n.habitsMovementMinutes30To60;
      case HabitMovementMinutes.mais60:
        return l10n.habitsMovementMinutesMais60;
      default:
        return key;
    }
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TagChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.clinicalTealDark),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
