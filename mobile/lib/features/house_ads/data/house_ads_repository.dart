import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/house_ad.dart';

final houseAdsRepositoryProvider = Provider<HouseAdsRepository>((ref) {
  return HouseAdsRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
});

/// Remote ads, or null to use the bundled ones. The request carries no
/// journal data: it is a plain GET without parameters.
final houseAdsProvider = FutureProvider<List<HouseAd>?>((ref) {
  return ref.watch(houseAdsRepositoryProvider).fetchAds();
});

class HouseAdsRepository {
  static const String waterAdDayKey = 'dualis_xv2_water_ad_day';

  final ApiClient _apiClient;
  final SecureStorageService _storage;

  HouseAdsRepository({
    required ApiClient apiClient,
    required SecureStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  Future<List<HouseAd>?> fetchAds() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.houseAds);
      final data = response.data;
      final raw = data is Map ? data['ads'] : null;
      if (raw is! List) return null;
      final ads = raw
          .whereType<Map>()
          .map((e) => HouseAd.fromJson(Map<String, dynamic>.from(e)))
          .where((ad) => ad.isValid)
          .toList();
      return ads.isEmpty ? null : ads;
    } catch (_) {
      return null;
    }
  }

  /// The ad after logging water shows at most once per day (strategy §14).
  /// Returns true the first time it is called on a given local day.
  Future<bool> takeWaterAdSlot(DateTime now) async {
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      if (await _storage.read(key: waterAdDayKey) == today) return false;
      await _storage.write(key: waterAdDayKey, value: today);
      return true;
    } catch (_) {
      return false;
    }
  }
}
