import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/load_error_view.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../controllers/habits_controller.dart';
import '../widgets/habits_water_summary_card.dart';
import '../../domain/models/habit_day.dart';

/// Screen "Hábitos de hoje" (docs/bienestar/CONTRATO-JOURNAL-V2.md section 6).
/// One question per card, big emoji buttons, few options, same visual style
/// as journal and hydration screens.
/// Supports editing yesterday via Hoje/Ontem switch.
/// Saves each answer at once.
class HabitsScreen extends ConsumerStatefulWidget {
  /// True inside the Premium "Hábitos" tab: no app bar, water summary on top.
  final bool isEmbedded;

  const HabitsScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  bool _isYesterday = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(habitsControllerProvider);
    final controller = ref.read(habitsControllerProvider.notifier);
    final viewOnly = activeProfileIsViewOnly(ref);
    final activeProfile = ref.watch(activeProfileControllerProvider).activeProfile;
    final user = ref.watch(authControllerProvider).user;
    final isMale = (activeProfile?.gender ?? user?.gender.value)?.toLowerCase() == 'masculino';
    ref.listen<Object?>(habitsControllerProvider.select((s) => s.saveError),
        (_, error) {
      if (error != null) showSaveFailedSnackBar(context);
    });

    final activeDayString =
        _isYesterday
            ? controller.yesterdayDayString
            : controller.todayDayString;
    final activeHabit = _isYesterday ? state.yesterdayHabit : state.todayHabit;

    final body =
          state.isLoading
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ActiveProfileBanner(),
                      if (viewOnly) const ActiveProfileReadOnlyNote(),
                      const SizedBox(height: 8),
                      // Day switcher: Hoje / Ontem
                      _DaySwitcher(
                        isYesterday: _isYesterday,
                        todayLabel: l10n.habitsTabToday,
                        yesterdayLabel: l10n.habitsTabYesterday,
                        onChanged: (yesterday) {
                          setState(() => _isYesterday = yesterday);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Card 1: Sleep Quality & Hours
                      _SleepCard(
                        dayString: activeDayString,
                        habit: activeHabit,
                        controller: controller,
                        l10n: l10n,
                        viewOnly: viewOnly,
                      ),
                      const SizedBox(height: 16),

                      // Card 2: Movement & Minutes
                      _MovementCard(
                        dayString: activeDayString,
                        habit: activeHabit,
                        controller: controller,
                        l10n: l10n,
                        viewOnly: viewOnly,
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
                      if (widget.isEmbedded && !_isYesterday) ...[
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
          _isYesterday ? l10n.habitsTitleYesterday : l10n.habitsTitleToday,
          style: GoogleFonts.plusJakartaSans(
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

class _DaySwitcher extends StatelessWidget {
  final bool isYesterday;
  final String todayLabel;
  final String yesterdayLabel;
  final ValueChanged<bool> onChanged;

  const _DaySwitcher({
    required this.isYesterday,
    required this.todayLabel,
    required this.yesterdayLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              key: const Key('habits_tab_today'),
              label: todayLabel,
              selected: !isYesterday,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              key: const Key('habits_tab_yesterday'),
              label: yesterdayLabel,
              selected: isYesterday,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.clinicalTeal : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      ),
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
      title: dayString == controller.yesterdayDayString
          ? l10n.habitsSleepQualityQuestionYesterday
          : l10n.habitsSleepQualityQuestion,
      titleKey: const Key('habits_sleep_question'),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
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
      title: dayString == controller.yesterdayDayString
          ? l10n.habitsMovedQuestionYesterday
          : l10n.habitsMovedQuestion,
      titleKey: const Key('habits_moved_question'),
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
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
      title: dayString == controller.yesterdayDayString
          ? l10n.habitsPeriodQuestionYesterday
          : l10n.habitsPeriodQuestion,
      titleKey: const Key('habits_period_question'),
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
    return Material(
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineLight),
      ),
      child: SwitchListTile(
        key: const Key('habits_cycle_switch'),
        value: enabled,
        onChanged: onChanged,
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        activeTrackColor: AppColors.clinicalTeal.withValues(alpha: 0.5),
        activeThumbColor: AppColors.clinicalTeal,
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String title;
  final Key? titleKey;
  final List<Widget> children;
  final bool saved;
  final String savedLabel;

  const _QuestionCard({
    super.key,
    required this.title,
    this.titleKey,
    required this.children,
    this.saved = false,
    this.savedLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  key: titleKey,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              if (saved) ...[
                const SizedBox(width: 8),
                Row(
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
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

class _EmojiOptionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _EmojiOptionButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected
              ? AppColors.clinicalTeal.withValues(alpha: 0.12)
              : AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.clinicalTeal : AppColors.outlineLight,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color:
                      selected
                          ? AppColors.clinicalTealDark
                          : AppColors.textPrimaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
    return Material(
      color:
          selected
              ? AppColors.clinicalTeal.withValues(alpha: 0.12)
              : AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.clinicalTeal : AppColors.outlineLight,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color:
                    selected
                        ? AppColors.clinicalTealDark
                        : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ),
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
      selectedColor: AppColors.clinicalTeal.withValues(alpha: 0.15),
      backgroundColor: AppColors.backgroundLight,
      side: BorderSide(
        color: selected ? AppColors.clinicalTeal : AppColors.outlineLight,
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        color:
            selected ? AppColors.clinicalTealDark : AppColors.textPrimaryLight,
      ),
    );
  }
}
