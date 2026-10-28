import 'package:flutter/material.dart';
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
    'zoc': (Icons.spa_rounded, Color(0xFF2E7D6B)),
    'wgi': (Icons.local_florist_rounded, Color(0xFF5B5BA8)),
    'ubo': (Icons.wb_twilight_rounded, Color(0xFFB0643A)),
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
        _bundled[ad.assetKey] ?? (Icons.campaign_outlined, AppColors.dualisNavy);
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
