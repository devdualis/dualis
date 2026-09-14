import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

final antiburlaDataSourceProvider = Provider<AntiburlaRemoteDataSource>((ref) {
  return AntiburlaRemoteDataSource();
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

  AntiburlaRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<AntiburlaCheckResult> checkConsistency({
    required String vertical,
    required String category,
    required String selectedPersistence,
    String? narrative,
    String? token,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.antiburlaCheck,
        data: {
          'vertical': vertical,
          'category': category,
          'selectedPersistence': selectedPersistence,
          if (narrative != null && narrative.isNotEmpty) 'narrative': narrative,
        },
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );

      if (response.data is Map<String, dynamic>) {
        return AntiburlaCheckResult.fromJson(response.data as Map<String, dynamic>);
      }
      return const AntiburlaCheckResult(triggered: false);
    } catch (_) {
      // Offline fallback: does not trigger if offline to avoid blocking triage flow
      return const AntiburlaCheckResult(triggered: false);
    }
  }
}
