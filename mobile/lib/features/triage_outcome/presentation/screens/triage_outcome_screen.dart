import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/triage_outcome_models.dart';
import '../widgets/intensity_meter.dart';
import '../widgets/article_card.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/wellness_guidance_block.dart';
import '../widgets/dual_axis_static_note.dart';

class TriageOutcomeScreen extends StatelessWidget {
  final TriageOutcome outcome;

  const TriageOutcomeScreen({
    super.key,
    required this.outcome,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPhysical = outcome.vertical == 'physical';
    final verticalColor = isPhysical ? AppColors.clinicalTeal : AppColors.softIndigo;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.outcomeScreenTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.go(RoutePaths.home),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.outcomeScreenSubtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: verticalColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: verticalColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPhysical ? Icons.healing_rounded : Icons.psychology_rounded,
                      color: verticalColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outcome.categoryLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: verticalColor,
                            ),
                          ),
                          if (outcome.somaticMapping.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              outcome.somaticMapping,
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
              if (outcome.secondaryCategoryLabel != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.softIndigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.softIndigo.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.psychology_rounded,
                        color: AppColors.softIndigo,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outcome.secondaryCategoryLabel!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
              IntensityMeter(
                score: [
                  outcome.intensityScore,
                  outcome.secondaryIntensityScore ?? 0,
                ].reduce((a, b) => a > b ? a : b),
              ),
              const SizedBox(height: 16),
              if (outcome.loggedBothAxesToday) ...[
                const DualAxisStaticNote(),
                const SizedBox(height: 16),
              ],
              AiInsightCard(
                mappedLayTerm: outcome.aiMappedLayTerm,
                bodyAreaOrMood: outcome.aiBodyAreaOrMood,
              ),
              if (outcome.aiMappedLayTerm != null || outcome.aiBodyAreaOrMood != null)
                const SizedBox(height: 16),
              const WellnessGuidanceBlock(),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.clinicalTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.outcomeWellnessReadingsTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.outcomeWellnessReadingsDisclaimer,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              if (outcome.recommendedArticles.isEmpty)
                Text(
                  l10n.outcomeArticlesEmpty,
                  style: GoogleFonts.plusJakartaSans(color: Colors.black54),
                )
              else
                ...outcome.recommendedArticles.map(
                  (article) => ArticleCard(article: article),
                ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: verticalColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.go(RoutePaths.home),
                child: Text(
                  l10n.outcomeDoneButton,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
