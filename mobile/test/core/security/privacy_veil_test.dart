import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/biometric_lock_controller.dart';
import 'package:dualis_mobile/core/security/biometric_service.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/shared/widgets/privacy_veil_overlay.dart';

class MockBiometricService extends Mock implements BiometricService {}

class FakeLockStorage extends SecureStorageService {
  bool biometricEnabled;
  bool hasSession = true;

  /// How many flag reads throw before one succeeds.
  int failingReads = 0;

  /// When set, the flag read waits for it (to look at the first frames).
  Completer<void>? readGate;

  FakeLockStorage({this.biometricEnabled = false});

  @override
  Future<bool> isBiometricEnabled() async {
    await readGate?.future;
    if (failingReads > 0) {
      failingReads--;
      throw Exception('keychain read failed');
    }
    return biometricEnabled;
  }

  @override
  Future<String?> getAccessToken() async => hasSession ? 'access' : null;

  @override
  Future<String?> getRefreshToken() async => hasSession ? 'refresh' : null;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    biometricEnabled = enabled;
  }

  @override
  Future<UserProfile?> getUserProfile() async => null;
}

class FakeAuthController extends AuthController {
  String? lastEmail;
  String? lastPassword;
  bool signedIn = true;
  bool loggedOut = false;
  String failureMessage = 'Credenciais inválidas';

  @override
  AuthState build() => AuthState(
    isAuthenticated: signedIn,
    user: UserProfile(
      id: 'user-1',
      name: 'Ana',
      email: 'ana@example.com',
      gender: Gender.feminino,
    ),
  );

