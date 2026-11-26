import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/fluent_emoji.dart';
import '../../../journal/presentation/journal_marks.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/load_error_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../journal_insights/presentation/widgets/history_widgets.dart';
import '../../../profile/domain/models/share_category.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../../profile/presentation/widgets/not_shared_placeholder.dart';
import '../controllers/habits_controller.dart';
import '../widgets/habits_water_summary_card.dart';
import '../widgets/movement_modal.dart';
import '../widgets/sleep_modal.dart';
import '../../domain/models/habit_day.dart';

/// Screen "Hábitos de hoje" (docs/bienestar/CONTRATO-JOURNAL-V2.md section 6).
/// One question per card, big emoji buttons, few options, same visual style
/// as journal and hydration screens. Focuses on today's habits.
/// Saves each answer at once.
class HabitsScreen extends ConsumerStatefulWidget {
  /// True inside the Premium "Hábitos" tab: no app bar, water summary on top.
  final bool isEmbedded;

  /// Optional initial habit card to focus ('sleep' or 'movement').
  final String? targetHabit;

  const HabitsScreen({
    super.key,
    this.isEmbedded = false,
    this.targetHabit,
  });

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  final _sleepCardKey = GlobalKey();
  final _movementCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.targetHabit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.targetHabit == 'sleep') {
          SleepModal.show(context);
        } else if (widget.targetHabit == 'movement') {
          MovementModal.show(context);
        } else {
          _scrollToTarget(widget.targetHabit!);
        }
      });
    }
  }

  void _scrollToTarget(String target) {
    final ctx = target == 'movement'
        ? _movementCardKey.currentContext
        : _sleepCardKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(habitsControllerProvider);
    final controller = ref.read(habitsControllerProvider.notifier);
    final canRead = activeProfileCanRead(ref, ShareCategory.habits);
    final viewOnly =
        activeProfileIsViewOnly(ref) ||
        !activeProfileCanWrite(ref, ShareCategory.habits);
    final activeProfile =
        ref.watch(activeProfileControllerProvider).activeProfile;
    final user = ref.watch(authControllerProvider).user;
    final isMale =
        (activeProfile?.gender ?? user?.gender.value)?.toLowerCase() ==
        'masculino';
    ref.listen<Object?>(habitsControllerProvider.select((s) => s.saveError), (
      _,
      error,
    ) {
      if (error != null) showSaveFailedSnackBar(context);
    });

    final activeDayString = controller.todayDayString;
    final activeHabit = state.todayHabit;

    final body =
        !canRead
            ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ActiveProfileBanner(),
                Expanded(
                  child: NotSharedPlaceholder(
                    profileName: activeProfile?.name ?? '',
                  ),
                ),
              ],
            )
            : state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.loadError != null
            ? LoadErrorView(
              error: state.loadError!,
              onRetry: () => controller.loadData(),
            )
            : RefreshIndicator(
              onRefresh: () => controller.loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ActiveProfileBanner(),
                    if (viewOnly) const ActiveProfileReadOnlyNote(),
                    const SizedBox(height: 8),

                    // Card 1: Sleep Quality & Hours
                    KeyedSubtree(
                      key: _sleepCardKey,
                      child: _SleepCard(
                        dayString: activeDayString,
                        habit: activeHabit,
                        controller: controller,
                        l10n: l10n,
                        viewOnly: viewOnly,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Movement & Minutes
                    KeyedSubtree(
                      key: _movementCardKey,
                      child: _MovementCard(
                        dayString: activeDayString,
                        habit: activeHabit,
                        controller: controller,
                        l10n: l10n,
                        viewOnly: viewOnly,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!isMale) ...[
                      // Setting: Track Menstrual Cycle switch
                      _CycleSettingTile(
                        enabled: state.trackMenstrualCycle,
                        title: l10n.habitsTrackMenstrualCycleSetting,
                        onChanged:
                            viewOnly
                                ? null
                                : (val) =>
                                    controller.setTrackMenstrualCycle(val),
                      ),
                      const SizedBox(height: 16),

                      // Card 3: Menstrual Cycle (Period)
                      // Shown only when setting is on OR period = true in last 60 days
                      if (state.showPeriodCard) ...[
                        _PeriodCard(
                          dayString: activeDayString,
                          habit: activeHabit,
                          controller: controller,
                          l10n: l10n,
                          viewOnly: viewOnly,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],

                    // Premium tab: water lives here too (today only).
                    if (widget.isEmbedded) ...[
                      const HabitsWaterSummaryCard(),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );

    if (widget.isEmbedded) return body;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.habitsTitleToday,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        actions: const [
          // Space for the global urgent-help button (UrgentHelpOverlay).
          SizedBox(width: 56),
        ],
      ),
      body: body,
    );
  }
}

class _SleepCard extends StatelessWidget {
  final String dayString;
  final HabitDay habit;
  final HabitsController controller;
  final AppLocalizations l10n;
  final bool viewOnly;

  const _SleepCard({
    required this.dayString,
    required this.habit,
    required this.controller,
    required this.l10n,
    required this.viewOnly,
  });

  @override
  Widget build(BuildContext context) {
    return _QuestionCard(
      title: l10n.habitsSleepQualityQuestion,
      titleKey: const Key('habits_sleep_question'),
      icon: Icons.bedtime_rounded,
      saved: habit.sleepQuality != null,
      savedLabel: l10n.habitsSaved,
      children: [
        // 3 Big Emoji buttons, same height even when a label wraps.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _EmojiOptionButton(
                  key: const Key('habits_sleep_bem'),
                  sleepKey: HabitSleepQuality.bem,
                  emoji: '😴',
                  label: l10n.habitsSleepQualityBem.replaceFirst('😴 ', ''),
                  selected: habit.sleepQuality == HabitSleepQuality.bem,
                  onTap:
                      viewOnly
                          ? null
                          : () => controller.saveAnswer(
                            day: dayString,
                            sleepQuality: HabitSleepQuality.bem,
                          ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EmojiOptionButton(
                  key: const Key('habits_sleep_regular'),
                  sleepKey: HabitSleepQuality.regular,
                  emoji: '😐',
                  label: l10n.habitsSleepQualityRegular.replaceFirst('😐 ', ''),
                  selected: habit.sleepQuality == HabitSleepQuality.regular,
                  onTap:
                      viewOnly
                          ? null
                          : () => controller.saveAnswer(
                            day: dayString,
                            sleepQuality: HabitSleepQuality.regular,
                          ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EmojiOptionButton(
                  key: const Key('habits_sleep_mal'),
                  sleepKey: HabitSleepQuality.mal,
                  emoji: '😫',
                  label: l10n.habitsSleepQualityMal.replaceFirst('😫 ', ''),
                  selected: habit.sleepQuality == HabitSleepQuality.mal,
                  onTap:
                      viewOnly
                          ? null
                          : () => controller.saveAnswer(
                            day: dayString,
                            sleepQuality: HabitSleepQuality.mal,
                          ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.habitsSleepHoursQuestion,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChipOption(
              key: const Key('habits_hours_menos_5'),
              label: l10n.habitsSleepHoursMenos5,
              selected: habit.sleepHours == HabitSleepHours.menos5,
              onSelected:
                  viewOnly
                      ? null
                      : (s) => controller.saveAnswer(
                        day: dayString,
                        sleepHours: HabitSleepHours.menos5,
                      ),
            ),
            _ChipOption(
              key: const Key('habits_hours_5_6'),
              label: l10n.habitsSleepHours5To6,
              selected: habit.sleepHours == HabitSleepHours.hours5To6,
              onSelected:
                  viewOnly
                      ? null
                      : (s) => controller.saveAnswer(
                        day: dayString,
                        sleepHours: HabitSleepHours.hours5To6,
                      ),
            ),
            _ChipOption(
              key: const Key('habits_hours_7_8'),
              label: l10n.habitsSleepHours7To8,
              selected: habit.sleepHours == HabitSleepHours.hours7To8,
              onSelected:
                  viewOnly
                      ? null
                      : (s) => controller.saveAnswer(
                        day: dayString,
                        sleepHours: HabitSleepHours.hours7To8,
                      ),
            ),
            _ChipOption(
              key: const Key('habits_hours_9_mais'),
              label: l10n.habitsSleepHours9Mais,
              selected: habit.sleepHours == HabitSleepHours.hours9Mais,
              onSelected:
                  viewOnly
                      ? null
                      : (s) => controller.saveAnswer(
                        day: dayString,
                        sleepHours: HabitSleepHours.hours9Mais,
                      ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MovementCard extends StatelessWidget {
  final String dayString;
  final HabitDay habit;
  final HabitsController controller;
  final AppLocalizations l10n;
  final bool viewOnly;

  const _MovementCard({
    required this.dayString,
    required this.habit,
    required this.controller,
    required this.l10n,
    required this.viewOnly,
  });

  @override
  Widget build(BuildContext context) {
    return _QuestionCard(
      title: l10n.habitsMovedQuestion,
      titleKey: const Key('habits_moved_question'),
      icon: Icons.directions_walk_rounded,
      saved: habit.moved != null,
      savedLabel: l10n.habitsSaved,
      children: [
        Row(
          children: [
            Expanded(
              child: _YesNoButton(
                key: const Key('habits_moved_sim'),
                label: l10n.habitsMovedYes,
                selected: habit.moved == true,
                onTap:
                    viewOnly
                        ? null
                        : () =>
                            controller.saveAnswer(day: dayString, moved: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _YesNoButton(
                key: const Key('habits_moved_nao'),
                label: l10n.habitsMovedNo,
                selected: habit.moved == false,
                onTap:
                    viewOnly
                        ? null
                        : () => controller.saveAnswer(
                          day: dayString,
                          moved: false,
                          clearMovementMinutes: true,
                        ),
              ),
            ),
          ],
        ),
        if (habit.moved == true) ...[
          const SizedBox(height: 16),
          Text(
            l10n.habitsMovementMinutesQuestion,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipOption(
                key: const Key('habits_minutes_ate_15'),
                label: l10n.habitsMovementMinutesAte15,
                selected: habit.movementMinutes == HabitMovementMinutes.ate15,
                onSelected:
                    viewOnly
                        ? null
                        : (s) => controller.saveAnswer(
                          day: dayString,
                          movementMinutes: HabitMovementMinutes.ate15,
                        ),
              ),
              _ChipOption(
                key: const Key('habits_minutes_15_30'),
                label: l10n.habitsMovementMinutes15To30,
                selected:
                    habit.movementMinutes == HabitMovementMinutes.minutes15To30,
                onSelected:
                    viewOnly
                        ? null
                        : (s) => controller.saveAnswer(
                          day: dayString,
                          movementMinutes: HabitMovementMinutes.minutes15To30,
                        ),
              ),
              _ChipOption(
                key: const Key('habits_minutes_30_60'),
                label: l10n.habitsMovementMinutes30To60,
                selected:
                    habit.movementMinutes == HabitMovementMinutes.minutes30To60,
                onSelected:
                    viewOnly
                        ? null
                        : (s) => controller.saveAnswer(
                          day: dayString,
                          movementMinutes: HabitMovementMinutes.minutes30To60,
                        ),
              ),
              _ChipOption(
                key: const Key('habits_minutes_mais_60'),
                label: l10n.habitsMovementMinutesMais60,
                selected: habit.movementMinutes == HabitMovementMinutes.mais60,
                onSelected:
                    viewOnly
                        ? null
                        : (s) => controller.saveAnswer(
                          day: dayString,
                          movementMinutes: HabitMovementMinutes.mais60,
                        ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final String dayString;
  final HabitDay habit;
  final HabitsController controller;
  final AppLocalizations l10n;
  final bool viewOnly;

  const _PeriodCard({
    required this.dayString,
    required this.habit,
    required this.controller,
    required this.l10n,
    required this.viewOnly,
  });

  @override
  Widget build(BuildContext context) {
    return _QuestionCard(
      key: const Key('habits_period_card'),
      title: l10n.habitsPeriodQuestion,
      titleKey: const Key('habits_period_question'),
      icon: Icons.event_repeat_rounded,
      saved: habit.period != null,
      savedLabel: l10n.habitsSaved,
      children: [
        Row(
          children: [
            Expanded(
              child: _YesNoButton(
                key: const Key('habits_period_sim'),
                label: l10n.habitsPeriodYes,
                selected: habit.period == true,
                onTap:
                    viewOnly
                        ? null
                        : () =>
                            controller.saveAnswer(day: dayString, period: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _YesNoButton(
                key: const Key('habits_period_nao'),
                label: l10n.habitsPeriodNo,
                selected: habit.period == false,
                onTap:
                    viewOnly
                        ? null
                        : () => controller.saveAnswer(
                          day: dayString,
                          period: false,
                        ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CycleSettingTile extends StatelessWidget {
  final bool enabled;
  final String title;
  final ValueChanged<bool>? onChanged;

  const _CycleSettingTile({
    required this.enabled,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          key: const Key('habits_cycle_switch'),
          value: enabled,
          onChanged: onChanged,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          secondary: const DuotoneIconTile(
            size: 32,
            radius: 10,
            child: Icon(
              Icons.event_repeat_rounded,
              size: 18,
              color: AppColors.dualisNavy,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          activeTrackColor: AppColors.dualisNavy,
          activeThumbColor: Colors.white,
        ),
      ),
    );
  }
}

/// One question on a glass card: duotone icon tile, title and the "saved" tag.
class _QuestionCard extends StatelessWidget {
  final String title;
  final Key? titleKey;
  final IconData? icon;
  final List<Widget> children;
  final bool saved;
  final String savedLabel;

  const _QuestionCard({
    super.key,
    required this.title,
    this.titleKey,
    this.icon,
    required this.children,
    this.saved = false,
    this.savedLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                DuotoneIconTile(
                  size: 32,
                  radius: 10,
                  child: Icon(icon, size: 18, color: AppColors.dualisNavy),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  key: titleKey,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              if (saved) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        savedLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// Option surface shared by the sleep, yes/no and chip answers (the check-in
/// wizard option card): soft navy tint, cyan fill and navy border when picked.
class _OptionSurface extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _OptionSurface({
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    const radius = 16.0;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color:
              selected
                  ? AppColors.dualisSymbolCyan.withValues(alpha: 0.14)
                  : AppColors.dualisNavy.withValues(alpha: 0.04),
          border: Border.all(
            color: selected ? AppColors.dualisNavy : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _EmojiOptionButton extends StatelessWidget {
  final String sleepKey;
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _EmojiOptionButton({
    super.key,
    required this.sleepKey,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _OptionSurface(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FluentEmoji.forSleep(
            sleepKey,
            size: 42,
            fallback: ExcludeSemantics(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.dualisNavy,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _YesNoButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _YesNoButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _OptionSurface(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.dualisNavy,
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.dualisNavy,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const _ChipOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      selectedColor: AppColors.dualisSymbolCyan.withValues(alpha: 0.14),
      backgroundColor: AppColors.dualisNavy.withValues(alpha: 0.04),
      side: BorderSide(
        color: selected ? AppColors.dualisNavy : Colors.transparent,
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      labelStyle: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: AppColors.dualisNavy,
      ),
    );
  }
}
