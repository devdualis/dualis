import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/dualis_logo.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          l10n.termsAppBarTitle,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight),
          onPressed: () => context.canPop() ? context.pop() : context.go(RoutePaths.settings),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineLight),
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
                    const DualisLogo(
                      variant: DualisLogoVariant.horizontal,
                      width: 140,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.termsHeaderTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.termsVersionLine,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      l10n.termsIntro,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1
              _LegalSectionCard(
                title: l10n.termsSection1Title,
                icon: Icons.assignment_turned_in_outlined,
                color: AppColors.clinicalTeal,
                content: l10n.termsSection1Body,
              ),
              const SizedBox(height: 16),

              // Section 2: intended use (wellness, not a medical device)
              _LegalSectionCard(
                title: l10n.termsSection2Title,
                icon: Icons.spa_outlined,
                color: AppColors.clinicalTeal,
                content: l10n.termsSection2Body,
                bullets: [
                  l10n.termsSection2Bullet1,
                  l10n.termsSection2Bullet2,
                  l10n.termsSection2Bullet3,
                ],
              ),
              const SizedBox(height: 16),

              // Section 3
              _LegalSectionCard(
                title: l10n.termsSection3Title,
                icon: Icons.credit_card_outlined,
                color: AppColors.softIndigo,
                content: l10n.termsSection3Body,
                bullets: [
                  l10n.termsSection3Bullet1,
                  l10n.termsSection3Bullet2,
                  l10n.termsSection3Bullet3,
                ],
              ),
              const SizedBox(height: 16),

              // Section 4
              _LegalSectionCard(
                title: l10n.termsSection4Title,
                icon: Icons.copyright_outlined,
                color: AppColors.clinicalTealDark,
                content: l10n.termsSection4Body,
              ),
              const SizedBox(height: 16),

              // Section 5
              _LegalSectionCard(
                title: l10n.termsSection5Title,
                icon: Icons.shield_outlined,
                color: AppColors.softIndigo,
                content: l10n.termsSection5Body,
              ),
              const SizedBox(height: 16),

              // Section 6
              _LegalSectionCard(
                title: l10n.termsSection6Title,
                icon: Icons.gavel_outlined,
                color: AppColors.textPrimaryLight,
                content: l10n.termsSection6Body,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  final List<String>? bullets;

  const _LegalSectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          if (bullets != null && bullets!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...bullets!.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bullet,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
