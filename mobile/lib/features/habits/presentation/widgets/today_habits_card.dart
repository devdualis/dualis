import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../hydration/presentation/controllers/hydration_controller.dart';
import '../../../hydration/presentation/screens/hydration_dashboard_screen.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../journal/presentation/journal_marks.dart';
import '../../../../shared/widgets/premium_gradient_icon.dart';
import '../controllers/habits_controller.dart';
import '../../domain/models/habit_day.dart';
import 'movement_modal.dart';
import 'sleep_modal.dart';

// Redesign: brand palette only. Tiles are neutral glass; the accent colours
// only the icon, the done marker and the buttons.
const Color _tileFill = Color(0xBFFFFFFF);
const Color _tileEdge = Color(0x140E3E6C);
const Color _sleepAccent = AppColors.dualisNavy;
const Color _moveAccent = AppColors.dualisNavy;

/// Home "Hábitos de hoje": same shell as the check-in card, with one tile per
/// habit. Sleep and movement are Premium; the Free build shows water and a
/// Premium teaser instead.
class TodayHabitsCard extends ConsumerWidget {
  const TodayHabitsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final premium = ref.watch(premiumProfilesEnabledProvider);
    final waterOn =
        ref.watch(hydrationControllerProvider).settings.trackingEnabled;

    final tiles = <Widget>[
      if (premium) ...[
        const Expanded(child: _SleepTile()),
        const SizedBox(width: 10),
        const Expanded(child: _MovementTile()),
      ],
      if (waterOn) ...[
        if (premium) const SizedBox(width: 10),
        const Expanded(child: _WaterTile()),
      ],
      if (!premium) ...[
        if (waterOn) const SizedBox(width: 10),
        const Expanded(flex: 2, child: _PremiumTeaserTile()),
      ],
    ];

    // Glass card from the app theme (radius 24, translucent fill).
    return Card(
      key: const Key('home_habits_card'),
      margin: EdgeInsets.zero,
      color: isDark ? AppColors.surfaceDark : null,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DuotoneIconTile(
                  child: premium
                      ? const PremiumGradientIcon(
                          icon: Icon(
                            Icons.wb_twilight_rounded,
                            color: AppColors.dualisNavy,
                            size: 24,
                          ),
                        )
                      : const Icon(
                          Icons.wb_twilight_rounded,
                          color: AppColors.dualisNavy,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.habitsHomeEyebrow,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: AppColors.clinicalTeal,
                        ),
                      ),
                      Text(
                        l10n.habitsTitleToday,
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          letterSpacing: -0.3,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: AppColors.dualisNavy.withValues(alpha: 0.08)),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: tiles,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTile extends ConsumerWidget {
  const _SleepTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(habitsControllerProvider).todayHabit;
    final viewOnly = activeProfileIsViewOnly(ref);
    final done = today.sleepQuality != null;
    final hours = today.sleepHours;
    final sleepEmoji = done
        ? JournalMarks.box(today.sleepQuality!, size: 22, sleep: true)
        : null;

    return _HabitTile(
      key: const Key('home_habit_tile_sleep'),
      premiumIcon: ref.watch(premiumProfilesEnabledProvider),
      accent: _sleepAccent,
      icon: Icons.bedtime_rounded,
      title: l10n.habitsTileSleep,
      done: done,
      doneLabel: l10n.habitsSaved,
      onTap: () => SleepModal.show(context),
      value: done
          ? [
              sleepQualityLabel(today.sleepQuality!, l10n),
              if (hours != null) _compactSleepHours(hours),
            ].join('\n')
          : l10n.habitsTileSleepPending,
      valueLeading: sleepEmoji,
      action: _TilePill(
        key: const Key('home_habit_sleep_action'),
        label: done ? l10n.habitsTileEdit : l10n.habitsTileAnswer,
        color: _sleepAccent,
        onTap: viewOnly
            ? null
            : () => SleepModal.show(context),
      ),
    );
  }
}

class _MovementTile extends ConsumerWidget {
  const _MovementTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(habitsControllerProvider.notifier);
    final today = ref.watch(habitsControllerProvider).todayHabit;
    final viewOnly = activeProfileIsViewOnly(ref);
    final moved = today.moved;

    String value;
    if (moved == null) {
      value = l10n.habitsTileMovedPending;
    } else if (moved) {
      final minutes = today.movementMinutes;
      value = minutes == null
          ? l10n.habitsTileMovedYesValue
          : '${l10n.habitsTileMovedYesValue}\n${movementMinutesLabel(minutes, l10n)}';
    } else {
      value = l10n.habitsTileMovedNoValue;
    }

    void answer(bool yes) => controller.saveAnswer(
          day: controller.todayDayString,
          moved: yes,
        );

