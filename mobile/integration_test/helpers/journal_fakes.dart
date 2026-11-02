import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/features/journal/data/journal_remote_data_source.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';

/// Network state the test can flip. `checkOnline` drives the repository and
/// the stream drives `isOnlineProvider`, so going back online triggers the
/// outbox sync the same way the device does.
class FakeConnectivity extends ConnectivityService {
  final _changes = StreamController<bool>.broadcast();
  bool online = true;

  void setOnline(bool value) {
    online = value;
    _changes.add(value);
  }

  @override
  Future<bool> checkOnline() async => online;

  @override
  Stream<bool> get isOnlineStream => _changes.stream;

  Future<void> close() => _changes.close();
}

/// In-memory stand-in for the journal v2 API with the Phase 16 rules:
///  * `POST /entries` is idempotent by `clientId` (a replay returns the
///    stored entry, nothing is inserted twice);
///  * condition items carry their readings, which get server ids;
///  * `PATCH /conditions/:id` sets tracking and/or the label;
///  * `GET /conditions/:id/readings` lists that condition's readings, newest
///    first.
/// Requests fail as offline while [connectivity] is offline.
class FakeJournalBackend implements JournalRemoteDataSource {
  final FakeConnectivity connectivity;
  final List<JournalEntry> entries = [];
  List<UserCondition> conditions;

  /// Every `POST /entries` call, by clientId (replays included).
  final Map<String, int> createCalls = {};
  final List<Map<String, dynamic>> patchRequests = [];
  int _seq = 0;

  FakeJournalBackend(this.connectivity, {this.conditions = const []});

  void _ensureOnline(String path) {
    if (connectivity.online) return;
    throw DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionError,
      message: 'integration_test: offline',
    );
  }

  /// Readings stored for [conditionId], newest first.
  List<ConditionReading> readingsOf(String conditionId) => [
        for (final e in entries)
          for (final i in e.items)
            if (i.kind == JournalKeys.kindCondition && i.conditionId == conditionId)
              ...i.readings,
      ]..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

  @override
  Future<JournalEntry> createEntry(JournalEntry entry, {String? profileId}) async {
    _ensureOnline(JournalEndpoints.entries);
    createCalls[entry.clientId] = (createCalls[entry.clientId] ?? 0) + 1;
    for (final e in entries) {
      if (e.clientId == entry.clientId) return e;
    }
    final id = 'entry-${++_seq}';
    final json = entry.toRequestJson();
    json['id'] = id;
    json['items'] = [
      for (final raw in json['items'] as List)
        {
          ...Map<String, dynamic>.from(raw as Map),
          if ((raw['readings'] as List?) != null)
            'readings': [
              for (final r in raw['readings'] as List)
                {
                  ...Map<String, dynamic>.from(r as Map),
                  'id': 'reading-${++_seq}',
                  'entryId': id,
                  'conditionId': raw['conditionId'],
                },
            ],
        },
    ];
    final stored = JournalEntry.fromJson(json);
    entries.add(stored);
    return stored;
  }

  @override
  Future<List<JournalEntry>> listEntries({int days = 30, String? profileId}) async {
    _ensureOnline(JournalEndpoints.entries);
    return [...entries];
  }

  @override
  Future<void> deleteEntry(String id) async {
    _ensureOnline(JournalEndpoints.entry(id));
    entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<UserCondition>> listConditions() async {
    _ensureOnline(JournalEndpoints.conditions);
    return conditions;
  }

  @override
  Future<UserCondition> createCondition(String label) async {
    _ensureOnline(JournalEndpoints.conditions);
    final c = UserCondition(id: 'cond-${++_seq}', label: label);
    conditions = [...conditions, c];
    return c;
  }

  @override
  Future<void> archiveCondition(String id) async {
    _ensureOnline(JournalEndpoints.condition(id));
    conditions = [for (final c in conditions) if (c.id != id) c];
  }

  @override
  Future<UserCondition> patchCondition(
    String id, {
    List<String>? tracking,
    String? label,
    String? profileId,
  }) async {
    _ensureOnline(JournalEndpoints.condition(id));
    patchRequests.add({
      'id': id,
      if (tracking != null) 'tracking': tracking,
      if (label != null) 'label': label,
    });
    final updated = conditions
        .firstWhere((c) => c.id == id)
        .copyWith(label: label, tracking: tracking);
    conditions = [for (final c in conditions) c.id == id ? updated : c];
    return updated;
  }

  @override
  Future<List<ConditionReading>> getConditionReadings(
    String conditionId, {
    int days = 90,
    String? profileId,
  }) async {
    _ensureOnline(JournalEndpoints.conditionReadings(conditionId));
    return readingsOf(conditionId);
  }

  @override
  Future<String?> suggestOption({
    required String text,
    required String kind,
    String? branch,
  }) async =>
      null;
}
