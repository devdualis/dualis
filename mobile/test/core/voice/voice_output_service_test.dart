import 'dart:async';

import 'package:dualis_mobile/core/voice/voice_output_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Records the plugin calls and lets the test fire the platform events.
class FakeTtsEngine implements TtsEngine {
  final List<String> calls = [];
  Set<String> available = {'pt-BR', 'es-US', 'en-US'};
  List<Map<String, String>> voices = [];
  bool missingPlugin = false;
  bool accept = true;

  VoidCallback? onStart;
  VoidCallback? onComplete;
  VoidCallback? onCancel;
  void Function(dynamic)? onError;

  Map<String, String>? voice;
  (IosTextToSpeechAudioCategory, List<IosTextToSpeechAudioCategoryOptions>, IosTextToSpeechAudioMode)?
      iosCategory;

  Future<T> _call<T>(String name, T value) async {
    calls.add(name);
    if (missingPlugin) throw MissingPluginException('No implementation found for $name');
    return value;
  }

  void start() => onStart?.call();
  void complete() => onComplete?.call();
  void cancel() => onCancel?.call();
  void error() => onError?.call('synthesis failed');

  @override
  Future<void> awaitSpeakCompletion(bool value) => _call('awaitSpeakCompletion:$value', null);

  @override
  Future<bool> speak(String text) async {
    final hold = holdSpeak;
    holdSpeak = null;
    final result = _call('speak', accept);
    if (hold != null) await hold.future;
    return result;
  }

  /// When set, the next engine stop waits for it (a slow platform call).
  Completer<void>? holdStop;

  /// When set, the next engine speak waits for it.
  Completer<void>? holdSpeak;

  @override
  Future<void> stop() async {
    final hold = holdStop;
    holdStop = null;
    final result = _call('stop', null);
    if (hold != null) await hold.future;
    return result;
  }

  @override
  Future<bool> isLanguageAvailable(String languageTag) =>
      _call('isLanguageAvailable:$languageTag', available.contains(languageTag));

  @override
  Future<void> setLanguage(String languageTag) => _call('setLanguage:$languageTag', null);

  @override
  Future<void> setSpeechRate(double rate) => _call('setSpeechRate:$rate', null);

  @override
  Future<void> setPitch(double pitch) => _call('setPitch:$pitch', null);

  @override
  Future<List<Map<String, String>>> getVoices() => _call('getVoices', voices);

  @override
  Future<void> setVoice(Map<String, String> voice) {
    this.voice = voice;
    return _call('setVoice', null);
  }

  @override
  Future<void> setSharedInstance(bool shared) => _call('setSharedInstance:$shared', null);

  @override
  Future<void> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options,
    IosTextToSpeechAudioMode mode,
  ) {
    iosCategory = (category, options, mode);
    return _call('setIosAudioCategory', null);
  }

  @override
  void setStartHandler(VoidCallback handler) => onStart = handler;

  @override
  void setCompletionHandler(VoidCallback handler) => onComplete = handler;

  @override
  void setCancelHandler(VoidCallback handler) => onCancel = handler;

  @override
  void setErrorHandler(void Function(dynamic message) handler) => onError = handler;
}

