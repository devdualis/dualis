import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/value_card_item.dart';

class CarouselCard extends StatelessWidget {
  final ValueCardItem item;

  const CarouselCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: 28,
        child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DuotoneIconTile(
                size: 72,
                radius: 22,
                child: Icon(
                  item.icon,
                  size: 36,
                  color: AppColors.dualisNavy,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.getTitle(l10n),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: AppColors.dualisNavy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.getBody(l10n),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
