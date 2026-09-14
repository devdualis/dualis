import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/admob_banner_container.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/wellness_confirmation_dialog.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createTriggerCheckInTestApp({
  void Function(TriageVertical vertical)? onTriageNavigated,
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.triage,
        builder: (context, state) {
          final vertical = state.extra as TriageVertical? ?? TriageVertical.psicoEmocional;
          if (onTriageNavigated != null) {
            onTriageNavigated(vertical);
          }
          return Scaffold(
            body: Center(child: Text('Triage Screen: ${vertical.name}')),
          );
        },
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('Screen 3: Unified Dual-Axis Trigger Check-in (RF-001 / TRG-01) Widget Tests', () {
    testWidgets('1. Displays dual-axis question and starts with CTA disabled',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTriggerCheckInTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Como você está se sentindo hoje?'), findsOneWidget);
      expect(find.text('1. Eixo Psico-Emocional'), findsOneWidget);
      expect(find.text('2. Eixo Avaliação Física'), findsOneWidget);

      final ctaFinder = find.byKey(const Key('startTriageButton'));
      expect(ctaFinder, findsOneWidget);
      expect(find.text('Selecione os Dois Eixos'), findsOneWidget);

      final button = tester.widget<FilledButton>(find.descendant(
        of: ctaFinder,
        matching: find.byType(FilledButton),
      ));
      expect(button.onPressed, isNull);
    });

    testWidgets('2. Case 1: Both [Bem / Normal] shows immediate Wellness Confirmation Dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTriggerCheckInTestApp());
      await tester.pumpAndSettle();

      // Tap Bem/Normal on emotional axis
      await tester.tap(find.byKey(const Key('emotional_goodNormal')));
      await tester.pumpAndSettle();

      // Tap Bem/Normal on physical axis
      await tester.tap(find.byKey(const Key('physical_goodNormal')));
      await tester.pumpAndSettle();

      // CTA is now active
      expect(find.text('Confirmar Check-in'), findsOneWidget);
      await tester.tap(find.byKey(const Key('startTriageButton')));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.byType(WellnessConfirmationDialog), findsOneWidget);
      expect(find.text('Tudo Bem por Aqui!'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Concluir Check-in'));
      await tester.pumpAndSettle();

      expect(find.byType(WellnessConfirmationDialog), findsNothing);
    });

    testWidgets('3. Case 2: Only Psico-Emocional distressed routes to emotional triage',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TriageVertical? navigatedVertical;

      await tester.pumpWidget(createTriggerCheckInTestApp(
        onTriageNavigated: (v) => navigatedVertical = v,
      ));
      await tester.pumpAndSettle();

      // Emotional: Mais ou menos
      await tester.tap(find.byKey(const Key('emotional_soSo')));
      await tester.pumpAndSettle();

      // Physical: Bem / Normal
      await tester.tap(find.byKey(const Key('physical_goodNormal')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('startTriageButton')));
      await tester.pumpAndSettle();

      expect(find.text('Triage Screen: psicoEmocional'), findsOneWidget);
      expect(navigatedVertical, equals(TriageVertical.psicoEmocional));
    });

    testWidgets('4. Case 3: Only Física distressed routes to physical triage',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TriageVertical? navigatedVertical;

      await tester.pumpWidget(createTriggerCheckInTestApp(
        onTriageNavigated: (v) => navigatedVertical = v,
      ));
      await tester.pumpAndSettle();

      // Emotional: Bem / Normal
      await tester.tap(find.byKey(const Key('emotional_goodNormal')));
      await tester.pumpAndSettle();

      // Physical: Mal / Ruim
      await tester.tap(find.byKey(const Key('physical_badSick')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('startTriageButton')));
      await tester.pumpAndSettle();

      expect(find.text('Triage Screen: fisica'), findsOneWidget);
      expect(navigatedVertical, equals(TriageVertical.fisica));
    });

    testWidgets('5. Case 4: BOTH axes distressed enforces Organic Primacy (Physical first)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TriageVertical? navigatedVertical;

      await tester.pumpWidget(createTriggerCheckInTestApp(
        onTriageNavigated: (v) => navigatedVertical = v,
      ));
      await tester.pumpAndSettle();

      // Emotional: Mal / Ruim
      await tester.tap(find.byKey(const Key('emotional_badSick')));
      await tester.pumpAndSettle();

      // Physical: Mais ou menos
      await tester.tap(find.byKey(const Key('physical_soSo')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('startTriageButton')));
      await tester.pumpAndSettle();

      // Must enforce Organic Primacy: Physical starts first!
      expect(find.text('Triage Screen: fisica'), findsOneWidget);
      expect(navigatedVertical, equals(TriageVertical.fisica));
    });

    testWidgets('6. Natural language input and suggestion chips update text field',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTriggerCheckInTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dor de cabeça'));
      await tester.pumpAndSettle();

      expect(find.text('Dor de cabeça'), findsWidgets);

      await tester.tap(find.text('Cansaço excessivo'));
      await tester.pumpAndSettle();

      expect(find.text('Dor de cabeça, Cansaço excessivo'), findsOneWidget);
    });

    testWidgets('7. Renders privacy-safe local AdMob banner container (AD-01)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTriggerCheckInTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(AdMobBannerContainer), findsOneWidget);
      expect(find.text('Parceiro Local • Zero rastreamento clínico'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget);
    });
  });
}
