import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Microsoft Fluent Emoji 3D (MIT), bundled under `assets/emoji/`. Used only
/// where the person picks an emotion or state: mood, "O que pesa" options and
/// sleep quality. Everywhere else the redesign uses duotone icons.
///
/// The key -> file mapping lives here and nowhere else. A key without an entry
/// has no Fluent emoji: callers keep the icon they already drew.
class FluentEmoji {
  const FluentEmoji._();

  static const String _dir = 'assets/emoji';

  /// Journal keys (see `journalEmojis`) mapped to a bundled PNG name.
  static const Map<String, String> _byJournalKey = {
    // Mood.
    'bem': 'smiling_face_with_smiling_eyes',
    'normal': 'slightly_smiling_face',
    'nao_tao_bem': 'pensive_face',
    // "O que pesa": the emotional branches.
    'passado.tristeza': 'fallen_leaf',
    'passado.memoria': 'repeat_button',
    'presente.energia': 'battery',
    'presente.sobrecarga': 'high_voltage',
    'presente.solidao': 'busts_in_silhouette',
    'futuro.mente': 'thought_balloon',
    'futuro.medo': 'worried_face',
  };

  /// Sleep quality (Bem / Regular / Mal) and sleeping, for the habits screens.
  static const Map<String, String> sleepQuality = {
    'bem': 'smiling_face_with_smiling_eyes',
    'regular': 'neutral_face',
    'mal': 'tired_face',
    'sono': 'sleeping_face',
  };

  /// Asset path for a journal key, or null when the key has no Fluent emoji.
  static String? assetForJournalKey(String key) {
    final name = _byJournalKey[key];
    return name == null ? null : '$_dir/${name}_3d.png';
  }

  /// Asset path for a sleep-quality key, or null.
  static String? assetForSleep(String key) {
    final name = sleepQuality[key];
    return name == null ? null : '$_dir/${name}_3d.png';
  }

  /// The emoji image for [key], or [fallback] when it is not mapped.
  static Widget forJournalKey(String key, {required double size, required Widget fallback}) {
    final path = assetForJournalKey(key);
    if (path == null) return fallback;
    return image(path, size: size);
  }

  static Widget image(String path, {required double size}) => ExcludeSemantics(
        child: Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      );

  static const String _license = '''
MIT License

Copyright (c) Microsoft Corporation.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';

  static bool _licenseRegistered = false;

  /// Adds the Fluent Emoji MIT notice to the Flutter licenses page. Safe to
  /// call more than once.
  static void registerLicense() {
    if (_licenseRegistered) return;
    _licenseRegistered = true;
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(
        ['Fluent Emoji (Microsoft)'],
        _license,
      );
    });
  }
}
