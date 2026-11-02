import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/security/biometric_lock_controller.dart';
import 'package:dualis_mobile/core/security/biometric_service.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/settings/presentation/widgets/biometric_lock_tile.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class MockBiometricService extends Mock implements BiometricService {}

class FakeLockStorage extends SecureStorageService {
  bool biometricEnabled = false;

  @override
  Future<bool> isBiometricEnabled() async => biometricEnabled;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    biometricEnabled = enabled;
  }

  // A stored session, so a saved "on" is not dropped as stale.
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => 'refresh-token';
}

class SignedInAuth extends AuthController {
  @override
  AuthState build() => const AuthState(isAuthenticated: true);
}

void main() {
  late MockBiometricService biometrics;
  late FakeLockStorage storage;

  setUp(() {
    biometrics = MockBiometricService();
    storage = FakeLockStorage();
    when(() => biometrics.isHardwareSupported()).thenAnswer((_) async => true);
  });

  Future<void> pumpTile(WidgetTester tester, {required bool premium}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumProfilesEnabledProvider.overrideWithValue(premium),
          biometricServiceProvider.overrideWithValue(biometrics),
          secureStorageServiceProvider.overrideWithValue(storage),
          authControllerProvider.overrideWith(SignedInAuth.new),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: BiometricLockTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final toggle = find.byKey(const Key('settings_biometric_lock_switch'));

  testWidgets('hidden on Free builds and never checks the device', (
    tester,
  ) async {
    await pumpTile(tester, premium: false);

    expect(toggle, findsNothing);
    verifyNever(() => biometrics.isHardwareSupported());
  });

  testWidgets('hidden on Premium when the device cannot do it', (tester) async {
    when(() => biometrics.isHardwareSupported()).thenAnswer((_) async => false);
    await pumpTile(tester, premium: true);

    expect(toggle, findsNothing);
  });

  testWidgets('shown on Premium, off by default', (tester) async {
    await pumpTile(tester, premium: true);

    expect(toggle, findsOneWidget);
    expect(find.text('Desbloquear com biometria'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
  });

  testWidgets('turning on needs a successful check first', (tester) async {
    when(
      () => biometrics.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    ).thenAnswer((_) async => false);
    await pumpTile(tester, premium: true);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(storage.biometricEnabled, isFalse);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(
      find.text(
        'Não foi possível confirmar. O desbloqueio com biometria continua desativado.',
      ),
      findsOneWidget,
    );

    when(
      () => biometrics.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    ).thenAnswer((_) async => true);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(storage.biometricEnabled, isTrue);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(find.text('Desbloqueio com biometria ativado.'), findsOneWidget);
  });

  testWidgets('turning off clears the saved setting', (tester) async {
    storage.biometricEnabled = true;
    await pumpTile(tester, premium: true);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(storage.biometricEnabled, isFalse);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    verifyNever(
      () => biometrics.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    );
  });
}
