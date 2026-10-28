import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/presentation/controllers/journal_flow_state.dart';
import '../../../journal/presentation/screens/journal_flow_screen.dart';
import '../../../triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import '../../domain/axis_intensity_resolver.dart';
import '../../domain/trigger_checkin_state.dart';
import '../controllers/trigger_checkin_controller.dart';

class DualAxisTriggerCard extends ConsumerWidget {
  const DualAxisTriggerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(triggerCheckInProvider);
    final outcomeState = ref.watch(triageOutcomeProvider);
    final outcome = outcomeState.outcome;
    final notifier = ref.read(triggerCheckInProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasSecondaryEmotional = outcome != null &&
        (outcome.vertical == 'physical' && outcome.secondaryCategoryLabel != null);
    final isEmotionalFromOutcome = outcome != null &&
        (outcome.vertical == 'emotional' || hasSecondaryEmotional);

    final hasSecondaryPhysical = outcome != null &&
        (outcome.vertical == 'emotional' && outcome.secondaryCategoryLabel != null);
    final isPhysicalFromOutcome = outcome != null &&
        (outcome.vertical == 'physical' || hasSecondaryPhysical);

    final isEmotionalCompleted = state.isEmotionalCompleted || isEmotionalFromOutcome;
    final isPhysicalCompleted = state.isPhysicalCompleted || isPhysicalFromOutcome;

    final emotionalIntensity = AxisIntensityResolver.resolveDisplayIntensity(
      axis: CheckInAxis.emotional,
      state: state,
      outcome: outcome,
    );

    final physicalIntensity = AxisIntensityResolver.resolveDisplayIntensity(
      axis: CheckInAxis.physical,
      state: state,
      outcome: outcome,
    );

    final emotionalStatus = state.emotionalStatus ??
        (outcome != null
            ? (outcome.vertical == 'emotional'
                ? triggerStatusFromIntensity(outcome.intensityScore)
                : (hasSecondaryEmotional
                    ? triggerStatusFromIntensity(outcome.secondaryIntensityScore ?? emotionalIntensity)
                    : null))
            : null);

    final physicalStatus = state.physicalStatus ??
        (outcome != null
            ? (outcome.vertical == 'physical'
                ? triggerStatusFromIntensity(outcome.intensityScore)
                : (hasSecondaryPhysical
                    ? triggerStatusFromIntensity(outcome.secondaryIntensityScore ?? physicalIntensity)
                    : null))
            : null);

    final emotionalSummary = state.emotionalSummary ??
        (outcome != null
            ? (outcome.vertical == 'emotional'
                ? outcome.categoryLabel
                : outcome.secondaryCategoryLabel)
            : null);

    final physicalSummary = state.physicalSummary ??
        (outcome != null
            ? (outcome.vertical == 'physical'
                ? outcome.categoryLabel
                : outcome.secondaryCategoryLabel)
            : null);

    final viewOnly = activeProfileIsViewOnly(ref);

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Icons.health_and_safety_outlined,
                    color: AppColors.clinicalTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-in Diário em 2 Etapas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.clinicalTeal,
                        ),
                      ),
                      Text(
                        'Como você está hoje?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
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

            const Divider(height: 1),
            const SizedBox(height: 16),

            if (viewOnly) const ActiveProfileReadOnlyNote(),

            // Etapa 1: Psicoemocional
            _buildStageCard(
              context: context,
              title: 'Psicoemocional',
              subtitle: 'Humor, ansiedade, estresse e clareza mental',
              icon: Icons.psychology_rounded,
              accentColor: AppColors.dualisSymbolGreen,
              isCompleted: isEmotionalCompleted,
              status: emotionalStatus,
              intensity: emotionalIntensity,
              summary: emotionalSummary,
              // Only text the user typed in that stage's triage; never the
              // AI's mapped lay term.
              narrative: state.emotionalNarrative,
              buttonKey: 'start_psicoemocional_triage_button',
              completedCardKey: 'psicoemocional_completed_card',
              retakeKey: 'retake_psicoemocional_button',
              onStart: () {
                context.push(
                  RoutePaths.journal,
                  extra: const JournalFlowArgs(initialArea: JournalArea.emotional),
                );
              },
              onRetake: () {
                notifier.prepareForUpdate();
                context.push(
                  RoutePaths.journal,
                  extra: const JournalFlowArgs(initialArea: JournalArea.emotional),
                );
              },
              isDark: isDark,
              viewOnly: viewOnly,
            ),

            const SizedBox(height: 16),

            // Etapa 2: Físico
            _buildStageCard(
              context: context,
              title: 'Físico',
              subtitle: 'Dores corporais, desconforto somático ou fadiga',
              icon: Icons.accessibility_new_rounded,
              accentColor: AppColors.dualisSymbolBlue,
              isCompleted: isPhysicalCompleted,
              status: physicalStatus,
              intensity: physicalIntensity,
              summary: physicalSummary,
              narrative: state.physicalNarrative,
              buttonKey: 'start_fisica_triage_button',
              completedCardKey: 'fisica_completed_card',
              retakeKey: 'retake_fisica_button',
              onStart: () {
                context.push(
                  RoutePaths.journal,
                  extra: const JournalFlowArgs(initialArea: JournalArea.physical),
                );
              },
              onRetake: () {
                notifier.prepareForUpdate();
                context.push(
                  RoutePaths.journal,
                  extra: const JournalFlowArgs(initialArea: JournalArea.physical),
                );
              },
              isDark: isDark,
              viewOnly: viewOnly,
            ),
            if (state.conditionsSummary != null &&
                state.conditionsSummary!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ConditionsTodaySummary(
                summary: state.conditionsSummary!,
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isCompleted,
    required TriggerStatus? status,
    int? intensity,
    required String? summary,
    required String? narrative,
    required String buttonKey,
    required String completedCardKey,
    required String retakeKey,
    required VoidCallback onStart,
    required VoidCallback onRetake,
    required bool isDark,
    required bool viewOnly,
  }) {
    if (isCompleted) {
      final tier = intensity != null
          ? ClinicalIntensityTier.fromScore(intensity)
          : (status?.tier ?? ClinicalIntensityTier.none);

      return Container(
        key: Key(completedCardKey),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : tier.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? tier.color.withValues(alpha: 0.5)
                : tier.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    semanticsLabel: '$title, ${tier.localizedLabel(context)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            if (summary != null && summary.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tier.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        summary,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (narrative != null &&
                narrative.trim().isNotEmpty &&
                int.tryParse(narrative.trim()) == null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineLight),
                ),
                child: Text(
                  '“${narrative.trim()}”',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
            if (!viewOnly) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: Key(retakeKey),
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Atualizar'),
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (viewOnly) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Botão de etapa intacto/sem tocar
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: Key(buttonKey),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onStart,
              icon: Icon(icon, size: 18),
              label: Text(
                'Iniciar $title',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Canonical tier resolver using the ClinicalIntensityTier Single Source of Truth.
  static ClinicalIntensityTier resolveTier({
    int? intensity,
    TriggerStatus? status,
  }) {
    if (intensity != null) {
      return ClinicalIntensityTier.fromScore(intensity);
    }
    return status?.tier ?? ClinicalIntensityTier.none;
  }
}

/// Today's "Minhas condições" items in the user's own words. Its own small
/// block: conditions never fill the emotional or physical axis.
class _ConditionsTodaySummary extends StatelessWidget {
  final String summary;
  final bool isDark;

  const _ConditionsTodaySummary({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('conditions_today_summary'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.jv2ConditionsTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
