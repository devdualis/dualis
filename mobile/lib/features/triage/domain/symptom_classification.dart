class SymptomClassification {
  final bool isOffTopic;
  final String? vertical;
  final String? bodyAreaOrMood;
  final String? layTerm;
  final bool mentionsSelfHarm;

  const SymptomClassification({
    this.isOffTopic = false,
    this.vertical,
    this.bodyAreaOrMood,
    this.layTerm,
    this.mentionsSelfHarm = false,
  });

  factory SymptomClassification.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('bodyAreaOrMood') || json.containsKey('layTerm')) {
      return SymptomClassification(
        isOffTopic: json['isOffTopic'] as bool? ?? false,
        vertical: json['vertical'] as String?,
        bodyAreaOrMood: json['bodyAreaOrMood'] as String?,
        layTerm: json['layTerm'] as String?,
        mentionsSelfHarm: json['mentionsSelfHarm'] as bool? ?? false,
      );
    }

    return SymptomClassification(
      isOffTopic: json['isOffTopic'] as bool? ?? false,
      vertical: json['primaryVertical'] as String?,
      bodyAreaOrMood: json['systemOrDimension'] as String?,
      layTerm: json['mappedLayTerm'] as String?,
      mentionsSelfHarm: json['isEmergencyCandidate'] as bool? ?? false,
    );
  }

  String get primaryVertical => vertical ?? 'physical';

  String get systemOrDimension => bodyAreaOrMood ?? 'general_somatic';

  String get mappedLayTerm => layTerm ?? '';

  double get confidence => 0.7;

  String get source => 'dictionary_fallback';

  static const Map<String, String> _wizardCategoryAliases = {
    'cardiovascular_chest': 'cardiovascular_torax',
    'head_neck': 'cabeca_pescoco',
    'respiratory': 'respiratorio',
    'neurological': 'neurologico',
    'musculoskeletal_back': 'coluna_dor_dorsal',
    'musculoskeletal_joints': 'membros_superiores',
    'gastrointestinal': 'gastrointestinal_abdomen',
    'general_somatic': 'muscular_geral_sistemico',
    'anxious_agitation': 'ansiosa_agitacao',
    'depressive_hopelessness': 'depressiva_desanimo',
    'stress_burnout': 'estresse_burnout',
    'emotional_general': 'cognitiva_foco',
  };

  String get wizardCategoryKey =>
      _wizardCategoryAliases[bodyAreaOrMood ?? systemOrDimension] ??
      bodyAreaOrMood ??
      systemOrDimension;
}
