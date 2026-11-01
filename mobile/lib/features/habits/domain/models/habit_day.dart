/// Domain model for daily habits (docs/bienestar/CONTRATO-JOURNAL-V2.md section 6).
class HabitDay {
  final String day; // Local day YYYY-MM-DD
  final String? sleepQuality; // 'bem', 'regular', 'mal'
  final String? sleepHours; // 'menos_5', '5_6', '7_8', '9_mais'
  final bool? moved;
  final String? movementMinutes; // 'ate_15', '15_30', '30_60', 'mais_60'
  final bool? period;
  final DateTime? updatedAt;

  const HabitDay({
    required this.day,
    this.sleepQuality,
    this.sleepHours,
    this.moved,
    this.movementMinutes,
    this.period,
    this.updatedAt,
  });

  bool get isEmpty =>
      sleepQuality == null &&
      sleepHours == null &&
      moved == null &&
      movementMinutes == null &&
      period == null;

  factory HabitDay.fromJson(Map<String, dynamic> json) {
    return HabitDay(
      day: json['day'] as String? ?? '',
      sleepQuality: json['sleepQuality'] as String?,
      sleepHours: json['sleepHours'] as String?,
      moved: json['moved'] as bool?,
      movementMinutes: json['movementMinutes'] as String?,
      period: json['period'] as bool?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'sleepQuality': sleepQuality,
      'sleepHours': sleepHours,
      'moved': moved,
      'movementMinutes': movementMinutes,
      'period': period,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Payload sent in PUT /v1/habits/:day.
  /// Contract v2.2 §6: full replace (omitted field is stored as null).
  /// movementMinutes without moved = true is invalid.
  Map<String, dynamic> toPutPayload() {
    return {
      'sleepQuality': sleepQuality,
      'sleepHours': sleepHours,
      'moved': moved,
      'movementMinutes': moved == true ? movementMinutes : null,
      'period': period,
    };
  }

  HabitDay copyWith({
    String? day,
    String? sleepQuality,
    bool clearSleepQuality = false,
    String? sleepHours,
    bool clearSleepHours = false,
    bool? moved,
    bool clearMoved = false,
    String? movementMinutes,
    bool clearMovementMinutes = false,
    bool? period,
    bool clearPeriod = false,
    DateTime? updatedAt,
  }) {
    final effectiveMoved = clearMoved ? null : (moved ?? this.moved);
    return HabitDay(
      day: day ?? this.day,
      sleepQuality: clearSleepQuality ? null : (sleepQuality ?? this.sleepQuality),
      sleepHours: clearSleepHours ? null : (sleepHours ?? this.sleepHours),
      moved: effectiveMoved,
      // If moved is not true, movementMinutes must be cleared.
      movementMinutes: effectiveMoved == true
          ? (clearMovementMinutes
              ? null
              : (movementMinutes ?? this.movementMinutes))
          : null,
      period: clearPeriod ? null : (period ?? this.period),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitDay &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          sleepQuality == other.sleepQuality &&
          sleepHours == other.sleepHours &&
          moved == other.moved &&
          movementMinutes == other.movementMinutes &&
          period == other.period;

  @override
  int get hashCode =>
      day.hashCode ^
      sleepQuality.hashCode ^
      sleepHours.hashCode ^
      moved.hashCode ^
      movementMinutes.hashCode ^
      period.hashCode;
}

abstract final class HabitSleepQuality {
  static const String bem = 'bem';
  static const String regular = 'regular';
  static const String mal = 'mal';
  static const List<String> all = [bem, regular, mal];
}

abstract final class HabitSleepHours {
  static const String menos5 = 'menos_5';
  static const String hours5To6 = '5_6';
  static const String hours7To8 = '7_8';
  static const String hours9Mais = '9_mais';
  static const List<String> all = [menos5, hours5To6, hours7To8, hours9Mais];
}

abstract final class HabitMovementMinutes {
  static const String ate15 = 'ate_15';
  static const String minutes15To30 = '15_30';
  static const String minutes30To60 = '30_60';
  static const String mais60 = 'mais_60';
  static const List<String> all = [ate15, minutes15To30, minutes30To60, mais60];
}
