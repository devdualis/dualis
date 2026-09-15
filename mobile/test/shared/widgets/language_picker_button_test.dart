import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/locale_provider.dart';
import 'package:dualis_mobile/shared/widgets/language_picker_button.dart';

Widget createTestApp() {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(localeProvider);
        return MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(
              actions: const [LanguagePickerButton()],
            ),
            body: Consumer(
              builder: (context, ref, _) {
                final l10n = AppLocalizations.of(context);
                return Center(
                  child: Text(l10n.screen1PrimaryCta),
                );
              },
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets(
      'Dynamic language toggle updates strings to Spanish and English immediately',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // Default: Portuguese
    expect(find.text('Criar Conta'), findsOneWidget);

    // Switch to Spanish
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🇪🇸  Español'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Cuenta'), findsOneWidget);

    // Switch to English
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🇺🇸  English'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
  });
}
