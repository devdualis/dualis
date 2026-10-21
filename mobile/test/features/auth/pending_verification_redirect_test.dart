import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  testWidgets(
      'Reopening the app with an unverified registration lands on the verification screen',
      (tester) async {
    final storage = MockSecureStorageService();
    when(() => storage.getAccessToken()).thenAnswer((_) async => null);
    when(() => storage.getUserProfile()).thenAnswer((_) async => null);
    when(() => storage.getPendingVerificationEmail())
        .thenAnswer((_) async => 'maria@dualis.test');

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        secureStorageServiceProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(appRouterProvider),
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(find.text('m***a@dualis.test'), findsOneWidget);
    expect(find.text('Não recebeu o código? Reenviar'), findsOneWidget);
  });
}
