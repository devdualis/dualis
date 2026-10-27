/// Tags returned by `/v1/ai/tag-entry` for optional free text. They only
/// organise the text (body area or mood, everyday term); nothing here
/// evaluates the entry.
class SymptomClassification {
  final bool isOffTopic;
  final String? vertical;
  final String? bodyAreaOrMood;
  final String? layTerm;

  const SymptomClassification({
    this.isOffTopic = false,
    this.vertical,
    this.bodyAreaOrMood,
    this.layTerm,
  });

  factory SymptomClassification.fromJson(Map<String, dynamic> json) {
    return SymptomClassification(
      isOffTopic: json['isOffTopic'] as bool? ?? false,
      vertical: json['vertical'] as String?,
      bodyAreaOrMood: json['bodyAreaOrMood'] as String?,
      layTerm: json['layTerm'] as String?,
    );
  }
}
