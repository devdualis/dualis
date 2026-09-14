import 'emergency_context.dart';
import 'emergency_trigger_category.dart';

/// Clinical red-flag evaluation engine based on Manchester Triage System (MTS)
/// and Emergency Severity Index (ESI) Level 4–5 criteria.
///
/// Operates 100% deterministically and synchronously (<1ms) without network
/// or LLM dependencies.
class RedFlagEvaluator {
  const RedFlagEvaluator._();

  /// Trilingual regex pattern detecting suicidal ideation and acute self-harm intent
  /// in Brazilian Portuguese, Spanish, and English.
  static final RegExp suicideRegex = RegExp(
    r'(quero|vou)\s+(me\s+)?(matar|morrer)|'
    r'(tirar|acabar\s+com)\s+(a\s+)?(minha\s+)?vida|'
    r'suic[ií]d|'
    r'(quiero|voy\s+a)\s+(morir|suicidar|quitarme\s+la\s+vida)|'
    r'quitarme\s+la\s+vida|'
    r'(want\s+to|going\s+to)\s+(die|kill\s+myself|end\s+my\s+life)|'
    r'end\s+my\s+life',
    caseSensitive: false,
  );

  /// Trilingual regex pattern detecting Cincinnati pre-hospital stroke signs
  /// (facial droop, arm weakness, speech difficulty).
  static final RegExp strokeRegex = RegExp(
    r'boca\s+torta|rosto\s+torto|paralisia\s+facial|'
    r'perda\s+de\s+for[çc]a\s+no\s+bra[çc]o|dorm[êe]ncia\s+no\s+bra[çc]o|'
    r'fala\s+arrastada|n[ãa]o\s+consigo\s+falar|'
    r'cara\s+torcida|dificultad\s+para\s+hablar|p[eé]rdida\s+de\s+fuerza|'
    r'facial\s+droop|slurred\s+speech|arm\s+weakness|hemipares',
    caseSensitive: false,
  );

  /// Trilingual regex pattern detecting crushing, acute, or radiating cardiac chest pain.
  static final RegExp chestPainRegex = RegExp(
    r'(dor|aperto|press[ãa]o)\s+no\s+peito(\s+(irradiando|forte|insuport[aá]vel))?|'
    r'peito\s+queimando.*(bra[çc]o|mand[ií]bula)?|'
    r'dolor\s+en\s+el\s+pecho(\s+irradiando)?|'
    r'crushing\s+chest\s+pain|chest\s+pain|infarto|heart\s+attack|ataque\s+card[ií]aco',
    caseSensitive: false,
  );

  /// Trilingual regex pattern detecting acute upper airway obstruction, anaphylaxis,
  /// or severe dyspneic suffocation.
  static final RegExp airwayRegex = RegExp(
    r'n[ãa]o\s+consigo\s+respirar|falta\s+de\s+ar\s+sufocante|garganta\s+fechando|'
    r'no\s+puedo\s+respirar|garganta\s+cerrada|asfixia|'
    r'can(\x27|not|\s+not)\s+breathe|throat\s+closing|suffocating|stridor',
    caseSensitive: false,
  );

  /// Trilingual regex pattern detecting sudden-onset maximum intensity ("thunderclap")
  /// headache suggestive of subarachnoid hemorrhage.
  static final RegExp thunderclapRegex = RegExp(
    r'pior\s+dor\s+de\s+cabe[çc]a\s+da\s+(minha\s+)?vida|'
    r'dor\s+s[uú]bita\s+explosiva\s+na\s+cabe[çc]a|'
    r'peor\s+dolor\s+de\s+cabeza\s+de\s+mi\s+vida|'
    r'worst\s+headache\s+of\s+my\s+life|thunderclap\s+headache',
    caseSensitive: false,
  );

  /// Scans raw lay text inputs across pt-BR, es, and en for acute red-flag conditions.
  ///
  /// Returns an [EmergencyContext] immediately if a high-lethality pattern is detected,
  /// or `null` if no emergency regex matched.
  static EmergencyContext? evaluateText(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return null;

    final suicideMatch = suicideRegex.firstMatch(cleanText);
    if (suicideMatch != null) {
      return EmergencyContext(
        category: EmergencyTriggerCategory.suicidalCrisis,
        severityLevel: 5,
        isEmotional: true,
        detectedAt: DateTime.now(),
        rawTriggerPhrase: suicideMatch.group(0),
      );
    }

    final chestMatch = chestPainRegex.firstMatch(cleanText);
    if (chestMatch != null) {
      return EmergencyContext(
        category: EmergencyTriggerCategory.chestPain,
        severityLevel: 5,
        isEmotional: false,
        detectedAt: DateTime.now(),
        rawTriggerPhrase: chestMatch.group(0),
      );
    }

    final strokeMatch = strokeRegex.firstMatch(cleanText);
    if (strokeMatch != null) {
      return EmergencyContext(
        category: EmergencyTriggerCategory.neurologicalStroke,
        severityLevel: 5,
        isEmotional: false,
        detectedAt: DateTime.now(),
        rawTriggerPhrase: strokeMatch.group(0),
      );
    }

    final airwayMatch = airwayRegex.firstMatch(cleanText);
    if (airwayMatch != null) {
      return EmergencyContext(
        category: EmergencyTriggerCategory.anaphylaxisAirway,
        severityLevel: 5,
        isEmotional: false,
        detectedAt: DateTime.now(),
        rawTriggerPhrase: airwayMatch.group(0),
      );
    }

    final thunderclapMatch = thunderclapRegex.firstMatch(cleanText);
    if (thunderclapMatch != null) {
      return EmergencyContext(
        category: EmergencyTriggerCategory.thunderclapHeadache,
        severityLevel: 5,
        isEmotional: false,
        detectedAt: DateTime.now(),
        rawTriggerPhrase: thunderclapMatch.group(0),
      );
    }

    return null;
  }

