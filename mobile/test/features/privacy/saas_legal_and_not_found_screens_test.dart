import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/presentation/screens/not_found_screen.dart';
import 'package:dualis_mobile/features/privacy/presentation/screens/terms_of_service_screen.dart';
import 'package:dualis_mobile/features/privacy/presentation/screens/privacy_policy_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('NotFoundScreen (Anti-Vibe-Coding Boring Pages Checklist)', () {
    testWidgets('renders branded 404 message and actionable home button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(const NotFoundScreen(uri: '/invalid-clinical-route')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ERRO 404'), findsOneWidget);
      expect(find.text('Página Não Encontrada'), findsOneWidget);
      expect(find.text('/invalid-clinical-route'), findsOneWidget);
      expect(find.byKey(const Key('not_found_home_button')), findsOneWidget);
    });
  });

  group('TermsOfServiceScreen (SaaS Legal Requirement 2)', () {
    testWidgets('renders complete contract with entity, CDC 7-day refund, and SaMD limits',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const TermsOfServiceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Termos de Uso do SaaS'), findsOneWidget);
      expect(find.textContaining('DualisCheckUp Saúde e Tecnologia Ltda.'), findsWidgets);
      expect(find.textContaining('48.291.834/0001-92'), findsOneWidget);

      // Verify refund policy (CDC Art. 49)
      expect(find.textContaining('Direito de Arrependimento (CDC Art. 49)'), findsOneWidget);

      // Verify clinical disclaimer (Anvisa / CFM)
      expect(find.textContaining('RDC Anvisa nº 657/2022'), findsOneWidget);
    });
  });

  group('PrivacyPolicyScreen (SaaS Legal Requirement 3, 4, 5)', () {
    testWidgets('renders LGPD Art. 11, DPO email, PCI zero-card storage, and 72h breach plan',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Política de Privacidade (LGPD)'), findsOneWidget);
      expect(find.textContaining('dpo@dualischeckup.com'), findsWidgets);
      expect(find.textContaining('Artigo 11 da LGPD'), findsOneWidget);

      // Verify PCI-DSS payment tokenization without card storage
      expect(find.textContaining('Zero Armazenamento'), findsOneWidget);

      // Verify 72-hour breach notification plan (LGPD Art. 48)
      expect(find.textContaining('Plano de Notificação em até 72h'), findsOneWidget);

      // Verify shortcut button to Privacy Center
      expect(find.text('Ir para a Central de Privacidade'), findsOneWidget);
    });
  });
}
