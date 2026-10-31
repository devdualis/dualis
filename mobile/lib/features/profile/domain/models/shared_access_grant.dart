enum GrantStatus { pending, accepted, revoked, expired }

enum GrantDirection { outgoing, incoming }

class SharedAccessGrant {
  final String id;
  final GrantDirection direction;
  final String targetProfileId;
  final String targetProfileName;
  final ProfileShareLevel accessLevel;
  final GrantStatus status;
  final String? inviteCode; // outgoing only
  final DateTime expiresAt; // deadline to accept a PENDING invite only
  final DateTime? acceptedAt;
  final String? granteeName; // outgoing only: who accepted the invite
  final String? granteeEmail; // outgoing only

  const SharedAccessGrant({
    required this.id,
    required this.direction,
    required this.targetProfileId,
    required this.targetProfileName,
    required this.accessLevel,
    required this.status,
    required this.expiresAt,
    this.inviteCode,
    this.acceptedAt,
    this.granteeName,
    this.granteeEmail,
  });

  /// [fallbackTargetProfileName] fills in responses that omit the name
  /// (invite creation returns only `targetProfileId`).
  factory SharedAccessGrant.fromJson(
    Map<String, dynamic> json,
    GrantDirection direction, {
    String fallbackTargetProfileName = '',
  }) {
    return SharedAccessGrant(
      id: json['id'] as String,
      direction: direction,
      targetProfileId: json['targetProfileId'] as String? ?? '',
      targetProfileName:
          json['targetProfileName'] as String? ?? fallbackTargetProfileName,
      accessLevel: shareLevelFromApi(json['accessLevel']),
      status: switch (json['status']) {
        'ACCEPTED' => GrantStatus.accepted,
        'REVOKED' => GrantStatus.revoked,
        'EXPIRED' => GrantStatus.expired,
        _ => GrantStatus.pending,
      },
      inviteCode: json['inviteCode'] as String?,
      expiresAt: _parseDate(json['expiresAt']) ?? DateTime.now(),
      acceptedAt: _parseDate(json['acceptedAt']),
      granteeName: json['granteeName'] as String?,
      granteeEmail: json['granteeEmail'] as String?,
    );
  }

  bool get isActive => status == GrantStatus.accepted;

  /// "Name (email)" of who accepted an outgoing invite, or null if unknown.
  String? get granteeLabel {
    final name = granteeName?.trim() ?? '';
    final email = granteeEmail?.trim() ?? '';
    if (name.isEmpty) return email.isEmpty ? null : email;
    return email.isEmpty ? name : '$name ($email)';
  }
}

/// `VIEW_ONLY` | `CO_MANAGE` in the API.
enum ProfileShareLevel { viewOnly, coManage }

/// Unknown values map to the most restrictive level.
ProfileShareLevel shareLevelFromApi(Object? raw) =>
    raw == 'CO_MANAGE' ? ProfileShareLevel.coManage : ProfileShareLevel.viewOnly;

String shareLevelToApi(ProfileShareLevel level) => switch (level) {
      ProfileShareLevel.viewOnly => 'VIEW_ONLY',
      ProfileShareLevel.coManage => 'CO_MANAGE',
    };

DateTime? _parseDate(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
