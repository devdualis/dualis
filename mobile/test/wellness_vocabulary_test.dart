// Wellness vocabulary guard (plan §2 and §5, docs/bienestar/PLAN-TECNICO-BIENESTAR.md).
//
// DualisCheckUp is a wellness journal, not a medical device. The words below
// describe a medical product (triage, diagnosis, patient record, clinical
// protocols, regulatory classes) and must not reach the user interface.
//
// Scope:
// - every value in lib/l10n/app_{pt,en,es}.arb;
// - every user-visible string literal in lib/**/*.dart.
//
// Allowed:
// - the help resources screen (l10n keys emergency*, urgentHelp*, safety* and
//   Dart files whose path mentions emergency/safety/urgent_help);
// - comments and identifiers (keys, routes, JSON fields, enum names);
// - generated localization files (their source, the .arb files, is checked).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Banned terms, matched case-insensitively on word boundaries.
final List<({String name, RegExp pattern})> bannedTerms = [
  (name: 'triagem/triage/triaje', pattern: _word(r'tria(?:g|j)\p{L}*')),
  (name: 'diagnóstico/diagnosis', pattern: _word(r'diagn[oóe]s\p{L}*')),
  (name: 'prontuário', pattern: _word(r'prontu[aá]rios?')),
  (name: 'paciente/patient', pattern: _word(r'(?:pacientes?|patients?)')),
  (name: 'clínico/clinical', pattern: _word(r'(?:cl[ií]nic[oa]s?|clinical(?:ly)?|cl[ií]nicamente)')),
  (name: 'Manchester', pattern: _word('manchester')),
  (name: 'ESI', pattern: _word('ESI', caseSensitive: true)),
  (name: 'SaMD', pattern: _word('samd')),
  (name: 'RDC 657', pattern: _word(r'rdc\s*(?:n[º°o.]*\s*)?657')),
  (name: 'CFM 2.314', pattern: _word(r'cfm\s*(?:n[º°o.]*\s*)?2\.?314')),
  (name: 'recomendação de cuidado', pattern: _word(r'recomenda[cç](?:[aã]o|[oõ]es)\s+de\s+cuidados?')),
  (name: 'pronto atendimento', pattern: _word(r'pronto[\s-]+atendimento')),
  (name: 'concordância clínica', pattern: _word(r'concord[aâ]ncia\s+cl[ií]nica')),
  (name: 'precisas', pattern: _word('precisas')),
  // Strategy §15 (Dualis Free): disorder names and clinical grouping.
  (name: 'transtorno/disorder', pattern: _word(r'(?:transtornos?|trastornos?|disorders?)')),
  (name: 'TAG', pattern: _word('TAG', caseSensitive: true)),
  (name: 'TOC', pattern: _word('TOC', caseSensitive: true)),
  (name: 'TEPT', pattern: _word('TEPT', caseSensitive: true)),
  (name: 'bipolar', pattern: _word(r'bipolar(?:es)?')),
  (name: 'ciclotimia', pattern: _word(r'ciclot[ií]m\p{L}*|cyclothym\p{L}*')),
  (name: 'borderline', pattern: _word('borderline')),
  (name: 'grupo clínico', pattern: _word(r'grupos?\s+cl[ií]nicos?')),
  (name: 'sintoma estruturado', pattern: _word(r'sintomas?\s+estruturados?')),
  (name: 'esfera', pattern: _word(r'esferas?')),
  (name: 'vertical de tratamento', pattern: _word(r'verticais?\s+de\s+tratamento')),
  (name: 'anedonia', pattern: _word(r'anh?edonia')),
  (name: 'radiculopatia', pattern: _word(r'radiculopat\p{L}*')),
  (name: 'costocondrite', pattern: _word(r'costocondri\p{L}*|costochondri\p{L}*')),
  (name: 'isquemia', pattern: _word(r'isqu[eé]mi\p{L}*|ischemi\p{L}*|ischaemi\p{L}*')),
  (name: '☠️', pattern: RegExp('\u2620')),
];

RegExp _word(String body, {bool caseSensitive = false}) => RegExp(
      '(?<![\\p{L}\\p{N}_])(?:$body)(?![\\p{L}\\p{N}_])',
      caseSensitive: caseSensitive,
      unicode: true,
    );

/// l10n keys that belong to the help resources screen (plan §2 exception).
const allowedArbKeyPrefixes = ['emergency', 'urgentHelp', 'safety'];

/// Dart files that belong to the help resources screen.
final allowedDartPath = RegExp(r'(emergency|safety|urgent_help)', caseSensitive: false);

/// A banned word right after a negation ("não faz diagnóstico", "does not
/// diagnose", "no realiza diagnósticos") is the intended-use disclaimer
/// itself (plan §1.1), so it is allowed. "sem"/"without" do not count.
final _negatedContext = RegExp(
  r'(?<![\p{L}\p{N}_])(?:não|nao|nem|not|nor|never|no|ni|nunca|jamais)(?:\s+[\p{L},]+){0,1}\s*$',
  caseSensitive: false,
  unicode: true,
);

