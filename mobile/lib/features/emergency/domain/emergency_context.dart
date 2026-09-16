import 'emergency_trigger_category.dart';

/// Available emergency dispatch and response service types.
enum EmergencyServiceType {
  samu192,
  cvv188,
  bombeiros193,
  policia190,
  mapsEmergencyRoom,
}

/// Immutable clinical context describing an intercepted emergency condition.
class EmergencyContext {
  final EmergencyTriggerCategory category;
  final int severityLevel;
  final bool isEmotional;
  final DateTime detectedAt;
  final String? rawTriggerPhrase;

  /// Structured wizard vertical ('physical' | 'emotional') and answers snapshot
  /// captured at the moment this emergency was detected, so the intercepted
  /// triage session can still be persisted as a real record if the user exits.
  final String? sourceVertical;
  final Map<int, String>? sourceAnswers;

  const EmergencyContext({
    required this.category,
    required this.severityLevel,
    required this.isEmotional,
    required this.detectedAt,
    this.rawTriggerPhrase,
    this.sourceVertical,
    this.sourceAnswers,
  });

  /// Primary emergency dispatch service recommended for this triage event.
  EmergencyServiceType get primaryService =>
      isEmotional ? EmergencyServiceType.cvv188 : EmergencyServiceType.samu192;

  EmergencyContext copyWith({
    EmergencyTriggerCategory? category,
    int? severityLevel,
    bool? isEmotional,
    DateTime? detectedAt,
    String? rawTriggerPhrase,
    String? sourceVertical,
    Map<int, String>? sourceAnswers,
  }) {
    return EmergencyContext(
      category: category ?? this.category,
      severityLevel: severityLevel ?? this.severityLevel,
      isEmotional: isEmotional ?? this.isEmotional,
      detectedAt: detectedAt ?? this.detectedAt,
      rawTriggerPhrase: rawTriggerPhrase ?? this.rawTriggerPhrase,
      sourceVertical: sourceVertical ?? this.sourceVertical,
      sourceAnswers: sourceAnswers ?? this.sourceAnswers,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyContext &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          severityLevel == other.severityLevel &&
          isEmotional == other.isEmotional &&
          detectedAt == other.detectedAt &&
          rawTriggerPhrase == other.rawTriggerPhrase;

  @override
  int get hashCode =>
      category.hashCode ^
      severityLevel.hashCode ^
      isEmotional.hashCode ^
      detectedAt.hashCode ^
      rawTriggerPhrase.hashCode;

  @override
  String toString() =>
      'EmergencyContext(category: $category, severityLevel: $severityLevel, '
      'isEmotional: $isEmotional, detectedAt: $detectedAt, rawTriggerPhrase: $rawTriggerPhrase)';
}
