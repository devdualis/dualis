import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/consent/data/ai_consent_repository.dart';
import 'package:dualis_mobile/features/consent/presentation/ai_consent_controller.dart';
import 'package:dualis_mobile/features/consent/presentation/ai_consent_widgets.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

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

/// Settings' fake storage plus delete, for the device decline flag.
class _Storage extends FakeSecureStorageService {
  @override
  Future<void> delete({required String key}) async => values.remove(key);
}

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: true,
    user: _user,
    accessToken: 'mock-jwt-token',
  );
}

const _declineKey = 'dualis_ai_consent_declined_2026.1';
const _errorText = 'Não foi possível salvar agora. Tente de novo.';
const _unavailableText =
    'Sem conexão. As sugestões com IA ficam para depois; siga normalmente.';

/// A screen with one button that runs [ensureAiConsent] and keeps the
/// results.
class _GateHarness {
  _GateHarness(this.consent, {this.ask = AiConsentAsk.always});

  final FakeAiConsentRepository consent;
  final AiConsentAsk ask;
  final storage = _Storage();
  final results = <bool>[];
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    _tallView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiConsentRepositoryProvider.overrideWithValue(consent),
          secureStorageServiceProvider.overrideWithValue(storage),
          authControllerProvider.overrideWith(_Auth.new),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          locale: const Locale('pt', 'BR'),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return Center(
                  child: FilledButton(
                    key: const Key('run_gate'),
                    onPressed: () async {
                      results.add(
                        await ensureAiConsent(context, ref, ask: ask),
                      );
                    },
                    child: const Text('Sugerir'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> run(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('run_gate')));
    await tester.pumpAndSettle();
  }
}

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

Finder _textContaining(String part) =>
    find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains(part));

