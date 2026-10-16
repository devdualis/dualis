import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class DualAxisStaticNote extends StatelessWidget {
  const DualAxisStaticNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softIndigo.withValues(alpha: 0.25)),
      ),
      child: Text(
        l10n.outcomeDualAxisNote,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          height: 1.4,
          color: Colors.black87,
        ),
      ),
    );
  }
}
