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
      expect(find.text('Normal / Me sinto bem'), findsOneWidget);
      expect(find.byType(TriageOptionChip), findsNWidgets(8));
    });

    testWidgets('2. Renders "Iniciando Autoavaliação Física" banner on fisica vertical',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.fisica,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Iniciando Autoavaliação Física'), findsOneWidget);
      expect(find.text('Passo 1 de 5'), findsOneWidget);
      expect(find.text('Normal / Me sinto bem'), findsOneWidget);
      expect(find.text('Cabeça e Pescoço'), findsOneWidget);
      expect(find.byType(TriageOptionChip), findsNWidgets(13));
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

    testWidgets('7. Step 4 in Physical vertical renders TriageIntensitySelector',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.fisica,
      ));
      await tester.pumpAndSettle();

      final colunaChip = find.text('Coluna e Dor Dorsal');
      await tester.ensureVisible(colunaChip);
      await tester.pumpAndSettle();
      await tester.tap(colunaChip);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Começou agora'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      // Step 2 is Trigger
      await tester.tap(find.text('Pegou peso ou fez esforço lombar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 4 de 5'), findsOneWidget);
      expect(find.byType(TriageIntensitySelector), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('8. Reaching Step 5 displays TriagePreviewCard, narrative input, and "Confirmar e Finalizar" button',
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

      final anxietyTriggerChip = find.text('Sobrecarga de tarefas, prazos ou expectativas');
      await tester.ensureVisible(anxietyTriggerChip);
      await tester.tap(anxietyTriggerChip);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leve e controlável'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 5 de 5'), findsOneWidget);
      expect(find.byType(TriagePreviewCard), findsOneWidget);
      expect(find.byKey(const Key('triageOptionalNarrativeInput')), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Confirmar e Finalizar'), findsOneWidget);
    });

    testWidgets('9. Step 3 in Physical vertical renders gastrointestinal trigger question when gastrointestinal is selected',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.fisica,
      ));
      await tester.pumpAndSettle();

      final gastroChip = find.text('Gastrointestinal / Abdômen');
      await tester.ensureVisible(gastroChip);
      await tester.tap(gastroChip);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Começou agora'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      // Step 3 of 5 (Trigger / Gatilho)
      expect(find.text('Passo 3 de 5'), findsOneWidget);
      expect(
        find.text('Você ingeriu algum alimento diferente ou pesado, tomou remédios recentes ou ficou muito tempo em jejum?'),
        findsOneWidget,
      );
      expect(find.text('Alimento diferente, pesado ou suspeito'), findsOneWidget);
      expect(find.text('Uso recente de medicamento ou anti-inflamatório'), findsOneWidget);
      expect(find.text('Longo período de jejum ou estresse intenso'), findsOneWidget);
      expect(find.text('Não, começou sem relação com alimentação'), findsOneWidget);

      // Verify the generic exercise / fall options are NOT present
      expect(find.text('Sim, exercício intenso'), findsNothing);
      expect(find.text('Sim, sofri uma queda'), findsNothing);
    });

    testWidgets('10. Step 3 in Emotional vertical renders specialized sleep trigger question when Sono is selected',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();

      final sonoChip = find.text('Sono (Insônia / Hipersônia)');
      await tester.ensureVisible(sonoChip);
      await tester.tap(sonoChip);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Começou hoje'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      // Step 3 of 5 (Trigger / Gatilho for Sleep)
      expect(find.text('Passo 3 de 5'), findsOneWidget);
      expect(
        find.text('Qual tem sido a principal dificuldade que atrapalha suas noites de sono?'),
        findsOneWidget,
      );
      expect(find.text('Cabeça acelerada / pensamentos na hora de dormir'), findsOneWidget);
      expect(find.text('Acordar no meio da noite e não conseguir voltar a dormir'), findsOneWidget);
      expect(find.text('Sono leve, agitado, com pesadelos ou despertares'), findsOneWidget);
      expect(find.text('Uso de celular/telas até tarde ou horários irregulares'), findsOneWidget);
      expect(find.text('Não sei identificar, surgiu de repente'), findsOneWidget);

      // Verify generic emotional options are NOT present
      expect(find.text('Trabalho / Estudos'), findsNothing);
      expect(find.text('Família / Relacionamentos'), findsNothing);
    });

    testWidgets('11. Selecting Normal as first option shows "Concluir como Normal / Bem" CTA',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();

      final normalChip = find.text('Normal / Me sinto bem');
      expect(normalChip, findsOneWidget);
      await tester.tap(normalChip);
      await tester.pumpAndSettle();

      final completeButton = find.widgetWithText(FilledButton, 'Concluir como Normal / Bem');
      expect(completeButton, findsOneWidget);
      final filledBtn = tester.widget<FilledButton>(completeButton);
      expect(filledBtn.onPressed, isNotNull);
    });
  });
}
