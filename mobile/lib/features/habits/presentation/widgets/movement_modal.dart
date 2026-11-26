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

/// Modal bottom sheet exclusively for recording and updating Movement habits.
class MovementModal extends ConsumerWidget {
  const MovementModal({super.key});

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
      builder: (ctx) => const MovementModal(),
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
              icon: Icons.directions_walk_rounded,
              eyebrow: l10n.habitsTileMovement,
              title: l10n.habitsMovedQuestion,
              saved: habit.moved != null,
              savedLabel: l10n.habitsSaved,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: YesNoButton(
                    key: const Key('habits_moved_sim'),
                    label: l10n.habitsMovedYes,
                    selected: habit.moved == true,
                    onTap: viewOnly
                        ? null
                        : () => controller.saveAnswer(
                              day: dayString,
                              moved: true,
                            ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: YesNoButton(
                    key: const Key('habits_moved_nao'),
                    label: l10n.habitsMovedNo,
                    selected: habit.moved == false,
                    onTap: viewOnly
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
              const SizedBox(height: 18),
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
                  ChipOption(
                    key: const Key('habits_minutes_ate_15'),
                    label: l10n.habitsMovementMinutesAte15,
                    selected: habit.movementMinutes == HabitMovementMinutes.ate15,
                    onSelected: viewOnly
                        ? null
                        : (s) => controller.saveAnswer(
                              day: dayString,
                              movementMinutes: HabitMovementMinutes.ate15,
                            ),
                  ),
                  ChipOption(
                    key: const Key('habits_minutes_15_30'),
                    label: l10n.habitsMovementMinutes15To30,
                    selected: habit.movementMinutes ==
                        HabitMovementMinutes.minutes15To30,
                    onSelected: viewOnly
                        ? null
                        : (s) => controller.saveAnswer(
                              day: dayString,
                              movementMinutes:
                                  HabitMovementMinutes.minutes15To30,
                            ),
                  ),
                  ChipOption(
                    key: const Key('habits_minutes_30_60'),
                    label: l10n.habitsMovementMinutes30To60,
                    selected: habit.movementMinutes ==
                        HabitMovementMinutes.minutes30To60,
                    onSelected: viewOnly
                        ? null
                        : (s) => controller.saveAnswer(
                              day: dayString,
                              movementMinutes:
                                  HabitMovementMinutes.minutes30To60,
                            ),
                  ),
                  ChipOption(
                    key: const Key('habits_minutes_mais_60'),
                    label: l10n.habitsMovementMinutesMais60,
                    selected:
                        habit.movementMinutes == HabitMovementMinutes.mais60,
                    onSelected: viewOnly
                        ? null
                        : (s) => controller.saveAnswer(
                              day: dayString,
                              movementMinutes: HabitMovementMinutes.mais60,
                            ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const Key('movement_modal_done'),
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
