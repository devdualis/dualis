import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';
import '../controllers/hydration_controller.dart';
import '../widgets/water_consumption_chart.dart';
import '../widgets/water_intake_modal.dart';

class HydrationDashboardScreen extends ConsumerWidget {
  const HydrationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydrationControllerProvider);
    final notifier = ref.read(hydrationControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Controle de Hidratação 💧',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => notifier.loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Highlight Card
                    _buildTodayHighlightCard(context, ref, state),
                    const SizedBox(height: 20),

                    // Chart
                    WaterConsumptionChart(
                      last7DaysTotals: state.last7DaysTotals,
                      dailyTargetMl: state.dailyTargetMl,
                    ),
                    const SizedBox(height: 24),

                    // Today's log history
                    Text(
                      'Registros de Hoje',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTodayLogsList(context, ref, state),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTodayHighlightCard(
    BuildContext context,
    WidgetRef ref,
    HydrationState state,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.clinicalTeal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: AppColors.clinicalTealDark,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total de Hoje',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        '${state.todayTotalMl} / ${state.dailyTargetMl} ml',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.isGoalReached
                        ? AppColors.clinicalTealDark.withValues(alpha: 0.12)
                        : AppColors.softIndigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${state.progressPercent}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: state.isGoalReached
                          ? AppColors.clinicalTealDark
                          : AppColors.softIndigo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.progressRatio.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  state.isGoalReached
                      ? AppColors.clinicalTealDark
                      : AppColors.clinicalTeal,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DualisPrimaryButton(
              key: const Key('dashboard_add_water_button'),
              text: '+ Registrar Água',
              onPressed: () => WaterIntakeModal.show(context, source: 'dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLogsList(
    BuildContext context,
    WidgetRef ref,
    HydrationState state,
  ) {
    if (state.todayLogs.isEmpty) {
      return Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.surfaceLight,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Nenhum copo de água registrado hoje ainda.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      );
    }

    final reversed = state.todayLogs.reversed.toList();

    return Column(
      children: reversed.map((log) {
        final timeStr = DateFormat('HH:mm').format(log.timestamp);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: AppColors.surfaceLight,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.clinicalTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_drink_rounded,
                color: AppColors.clinicalTealDark,
                size: 20,
              ),
            ),
            title: Text(
              '${log.amountMl} ml',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              log.source == 'reminder_alarm'
                  ? 'Registrado via lembrete das $timeStr'
                  : 'Registrado às $timeStr',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
              onPressed: () {
                if (log.id != null) {
                  ref.read(hydrationControllerProvider.notifier).deleteLog(log.id!);
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}
