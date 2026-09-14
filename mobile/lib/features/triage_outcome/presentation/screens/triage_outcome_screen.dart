import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../domain/triage_outcome_models.dart';
import '../widgets/intensity_meter.dart';
import '../widgets/disposition_card.dart';
import '../widgets/organic_primacy_banner.dart';
import '../widgets/article_card.dart';

class TriageOutcomeScreen extends StatelessWidget {
  final TriageOutcome outcome;

  const TriageOutcomeScreen({
    super.key,
    required this.outcome,
  });

  @override
  Widget build(BuildContext context) {
    final isPhysical = outcome.vertical == 'physical';
    final verticalColor = isPhysical ? AppColors.clinicalTeal : AppColors.softIndigo;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Resultado da Triagem',
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
              // Vertical banner badge
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
              const SizedBox(height: 16),

              // Intensity meter (1 to 5)
              IntensityMeter(score: outcome.intensityScore),
              const SizedBox(height: 16),

              // Organic Primacy banner if applicable
              if (outcome.organicPrimacyApplied) ...[
                OrganicPrimacyBanner(notice: outcome.organicPrimacyNotice),
                const SizedBox(height: 16),
              ],

              // Care disposition card
              DispositionCard(disposition: outcome.careDisposition),
              const SizedBox(height: 24),

              // Specialist Articles Header
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.clinicalTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Artigos Médicos Recomendados',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Conteúdos preventivos elaborados por especialistas renomados',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              // Articles list
              if (outcome.recommendedArticles.isEmpty)
                Text(
                  'Nenhum artigo disponível no momento.',
                  style: GoogleFonts.plusJakartaSans(color: Colors.black54),
                )
              else
                ...outcome.recommendedArticles.map(
                  (article) => ArticleCard(article: article),
                ),

              const SizedBox(height: 24),

              // Finish button
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
                  'Concluir e Voltar ao Início',
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
