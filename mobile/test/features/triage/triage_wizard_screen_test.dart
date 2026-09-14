import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dualis_mobile/features/triage/data/antiburla_remote_data_source.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/features/triage/presentation/screens/triage_wizard_screen.dart';
import 'package:dualis_mobile/features/triage/presentation/widgets/triage_intensity_selector.dart';
import 'package:dualis_mobile/features/triage/presentation/widgets/triage_option_chip.dart';
import 'package:dualis_mobile/features/triage/presentation/widgets/triage_preview_card.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class FakeAntiburlaRemoteDataSource extends AntiburlaRemoteDataSource {
  final AntiburlaCheckResult result;

  FakeAntiburlaRemoteDataSource({
    this.result = const AntiburlaCheckResult(triggered: false),
  });

  @override
  Future<AntiburlaCheckResult> checkConsistency({
    required String vertical,
    required String category,
    required String selectedPersistence,
    String? narrative,
    String? token,
  }) async {
    return result;
  }
}

Widget createTriageTestWidget({
  TriageVertical vertical = TriageVertical.psicoEmocional,
  AntiburlaRemoteDataSource? antiburlaDataSource,
}) {
  return ProviderScope(
    overrides: [
      antiburlaDataSourceProvider.overrideWithValue(
        antiburlaDataSource ?? FakeAntiburlaRemoteDataSource(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      home: TriageWizardScreen(vertical: vertical),
    ),
  );
}

void main() {
  group('TriageWizardScreen Widget Tests', () {
    testWidgets('1. Renders "Iniciando Autoavaliação Psico-Emocional" banner on psicoEmocional vertical',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Iniciando Autoavaliação Psico-Emocional'), findsOneWidget);
      expect(find.text('Passo 1 de 5'), findsOneWidget);
      expect(find.byType(TriageOptionChip), findsNWidgets(7));
    });

    testWidgets('2. Renders "Iniciando Autoavaliação Física" banner on fisica vertical',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.fisica,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Iniciando Autoavaliação Física'), findsOneWidget);
      expect(find.text('Passo 1 de 5'), findsOneWidget);
      expect(find.text('Cabeça e Pescoço'), findsOneWidget);
      expect(find.byType(TriageOptionChip), findsNWidgets(12));
    });

    testWidgets('3. "Próximo" button starts disabled when no option is selected',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();

      final nextButton = find.widgetWithText(FilledButton, 'Próximo');
      expect(nextButton, findsOneWidget);

      final filledButton = tester.widget<FilledButton>(nextButton);
      expect(filledButton.onPressed, isNull);
    });

    testWidgets('4. Tapping an option chip enables the "Próximo" button',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ansiosa / Agitação'));
      await tester.pumpAndSettle();

      final nextButton = find.widgetWithText(FilledButton, 'Próximo');
      final filledButton = tester.widget<FilledButton>(nextButton);
      expect(filledButton.onPressed, isNotNull);
    });

    testWidgets('5. Tapping "Próximo" advances to Step 2', (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ansiosa / Agitação'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 2 de 5'), findsOneWidget);
      expect(find.text('Começou hoje'), findsOneWidget);
    });

    testWidgets('6. Tapping back arrow at Step 2 returns to Step 1', (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ansiosa / Agitação'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();
      expect(find.text('Passo 2 de 5'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Passo 1 de 5'), findsOneWidget);
      expect(find.text('Ansiosa / Agitação'), findsOneWidget);
    });

    testWidgets('7. Step 3 in Physical vertical renders TriageIntensitySelector',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.fisica,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Coluna e Dor Dorsal'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Começou agora'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 3 de 5'), findsOneWidget);
      expect(find.byType(TriageIntensitySelector), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('8. Reaching Step 5 displays TriagePreviewCard and "Confirmar e Finalizar" button',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ansiosa / Agitação'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Começou hoje'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leve e controlável'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trabalho / Estudos'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 5 de 5'), findsOneWidget);
      expect(find.byType(TriagePreviewCard), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Confirmar e Finalizar'), findsOneWidget);
    });
  });
}
