import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntensityMeter extends StatelessWidget {
  final int score;

  const IntensityMeter({
    super.key,
    required this.score,
  });

  Color _getColorForLevel(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF4CAF50);
      case 2:
        return const Color(0xFF8BC34A);
      case 3:
        return const Color(0xFFFFB300);
      case 4:
        return const Color(0xFFFF9800);
      case 5:
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getLabelForScore(int score) {
    switch (score) {
      case 1:
        return 'Leve / Mínimo';
      case 2:
        return 'Moderado Baixo';
      case 3:
        return 'Moderado / Atenção';
      case 4:
        return 'Significativo / Agudo';
      case 5:
        return 'Crítico / Alerta';
      default:
        return 'Nível $score';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getColorForLevel(score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Nível de Intensidade',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score / 5',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: activeColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _getLabelForScore(score),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: activeColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(5, (index) {
              final level = index + 1;
              final isFilled = level <= score;
              final segmentColor = isFilled ? _getColorForLevel(level) : Colors.grey.shade200;

              return Expanded(
                child: Container(
                  height: 10,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == 4 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: segmentColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
