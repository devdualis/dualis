import 'dart:convert';

import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/condition_readings_controller.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:flutter_test/flutter_test.dart';

final _t1 = DateTime.utc(2026, 11, 1, 8, 10);
final _t2 = DateTime.utc(2026, 11, 1, 7, 30);
final _t3 = DateTime.utc(2026, 11, 1, 6);

final _bp = ConditionReading.bloodPressure(measuredAt: _t1, systolic: 130, diastolic: 85, pulse: 72);
final _glucose = ConditionReading.glucose(measuredAt: _t2, mgdl: 98, moment: JournalKeys.momentJejum);
final _weight = ConditionReading.weight(measuredAt: _t3, kg: 72.5);

JournalEntry _entry() => JournalEntry(
      clientId: 'e-1',
      recordedAt: DateTime.utc(2026, 11, 1, 9),
      mood: JournalKeys.moodNaoTaoBem,
      area: JournalKeys.areaPhysical,
      items: [
        JournalItem(
          kind: JournalKeys.kindCondition,
          conditionId: 'c1',
          conditionLabel: 'Pressão alta',
          readings: [_bp, _glucose, _weight],
        ),
        const JournalItem(kind: JournalKeys.kindCondition, conditionId: 'c2', intensity: 2),
      ],
    );

void main() {
  group('ConditionReading JSON', () {
    test('request body carries only the kind, time and its values', () {
      expect(_bp.toJson(), {
        'kind': 'blood_pressure',
        'measuredAt': '2026-11-01T08:10:00.000Z',
        'systolic': 130,
        'diastolic': 85,
        'pulse': 72,
      });
      expect(_glucose.toJson(), {
        'kind': 'glucose',
        'measuredAt': '2026-11-01T07:30:00.000Z',
        'mgdl': 98,
        'moment': 'jejum',
      });
      expect(_weight.toJson(), {
        'kind': 'weight',
        'measuredAt': '2026-11-01T06:00:00.000Z',
        'kg': 72.5,
      });
      final noPulse = ConditionReading.bloodPressure(measuredAt: _t1, systolic: 120, diastolic: 80);
      expect(noPulse.toJson().containsKey('pulse'), isFalse);
    });

    test('server reading round-trips with its ids', () {
      final server = ConditionReading.fromJson({
        'id': 'r1',
        'entryId': 'e1',
        'conditionId': 'c1',
        'kind': 'weight',
        'measuredAt': '2026-11-01T06:00:00.000Z',
        'kg': 72.45,
      });
      expect(server.id, 'r1');
      expect(server.kg, 72.45);
      final back = ConditionReading.fromJson(
        jsonDecode(jsonEncode(server.toLocalJson())) as Map<String, dynamic>,
      );
      expect(back, server);
      expect(back.toJson().containsKey('id'), isFalse);
    });

    test('weight keeps two decimals in the body', () {
      final w = ConditionReading.weight(measuredAt: _t3, kg: 72.456);
      expect(w.toJson()['kg'], 72.46);
    });

    test('input limits catch typos only', () {
      expect(_bp.valuesAccepted, isTrue);
      expect(ConditionReading.bloodPressure(measuredAt: _t1, systolic: 1300, diastolic: 85).valuesAccepted, isFalse);
      expect(ConditionReading.bloodPressure(measuredAt: _t1, systolic: 130, diastolic: 85, pulse: 10).valuesAccepted, isFalse);
      expect(ConditionReading.glucose(measuredAt: _t2, mgdl: 1000, moment: 'dormir').valuesAccepted, isTrue);
      expect(ConditionReading.glucose(measuredAt: _t2, mgdl: 98, moment: 'outro').valuesAccepted, isFalse);
      expect(ConditionReading.weight(measuredAt: _t3, kg: 9.9).valuesAccepted, isFalse);
      expect(ConditionReading.weight(measuredAt: _t3, kg: 500).valuesAccepted, isTrue);
    });

    test('reading time stays near the entry time', () {
      final recordedAt = DateTime.utc(2026, 11, 1, 9);
      final now = recordedAt;
      bool ok(DateTime at) => ConditionReading.weight(measuredAt: at, kg: 70)
          .timeAccepted(recordedAt: recordedAt, now: now);
      expect(ok(now.add(const Duration(minutes: 10))), isTrue);
      expect(ok(now.add(const Duration(minutes: 11))), isFalse);
      expect(ok(recordedAt.subtract(const Duration(days: 7))), isTrue);
      expect(ok(recordedAt.subtract(const Duration(days: 7, minutes: 1))), isFalse);
    });
  });

  group('entry with readings', () {
    test('request body nests readings in the condition item, no label', () {
      final body = _entry().toRequestJson();
      final items = body['items'] as List;
      final tracked = items[0] as Map<String, dynamic>;
      expect(tracked.containsKey('intensity'), isFalse);
      expect(tracked.containsKey('label'), isFalse);
      expect(tracked['readings'], [_bp.toJson(), _glucose.toJson(), _weight.toJson()]);
      expect((items[1] as Map).containsKey('readings'), isFalse);
    });

    test('outbox copy decodes back to the same entry', () {
      final entry = _entry();
      final stored = jsonEncode(entry.toLocalJson());
      final back = JournalEntry.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      expect(back.items.first.readings, entry.items.first.readings);
      expect(back.items.first.conditionLabel, 'Pressão alta');
      expect(back.items.first.intensity, isNull);
      expect(back.items.last.readings, isEmpty);
      expect(back.toRequestJson(), entry.toRequestJson());
    });

    test('server entry DTO readings are read with their ids', () {
      final dto = JournalEntry.fromJson({
        'id': 'e1',
        'clientId': 'e-1',
        'recordedAt': '2026-11-01T09:00:00.000Z',
        'mood': 'nao_tao_bem',
        'area': 'physical',
        'items': [
          {
            'kind': 'condition',
            'conditionId': 'c1',
            'label': 'Pressão alta',
            'intensity': null,
            'readings': [
              {'id': 'r1', 'kind': 'blood_pressure', 'measuredAt': '2026-11-01T08:10:00.000Z', 'systolic': 130, 'diastolic': 85},
            ],
          },
        ],
      });
      final r = dto.items.single.readings.single;
      expect(r.id, 'r1');
      expect(r.systolic, 130);
      expect(r.pulse, isNull);
    });

    test('copyWith keeps or replaces readings and can clear intensity', () {
      final item = const JournalItem(kind: 'condition', conditionId: 'c1', intensity: 3);
      final withReadings = item.copyWith(readings: [_bp], clearIntensity: true);
      expect(withReadings.intensity, isNull);
      expect(withReadings.readings, [_bp]);
      expect(withReadings.copyWith(persistence: 'hoje').readings, [_bp]);
    });
  });

  group('UserCondition tracking', () {
    test('reads known kinds in order and writes them back', () {
      final c = UserCondition.fromJson({
        'id': 'c1',
        'label': 'Diabetes',
        'tracking': ['weight', 'glucose', 'other'],
      });
      expect(c.tracking, ['glucose', 'weight']);
      expect(c.isTracked, isTrue);
      expect(UserCondition.fromJson(c.toJson()).tracking, c.tracking);
      expect(UserCondition.fromJson({'id': 'c2', 'label': 'Sono'}).tracking, isEmpty);
    });
  });

  group('flow readiness', () {
    test('a condition with a reading is ready without intensity', () {
      final ready = JournalFlowState(items: [
        JournalItem(kind: 'condition', conditionId: 'c1', readings: [_bp]),
        const JournalItem(kind: 'condition', conditionId: 'c2', intensity: 4),
      ]);
      expect(ready.allItemsReady, isTrue);
      const notReady = JournalFlowState(items: [
        JournalItem(kind: 'condition', conditionId: 'c1'),
      ]);
      expect(notReady.allItemsReady, isFalse);
      final physical = JournalFlowState(items: [
        JournalItem(kind: 'physical', optionKey: 'cabeca.pressao.temporas', readings: [_bp]),
      ]);
      expect(physical.allItemsReady, isFalse);
    });
  });

  group('readingsByDay', () {
    test('newest day first, newest reading first, nothing merged', () {
      final a = ConditionReading.bloodPressure(measuredAt: DateTime(2026, 11, 1, 8), systolic: 130, diastolic: 85);
      final b = ConditionReading.bloodPressure(measuredAt: DateTime(2026, 11, 1, 20), systolic: 128, diastolic: 80);
      final c = ConditionReading.bloodPressure(measuredAt: DateTime(2026, 10, 30, 9), systolic: 125, diastolic: 82);
      final days = readingsByDay([a, c, b]);
      expect(days.map((d) => d.day), [DateTime(2026, 11, 1), DateTime(2026, 10, 30)]);
      expect(days.first.readings, [b, a]);
      expect(days.last.readings, [c]);
      expect(readingsByDay(const []), isEmpty);
    });
  });
}