  @override
  Future<bool> login({required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    if (password == 'right-password') return true;
    state = state.copyWith(errorMessage: failureMessage);
    return false;
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
    state = const AuthState();
  }
}

const _privateText = 'Private wellness entries (User 101)';
const _helpText = 'Help resources screen';
const _historyText = 'History screen (private)';

void main() {
  late MockBiometricService biometrics;
  late FakeLockStorage storage;
  late FakeAuthController auth;

  setUp(() {
    biometrics = MockBiometricService();
    when(() => biometrics.isHardwareSupported()).thenAnswer((_) async => true);
    when(
      () => biometrics.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    ).thenAnswer((_) async => false);
    storage = FakeLockStorage();
    auth = FakeAuthController();
  });

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    bool premium = true,
    bool settle = true,
  }) async {
    final router = GoRouter(
      initialLocation: RoutePaths.home,
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder:
              (_, __) =>
                  const Scaffold(body: Center(child: Text(_privateText))),
        ),
        GoRoute(
          path: RoutePaths.emergency,
          builder:
              (_, __) => const Scaffold(body: Center(child: Text(_helpText))),
        ),
        GoRoute(
          path: RoutePaths.history,
          builder:
              (_, __) =>
                  const Scaffold(body: Center(child: Text(_historyText))),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        premiumProfilesEnabledProvider.overrideWithValue(premium),
        biometricServiceProvider.overrideWithValue(biometrics),
        secureStorageServiceProvider.overrideWithValue(storage),
        authControllerProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder:
              (context, child) =>
                  PrivacyVeilOverlay(router: router, child: child!),
        ),
      ),
    );
    // The loading cover spins, so it never settles while the read waits.
    settle ? await tester.pumpAndSettle() : await tester.pump();
    return container;
  }

  final veil = find.byKey(const Key('privacyVeilBackdrop'));

  group('Biometric app lock (Premium)', () {
    testWidgets('Free build never locks or asks for biometrics', (
      tester,
    ) async {
      storage.biometricEnabled = true;
      await pumpApp(tester, premium: false);

      expect(veil, findsNothing);
      expect(find.text(_privateText), findsOneWidget);
      verifyNever(
        () => biometrics.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      );
    });

    testWidgets('setting off: no lock on cold start', (tester) async {
      await pumpApp(tester);

      expect(veil, findsNothing);
      expect(find.text(_privateText), findsOneWidget);
    });

    testWidgets('setting on: locks on cold start, hides content and asks for '
        'biometrics once by itself', (tester) async {
      storage.biometricEnabled = true;
      await pumpApp(tester);

      expect(veil, findsOneWidget);
      expect(find.text(_privateText), findsNothing);
      expect(find.text('Seus registros estão protegidos'), findsOneWidget);
      verify(
        () => biometrics.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).called(1);
    });

    testWidgets('no manual bypass: a failed check keeps the lock', (
      tester,
    ) async {
      storage.biometricEnabled = true;
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('privacyVeilUnlockButton')));
      await tester.pumpAndSettle();

      expect(veil, findsOneWidget);
      expect(find.byKey(const Key('privacyVeilFallbackButton')), findsNothing);
      expect(find.text('Desbloquear manualmente'), findsNothing);
      expect(find.text(_privateText), findsNothing);
    });

    testWidgets('retry button unlocks after a successful check', (
      tester,
    ) async {
      storage.biometricEnabled = true;
      await pumpApp(tester);
      when(
        () => biometrics.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => true);

      await tester.tap(find.byKey(const Key('privacyVeilUnlockButton')));
      await tester.pumpAndSettle();

      expect(veil, findsNothing);
      expect(find.text(_privateText), findsOneWidget);
    });

    testWidgets(
      'help button is on the lock screen, opens help while locked, and '
      'coming back shows the lock again',
      (tester) async {
        storage.biometricEnabled = true;
        await pumpApp(tester);

        final helpButton = find.byKey(const Key('urgent_help_button'));
        expect(helpButton, findsOneWidget);

        await tester.tap(helpButton);
        await tester.pumpAndSettle();

        expect(find.text(_helpText), findsOneWidget);
        expect(veil, findsNothing);

        final router = GoRouter.of(tester.element(find.text(_helpText)));
        router.pop();
        await tester.pumpAndSettle();

        expect(veil, findsOneWidget);
        expect(find.text(_privateText), findsNothing);
        // The automatic prompt is not repeated after visiting help.
        verify(
          () => biometrics.authenticate(
            localizedReason: any(named: 'localizedReason'),
          ),
        ).called(1);
      },
    );

    testWidgets('"Entrar com senha" checks the account password', (
      tester,
    ) async {
      storage.biometricEnabled = true;
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('bioLockPasswordButton')));
      await tester.pumpAndSettle();
      expect(find.text('ana@example.com'), findsOneWidget);

      // Wrong password: stays locked and explains.
      await tester.enterText(
        find.byKey(const Key('bioLockPasswordField')),
        'wrong',
      );
      await tester.tap(find.byKey(const Key('bioLockPasswordSubmit')));
      await tester.pumpAndSettle();
      expect(auth.lastEmail, 'ana@example.com');
      expect(find.byKey(const Key('bioLockPasswordError')), findsOneWidget);
      expect(veil, findsOneWidget);
      // Focus stays on the field for a second try (QA bug: it was lost).
      final field = tester.widget<TextField>(find.byKey(const Key('bioLockPasswordField')));
      expect(field.focusNode!.hasFocus, isTrue);

      // Right password: unlocks without logging out.
      await tester.enterText(
        find.byKey(const Key('bioLockPasswordField')),
        'right-password',
      );
      await tester.tap(find.byKey(const Key('bioLockPasswordSubmit')));
      await tester.pumpAndSettle();
      expect(auth.lastPassword, 'right-password');
      expect(veil, findsNothing);
      expect(find.text(_privateText), findsOneWidget);
    });

    testWidgets('empty password is not sent', (tester) async {
      storage.biometricEnabled = true;
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('bioLockPasswordButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bioLockPasswordSubmit')));
      await tester.pumpAndSettle();

      expect(auth.lastPassword, isNull);
      expect(find.text('Digite sua senha.'), findsOneWidget);
    });

    testWidgets('locks again only after 60 s or more in background (paused), '
        'never on inactive alone', (tester) async {
      storage.biometricEnabled = true;
      final container = await pumpApp(tester);
      when(
        () => biometrics.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => true);
      await tester.tap(find.byKey(const Key('privacyVeilUnlockButton')));
      await tester.pumpAndSettle();
      expect(veil, findsNothing);

      var now = DateTime(2026, 11, 2, 10);
      container.read(biometricLockControllerProvider.notifier).clock =
          () => now;

      // Notification shade / Face ID dialog: inactive only.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      now = now.add(const Duration(minutes: 5));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(veil, findsNothing);

      // Short trip to another app.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 59));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(veil, findsNothing);

      // A minute or more away.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 60));
      // Unlock succeeds on the automatic prompt; make it fail to see the lock.
      when(
        () => biometrics.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(veil, findsOneWidget);
      expect(find.text(_privateText), findsNothing);
    });

    testWidgets('logout clears the setting and removes the lock', (
      tester,
    ) async {
      storage.biometricEnabled = true;
      final container = await pumpApp(tester);
      expect(veil, findsOneWidget);

      auth.state = const AuthState();
      await tester.pumpAndSettle();

      expect(storage.biometricEnabled, isFalse);
      expect(container.read(biometricLockControllerProvider).enabled, isFalse);
      expect(veil, findsNothing);
    });

    testWidgets('cold start: covered while the setting loads, even before the '
        'session is restored', (tester) async {
      auth.signedIn = false;
      storage.readGate = Completer<void>();
      await pumpApp(tester, settle: false);

      expect(veil, findsOneWidget);
      expect(find.text(_privateText), findsNothing);
      expect(find.byKey(const Key('urgent_help_button')), findsOneWidget);

      storage.readGate!.complete();
      await tester.pumpAndSettle();
      expect(veil, findsNothing);
      expect(find.text(_privateText), findsOneWidget);
    });

    testWidgets('a failed read is retried once', (tester) async {
      storage
        ..biometricEnabled = true
        ..failingReads = 1;
      await pumpApp(tester);

      expect(veil, findsOneWidget);
      expect(storage.failingReads, 0);
    });

    testWidgets('fails closed when the setting cannot be read', (tester) async {
      storage.failingReads = 2;
      await pumpApp(tester);

      expect(veil, findsOneWidget);
      expect(find.text(_privateText), findsNothing);
      expect(find.byKey(const Key('privacyVeilUnlockButton')), findsOneWidget);
      expect(find.byKey(const Key('bioLockPasswordButton')), findsOneWidget);
      expect(find.byKey(const Key('bioLockSignOutButton')), findsOneWidget);
    });

    testWidgets('stale flag without a stored session: no lock, flag cleared', (
      tester,
    ) async {
      auth.signedIn = false;
      storage
        ..biometricEnabled = true
        ..hasSession = false;
      await pumpApp(tester);

      expect(veil, findsNothing);
      expect(find.text(_privateText), findsOneWidget);
      expect(storage.biometricEnabled, isFalse);
    });

    testWidgets('"Sair da conta" on the lock screen signs out after confirm', (
      tester,
    ) async {
      storage.biometricEnabled = true;
      final container = await pumpApp(tester);

      await tester.tap(find.byKey(const Key('bioLockSignOutButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bioLockSignOutConfirm')));
      await tester.pumpAndSettle();

      expect(auth.loggedOut, isTrue);
      expect(container.read(biometricLockControllerProvider).locked, isFalse);
      expect(veil, findsNothing);
    });

    testWidgets('offline password check points to the device passcode', (
      tester,
    ) async {
      storage.biometricEnabled = true;
      auth.failureMessage =
          'Não foi possível conectar ao servidor. Verifique sua conexão.';
      await pumpApp(tester);

      expect(
        find.text(
          'Use o rosto, a digital ou a senha do aparelho para ver seus registros.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('bioLockPasswordButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('bioLockPasswordField')),
        'any-password',
      );
      await tester.tap(find.byKey(const Key('bioLockPasswordSubmit')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Sem conexão, não dá para conferir a senha da conta agora. '
          'Use o rosto, a digital ou a senha do aparelho.',
        ),
        findsOneWidget,
      );
      expect(veil, findsOneWidget);
    });

    testWidgets(
      'Android back is swallowed while locked; on help it returns to the lock',
      (tester) async {
        storage.biometricEnabled = true;
        await pumpApp(tester);
        final router = GoRouter.of(
          tester.element(find.text(_privateText, skipOffstage: false)),
        );
        router.push(RoutePaths.history);
        await tester.pumpAndSettle();
        expect(veil, findsOneWidget);

        // Back while locked: the hidden screen stays.
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, RoutePaths.history);
        expect(veil, findsOneWidget);

        // Back on help: pops help and shows the lock again.
        await tester.tap(find.byKey(const Key('urgent_help_button')));
        await tester.pumpAndSettle();
        expect(find.text(_helpText), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, RoutePaths.history);
        expect(find.text(_helpText), findsNothing);
        expect(veil, findsOneWidget);

        // Unlocked: back pops as usual.
        when(
          () => biometrics.authenticate(
            localizedReason: any(named: 'localizedReason'),
          ),
        ).thenAnswer((_) async => true);
        await tester.tap(find.byKey(const Key('privacyVeilUnlockButton')));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, RoutePaths.home);
        expect(find.text(_privateText), findsOneWidget);
      },
    );

    final snapshotCover = find.byKey(const Key('privacyVeilSnapshotCover'));

    testWidgets(
      'app switcher: plain cover while inactive, gone on quick resume',
      (tester) async {
        storage.biometricEnabled = true;
        await pumpApp(tester);
        when(
          () => biometrics.authenticate(
            localizedReason: any(named: 'localizedReason'),
          ),
        ).thenAnswer((_) async => true);
        await tester.tap(find.byKey(const Key('privacyVeilUnlockButton')));
        await tester.pumpAndSettle();
        clearInteractions(biometrics);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        expect(snapshotCover, findsOneWidget);
        expect(find.text(_privateText), findsNothing);
        expect(veil, findsNothing);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(snapshotCover, findsNothing);
        expect(find.text(_privateText), findsOneWidget);
        verifyNever(
          () => biometrics.authenticate(
            localizedReason: any(named: 'localizedReason'),
          ),
        );
      },
    );

    testWidgets('app switcher: no cover when the lock is off', (tester) async {
      await pumpApp(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(snapshotCover, findsNothing);
      expect(find.text(_privateText), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    });
  });
}
