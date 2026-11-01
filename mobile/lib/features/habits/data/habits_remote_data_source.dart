import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../domain/models/habit_day.dart';

/// Answers that will never succeed on retry (the server rejected this write).
/// 401, 408 and 429 are left out: the write stays pending and is sent again.
bool isPermanentHabitRejection(int? status) =>
    status == 400 ||
    status == 403 ||
    status == 404 ||
    status == 409 ||
    status == 422;

class HabitClientException implements Exception {
  final int statusCode;
  final dynamic data;
  const HabitClientException(this.statusCode, [this.data]);

  @override
  String toString() => 'HabitClientException($statusCode): $data';
}

final habitsRemoteDataSourceProvider = Provider<HabitsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return HabitsRemoteDataSource(
    apiClient: apiClient,
    secureStorage: secureStorage,
  );
});

class HabitsRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  HabitsRemoteDataSource({
    ApiClient? apiClient,
    SecureStorageService? secureStorage,
  }) : _apiClient = apiClient ?? ApiClient(),
       _secureStorage = secureStorage ?? SecureStorageService();

  Future<List<HabitDay>?> getHabits({int days = 30, String? profileId}) async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final headers = <String, dynamic>{
        'Authorization': 'Bearer $token',
        if (profileId != null && profileId.isNotEmpty)
          'X-Profile-Id': profileId,
      };

      final response = await _apiClient.get(
        ApiEndpoints.habits,
        queryParameters: {'days': days},
        options: Options(headers: headers),
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final rawDays = data['days'] as List<dynamic>? ?? [];
        return rawDays
            .map((item) => HabitDay.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<HabitDay?> saveHabitDay(
    String day,
    HabitDay habitDay, {
    String? profileId,
  }) async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final headers = <String, dynamic>{
        'Authorization': 'Bearer $token',
        if (profileId != null && profileId.isNotEmpty)
          'X-Profile-Id': profileId,
      };

      final response = await _apiClient.put(
        ApiEndpoints.habitDay(day),
        data: habitDay.toPutPayload(),
        options: Options(headers: headers),
      );

      if (response.data is Map<String, dynamic>) {
        return HabitDay.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (isPermanentHabitRejection(code)) {
        throw HabitClientException(code!, e.response?.data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteHabitDay(String day, {String? profileId}) async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) return false;

      final headers = <String, dynamic>{
        'Authorization': 'Bearer $token',
        if (profileId != null && profileId.isNotEmpty)
          'X-Profile-Id': profileId,
      };

      final response = await _apiClient.delete(
        ApiEndpoints.habitDay(day),
        options: Options(headers: headers),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
