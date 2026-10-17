import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/models/profile.dart';
import '../domain/models/shared_access_grant.dart';
import 'profile_endpoints.dart';

/// Thrown by [ProfileRepository] for any failed call. [message] is the backend
/// message (already pt-BR for profile/guardianship errors) so the UI can show
/// 400/403/404 reasons verbatim.
class ProfileApiException implements Exception {
  final String message;
  final int? statusCode;

  const ProfileApiException(this.message, {this.statusCode});

  /// No HTTP response at all (offline, timeout, server down).
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => message;

  factory ProfileApiException.fromDio(DioException e) {
    final response = e.response;
    final data = response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is List && message.isNotEmpty) {
        return ProfileApiException(message.join('\n'),
            statusCode: response?.statusCode);
      }
      if (message is String && message.isNotEmpty) {
        return ProfileApiException(message, statusCode: response?.statusCode);
      }
    }
    if (response == null) {
      return const ProfileApiException(
        'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.',
      );
    }
    return ProfileApiException(
      'Erro inesperado na comunicação com o servidor.',
      statusCode: response.statusCode,
    );
  }
}

class FamilySharingGrants {
  final List<SharedAccessGrant> outgoing;
  final List<SharedAccessGrant> incoming;

  const FamilySharingGrants({this.outgoing = const [], this.incoming = const []});
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

class ProfileRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  static const _activeProfileKeyPrefix = 'dualis_active_profile_';

  ProfileRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  Future<List<Profile>> fetchProfiles() async {
    final data = await _send((options) =>
        _apiClient.get<dynamic>(ProfileEndpoints.profiles, options: options));
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((m) => Profile.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Profile> createDependent({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    required String relationshipType,
    required bool lgpdConsent,
  }) async {
    final data = await _send((options) => _apiClient.post<dynamic>(
          ProfileEndpoints.dependents,
          data: {
            'name': name,
            'dateOfBirth': formatApiDate(dateOfBirth),
            'gender': gender,
            'relationshipType': relationshipType,
            'lgpdConsent': lgpdConsent,
          },
          options: options,
        ));
    return Profile.fromJson(_asMap(data));
  }

  Future<Profile> updateProfileName(String profileId, String name) async {
    final data = await _send((options) => _apiClient.put<dynamic>(
          ProfileEndpoints.profile(profileId),
          data: {'name': name},
          options: options,
        ));
    return Profile.fromJson(_asMap(data));
  }

  Future<void> deleteProfile(String profileId) async {
    await _send((options) => _apiClient.delete<dynamic>(
          ProfileEndpoints.profile(profileId),
          options: options,
        ));
  }

  Future<FamilySharingGrants> fetchGrants() async {
    final data = await _send((options) =>
        _apiClient.get<dynamic>(ProfileEndpoints.grants, options: options));
    if (data is! Map) return const FamilySharingGrants();
    List<SharedAccessGrant> parse(Object? raw, GrantDirection direction) =>
        raw is List
            ? raw
                .whereType<Map>()
                .map((m) => SharedAccessGrant.fromJson(
                    Map<String, dynamic>.from(m), direction))
                .toList()
            : const [];
    return FamilySharingGrants(
      outgoing: parse(data['outgoing'], GrantDirection.outgoing),
      incoming: parse(data['incoming'], GrantDirection.incoming),
    );
  }

  /// Returns the PENDING outgoing grant. The API omits the profile name, so
  /// pass [targetProfileName] to fill it in.
  Future<SharedAccessGrant> createInvite({
    required String targetProfileId,
    required ProfileShareLevel accessLevel,
    String targetProfileName = '',
  }) async {
    final data = await _send((options) => _apiClient.post<dynamic>(
          ProfileEndpoints.invite,
          data: {
            'targetProfileId': targetProfileId,
            'accessLevel': shareLevelToApi(accessLevel),
          },
          options: options,
        ));
    return SharedAccessGrant.fromJson(
      {'status': 'PENDING', ..._asMap(data)},
      GrantDirection.outgoing,
      fallbackTargetProfileName: targetProfileName,
    );
  }

  Future<void> acceptInvite(String inviteCode) async {
    await _send((options) => _apiClient.post<dynamic>(
          ProfileEndpoints.accept,
          data: {'inviteCode': inviteCode},
          options: options,
        ));
  }

  Future<void> revokeGrant(String grantId) async {
    await _send((options) => _apiClient.post<dynamic>(
          ProfileEndpoints.revoke(grantId),
          options: options,
        ));
  }

  /// Selected profile, stored per signed-in user.
  Future<String?> readActiveProfileId(String userId) async {
    try {
      return await _secureStorage.read(key: '$_activeProfileKeyPrefix$userId');
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveProfileId(String userId, String? profileId) async {
    final key = '$_activeProfileKeyPrefix$userId';
    try {
      if (profileId == null) {
        await _secureStorage.delete(key: key);
      } else {
        await _secureStorage.write(key: key, value: profileId);
      }
    } catch (_) {
      // Losing the selection only means falling back to the primary profile.
    }
  }

  Future<dynamic> _send(
    Future<Response<dynamic>> Function(Options options) request,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const ProfileApiException(
        'Sessão expirada. Faça login novamente.',
        statusCode: 401,
      );
    }
    try {
      final response =
          await request(Options(headers: {'Authorization': 'Bearer $token'}));
      return response.data;
    } on DioException catch (e) {
      throw ProfileApiException.fromDio(e);
    }
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ProfileApiException(
      'Resposta inesperada do servidor.',
      statusCode: 200,
    );
  }
}

/// `yyyy-MM-dd`, the format the backend DTOs validate.
String formatApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
