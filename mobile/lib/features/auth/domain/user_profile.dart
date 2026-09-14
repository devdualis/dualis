enum Gender {
  masculino('masculino'),
  feminino('feminino'),
  outro('outro');

  final String value;
  const Gender(this.value);

  static Gender fromString(String value) {
    switch (value.toLowerCase()) {
      case 'masculino':
        return Gender.masculino;
      case 'feminino':
        return Gender.feminino;
      case 'outro':
      default:
        return Gender.outro;
    }
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final Gender gender;
  final String? dateOfBirth;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    this.dateOfBirth,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      gender: Gender.fromString(json['gender'] as String? ?? 'outro'),
      dateOfBirth: json['dateOfBirth'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'gender': gender.value,
      'dateOfBirth': dateOfBirth,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    Gender? gender,
    String? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
