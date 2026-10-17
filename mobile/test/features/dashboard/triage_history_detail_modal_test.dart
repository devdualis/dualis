import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/retrospective_list_view.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/triage_history_detail_modal.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

void main() {
  group('TriageHistoryDetailModal & History Item Click Widget Tests', () {
    testWidgets('1. Tapping a historical record opens modal with symptoms, time, intensity and narrative', (tester) async {
      final entries = [
        TriageHistoryEntry(
          id: 'log-modal-1',
          intensity: 4,
          anatomicalSystem: 'coluna_dorsal',
          emotionalDimension: null,
          narrative: 'Dor aguda na região lombar após esforço físico intenso no treino.',
          stepAnswers: {
            '1': 'comecou_hoje',
            '3': 'sim_carregou_peso',
            'causes': 'carregamento de peso excessivo',
          },
          recordedAt: DateTime.parse('2026-09-15T14:30:00.000Z'),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RetrospectiveListView(
                entries: entries,
                verticalFilter: 'physical',
              ),
            ),
          ),
        ),
      );

      // Verify item card is displayed with key
      final itemCard = find.byKey(const Key('history_item_log-modal-1'));
      expect(itemCard, findsOneWidget);

      // Tap on the item card to open modal
      await tester.tap(itemCard);
      await tester.pumpAndSettle();

      // Verify modal is open
      expect(find.byKey(const Key('triage_history_detail_modal')), findsOneWidget);
      expect(find.text('Detalhes do registro'), findsOneWidget);

      // Verify Category & Vertical
      expect(find.text('AVALIAÇÃO FÍSICA'), findsOneWidget);
      expect(find.byKey(const Key('modal_category_badge')), findsOneWidget);
      expect(find.text('COSTAS'), findsWidgets);

      // Verify Level (Nível 4)
      expect(find.byKey(const Key('modal_intensity_badge')), findsOneWidget);
      expect(find.text('Intensidade informada: 4/5'), findsWidgets);
      // No care recommendation or clinical reasoning in the journal entry.
      expect(find.byKey(const Key('modal_disposition_badge')), findsNothing);
      expect(find.text('Pronto Atendimento'), findsNothing);
      expect(find.textContaining('Primazia Orgânica'), findsNothing);

      // Verify Symptoms & Step answers
      expect(find.text('Começou hoje'), findsOneWidget);
      expect(find.text('Carregamento de peso excessivo'), findsWidgets);

      // Verify Additional Description (Relato do Paciente)
      final narrativeWidget = tester.widget<Text>(find.byKey(const Key('modal_narrative_text')));
      expect(narrativeWidget.data, contains('Dor aguda na região lombar após esforço físico intenso'));

      // Verify Close Button dismisses the modal
      final closeButton = find.byKey(const Key('modal_close_button'));
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('triage_history_detail_modal')), findsNothing);
    });

    testWidgets('2. Modal displays emotional dimension and daily check-in axes correctly', (tester) async {
      final entries = [
        TriageHistoryEntry(
          id: 'log-checkin-1',
          intensity: 2,
          anatomicalSystem: null,
          emotionalDimension: 'estresse_burnout',
          narrative: 'Sobrecarga de prazos de entrega esta semana.',
          stepAnswers: {
            'type': 'daily_checkin',
            'emotionalStatus': 'soSo',
            'physicalStatus': 'goodNormal',
          },
          recordedAt: DateTime.parse('2026-09-16T09:15:00.000Z'),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RetrospectiveListView(
                entries: entries,
                verticalFilter: 'emotional',
              ),
            ),
          ),
        ),
      );

      final itemCard = find.byKey(const Key('history_item_log-checkin-1'));
      expect(itemCard, findsOneWidget);

      await tester.tap(itemCard);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('triage_history_detail_modal')), findsOneWidget);
      expect(find.text('AUTOAVALIAÇÃO EMOCIONAL'), findsOneWidget);
      expect(find.text('ESTRESSADO(A) OU ESGOTADO(A)'), findsWidgets);
      expect(find.text('Intensidade informada: 2/5'), findsWidgets);

      // Verify Daily Check-In axes
      expect(find.text('Eixo Psico-Emocional'), findsOneWidget);
      expect(find.text('Mais ou menos'), findsOneWidget);
      expect(find.text('Eixo Avaliação Física'), findsOneWidget);
      expect(find.text('Bem / Normal'), findsOneWidget);

      // Verify narrative within modal
      final checkInNarrativeWidget = tester.widget<Text>(find.byKey(const Key('modal_narrative_text')));
      expect(checkInNarrativeWidget.data, contains('Sobrecarga de prazos'));

      // Tap bottom 'Fechar' button to dismiss
      final dismissButton = find.byKey(const Key('modal_dismiss_button'));
      expect(dismissButton, findsOneWidget);
      await tester.tap(dismissButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('triage_history_detail_modal')), findsNothing);
    });

    testWidgets('3. Modal handles empty narrative gracefully', (tester) async {
      final entry = TriageHistoryEntry(
        id: 'log-no-narrative',
        intensity: 3,
        anatomicalSystem: 'respiratorio',
        narrative: null,
        stepAnswers: null,
        recordedAt: DateTime.parse('2026-09-17T11:00:00.000Z'),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TriageHistoryDetailModal.show(context, entry),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('triage_history_detail_modal')), findsOneWidget);
      expect(find.byKey(const Key('modal_category_badge')), findsOneWidget);
      expect(find.text('RESPIRAÇÃO'), findsWidgets);
      expect(find.text('Intensidade informada: 3/5'), findsOneWidget);
      expect(
        find.text('Você não adicionou uma descrição neste registro.'),
        findsOneWidget,
      );
    });

    testWidgets('4. Bug Regression: Numeric intensity in step 3 is NOT displayed as Fator Associado / Sintoma, and step 2 factor is formatted', (tester) async {
      final entryWithNumericStep3 = TriageHistoryEntry(
        id: 'log-numeric-step3',
        intensity: 2,
        anatomicalSystem: 'neurologico',
        narrative: null,
        stepAnswers: {
          '0': 'neurologico',
          '1': 'comecou_agora',
          '2': 'sim_levantar_rapido',
          '3': '2', // Intensity 2! Must NOT be shown as symptom / factor
        },
        recordedAt: DateTime.parse('2026-09-25T12:00:00.000Z'),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TriageHistoryDetailModal.show(context, entryWithNumericStep3),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // "2" should NEVER appear as the value of "Fator Associado / Sintoma"
      expect(find.text('Fator Associado / Sintoma'), findsOneWidget);
      expect(find.text('Ao levantar rápido / postural'), findsOneWidget);
      expect(find.widgetWithText(Row, '2'), findsNothing);

      // Now verify if only step '3': '2' exists without step 2:
      // It should NOT show Fator Associado / Sintoma at all
    });

    testWidgets('5. Bug Regression: Numeric narrative string (e.g. "5") is rejected and shows default empty message', (tester) async {
      final entryWithNumericNarrative = TriageHistoryEntry(
        id: 'log-numeric-narrative',
        intensity: 5,
        anatomicalSystem: 'cabeca_pescoco',
        narrative: '5', // Leaked intensity/number instead of actual description
        stepAnswers: {
          '0': 'cabeca_pescoco',
          '1': 'comecou_agora',
          '2': 'sim_telas_esforco_visual',
          'naturalLanguageText': '5',
        },
        recordedAt: DateTime.parse('2026-09-25T12:00:00.000Z'),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TriageHistoryDetailModal.show(context, entryWithNumericNarrative),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // The narrative should NOT display "5"
      expect(find.text('5'), findsNothing);
      expect(
        find.text('Você não adicionou uma descrição neste registro.'),
        findsOneWidget,
      );
    });

    testWidgets('6. Emotional entry with a physical cross-tag is shown as emotional (vertical field)', (tester) async {
      final entry = TriageHistoryEntry(
        id: 'log-cross-tag',
        intensity: 3,
        anatomicalSystem: 'cabeca_pescoco',
        emotionalDimension: 'ansiosa_agitacao',
        vertical: 'emotional',
        recordedAt: DateTime.parse('2026-09-25T12:00:00.000Z'),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TriageHistoryDetailModal.show(context, entry),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('AUTOAVALIAÇÃO EMOCIONAL'), findsOneWidget);
      expect(find.text('AVALIAÇÃO FÍSICA'), findsNothing);
    });
  });
}
