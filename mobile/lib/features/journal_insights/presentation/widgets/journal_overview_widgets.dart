import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';

/// Glass card with a title (and an optional duotone icon tile), shared by the
/// dashboard sections.
class InsightsCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  const InsightsCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassEdge),
        boxShadow: AppColors.glassShadow(blur: 24, alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon == null)
            titleBlock
          else
            Row(
              children: [
                DuotoneIconTile(
                  size: 32,
                  radius: 10,
                  child: Icon(icon, size: 18, color: AppColors.dualisNavy),
                ),
                const SizedBox(width: 10),
                Expanded(child: titleBlock),
              ],
            ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
