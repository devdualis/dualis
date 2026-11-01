import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../domain/models/habit_day.dart';

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
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  Future<List<HabitDay>?> getHabits({
    int days = 30,
    String? profileId,
  }) async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final headers = <String, dynamic>{
        'Authorization': 'Bearer $token',
        if (profileId != null && profileId.isNotEmpty) 'X-Profile-Id': profileId,
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
        if (profileId != null && profileId.isNotEmpty) 'X-Profile-Id': profileId,
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
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteHabitDay(
    String day, {
    String? profileId,
  }) async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) return false;

      final headers = <String, dynamic>{
        'Authorization': 'Bearer $token',
        if (profileId != null && profileId.isNotEmpty) 'X-Profile-Id': profileId,
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
