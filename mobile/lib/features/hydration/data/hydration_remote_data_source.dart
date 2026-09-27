import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../domain/models/water_intake_log.dart';

final hydrationRemoteDataSourceProvider = Provider<HydrationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return HydrationRemoteDataSource(
    apiClient: apiClient,
    secureStorage: secureStorage,
  );
});

class HydrationRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  HydrationRemoteDataSource({
    ApiClient? apiClient,
    SecureStorageService? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  Future<WaterIntakeEntry?> logWater({
    required int amountMl,
    String source = 'manual',
    DateTime? timestamp,
  }) async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final response = await _apiClient.post(
        ApiEndpoints.hydrationLog,
        data: {
          'amountMl': amountMl,
          'source': source,
          if (timestamp != null) 'recordedAt': timestamp.toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return WaterIntakeEntry(
          remoteId: data['id'] as String?,
          userId: data['userId'] as String? ?? '',
          amountMl: data['amountMl'] as int? ?? amountMl,
          timestamp: data['recordedAt'] != null
              ? DateTime.parse(data['recordedAt'] as String)
              : (timestamp ?? DateTime.now()),
          source: data['source'] as String? ?? source,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<WaterIntakeEntry>?> getTodayLogs({DateTime? date}) async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date.toIso8601String();
      }

      final response = await _apiClient.get(
        ApiEndpoints.hydrationToday,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final rawLogs = data['logs'] as List<dynamic>? ?? [];
        return rawLogs.map((l) {
          final m = l as Map<String, dynamic>;
          return WaterIntakeEntry(
            remoteId: m['id'] as String?,
            userId: m['userId'] as String? ?? '',
            amountMl: m['amountMl'] as int? ?? 0,
            timestamp: m['recordedAt'] != null
                ? DateTime.parse(m['recordedAt'] as String)
                : DateTime.now(),
            source: m['source'] as String? ?? 'manual',
          );
        }).toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<DateTime, int>?> getHistoryTotals({
    int days = 7,
    DateTime? referenceDate,
  }) async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final queryParams = <String, dynamic>{
        'days': days,
        if (referenceDate != null) 'referenceDate': referenceDate.toIso8601String(),
      };

      final response = await _apiClient.get(
        ApiEndpoints.hydrationHistory,
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final rawTotals = data['totals'] as Map<String, dynamic>? ?? {};
        final result = <DateTime, int>{};
        rawTotals.forEach((dateStr, sum) {
          final parsedDate = DateTime.tryParse(dateStr);
          if (parsedDate != null) {
            result[DateTime(parsedDate.year, parsedDate.month, parsedDate.day)] =
                (sum as num).toInt();
          }
        });
        return result;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteLog(String remoteId) async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) return false;

      final response = await _apiClient.delete(
        ApiEndpoints.hydrationLogItem(remoteId),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
