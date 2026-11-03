import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../hydration/presentation/controllers/hydration_controller.dart';
import '../../../hydration/presentation/screens/hydration_dashboard_screen.dart';
import '../../../hydration/presentation/widgets/water_intake_modal.dart';
import '../../../profile/domain/models/share_category.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';

/// Premium "Hábitos" tab: today's water at a glance, quick logging, and a link
/// to the full water screen (logs, history, reminders).
class HabitsWaterSummaryCard extends ConsumerWidget {
  const HabitsWaterSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final water = ref.watch(hydrationControllerProvider);
    if (!water.settings.trackingEnabled) return const SizedBox.shrink();
    final viewOnly = activeProfileIsViewOnly(ref) ||
        !activeProfileCanWrite(ref, ShareCategory.habits);

    Widget chip(String key, String emoji, String label, VoidCallback onTap) {
      return Expanded(
        child: Material(
          color: AppColors.backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.outlineLight),
          ),
          child: InkWell(
            key: Key(key),
            borderRadius: BorderRadius.circular(12),
            onTap: viewOnly ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '$emoji $label',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.clinicalTealDark,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      key: const Key('habits_water_summary_card'),
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
          Text(
            l10n.habitsWaterSummaryTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: water.progressRatio.clamp(0.0, 1.0),
                      strokeWidth: 7,
                      backgroundColor: AppColors.outlineLight,
                      color: AppColors.clinicalTeal,
                    ),
                    Center(
                      child: Text(
                        '${water.progressPercent}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${water.todayTotalMl} / ${water.dailyTargetMl} ml',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              chip('habits_water_add_200', '🥛', '200 ml',
                  () => logWaterWithUndo(context, ref, 200)),
              const SizedBox(width: 8),
              chip('habits_water_add_500', '🍶', '500 ml',
                  () => logWaterWithUndo(context, ref, 500)),
              const SizedBox(width: 8),
              chip('habits_water_add_other', '✏️', l10n.xv2WaterOther,
                  () => WaterIntakeModal.show(context)),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('habits_water_open_full'),
              onPressed: () => context.push(RoutePaths.hydration),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: Text(
                l10n.habitsWaterSummaryOpen,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
