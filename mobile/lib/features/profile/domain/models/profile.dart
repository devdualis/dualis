enum ProfileType { primary, dependentMinor, dependentAdult }

/// How the signed-in user relates to a profile (`ownership` in the API).
enum ProfileOwnership { own, dependent, shared }

/// `OWNER` | `VIEW_ONLY` | `CO_MANAGE` in the API.
enum ProfileAccessLevel { owner, viewOnly, coManage }

/// Hand-over at 18 (`handoverStatus` in the API, owned dependents only).
/// `due`: the dependent turned 18 and no code is active; `codeActive`: the
/// guardian generated a transfer code that has not expired yet.
enum HandoverStatus { none, due, codeActive }

class Profile {
  final String id;
  final String name;
  final ProfileType profileType;
  final ProfileOwnership ownership;
  final ProfileAccessLevel accessLevel;
  final DateTime? dateOfBirth;
  final String? gender;
  final HandoverStatus handoverStatus;
  final DateTime? handoverCodeExpiresAt;

  /// Guardianship relationship (`parent`, `legal_guardian`, `curator`,
  /// `supported_decision`); null for profiles that are not owned dependents.
  final String? relationshipType;

  /// `lgpd_art_14` | `lgpd_art_11_i`; null for profiles that are not owned
  /// dependents.
  final String? lgpdLegalBasis;

  /// Adult dependent still registered under Art. 14: the guardian is asked
  /// once to re-confirm under Art. 11, I.
  final bool legalBasisNeedsConfirmation;

  const Profile({
    required this.id,
    required this.name,
    required this.profileType,
    required this.ownership,
    required this.accessLevel,
    this.dateOfBirth,
    this.gender,
    this.handoverStatus = HandoverStatus.none,
    this.handoverCodeExpiresAt,
    this.relationshipType,
    this.lgpdLegalBasis,
    this.legalBasisNeedsConfirmation = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final dob = json['dateOfBirth'];
    final codeExpiry = json['handoverCodeExpiresAt'];
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      profileType: switch (json['profileType']) {
        'dependent_minor' => ProfileType.dependentMinor,
        'dependent_adult' => ProfileType.dependentAdult,
        _ => ProfileType.primary,
      },
      ownership: switch (json['ownership']) {
        'dependent' => ProfileOwnership.dependent,
        'shared' => ProfileOwnership.shared,
        _ => ProfileOwnership.own,
      },
      accessLevel: parseProfileAccessLevel(json['accessLevel']),
      // `yyyy-MM-dd` parses as a local calendar date (no timezone shift).
      dateOfBirth: dob is String ? DateTime.tryParse(dob) : null,
      gender: json['gender'] as String?,
      handoverStatus: parseHandoverStatus(json['handoverStatus']),
      handoverCodeExpiresAt:
          codeExpiry is String ? DateTime.tryParse(codeExpiry)?.toLocal() : null,
      relationshipType: _stringOrNull(json['relationshipType']),
      lgpdLegalBasis: _stringOrNull(json['lgpdLegalBasis']),
      legalBasisNeedsConfirmation: json['legalBasisNeedsConfirmation'] == true,
    );
  }

  bool get isPrimary => profileType == ProfileType.primary;
  bool get isShared => ownership == ProfileOwnership.shared;
  bool get canEdit => accessLevel != ProfileAccessLevel.viewOnly;
  bool get canDelete => accessLevel == ProfileAccessLevel.owner && !isPrimary;

  /// Only the owner (guardian) of a dependent manages its hand-over and
  /// legal basis.
  bool get isOwnedDependent =>
      ownership == ProfileOwnership.dependent &&
      accessLevel == ProfileAccessLevel.owner;
}

/// Unknown values map to the most restrictive level.
ProfileAccessLevel parseProfileAccessLevel(Object? raw) => switch (raw) {
      'OWNER' => ProfileAccessLevel.owner,
      'CO_MANAGE' => ProfileAccessLevel.coManage,
      _ => ProfileAccessLevel.viewOnly,
    };

/// Unknown or missing values map to [HandoverStatus.none] (no banner).
HandoverStatus parseHandoverStatus(Object? raw) => switch (raw) {
      'due' => HandoverStatus.due,
      'code_active' => HandoverStatus.codeActive,
      _ => HandoverStatus.none,
    };

String? _stringOrNull(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;
