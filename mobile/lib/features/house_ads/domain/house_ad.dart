import '../../../l10n/app_localizations.dart';

/// Native house ad (strategy §14): own products only, no third-party SDK.
/// Identical for everyone and never built from what the person recorded.
class HouseAd {
  final String id;
  final String brand;
  final String title;
  final String body;
  final String? imageUrl;
  final String? assetKey;
  final String url;

  const HouseAd({
    required this.id,
    required this.brand,
    required this.title,
    required this.body,
    this.imageUrl,
    this.assetKey,
    this.url = '',
  });

  factory HouseAd.fromJson(Map<String, dynamic> json) {
    return HouseAd(
      id: json['id']?.toString() ?? '',
      brand: json['brand'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      assetKey: json['assetKey'] as String?,
      url: json['url'] as String? ?? '',
    );
  }

  bool get isValid => id.isNotEmpty && brand.isNotEmpty && title.isNotEmpty;
}

/// Brand key without the `house_ad_` prefix the API uses, so remote and
/// bundled ads share the same look.
String? houseAdBrandKey(HouseAd ad) => ad.assetKey?.replaceFirst('house_ad_', '');

/// Plans section of the Dualis site, where Premium is sold for now.
const String dualisPremiumUrl = 'https://dualischeckup.com/#pricing';

/// Bundled ads used when `/v1/house-ads` is not reachable: our own apps
/// (alpha test list, 2026-10-30).
List<HouseAd> bundledHouseAds(AppLocalizations l10n) => [
      HouseAd(
        id: 'bundled-dualis-premium',
        brand: 'Dualis Premium',
        title: l10n.xv2AdPremiumTitle,
        body: l10n.xv2AdPremiumBody,
        assetKey: 'dualis_premium',
        url: dualisPremiumUrl,
      ),
      HouseAd(
        id: 'bundled-zoc',
        brand: 'ZOC',
        title: l10n.xv2AdZocTitle,
        body: l10n.xv2AdZocBody,
        assetKey: 'zoc',
        url: 'https://www.zoctec.com',
      ),
      HouseAd(
        id: 'bundled-ebef',
        brand: 'e-BEF',
        title: l10n.xv2AdEbefTitle,
        body: l10n.xv2AdEbefBody,
        assetKey: 'ebef',
        url: 'https://e-bef.com.br',
      ),
    ];

/// The ad of the day: depends only on the date, so everyone sees the same.
HouseAd? pickHouseAd(List<HouseAd> ads, DateTime now) {
  if (ads.isEmpty) return null;
  final dayIndex =
      DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay;
  return ads[dayIndex % ads.length];
}
