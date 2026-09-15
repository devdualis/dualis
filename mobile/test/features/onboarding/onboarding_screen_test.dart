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

    // Brand and Shield Emblem Header
    expect(find.byType(DualisLogo), findsOneWidget);
    expect(find.byType(DualisEmblem), findsOneWidget);
    expect(find.textContaining('Dualis'), findsWidgets);
    expect(find.textContaining('CheckUp'), findsWidgets);

    // Initial Card 1
    expect(find.text('Triagem Preventiva Unificada'), findsOneWidget);
    expect(
      find.text(
        'Conecte sua saúde física e estado psico-emocional em um único fluxo diário inteligente, garantindo cuidado holístico e sem ruídos.',
      ),
      findsOneWidget,
    );

    // Primary and Secondary CTAs
    expect(find.text('Criar Conta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    // Page indicator
    expect(find.byType(AnimatedPageIndicator), findsOneWidget);
  });

  testWidgets('Swiping carousel advances through 3 value proposition cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // Verify Card 1
    expect(find.text('Triagem Preventiva Unificada'), findsOneWidget);

    // Swipe to Card 2
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Registros Médicos Blindados'), findsOneWidget);
    expect(
      find.text(
        'Seu histórico clínico protegido por criptografia AES-256 e custodiado sob os mais rigorosos padrões da LGPD. Você é o único dono dos seus dados.',
      ),
      findsOneWidget,
    );

    // Swipe to Card 3
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Orientações Preventivas Precisas'), findsOneWidget);
    expect(
      find.text(
        'Recomendações e artigos de especialistas médicos renomados sem diagnósticos falsos ou alarmismos desnecessários.',
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
