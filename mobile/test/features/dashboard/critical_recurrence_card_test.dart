import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/critical_recurrence_card.dart';

void main() {
  group('CriticalRecurrenceCard Widget Tests (DASH-04)', () {
    testWidgets('1. Renders title, description, and frequency badge', (tester) async {
      const item = CriticalRecurrenceItem(
        id: 'rec-1',
        vertical: 'emotional',
        category: 'estresse_burnout',
        categoryLabel: 'Estresse / Burnout',
        title: 'Foco de Atenção: Estresse / Burnout',
        description:
            'Identificamos que a sua dimensão Estresse esteve em nível 4 em 6 dos últimos 10 dias.',
        intensity: 4,
        frequencyCount: 6,
        windowDays: 10,
        recommendedArticleTitle: 'Manejo do Burnout',
        recommendedArticleUrl: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/sindrome-de-burnout',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CriticalRecurrenceCard(item: item),
          ),
        ),
      );

      expect(find.text('Foco de Atenção: Estresse / Burnout'), findsOneWidget);
      expect(find.text('6x'), findsOneWidget);
      expect(
        find.textContaining('Identificamos que a sua dimensão Estresse'),
        findsOneWidget,
      );
      expect(find.text('Manejo do Burnout'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
