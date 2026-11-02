import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Why listening could not start.
enum VoiceStartError { permissionDenied, unavailable }

/// Speech to text, behind an interface so tests and the simulator QA can
/// feed phrases without a microphone.
abstract class VoiceInputService {
  /// Asks for microphone and speech permission the first time. Returns
  /// null when ready.
  Future<VoiceStartError?> prepare();

  /// Listens once. [onResult] gets partial text and then the final text;
  /// [onDone] runs when the session ends (final text, silence or error).
  Future<void> listen({
    required String languageCode,
    required bool dictation,
    required void Function(String text, bool isFinal) onResult,
    required void Function() onDone,
  });

  Future<void> stop();

  Future<void> cancel();
}

/// Platform speech recognition (Apple Speech / Android SpeechRecognizer).
/// Recognition runs on the device when the device supports it for the
/// language; otherwise the platform service is used. Nothing said is
/// stored or sent to the Dualis backend by this class.
class SpeechToTextVoiceInputService implements VoiceInputService {
  final SpeechToText _speech;
  bool _ready = false;
  bool _onDevice = true;
  void Function()? _onDone;
  String? _localeId;
  String? _localeLanguage;

  // Retry state for the on-device fallback.
  String? _lastLanguage;
  bool _lastDictation = false;
  void Function(String, bool)? _lastOnResult;
  bool _gotResult = false;

  SpeechToTextVoiceInputService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  @override
  Future<VoiceStartError?> prepare() async {
    if (_ready) return null;
    try {
      _ready = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
    } catch (_) {
      _ready = false;
    }
    if (_ready) return null;
    final permission = await _speech.hasPermission;
    return permission ? VoiceStartError.unavailable : VoiceStartError.permissionDenied;
  }

  Future<String?> _localeFor(String languageCode) async {
    if (_localeLanguage == languageCode) return _localeId;
    const preferred = {'pt': 'pt_BR', 'es': 'es_ES', 'en': 'en_US'};
    String? chosen;
    try {
      final locales = await _speech.locales();
      final ids = [for (final l in locales) l.localeId.replaceAll('-', '_')];
      final want = preferred[languageCode];
      if (want != null && ids.contains(want)) {
        chosen = want;
      } else {
        chosen = ids.where((id) => id.startsWith('${languageCode}_')).firstOrNull;
      }
    } catch (_) {}
    _localeLanguage = languageCode;
    _localeId = chosen ?? preferred[languageCode];
    return _localeId;
  }

  @override
  Future<void> listen({
    required String languageCode,
    required bool dictation,
    required void Function(String text, bool isFinal) onResult,
    required void Function() onDone,
  }) async {
    _onDone = onDone;
    _lastLanguage = languageCode;
    _lastDictation = dictation;
    _lastOnResult = onResult;
    _gotResult = false;
    final localeId = await _localeFor(languageCode);
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) {
          _gotResult = true;
          onResult(r.recognizedWords, r.finalResult);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          onDevice: _onDevice,
          partialResults: true,
          cancelOnError: true,
          listenMode: dictation ? ListenMode.dictation : ListenMode.confirmation,
          listenFor: Duration(seconds: dictation ? 60 : 20),
          pauseFor: Duration(seconds: dictation ? 4 : 3),
        ),
      );
    } catch (_) {
      if (_onDevice) {
        _onDevice = false;
        return listen(
          languageCode: languageCode,
          dictation: dictation,
          onResult: onResult,
          onDone: onDone,
        );
      }
      _finish();
    }
  }

  /// On-device recognition failed before hearing anything: retry once
  /// with the platform service (then keep using it). The retry waits for
  /// the failed session to report "done", so its late status never ends
  /// the new session.
  bool _retryPending = false;
  Timer? _retryTimer;

  void _handleError(SpeechRecognitionError error) {
    const normalEnds = {
      'error_permission',
      'error_no_match',
      'error_speech_timeout',
      'error_busy',
    };
    if (_onDevice && !_gotResult && !normalEnds.contains(error.errorMsg)) {
      _onDevice = false;
      _retryPending = true;
      // Some platforms send no "done" after an error.
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(milliseconds: 400), _retry);
      return;
    }
    _finish();
  }

  void _handleStatus(String status) {
    if (status != SpeechToText.doneStatus) return;
    if (_retryPending) {
      _retry();
      return;
    }
    _finish();
  }

  void _retry() {
    _retryTimer?.cancel();
    if (!_retryPending) return;
    _retryPending = false;
    final onResult = _lastOnResult;
    final onDone = _onDone;
    final language = _lastLanguage;
    if (onResult == null || onDone == null || language == null) {
      _finish();
      return;
    }
    listen(
      languageCode: language,
      dictation: _lastDictation,
      onResult: onResult,
      onDone: onDone,
    );
  }

  void _finish() {
    final done = _onDone;
    _onDone = null;
    done?.call();
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    _onDone = null;
    _retryPending = false;
    _retryTimer?.cancel();
    await _speech.cancel();
  }
}

/// Overridden in tests with a scripted service.
final voiceInputServiceProvider = Provider<VoiceInputService>(
  (ref) => SpeechToTextVoiceInputService(),
);
