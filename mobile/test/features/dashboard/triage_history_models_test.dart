import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';

/// Round-trips through jsonEncode/jsonDecode so maps have the same runtime
/// types as a real API payload (`Map<String, dynamic>`).
Map<String, dynamic> _payload(Object json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('TriageHistoryModels', () {
    test('TriageHistoryEntry parses a journal entry', () {
      final entry = TriageHistoryEntry.fromJson(_payload({
        'id': 'log-1',
        'intensity': 4,
        'anatomicalSystem': 'coluna_dorsal',
        'emotionalDimension': null,
        'stepAnswers': {'causes': 'postura'},
        'recordedAt': '2026-09-14T10:00:00.000Z',
      }));

      expect(entry.id, 'log-1');
      expect(entry.intensity, 4);
      expect(entry.anatomicalSystem, 'coluna_dorsal');
      expect(entry.emotionalDimension, isNull);
      expect(entry.stepAnswers?['causes'], 'postura');
      expect(entry.recordedAt, DateTime.parse('2026-09-14T10:00:00.000Z'));
    });

    test('TriageHistoryEntry parses vertical; unknown values become null', () {
      Map<String, dynamic> json(Object? vertical) => _payload({
            'id': 'log-v',
            'intensity': 3,
            'anatomicalSystem': 'cabeca_pescoco',
            'emotionalDimension': 'ansiosa_agitacao',
            'vertical': vertical,
            'recordedAt': '2026-09-14T10:00:00.000Z',
          });

      expect(TriageHistoryEntry.fromJson(json('emotional')).vertical, 'emotional');
      expect(TriageHistoryEntry.fromJson(json('physical')).vertical, 'physical');
      expect(TriageHistoryEntry.fromJson(json(null)).vertical, isNull);
      expect(TriageHistoryEntry.fromJson(json('other')).vertical, isNull);
      expect(TriageHistoryEntry.fromJson(json('emotional')).toJson()['vertical'], 'emotional');
    });

    test('TriageHistoryEntry tolerates legacy disposition fields from old caches', () {
      final entry = TriageHistoryEntry.fromJson(_payload({
        'id': 'abc',
        'intensity': 4,
        'anatomicalSystem': 'respiratorio',
        'disposition': 'consulta_rotina',
        'organicPrimacyApplied': true,
        'recordedAt': '2026-01-01T12:00:00.000Z',
      }));

      expect(entry.id, 'abc');
      expect(entry.intensity, 4);
      expect(entry.anatomicalSystem, 'respiratorio');
    });

    test('JournalPatternItem parses the descriptive contract', () {
      final item = JournalPatternItem.fromJson(_payload({
        'category': 'estresse_burnout',
        'vertical': 'emotional',
        'count': 6,
        'windowDays': 10,
      }));

      expect(item.category, 'estresse_burnout');
      expect(item.vertical, 'emotional');
      expect(item.count, 6);
      expect(item.windowDays, 10);
    });

    test('TriageHistoryResponse parses journalPatterns and legacy criticalRecurrences', () {
      final response = TriageHistoryResponse.fromJson(_payload({
        'logs': [
          {
            'id': 'log-1',
            'intensity': 3,
            'anatomicalSystem': 'cabeca_pescoco',
            'emotionalDimension': null,
            'stepAnswers': null,
            'recordedAt': '2026-09-14T12:00:00.000Z',
          },
        ],
        'physicalSummary': {'cabeca_pescoco': 3, 'coluna_dorsal': 0},
        'emotionalSummary': [
          {
            'date': '2026-09-14',
            'dimensions': {'ansiosa_agitacao': 2},
          },
        ],
        'journalPatterns': [
          {
            'category': 'cabeca_pescoco',
            'vertical': 'physical',
            'count': 2,
            'windowDays': 10,
          },
        ],
      }));

      expect(response.logs, hasLength(1));
      expect(response.logs.first.anatomicalSystem, 'cabeca_pescoco');
      expect(response.physicalSummary['cabeca_pescoco'], 3);
      expect(response.emotionalSummary.first.dimensions['ansiosa_agitacao'], 2);
      expect(response.journalPatterns, hasLength(1));
      expect(response.journalPatterns.first.count, 2);
      expect(response.journalPatterns.first.category, 'cabeca_pescoco');

      final legacy = TriageHistoryResponse.fromJson(_payload({
        'logs': [],
        'physicalSummary': {},
        'emotionalSummary': [],
        'criticalRecurrences': [
          {
            'category': 'ansiosa_agitacao',
            'vertical': 'emotional',
            'frequencyCount': 3,
            'windowDays': 10,
          },
        ],
      }));
      expect(legacy.journalPatterns.first.category, 'ansiosa_agitacao');
      expect(legacy.journalPatterns.first.count, 3);
    });

    test('empty response', () {
      final emptyResponse = TriageHistoryResponse.empty();
      expect(emptyResponse.logs, isEmpty);
      expect(emptyResponse.journalPatterns, isEmpty);
    });
  });
}
