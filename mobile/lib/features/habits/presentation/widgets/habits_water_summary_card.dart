import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/glass_card.dart';
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
    final viewOnly =
        activeProfileIsViewOnly(ref) ||
        !activeProfileCanWrite(ref, ShareCategory.habits);

    Widget chip(String key, IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: Material(
          color: AppColors.dualisNavy.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            key: Key(key),
            borderRadius: BorderRadius.circular(16),
            onTap: viewOnly ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: AppColors.dualisNavy),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
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

    return GlassCard(
      key: const Key('habits_water_summary_card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const DuotoneIconTile(
                size: 32,
                radius: 10,
                child: Icon(
                  Icons.water_drop_rounded,
                  size: 18,
                  color: AppColors.dualisNavy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.habitsWaterSummaryTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
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
                      backgroundColor: AppColors.dualisNavy.withValues(
                        alpha: 0.08,
                      ),
                      color: AppColors.dualisSymbolBlue,
                    ),
                    Center(
                      child: Text(
                        '${water.progressPercent}%',
                        style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
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
              chip(
                'habits_water_add_200',
                Icons.water_drop_outlined,
                '200 ml',
                () => logWaterWithUndo(context, ref, 200),
              ),
              const SizedBox(width: 8),
              chip(
                'habits_water_add_500',
                Icons.local_drink_rounded,
                '500 ml',
                () => logWaterWithUndo(context, ref, 500),
              ),
              const SizedBox(width: 8),
              chip(
                'habits_water_add_other',
                Icons.edit_rounded,
                l10n.xv2WaterOther,
                () => WaterIntakeModal.show(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('habits_water_open_full'),
              onPressed: () => context.push(RoutePaths.hydration),
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.dualisNavy,
              ),
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: Text(
                l10n.habitsWaterSummaryOpen,
                style: GoogleFonts.inter(
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
