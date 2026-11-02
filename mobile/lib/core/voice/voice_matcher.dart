/// Matches what the person said against the labels on screen.
///
/// Pure text work, no network and no interpretation: a spoken phrase is
/// only ever mapped to an option, button or command the person could tap.
class VoiceMatcher {
  const VoiceMatcher._();

  /// Score needed for a label to count as said.
  static const double threshold = 0.5;

  /// Score of a match where every word of the label was said.
  static const double strong = 0.8;

  static const Map<String, String> _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  /// Small words that carry no choice ("eu estou", "the", "me siento").
  /// Number words are not here: they pick intensity levels.
  static const Set<String> _filler = {
    // pt
    'o', 'a', 'os', 'as', 'de', 'do', 'da', 'dos', 'das', 'no', 'na', 'nos',
    'nas', 'em', 'e', 'eu', 'estou', 'to', 'tou', 'esta', 'me', 'meu',
    'minha', 'sinto', 'sentindo', 'quero', 'por', 'favor', 'com', 'que',
    'pra', 'para', 'ta', 'foi', 'ser', 'opcao', 'tipo', 'acho',
    // en
    'the', 'i', 'im', 'am', 'feel', 'feeling', 'my', 'is', 'it', 'and', 'of',
    'please', 'want', 'option',
    // es
    'el', 'la', 'los', 'las', 'del', 'y', 'yo', 'estoy', 'siento', 'mi',
    'en', 'con', 'quiero', 'opcion',
  };

  /// Lower case, no accents, no emoji or punctuation, single spaces.
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final plain = _accents[char] ?? char;
      final isWordChar = RegExp(r'[a-z0-9]').hasMatch(plain);
      buffer.write(isWordChar ? plain : ' ');
    }
    return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Rough word stem so "cansado", "cansada" and "cansados" agree.
  static String _stem(String word) {
    var w = word;
    if (w.length > 3 && w.endsWith('s')) w = w.substring(0, w.length - 1);
    if (w.length > 3 && RegExp(r'[aoe]$').hasMatch(w)) {
      w = w.substring(0, w.length - 1);
    }
    return w;
  }

  static List<String> _words(String normalized) =>
      normalized.isEmpty ? const [] : normalized.split(' ');

  static Set<String> _content(String normalized) {
    final words = _words(normalized);
    final kept = {for (final w in words) if (!_filler.contains(w)) _stem(w)};
    return kept.isEmpty ? {for (final w in words) _stem(w)} : kept;
  }

  /// 0 (unrelated) to 1 (said exactly) for [spoken] against one [label].
  static double score(String spoken, String label) {
    final s = normalize(spoken);
    final l = normalize(label);
    if (s.isEmpty || l.isEmpty) return 0;
    if (s == l) return 1;
    final said = _content(s);
    final wanted = _content(l);
    final common = wanted.intersection(said).length;
    if (common == 0) return 0;
    final coverage = common / wanted.length;
    final precision = common / said.length;
    if (coverage == 1) return strong + (1 - strong) * precision;
    // Every word said is in the label, and at least half of it: a short
    // way to say it ("hoje" for "Começou hoje"). Below a full match.
    if (precision == 1 && coverage >= 0.5) return threshold + 0.2 * coverage;
    return coverage * precision * 0.75;
  }

  /// Best score of [spoken] against any of [labels].
  static double bestScore(String spoken, Iterable<String> labels) {
    var best = 0.0;
    for (final label in labels) {
      final value = score(spoken, label);
      if (value > best) best = value;
    }
    return best;
  }

  /// True when any of [phrases] appears as whole words inside [spoken]
  /// ("preciso de ajuda" contains "ajuda").
  static bool containsPhrase(String spoken, Iterable<String> phrases) {
    final s = ' ${normalize(spoken)} ';
    for (final phrase in phrases) {
      final p = normalize(phrase);
      if (p.isNotEmpty && s.contains(' $p ')) return true;
    }
    return false;
  }

  /// Splits "cansado e ansioso" into the parts of a multi-choice answer.
  static List<String> segments(String spoken) => [
        for (final part in normalize(spoken).split(RegExp(r'\s(?:e|y|and|tambem|also)\s')))
          if (part.trim().isNotEmpty) part.trim(),
      ];

  /// Pipe-separated alias list from the translations ("continuar|próximo").
  static List<String> aliases(String pipeList) => [
        for (final a in pipeList.split('|'))
          if (a.trim().isNotEmpty) a.trim(),
      ];
}
