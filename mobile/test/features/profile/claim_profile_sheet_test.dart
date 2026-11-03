import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/features/profile/presentation/widgets/claim_profile_sheet.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/shared/widgets/urgent_help_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _claimed = Profile(
  id: 'claimed',
  name: 'Enzo Silva',
  profileType: ProfileType.primary,
  ownership: ProfileOwnership.own,
  accessLevel: ProfileAccessLevel.owner,
);

class _FakeController extends ActiveProfileController {
  _FakeController({this.error});

  final ProfileClaimError? error;
  final codes = <String>[];

  @override
  ActiveProfileState build() => const ActiveProfileState();

  @override
  Future<Profile> claimProfile(String code) async {
    codes.add(code);
    final reason = error;
    if (reason != null) {
      throw ProfileClaimException(reason, 'server message');
    }
    return _claimed;
  }
}

const _delegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// A host screen with a button that opens the claim sheet.
class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const ValueKey('open-claim'),
            onPressed: () => showClaimProfileSheet(context),
            child: const Text('open'),
          ),
        ),
      );
}

Future<void> _pump(WidgetTester tester, _FakeController fake) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        premiumProfilesEnabledProvider.overrideWithValue(false),
        activeProfileControllerProvider.overrideWith(() => fake),
      ],
      child: const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: _delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _Host(),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-claim')));
  await tester.pumpAndSettle();
}

Finder get _submit => find.byKey(const ValueKey('claim-code-submit'));
Finder get _field => find.byKey(const ValueKey('claim-code-field'));

void main() {
  testWidgets('empty code disables submit; a full code enables it',
      (tester) async {
    await _pump(tester, _FakeController());

    expect(find.text('Receber meu perfil'), findsOneWidget);
    expect(tester.widget<FilledButton>(_submit).onPressed, isNull);

    await tester.enterText(_field, 'abc');
    await tester.pump();
    expect(tester.widget<FilledButton>(_submit).onPressed, isNull);

    await tester.enterText(_field, 'handover01');
    await tester.pump();
    expect(tester.widget<FilledButton>(_submit).onPressed, isNotNull);
    expect(find.text('HANDOVER01'), findsOneWidget);
  });

  const messages = {
    ProfileClaimError.invalidCode: 'Código inválido ou expirado.',
    ProfileClaimError.byGuardian:
        'Este código deve ser usado na conta da pessoa que fez 18 anos.',
    ProfileClaimError.notAdult:
        'A transferência só é possível a partir dos 18 anos.',
    ProfileClaimError.accountHasData:
        'Esta conta já tem registros. Use uma conta nova para receber o perfil.',
    ProfileClaimError.tooManyAttempts:
        'Muitas tentativas. Tente de novo em alguns minutos.',
  };

  for (final MapEntry(key: reason, value: message) in messages.entries) {
    testWidgets('$reason shows its message and keeps the sheet open',
        (tester) async {
      final fake = _FakeController(error: reason);
      await _pump(tester, fake);

      await tester.enterText(_field, 'HANDOVER01');
      await tester.pump();
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(fake.codes, ['HANDOVER01']);
      final error = tester.widget<Text>(
          find.byKey(const ValueKey('claim-code-error')));
      expect(error.data, message);
      expect(_field, findsOneWidget);
    });
  }

  testWidgets('other errors show the generic message', (tester) async {
    await _pump(tester, _FakeController(error: ProfileClaimError.other));

    await tester.enterText(_field, 'HANDOVER01');
    await tester.pump();
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('claim-code-error')), findsOneWidget);
  });

  testWidgets('success pops the sheet and shows the success message',
      (tester) async {
    final fake = _FakeController();
    await _pump(tester, fake);

    await tester.enterText(_field, ' handover01 ');
    await tester.pump();
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(fake.codes, ['HANDOVER01']);
    expect(_field, findsNothing);
    expect(find.text('Perfil recebido. Agora ele é seu.'), findsOneWidget);
  });

  testWidgets('urgent help stays reachable while the claim sheet is open',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [GoRoute(path: '/', builder: (_, _) => const _Host())],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumProfilesEnabledProvider.overrideWithValue(false),
          activeProfileControllerProvider.overrideWith(_FakeController.new),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('pt'),
          localizationsDelegates: _delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Same wiring as main.dart's MaterialApp.builder.
          builder: (context, child) =>
              UrgentHelpOverlay(router: router, child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-claim')));
    await tester.pumpAndSettle();

    expect(_field, findsOneWidget);
    expect(find.byKey(const Key('urgent_help_button')), findsOneWidget);
    expect(find.byKey(const Key('urgent_help_button')).hitTestable(),
        findsOneWidget);
  });
}
