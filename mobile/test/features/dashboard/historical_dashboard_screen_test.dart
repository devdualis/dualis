import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/screens/historical_dashboard_screen.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/anatomical_body_map.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/emotional_trend_chart.dart';

class MockTriageHistoryRemoteDataSource implements TriageHistoryRemoteDataSource {
  final TriageHistoryResponse mockResponse;

  MockTriageHistoryRemoteDataSource(this.mockResponse);

  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async {
    return mockResponse;
  }
}

void main() {
  group('HistoricalDashboardScreen Widget Tests (DASH-01, DASH-02, DASH-03, DASH-04)', () {
    late TriageHistoryResponse testResponse;

    setUp(() {
      testResponse = TriageHistoryResponse(
        logs: [
          TriageHistoryEntry(
            id: 'log-1',
            intensity: 4,
            anatomicalSystem: 'coluna_dorsal',
            emotionalDimension: null,
            disposition: 'consulta_rotina',
            stepAnswers: {'causes': 'postura'},
            recordedAt: DateTime.parse('2026-09-14T10:00:00.000Z'),
          ),
          TriageHistoryEntry(
            id: 'log-2',
            intensity: 3,
            anatomicalSystem: null,
            emotionalDimension: 'estresse_burnout',
            disposition: 'auto_cuidado',
            stepAnswers: {'causes': 'trabalho'},
            recordedAt: DateTime.parse('2026-09-13T10:00:00.000Z'),
          ),
        ],
        physicalSummary: {
          'cabeca_pescoco': 0,
          'coluna_dorsal': 4,
        },
        emotionalSummary: [
          const EmotionalDayData(
            date: '2026-09-13',
            dimensions: {'estresse_burnout': 3},
          ),
          const EmotionalDayData(
            date: '2026-09-14',
            dimensions: {'estresse_burnout': 4},
          ),
        ],
        criticalRecurrences: [
          const CriticalRecurrenceItem(
            id: 'rec-1',
            vertical: 'emotional',
            category: 'estresse_burnout',
            categoryLabel: 'Estresse / Burnout',
            title: 'Foco de Atenção: Estresse / Burnout',
            description: 'Identificamos nível 4 em 6 dos últimos 10 dias.',
            intensity: 4,
            frequencyCount: 6,
            windowDays: 10,
            recommendedArticleTitle: 'Manejo do Burnout',
            recommendedArticleUrl: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/sindrome-de-burnout',
          ),
        ],
      );
    });

    testWidgets('1. Renders AppBar and starts on Psico-Emocional tab with EmotionalTrendChart', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            triageHistoryDataSourceProvider.overrideWithValue(
              MockTriageHistoryRemoteDataSource(testResponse),
            ),
          ],
          child: const MaterialApp(
            home: HistoricalDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Histórico & Tendências'), findsOneWidget);
      expect(find.text('Psico-Emocional'), findsOneWidget);
      expect(find.text('Física'), findsOneWidget);
      expect(find.byType(EmotionalTrendChart), findsOneWidget);
      expect(find.text('Foco de Atenção: Estresse / Burnout'), findsOneWidget);
      expect(find.text('Registros Emocionais Recentes'), findsOneWidget);
    });

    testWidgets('2. Tapping Física tab switches to AnatomicalBodyMap and physical records', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            triageHistoryDataSourceProvider.overrideWithValue(
              MockTriageHistoryRemoteDataSource(testResponse),
            ),
          ],
          child: const MaterialApp(
            home: HistoricalDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final fisicaTab = find.text('Física');
      expect(fisicaTab, findsOneWidget);

      await tester.tap(fisicaTab);
      await tester.pumpAndSettle();

      expect(find.byType(AnatomicalBodyMap), findsOneWidget);
      expect(find.text('Mapa Corporal 2D (Últimos 14 Dias)'), findsOneWidget);
      expect(find.text('Registros Físicos Recentes'), findsOneWidget);
      expect(find.text('COLUNA DORSAL'), findsOneWidget);
    });
  });
}
