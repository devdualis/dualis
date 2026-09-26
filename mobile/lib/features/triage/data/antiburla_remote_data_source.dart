import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage_service.dart';

final antiburlaDataSourceProvider = Provider<AntiburlaRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AntiburlaRemoteDataSource(apiClient: apiClient, secureStorage: secureStorage);
});

class AntiburlaCheckResult {
  final bool triggered;
  final int? daysAgo;
  final String? previousRecordedAt;
  final String? previousCategoryLabel;
  final String? empatheticPrompt;
  final bool biologicalDiscordance;
  final String? biologicalNotice;

  const AntiburlaCheckResult({
    required this.triggered,
    this.daysAgo,
    this.previousRecordedAt,
    this.previousCategoryLabel,
    this.empatheticPrompt,
    this.biologicalDiscordance = false,
    this.biologicalNotice,
  });

  factory AntiburlaCheckResult.fromJson(Map<String, dynamic> json) {
    return AntiburlaCheckResult(
      triggered: json['triggered'] as bool? ?? false,
      daysAgo: json['daysAgo'] as int?,
      previousRecordedAt: json['previousRecordedAt'] as String?,
      previousCategoryLabel: json['previousCategoryLabel'] as String?,
      empatheticPrompt: json['empatheticPrompt'] as String?,
      biologicalDiscordance: json['biologicalDiscordance'] as bool? ?? false,
      biologicalNotice: json['biologicalNotice'] as String?,
    );
  }
}

class AntiburlaRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  AntiburlaRemoteDataSource({
    ApiClient? apiClient,
    SecureStorageService? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  Future<AntiburlaCheckResult> checkConsistency({
    required String vertical,
    required String category,
    required String selectedPersistence,
    String? narrative,
    String? token,
  }) async {
    try {
      final authToken = token ?? await _secureStorage.getAccessToken();
      final response = await _apiClient.post(
        ApiEndpoints.antiburlaCheck,
        data: {
          'vertical': vertical,
          'category': category,
          'selectedPersistence': selectedPersistence,
          if (narrative != null && narrative.isNotEmpty) 'narrative': narrative,
        },
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      if (response.data is Map<String, dynamic>) {
        return AntiburlaCheckResult.fromJson(response.data as Map<String, dynamic>);
      }
      return const AntiburlaCheckResult(triggered: false);
    } catch (_) {
      return const AntiburlaCheckResult(triggered: false);
    }
  }
}
