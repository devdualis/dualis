import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../l10n/app_localizations.dart';

/// Text to speech, behind an interface so tests and the simulator QA can
/// check what is read without a speaker. It reads only what is on screen
/// (the step's question and its option labels), never what the person
/// wrote, and it never interprets anything.
abstract class VoiceOutputService {
  /// Picks the voice for [languageCode] ('pt', 'es' or 'en'). When the
  /// device has no voice for it, the device default voice stays.
  Future<void> prepare(String languageCode);

  /// Reads [text] aloud. Completes when the speech ends, is cancelled,
  /// fails or a safety timeout passes; it never throws.
  Future<void> speak(String text);

  /// Stops at once; a pending [speak] completes.
  Future<void> stop();
}

/// The plugin calls the service needs, so it can be unit-tested without the
/// platform.
abstract class TtsEngine {
  Future<void> awaitSpeakCompletion(bool value);

  /// False when the engine refused the text (nothing will be read).
  Future<bool> speak(String text);
  Future<void> stop();
  Future<bool> isLanguageAvailable(String languageTag);
  Future<void> setLanguage(String languageTag);
  Future<void> setSpeechRate(double rate);
  Future<void> setPitch(double pitch);

  /// Android: name, locale and network_required ("0" works offline).
  Future<List<Map<String, String>>> getVoices();
  Future<void> setVoice(Map<String, String> voice);

  /// iOS: share the app's audio session with speech recognition.
  Future<void> setSharedInstance(bool shared);
  Future<void> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options,
    IosTextToSpeechAudioMode mode,
  );

  void setStartHandler(VoidCallback handler);
  void setCompletionHandler(VoidCallback handler);
  void setCancelHandler(VoidCallback handler);
  void setErrorHandler(void Function(dynamic message) handler);
}

/// [TtsEngine] over the `flutter_tts` plugin.
class FlutterTtsEngine implements TtsEngine {
  FlutterTtsEngine([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  static bool _truthy(dynamic value) => value == true || value == 1;

  @override
  Future<void> awaitSpeakCompletion(bool value) => _tts.awaitSpeakCompletion(value);

  @override
  Future<bool> speak(String text) async => (await _tts.speak(text)) != 0;

  @override
  Future<void> stop() => _tts.stop();

  @override
  Future<bool> isLanguageAvailable(String languageTag) async =>
      _truthy(await _tts.isLanguageAvailable(languageTag));

  @override
  Future<void> setLanguage(String languageTag) => _tts.setLanguage(languageTag);

  @override
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);

  @override
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  @override
  Future<List<Map<String, String>>> getVoices() async {
    final raw = await _tts.getVoices;
    if (raw is! List) return const [];
    return [
      for (final v in raw)
        if (v is Map) {for (final e in v.entries) '${e.key}': '${e.value}'},
    ];
  }

  @override
  Future<void> setVoice(Map<String, String> voice) => _tts.setVoice(voice);

  @override
  Future<void> setSharedInstance(bool shared) => _tts.setSharedInstance(shared);

  @override
  Future<void> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options,
    IosTextToSpeechAudioMode mode,
  ) =>
      _tts.setIosAudioCategory(category, options, mode);

  @override
  void setStartHandler(VoidCallback handler) => _tts.setStartHandler(handler);

  @override
  void setCompletionHandler(VoidCallback handler) => _tts.setCompletionHandler(handler);

  @override
  void setCancelHandler(VoidCallback handler) => _tts.setCancelHandler(handler);

  @override
  void setErrorHandler(void Function(dynamic message) handler) =>
      _tts.setErrorHandler(handler);
}

/// On-device speech (AVSpeechSynthesizer / Android TextToSpeech). The done
/// signal is a [Completer] completed by the completion, cancel and error
/// handlers, by [stop] and by a safety timer: the plugin's own speak future
/// never completes on iOS after a cancel, so it is not awaited.
class FlutterTtsVoiceOutputService implements VoiceOutputService {
  FlutterTtsVoiceOutputService(
    this._engine, {
    this.perCharacter = const Duration(milliseconds: 90),
    this.timeoutBase = const Duration(seconds: 3),
  });

  final TtsEngine _engine;

  /// Safety timeout: [timeoutBase] plus [perCharacter] for each character.
  final Duration perCharacter;
  final Duration timeoutBase;

  /// Calm reading speed on the plugin scale (0.5 is the platform normal).
  static const double speechRate = 0.45;
  static const double pitch = 1.0;

  /// Device locales tried for each app language, in order.
  static const Map<String, List<String>> localesFor = {
    'pt': ['pt-BR'],
    'es': ['es-ES', 'es-US'],
    'en': ['en-US'],
  };

