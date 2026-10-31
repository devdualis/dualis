import 'package:dio/dio.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/notifications/app_notification_center.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/domain/models/shared_access_grant.dart';

const userA = UserProfile(
  id: 'user-a',
  name: 'Ana Guardiã',
  email: 'ana@example.test',
  gender: Gender.feminino,
  dateOfBirth: '1985-04-12',
  isEmailVerified: true,
);

const userB = UserProfile(
  id: 'user-b',
  name: 'Bruno Convidado',
  email: 'bruno@example.test',
  gender: Gender.masculino,
  dateOfBirth: '1983-09-30',
  isEmailVerified: true,
);

const _users = [userA, userB];

String tokenFor(UserProfile user) => 'fake-token-${user.id}';

/// Fake auth backend: a token or email maps to user A or B.
class FakeAuthRepository implements AuthRepository {
  UserProfile _byToken(String token) =>
      _users.firstWhere((u) => tokenFor(u) == token);

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final user = _users.firstWhere((u) => u.email == email);
    return {
      'user': user.toJson(),
      'accessToken': tokenFor(user),
      'refreshToken': 'refresh-${user.id}',
    };
  }

  @override
  Future<UserProfile> getProfile({required String token}) async =>
      _byToken(token);

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String dateOfBirth,
    required bool lgpdConsent,
    String? disclaimerVersion,
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async =>
      {};

  @override
  Future<UserProfile> updateProfile({
    required String token,
    String? name,
    String? dateOfBirth,
    String? picture,
    String? gender,
  }) async =>
      _byToken(token);

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async =>
      {};
}

/// Every other feature's HTTP call fails at once as offline. Nothing leaves
/// the device and no real base URL is used.
ApiClient offlineApiClient(SecureStorageService storage) {
  final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:9'));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) => handler.reject(DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'integration_test: network disabled',
    )),
  ));
  return ApiClient(customDio: dio, secureStorage: storage);
}

/// Skips the OS notification permission dialog on the simulator.
class AlreadyPromptedStore implements NotificationPermissionPromptStore {
  @override
  Future<bool> wasRequested() async => true;

  @override
  Future<void> markRequested() async {}
}

class _FakeProfile {
  final String id;
  final String ownerUserId;
  String name;
  final ProfileType type;
  final DateTime? dateOfBirth;
  final String? gender;

  _FakeProfile({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.type,
    this.dateOfBirth,
    this.gender,
  });
}

class _FakeGrant {
  final String id;
  final String ownerUserId;
  final String targetProfileId;
  final ProfileShareLevel level;
  final String inviteCode;
  final DateTime expiresAt;
  String status = 'PENDING';
  String? granteeUserId;
  DateTime? acceptedAt;

  _FakeGrant({
    required this.id,
    required this.ownerUserId,
    required this.targetProfileId,
    required this.level,
    required this.inviteCode,
    required this.expiresAt,
  });
}

/// In-memory stand-in for the Wave 1 profile/guardianship API, shared by both
/// users. Rules mirrored from the backend:
///  * a dependent needs LGPD Art. 14 consent;
///  * only the owner can invite, and not for their primary profile's peers;
///  * an invite is single-use, not for its own creator, and expires in 48h;
///  * VIEW_ONLY grantees cannot rename or delete;
///  * owner or grantee can revoke; incoming lists drop revoked grants.
class FakeProfileBackend {
  final List<_FakeProfile> _profiles = [
    for (final u in _users)
      _FakeProfile(
        id: 'profile-${u.id}',
        ownerUserId: u.id,
        name: u.name,
        type: ProfileType.primary,
      ),
  ];
  final List<_FakeGrant> _grants = [];
  final Map<String, String> _activeProfileIds = {};
  int _seq = 0;

  /// Codes handed out, in order (test reads them as a cross-check).
  final List<String> issuedCodes = [];

  ProfileRepository repositoryFor(String? userId) =>
      FakeProfileRepository(this, userId);

