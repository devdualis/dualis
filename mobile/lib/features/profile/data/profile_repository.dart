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

  /// Machine-readable error `code` from the API body (e.g.
  /// `CLAIM_INVALID_CODE`), when the backend sends one.
  final String? code;

  const ProfileApiException(this.message, {this.statusCode, this.code});

  /// No HTTP response at all (offline, timeout, server down).
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => message;

  factory ProfileApiException.fromDio(DioException e) {
    final response = e.response;
    final data = response?.data;
    if (data is Map) {
      final rawCode = data['code'];
      final code = rawCode is String && rawCode.isNotEmpty ? rawCode : null;
      final message = data['message'];
      if (message is List && message.isNotEmpty) {
        return ProfileApiException(message.join('\n'),
            statusCode: response?.statusCode, code: code);
      }
      if (message is String && message.isNotEmpty) {
        return ProfileApiException(message,
            statusCode: response?.statusCode, code: code);
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

/// Why a profile claim failed, so the UI can show a localized message.
enum ProfileClaimError {
  /// Unknown, expired or already used code (404 `CLAIM_INVALID_CODE`).
  invalidCode,

  /// The guardian tried to use their own code (403 `CLAIM_BY_GUARDIAN`).
  byGuardian,

  /// The profile is not 18 yet (409 `CLAIM_NOT_ADULT`).
  notAdult,

  /// This account's own profile already has entries (409
  /// `CLAIM_ACCOUNT_HAS_DATA`); profiles are never merged.
  accountHasData,

  /// Too many failed codes (429).
  tooManyAttempts,

  /// Anything else (offline, server error).
  other,
}

/// A failed `POST /v1/profiles/claim`. Still a [ProfileApiException].
class ProfileClaimException extends ProfileApiException {
  final ProfileClaimError reason;

  const ProfileClaimException(
    this.reason,
    super.message, {
    super.statusCode,
    super.code,
  });

  factory ProfileClaimException.from(ProfileApiException e) {
    final reason = switch ((e.statusCode, e.code)) {
      (429, _) => ProfileClaimError.tooManyAttempts,
      (_, 'CLAIM_INVALID_CODE') => ProfileClaimError.invalidCode,
      (_, 'CLAIM_BY_GUARDIAN') => ProfileClaimError.byGuardian,
      (_, 'CLAIM_NOT_ADULT') => ProfileClaimError.notAdult,
      (_, 'CLAIM_ACCOUNT_HAS_DATA') => ProfileClaimError.accountHasData,
      // 400 is a malformed code (length/alphabet), 404 an unknown one.
      (400 || 404, _) => ProfileClaimError.invalidCode,
      _ => ProfileClaimError.other,
    };
    return ProfileClaimException(reason, e.message,
        statusCode: e.statusCode, code: e.code);
  }
}

/// A transfer code the guardian hands to the young adult.
typedef HandoverCode = ({String code, DateTime expiresAt});

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
    String? lgpdLegalBasisNotes,
  }) async {
    final notes = lgpdLegalBasisNotes?.trim();
    final data = await _send((options) => _apiClient.post<dynamic>(
          ProfileEndpoints.dependents,
          data: {
            'name': name,
            'dateOfBirth': formatApiDate(dateOfBirth),
            'gender': gender,
            'relationshipType': relationshipType,
            'lgpdConsent': lgpdConsent,
            if (notes != null && notes.isNotEmpty) 'lgpdLegalBasisNotes': notes,
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
    required GrantRelationship relationship,
    required List<ShareCategory> categories,
    bool dependentShareConfirmed = false,
    String targetProfileName = '',
  }) async {
    final data = await _send((options) => _apiClient.post<dynamic>(
          ProfileEndpoints.invite,
          data: {
            'targetProfileId': targetProfileId,
            'accessLevel': shareLevelToApi(accessLevel),
            'relationship': relationship.apiValue,
            'categories': [for (final c in categories) c.apiValue],
            'dependentShareConfirmed': dependentShareConfirmed,
          },
          options: options,
        ));
    return SharedAccessGrant.fromJson(
      {'status': 'PENDING', ..._asMap(data)},
      GrantDirection.outgoing,
      fallbackTargetProfileName: targetProfileName,
    );
  }

  /// Owner edits what an outgoing grant shares (PATCH). Dependent targets
  /// need [dependentShareConfirmed]. 409 GRANT_SCOPE_LOCKED once the grant
  /// is revoked or expired.
  Future<SharedAccessGrant> updateGrant(
    String grantId, {
    List<ShareCategory>? categories,
    GrantRelationship? relationship,
    bool dependentShareConfirmed = false,
    String targetProfileName = '',
  }) async {
    final data = await _send((options) => _apiClient.patch<dynamic>(
          ProfileEndpoints.grant(grantId),
          data: {
            if (categories != null)
              'categories': [for (final c in categories) c.apiValue],
            if (relationship != null) 'relationship': relationship.apiValue,
            'dependentShareConfirmed': dependentShareConfirmed,
          },
          options: options,
        ));
    return SharedAccessGrant.fromJson(
      _asMap(data),
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

  /// The young adult claims a profile with the guardian's transfer code. The
  /// returned profile is now this account's own primary profile.
  /// Throws [ProfileClaimException]. The code is never logged.
  Future<Profile> claimProfile(String code) async {
    try {
      final data = await _send((options) => _apiClient.post<dynamic>(
            ProfileEndpoints.claim,
            data: {'claimCode': code.trim().toUpperCase()},
            options: options,
          ));
      return Profile.fromJson(_asMap(data));
    } on ProfileClaimException {
      rethrow;
    } on ProfileApiException catch (e) {
      throw ProfileClaimException.from(e);
    }
  }

  /// The guardian generates (or regenerates) a transfer code for a dependent
  /// who turned 18. 409 `HANDOVER_NOT_DUE` otherwise.
  Future<HandoverCode> createHandoverCode(String profileId) async {
    final data = _asMap(await _send((options) => _apiClient.post<dynamic>(
          ProfileEndpoints.handoverCode(profileId),
          options: options,
        )));
    final code = data['claimCode'];
    final expiresAt = data['expiresAt'];
    final parsedExpiry =
        expiresAt is String ? DateTime.tryParse(expiresAt)?.toLocal() : null;
    if (code is! String || code.isEmpty || parsedExpiry == null) {
      throw const ProfileApiException(
        'Resposta inesperada do servidor.',
        statusCode: 200,
      );
    }
    return (code: code, expiresAt: parsedExpiry);
  }

  /// The guardian re-confirms an adult dependent's registration under LGPD
  /// Art. 11, I. Returns the updated profile.
  Future<Profile> confirmLegalBasis(String profileId) async {
    final data = await _send((options) => _apiClient.post<dynamic>(
          ProfileEndpoints.legalBasisConfirmation(profileId),
          data: {'lgpdConsent': true},
          options: options,
        ));
    return Profile.fromJson(_asMap(data));
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