  Future<void>? _init;
  String? _preparedLanguage;
  Completer<void>? _pending;
  Timer? _timer;

  /// Cancel events of a speech stopped just before a new one must not end
  /// the new one: a cancel counts only once the new speech has started.
  bool _started = false;

  /// No platform plugin (widget tests, unsupported platform): nothing is
  /// read and every call returns at once.
  bool _unavailable = false;

  Future<void> _ensureInit() => _init ??= _initialize();

  Future<void> _initialize() async {
    _engine
      ..setStartHandler(() => _started = true)
      ..setCompletionHandler(_finish)
      ..setCancelHandler(() {
        if (_started) _finish();
      })
      ..setErrorHandler((_) => _finish());
    await _guard(() => _engine.awaitSpeakCompletion(false));
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // speech_to_text switches the session to playAndRecord while it
      // listens; speaking in the same category keeps the loudspeaker and
      // Bluetooth after a listen, and is not muted by the silent switch.
      await _guard(() => _engine.setSharedInstance(true));
      await _guard(() => _engine.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playAndRecord,
            const [
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
            IosTextToSpeechAudioMode.voicePrompt,
          ));
    }
  }

  @override
  Future<void> prepare(String languageCode) async {
    await _ensureInit();
    if (_preparedLanguage == languageCode) return;
    _preparedLanguage = languageCode;
    for (final tag in localesFor[languageCode] ?? const <String>[]) {
      final available = await _guard(() => _engine.isLanguageAvailable(tag)) ?? false;
      if (available) {
        await _guard(() => _engine.setLanguage(tag));
        if (defaultTargetPlatform == TargetPlatform.android) await _pickOfflineVoice(tag);
        break;
      }
    }
    await _guard(() => _engine.setSpeechRate(speechRate));
    await _guard(() => _engine.setPitch(pitch));
  }

  /// Android: some engines default to a voice that needs the network; a
  /// voice of the same locale marked network_required "0" works offline.
  Future<void> _pickOfflineVoice(String tag) async {
    final voices = await _guard(_engine.getVoices) ?? const <Map<String, String>>[];
    String norm(String? locale) => (locale ?? '').replaceAll('_', '-').toLowerCase();
    for (final v in voices) {
      final name = v['name'] ?? '';
      if (name.isEmpty) continue;
      if (norm(v['locale']) == tag.toLowerCase() && v['network_required'] == '0') {
        await _guard(() => _engine.setVoice({'name': name, 'locale': v['locale']!}));
        return;
      }
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInit();
    if (_unavailable) return;
    _finish();
    await _guard(_engine.stop);
    final done = Completer<void>();
    _pending = done;
    _started = false;
    _timer = Timer(timeoutBase + perCharacter * text.length, () => _finish(done));
    final accepted = await _guard(() => _engine.speak(text)) ?? false;
    if (!accepted || _unavailable) _finish(done);
    return done.future;
  }

  @override
  Future<void> stop() async {
    _finish();
    await _guard(_engine.stop);
  }

  void _finish([Completer<void>? only]) {
    final pending = _pending;
    if (pending == null || (only != null && !identical(pending, only))) return;
    _pending = null;
    _started = false;
    _timer?.cancel();
    _timer = null;
    if (!pending.isCompleted) pending.complete();
  }

  /// Plugin failures never reach the caller.
  Future<T?> _guard<T>(Future<T> Function() call) async {
    if (_unavailable) return null;
    try {
      return await call();
    } on MissingPluginException {
      _unavailable = true;
      return null;
    } catch (error) {
      debugPrint('VoiceOutput: $error');
      return null;
    }
  }
}

/// Overridden in tests with a fake that records what is read.
final voiceOutputServiceProvider = Provider<VoiceOutputService>((ref) {
  final service = FlutterTtsVoiceOutputService(FlutterTtsEngine());
  ref.onDispose(service.stop);
  return service;
});

/// Options read aloud after the question; the rest stay on screen.
const int maxReadOptions = 6;

/// What is read for a step: its question, then at most [maxReadOptions]
/// option labels ("Como você está? Bem, Não tão bem."). Nothing else.
String composeReadOut(AppLocalizations l10n, String question, List<String> options) {
  final q = question.trim();
  final labels = [
    for (final o in options)
      if (o.trim().isNotEmpty) o.trim(),
  ].take(maxReadOptions).toList();
  if (labels.isEmpty) return q;
  final ends = q.isEmpty || RegExp(r'[.?!:;]$').hasMatch(q);
  return '$q${ends ? '' : '.'} ${labels.join(', ')}.'.trim();
}
