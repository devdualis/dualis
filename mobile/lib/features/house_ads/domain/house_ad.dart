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

/// Bundled demo ads used when `/v1/house-ads` is not reachable. ZOC, WGI and
/// UBO are fictional internal examples (strategy §18, decision 3).
List<HouseAd> bundledHouseAds(AppLocalizations l10n) => [
      HouseAd(
        id: 'bundled-dualis-premium',
        brand: 'Dualis Premium',
        title: l10n.xv2AdPremiumTitle,
        body: l10n.xv2AdPremiumBody,
        assetKey: 'dualis_premium',
      ),
      HouseAd(
        id: 'bundled-zoc',
        brand: 'ZOC',
        title: l10n.xv2AdZocTitle,
        body: l10n.xv2AdZocBody,
        assetKey: 'zoc',
      ),
      HouseAd(
        id: 'bundled-wgi',
        brand: 'WGI',
        title: l10n.xv2AdWgiTitle,
        body: l10n.xv2AdWgiBody,
        assetKey: 'wgi',
      ),
      HouseAd(
        id: 'bundled-ubo',
        brand: 'UBO',
        title: l10n.xv2AdUboTitle,
        body: l10n.xv2AdUboBody,
        assetKey: 'ubo',
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
