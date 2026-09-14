import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/anatomical_body_map.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/retrospective_list_view.dart';

void main() {
  group('AnatomicalBodyMap & RetrospectiveListView Widget Tests (DASH-02, DASH-04)', () {
    testWidgets('1. AnatomicalBodyMap renders silhouette canvas and legend bar', (tester) async {
      final summary = {
        'cabeca_pescoco': 4,
        'coluna_dorsal': 2,
        'cardiovascular_torax': 0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnatomicalBodyMap(physicalSummary: summary),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Sem dor'), findsOneWidget);
      expect(find.text('Leve (1-2)'), findsOneWidget);
      expect(find.text('Moderada (3)'), findsOneWidget);
      expect(find.text('Intensa (4-5)'), findsOneWidget);
    });

    testWidgets('2. Tapping on body map displays region details card', (tester) async {
      final summary = {
        'cabeca_pescoco': 4,
        'coluna_dorsal': 3,
      };

      String? tappedKey;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnatomicalBodyMap(
              physicalSummary: summary,
              onRegionSelected: (key) => tappedKey = key,
            ),
          ),
        ),
      );

      final gestureDetector = find.byKey(const Key('body_map_gesture_detector'));
      expect(gestureDetector, findsOneWidget);

      await tester.tap(gestureDetector);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_map_detail_card')), findsOneWidget);
      expect(tappedKey, isNotNull);
    });

    testWidgets('3. RetrospectiveListView renders entries with formatted date and category', (tester) async {
      final entries = [
        TriageHistoryEntry(
          id: 'log-1',
          intensity: 4,
          anatomicalSystem: 'coluna_dorsal',
          emotionalDimension: null,
          disposition: 'consulta_rotina',
          stepAnswers: {'causes': 'postura incorreta no trabalho'},
          recordedAt: DateTime.parse('2026-09-14T10:30:00.000Z'),
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

      expect(find.text('Nível 4'), findsOneWidget);
      expect(find.text('COLUNA DORSAL'), findsOneWidget);
      expect(find.text('Consulta de Rotina'), findsOneWidget);
      expect(find.textContaining('postura incorreta'), findsOneWidget);
    });

    testWidgets('4. RetrospectiveListView displays empty state when no records exist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RetrospectiveListView(
              entries: [],
              verticalFilter: 'physical',
            ),
          ),
        ),
      );

      expect(find.text('Nenhum registro anterior'), findsOneWidget);
      expect(find.text('Os seus check-ins diários concluídos aparecerão aqui.'), findsOneWidget);
    });
  });
}
