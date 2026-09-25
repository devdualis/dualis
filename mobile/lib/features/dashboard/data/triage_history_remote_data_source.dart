import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../domain/models/triage_history_models.dart';

final triageHistoryDataSourceProvider = Provider<TriageHistoryRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return TriageHistoryRemoteDataSource(apiClient: apiClient, secureStorage: secureStorage);
});

class TriageHistoryRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  TriageHistoryRemoteDataSource({
    ApiClient? apiClient,
    SecureStorageService? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async {
    try {
      final token = await _secureStorage.getAccessToken();
      final response = await _apiClient.get(
        ApiEndpoints.triageHistory,
        queryParameters: {'days': days},
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );

      if (response.data is Map<String, dynamic>) {
        return TriageHistoryResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return TriageHistoryResponse.empty();
    } catch (_) {
      return TriageHistoryResponse.empty();
    }
  }

  Future<bool> deleteHistoryItem(String id) async {
    try {
      final token = await _secureStorage.getAccessToken();
      final response = await _apiClient.delete(
        ApiEndpoints.triageHistoryItem(id),
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