  _FakeGrant? _activeGrant(String userId, String profileId) => _grants
      .where((g) =>
          g.status == 'ACCEPTED' &&
          g.granteeUserId == userId &&
          g.targetProfileId == profileId)
      .firstOrNull;

  String _ownershipApi(String userId, _FakeProfile p) {
    if (p.ownerUserId != userId) return 'shared';
    return p.type == ProfileType.primary ? 'own' : 'dependent';
  }

  Map<String, dynamic> _profileJson(String userId, _FakeProfile p) {
    final grant = _activeGrant(userId, p.id);
    return {
      'id': p.id,
      'name': p.name,
      'profileType': switch (p.type) {
        ProfileType.primary => 'primary',
        ProfileType.dependentMinor => 'dependent_minor',
        ProfileType.dependentAdult => 'dependent_adult',
      },
      'ownership': _ownershipApi(userId, p),
      'accessLevel': p.ownerUserId == userId
          ? 'OWNER'
          : shareLevelToApi(grant!.level),
      if (p.dateOfBirth != null) 'dateOfBirth': formatApiDate(p.dateOfBirth!),
      'gender': p.gender,
    };
  }

  Map<String, dynamic> _grantJson(_FakeGrant g, {required bool outgoing}) => {
        'id': g.id,
        'targetProfileId': g.targetProfileId,
        'targetProfileName':
            _profiles.firstWhere((p) => p.id == g.targetProfileId).name,
        'accessLevel': shareLevelToApi(g.level),
        'status': g.status,
        if (outgoing) 'inviteCode': g.inviteCode,
        'expiresAt': g.expiresAt.toUtc().toIso8601String(),
        if (g.acceptedAt != null)
          'acceptedAt': g.acceptedAt!.toUtc().toIso8601String(),
      };

  List<_FakeProfile> _visibleTo(String userId) => _profiles
      .where((p) => p.ownerUserId == userId || _activeGrant(userId, p.id) != null)
      .toList();

  _FakeProfile _writable(String userId, String profileId) {
    final p = _profiles.where((p) => p.id == profileId).firstOrNull;
    if (p == null || !_visibleTo(userId).contains(p)) {
      throw const ProfileApiException('Perfil não encontrado.', statusCode: 404);
    }
    if (p.ownerUserId != userId &&
        _activeGrant(userId, p.id)!.level == ProfileShareLevel.viewOnly) {
      throw const ProfileApiException(
          'Acesso somente leitura a este perfil.',
          statusCode: 403);
    }
    return p;
  }

  String _nextCode() {
    _seq++;
    final code = 'INV${_seq.toString().padLeft(7, '0')}'; // 10 chars, like the API
    issuedCodes.add(code);
    return code;
  }
}

class FakeProfileRepository implements ProfileRepository {
  final FakeProfileBackend _db;
  final String? _userId;

  FakeProfileRepository(this._db, this._userId);

  String get _uid {
    final id = _userId;
    if (id == null) {
      throw const ProfileApiException('Sessão expirada. Faça login novamente.',
          statusCode: 401);
    }
    return id;
  }

  Future<T> _respond<T>(T Function() body) async {
    // A tiny async gap, like a real round trip.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return body();
  }

  @override
  Future<List<Profile>> fetchProfiles() => _respond(() => [
        for (final p in _db._visibleTo(_uid))
          Profile.fromJson(_db._profileJson(_uid, p)),
      ]);

  @override
  Future<Profile> createDependent({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    required String relationshipType,
    required bool lgpdConsent,
  }) =>
      _respond(() {
        if (!lgpdConsent) {
          throw const ProfileApiException(
              'Consentimento LGPD Art. 14 obrigatório.',
              statusCode: 400);
        }
        final now = DateTime.now();
        final adult = DateTime(dateOfBirth.year + 18, dateOfBirth.month,
                dateOfBirth.day)
            .isBefore(now);
        final p = _FakeProfile(
          id: 'profile-dep-${_db._profiles.length + 1}',
          ownerUserId: _uid,
          name: name,
          type: adult ? ProfileType.dependentAdult : ProfileType.dependentMinor,
          dateOfBirth: dateOfBirth,
          gender: gender,
        );
        _db._profiles.add(p);
        return Profile.fromJson(_db._profileJson(_uid, p));
      });