/// Next item of a negated list: "does not assess symptoms, indicate urgency,
/// diagnose or recommend treatment".
final _negationWord = RegExp(
  r'(?<![\p{L}\p{N}_])(?:não|nao|nem|not|nor|never|no|ni|nunca|jamais)(?![\p{L}\p{N}_])',
  caseSensitive: false,
  unicode: true,
);
final _listContinuation = RegExp(
  r'(?:,|(?<![\p{L}])(?:or|ou|o|nor|nem|ni)(?![\p{L}]))\s*(?:\p{L}+\s+)?$',
  caseSensitive: false,
  unicode: true,
);

bool _isNegated(String text, int matchStart) {
  final before = text.substring(0, matchStart);
  if (_negatedContext.hasMatch(before.endsWith(' ') ? before : '$before ')) {
    return true;
  }
  final clauseStart = before.lastIndexOf(RegExp(r'[.;:!?\n]')) + 1;
  final clause = before.substring(clauseStart);
  return _negationWord.hasMatch(clause) && _listContinuation.hasMatch(clause);
}

List<String> findBannedTerms(String text) => [
      for (final term in bannedTerms)
        if (term.pattern
            .allMatches(text)
            .any((m) => !_isNegated(text, m.start)))
          term.name,
    ];

class StringLiteral {
  StringLiteral(this.line, this.value, this.precedingCode);
  final int line;
  final String value;

  /// Code right before the literal (same statement), used to skip log calls.
  final String precedingCode;
}

/// Extracts string literals from Dart source, skipping comments.
/// Interpolated expressions are replaced by a space.
List<StringLiteral> extractStringLiterals(String src) {
  final out = <StringLiteral>[];
  var i = 0;
  var line = 1;
  final n = src.length;

  String readString(int quoteLen, String quote, bool raw) {
    final buf = StringBuffer();
    while (i < n) {
      if (src.startsWith(quote * quoteLen, i)) {
        i += quoteLen;
        return buf.toString();
      }
      final c = src[i];
      if (c == '\n') {
        if (quoteLen == 1) return buf.toString();
        line++;
      }
      if (!raw && c == r'\' && i + 1 < n) {
        buf.write(src[i + 1]);
        i += 2;
        continue;
      }
      if (!raw && c == r'$' && i + 1 < n && src[i + 1] == '{') {
        // Skip the interpolated expression, honouring nested braces/strings.
        i += 2;
        var depth = 1;
        while (i < n && depth > 0) {
          final d = src[i];
          if (d == '\n') line++;
          if (d == '{') depth++;
          if (d == '}') depth--;
          if (d == "'" || d == '"') {
            i++;
            readString(1, d, false);
            continue;
          }
          i++;
        }
        buf.write(' ');
        continue;
      }
      if (!raw && c == r'$') {
        i++;
        while (i < n && RegExp(r'[A-Za-z0-9_]').hasMatch(src[i])) {
          i++;
        }
        buf.write(' ');
        continue;
      }
      buf.write(c);
      i++;
    }
    return buf.toString();
  }

  while (i < n) {
    final c = src[i];
    if (c == '\n') {
      line++;
      i++;
    } else if (src.startsWith('//', i)) {
      while (i < n && src[i] != '\n') {
        i++;
      }
    } else if (src.startsWith('/*', i)) {
      final end = src.indexOf('*/', i + 2);
      final stop = end == -1 ? n : end + 2;
      line += '\n'.allMatches(src.substring(i, stop)).length;
      i = stop;
    } else if (c == "'" || c == '"' || ((c == 'r' || c == 'R') && i + 1 < n && (src[i + 1] == "'" || src[i + 1] == '"') && (i == 0 || !RegExp(r'[A-Za-z0-9_]').hasMatch(src[i - 1])))) {
      final raw = c == 'r' || c == 'R';
      if (raw) i++;
      final quote = src[i];
      final triple = src.startsWith(quote * 3, i);
      final startLine = line;
      final statementStart = src.lastIndexOf(RegExp(r'[;{}]'), i);
      final preceding = src.substring(statementStart + 1, i);
      i += triple ? 3 : 1;
      final value = readString(triple ? 3 : 1, quote, raw);
      out.add(StringLiteral(startLine, value, preceding));
    } else {
      i++;
    }
  }
  return out;
}

