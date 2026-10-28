import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../triage_outcome/domain/curated_articles_catalog.dart';
import '../../../triage_outcome/domain/triage_outcome_models.dart';
import '../../../triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import '../../../triage_outcome/presentation/widgets/article_card.dart';
import '../../../triage_outcome/presentation/widgets/intensity_meter.dart';
import '../../../triage_outcome/presentation/widgets/wellness_guidance_block.dart';
import '../../../triage_outcome/presentation/widgets/dual_axis_static_note.dart';
import '../../domain/axis_intensity_resolver.dart';
import '../../domain/trigger_checkin_state.dart';
import '../controllers/trigger_checkin_controller.dart';

class TodayTriageResultTab extends ConsumerWidget {
  final VoidCallback onGoToCheckIn;

  const TodayTriageResultTab({super.key, required this.onGoToCheckIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcomeState = ref.watch(triageOutcomeProvider);
    final triggerState = ref.watch(triggerCheckInProvider);

    final outcome = outcomeState.outcome;
    final isCompletedToday = triggerState.isCompletedToday;
    final isTrueWellness =
        triggerState.emotionalStatus == TriggerStatus.goodNormal &&
        triggerState.physicalStatus == TriggerStatus.goodNormal &&
        triggerState.naturalLanguageText.trim().isEmpty;

    return SingleChildScrollView(
      key: const Key('today_triage_result_scroll_view'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (outcome != null) ...[
            _buildFullOutcomeView(context, ref, outcome),
          ] else if (isCompletedToday && isTrueWellness) ...[
            _buildWellnessCheckInView(context, triggerState),
          ] else if (isCompletedToday && !isTrueWellness) ...[
            _buildSymptomCheckInView(context, triggerState),
          ] else ...[
            _buildPendingCheckInView(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFullOutcomeView(
    BuildContext context,
    WidgetRef ref,
    TriageOutcome outcome,
  ) {
    final triggerState = ref.watch(triggerCheckInProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPhysical = outcome.vertical == 'physical';

    final hasEmotionalOutcome =
        !isPhysical ||
        triggerState.isEmotionalCompleted ||
        outcome.secondaryCategoryLabel != null;

    final hasPhysicalOutcome =
        isPhysical ||
        triggerState.isPhysicalCompleted ||
        (outcome.secondaryCategoryLabel != null && !isPhysical);

    final physicalTitle =
        isPhysical
            ? outcome.categoryLabel
            : (triggerState.physicalSummary ??
                outcome.secondaryCategoryLabel ??
                'Registro físico');
    final physicalDescription =
        isPhysical
            ? outcome.somaticMapping
            : (triggerState.physicalNarrative ??
                outcome.secondarySomaticMapping ??
                l10n.outcomeTodayYouLogged(
                  _statusLabel(l10n, triggerState.physicalStatus),
                ));
    final physicalIntensity = AxisIntensityResolver.resolveDisplayIntensity(
      axis: CheckInAxis.physical,
      state: triggerState,
      outcome: outcome,
    );
    final physicalStatus =
        isPhysical
            ? triggerStatusFromIntensity(outcome.intensityScore)
            : (triggerState.physicalStatus ?? TriggerStatus.goodNormal);

    final emotionalTitle =
        !isPhysical
            ? outcome.categoryLabel
            : (triggerState.emotionalSummary ??
                outcome.secondaryCategoryLabel ??
                'Registro emocional');
    final emotionalDescription =
        !isPhysical
            ? outcome.somaticMapping
            : (triggerState.emotionalNarrative ??
                outcome.secondarySomaticMapping ??
                l10n.outcomeTodayYouLogged(
                  _statusLabel(l10n, triggerState.emotionalStatus),
                ));
    final emotionalIntensity = AxisIntensityResolver.resolveDisplayIntensity(
      axis: CheckInAxis.emotional,
      state: triggerState,
      outcome: outcome,
    );
    final emotionalStatus =
        !isPhysical
            ? triggerStatusFromIntensity(outcome.intensityScore)
            : (triggerState.emotionalStatus ?? TriggerStatus.goodNormal);

    // Same general readings for everyone: never chosen from what was
    // recorded (strategy §9.3).
    final articles = CuratedArticlesCatalog.wellnessArticles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (outcome.loggedBothAxesToday) ...[
          const DualAxisStaticNote(),
          const SizedBox(height: 16),
        ],

        // Exibe os eixos de triagem realizados
        if (hasPhysicalOutcome && hasEmotionalOutcome) ...[
          _buildOutcomeAxisCard(
            axisLabel: l10n.outcomeAxisPhysicalNumbered,
            categoryTitle: physicalTitle,
            description: physicalDescription,
            narrative: isPhysical ? triggerState.physicalNarrative : null,
            icon: Icons.accessibility_new_rounded,
            accentColor: AppColors.clinicalTeal,
            status: physicalStatus,
            intensity: physicalIntensity,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildOutcomeAxisCard(
            // Same axis label with or without an associated component; the
            // component itself is the card's category title.
            axisLabel: l10n.outcomeAxisEmotionalNumbered,
            categoryTitle: emotionalTitle,
            description: emotionalDescription,
            narrative: !isPhysical ? triggerState.emotionalNarrative : null,
            icon: Icons.psychology_rounded,
            accentColor: AppColors.softIndigo,
            status: emotionalStatus,
            intensity: emotionalIntensity,
            isDark: isDark,
          ),
        ] else if (isPhysical) ...[
          _buildOutcomeAxisCard(
            axisLabel: 'Registro físico',
            categoryTitle: physicalTitle,
            description: physicalDescription,
            narrative: triggerState.physicalNarrative,
            icon: Icons.accessibility_new_rounded,
            accentColor: AppColors.clinicalTeal,
            status: physicalStatus,
            intensity: physicalIntensity,
            isDark: isDark,
          ),
        ] else ...[
          _buildOutcomeAxisCard(
            axisLabel: 'Registro emocional',
            categoryTitle: emotionalTitle,
            description: emotionalDescription,
            narrative: triggerState.emotionalNarrative,
            icon: Icons.psychology_rounded,
            accentColor: AppColors.softIndigo,
            status: emotionalStatus,
            intensity: emotionalIntensity,
            isDark: isDark,
          ),
        ],
        const SizedBox(height: 16),
        const WellnessGuidanceBlock(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.outcomeWellnessReadingsTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            Text(
              l10n.outcomeWellnessReadingsCount(articles.length),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...articles.map(
          (article) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ArticleCard(article: article),
          ),
        ),
        const SizedBox(height: 12),
        if (!activeProfileIsViewOnly(ref))
          Center(
            child: TextButton.icon(
              key: const Key('today_retake_triage_button'),
              onPressed: () {
                ref.read(triggerCheckInProvider.notifier).prepareForUpdate();
                onGoToCheckIn();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.todayOutcomeUpdateButton),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _statusLabel(AppLocalizations l10n, TriggerStatus? status) {
    switch (status) {
      case TriggerStatus.badSick:
        return l10n.outcomeTodayStatusBad;
      case TriggerStatus.soSo:
        return l10n.outcomeTodayStatusSoSo;
      case TriggerStatus.goodNormal:
      case null:
        return l10n.outcomeTodayStatusGood;
    }
  }

  Widget _buildOutcomeAxisCard({
    required String axisLabel,
    required String categoryTitle,
    required String description,
    String? narrative,
    required IconData icon,
    required Color accentColor,
    TriggerStatus? status,
    int? intensity,
    required bool isDark,
  }) {
    final tier =
        intensity != null
            ? SelfReportedIntensityBand.fromScore(intensity)
            : (status?.tier ?? SelfReportedIntensityBand.none);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : tier.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? tier.color.withValues(alpha: 0.5) : tier.borderColor,
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
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      axisLabel,
                      semanticsLabel: '$axisLabel, ${tier.label}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      categoryTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.surfaceDark
                        : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                  height: 1.3,
                ),
              ),
            ),
          ],
          if (narrative != null && narrative.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
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
                  color:
                      isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSymptomCheckInView(
    BuildContext context,
    TriggerCheckInState triggerState,
  ) {
    final hasBadSick =
        triggerState.emotionalStatus == TriggerStatus.badSick ||
        triggerState.physicalStatus == TriggerStatus.badSick;
    final hasSoSo =
        triggerState.emotionalStatus == TriggerStatus.soSo ||
        triggerState.physicalStatus == TriggerStatus.soSo;

    final calculatedScore = hasBadSick ? 4 : (hasSoSo ? 3 : 1);
    final l10n = AppLocalizations.of(context);

    final articles = CuratedArticlesCatalog.wellnessArticles;

    final completedTimeStr =
        triggerState.completedAt != null
            ? ' às ${triggerState.completedAt!.hour.toString().padLeft(2, '0')}:${triggerState.completedAt!.minute.toString().padLeft(2, '0')}'
            : '';

    return Column(
      key: const Key('today_symptom_checkin_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_late_rounded,
                    color: Colors.amber.shade900,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sintomas Registrados no Check-in',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        Text(
                          'Registrado hoje$completedTimeStr',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildReportedAxisRow(
                icon: Icons.psychology_outlined,
                axisLabel: '1. Eixo Psico-Emocional',
                status: triggerState.emotionalStatus,
              ),
              const SizedBox(height: 8),
              _buildReportedAxisRow(
                icon: Icons.accessibility_new_rounded,
                axisLabel: '2. Eixo Avaliação Física',
                status: triggerState.physicalStatus,
              ),
              if (triggerState.naturalLanguageText.trim().isNotEmpty &&
                  int.tryParse(triggerState.naturalLanguageText.trim()) ==
                      null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        color: Colors.amber.shade900,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Relato: "${triggerState.naturalLanguageText.trim()}"',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntensityMeter(score: calculatedScore),
        const SizedBox(height: 16),
        const WellnessGuidanceBlock(),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          key: const Key('today_start_full_triage_button'),
          onPressed: onGoToCheckIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.clinicalTeal,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          label: Text(
            l10n.todayOutcomeDetailedCheckinButton,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.outcomeWellnessReadingsTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.outcomeWellnessReadingsCount(articles.length),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.outcomeWellnessReadingsDisclaimer,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        ...articles.map(
          (article) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ArticleCard(article: article),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            key: const Key('today_edit_symptoms_button'),
            onPressed: onGoToCheckIn,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Revisar Respostas do Check-in'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReportedAxisRow({
    required IconData icon,
    required String axisLabel,
    required TriggerStatus? status,
  }) {
    Color badgeColor;
    String statusText;

    switch (status) {
      case TriggerStatus.badSick:
        badgeColor = AppColors.emergencyCrimson;
        statusText = 'Mal / Ruim';
        break;
      case TriggerStatus.soSo:
        badgeColor = Colors.amber.shade800;
        statusText = 'Mais ou menos';
        break;
      case TriggerStatus.goodNormal:
      default:
        badgeColor = AppColors.clinicalTeal;
        statusText = 'Bem / Normal';
        break;
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            axisLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            statusText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessCheckInView(
    BuildContext context,
    TriggerCheckInState triggerState,
  ) {
    final articles = CuratedArticlesCatalog.wellnessArticles;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.clinicalTeal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.clinicalTeal.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.spa_rounded,
                    color: AppColors.clinicalTeal,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Check-in de Bem-Estar Confirmado',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.clinicalTealDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Você indicou estar se sentindo bem em ambos os eixos hoje. Mantenha seus hábitos saudáveis e continue acompanhando seu corpo.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.outcomeArticlesTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.outcomeArticlesSubtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 14),
        ...articles.map(
          (article) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ArticleCard(article: article),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            key: const Key('today_edit_wellness_button'),
            onPressed: onGoToCheckIn,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Revisar Respostas do Check-in'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPendingCheckInView(BuildContext context) {
    final articles = CuratedArticlesCatalog.wellnessArticles;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.clinicalTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 40,
              color: AppColors.clinicalTeal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum registro hoje',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Faça seu check-in diário de 1 minuto na aba Início para registrar como você está e acompanhar seus registros.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            key: const Key('today_start_checkin_cta_button'),
            onPressed: onGoToCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.clinicalTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(
              'Realizar Check-in Agora',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context).outcomeArticlesTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...articles.map(
            (article) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ArticleCard(article: article),
            ),
          ),
        ],
      ),
    );
  }
}
