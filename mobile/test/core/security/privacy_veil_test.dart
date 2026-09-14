import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dualis_mobile/core/security/biometric_service.dart';
import 'package:dualis_mobile/shared/widgets/privacy_veil_overlay.dart';

class MockBiometricService extends Mock implements BiometricService {}

void main() {
  late MockBiometricService mockBiometricService;

  setUp(() {
    mockBiometricService = MockBiometricService();
  });

  Widget createVeilTestApp({bool initialLocked = false}) {
    return MaterialApp(
      home: Scaffold(
        body: PrivacyVeilOverlay(
          biometricService: mockBiometricService,
          initialLocked: initialLocked,
          child: const Center(
            child: Text('Confidential Health Records (Patient 101)'),
          ),
        ),
      ),
    );
  }

  group('PrivacyVeilOverlay & AppLifecycleObserver Tests (AUTH-02 & T-02-07)', () {
    testWidgets(
        'Child content is visible initially and privacy veil is not displayed',
        (WidgetTester tester) async {
      await tester.pumpWidget(createVeilTestApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Confidential Health Records (Patient 101)'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('privacyVeilBackdrop')), findsNothing);
      expect(find.text('Dados de Saúde Protegidos'), findsNothing);
    });

    testWidgets(
        'Transitions to paused state triggers 25px Gaussian blur PrivacyVeilOverlay',
        (WidgetTester tester) async {
      await tester.pumpWidget(createVeilTestApp());
      await tester.pumpAndSettle();

      // Trigger app backgrounding (paused state) via AppLifecycleObserver
      final veilState =
          tester.state<PrivacyVeilOverlayState>(find.byType(PrivacyVeilOverlay));
      veilState.lifecycleObserver
          .didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      // Verify privacy veil is mounted and obscuring content
      expect(find.byKey(const Key('privacyVeilBackdrop')), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Dados de Saúde Protegidos'), findsOneWidget);
      expect(
        find.text('Autentique-se com biometria ou senha para acessar seu prontuário.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('privacyVeilUnlockButton')), findsOneWidget);
    });

    testWidgets(
        'Failed biometric authentication keeps privacy veil active upon resume',
        (WidgetTester tester) async {
      when(() => mockBiometricService.authenticate(
            localizedReason: any(named: 'localizedReason'),
          )).thenAnswer((_) async => false);

      await tester.pumpWidget(createVeilTestApp(initialLocked: true));
      await tester.pumpAndSettle();

      // Veiled initially
      expect(find.byKey(const Key('privacyVeilBackdrop')), findsOneWidget);

      // Simulate resume via AppLifecycleObserver
      final veilState =
          tester.state<PrivacyVeilOverlayState>(find.byType(PrivacyVeilOverlay));
      veilState.lifecycleObserver
          .didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Attempt unlock with failed auth
      final unlockBtn = find.byKey(const Key('privacyVeilUnlockButton'));
      await tester.tap(unlockBtn);
      await tester.pumpAndSettle();

      // Veil must remain visible
      expect(find.byKey(const Key('privacyVeilBackdrop')), findsOneWidget);
      expect(find.text('Dados de Saúde Protegidos'), findsOneWidget);
    });

    testWidgets(
        'Successful biometric authentication lifts the privacy veil and restores health view',
        (WidgetTester tester) async {
      when(() => mockBiometricService.authenticate(
            localizedReason: any(named: 'localizedReason'),
          )).thenAnswer((_) async => true);

      await tester.pumpWidget(createVeilTestApp(initialLocked: true));
      await tester.pumpAndSettle();

      // Verify locked
      expect(find.byKey(const Key('privacyVeilBackdrop')), findsOneWidget);

      // Attempt unlock with successful auth
      final unlockBtn = find.byKey(const Key('privacyVeilUnlockButton'));
      await tester.tap(unlockBtn);
      await tester.pumpAndSettle();

      // Veil is lifted
      expect(find.byKey(const Key('privacyVeilBackdrop')), findsNothing);
      expect(
        find.text('Confidential Health Records (Patient 101)'),
        findsOneWidget,
      );
    });
  });
}
