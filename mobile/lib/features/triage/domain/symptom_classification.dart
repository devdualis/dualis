class SymptomClassification {
  final String primaryVertical;
  final String systemOrDimension;
  final int urgencyScore;
  final String mappedLayTerm;
  final String clinicalConcept;
  final bool isEmergencyCandidate;
  final double confidence;
  final String source;

  const SymptomClassification({
    required this.primaryVertical,
    required this.systemOrDimension,
    required this.urgencyScore,
    required this.mappedLayTerm,
    required this.clinicalConcept,
    required this.isEmergencyCandidate,
    required this.confidence,
    required this.source,
  });

  factory SymptomClassification.fromJson(Map<String, dynamic> json) {
    return SymptomClassification(
      primaryVertical: json['primaryVertical'] as String? ?? 'physical',
      systemOrDimension: json['systemOrDimension'] as String? ?? 'general_somatic',
      urgencyScore: (json['urgencyScore'] as num?)?.toInt() ?? 2,
      mappedLayTerm: json['mappedLayTerm'] as String? ?? '',
      clinicalConcept: json['clinicalConcept'] as String? ?? '',
      isEmergencyCandidate: json['isEmergencyCandidate'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.7,
      source: json['source'] as String? ?? 'dictionary_fallback',
    );
  }

  /// The AI/idiom classification engine and the triage wizard's question bank grew
  /// slightly different vocabularies for the same systems/dimensions over time.
  /// This normalizes a classification's [systemOrDimension] to the wizard's
  /// TriageOption key so it can be used to pre-select the step-0 category.
  static const Map<String, String> _wizardCategoryAliases = {
    // Physical
    'cardiovascular_chest': 'cardiovascular_torax',
    'head_neck': 'cabeca_pescoco',
    'respiratory': 'respiratorio',
    'neurological': 'neurologico',
    'musculoskeletal_back': 'coluna_dor_dorsal',
    'musculoskeletal_joints': 'membros_superiores',
    'gastrointestinal': 'gastrointestinal_abdomen',
    'general_somatic': 'muscular_geral_sistemico',
    // Emotional
    'anxious_agitation': 'ansiosa_agitacao',
    'depressive_hopelessness': 'depressiva_desanimo',
    'stress_burnout': 'estresse_burnout',
    'emotional_general': 'cognitiva_foco',
  };

  String get wizardCategoryKey =>
      _wizardCategoryAliases[systemOrDimension] ?? systemOrDimension;
}
