import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../hydration/presentation/controllers/hydration_controller.dart';
import '../../../hydration/presentation/widgets/water_intake_modal.dart';

class HomeHydrationCard extends ConsumerWidget {
  const HomeHydrationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydrationControllerProvider);
    final target = state.dailyTargetMl;
    final total = state.todayTotalMl;
    final percent = state.progressPercent;
    final isMet = state.isGoalReached;

    return Card(
      key: const Key('home_hydration_card'),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isMet
              ? AppColors.clinicalTeal.withValues(alpha: 0.4)
              : Colors.grey.shade200,
        ),
      ),
      color: AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.clinicalTeal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.clinicalTealDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Controle de Hidratação',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          if (isMet) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppColors.clinicalTealDark,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '$total de $target ml atingidos hoje ($percent%)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('home_hydration_view_chart_button'),
                  onPressed: () => context.push(RoutePaths.hydration),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gráfico',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.softIndigo,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.softIndigo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: state.progressRatio.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isMet ? AppColors.clinicalTealDark : AppColors.clinicalTeal,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('home_hydration_quick_add_button'),
                    icon: const Icon(Icons.add, size: 16, color: AppColors.clinicalTealDark),
                    label: Text(
                      '+250 ml (Copo)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.clinicalTealDark,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.clinicalTeal.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () async {
                      final success = await ref
                          .read(hydrationControllerProvider.notifier)
                          .logWater(amountMl: 250, source: 'home_quick_button');
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('💧 +250 ml registrados!'),
                            duration: Duration(seconds: 2),
                            backgroundColor: AppColors.clinicalTealDark,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('home_hydration_log_modal_button'),
                    icon: const Icon(Icons.edit_note, size: 16, color: Colors.white),
                    label: Text(
                      'Outra Quantidade',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.clinicalTealDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: () => WaterIntakeModal.show(context, source: 'home_card'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
