import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/domain/home_greeting.dart';
import '../data/house_ads_repository.dart';
import '../domain/house_ad.dart';

/// Native, non-blocking house ad card labelled "Anúncio" (strategy §14).
/// It takes no parameters about the journal on purpose: the ad can never
/// depend on what the person recorded.
class HouseAdCard extends ConsumerWidget {
  const HouseAdCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final remote = ref.watch(houseAdsProvider).value;
    final ads = remote ?? bundledHouseAds(l10n);
    final ad = pickHouseAd(ads, ref.read(homeClockProvider)());
    if (ad == null) return const SizedBox.shrink();
    return HouseAdView(ad: ad);
  }
}

class HouseAdView extends StatelessWidget {
  final HouseAd ad;

  const HouseAdView({super.key, required this.ad});

  Future<void> _open() async {
    final uri = Uri.tryParse(ad.url);
    if (uri == null || !uri.hasScheme) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasLink = Uri.tryParse(ad.url)?.hasScheme ?? false;
    final style = _BrandStyle.of(houseAdBrandKey(ad), l10n);
    if (style != null) {
      return _BrandAdCard(ad: ad, style: style, onOpen: hasLink ? _open : null);
    }
    return Container(
      key: const Key('house_ad_card'),
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.outlineLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.xv2AdLabel,
                  key: const Key('house_ad_label'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                ad.brand,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdLogo(ad: ad),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.body,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasLink) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _open,
                child: Text(l10n.xv2AdLearnMore),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Logo placeholder drawn in code until real brand assets exist.
class _AdLogo extends StatelessWidget {
  final HouseAd ad;

  const _AdLogo({required this.ad});

  static const Map<String, (IconData, Color)> _bundled = {
    'dualis_premium': (Icons.workspace_premium_rounded, AppColors.dualisNavy),
  };

  @override
  Widget build(BuildContext context) {
    final url = ad.imageUrl;
    if (url != null && url.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final (icon, color) =
        _bundled[ad.assetKey] ??
        (Icons.campaign_outlined, AppColors.dualisNavy);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

/// e-BEF symbol from its brand manual: circle (outline), square (filled),
/// triangle (outline), diamond (filled), in that order.
const String _ebefSymbolSvg =
    '<svg viewBox="0 0 92 22" xmlns="http://www.w3.org/2000/svg">'
    '<circle cx="10" cy="11" r="8.5" fill="none" stroke="#F7F8FA" stroke-width="2.4"/>'
    '<rect x="25" y="2.5" width="17" height="17" fill="#007C83"/>'
    '<polygon points="57,2.5 66.5,19.5 47.5,19.5" fill="none" stroke="#F7F8FA" stroke-width="2.4" stroke-linejoin="round"/>'
    '<polygon points="81,1.5 90.5,11 81,20.5 71.5,11" fill="#007C83"/></svg>';

/// Look of the large card for each of our own brands, taken from their sites
/// and brand guides.
class _BrandStyle {
  final Decoration background;
  final Color accentBar;
  final Color title;
  final Color body;
  final Color labelBg;
  final Color labelText;
  final Color chipBg;
  final Color chipText;
  final Color buttonBg;
  final Color buttonText;
  final Color footnoteColor;
  final Widget logo;
  final String tags;
  final String cta;
  final String footnote;
  final String? screenshot;

  const _BrandStyle({
    required this.background,
    required this.accentBar,
    required this.title,
    required this.body,
    required this.labelBg,
    required this.labelText,
    required this.chipBg,
    required this.chipText,
    required this.buttonBg,
    required this.buttonText,
    required this.footnoteColor,
    required this.logo,
    required this.tags,
    required this.cta,
    required this.footnote,
    this.screenshot,
  });

  static _BrandStyle? of(String? key, AppLocalizations l10n) {
    switch (key) {
      case 'dualis_premium':
        return _BrandStyle(
          background: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.dualisNavy,
                AppColors.dualisSymbolBlue,
                AppColors.dualisSymbolCyan,
              ],
              stops: [0, 0.7, 1],
            ),
          ),
          accentBar: AppColors.dualisSymbolGreen,
          title: Colors.white,
          body: const Color(0xFFE0F4FB),
          labelBg: Colors.white.withValues(alpha: 0.18),
          labelText: Colors.white,
          chipBg: Colors.white.withValues(alpha: 0.16),
          chipText: Colors.white,
          buttonBg: Colors.white,
          buttonText: AppColors.dualisNavy,
          footnoteColor: const Color(0xFFE0F4FB),
          logo: Image.asset(
            'lib/assets/brand/dualis_logo_reverse_white.png',
            height: 24,
          ),
          tags: l10n.xv2AdPremiumTags,
          cta: l10n.xv2AdPremiumCta,
          footnote: l10n.xv2AdPremiumPrice,
          screenshot: 'lib/assets/brand/premium_screen_care.png',
        );
      case 'zoc':
        return _BrandStyle(
          background: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x260F8F8A)),
          ),
          accentBar: const Color(0xFF0F8F8A),
          title: const Color(0xFF101827),
          body: const Color(0xFF475569),
          labelBg: const Color(0xFFE6F4F3),
          labelText: const Color(0xFF0F8F8A),
          chipBg: const Color(0xFFE6F4F3),
          chipText: const Color(0xFF0B6E6A),
          buttonBg: const Color(0xFF0F8F8A),
          buttonText: Colors.white,
          footnoteColor: const Color(0xFF0F8F8A),
          logo: Image.asset('lib/assets/brand/house_ad_zoc.png', height: 28),
          tags: l10n.xv2AdZocTags,
          cta: l10n.xv2AdZocCta,
          footnote: 'zoctec.com',
        );
      case 'ebef':
        return _BrandStyle(
          background: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.4,
              colors: [Color(0xFF1E5A8A), Color(0xFF0B2745)],
              stops: [0, 0.6],
            ),
          ),
          accentBar: const Color(0xFF007C83),
          title: const Color(0xFFF7F8FA),
          body: const Color(0xFFC9D6E2),
          labelBg: const Color(0x24F7F8FA),
          labelText: const Color(0xFFF7F8FA),
          chipBg: const Color(0x40007C83),
          chipText: const Color(0xFFBFEDEF),
          buttonBg: const Color(0xFF007C83),
          buttonText: Colors.white,
          footnoteColor: const Color(0xFF5FC7CC),
          logo: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.string(_ebefSymbolSvg, height: 20),
              const SizedBox(width: 10),
              Text(
                'e-BEF',
                style: GoogleFonts.inter(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: const Color(0xFFF7F8FA),
                ),
              ),
            ],
          ),
          tags: l10n.xv2AdEbefTags,
          cta: l10n.xv2AdEbefCta,
          footnote: 'e-ubo.com',
        );
    }
    return null;
  }
}

/// Large ad card in the brand's own colours (approved mockup, option A).
class _BrandAdCard extends StatelessWidget {
  final HouseAd ad;
  final _BrandStyle style;
  final VoidCallback? onOpen;

  const _BrandAdCard({required this.ad, required this.style, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shot = style.screenshot;
    final textWidth = shot == null ? double.infinity : 230.0;
    return Container(
      key: const Key('house_ad_card'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: style.background,
          child: InkWell(
            onTap: onOpen,
            child: Stack(
              children: [
                if (shot != null)
                  Positioned(
                    right: -26,
                    top: 56,
                    child: Transform.rotate(
                      angle: 0.14,
                      child: Image.asset(shot, width: 118),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 5, color: style.accentBar),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              style.logo,
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: style.labelBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.xv2AdLabel,
                                  key: const Key('house_ad_label'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: style.labelText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: textWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ad.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: style.title,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ad.body,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    height: 1.45,
                                    color: style.body,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final tag in style.tags.split('|'))
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: style.chipBg,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: style.chipText,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Container(
                                key: const Key('house_ad_cta'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: style.buttonBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '${style.cta} →',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: style.buttonText,
                                  ),
                                ),
                              ),
                              Text(
                                style.footnote,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: style.footnoteColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
