import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/dualis_logo.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          l10n.privacyPolicyAppBarTitle,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight),
          onPressed: () => context.canPop() ? context.pop() : context.go(RoutePaths.privacyCenter),
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
                      l10n.privacyPolicyHeaderTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.privacyPolicyHeaderSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.clinicalTealDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      l10n.privacyPolicyIntro,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.clinicalTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.clinicalTeal, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.privacyPolicyDpoLine,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1
              _PrivacySectionCard(
                title: l10n.privacyPolicySection1Title,
                icon: Icons.folder_shared_outlined,
                color: AppColors.clinicalTeal,
                content: l10n.privacyPolicySection1Body,
                bullets: [
                  l10n.privacyPolicySection1Bullet1,
                  l10n.privacyPolicySection1Bullet2,
                  l10n.privacyPolicySection1Bullet3,
                  l10n.privacyPolicySection1Bullet4,
                ],
              ),
              const SizedBox(height: 16),

              // Section 2: purposes (L-04)
              _PrivacySectionCard(
                title: l10n.privacyPolicySection2Title,
                icon: Icons.health_and_safety_outlined,
                color: AppColors.softIndigo,
                content: l10n.privacyPolicySection2Body,
                bullets: [
                  l10n.privacyPolicySection2Bullet1,
                  l10n.privacyPolicySection2Bullet2,
                  l10n.privacyPolicySection2Bullet3,
                  l10n.privacyPolicySection2Bullet4,
                ],
              ),
              const SizedBox(height: 16),

              // Section 3: processors and international transfer (LGPD Art. 33)
              _PrivacySectionCard(
                title: l10n.privacyPolicySection3Title,
                icon: Icons.public_outlined,
                color: AppColors.clinicalTealDark,
                content: l10n.privacyPolicySection3Body,
                bullets: [
                  l10n.privacyPolicySection3Bullet1,
                  l10n.privacyPolicySection3Bullet4,
                  l10n.privacyPolicySection3Bullet2,
                  l10n.privacyPolicySection3Bullet3,
                ],
              ),
              const SizedBox(height: 16),

              // Section 4
              _PrivacySectionCard(
                title: l10n.privacyPolicySection4Title,
                icon: Icons.lock_clock_outlined,
                color: AppColors.clinicalTealDark,
                content: l10n.privacyPolicySection4Body,
                bullets: [
                  l10n.privacyPolicySection4Bullet1,
                  l10n.privacyPolicySection4Bullet2,
                ],
              ),
              const SizedBox(height: 16),

              // Section 5
              _PrivacySectionCard(
                title: l10n.privacyPolicySection5Title,
                icon: Icons.shield_moon_outlined,
                color: AppColors.clinicalTeal,
                content: l10n.privacyPolicySection5Body,
                bullets: [
                  l10n.privacyPolicySection5Bullet1,
                  l10n.privacyPolicySection5Bullet2,
                  l10n.privacyPolicySection5Bullet3,
                ],
              ),
              const SizedBox(height: 16),

              // Section 6
              _PrivacySectionCard(
                title: l10n.privacyPolicySection6Title,
                icon: Icons.security_rounded,
                color: AppColors.softIndigo,
                content: l10n.privacyPolicySection6Body,
                bullets: [
                  l10n.privacyPolicySection6Bullet1,
                  l10n.privacyPolicySection6Bullet2,
                  l10n.privacyPolicySection6Bullet3,
                ],
              ),
              const SizedBox(height: 16),

              // Section 7
              _PrivacySectionCard(
                title: l10n.privacyPolicySection7Title,
                icon: Icons.notifications_none_rounded,
                color: AppColors.textPrimaryLight,
                content: l10n.privacyPolicySection7Body,
                bullets: [
                  l10n.privacyPolicySection7Bullet1,
                  l10n.privacyPolicySection7Bullet2,
                ],
              ),
              const SizedBox(height: 24),

              // Quick Action Button to Privacy Center
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.clinicalTeal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.clinicalTeal.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.privacyPolicyCtaQuestion,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.clinicalTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.push(RoutePaths.privacyCenter),
                      icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                      label: Text(l10n.privacyPolicyCtaButton),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  final List<String>? bullets;

  const _PrivacySectionCard({
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
