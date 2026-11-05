import 'package:dio/dio.dart';
import 'package:dualis_mobile/features/journal/data/journal_repository.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/condition_readings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journal_test_helpers.dart';

final _now = DateTime.now();
final _bp = ConditionReading.bloodPressure(
  measuredAt: _now.subtract(const Duration(hours: 2)),
  systolic: 130,
  diastolic: 85,
  pulse: 72,
);
final _glucose = ConditionReading.glucose(
  measuredAt: _now.subtract(const Duration(hours: 1)),
  mgdl: 98,
  moment: JournalKeys.momentPosRefeicao,
);

JournalEntry _entry(String clientId, {List<ConditionReading>? readings, String conditionId = 'c1'}) =>
    JournalEntry(
      clientId: clientId,
      recordedAt: _now,
      mood: JournalKeys.moodNaoTaoBem,
      area: JournalKeys.areaPhysical,
      items: [
        JournalItem(
          kind: JournalKeys.kindCondition,
          conditionId: conditionId,
          conditionLabel: 'Pressão alta',
          readings: readings ?? [_bp, _glucose],
        ),
      ],
    );

void main() {
  group('offline save and replay with readings', () {
    test('queued offline, then sent with every reading', () async {
      final h = JournalHarness(online: false);
      final saved = await h.repository.saveEntry(_entry('e-1'));
      expect(saved.pendingSync, isTrue);
      expect(h.remote.requestBodies, isEmpty);

      final queued = await h.local.pendingEntries();
      expect(queued.single.items.single.readings, [_bp, _glucose]);

      h.online = true;
      expect(await h.repository.syncPending(), 1);
      final body = h.remote.requestBodies.single;
      final item = (body['items'] as List).single as Map<String, dynamic>;
      expect(item['readings'], [_bp.toJson(), _glucose.toJson()]);
      expect(item.containsKey('intensity'), isFalse);
      expect(item.containsKey('label'), isFalse);
      expect(await h.local.pendingEntries(), isEmpty);
    });

    test('server down while online also queues the readings', () async {
      final h = JournalHarness();
      h.remote.fail = true;
      final saved = await h.repository.saveEntry(_entry('e-2'));
      expect(saved.pendingSync, isTrue);
      expect((await h.local.pendingEntries()).single.items.single.readings, hasLength(2));
      h.remote.fail = false;
      expect(await h.repository.syncPending(), 1);
      expect((h.remote.requestBodies.single['items'] as List).single['readings'], hasLength(2));
    });
  });

  group('condition tracking', () {
    test('updateCondition sends PATCH and refreshes the cache', () async {
      final h = JournalHarness(conditions: const [UserCondition(id: 'c1', label: 'Pressão alta')]);
      await h.repository.conditions();
      final updated = await h.repository.updateCondition('c1', tracking: ['weight', 'blood_pressure', 'x']);
      expect(h.remote.patchRequests.single, {'id': 'c1', 'tracking': ['blood_pressure', 'weight']});
      expect(updated.tracking, ['blood_pressure', 'weight']);
      final cached = await h.local.cachedConditions(null);
      expect(cached.single.tracking, ['blood_pressure', 'weight']);
    });

    test('updateCondition is online only', () async {
      final h = JournalHarness(online: false);
      expect(
        () => h.repository.updateCondition('c1', tracking: const []),
        throwsA(isA<JournalOfflineException>()),
      );
    });

    test('addCondition with tracking creates then patches', () async {
      final h = JournalHarness();
      final created = await h.repository.addCondition('Diabetes', tracking: ['glucose']);
      expect(created.tracking, ['glucose']);
      expect(h.remote.patchRequests.single['tracking'], ['glucose']);
      expect((await h.local.cachedConditions(null)).single.tracking, ['glucose']);
    });

    test('addCondition without tracking does not patch', () async {
      final h = JournalHarness();
      await h.repository.addCondition('Sono');
      expect(h.remote.patchRequests, isEmpty);
    });
  });

  group('condition readings history', () {
    test('server readings plus pending ones, newest first', () async {
      final h = JournalHarness(online: false);
      await h.repository.saveEntry(_entry('e-3', readings: [_glucose]));
      await h.repository.saveEntry(_entry('e-4', readings: [_bp], conditionId: 'c2'));
      h.online = true;
      final older = ConditionReading.weight(
        id: 'r1',
        entryId: 'srv-e',
        conditionId: 'c1',
        measuredAt: _now.subtract(const Duration(days: 2)),
        kg: 72.5,
      );
      h.remote.readings = [older];

      final history = await h.repository.conditionReadings('c1');
      expect(history.complete, isTrue);
      expect(history.readings.map((r) => r.kind), ['glucose', 'weight']);
      expect(history.readings.first.pendingSync, isTrue);
      expect(history.readings.first.conditionId, 'c1');
      expect(history.readings.last.id, 'r1');
      expect(h.remote.readingRequests.single, {'conditionId': 'c1', 'days': 90, 'profileId': null});
    });

    test('offline: only the readings saved on the device', () async {
      final h = JournalHarness(online: false);
      await h.repository.saveEntry(_entry('e-5'));
      final history = await h.repository.conditionReadings('c1');
      expect(history.complete, isFalse);
      expect(history.readings, hasLength(2));
      expect(history.readings.every((r) => r.pendingSync), isTrue);
      expect(h.remote.readingRequests, isEmpty);
    });

    test('a pending reading already on the server shows once', () async {
      final h = JournalHarness(online: false);
      await h.repository.saveEntry(_entry('e-6', readings: [_bp]));
      h.online = true;
      h.remote.readings = [
        ConditionReading.bloodPressure(
          id: 'r9',
          conditionId: 'c1',
          measuredAt: _bp.measuredAt,
          systolic: 130,
          diastolic: 85,
          pulse: 72,
        ),
      ];
      final history = await h.repository.conditionReadings('c1');
      expect(history.readings.single.id, 'r9');
      expect(history.readings.single.pendingSync, isFalse);
    });

    test('provider loads the history of one condition', () async {
      final h = JournalHarness();
      h.remote.readings = [
        ConditionReading.weight(id: 'r1', conditionId: 'c1', measuredAt: _now, kg: 70),
        ConditionReading.weight(id: 'r2', conditionId: 'c2', measuredAt: _now, kg: 80),
      ];
      final container = ProviderContainer(overrides: h.overrides);
      addTearDown(container.dispose);
      final sub = container.listen(conditionReadingsProvider('c1'), (_, _) {});
      addTearDown(sub.close);
      final history = await container.read(conditionReadingsProvider('c1').future);
      expect(history.readings.single.id, 'r1');
    });
  });

  group('AI suggestion failures', () {
    DioException typed(DioExceptionType type) =>
        DioException(requestOptions: RequestOptions(path: '/x'), type: type);
    DioException status(int code, [Object? data]) {
      final request = RequestOptions(path: '/x');
      return DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: code, data: data),
        type: DioExceptionType.badResponse,
      );
    }

    test('aiSuggestFailureOf maps server and network errors', () {
      expect(aiSuggestFailureOf(suggestForbidden('AI_CONSENT_REQUIRED')),
          AiSuggestFailure.consentRequired);
      expect(aiSuggestFailureOf(suggestForbidden('AI_PROFILE_NOT_ALLOWED')),
          AiSuggestFailure.profileNotAllowed);
      expect(aiSuggestFailureOf(status(403, {'code': 'OTHER'})), AiSuggestFailure.unavailable);
      expect(aiSuggestFailureOf(status(429)), AiSuggestFailure.busy);
      expect(aiSuggestFailureOf(status(500)), AiSuggestFailure.unavailable);
      expect(aiSuggestFailureOf(typed(DioExceptionType.connectionError)), AiSuggestFailure.offline);
      expect(aiSuggestFailureOf(typed(DioExceptionType.connectionTimeout)), AiSuggestFailure.offline);
      expect(aiSuggestFailureOf(typed(DioExceptionType.sendTimeout)), AiSuggestFailure.timeout);
      expect(aiSuggestFailureOf(typed(DioExceptionType.receiveTimeout)), AiSuggestFailure.timeout);
      expect(aiSuggestFailureOf(const JournalOfflineException()), AiSuggestFailure.offline);
      expect(aiSuggestFailureOf(StateError('x')), AiSuggestFailure.unavailable);
      expect(aiSuggestFailureOf(const AiSuggestException(AiSuggestFailure.busy)),
          AiSuggestFailure.busy);
    });

    test('suggestOption raises consent and profile refusals, other errors give null', () async {
      final h = JournalHarness();
      h.remote.suggestOptionError = suggestForbidden('AI_CONSENT_REQUIRED');
      await expectLater(
        h.repository.suggestOption(text: 'a', kind: 'emotional'),
        throwsA(isA<AiSuggestException>()
            .having((e) => e.reason, 'reason', AiSuggestFailure.consentRequired)),
      );
      h.remote.suggestOptionError = suggestForbidden('AI_PROFILE_NOT_ALLOWED');
      await expectLater(
        h.repository.suggestOption(text: 'a', kind: 'emotional'),
        throwsA(isA<AiSuggestException>()
            .having((e) => e.reason, 'reason', AiSuggestFailure.profileNotAllowed)),
      );
      h.remote.suggestOptionError = status(429);
      expect(await h.repository.suggestOption(text: 'a', kind: 'emotional'), isNull);
      h.remote.suggestOptionError = null;
      h.online = false;
      expect(await h.repository.suggestOption(text: 'a', kind: 'emotional'), isNull);
      expect(await h.repository.isOnline(), isFalse);
    });
  });
}
