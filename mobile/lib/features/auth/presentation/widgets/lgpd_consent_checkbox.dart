import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';

class LgpdConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const LgpdConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  void _showDisclaimerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.lgpdConsentSheetTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.lgpdConsentSheetBody,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.lgpdConsentSheetBasesTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.lgpdConsentSheetBases,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.push(RoutePaths.termsOfService);
                          },
                          child: Text(l10n.lgpdConsentViewTerms),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.softIndigo,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.push(RoutePaths.privacyPolicy);
                          },
                          child: Text(l10n.lgpdConsentViewPolicy),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CheckboxListTile(
      key: const Key('lgpdConsentCheckbox'),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.softIndigo,
      title: Text.rich(
        TextSpan(
          text: l10n.lgpdConsentPrefix,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textPrimaryLight,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: l10n.lgpdConsentTermsLink,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.softIndigo,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.push(RoutePaths.termsOfService),
            ),
            TextSpan(text: l10n.lgpdConsentAnd),
            TextSpan(
              text: l10n.lgpdConsentPrivacyLink,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.softIndigo,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.push(RoutePaths.privacyPolicy),
            ),
            TextSpan(text: l10n.lgpdConsentSuffix),
            TextSpan(
              text: l10n.lgpdConsentLearnMore,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.clinicalTealDark,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _showDisclaimerBottomSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}
