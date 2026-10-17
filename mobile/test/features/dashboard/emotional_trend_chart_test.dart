import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/emotional_trend_chart.dart';

void main() {
  group('EmotionalTrendChart Widget Tests (DASH-03)', () {
    for (final width in [375.0, 390.0, 430.0]) {
      testWidgets(
        'legend wraps compactly with accessible touch targets at $width px',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: EmotionalTrendChart(
                    data: [
                      EmotionalDayData(
                        date: '2026-10-17',
                        dimensions: {'ansiosa_agitacao': 2},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          const labels = [
            'Ansiedade',
            'Desânimo',
            'Estresse',
            'Tensão no corpo',
            'Sono',
            'Foco / Atenção',
            'Autoestima',
          ];
          final firstChip = find.widgetWithText(InkWell, labels.first);
          final secondChip = find.widgetWithText(InkWell, labels[1]);
          final firstRect = tester.getRect(firstChip);
          final secondRect = tester.getRect(secondChip);

          // Phone layouts must put multiple chips on a row instead of
          // allocating the entire available width to each touch target.
          expect(secondRect.top, firstRect.top);
          expect(secondRect.left, greaterThan(firstRect.right));

          for (final label in labels) {
            final chip = find.widgetWithText(InkWell, label);
            expect(chip, findsOneWidget);
            final rect = tester.getRect(chip);
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(16));
            expect(rect.right, lessThanOrEqualTo(width - 16));
          }
          expect(tester.takeException(), isNull);

          expect(
            tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData,
            hasLength(1),
          );
          // The padding above the visible pill remains tappable.
          await tester.tapAt(firstRect.topCenter + const Offset(0, 2));
          await tester.pumpAndSettle();
          expect(
            tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData,
            isEmpty,
          );
          await tester.tap(firstChip);
          await tester.pumpAndSettle();
          expect(
            tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData,
            hasLength(1),
          );
        },
      );
    }

    testWidgets('1. Renders empty state when data list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EmotionalTrendChart(data: []))),
      );

      expect(
        find.text('Sem registros emocionais nesta semana'),
        findsOneWidget,
      );
    });

    testWidgets('2. Renders chart and dimension legend when data is present', (
      tester,
    ) async {
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
            body: SingleChildScrollView(child: EmotionalTrendChart(data: data)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evolução Emocional (Últimos 7 Dias)'), findsOneWidget);
      expect(find.text('Estresse'), findsOneWidget);
      expect(find.text('Ansiedade'), findsOneWidget);
    });
  });
}
