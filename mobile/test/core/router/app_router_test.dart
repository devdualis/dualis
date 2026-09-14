import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/locale_provider.dart';
import 'package:dualis_mobile/shared/widgets/dualis_primary_button.dart';
import 'package:dualis_mobile/shared/widgets/dualis_text_field.dart';

Widget createRouterTestApp({String initialLocation = RoutePaths.onboarding}) {
  final router = createRouter(initialLocation: initialLocation);

  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(localeProvider);
        return MaterialApp.router(
          routerConfig: router,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    ),
  );
}

void main() {
  group('RoutePaths Constants', () {
    test('declares correct route string constants', () {
      expect(RoutePaths.onboarding, equals('/onboarding'));
      expect(RoutePaths.register, equals('/register'));
      expect(RoutePaths.login, equals('/login'));
      expect(RoutePaths.home, equals('/home'));
    });
  });

  group('AppRouter Declarative Navigation', () {
    testWidgets('initial location defaults to /onboarding',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRouterTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('DualisCheckUp'), findsOneWidget);
    });

    testWidgets('navigates directly to /register',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createRouterTestApp(initialLocation: RoutePaths.register),
      );
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });

    testWidgets('navigates directly to /login',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createRouterTestApp(initialLocation: RoutePaths.login),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('navigates directly to /home',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createRouterTestApp(initialLocation: RoutePaths.home),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });
  });

  group('Reusable Shared UI Widgets', () {
    testWidgets('DualisPrimaryButton executes callback and respects loading state',
        (WidgetTester tester) async {
      var tapped = false;

      // Normal active state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DualisPrimaryButton(
              text: 'Avançar',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Avançar'), findsOneWidget);
      await tester.tap(find.text('Avançar'));
      await tester.pump();
      expect(tapped, isTrue);

      // Loading state: shows spinner and ignores taps
      tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DualisPrimaryButton(
              text: 'Avançar',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Avançar'), findsNothing);
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('DualisTextField renders label and captures text input',
        (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DualisTextField(
              labelText: 'Nome Completo',
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nome Completo'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Dr. Carlos Silva');
      await tester.pump();

      expect(controller.text, equals('Dr. Carlos Silva'));
    });
  });
}
