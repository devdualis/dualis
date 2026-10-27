import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/journal_insights_models.dart';

final journalInsightsDataSourceProvider =
    Provider<JournalInsightsRemoteDataSource>((ref) {
  return JournalInsightsRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

/// Read side of the journal v2 API: entries and counts for the dashboard.
class JournalInsightsRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  JournalInsightsRemoteDataSource({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  Future<Options> _auth() async {
    final token = await _secureStorage.getAccessToken();
    return Options(
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
  }

  /// Newest first, legacy rows included. Throws when the API fails.
  Future<List<JournalEntryView>> fetchEntries({int days = 30}) async {
    final response = await _apiClient.get(
      ApiEndpoints.journalEntries,
      queryParameters: {'days': days},
      options: await _auth(),
    );
    final data = response.data;
    final raw = data is Map ? data['entries'] : null;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => JournalEntryView.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Null when the summary endpoint is unavailable (the app computes it).
  Future<JournalSummary?> fetchSummary({int days = 30}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.journalSummary,
        queryParameters: {'days': days},
        options: await _auth(),
      );
      final data = response.data;
      if (data is Map) {
        return JournalSummary.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteEntry(String id) async {
    try {
      final options = await _auth();
      options.headers!['Content-Type'] = null;
      final response = await _apiClient.delete(
        ApiEndpoints.journalEntry(id),
        options: options,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
