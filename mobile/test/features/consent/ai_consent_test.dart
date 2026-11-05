import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';

import '../settings/settings_screen_test.dart'
    show FakeAuthRepository, FakeSecureStorageService, createSettingsTestApp;
import 'fake_ai_consent_repository.dart';

const _user = UserProfile(
  id: 'usr-1234',
  name: 'Ricardo Rincon',
  email: 'ricardo@dualis.com.br',
  gender: Gender.masculino,
  dateOfBirth: '1990-05-15',
  picture: 'avatar_doctor',
);

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpSettings(
  WidgetTester tester,
  FakeAiConsentRepository consent, {
  FakeSecureStorageService? storage,
}) async {
  _tallView(tester);
  await tester.pumpWidget(
    createSettingsTestApp(
      repository: FakeAuthRepository(mockUser: _user),
      user: _user,
      storage: storage,
      aiConsent: consent,
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(_switch);
  await tester.pumpAndSettle();
}

final _switch = find.byKey(const Key('settings_ai_consent_switch'));
final _dialog = find.byKey(const Key('ai_consent_dialog'));
final _accept = find.byKey(const Key('ai_consent_accept'));
final _decline = find.byKey(const Key('ai_consent_decline'));

bool _switchValue(WidgetTester tester) =>
    tester.widget<SwitchListTile>(_switch).value;

Finder _textContaining(String part) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').contains(part),
);

void main() {
  group('AI consent from Settings', () {
    testWidgets(
      'the tile is off; the dialog names provider, region and no training; Permitir records the server version',
      (tester) async {
        final consent = FakeAiConsentRepository();
        await _pumpSettings(tester, consent);

        expect(find.byKey(const Key('settings_ai_consent_tile')), findsOneWidget);
        expect(find.text('Sugestões com IA no diário'), findsOneWidget);
        expect(find.text('Desligado. Nenhum texto é enviado à IA.'), findsOneWidget);
        expect(_switchValue(tester), isFalse);

        await tester.tap(_switch);
        await tester.pumpAndSettle();

        expect(_dialog, findsOneWidget);
        expect(_textContaining('Google (Vertex AI, modelo Gemini)'), findsOneWidget);
        expect(_textContaining('São Paulo (southamerica-east1)'), findsOneWidget);
        expect(_textContaining('nomes, CPF, e-mails'), findsOneWidget);
        expect(_textContaining('não é usado para treinar modelos'), findsOneWidget);
        expect(_textContaining('nada é marcado sem você'), findsOneWidget);
        expect(_textContaining('É opcional'), findsOneWidget);
        expect(_textContaining('LGPD, art. 11, I'), findsOneWidget);
        // Opening the dialog alone records nothing.
        expect(consent.calls.where((c) => c.startsWith('grant')), isEmpty);

        await tester.tap(_accept);
        await tester.pumpAndSettle();

        expect(_dialog, findsNothing);
        expect(consent.calls, contains('grant:2026.1'));
        expect(_switchValue(tester), isTrue);
        expect(find.text('Permitido em 05/11/2026'), findsOneWidget);
      },
    );

    testWidgets('"Agora não" sends no grant and the tile stays off', (
      tester,
    ) async {
      final consent = FakeAiConsentRepository();
      await _pumpSettings(tester, consent);

      await tester.tap(_switch);
      await tester.pumpAndSettle();
      await tester.tap(_decline);
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(consent.calls.where((c) => c.startsWith('grant')), isEmpty);
      expect(_switchValue(tester), isFalse);
      expect(find.text('Desligado. Nenhum texto é enviado à IA.'), findsOneWidget);
    });
  });
}
