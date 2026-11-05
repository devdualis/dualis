import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_service.dart';

/// Stable codes returned by the server (plan 17-01).
const String aiConsentVersionMismatchCode = 'AI_CONSENT_VERSION_MISMATCH';
const String aiConsentRequiredCode = 'AI_CONSENT_REQUIRED';
const String aiProfileNotAllowedCode = 'AI_PROFILE_NOT_ALLOWED';

/// The person's AI-processing consent (LGPD Art. 11, I), account level.
///
/// UX state only: the server gate is the authority.
class AiConsentStatus {
  final bool granted;
  final String? version;
  final String currentVersion;
  final DateTime? grantedAt;

  const AiConsentStatus({
    required this.granted,
    required this.currentVersion,
    this.version,
    this.grantedAt,
  });

  factory AiConsentStatus.fromJson(Map<String, dynamic> json) {
    final grantedAt = json['grantedAt'];
    return AiConsentStatus(
      granted: json['granted'] == true,
      version: json['version'] as String?,
      currentVersion: (json['currentVersion'] as String?) ?? '',
      grantedAt:
          grantedAt is String ? DateTime.tryParse(grantedAt)?.toLocal() : null,
    );
  }
}

/// The server's consent version changed between reading and granting.
class AiConsentVersionMismatch implements Exception {
  const AiConsentVersionMismatch();

  @override
  String toString() => 'AiConsentVersionMismatch';
}

abstract class AiConsentRepository {
  Future<AiConsentStatus> status();
  Future<AiConsentStatus> grant(String version);
  Future<AiConsentStatus> revoke();
}

final aiConsentRepositoryProvider = Provider<AiConsentRepository>((ref) {
  return HttpAiConsentRepository(
    client: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
});

/// `/v1/consents/ai-processing` over the app's [ApiClient].
class HttpAiConsentRepository implements AiConsentRepository {
  static const String path = '/v1/consents/ai-processing';

  final ApiClient client;
  final SecureStorageService storage;

  HttpAiConsentRepository({required this.client, required this.storage});

  Future<Options> _auth() async {
    final token = await storage.getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  AiConsentStatus _parse(Response<Map<String, dynamic>> response) =>
      AiConsentStatus.fromJson(response.data ?? const {});

  @override
  Future<AiConsentStatus> status() async {
    final response = await client.get<Map<String, dynamic>>(
      path,
      options: await _auth(),
    );
    return _parse(response);
  }

  @override
  Future<AiConsentStatus> grant(String version) async {
    try {
      final response = await client.post<Map<String, dynamic>>(
        path,
        data: {'version': version},
        options: await _auth(),
      );
      return _parse(response);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 409 &&
          data is Map &&
          data['code'] == aiConsentVersionMismatchCode) {
        throw const AiConsentVersionMismatch();
      }
      rethrow;
    }
  }

  @override
  Future<AiConsentStatus> revoke() async {
    final response = await client.delete<Map<String, dynamic>>(
      path,
      options: await _auth(),
    );
    return _parse(response);
  }
}
