import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/dualis_logo.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/glass_card.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundDepth,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDepth,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.privacyPolicyAppBarTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.2,
            color: AppColors.dualisNavy,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.dualisNavy),
          onPressed: () => context.canPop() ? context.pop() : context.go(RoutePaths.privacyCenter),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              SizedBox(width: double.infinity, child: GlassCard(padding: const EdgeInsets.all(20), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DualisLogo(
                      variant: DualisLogoVariant.horizontal,
                      width: 140,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.privacyPolicyHeaderTitle,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.privacyPolicyHeaderSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.dualisNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      l10n.privacyPolicyIntro,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.iconTileTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.dualisNavy, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.privacyPolicyDpoLine,
                              style: GoogleFonts.inter(
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
                ))),
              const SizedBox(height: 20),

              // Section 1
              _PrivacySectionCard(
                title: l10n.privacyPolicySection1Title,
                icon: Icons.folder_shared_outlined,
                color: AppColors.dualisNavy,
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
                color: AppColors.dualisNavy,
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
                color: AppColors.dualisNavy,
                content: l10n.privacyPolicySection3Body,
                bullets: [
                  l10n.privacyPolicySection3Bullet1,
                  l10n.privacyPolicySection3Bullet2,
                  l10n.privacyPolicySection3Bullet3,
                  l10n.privacyPolicySection3BulletMap,
                  l10n.privacyPolicySection3Bullet4,
                  l10n.privacyPolicySection3Bullet5,
                  l10n.privacyPolicySection3Bullet6,
                ],
              ),
              const SizedBox(height: 16),

              // Section 4
              _PrivacySectionCard(
                title: l10n.privacyPolicySection4Title,
                icon: Icons.lock_clock_outlined,
                color: AppColors.dualisNavy,
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
                color: AppColors.dualisNavy,
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
                color: AppColors.dualisNavy,
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
              const SizedBox(height: 16),

              // Section 8: AI journal suggestions (specific consent, LGPD
              // Art. 11, I). Mirrors section 7 of the API privacy policy.
              _PrivacySectionCard(
                title: l10n.privacyPolicySection8Title,
                icon: Icons.auto_awesome_outlined,
                color: AppColors.dualisNavy,
                content: l10n.privacyPolicySection8Body,
                bullets: [
                  l10n.privacyPolicySection8Bullet1,
                  l10n.privacyPolicySection8Bullet2,
                  l10n.privacyPolicySection8Bullet3,
                  l10n.privacyPolicySection8Bullet4,
                  l10n.privacyPolicySection8Bullet5,
                  l10n.privacyPolicySection8Bullet6,
                ],
              ),
              const SizedBox(height: 24),

              // Quick Action Button to Privacy Center
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.iconTileTint,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.dualisNavy.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.privacyPolicyCtaQuestion,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dualisNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
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
    return SizedBox(width: double.infinity, child: GlassCard(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DuotoneIconTile(size: 36, radius: 11, child: Icon(icon, color: AppColors.dualisNavy, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
      )));
  }
}