/// Lets queued microtasks and the speak call run.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeTtsEngine engine;
  late FlutterTtsVoiceOutputService service;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    engine = FakeTtsEngine();
    service = FlutterTtsVoiceOutputService(engine);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  /// Starts a speak and reports whether it has completed so far.
  Future<(Future<void>, bool Function())> begin(String text) async {
    var done = false;
    final future = service.speak(text)..then((_) => done = true);
    await settle();
    return (future, () => done);
  }

  test('speak completes when the engine reports completion', () async {
    final (future, done) = await begin('Como você está?');
    engine.start();
    await settle();
    expect(done(), isFalse);
    engine.complete();
    await future;
    expect(done(), isTrue);
  });

  test('speak completes when the engine reports cancel', () async {
    final (future, done) = await begin('Como você está?');
    engine
      ..start()
      ..cancel();
    await future;
    expect(done(), isTrue);
  });

  test('speak completes when the engine reports an error', () async {
    final (future, done) = await begin('Como você está?');
    engine.error();
    await future;
    expect(done(), isTrue);
  });

  test('speak completes when stop() is called while speaking', () async {
    final (future, done) = await begin('Como você está?');
    engine.start();
    await service.stop();
    await future;
    expect(done(), isTrue);
    expect(engine.calls.last, 'stop');
  });

  test('speak completes after the safety timeout when the engine reports nothing', () async {
    service = FlutterTtsVoiceOutputService(
      engine,
      perCharacter: Duration.zero,
      timeoutBase: const Duration(milliseconds: 40),
    );
    final (future, done) = await begin('Como você está?');
    expect(done(), isFalse);
    await future.timeout(const Duration(seconds: 2));
    expect(done(), isTrue);
  });

  test('the safety timeout also stops the engine (the mic never opens over speech)', () async {
    service = FlutterTtsVoiceOutputService(
      engine,
      perCharacter: Duration.zero,
      timeoutBase: const Duration(milliseconds: 40),
    );
    final (future, _) = await begin('Como você está?');
    engine.start();
    final speak = engine.calls.lastIndexOf('speak');
    await future.timeout(const Duration(seconds: 2));
    await settle();
    expect(engine.calls.lastIndexOf('stop'), greaterThan(speak));
  });

  test('stop() while speak waits for the engine stop: nothing is read', () async {
    await service.prepare('pt');
    engine.calls.clear();
    final release = engine.holdStop = Completer<void>();
    var done = false;
    final future = service.speak('Como você está?')..then((_) => done = true);
    await settle();
    expect(engine.calls, ['stop']);

    await service.stop();
    release.complete();
    await future.timeout(const Duration(seconds: 1));

    expect(done, isTrue);
    expect(engine.calls, isNot(contains('speak')));
  });

  test('stop() while the engine takes the text: it is stopped right after', () async {
    await service.prepare('pt');
    engine.calls.clear();
    final release = engine.holdSpeak = Completer<void>();
    final future = service.speak('Como você está?');
    await settle();
    expect(engine.calls, ['stop', 'speak']);

    await service.stop();
    release.complete();
    await future.timeout(const Duration(seconds: 1));
    await settle();

    expect(engine.calls.last, 'stop');
    expect(engine.calls.lastIndexOf('stop'), greaterThan(engine.calls.indexOf('speak')));
  });

  test('a late cancel of the stopped speech does not end the new one', () async {
    final (first, firstDone) = await begin('Primeira pergunta');
    engine.start();
    final (second, secondDone) = await begin('Segunda pergunta');
    await first;
    expect(firstDone(), isTrue);
    engine.cancel(); // The first speech's cancel, before the second starts.
    await settle();
    expect(secondDone(), isFalse);
    engine
      ..start()
      ..complete();
    await second;
    expect(secondDone(), isTrue);
  });

  test('speak stops the engine before speaking', () async {
    final (future, _) = await begin('Como você está?');
    final stop = engine.calls.lastIndexOf('stop');
    final speak = engine.calls.lastIndexOf('speak');
    expect(stop, greaterThanOrEqualTo(0));
    expect(stop, lessThan(speak));
    expect(engine.calls, contains('awaitSpeakCompletion:false'));
    engine.complete();
    await future;
  });

  test('prepare(pt) sets pt-BR when it is available', () async {
    await service.prepare('pt');
    expect(engine.calls, contains('setLanguage:pt-BR'));
    expect(engine.calls, contains('setSpeechRate:${FlutterTtsVoiceOutputService.speechRate}'));
    expect(engine.calls, contains('setPitch:1.0'));
  });

  test('prepare(es) tries es-ES, then es-US', () async {
    await service.prepare('es');
    final asked = [for (final c in engine.calls) if (c.startsWith('isLanguageAvailable')) c];
    expect(asked, ['isLanguageAvailable:es-ES', 'isLanguageAvailable:es-US']);
    expect(engine.calls, contains('setLanguage:es-US'));
    expect(engine.calls, isNot(contains('setLanguage:es-ES')));
  });

  test('a missing language keeps the device default voice', () async {
    engine.available = {};
    await service.prepare('en');
    expect(engine.calls.where((c) => c.startsWith('setLanguage')), isEmpty);
    expect(engine.calls, isNot(contains('setVoice')));
  });

  test('prepare for the same language twice configures once', () async {
    await service.prepare('pt');
    await service.prepare('pt');
    expect(engine.calls.where((c) => c == 'setLanguage:pt-BR'), hasLength(1));
    expect(engine.calls.where((c) => c.startsWith('setSpeechRate')), hasLength(1));
  });

  test('on Android an offline voice of the language is selected', () async {
    engine.voices = [
      {'name': 'pt-br-x-online', 'locale': 'pt-BR', 'network_required': '1'},
      {'name': 'en-us-x-local', 'locale': 'en-US', 'network_required': '0'},
      {'name': 'pt-br-x-local', 'locale': 'pt-BR', 'network_required': '0'},
    ];
    await service.prepare('pt');
    expect(engine.voice, {'name': 'pt-br-x-local', 'locale': 'pt-BR'});
  });

  test('on Android with only online voices the default stays', () async {
    engine.voices = [
      {'name': 'pt-br-x-online', 'locale': 'pt-BR', 'network_required': '1'},
    ];
    await service.prepare('pt');
    expect(engine.voice, isNull);
  });

  test('on iOS the shared playAndRecord voice-prompt session is set, no voice lookup', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    service = FlutterTtsVoiceOutputService(engine);
    await service.prepare('pt');
    expect(engine.calls, contains('setSharedInstance:true'));
    final (category, options, mode) = engine.iosCategory!;
    expect(category, IosTextToSpeechAudioCategory.playAndRecord);
    expect(options, unorderedEquals([
      IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
      IosTextToSpeechAudioCategoryOptions.allowBluetooth,
      IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      IosTextToSpeechAudioCategoryOptions.mixWithOthers,
    ]));
    expect(mode, IosTextToSpeechAudioMode.voicePrompt);
    expect(engine.calls, isNot(contains('getVoices')));
  });

  test('a MissingPluginException makes speak complete at once', () async {
    engine.missingPlugin = true;
    await service.prepare('pt');
    await service.speak('Como você está?').timeout(const Duration(milliseconds: 200));
    await service.stop();
  });
}
