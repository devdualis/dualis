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

  Future<bool?> onDeviceUsed(SpeechToTextVoiceInputService service) async {
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
    return options.onDevice;
  }

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
}
