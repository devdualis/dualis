import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../triage_outcome/domain/triage_outcome_models.dart';

class TodayTriageSummaryCard extends StatelessWidget {
  final TriageOutcome outcome;
  final VoidCallback onViewFullResult;
  final VoidCallback? onRetake;

  const TodayTriageSummaryCard({
    super.key,
    required this.outcome,
    required this.onViewFullResult,
    this.onRetake,
  });

  Color _getDispositionColor(CareDisposition disposition) {
    switch (disposition) {
      case CareDisposition.emergency:
        return const Color(0xFFD32F2F); // Red
      case CareDisposition.urgentCare:
        return const Color(0xFFE65100); // Deep Orange
      case CareDisposition.routineConsultation:
        return const Color(0xFF3F51B5); // Soft Indigo
      case CareDisposition.selfCare:
        return const Color(0xFF00796B); // Clinical Teal
    }
  }

  String _getDispositionLabel(CareDisposition disposition) {
    switch (disposition) {
      case CareDisposition.emergency:
        return 'Atendimento de Emergência';
      case CareDisposition.urgentCare:
        return 'Pronto Atendimento (24h)';
      case CareDisposition.routineConsultation:
        return 'Consulta de Rotina';
      case CareDisposition.selfCare:
        return 'Auto-cuidado Monitorado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dispositionColor = _getDispositionColor(outcome.careDisposition);
    final dispositionLabel = _getDispositionLabel(outcome.careDisposition);

    final recordedHour = outcome.recordedAt.hour.toString().padLeft(2, '0');
    final recordedMin = outcome.recordedAt.minute.toString().padLeft(2, '0');

    return Card(
      key: const Key('today_triage_summary_card'),
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dispositionColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('view_full_triage_result_button'),
        onTap: onViewFullResult,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dispositionColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  outcome.intensityScore >= 4
                      ? Icons.warning_amber_rounded
                      : Icons.verified_rounded,
                  color: dispositionColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Triagem de Hoje Concluída',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Realizada às $recordedHour:$recordedMin',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: dispositionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dispositionColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  dispositionLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: dispositionColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
