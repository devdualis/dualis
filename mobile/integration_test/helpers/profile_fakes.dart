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

/// The young adult who claims the profile Ana managed until 18 (T-11.1-D).
const userC = UserProfile(
  id: 'user-c',
  name: 'Clara Jovem',
  email: 'clara@example.test',
  gender: Gender.feminino,
  dateOfBirth: '2008-01-10',
  isEmailVerified: true,
);

const _users = [userA, userB, userC];

String tokenFor(UserProfile user) => 'fake-token-${user.id}';

/// Fake auth backend: a token or email maps to one of the fake users.
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
  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async =>
      {};

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
  String ownerUserId;
  String name;
  ProfileType type;
  final DateTime? dateOfBirth;
  final String? gender;
  String? relationshipType;
  final String? lgpdLegalBasisNotes;
  String? lgpdLegalBasis;
  String? handoverCode;
  DateTime? handoverCodeExpiresAt;

  _FakeProfile({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.type,
    this.dateOfBirth,
    this.gender,
    this.relationshipType,
    this.lgpdLegalBasisNotes,
    this.lgpdLegalBasis,
  });

  bool get isAdult {
    final dob = dateOfBirth;
    if (dob == null) return false;
    final now = DateTime.now();
    return !DateTime(dob.year + 18, dob.month, dob.day).isAfter(now);
  }

  /// A minor's guardianship (parent / legal guardian) whose dependent is 18+.
  bool get handoverDue =>
      type != ProfileType.primary &&
      (relationshipType == 'parent' || relationshipType == 'legal_guardian') &&
      isAdult;

  bool get handoverCodeActive =>
      handoverCode != null &&
      (handoverCodeExpiresAt?.isAfter(DateTime.now()) ?? false);
}

class _FakeGrant {
  final String id;
  final String ownerUserId;
  final String targetProfileId;
  final ProfileShareLevel level;
  GrantRelationship? relationship;
  List<ShareCategory> categories;
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
    this.relationship,
    this.categories = const [],
  });
}

