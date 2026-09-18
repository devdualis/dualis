import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/retrospective_list_view.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/triage_history_detail_modal.dart';

void main() {
  group('TriageHistoryDetailModal & History Item Click Widget Tests', () {
    testWidgets('1. Tapping a historical record opens modal with symptoms, time, level, disposition and narrative', (tester) async {
      final entries = [
        TriageHistoryEntry(
          id: 'log-modal-1',
          intensity: 4,
          anatomicalSystem: 'coluna_dorsal',
          emotionalDimension: null,
          disposition: 'pronto_atendimento',
          narrative: 'Dor aguda na região lombar após esforço físico intenso no treino.',
          organicPrimacyApplied: true,
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
      expect(find.text('Detalhes da Triagem'), findsOneWidget);

      // Verify Category & Vertical
      expect(find.text('AVALIAÇÃO FÍSICA'), findsOneWidget);
      expect(find.byKey(const Key('modal_category_badge')), findsOneWidget);
      expect(find.text('COLUNA DORSAL'), findsWidgets);

      // Verify Level (Nível 4)
      expect(find.byKey(const Key('modal_intensity_badge')), findsOneWidget);
      expect(find.text('Nível 4 - Severo / Urgente'), findsOneWidget);

      // Verify Disposition (Pronto Atendimento)
      expect(find.byKey(const Key('modal_disposition_badge')), findsOneWidget);
      expect(find.text('Pronto Atendimento'), findsWidgets);

      // Verify Organic Primacy Banner
      expect(find.textContaining('Primazia Orgânica'), findsOneWidget);

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
          disposition: 'auto_cuidado',
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
      expect(find.text('ESTRESSE / BURNOUT'), findsWidgets);
      expect(find.text('Nível 2 - Leve'), findsOneWidget);
      expect(find.text('Autocuidado'), findsWidgets);

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
        disposition: 'consulta_rotina',
        narrative: null,
        stepAnswers: null,
        recordedAt: DateTime.parse('2026-09-17T11:00:00.000Z'),
      );

      await tester.pumpWidget(
        MaterialApp(
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
      expect(find.text('RESPIRATÓRIO'), findsWidgets);
      expect(find.text('Nível 3 - Moderado'), findsOneWidget);
      expect(find.byKey(const Key('modal_disposition_badge')), findsOneWidget);
      expect(find.text('Consulta de Rotina'), findsOneWidget);
      expect(
        find.text('Nenhuma descrição adicional relatada pelo paciente nesta triagem.'),
        findsOneWidget,
      );
    });
  });
}
