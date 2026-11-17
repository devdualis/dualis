import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Replaces a screen body when the active shared profile did not grant this
/// area, so an empty list never reads as "nothing recorded". Only the body is
/// replaced: the global urgent-help button stays on top.
class NotSharedPlaceholder extends StatelessWidget {
  const NotSharedPlaceholder({super.key, required this.profileName});

  final String profileName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      key: const ValueKey('category-not-shared'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DuotoneIconTile(
                size: 56,
                radius: 18,
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 28,
                  color: AppColors.dualisNavy,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.profileCategoryNotSharedTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dualisNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.profileCategoryNotSharedBody(profileName),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.4,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
