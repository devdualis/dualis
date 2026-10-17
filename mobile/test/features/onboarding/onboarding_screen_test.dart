import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:dualis_mobile/features/onboarding/presentation/widgets/animated_page_indicator.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/locale_provider.dart';
import 'package:dualis_mobile/shared/widgets/dualis_logo.dart';

Widget createTestApp() {
  final router = GoRouter(
    initialLocation: RoutePaths.onboarding,
    routes: [
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Register Screen Target')),
        ),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login Screen Target')),
        ),
      ),
    ],
  );

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
  testWidgets('Screen 1 renders brand header, initial card and CTAs in pt-BR',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // Brand Header (Official Dualis Logo per Brand Manual)
    expect(find.byType(DualisLogo), findsOneWidget);

    // Initial Card 1
    expect(find.text('Diário de Bem-Estar Integrado'), findsOneWidget);
    expect(
      find.text(
        'Registre como você está no corpo e nas emoções em um único check-in diário de 1 minuto.',
      ),
      findsOneWidget,
    );

    // Primary and Secondary CTAs
    expect(find.text('Criar Conta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    // Page indicator
    expect(find.byType(AnimatedPageIndicator), findsOneWidget);

    // Intended-use statement: wellness app, not a medical device
    expect(
      find.text(
        'O DualisCheckUp é um aplicativo de bem-estar e autoconhecimento. Não é um dispositivo médico e não substitui um profissional de saúde.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Swiping carousel advances through 3 value proposition cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // Verify Card 1
    expect(find.text('Diário de Bem-Estar Integrado'), findsOneWidget);

    // Swipe to Card 2
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Seus Dados Protegidos'), findsOneWidget);
    expect(
      find.text(
        'Seus registros de bem-estar ficam criptografados e sob seu controle, conforme a LGPD.',
      ),
      findsOneWidget,
    );

    // Swipe to Card 3
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conteúdos para Hábitos Saudáveis'), findsOneWidget);
    expect(
      find.text(
        'Leituras curtas e gerais sobre sono, estresse, postura, hidratação e mais.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Tapping "Criar Conta" pushes /register route',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final registerBtn = find.byKey(const Key('onboarding_register_button'));
    expect(registerBtn, findsOneWidget);

    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    expect(find.text('Register Screen Target'), findsOneWidget);
  });

  testWidgets('Tapping "Entrar" pushes /login route',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final loginBtn = find.byKey(const Key('onboarding_login_button'));
    expect(loginBtn, findsOneWidget);

    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(find.text('Login Screen Target'), findsOneWidget);
  });

  testWidgets('Language picker button is not displayed on onboarding screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.language), findsNothing);
  });
}
