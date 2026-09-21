import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class AiInsightCard extends StatelessWidget {
  final String? mappedLayTerm;
  final String clinicalConcept;
  final String? source;
  final bool isCrossVerticalSomatic;
  final String? contextNote;

  const AiInsightCard({
    super.key,
    required this.mappedLayTerm,
    required this.clinicalConcept,
    required this.source,
    this.isCrossVerticalSomatic = false,
    this.contextNote,
  });

  bool get _isGeneratedByAi => source == 'gemini_flash';

  @override
  Widget build(BuildContext context) {
    final title = isCrossVerticalSomatic
        ? 'Manifestação Somática Concomitante'
        : 'Informação Clínica Complementar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softIndigo.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softIndigo.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.softIndigo.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCrossVerticalSomatic ? Icons.healing_outlined : Icons.auto_awesome_rounded,
              color: AppColors.softIndigo,
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
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.softIndigo,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  clinicalConcept,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                if (mappedLayTerm != null && mappedLayTerm!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Termo identificado: $mappedLayTerm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
                if (contextNote != null && contextNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.softIndigo.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: AppColors.softIndigo,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            contextNote!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              height: 1.35,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isGeneratedByAi
                        ? const Color(0xFFFFF3E0)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isGeneratedByAi
                        ? 'Gerado por IA — confirme com um profissional'
                        : (isCrossVerticalSomatic
                            ? 'Sintoma físico relatado no check-in'
                            : 'Já catalogado na base clínica'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _isGeneratedByAi
                          ? const Color(0xFFE65100)
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
