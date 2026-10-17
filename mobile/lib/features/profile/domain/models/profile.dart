enum ProfileType { primary, dependentMinor, dependentAdult }

/// How the signed-in user relates to a profile (`ownership` in the API).
enum ProfileOwnership { own, dependent, shared }

/// `OWNER` | `VIEW_ONLY` | `CO_MANAGE` in the API.
enum ProfileAccessLevel { owner, viewOnly, coManage }

class Profile {
  final String id;
  final String name;
  final ProfileType profileType;
  final ProfileOwnership ownership;
  final ProfileAccessLevel accessLevel;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? avatarUrl;

  const Profile({
    required this.id,
    required this.name,
    required this.profileType,
    required this.ownership,
    required this.accessLevel,
    this.dateOfBirth,
    this.gender,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final dob = json['dateOfBirth'];
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
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  bool get isPrimary => profileType == ProfileType.primary;
  bool get isShared => ownership == ProfileOwnership.shared;
  bool get canEdit => accessLevel != ProfileAccessLevel.viewOnly;
  bool get canDelete => accessLevel == ProfileAccessLevel.owner && !isPrimary;
}

/// Unknown values map to the most restrictive level.
ProfileAccessLevel parseProfileAccessLevel(Object? raw) => switch (raw) {
      'OWNER' => ProfileAccessLevel.owner,
      'CO_MANAGE' => ProfileAccessLevel.coManage,
      _ => ProfileAccessLevel.viewOnly,
    };
