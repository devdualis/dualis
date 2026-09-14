import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/features/triage/data/antiburla_remote_data_source.dart';
import 'package:dualis_mobile/features/triage/presentation/widgets/antiburla_verification_bottom_sheet.dart';

Widget _buildTestApp({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt')],
      locale: const Locale('pt'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Screen 5 Antiburla Verification Bottom Sheet Tests', () {
    testWidgets('renders UC-01 empathetic text and binary choice buttons', (tester) async {
      const result = AntiburlaCheckResult(
        triggered: true,
        daysAgo: 4,
        empatheticPrompt:
            'Você registrou um sintoma similar há 4 dias. É a mesma sensação que voltou ou algo totalmente novo?',
      );

      await tester.pumpWidget(_buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                AntiburlaVerificationBottomSheet.show(context, result: result);
              },
              child: const Text('Open Sheet'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Verificação Histórica'), findsOneWidget);
      expect(
        find.text(
            'Você registrou um sintoma similar há 4 dias. É a mesma sensação que voltou ou algo totalmente novo?'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('antiburla_recurring_button')), findsOneWidget);
      expect(find.byKey(const Key('antiburla_new_button')), findsOneWidget);
    });

    testWidgets('tapping recurring button returns AntiburlaUserChoice.recurring', (tester) async {
      AntiburlaUserChoice? selectedChoice;

      const result = AntiburlaCheckResult(
        triggered: true,
        daysAgo: 5,
      );

      await tester.pumpWidget(_buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                selectedChoice = await AntiburlaVerificationBottomSheet.show(
                  context,
                  result: result,
                );
              },
              child: const Text('Open Sheet'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('antiburla_recurring_button')));
      await tester.pumpAndSettle();

      expect(selectedChoice, equals(AntiburlaUserChoice.recurring));
      expect(find.byType(AntiburlaVerificationBottomSheet), findsNothing);
    });

    testWidgets('tapping new button returns AntiburlaUserChoice.newSymptom', (tester) async {
      AntiburlaUserChoice? selectedChoice;

      const result = AntiburlaCheckResult(
        triggered: true,
        daysAgo: 2,
      );

      await tester.pumpWidget(_buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                selectedChoice = await AntiburlaVerificationBottomSheet.show(
                  context,
                  result: result,
                );
              },
              child: const Text('Open Sheet'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('antiburla_new_button')));
      await tester.pumpAndSettle();

      expect(selectedChoice, equals(AntiburlaUserChoice.newSymptom));
      expect(find.byType(AntiburlaVerificationBottomSheet), findsNothing);
    });

    testWidgets('displays biological discordance notice when detected', (tester) async {
      const result = AntiburlaCheckResult(
        triggered: true,
        daysAgo: 3,
        biologicalDiscordance: true,
        biologicalNotice:
            'Aviso: Região anatômica masculina selecionada para perfil feminino.',
      );

      await tester.pumpWidget(_buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                AntiburlaVerificationBottomSheet.show(context, result: result);
              },
              child: const Text('Open Sheet'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Aviso: Região anatômica masculina selecionada para perfil feminino.'),
        findsOneWidget,
      );
    });
  });
}
