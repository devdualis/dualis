import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

final privacyRemoteDataSourceProvider = Provider<PrivacyRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PrivacyRemoteDataSource(client: apiClient);
});

class PrivacyRemoteDataSource {
  final ApiClient apiClient;

  PrivacyRemoteDataSource({ApiClient? client})
      : apiClient = client ?? ApiClient();

  Future<Map<String, dynamic>> exportUserData({required String token}) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.exportData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> deleteUserAccount({
    required String token,
    required String password,
  }) async {
    final response = await apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.deleteAccount,
      data: {
        'password': password,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return response.data ?? {};
  }
}
