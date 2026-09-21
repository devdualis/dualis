import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../triage_outcome/domain/curated_articles_catalog.dart';
import '../../../triage_outcome/domain/triage_outcome_models.dart';
import '../../../triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import '../../../triage_outcome/presentation/widgets/article_card.dart';
import '../../../triage_outcome/presentation/widgets/disposition_card.dart';
import '../../../triage_outcome/presentation/widgets/intensity_meter.dart';
import '../../../triage_outcome/presentation/widgets/organic_primacy_banner.dart';
import '../../../triage_outcome/presentation/widgets/ai_insight_card.dart';
import '../../domain/trigger_checkin_state.dart';
import '../controllers/trigger_checkin_controller.dart';

class TodayTriageResultTab extends ConsumerWidget {
  final VoidCallback onGoToCheckIn;

  const TodayTriageResultTab({
    super.key,
    required this.onGoToCheckIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcomeState = ref.watch(triageOutcomeProvider);
    final triggerState = ref.watch(triggerCheckInProvider);

    final outcome = outcomeState.outcome;
    final isCompletedToday = triggerState.isCompletedToday;
    final isTrueWellness = triggerState.emotionalStatus == TriggerStatus.goodNormal &&
        triggerState.physicalStatus == TriggerStatus.goodNormal &&
        triggerState.naturalLanguageText.trim().isEmpty;

    final now = DateTime.now();
    final dateFormatted = DateFormat("d 'de' MMMM, yyyy", 'pt_BR').format(now);

    return SingleChildScrollView(
      key: const Key('today_triage_result_scroll_view'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayHeader(
            dateFormatted,
            isCompletedToday,
            outcome != null,
            isTrueWellness: isTrueWellness,
          ),
          const SizedBox(height: 16),
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

  Widget _buildDayHeader(
    String dateText,
    bool isCompleted,
    bool hasOutcome, {
    required bool isTrueWellness,
  }) {
    Color badgeBgColor;
    Color badgeBorderColor;
    Color badgeTextColor;
    String badgeText;
    IconData headerIcon;
    Color headerIconColor;

    if (hasOutcome) {
      badgeBgColor = AppColors.clinicalTeal.withValues(alpha: 0.12);
      badgeBorderColor = AppColors.clinicalTeal.withValues(alpha: 0.3);
      badgeTextColor = AppColors.clinicalTealDark;
      badgeText = 'Triagem Concluída';
      headerIcon = Icons.verified_rounded;
      headerIconColor = AppColors.clinicalTeal;
    } else if (isCompleted) {
      if (isTrueWellness) {
        badgeBgColor = AppColors.clinicalTeal.withValues(alpha: 0.12);
        badgeBorderColor = AppColors.clinicalTeal.withValues(alpha: 0.3);
        badgeTextColor = AppColors.clinicalTealDark;
        badgeText = 'Bem-Estar Confirmado';
        headerIcon = Icons.check_circle_rounded;
        headerIconColor = AppColors.clinicalTeal;
      } else {
        badgeBgColor = Colors.amber.shade50;
        badgeBorderColor = Colors.amber.shade300;
        badgeTextColor = Colors.amber.shade900;
        badgeText = 'Sintomas Registrados';
        headerIcon = Icons.assignment_late_rounded;
        headerIconColor = Colors.amber.shade800;
      }
    } else {
      badgeBgColor = Colors.orange.shade50;
      badgeBorderColor = Colors.orange.shade200;
      badgeTextColor = Colors.orange.shade800;
      badgeText = 'Pendente';
      headerIcon = Icons.pending_actions_rounded;
      headerIconColor = Colors.grey.shade600;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (hasOutcome || isCompleted)
              ? (isTrueWellness || hasOutcome
                  ? AppColors.clinicalTeal.withValues(alpha: 0.3)
                  : Colors.amber.shade300)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (hasOutcome || isCompleted)
                  ? headerIconColor.withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              headerIcon,
              color: headerIconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado Geral de Hoje',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeBorderColor),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullOutcomeView(
    BuildContext context,
    WidgetRef ref,
    TriageOutcome outcome,
  ) {
    final isPhysical = outcome.vertical == 'physical';
    final verticalColor = isPhysical ? AppColors.clinicalTeal : AppColors.softIndigo;
    final articles = outcome.recommendedArticles.isNotEmpty
        ? outcome.recommendedArticles
        : CuratedArticlesCatalog.getArticlesForSymptoms(
            queryText: outcome.aiMappedLayTerm,
            anatomicalSystem: outcome.primaryCategory,
            isPhysicalDistressed: isPhysical,
            isEmotionalDistressed: !isPhysical || outcome.organicPrimacyApplied,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (outcome.organicPrimacyApplied) ...[
          OrganicPrimacyBanner(notice: outcome.organicPrimacyNotice),
          const SizedBox(height: 16),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: verticalColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: verticalColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                isPhysical ? Icons.healing_rounded : Icons.psychology_rounded,
                color: verticalColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outcome.categoryLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: verticalColor,
                      ),
                    ),
                    if (outcome.somaticMapping.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        outcome.somaticMapping,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (outcome.secondaryCategoryLabel != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softIndigo.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.softIndigo.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.softIndigo, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Componente Associado: ${outcome.secondaryCategoryLabel}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.softIndigo,
                        ),
                      ),
                      if (outcome.secondarySomaticMapping != null &&
                          outcome.secondarySomaticMapping!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          outcome.secondarySomaticMapping!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        IntensityMeter(score: outcome.intensityScore),
        const SizedBox(height: 16),
        if (outcome.aiClinicalConcept != null &&
            outcome.aiClinicalConcept!.isNotEmpty) ...[
          AiInsightCard(
            mappedLayTerm: outcome.aiMappedLayTerm,
            clinicalConcept: outcome.aiClinicalConcept!,
            source: outcome.aiSource,
            isCrossVerticalSomatic: outcome.isCrossVerticalSomatic,
            contextNote: outcome.crossVerticalContextNote,
          ),
          const SizedBox(height: 16),
        ],
        DispositionCard(disposition: outcome.careDisposition),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Artigos Sugeridos para Você',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            Text(
              '${articles.length} recomendações',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...articles.map((article) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ArticleCard(article: article),
            )),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            key: const Key('today_retake_triage_button'),
            onPressed: () {
              ref.read(triggerCheckInProvider.notifier).prepareForUpdate();
              onGoToCheckIn();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Atualizar Triagem de Hoje'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSymptomCheckInView(
    BuildContext context,
    TriggerCheckInState triggerState,
  ) {
    final hasBadSick = triggerState.emotionalStatus == TriggerStatus.badSick ||
        triggerState.physicalStatus == TriggerStatus.badSick;
    final hasSoSo = triggerState.emotionalStatus == TriggerStatus.soSo ||
        triggerState.physicalStatus == TriggerStatus.soSo;

    final calculatedScore = hasBadSick ? 4 : (hasSoSo ? 3 : 1);
    final calculatedDisposition = hasBadSick
        ? CareDisposition.urgentCare
        : (hasSoSo ? CareDisposition.routineConsultation : CareDisposition.selfCare);

    final articles = CuratedArticlesCatalog.getArticlesForSymptoms(
      queryText: triggerState.naturalLanguageText,
      isEmotionalDistressed: triggerState.emotionalStatus != TriggerStatus.goodNormal,
      isPhysicalDistressed: triggerState.physicalStatus != TriggerStatus.goodNormal,
    );

    final completedTimeStr = triggerState.completedAt != null
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
              if (triggerState.naturalLanguageText.trim().isNotEmpty) ...[
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
        DispositionCard(disposition: calculatedDisposition),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          key: const Key('today_start_full_triage_button'),
          onPressed: onGoToCheckIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.clinicalTeal,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          label: Text(
            'Completar Triagem Clínica Detalhada',
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
                'Artigos Sugeridos para Seus Sintomas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${articles.length} recomendações',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Recomendações clínicas selecionadas de acordo com os sintomas relatados hoje.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        ...articles.map((article) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ArticleCard(article: article),
            )),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.clinicalTeal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.clinicalTeal.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.spa_rounded, color: AppColors.clinicalTeal, size: 28),
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
          'Artigos Preventivos do Dia',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Leituras rápidas recomendadas pela equipe clínica para manter seu equilíbrio diário.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 14),
        ...articles.map((article) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ArticleCard(article: article),
            )),
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
            'Nenhuma avaliação realizada hoje',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Faça seu check-in diário de 1 minuto na aba Início para registrar seus sintomas, acompanhar sua saúde e receber artigos personalizados.',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              'Artigos Sugeridos para Você',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...articles.map((article) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ArticleCard(article: article),
              )),
        ],
      ),
    );
  }
}
