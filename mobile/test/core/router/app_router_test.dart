import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/presentation/screens/not_found_screen.dart';
import 'package:dualis_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:dualis_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:dualis_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/features/privacy/presentation/screens/terms_of_service_screen.dart';
import 'package:dualis_mobile/features/privacy/presentation/screens/privacy_policy_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/locale_provider.dart';
import 'package:dualis_mobile/shared/widgets/dualis_primary_button.dart';
import 'package:dualis_mobile/shared/widgets/dualis_text_field.dart';
import 'package:dualis_mobile/shared/widgets/dualis_logo.dart';

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
      expect(RoutePaths.termsOfService, equals('/terms-of-service'));
      expect(RoutePaths.privacyPolicy, equals('/privacy-policy'));
      expect(RoutePaths.notFound, equals('/404'));
    });
  });

  group('AppRouter Declarative Navigation', () {
    testWidgets('initial location defaults to /onboarding',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRouterTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(DualisLogo), findsOneWidget);
    });

    testWidgets('navigates directly to /register',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createRouterTestApp(initialLocation: RoutePaths.register),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('navigates directly to /login',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createRouterTestApp(initialLocation: RoutePaths.login),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('navigates directly to /home',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createRouterTestApp(initialLocation: RoutePaths.home),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('navigates to Terms of Service screen (SaaS Legal Requirement)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createRouterTestApp(initialLocation: RoutePaths.termsOfService),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TermsOfServiceScreen), findsOneWidget);
      expect(find.text('Termos de Uso do SaaS'), findsOneWidget);
    });

    testWidgets('navigates to Privacy Policy screen (LGPD SaaS Requirement)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createRouterTestApp(initialLocation: RoutePaths.privacyPolicy),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('Política de Privacidade (LGPD)'), findsOneWidget);
    });

    testWidgets('renders custom NotFoundScreen for nonexistent routes (Video 1 Anti-Vibe Coding)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createRouterTestApp(initialLocation: '/nonexistent-random-route'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('ERRO 404'), findsOneWidget);
      expect(find.text('Página Não Encontrada'), findsOneWidget);
      expect(find.byKey(const Key('not_found_home_button')), findsOneWidget);
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