    return _HabitTile(
      key: const Key('home_habit_tile_movement'),
      premiumIcon: ref.watch(premiumProfilesEnabledProvider),
      accent: _moveAccent,
      icon: Icons.directions_walk_rounded,
      title: l10n.habitsTileMovement,
      done: moved != null,
      doneLabel: l10n.habitsSaved,
      onTap: () => MovementModal.show(context),
      value: value,
      action: moved == null
          ? Row(
              children: [
                Expanded(
                  child: _TilePill(
                    key: const Key('home_habit_moved_yes'),
                    label: l10n.habitsMovedYes,
                    color: _moveAccent,
                    onTap: viewOnly ? null : () => answer(true),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TilePill(
                    key: const Key('home_habit_moved_no'),
                    label: l10n.habitsMovedNo,
                    color: _moveAccent,
                    onTap: viewOnly ? null : () => answer(false),
                  ),
                ),
              ],
            )
          : _TilePill(
              key: const Key('home_habit_movement_action'),
              label: l10n.habitsTileEdit,
              color: _moveAccent,
              onTap: viewOnly
                  ? null
                  : () => MovementModal.show(context),
            ),
    );
  }
}

class _WaterTile extends ConsumerWidget {
  const _WaterTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final water = ref.watch(hydrationControllerProvider);
    final viewOnly = activeProfileIsViewOnly(ref);

    return _HabitTile(
      key: const Key('home_habit_tile_water'),
      premiumIcon: ref.watch(premiumProfilesEnabledProvider),
      accent: AppColors.clinicalTeal,
      icon: Icons.water_drop_rounded,
      title: l10n.navHydration,
      done: water.isGoalReached,
      doneLabel: '${water.progressPercent}%',
      onTap: () => context.push(RoutePaths.hydration),
      value: '${water.todayTotalMl} ml',
      valueCaption: '/ ${water.dailyTargetMl} ml',
      extra: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: water.progressRatio.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: AppColors.dualisNavy.withValues(alpha: 0.08),
          color: AppColors.clinicalTeal,
        ),
      ),
      action: _TilePill(
        key: const Key('home_habit_water_add'),
        label: '+200 ml',
        color: AppColors.dualisNavy,
        filled: true,
        onTap: viewOnly ? null : () => logWaterWithUndo(context, ref, 200),
      ),
    );
  }
}

/// Free build: what Premium adds to habits, opens the promo.
class _PremiumTeaserTile extends StatelessWidget {
  const _PremiumTeaserTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      key: const Key('home_habits_premium_teaser'),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(gradient: AppColors.gradientNavy),
        child: InkWell(
          onTap: () => context.push(RoutePaths.premiumPromo),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bedtime_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 4),
                    const Icon(Icons.directions_walk_rounded, size: 18, color: Colors.white),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dualisSymbolGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.habitsPremiumTeaserTitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.habitsPremiumTeaserBody,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFE0F4FB),
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.habitsPremiumTeaserCta,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dualisNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One habit as a neutral glass tile: duotone icon square, title, value and
/// one action pill.
class _HabitTile extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String value;
  final String? valueCaption;

  /// Optional Fluent emoji shown before [value] (sleep quality).
  final Widget? valueLeading;
  final bool done;
  final String doneLabel;
  final Widget? extra;
  final Widget action;
  final VoidCallback onTap;

  /// Premium build: the tile icon gets the teal gradient.
  final bool premiumIcon;

  const _HabitTile({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.value,
    required this.done,
    required this.doneLabel,
    required this.action,
    required this.onTap,
    this.extra,
    this.valueCaption,
    this.valueLeading,
    this.premiumIcon = false,
  });

  Widget _valueText() => Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: AppColors.dualisNavy,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _tileFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _tileEdge),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DuotoneIconTile(
                    size: 32,
                    radius: 10,
                    child: premiumIcon
                        ? PremiumGradientIcon(icon: Icon(icon, color: accent, size: 18))
                        : Icon(icon, color: accent, size: 18),
                  ),
                  const Spacer(),
                  if (done)
                    Icon(Icons.check_circle_rounded, size: 16, color: accent),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              if (valueLeading != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    valueLeading!,
                    const SizedBox(width: 6),
                    Expanded(child: _valueText()),
                  ],
                )
              else
                _valueText(),
              if (valueCaption != null)
                Text(
                  valueCaption!,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              if (extra != null) ...[
                const SizedBox(height: 8),
                extra!,
              ],
              const Spacer(),
              const SizedBox(height: 10),
              action,
            ],
          ),
        ),
      ),
    );
  }
}

class _TilePill extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _TilePill({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: filled ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: (filled ? Colors.white : color)
                  .withValues(alpha: enabled ? 1 : 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

String sleepQualityLabel(String key, AppLocalizations l10n) {
  switch (key) {
    case HabitSleepQuality.bem:
      return l10n.habitsSleepQualityBem;
    case HabitSleepQuality.regular:
      return l10n.habitsSleepQualityRegular;
    case HabitSleepQuality.mal:
      return l10n.habitsSleepQualityMal;
    default:
      return key;
  }
}

String movementMinutesLabel(String key, AppLocalizations l10n) {
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

/// Short hours for the narrow home tile ("Menos de 5 h" breaks badly there).
String _compactSleepHours(String key) {
  switch (key) {
    case HabitSleepHours.menos5:
      return '< 5 h';
    case HabitSleepHours.hours5To6:
      return '5–6 h';
    case HabitSleepHours.hours7To8:
      return '7–8 h';
    case HabitSleepHours.hours9Mais:
      return '9+ h';
    default:
      return key;
  }
}