/// In-memory stand-in for the Wave 1 profile/guardianship API, shared by both
/// users. Rules mirrored from the backend:
///  * a dependent needs LGPD consent, and the relationship must match the
///    age (parent / legal_guardian under 18, curator / supported_decision
///    from 18), like 11.1-06;
///  * invites need at least one category; a dependent's invite needs the
///    guardian's confirmation; grantees see only the grant's categories;
///  * a dependent who turned 18 gets a hand-over code, and the claim moves
///    the profile to the claiming account as its primary profile;
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
    final ownedDependent =
        p.ownerUserId == userId && p.type != ProfileType.primary;
    return {
      'id': p.id,
      'name': p.name,
      // Like the API, a dependent's type is recomputed from the birth date
      // on every read (D3), so a minor who turned 18 reads as an adult.
      'profileType': p.type == ProfileType.primary
          ? 'primary'
          : (p.isAdult ? 'dependent_adult' : 'dependent_minor'),
      'ownership': _ownershipApi(userId, p),
      'accessLevel': p.ownerUserId == userId
          ? 'OWNER'
          : shareLevelToApi(grant!.level),
      if (p.dateOfBirth != null) 'dateOfBirth': formatApiDate(p.dateOfBirth!),
      'gender': p.gender,
      'handoverStatus': !ownedDependent || !p.handoverDue
          ? 'none'
          : (p.handoverCodeActive ? 'code_active' : 'due'),
      'handoverCodeExpiresAt': ownedDependent && p.handoverCodeActive
          ? p.handoverCodeExpiresAt!.toUtc().toIso8601String()
          : null,
      'relationshipType': ownedDependent ? p.relationshipType : null,
      'lgpdLegalBasis': ownedDependent ? p.lgpdLegalBasis : null,
      'legalBasisNeedsConfirmation': ownedDependent &&
          (p.relationshipType == 'curator' ||
              p.relationshipType == 'supported_decision') &&
          p.lgpdLegalBasis == 'lgpd_art_14',
      // Owners get every area; a grantee gets the grant's categories, and
      // writes only on CO_MANAGE grants (GET /v1/profiles, 11.1-05).
      'readableCategories': [
        for (final c in p.ownerUserId == userId
            ? ShareCategory.values
            : grant!.categories)
          c.apiValue,
      ],
      'writableCategories': [
        for (final c in p.ownerUserId == userId
            ? ShareCategory.values
            : grant!.level == ProfileShareLevel.coManage
                ? grant.categories
                : const <ShareCategory>[])
          c.apiValue,
      ],
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
        'relationship': g.relationship?.apiValue,
        'categories': [for (final c in g.categories) c.apiValue],
      };

  /// Same order as GET /v1/profiles: own primary, own dependents, then
  /// shared profiles (the app falls back to the first primary in the list).
  List<_FakeProfile> _visibleTo(String userId) => [
        ..._profiles.where(
            (p) => p.ownerUserId == userId && p.type == ProfileType.primary),
        ..._profiles.where(
            (p) => p.ownerUserId == userId && p.type != ProfileType.primary),
        ..._profiles.where((p) =>
            p.ownerUserId != userId && _activeGrant(userId, p.id) != null),
      ];

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

  /// Stored audit note of a profile (lgpdLegalBasisNotes), for assertions.
  String? notesOf(String profileId) =>
      _profiles.firstWhere((p) => p.id == profileId).lgpdLegalBasisNotes;

  /// Stored LGPD basis of a dependent, for assertions.
  String? legalBasisOf(String profileId) =>
      _profiles.firstWhere((p) => p.id == profileId).lgpdLegalBasis;

  /// Seeds a dependent of [ownerUserId] under parental authority who turned
  /// 18 yesterday, so its hand-over is due. The create rules refuse a
  /// `parent` relationship for an adult, so this state only comes from
  /// someone registered as a child who grew up.
  String seedHandoverDueDependent(String ownerUserId, String name) {
    final now = DateTime.now();
    final p = _FakeProfile(
      id: 'profile-dep-${_profiles.length + 1}',
      ownerUserId: ownerUserId,
      name: name,
      type: ProfileType.dependentMinor,
      dateOfBirth: DateTime(now.year - 18, now.month, now.day - 1),
      gender: 'feminino',
      relationshipType: 'parent',
      lgpdLegalBasis: 'lgpd_art_14',
    );
    _profiles.add(p);
    return p.id;
  }

  /// Seeds an ACCEPTED grant from [ownerUserId]'s primary profile to
  /// [granteeUserId] with [categories], as if the invite was already used.
  String seedAcceptedGrant({
    required String ownerUserId,
    required String granteeUserId,
    required ProfileShareLevel level,
    required GrantRelationship relationship,
    required List<ShareCategory> categories,
  }) {
    final g =
        _FakeGrant(
            id: 'grant-${_grants.length + 1}',
            ownerUserId: ownerUserId,
            targetProfileId: 'profile-$ownerUserId',
            level: level,
            inviteCode: _nextCode(),
            expiresAt: DateTime.now().add(const Duration(hours: 48)),
            relationship: relationship,
            categories: categories,
          )
          ..status = 'ACCEPTED'
          ..granteeUserId = granteeUserId
          ..acceptedAt = DateTime.now();
    _grants.add(g);
    return g.targetProfileId;
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
    String? lgpdLegalBasisNotes,
  }) =>
      _respond(() {
        if (!lgpdConsent) {
          throw const ProfileApiException('Consentimento LGPD é obrigatório.',
              statusCode: 400);
        }
        final now = DateTime.now();
        final adult = !DateTime(dateOfBirth.year + 18, dateOfBirth.month,
                dateOfBirth.day)
            .isAfter(now);
        // Age × relationship, same messages as profiles.service.ts.
        const adultRelationships = ['curator', 'supported_decision'];
        const minorRelationships = ['parent', 'legal_guardian'];
        if (adult && !adultRelationships.contains(relationshipType)) {
          throw const ProfileApiException(
              'Para maiores de 18 anos, escolha curatela ou tomada de decisão apoiada.',
              statusCode: 400);
        }
        if (!adult && !minorRelationships.contains(relationshipType)) {
          throw const ProfileApiException(
              'Para menores de 18 anos, escolha poder familiar ou tutela.',
              statusCode: 400);
        }
        final p = _FakeProfile(
          id: 'profile-dep-${_db._profiles.length + 1}',
          ownerUserId: _uid,
          name: name,
          type: adult ? ProfileType.dependentAdult : ProfileType.dependentMinor,
          dateOfBirth: dateOfBirth,
          gender: gender,
          relationshipType: relationshipType,
          lgpdLegalBasisNotes: lgpdLegalBasisNotes,
          lgpdLegalBasis: adult ? 'lgpd_art_11_i' : 'lgpd_art_14',
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
    required GrantRelationship relationship,
    required List<ShareCategory> categories,
    bool dependentShareConfirmed = false,
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
        if (categories.isEmpty) {
          throw const ProfileApiException('Escolha ao menos uma categoria.',
              statusCode: 400);
        }
        final target =
            _db._profiles.firstWhere((p) => p.id == targetProfileId);
        if (target.type != ProfileType.primary && !dependentShareConfirmed) {
          throw const ProfileApiException(
              'Confirme o compartilhamento do perfil dependente.',
              statusCode: 400);
        }
        final g = _FakeGrant(
          id: 'grant-${_db._grants.length + 1}',
          ownerUserId: _uid,
          targetProfileId: targetProfileId,
          level: accessLevel,
          inviteCode: _db._nextCode(),
          expiresAt: DateTime.now().add(const Duration(hours: 48)),
          relationship: relationship,
          categories: categories,
        );
        _db._grants.add(g);
        // Like the API: no targetProfileName in the create response.
        final json = _db._grantJson(g, outgoing: true)
          ..remove('targetProfileName');
        return SharedAccessGrant.fromJson(json, GrantDirection.outgoing,
            fallbackTargetProfileName: targetProfileName);
      });

  @override
  Future<SharedAccessGrant> updateGrant(
    String grantId, {
    List<ShareCategory>? categories,
    GrantRelationship? relationship,
    bool dependentShareConfirmed = false,
    String targetProfileName = '',
  }) =>
      _respond(() {
        final g = _db._grants.where((g) => g.id == grantId).firstOrNull;
        if (g == null ||
            (g.ownerUserId != _uid && g.granteeUserId != _uid)) {
          throw const ProfileApiException('Compartilhamento não encontrado.',
              statusCode: 404);
        }
        if (g.ownerUserId != _uid) {
          throw const ProfileApiException(
              'Só quem compartilhou pode alterar este acesso.',
              statusCode: 403);
        }
        if (g.status != 'PENDING' && g.status != 'ACCEPTED') {
          throw const ProfileApiException(
              'Este compartilhamento não pode mais ser alterado.',
              statusCode: 409);
        }
        if (categories != null && categories.isEmpty) {
          throw const ProfileApiException('Escolha ao menos uma categoria.',
              statusCode: 400);
        }
        final target =
            _db._profiles.firstWhere((p) => p.id == g.targetProfileId);
        if (target.type != ProfileType.primary && !dependentShareConfirmed) {
          throw const ProfileApiException(
              'Confirme o compartilhamento do perfil dependente.',
              statusCode: 400);
        }
        if (categories != null) g.categories = categories;
        if (relationship != null) g.relationship = relationship;
        return SharedAccessGrant.fromJson(
            _db._grantJson(g, outgoing: true), GrantDirection.outgoing);
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

  /// Fixed 10-char transfer code, like the API's invite alphabet and length.
  static const handoverCodeValue = 'HANDOVER01';

  @override
  Future<HandoverCode> createHandoverCode(String profileId) => _respond(() {
        final p = _db._profiles.where((p) => p.id == profileId).firstOrNull;
        if (p == null || p.ownerUserId != _uid || !p.handoverDue) {
          throw const ProfileApiException(
              'A transferência ainda não está disponível para este perfil.',
              statusCode: 409,
              code: 'HANDOVER_NOT_DUE');
        }
        p
          ..handoverCode = handoverCodeValue
          ..handoverCodeExpiresAt =
              DateTime.now().add(const Duration(hours: 72));
        return (code: handoverCodeValue, expiresAt: p.handoverCodeExpiresAt!);
      });

  @override
  Future<Profile> claimProfile(String code) => _respond(() {
        final normalized = code.trim().toUpperCase();
        final p = _db._profiles
            .where((p) => p.handoverCode == normalized && p.handoverCodeActive)
            .firstOrNull;
        if (p == null) {
          throw const ProfileClaimException(ProfileClaimError.invalidCode,
              'Código inválido ou expirado.',
              statusCode: 404, code: 'CLAIM_INVALID_CODE');
        }
        if (p.ownerUserId == _uid) {
          throw const ProfileClaimException(ProfileClaimError.byGuardian,
              'Use o código na conta da pessoa que fez 18 anos.',
              statusCode: 403, code: 'CLAIM_BY_GUARDIAN');
        }
        if (!p.isAdult) {
          throw const ProfileClaimException(ProfileClaimError.notAdult,
              'O perfil ainda não tem 18 anos.',
              statusCode: 409, code: 'CLAIM_NOT_ADULT');
        }
        // The caller's empty primary is replaced by the claimed profile.
        _db._profiles.removeWhere(
            (o) => o.ownerUserId == _uid && o.type == ProfileType.primary);
        p
          ..ownerUserId = _uid
          ..type = ProfileType.primary
          ..relationshipType = null
          ..lgpdLegalBasis = null
          ..handoverCode = null
          ..handoverCodeExpiresAt = null;
        return Profile.fromJson(_db._profileJson(_uid, p));
      });

  @override
  Future<Profile> confirmLegalBasis(String profileId) => _respond(() {
        final p = _db._profiles.where((p) => p.id == profileId).firstOrNull;
        if (p == null || p.ownerUserId != _uid) {
          throw const ProfileApiException('Perfil não encontrado.',
              statusCode: 404);
        }
        p.lgpdLegalBasis = 'lgpd_art_11_i';
        return Profile.fromJson(_db._profileJson(_uid, p));
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