  /// Evaluates structured triage selections against Manchester/ESI Level 4–5 criteria.
  ///
  /// Intercepts:
  /// - Intensity == 5: On any organ or emotional dimension (Level 5 / MTS Red / ESI 1).
  /// - Intensity == 4: On vital anatomical systems (`cardiovascular_chest`, `respiratory`,
  ///   `neurological`, `head_neck`) or acute emotional crisis dimensions (`depressive_hopelessness`,
  ///   `anxious_agitation`, `stress_burnout`).
  ///
  /// Returns `null` for non-emergency presentations (intensity < 4 or non-critical organs at Level 4).
  static EmergencyContext? evaluateStructured({
    required String systemOrDimension,
    required int intensity,
    required bool isEmotional,
    String? selectedSymptom,
  }) {
    if (intensity < 4) {
      return null;
    }

    final phrase = selectedSymptom ?? '$systemOrDimension (intensity $intensity)';
    final now = DateTime.now();

    if (intensity == 5) {
      if (isEmotional) {
        switch (systemOrDimension) {
          case 'depressive_hopelessness':
            return EmergencyContext(
              category: EmergencyTriggerCategory.suicidalCrisis,
              severityLevel: 5,
              isEmotional: true,
              detectedAt: now,
              rawTriggerPhrase: phrase,
            );
          case 'anxious_agitation':
            return EmergencyContext(
              category: EmergencyTriggerCategory.anxiousPanicCollapse,
              severityLevel: 5,
              isEmotional: true,
              detectedAt: now,
              rawTriggerPhrase: phrase,
            );
          case 'stress_burnout':
            return EmergencyContext(
              category: EmergencyTriggerCategory.severePsychosisDelirium,
              severityLevel: 5,
              isEmotional: true,
              detectedAt: now,
              rawTriggerPhrase: phrase,
            );
          default:
            return EmergencyContext(
              category: EmergencyTriggerCategory.generalCriticalIntensity,
              severityLevel: 5,
              isEmotional: true,
              detectedAt: now,
              rawTriggerPhrase: phrase,
            );
        }
      } else {
        switch (systemOrDimension) {
          case 'cardiovascular_chest':
            return EmergencyContext(
              category: EmergencyTriggerCategory.chestPain,
              severityLevel: 5,
              isEmotional: false,
              detectedAt: now,
              rawTriggerPhrase: phrase,
            );
          case 'respiratory':
            return EmergencyContext(
              category: EmergencyTriggerCategory.respiratoryDistress,
              severityLevel: 5,
              isEmotional: false,
              detectedAt: now,
              rawTriggerPhrase: phrase,
            );
          case 'neurological':
            return EmergencyContext(
              category: EmergencyTriggerCategory.neurologicalStroke,
              severityLevel: 5,
              isEmotional: false,
              detectedAt: now,
              rawTriggerPhrase: phrase,
            );
          case 'head_neck':
            return EmergencyContext(
              category: EmergencyTriggerCategory.anaphylaxisAirway,
              severityLevel: 5,
              isEmotional: false,
              detectedAt: now,
              rawTriggerPhrase: phrase,
            );
          default:
            return EmergencyContext(
              category: EmergencyTriggerCategory.generalCriticalIntensity,
              severityLevel: 5,
              isEmotional: false,
              detectedAt: now,
              rawTriggerPhrase: phrase,
            );
        }
      }
    }

    // intensity == 4
    if (isEmotional) {
      switch (systemOrDimension) {
        case 'depressive_hopelessness':
          return EmergencyContext(
            category: EmergencyTriggerCategory.suicidalCrisis,
            severityLevel: 4,
            isEmotional: true,
            detectedAt: now,
            rawTriggerPhrase: phrase,
          );
        case 'anxious_agitation':
          return EmergencyContext(
            category: EmergencyTriggerCategory.anxiousPanicCollapse,
            severityLevel: 4,
            isEmotional: true,
            detectedAt: now,
            rawTriggerPhrase: phrase,
          );
        case 'stress_burnout':
          return EmergencyContext(
            category: EmergencyTriggerCategory.severePsychosisDelirium,
            severityLevel: 4,
            isEmotional: true,
            detectedAt: now,
            rawTriggerPhrase: phrase,
          );
        default:
          return null;
      }
    } else {
      switch (systemOrDimension) {
        case 'cardiovascular_chest':
          return EmergencyContext(
            category: EmergencyTriggerCategory.chestPain,
            severityLevel: 4,
            isEmotional: false,
            detectedAt: now,
            rawTriggerPhrase: phrase,
          );
        case 'respiratory':
          return EmergencyContext(
            category: EmergencyTriggerCategory.respiratoryDistress,
            severityLevel: 4,
            isEmotional: false,
            detectedAt: now,
            rawTriggerPhrase: phrase,
          );
        case 'neurological':
          return EmergencyContext(
            category: EmergencyTriggerCategory.neurologicalStroke,
            severityLevel: 4,
            isEmotional: false,
            detectedAt: now,
            rawTriggerPhrase: phrase,
          );
        case 'head_neck':
          return EmergencyContext(
            category: EmergencyTriggerCategory.anaphylaxisAirway,
            severityLevel: 4,
            isEmotional: false,
            detectedAt: now,
            rawTriggerPhrase: phrase,
          );
        default:
          return null;
      }
    }
  }
}