  @override
  Future<Profile> updateProfileName(String profileId, String name) =>
      _respond(() {
        final p = _db._writable(_uid, profileId)..name = name;
        return Profile.fromJson(_db._profileJson(_uid, p));
      });

  @override
  Future<void> deleteProfile(String profileId) => _respond(() {
        final p = _db._writable(_uid, profileId);
        if (p.ownerUserId != _uid || p.type == ProfileType.primary) {
          throw const ProfileApiException('Operação não permitida.',
              statusCode: 403);
        }
        _db._profiles.remove(p);
      });

  @override
  Future<FamilySharingGrants> fetchGrants() => _respond(() {
        final uid = _uid;
        return FamilySharingGrants(
          outgoing: [
            for (final g in _db._grants.where((g) => g.ownerUserId == uid))
              SharedAccessGrant.fromJson(
                  _db._grantJson(g, outgoing: true), GrantDirection.outgoing),
          ],
          incoming: [
            for (final g in _db._grants.where(
                (g) => g.granteeUserId == uid && g.status == 'ACCEPTED'))
              SharedAccessGrant.fromJson(
                  _db._grantJson(g, outgoing: false), GrantDirection.incoming),
          ],
        );
      });

  @override
  Future<SharedAccessGrant> createInvite({
    required String targetProfileId,
    required ProfileShareLevel accessLevel,
    String targetProfileName = '',
  }) =>
      _respond(() {
        final owned = _db._profiles.any(
            (p) => p.id == targetProfileId && p.ownerUserId == _uid);
        if (!owned) {
          throw const ProfileApiException(
              'Só o responsável pode compartilhar este perfil.',
              statusCode: 403);
        }
        final g = _FakeGrant(
          id: 'grant-${_db._grants.length + 1}',
          ownerUserId: _uid,
          targetProfileId: targetProfileId,
          level: accessLevel,
          inviteCode: _db._nextCode(),
          expiresAt: DateTime.now().add(const Duration(hours: 48)),
        );
        _db._grants.add(g);
        // Like the API: no targetProfileName in the create response.
        final json = _db._grantJson(g, outgoing: true)
          ..remove('targetProfileName');
        return SharedAccessGrant.fromJson(json, GrantDirection.outgoing,
            fallbackTargetProfileName: targetProfileName);
      });

  @override
  Future<void> acceptInvite(String inviteCode) => _respond(() {
        final g = _db._grants
            .where((g) =>
                g.inviteCode == inviteCode.trim().toUpperCase() &&
                g.status == 'PENDING' &&
                g.expiresAt.isAfter(DateTime.now()))
            .firstOrNull;
        if (g == null || g.ownerUserId == _uid) {
          throw const ProfileApiException('Código inválido ou expirado.',
              statusCode: 400);
        }
        g
          ..status = 'ACCEPTED'
          ..granteeUserId = _uid
          ..acceptedAt = DateTime.now();
      });

  @override
  Future<void> revokeGrant(String grantId) => _respond(() {
        final g = _db._grants.where((g) => g.id == grantId).firstOrNull;
        if (g == null || (g.ownerUserId != _uid && g.granteeUserId != _uid)) {
          throw const ProfileApiException('Compartilhamento não encontrado.',
              statusCode: 404);
        }
        g.status = 'REVOKED';
      });

  @override
  Future<String?> readActiveProfileId(String userId) async =>
      _db._activeProfileIds[userId];

  @override
  Future<void> saveActiveProfileId(String userId, String? profileId) async {
    if (profileId == null) {
      _db._activeProfileIds.remove(userId);
    } else {
      _db._activeProfileIds[userId] = profileId;
    }
  }
}
