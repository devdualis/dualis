import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../profile/domain/models/profile.dart';
import '../../profile/presentation/controllers/active_profile_controller.dart';
import '../domain/models/habit_day.dart';
import 'habits_remote_data_source.dart';

abstract class HabitsRepository {
  Future<List<HabitDay>> getHabits({int days = 30, String? profileId});
  Future<HabitDay?> getHabitForDay(String day, {String? profileId});
  Future<HabitDay> saveHabitDay(HabitDay habitDay, {String? profileId});
  Future<void> deleteHabitDay(String day, {String? profileId});
  Future<bool> getTrackMenstrualCycleSetting({String? profileId});
  Future<void> setTrackMenstrualCycleSetting(bool enabled, {String? profileId});
  Future<void> syncPending({String? profileId});
}

class HabitsRepositoryImpl implements HabitsRepository {
  final SecureStorageService _storage;
  final HabitsRemoteDataSource? _remoteDataSource;
  final Ref? _ref;

  HabitsRepositoryImpl({
    required SecureStorageService storage,
    HabitsRemoteDataSource? remoteDataSource,
    Ref? ref,
  })  : _storage = storage,
        _remoteDataSource = remoteDataSource,
        _ref = ref;

  Profile? get _activeProfile =>
      _ref?.read(activeProfileControllerProvider).activeProfile;

  String _profileKey(String? explicitProfileId) {
    final id = explicitProfileId ?? _activeProfile?.id;
    return id != null && id.isNotEmpty ? id : 'primary';
  }

  String _storeKey(String profileKey) => 'dualis_habits_store_$profileKey';
  String _pendingKey(String profileKey) => 'dualis_habits_pending_$profileKey';
  String _cycleKey(String profileKey) => 'dualis_habits_track_cycle_$profileKey';

  Future<Map<String, HabitDay>> _readLocalStore(String profileKey) async {
    try {
      final raw = await _storage.read(key: _storeKey(profileKey));
      if (raw == null || raw.isEmpty) return <String, HabitDay>{};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final result = <String, HabitDay>{};
        decoded.forEach((day, value) {
          if (value is Map<String, dynamic>) {
            result[day] = HabitDay.fromJson(value);
          }
        });
        return result;
      }
      return <String, HabitDay>{};
    } catch (_) {
      return <String, HabitDay>{};
    }
  }

  Future<void> _writeLocalStore(
    String profileKey,
    Map<String, HabitDay> store,
  ) async {
    try {
      final map = <String, dynamic>{
        for (final entry in store.entries) entry.key: entry.value.toJson(),
      };
      await _storage.write(key: _storeKey(profileKey), value: jsonEncode(map));
    } catch (_) {}
  }

  Future<Set<String>> _readPending(String profileKey) async {
    try {
      final raw = await _storage.read(key: _pendingKey(profileKey));
      if (raw == null || raw.isEmpty) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toSet();
      }
      return <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _writePending(String profileKey, Set<String> pending) async {
    try {
      await _storage.write(
        key: _pendingKey(profileKey),
        value: jsonEncode(pending.toList()),
      );
    } catch (_) {}
  }

  @override
  Future<void> syncPending({String? profileId}) async {
    final pk = _profileKey(profileId);
    final remote = _remoteDataSource;
    if (remote == null) return;

    final pending = await _readPending(pk);
    if (pending.isEmpty) return;

    final store = await _readLocalStore(pk);
    final remaining = <String>{};

    for (final day in pending) {
      final habit = store[day];
      if (habit != null) {
        final saved = await remote.saveHabitDay(day, habit, profileId: profileId);
        if (saved == null) {
          remaining.add(day);
        } else {
          store[day] = saved;
        }
      }
    }

    await _writeLocalStore(pk, store);
    await _writePending(pk, remaining);
  }

  @override
  Future<List<HabitDay>> getHabits({int days = 30, String? profileId}) async {
    final pk = _profileKey(profileId);
    await syncPending(profileId: profileId);

    final remote = _remoteDataSource;
    if (remote != null) {
      try {
        final remoteDays = await remote.getHabits(
          days: days,
          profileId: profileId,
        );
        if (remoteDays != null) {
          final store = await _readLocalStore(pk);
          final pending = await _readPending(pk);
          for (final rd in remoteDays) {
            if (!pending.contains(rd.day)) {
              store[rd.day] = rd;
            }
          }
          await _writeLocalStore(pk, store);
        }
      } catch (_) {}
    }

    final store = await _readLocalStore(pk);
    final list = store.values.toList();
    list.sort((a, b) => b.day.compareTo(a.day)); // newest first
    if (list.length > days) {
      return list.sublist(0, days);
    }
    return list;
  }

  @override
  Future<HabitDay?> getHabitForDay(String day, {String? profileId}) async {
    final pk = _profileKey(profileId);
    final store = await _readLocalStore(pk);
    return store[day];
  }

  @override
  Future<HabitDay> saveHabitDay(HabitDay habitDay, {String? profileId}) async {
    final pk = _profileKey(profileId);
    final store = await _readLocalStore(pk);
    store[habitDay.day] = habitDay;
    await _writeLocalStore(pk, store);

    var synced = false;
    final remote = _remoteDataSource;
    if (remote != null) {
      try {
        final result = await remote.saveHabitDay(
          habitDay.day,
          habitDay,
          profileId: profileId,
        );
        if (result != null) {
          synced = true;
          store[habitDay.day] = result;
          await _writeLocalStore(pk, store);
        }
      } catch (_) {}
    }

    final pending = await _readPending(pk);
    if (synced) {
      pending.remove(habitDay.day);
    } else {
      pending.add(habitDay.day);
    }
    await _writePending(pk, pending);

    return store[habitDay.day] ?? habitDay;
  }

  @override
  Future<void> deleteHabitDay(String day, {String? profileId}) async {
    final pk = _profileKey(profileId);
    final store = await _readLocalStore(pk);
    store.remove(day);
    await _writeLocalStore(pk, store);

    final pending = await _readPending(pk);
    pending.remove(day);
    await _writePending(pk, pending);

    if (_remoteDataSource != null) {
      try {
        await _remoteDataSource.deleteHabitDay(day, profileId: profileId);
      } catch (_) {}
    }
  }

  @override
  Future<bool> getTrackMenstrualCycleSetting({String? profileId}) async {
    final pk = _profileKey(profileId);
    final val = await _storage.read(key: _cycleKey(pk));
    return val == 'true';
  }

  @override
  Future<void> setTrackMenstrualCycleSetting(
    bool enabled, {
    String? profileId,
  }) async {
    final pk = _profileKey(profileId);
    await _storage.write(key: _cycleKey(pk), value: enabled ? 'true' : 'false');
  }
}

final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final remoteDataSource = ref.watch(habitsRemoteDataSourceProvider);
  return HabitsRepositoryImpl(
    storage: storage,
    remoteDataSource: remoteDataSource,
    ref: ref,
  );
});