void main() {
  group('AI consent from Settings', () {
    testWidgets(
      'the tile is off; the dialog names provider, region and no training; Permitir records the server version',
      (tester) async {
        final consent = FakeAiConsentRepository();
        await _pumpSettings(tester, consent);

        expect(
          find.byKey(const Key('settings_ai_consent_tile')),
          findsOneWidget,
        );
        expect(find.text('Sugestões com IA no diário'), findsOneWidget);
        expect(
          find.text('Desligado. Nenhum texto é enviado à IA.'),
          findsOneWidget,
        );
        expect(_switchValue(tester), isFalse);

        await tester.tap(_switch);
        await tester.pumpAndSettle();

        expect(_dialog, findsOneWidget);
        expect(
          _textContaining('Google (Vertex AI, modelo Gemini)'),
          findsOneWidget,
        );
        expect(
          _textContaining('São Paulo (southamerica-east1)'),
          findsOneWidget,
        );
        expect(_textContaining('números longos, como CPF'), findsOneWidget);
        expect(_textContaining('nem o usa para treinar modelos'), findsOneWidget);
        // Honest about what stays: the person's own words they choose to keep.
        expect(_textContaining('No seu diário fica só o que você escolher manter'), findsOneWidget);
        expect(_textContaining('não fica guardado'), findsNothing);
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
      expect(
        find.text('Desligado. Nenhum texto é enviado à IA.'),
        findsOneWidget,
      );
    });
  });

  group('Revoke, failures and version changes', () {
    testWidgets('turning the tile off asks first, then revokes on the server', (
      tester,
    ) async {
      final consent = FakeAiConsentRepository(granted: true);
      await _pumpSettings(tester, consent);
      expect(_switchValue(tester), isTrue);
      expect(find.text('Permitido em 05/11/2026'), findsOneWidget);

      await tester.tap(_switch);
      await tester.pumpAndSettle();
      expect(find.text('Desligar as sugestões com IA?'), findsOneWidget);
      expect(consent.calls, isNot(contains('revoke')));

      await tester.tap(find.byKey(const Key('ai_consent_revoke_confirm')));
      await tester.pumpAndSettle();

      expect(consent.calls, contains('revoke'));
      expect(_switchValue(tester), isFalse);
      expect(
        find.text('Desligado. Nenhum texto é enviado à IA.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'a failing grant shows a calm message and leaves the tile off',
      (tester) async {
        final consent = FakeAiConsentRepository();
        await _pumpSettings(tester, consent);
        consent.fail = true;

        await tester.tap(_switch);
        await tester.pumpAndSettle();
        await tester.tap(_accept);
        await tester.pumpAndSettle();

        expect(find.text(_errorText), findsOneWidget);
        expect(_switchValue(tester), isFalse);
        expect(consent.granted, isFalse);
      },
    );

    testWidgets(
      'a failing revoke shows a calm message and leaves the tile on',
      (tester) async {
        final consent = FakeAiConsentRepository(granted: true);
        await _pumpSettings(tester, consent);
        consent.fail = true;

        await tester.tap(_switch);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('ai_consent_revoke_confirm')));
        await tester.pumpAndSettle();

        expect(find.text(_errorText), findsOneWidget);
        expect(_switchValue(tester), isTrue);
        expect(find.text('Permitido em 05/11/2026'), findsOneWidget);
      },
    );

    testWidgets(
      'a version change refreshes the status and asks again; the second accept grants the new version',
      (tester) async {
        final consent = FakeAiConsentRepository(mismatchOnce: true);
        await _pumpSettings(tester, consent);

        await tester.tap(_switch);
        await tester.pumpAndSettle();
        await tester.tap(_accept);
        await tester.pumpAndSettle();

        // The first grant was refused; the status was read again and the
        // dialog is back.
        expect(consent.calls, containsAllInOrder(['grant:2026.1', 'status']));
        expect(_dialog, findsOneWidget);
        expect(consent.granted, isFalse);

        await tester.tap(_accept);
        await tester.pumpAndSettle();

        expect(consent.calls.last, 'grant:2026.2');
        expect(_switchValue(tester), isTrue);
      },
    );
  });

  group('ensureAiConsent', () {
    testWidgets(
      'ask: always with consent granted returns true with no dialog',
      (tester) async {
        final gate = _GateHarness(FakeAiConsentRepository(granted: true));
        await gate.pump(tester);

        await gate.run(tester);

        expect(_dialog, findsNothing);
        expect(gate.results, [true]);
        expect(gate.consent.calls.where((c) => c.startsWith('grant')), isEmpty);
      },
    );

    testWidgets(
      'ask: always without consent asks; accept is true, decline is false',
      (tester) async {
        final gate = _GateHarness(FakeAiConsentRepository());
        await gate.pump(tester);

        await gate.run(tester);
        expect(_dialog, findsOneWidget);
        await tester.tap(_decline);
        await tester.pumpAndSettle();
        expect(gate.results, [false]);
        expect(gate.consent.calls.where((c) => c.startsWith('grant')), isEmpty);
        // "always" does not remember the decline.
        expect(gate.storage.values.containsKey(_declineKey), isFalse);

        await gate.run(tester);
        expect(_dialog, findsOneWidget);
        await tester.tap(_accept);
        await tester.pumpAndSettle();
        expect(gate.results, [false, true]);
        expect(gate.consent.calls, contains('grant:2026.1'));
      },
    );

    testWidgets(
      'ask: unlessDeclined asks once; a decline is kept for this version; a later grant from Settings opens the gate',
      (tester) async {
        final gate = _GateHarness(
          FakeAiConsentRepository(),
          ask: AiConsentAsk.unlessDeclined,
        );
        await gate.pump(tester);

        await gate.run(tester);
        expect(_dialog, findsOneWidget);
        await tester.tap(_decline);
        await tester.pumpAndSettle();
        expect(gate.results, [false]);
        expect(gate.storage.values[_declineKey], 'yes');

        await gate.run(tester);
        expect(_dialog, findsNothing);
        expect(gate.results, [false, false]);

        // The person turns it on from Settings.
        final ok =
            await gate.container
                .read(aiConsentControllerProvider.notifier)
                .grant();
        await tester.pumpAndSettle();
        expect(ok, isTrue);
        expect(gate.storage.values.containsKey(_declineKey), isFalse);

        await gate.run(tester);
        expect(_dialog, findsNothing);
        expect(gate.results, [false, false, true]);
        expect(gate.consent.calls.where((c) => c.startsWith('grant')), [
          'grant:2026.1',
        ]);
      },
    );

    testWidgets(
      'offline: the status cannot be read, so it returns false with a calm message',
      (tester) async {
        final gate = _GateHarness(FakeAiConsentRepository(fail: true));
        await gate.pump(tester);

        await gate.run(tester);

        expect(_dialog, findsNothing);
        expect(gate.results, [false]);
        expect(find.text(_unavailableText), findsOneWidget);
      },
    );
  });
}
