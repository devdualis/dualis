import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/emotional_trend_chart.dart';

void main() {
  group('EmotionalTrendChart Widget Tests (DASH-03)', () {
    testWidgets('1. Renders empty state when data list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmotionalTrendChart(data: []),
          ),
        ),
      );

      expect(find.text('Sem registros emocionais nesta semana'), findsOneWidget);
    });

    testWidgets('2. Renders chart and dimension legend when data is present', (tester) async {
      final data = [
        const EmotionalDayData(
          date: '2026-09-08',
          dimensions: {'estresse_burnout': 3, 'ansiosa_agitacao': 2},
        ),
        const EmotionalDayData(
          date: '2026-09-09',
          dimensions: {'estresse_burnout': 4, 'ansiosa_agitacao': 1},
        ),
        const EmotionalDayData(
          date: '2026-09-10',
          dimensions: {'estresse_burnout': 2, 'ansiosa_agitacao': 3},
        ),
      ];

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmotionalTrendChart(data: data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evolução Emocional (Últimos 7 Dias)'), findsOneWidget);
      expect(find.text('Estresse / Burnout'), findsOneWidget);
      expect(find.text('Ansiedade'), findsOneWidget);
    });
  });
}
