import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrganicPrimacyBanner extends StatelessWidget {
  final String? notice;

  const OrganicPrimacyBanner({
    super.key,
    this.notice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Warm Amber
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFECB3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Color(0xFFE65100),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atenção Clínica: Primazia Orgânica',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFBF360C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notice ??
                      'Sintomas físicos concomitantes ao desconforto emocional requerem avaliação médica física prioritária antes de serem atribuídos unicamente ao estresse psicológico.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.4,
                    color: const Color(0xFF3E2723),
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
