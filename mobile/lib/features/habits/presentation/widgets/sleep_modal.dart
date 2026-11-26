import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/domain/models/share_category.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../domain/models/habit_day.dart';
import '../controllers/habits_controller.dart';
import 'habit_option_widgets.dart';

/// Modal bottom sheet exclusively for recording and updating Sleep habits.
class SleepModal extends ConsumerWidget {
  const SleepModal({super.key});

  static Future<void> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const SleepModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(habitsControllerProvider);
    final controller = ref.read(habitsControllerProvider.notifier);
    final dayString = controller.todayDayString;
    final habit = state.todayHabit;
    final viewOnly = activeProfileIsViewOnly(ref) ||
        !activeProfileCanWrite(ref, ShareCategory.habits);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HabitModalHeader(
              icon: Icons.bedtime_rounded,
              eyebrow: l10n.habitsTileSleep,
              title: l10n.habitsSleepQualityQuestion,
              saved: habit.sleepQuality != null,
              savedLabel: l10n.habitsSaved,
            ),
            const SizedBox(height: 18),
            // 3 Big Emoji buttons
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: EmojiOptionButton(
                      key: const Key('habits_sleep_bem'),
                      sleepKey: HabitSleepQuality.bem,
                      emoji: '😴',
                      label: l10n.habitsSleepQualityBem.replaceFirst('😴 ', ''),
                      selected: habit.sleepQuality == HabitSleepQuality.bem,
                      onTap: viewOnly
                          ? null
                          : () => controller.saveAnswer(
                                day: dayString,
                                sleepQuality: HabitSleepQuality.bem,
                              ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: EmojiOptionButton(
                      key: const Key('habits_sleep_regular'),
                      sleepKey: HabitSleepQuality.regular,
                      emoji: '😐',
                      label: l10n.habitsSleepQualityRegular.replaceFirst('😐 ', ''),
                      selected: habit.sleepQuality == HabitSleepQuality.regular,
                      onTap: viewOnly
                          ? null
                          : () => controller.saveAnswer(
                                day: dayString,
                                sleepQuality: HabitSleepQuality.regular,
                              ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: EmojiOptionButton(
                      key: const Key('habits_sleep_mal'),
                      sleepKey: HabitSleepQuality.mal,
                      emoji: '😫',
                      label: l10n.habitsSleepQualityMal.replaceFirst('😫 ', ''),
                      selected: habit.sleepQuality == HabitSleepQuality.mal,
                      onTap: viewOnly
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
            const SizedBox(height: 18),
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
                ChipOption(
                  key: const Key('habits_hours_menos_5'),
                  label: l10n.habitsSleepHoursMenos5,
                  selected: habit.sleepHours == HabitSleepHours.menos5,
                  onSelected: viewOnly
                      ? null
                      : (s) => controller.saveAnswer(
                            day: dayString,
                            sleepHours: HabitSleepHours.menos5,
                          ),
                ),
                ChipOption(
                  key: const Key('habits_hours_5_6'),
                  label: l10n.habitsSleepHours5To6,
                  selected: habit.sleepHours == HabitSleepHours.hours5To6,
                  onSelected: viewOnly
                      ? null
                      : (s) => controller.saveAnswer(
                            day: dayString,
                            sleepHours: HabitSleepHours.hours5To6,
                          ),
                ),
                ChipOption(
                  key: const Key('habits_hours_7_8'),
                  label: l10n.habitsSleepHours7To8,
                  selected: habit.sleepHours == HabitSleepHours.hours7To8,
                  onSelected: viewOnly
                      ? null
                      : (s) => controller.saveAnswer(
                            day: dayString,
                            sleepHours: HabitSleepHours.hours7To8,
                          ),
                ),
                ChipOption(
                  key: const Key('habits_hours_9_mais'),
                  label: l10n.habitsSleepHours9Mais,
                  selected: habit.sleepHours == HabitSleepHours.hours9Mais,
                  onSelected: viewOnly
                      ? null
                      : (s) => controller.saveAnswer(
                            day: dayString,
                            sleepHours: HabitSleepHours.hours9Mais,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const Key('sleep_modal_done'),
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dualisNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.close,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
