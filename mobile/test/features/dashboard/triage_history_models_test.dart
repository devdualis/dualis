import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';

void main() {
  group('Triage History Models Tests', () {
    test('TriageHistoryEntry parses valid json correctly', () {
      final json = {
        'id': 'log-1',
        'intensity': 4,
        'anatomicalSystem': 'coluna_dorsal',
        'emotionalDimension': null,
        'disposition': 'consulta_rotina',
        'stepAnswers': {'causes': 'postura'},
        'recordedAt': '2026-09-14T10:00:00.000Z',
      };

      final entry = TriageHistoryEntry.fromJson(json);

      expect(entry.id, 'log-1');
      expect(entry.intensity, 4);
      expect(entry.anatomicalSystem, 'coluna_dorsal');
      expect(entry.emotionalDimension, isNull);
      expect(entry.disposition, 'consulta_rotina');
      expect(entry.stepAnswers?['causes'], 'postura');
      expect(entry.recordedAt, DateTime.parse('2026-09-14T10:00:00.000Z'));
    });

    test('CriticalRecurrenceItem parses valid json correctly', () {
      final json = {
        'id': 'rec-1',
        'vertical': 'emotional',
        'category': 'estresse_burnout',
        'categoryLabel': 'Estresse / Burnout',
        'title': 'Foco de Atenção: Estresse / Burnout',
        'description': 'Identificamos nível 4 em 6 dos últimos 10 dias.',
        'intensity': 4,
        'frequencyCount': 6,
        'windowDays': 10,
        'recommendedArticleTitle': 'Manejo do Burnout',
        'recommendedArticleUrl': 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/sindrome-de-burnout',
      };

      final item = CriticalRecurrenceItem.fromJson(json);

      expect(item.id, 'rec-1');
      expect(item.vertical, 'emotional');
      expect(item.category, 'estresse_burnout');
      expect(item.categoryLabel, 'Estresse / Burnout');
      expect(item.intensity, 4);
      expect(item.frequencyCount, 6);
      expect(item.windowDays, 10);
      expect(item.recommendedArticleTitle, 'Manejo do Burnout');
    });

    test('TriageHistoryResponse parses full response payload and empty fallback', () {
      final json = {
        'logs': [
          {
            'id': 'log-1',
            'intensity': 3,
            'anatomicalSystem': 'cabeca_pescoco',
            'emotionalDimension': null,
            'disposition': 'auto_cuidado',
            'stepAnswers': null,
            'recordedAt': '2026-09-14T12:00:00.000Z',
          }
        ],
        'physicalSummary': {'cabeca_pescoco': 3, 'coluna_dorsal': 0},
        'emotionalSummary': [
          {
            'date': '2026-09-14',
            'dimensions': {'estresse_burnout': 2}
          }
        ],
        'criticalRecurrences': [
          {
            'id': 'rec-1',
            'vertical': 'emotional',
            'category': 'estresse_burnout',
            'categoryLabel': 'Estresse / Burnout',
            'title': 'Alerta',
            'description': 'Recorrência alta',
            'intensity': 4,
            'frequencyCount': 3,
            'windowDays': 10,
            'recommendedArticleTitle': 'Burnout',
            'recommendedArticleUrl': 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/sindrome-de-burnout',
          }
        ],
      };

      final response = TriageHistoryResponse.fromJson(json);

      expect(response.logs, hasLength(1));
      expect(response.physicalSummary['cabeca_pescoco'], 3);
      expect(response.emotionalSummary, hasLength(1));
      expect(response.emotionalSummary.first.dimensions['estresse_burnout'], 2);
      expect(response.criticalRecurrences, hasLength(1));

      final emptyResponse = TriageHistoryResponse.empty();
      expect(emptyResponse.logs, isEmpty);
      expect(emptyResponse.physicalSummary, isEmpty);
      expect(emptyResponse.emotionalSummary, isEmpty);
      expect(emptyResponse.criticalRecurrences, isEmpty);
    });
  });
}
