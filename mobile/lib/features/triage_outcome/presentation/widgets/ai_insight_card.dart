import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class AiInsightCard extends StatelessWidget {
  final String? mappedLayTerm;
  final String? bodyAreaOrMood;

  const AiInsightCard({
    super.key,
    required this.mappedLayTerm,
    this.bodyAreaOrMood,
  });

  bool get _hasContent =>
      (mappedLayTerm != null && mappedLayTerm!.trim().isNotEmpty) ||
      (bodyAreaOrMood != null && bodyAreaOrMood!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

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
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.softIndigo,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.outcomeAiInsightTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.softIndigo,
                  ),
                ),
                if (mappedLayTerm != null && mappedLayTerm!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.outcomeAiInsightLayTerm(mappedLayTerm!.trim()),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ],
                if (bodyAreaOrMood != null && bodyAreaOrMood!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.outcomeAiInsightArea(bodyAreaOrMood!.trim()),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
