import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../house_ads/domain/house_ad.dart';

/// Free build: the "Meus cuidados" tab shows what Premium adds and links to
/// the plans on the Dualis site (approved mockup, option 2).
class PremiumPromoScreen extends StatelessWidget {
  const PremiumPromoScreen({super.key});

  Future<void> _subscribe() async {
    try {
      await launchUrl(
        Uri.parse(dualisPremiumUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final features = [
      (
        Icons.vaccines_outlined,
        AppColors.clinicalTealLight,
        AppColors.clinicalTealDark,
        l10n.premiumPromoVaccines,
        l10n.premiumPromoVaccinesDesc,
      ),
      (
        Icons.block_rounded,
        const Color(0xFFFFF8E1),
        const Color(0xFFB26A00),
        l10n.premiumPromoAllergies,
        l10n.premiumPromoAllergiesDesc,
      ),
      (
        Icons.medication_outlined,
        AppColors.softIndigoLight,
        AppColors.dualisNavy,
        l10n.premiumPromoMedication,
        l10n.premiumPromoMedicationDesc,
      ),
      (
        Icons.calendar_month_outlined,
        const Color(0xFFE8F5E9),
        const Color(0xFF2E7D32),
        l10n.premiumPromoAppointments,
        l10n.premiumPromoAppointmentsDesc,
      ),
      (
        Icons.folder_outlined,
        const Color(0xFFF1F5F9),
        const Color(0xFF334155),
        l10n.premiumPromoExams,
        l10n.premiumPromoExamsDesc,
      ),
      (
        Icons.picture_as_pdf_outlined,
        AppColors.clinicalTealLight,
        AppColors.clinicalTealDark,
        l10n.premiumPromoPdf,
        l10n.premiumPromoPdfDesc,
      ),
    ];

    return Column(
      key: const Key('premium_promo_screen'),
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Hero(l10n: l10n),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                // Two columns that grow with the text size instead of a fixed grid.
                child: LayoutBuilder(
                  builder:
                      (context, box) => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final (icon, bg, fg, title, desc) in features)
                            Container(
                              width: (box.maxWidth - 10) / 2,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.outlineLight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(icon, size: 19, color: fg),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: AppColors.backgroundLight,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('premium_promo_subscribe'),
                  onPressed: _subscribe,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dualisNavy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.premiumPromoCta,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.premiumPromoNote,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final AppLocalizations l10n;

  const _Hero({required this.l10n});

  /// (asset, rotation, horizontal offset from centre, top). Last is on top.
  static const _screens = [
    ('lib/assets/brand/premium_screen_medication.png', -0.14, -100.0, 34.0),
    ('lib/assets/brand/premium_screen_exams.png', 0.14, 100.0, 34.0),
    ('lib/assets/brand/premium_screen_care.png', 0.0, 0.0, 0.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.dualisNavy,
            AppColors.dualisSymbolBlue,
            AppColors.dualisSymbolCyan,
          ],
          stops: [0, 0.75, 1],
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.premiumPromoBadge.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.premiumPromoTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.premiumPromoSubtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.4,
                    color: const Color(0xFFE0F4FB),
                  ),
                ),
              ],
            ),
          ),
          // Fan of three real Premium screens, centre one on top.
          Positioned(
            left: 0,
            right: 0,
            bottom: -130,
            height: 300,
            child: LayoutBuilder(
              builder: (context, box) {
                const w = 120.0;
                final centre = (box.maxWidth - w) / 2;
                return Stack(
                  children: [
                    for (final (asset, angle, dx, top) in _screens)
                      Positioned(
                        top: top,
                        left: centre + dx,
                        child: Transform.rotate(
                          angle: angle,
                          child: Image.asset(asset, width: w),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
