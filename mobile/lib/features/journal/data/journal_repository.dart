import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity_service.dart';
import '../../profile/presentation/controllers/active_profile_controller.dart';
import '../domain/journal_keys.dart';
import '../domain/journal_models.dart';
import 'journal_local_store.dart';
import 'journal_remote_data_source.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(
    remote: ref.watch(journalRemoteDataSourceProvider),
    local: ref.watch(journalLocalStoreProvider),
    isOnline: () => ref.read(connectivityServiceProvider).checkOnline(),
    activeProfileId:
        () => ref.read(activeProfileControllerProvider).activeProfile?.id,
  );
});

/// Raised when an action needs the server (conditions are created and
/// archived online only, so they always have a server id).
class JournalOfflineException implements Exception {
  const JournalOfflineException();
}

/// Raised when the profile already has the maximum of active conditions.
class JournalConditionLimitException implements Exception {
  const JournalConditionLimitException();
}

/// Offline-first access to journal v2. Entries are saved online when
/// possible; otherwise they go to the Drift outbox and sync later with the
/// same `clientId`.
class JournalRepository {
  final JournalRemoteDataSource _remote;
  final JournalLocalStore _local;
  final Future<bool> Function() _isOnline;
  final String? Function() _activeProfileId;

  JournalRepository({
    required JournalRemoteDataSource remote,
    required JournalLocalStore local,
    required Future<bool> Function() isOnline,
    required String? Function() activeProfileId,
  }) : _remote = remote,
       _local = local,
       _isOnline = isOnline,
       _activeProfileId = activeProfileId;

  /// Returns the stored entry, or the local copy with `pendingSync: true`
  /// when it was queued for later.
  Future<JournalEntry> saveEntry(JournalEntry entry) async {
    final profileId = _activeProfileId();
    if (await _isOnline()) {
      try {
        return await _remote.createEntry(entry, profileId: profileId);
      } on DioException catch (e) {
        // A validation error will not fix itself by retrying later.
        final status = e.response?.statusCode ?? 0;
        if (status >= 400 && status < 500 && status != 401 && status != 408) {
          rethrow;
        }
      } catch (_) {
        // Fall through to the outbox.
      }
    }
    await _local.enqueue(entry, profileId: profileId);
    return entry.copyWith(pendingSync: true);
  }

  /// Active conditions. Falls back to the cached list when offline.
  Future<List<UserCondition>> conditions() async {
    final profileId = _activeProfileId();
    try {
      if (!await _isOnline()) return await _local.cachedConditions(profileId);
      final list = await _remote.listConditions();
      await _local.replaceConditions(profileId, list);
      return list;
    } catch (_) {
      return _local.cachedConditions(profileId);
    }
  }

  Future<UserCondition> addCondition(String label) async {
    final clean = label.trim();
    final current = await conditions();
    if (current.length >= JournalKeys.maxActiveConditions) {
      throw const JournalConditionLimitException();
    }
    if (!await _isOnline()) throw const JournalOfflineException();
    final created = await _remote.createCondition(
      JournalKeys.limitChars(clean, JournalKeys.conditionLabelMaxLength),
    );
    await _local.replaceConditions(_activeProfileId(), [...current, created]);
    return created;
  }

  Future<void> archiveCondition(String id) async {
    if (!await _isOnline()) throw const JournalOfflineException();
    await _remote.archiveCondition(id);
    final profileId = _activeProfileId();
    final current = await _local.cachedConditions(profileId);
    await _local.replaceConditions(profileId, [
      for (final c in current)
        if (c.id != id) c,
    ]);
  }

  /// Sends queued entries in the order they were saved. Returns how many
  /// reached the server.
  Future<int> syncPending() async {
    var synced = 0;
    for (final row in await _local.pending()) {
      await _local.markSyncing(row.id);
      try {
        await _remote.createEntry(_local.decode(row), profileId: row.profileId);
        await _local.markSynced(row.id);
        synced++;
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        if (status == 409 && _isIdempotentReplay(e)) {
          await _local.markSynced(row.id);
          synced++;
        } else if (status == 400 || status == 422 || status == 409) {
          await _local.markRejected(row.id, e.message ?? e.type.name);
        } else {
          await _local.markFailed(row.id, e.message ?? e.type.name);
        }
      } catch (e) {
        await _local.markFailed(row.id, e.toString());
      }
    }
    return synced;
  }

  /// Existing diary chip for [text], or null if none / offline / error.
  Future<String?> suggestOption({
    required String text,
    required String kind,
    String? branch,
  }) async {
    if (!await _isOnline()) return null;
    try {
      return await _remote.suggestOption(text: text, kind: kind, branch: branch);
    } catch (_) {
      return null;
    }
  }

  /// 409 is success only when the server returns the existing entry
  /// (idempotent replay of the same `clientId`).
  bool _isIdempotentReplay(DioException e) {
    final data = e.response?.data;
    if (data is! Map) return false;
    return data['id'] != null || data['clientId'] != null;
  }
}
