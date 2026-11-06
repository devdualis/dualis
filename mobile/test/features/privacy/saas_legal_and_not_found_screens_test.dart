import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/presentation/screens/not_found_screen.dart';
import 'package:dualis_mobile/features/privacy/presentation/screens/terms_of_service_screen.dart';
import 'package:dualis_mobile/features/privacy/presentation/screens/privacy_policy_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createTestApp(Widget child, {Locale locale = const Locale('pt', 'BR')}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
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
    testWidgets('renders complete contract with entity, CDC 7-day refund, and wellness intended use',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const TermsOfServiceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Termos de Uso do SaaS'), findsOneWidget);
      expect(find.textContaining('WGI (Brothers Baum Ltda.)'), findsWidgets);
      expect(find.textContaining('30.889.282/0001-90'), findsOneWidget);

      // Verify refund policy (CDC Art. 49)
      expect(find.textContaining('Direito de Arrependimento (CDC Art. 49)'), findsOneWidget);

      // Verify section 2 "Natureza do Serviço" carries the intended-use statement (plan §1.1)
      expect(find.text('2. Natureza do Serviço'), findsOneWidget);
      expect(find.textContaining('não é um dispositivo médico'), findsOneWidget);

      // No medical-device or triage claims (L-01, L-02)
      for (final banned in ['RDC', 'CFM', 'SaMD', 'estratificação', 'triagem']) {
        expect(find.textContaining(banned), findsNothing, reason: banned);
      }
    });
  });

  group('PrivacyPolicyScreen (SaaS Legal Requirement 3, 4, 5)', () {
    testWidgets('renders LGPD Art. 11, DPO email, AI for diary chips, zero-card storage, and 72h breach plan',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Política de Privacidade (LGPD)'), findsOneWidget);
      expect(find.textContaining('contato@dualischeckup.com'), findsWidgets);
      expect(find.textContaining('Artigo 11 da LGPD'), findsOneWidget);

      expect(find.textContaining('diário de bem-estar'), findsWidgets);
      expect(find.textContaining('Inteligência artificial: '), findsOneWidget);
      expect(find.textContaining('opção já existente do diário'), findsWidgets);
      expect(find.textContaining('LGPD Art. 33'), findsOneWidget);
      expect(find.textContaining('provedor de reconhecimento de texto'), findsOneWidget);
      expect(find.textContaining('provedor de e-mail'), findsOneWidget);
      expect(find.textContaining('LGPD Art. 18, VII'), findsOneWidget);
      for (final provider in ['Google', 'Gemini', 'Vision', 'Resend']) {
        expect(find.textContaining(provider), findsNothing, reason: provider);
      }

      // Card data never stored; unverified PCI-DSS claim removed (L-07)
      expect(find.textContaining('Zero Armazenamento'), findsOneWidget);
      expect(find.textContaining('PCI-DSS'), findsNothing);

      // Verify 72-hour breach notification plan (LGPD Art. 48)
      expect(find.textContaining('Plano de Notificação em até 72h'), findsOneWidget);

      // Verify shortcut button to Privacy Center
      expect(find.text('Ir para a Central de Privacidade'), findsOneWidget);
    });
  });

  group('PrivacyPolicyScreen section 8: AI journal suggestions', () {
    const locales = {
      'pt': Locale('pt', 'BR'),
      'es': Locale('es'),
      'en': Locale('en'),
    };

    for (final entry in locales.entries) {
      testWidgets('${entry.key}: section 8 follows section 7 with the API facts and no brand names',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1000, 6000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          createTestApp(const PrivacyPolicyScreen(), locale: entry.value),
        );
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(entry.value);

        final title8 = find.text(l10n.privacyPolicySection8Title);
        final title7 = find.text(l10n.privacyPolicySection7Title);
        expect(title8, findsOneWidget);
        expect(tester.getTopLeft(title8).dy, greaterThan(tester.getTopLeft(title7).dy));
        expect(find.text(l10n.privacyPolicySection8Body), findsOneWidget);
        for (final bullet in [
          l10n.privacyPolicySection8Bullet1,
          l10n.privacyPolicySection8Bullet2,
          l10n.privacyPolicySection8Bullet3,
          l10n.privacyPolicySection8Bullet4,
          l10n.privacyPolicySection8Bullet5,
          l10n.privacyPolicySection8Bullet6,
        ]) {
          expect(find.textContaining(bullet), findsOneWidget, reason: bullet);
        }
        expect(find.textContaining('Art. 11, I'), findsWidgets);
        expect(find.textContaining('São Paulo'), findsWidgets);

        for (final brand in ['Google', 'Gemini', 'Vertex']) {
          expect(find.textContaining(brand), findsNothing, reason: brand);
        }
      });
    }

    test('section 3 AI bullet names both features and the specific consent', () {
      final pt = lookupAppLocalizations(const Locale('pt'));
      expect(pt.privacyPolicySection3Bullet1, contains('escrever o meu'));
      expect(pt.privacyPolicySection3Bullet1, contains('descrever com minhas palavras'));
      expect(pt.privacyPolicySection3Bullet1, contains('consentimento específico'));
      final es = lookupAppLocalizations(const Locale('es'));
      expect(es.privacyPolicySection3Bullet1, contains('describir con mis palabras'));
      expect(es.privacyPolicySection3Bullet1, contains('consentimiento específico'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(en.privacyPolicySection3Bullet1, contains('describe in my own words'));
      expect(en.privacyPolicySection3Bullet1, contains('specific consent'));
    });

    test('section 8 texts carry no provider brand in any language', () {
      for (final locale in locales.values) {
        final l = lookupAppLocalizations(locale);
        final texts = [
          l.privacyPolicySection3Bullet1,
          l.privacyPolicySection8Title,
          l.privacyPolicySection8Body,
          l.privacyPolicySection8Bullet1,
          l.privacyPolicySection8Bullet2,
          l.privacyPolicySection8Bullet3,
          l.privacyPolicySection8Bullet4,
          l.privacyPolicySection8Bullet5,
          l.privacyPolicySection8Bullet6,
        ];
        for (final t in texts) {
          expect(t, isNot(matches(RegExp('Google|Gemini|Vertex'))), reason: t);
        }
      }
    });

    test('AI copy never says the text is not stored; it says what is kept (WR-06)', () {
      final never = RegExp(
        r'não fica guardado nos|not stored on|no se guarda en (los|nuestros) servidores|not kept on our servers',
      );
      final kept = {
        'pt': RegExp(r'"escrever o meu".*"Guardar este texto como nota".*guardado no seu registro do diário'),
        'es': RegExp(r'"escribir el mío".*"Guardar este texto como nota".*se guarda en su registro del diario'),
        'en': RegExp(r'"Write my own".*"Keep this text as a note".*saved in your journal entry'),
      };
      for (final entry in locales.entries) {
        final l = lookupAppLocalizations(entry.value);
        final code = entry.value.languageCode;
        for (final t in [l.privacyPolicySection8Bullet3, l.privacyPolicySection8Bullet6, l.aiConsentNoTraining]) {
          expect(t, isNot(matches(never)), reason: t);
        }
        expect(l.privacyPolicySection8Bullet6, matches(kept[code]!), reason: code);
        expect(l.aiConsentNoTraining, contains(l.jv2WriteMine), reason: code);
      }
    });

    test('describe-flow copy resolves in pt, es and en', () {
      final pt = lookupAppLocalizations(const Locale('pt'));
      expect(pt.jv2DescribeTile, 'Descrever com minhas palavras');
      expect(pt.jv2DescribeOffline,
          'Sem conexão. Seu texto não foi enviado; siga pelas telas normais.');
      for (final locale in locales.values) {
        final l = lookupAppLocalizations(locale);
        final texts = [
          l.jv2DescribeTile,
          l.jv2DescribeTitle,
          l.jv2DescribeHint,
          l.jv2DescribeKeepNote,
          l.jv2DescribeSuggest,
          l.jv2DescribeSearching,
          l.jv2DescribeReviewTitle,
          l.jv2DescribeReviewHint,
          l.jv2DescribeUse,
          l.jv2DescribeManual,
          l.jv2DescribeEmpty,
          l.jv2DescribeOffline,
          l.jv2DescribeFailed,
          l.jv2DescribeBusy,
          l.jv2DescribeProfileNotAllowed,
          l.jv2DescribeCancel,
        ];
        expect(texts.toSet(), hasLength(16), reason: '$locale');
        for (final t in texts) {
          expect(t.trim(), isNotEmpty);
        }
      }
    });
  });
}