/// True when the literal is an identifier-like value (key, route, JSON field,
/// asset path, enum name) rather than text a person reads.
bool isIdentifierLiteral(String value) {
  final v = value.trim();
  if (v.isEmpty) return true;
  if (RegExp(r'\s').hasMatch(v)) return false;
  if (RegExp(r'[_/.:#@=?&\\]').hasMatch(v)) return true;
  if (RegExp(r'\d').hasMatch(v)) return true;
  if (v == v.toLowerCase()) return true; // triage, clinical
  if (RegExp(r'^\p{Ll}+\p{Lu}', unicode: true).hasMatch(v)) return true; // camelCase
  return false; // "Triagem", "Paciente", "ESI"
}

final _logCall = RegExp(r'(debugPrint|print|log|logger\.\w+|developer\.log)\s*\([^()]*$');

void main() {
  final libDir = Directory('lib');

  group('Wellness vocabulary guard', () {
    test('banned-term matcher behaves as expected', () {
      expect(findBannedTerms('Resultado da Triagem'), contains('triagem/triage/triaje'));
      expect(findBannedTerms('Seu prontuário'), contains('prontuário'));
      expect(findBannedTerms('Orientações Preventivas Precisas'), contains('precisas'));
      expect(findBannedTerms('Protocolo ESI nível 2'), contains('ESI'));
      expect(findBannedTerms('Concordância clínica 100%'), isNotEmpty);
      expect(findBannedTerms('Revise seu registro de bem-estar'), isEmpty);
      expect(findBannedTerms('Precisa de ajuda agora?'), isEmpty);
      expect(findBannedTerms('O app não faz diagnóstico nem triagem.'), isEmpty);
      expect(findBannedTerms('It does not diagnose or recommend treatment.'), isEmpty);
      expect(findBannedTerms('Artigos sem diagnósticos falsos'), isNotEmpty);
      expect(findBannedTerms('Não perca sua triagem diária'), isNotEmpty);
      expect(
        findBannedTerms('It does not assess symptoms, indicate urgency, diagnose or recommend treatment.'),
        isEmpty,
      );
      expect(findBannedTerms('Não esqueça: faça sua triagem, e veja o diagnóstico.'), isNotEmpty);
      expect(findBannedTerms('Resiliência e esforço'), isEmpty);
      expect(findBannedTerms('Sinais de transtorno bipolar'), containsAll(['transtorno/disorder', 'bipolar']));
      expect(findBannedTerms('Grupo 09 TAG'), contains('TAG'));
      expect(findBannedTerms('Esfera: radiculopatia'), containsAll(['esfera', 'radiculopatia']));
      expect(findBannedTerms('Paralisante ☠️'), contains('☠️'));
      expect(findBannedTerms('Tag da etiqueta'), isEmpty);
      expect(findBannedTerms('Toque no mapa'), isEmpty);
      expect(isIdentifierLiteral('triage_outcome'), isTrue);
      expect(isIdentifierLiteral('/v1/triage/outcome'), isTrue);
      expect(isIdentifierLiteral('clinicalConcept'), isTrue);
      expect(isIdentifierLiteral('Triagem'), isFalse);
      expect(isIdentifierLiteral('Paciente'), isFalse);
      final literals = extractStringLiterals(
        "// 'Triagem' in a comment\nfinal a = 'Olá \${user.name}'; /* 'paciente' */ final b = \"x\";",
      );
      expect(literals.map((l) => l.value), ['Olá  ', 'x']);
    });

    test('.arb values contain no banned vocabulary outside help resources', () {
      final hits = <String>[];
      for (final lang in ['pt', 'en', 'es']) {
        final file = File('lib/l10n/app_$lang.arb');
        final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        arb.forEach((key, value) {
          if (key.startsWith('@') || value is! String) return;
          if (allowedArbKeyPrefixes.any(key.startsWith)) return;
          final terms = findBannedTerms(value);
          if (terms.isNotEmpty) {
            hits.add('app_$lang.arb  $key  [${terms.join(', ')}]  "$value"');
          }
        });
      }
      expect(hits, isEmpty, reason: 'Banned vocabulary in .arb files:\n${hits.join('\n')}');
    });

    test('Dart string literals contain no banned vocabulary outside help resources', () {
      final hits = <String>[];
      final files = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('.g.dart') && !f.path.endsWith('.freezed.dart'))
          .where((f) => !f.path.contains('${Platform.pathSeparator}l10n${Platform.pathSeparator}app_localizations'))
          .where((f) => !allowedDartPath.hasMatch(f.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      for (final file in files) {
        for (final literal in extractStringLiterals(file.readAsStringSync())) {
          if (isIdentifierLiteral(literal.value)) continue;
          if (_logCall.hasMatch(literal.precedingCode)) continue;
          final terms = findBannedTerms(literal.value);
          if (terms.isNotEmpty) {
            final shown = literal.value.replaceAll('\n', r'\n');
            hits.add('${file.path}:${literal.line}  [${terms.join(', ')}]  "$shown"');
          }
        }
      }
      expect(hits, isEmpty, reason: 'Banned vocabulary in lib/ string literals:\n${hits.join('\n')}');
    });
  });
}
