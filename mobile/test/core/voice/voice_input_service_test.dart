import 'dart:async';
import 'dart:ui' show Locale;

import 'package:dualis_mobile/core/voice/voice_input_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_to_text.dart';

class _MockSpeech extends Mock implements SpeechToText {}

void main() {
  setUpAll(() {
    registerFallbackValue(SpeechListenOptions());
  });

  late _MockSpeech speech;

  setUp(() {
    speech = _MockSpeech();
    when(() => speech.locales()).thenAnswer((_) async => []);
    when(() => speech.listen(
          onResult: any(named: 'onResult'),
          listenOptions: any(named: 'listenOptions'),
        )).thenAnswer((_) async {});
  });

  Future<SpeechListenOptions> listenOnce(SpeechToTextVoiceInputService service) async {
    await service.listen(
      languageCode: 'es',
      dictation: false,
      onResult: (_, __) {},
      onDone: () {},
    );
    final options = verify(() => speech.listen(
          onResult: any(named: 'onResult'),
          listenOptions: captureAny(named: 'listenOptions'),
        )).captured.single as SpeechListenOptions;
    return options;
  }

  Future<bool?> onDeviceUsed(SpeechToTextVoiceInputService service) async =>
      (await listenOnce(service)).onDevice;

  test('Android uses the standard recognizer, not the strict on-device one', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(await onDeviceUsed(SpeechToTextVoiceInputService(speech: speech)), isFalse);
  });

  test('iOS asks for on-device recognition first', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(await onDeviceUsed(SpeechToTextVoiceInputService(speech: speech)), isTrue);
  });

  test('Android starts listening without waiting for the locale list', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    // The plugin can leave this call unanswered on Android 13+.
    when(() => speech.locales()).thenAnswer((_) => Completer<List<LocaleName>>().future);

    final options = await listenOnce(SpeechToTextVoiceInputService(
      speech: speech,
      deviceLocales: () => const [Locale('es', 'CO'), Locale('en', 'US')],
    ));

    expect(options.localeId, 'es_CO');
    verifyNever(() => speech.locales());
  });

  test('Android without a matching phone language uses the default region', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final options = await listenOnce(SpeechToTextVoiceInputService(
      speech: speech,
      deviceLocales: () => const [Locale('en', 'US')],
    ));

    expect(options.localeId, 'es_ES');
  });

  test('iOS does not hang when the locale list never arrives', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    when(() => speech.locales()).thenAnswer((_) => Completer<List<LocaleName>>().future);

    final options = await listenOnce(SpeechToTextVoiceInputService(
      speech: speech,
      deviceLocales: () => const [Locale('es', 'MX')],
    )).timeout(const Duration(seconds: 4));

    expect(options.localeId, 'es_MX');
  });

  test('Android commands wait for the recognizer, not a 3 s silence timer', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final options = await listenOnce(SpeechToTextVoiceInputService(speech: speech));

    expect(options.pauseFor, isNull);
  });
}
