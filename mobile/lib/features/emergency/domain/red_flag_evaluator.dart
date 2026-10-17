/// Which generic safety notice to show inline. Never names a condition and
/// never carries a level: every trigger of the same kind shows the same text.
enum SafetyNoticeKind {
  /// "If this is an emergency, don't use the app: call {number} now."
  general,

  /// Crisis resources (emotional support line + emergency number) for text
  /// that mentions wanting to hurt oneself or die.
  selfHarm,
}

/// Content-safety matcher for journal entries.
///
/// It does not assess anything: it only decides whether to show a generic,
/// non-blocking safety notice that is identical for every user. Runs offline
/// and synchronously.
class RedFlagEvaluator {
  const RedFlagEvaluator._();

  /// Mentions of wanting to hurt oneself or die (pt-BR, es, en).
  static final RegExp selfHarmPattern = RegExp(
    r'(quero|vou)\s+(me\s+)?(matar|morrer)|'
    r'(tirar|acabar\s+com)\s+(a\s+)?(minha\s+)?vida|'
    r'suic[ií]d|'
    r'(quiero|voy\s+a)\s+(morir|suicidar|quitarme\s+la\s+vida)|'
    r'quitarme\s+la\s+vida|'
    r'(want\s+to|going\s+to)\s+(die|kill\s+myself|end\s+my\s+life)|'
    r'end\s+my\s+life',
    caseSensitive: false,
  );

  /// Expressions from the public "call the emergency number if…" warning
  /// signs (pt-BR, es, en). A match only shows the generic notice.
  static final List<RegExp> warningSignPatterns = [
    RegExp(
      r'(dor|aperto|press[ãa]o)\s+(forte\s+)?no\s+peito|peito\s+queimando|'
      r'dolor\s+en\s+el\s+pecho|chest\s+pain|infarto|heart\s+attack|ataque\s+card[ií]aco',
      caseSensitive: false,
    ),
    RegExp(
      r'boca\s+torta|rosto\s+torto|paralisia\s+facial|'
      r'perda\s+de\s+for[çc]a\s+no\s+bra[çc]o|dorm[êe]ncia\s+no\s+bra[çc]o|'
      r'fala\s+(arrastada|enrolada)|n[ãa]o\s+consigo\s+falar|'
      r'cara\s+torcida|dificultad\s+para\s+hablar|p[eé]rdida\s+de\s+fuerza|'
      r'facial\s+droop|slurred\s+speech|arm\s+weakness',
      caseSensitive: false,
    ),
    RegExp(
      r'n[ãa]o\s+consigo\s+respirar|falta\s+de\s+ar\s+(sufocante|intensa)|garganta\s+fechando|'
      r'no\s+puedo\s+respirar|garganta\s+cerrada|asfixia|'
      r"can('|no|\s+no)t\s+breathe|throat\s+closing|suffocating",
      caseSensitive: false,
    ),
    RegExp(
      r'pior\s+dor\s+de\s+cabe[çc]a\s+da\s+(minha\s+)?vida|'
      r'peor\s+dolor\s+de\s+cabeza\s+de\s+mi\s+vida|'
      r'worst\s+headache\s+of\s+my\s+life',
      caseSensitive: false,
    ),
  ];

  /// Body areas where a self-reported 4/5 also shows the generic notice
  /// (chest, breathing, head).
  static const Set<String> _areasNoticedAtFour = {
    'cardiovascular_torax',
    'respiratorio',
    'cabeca',
    'cabeca_pescoco',
    'neurologico',
  };

  /// Free text: self-harm mentions show crisis resources; warning-sign
  /// expressions show the generic notice; anything else shows nothing.
  static SafetyNoticeKind? evaluateText(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;
    if (selfHarmPattern.hasMatch(clean)) return SafetyNoticeKind.selfHarm;
    if (warningSignPatterns.any((p) => p.hasMatch(clean))) {
      return SafetyNoticeKind.general;
    }
    return null;
  }

  /// Self-reported intensity: 5 anywhere, or 4 on chest / breathing / head
  /// ([bodyAreaKey] is the step-0 answer key), shows the generic notice.
  static SafetyNoticeKind? evaluateIntensity({
    required int intensity,
    String? bodyAreaKey,
  }) {
    if (intensity >= 5) return SafetyNoticeKind.general;
    if (intensity == 4 && _areasNoticedAtFour.contains(bodyAreaKey)) {
      return SafetyNoticeKind.general;
    }
    return null;
  }
}
