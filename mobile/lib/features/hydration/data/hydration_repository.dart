import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' hide WaterIntakeLog;
import '../../../../core/database/app_database.dart' as local_db show WaterIntakeLog;
import '../../../../core/security/secure_storage_service.dart';
import '../../profile/domain/models/profile.dart';
import '../../profile/presentation/controllers/active_profile_controller.dart';
import '../domain/models/hydration_settings.dart';
import '../domain/models/water_intake_log.dart';
import 'hydration_remote_data_source.dart';

abstract class HydrationRepository {
  Future<WaterIntakeEntry> logWaterIntake({
    required String userId,
    required int amountMl,
    String source = 'manual',
    DateTime? timestamp,
  });

  Future<List<WaterIntakeEntry>> getLogsForDay({
    required String userId,
    required DateTime day,
  });

  Future<int> getTodayTotalMl({required String userId});

  /// Daily totals for the [days] days ending on [referenceDate] (Free shows
  /// 30, strategy §11).
  Future<Map<DateTime, int>> getDailyTotals({
    required String userId,
    int days = 30,
    DateTime? referenceDate,
  });

  Future<void> deleteLog(int id);

  Future<void> deleteRemoteLog(String remoteId) async {}

  Future<HydrationSettings> getSettings();

  Future<void> saveSettings(HydrationSettings settings);
}

class HydrationRepositoryImpl implements HydrationRepository {
  final AppDatabase _db;
  final SecureStorageService _storage;
  final HydrationRemoteDataSource? _remoteDataSource;
  final Ref? _ref;

  static const _settingsKey = SecureStorageService.keyHydrationSettings;

  HydrationRepositoryImpl({
    required AppDatabase db,
    required SecureStorageService storage,
    HydrationRemoteDataSource? remoteDataSource,
    Ref? ref,
  })  : _db = db,
        _storage = storage,
        _remoteDataSource = remoteDataSource,
        _ref = ref;

  Profile? get _activeProfile =>
      _ref?.read(activeProfileControllerProvider).activeProfile;

  String? _resolveProfileId(String? explicitProfileId) =>
      explicitProfileId ?? _activeProfile?.id;

  bool _resolveIsPrimary(String? resolvedProfileId, bool? explicitIsPrimary) {
    if (explicitIsPrimary != null) return explicitIsPrimary;
    final active = _activeProfile;
    if (active != null) {
      if (resolvedProfileId == null || resolvedProfileId == active.id) {
        return active.isPrimary;
      }
    }
    // Default fallback: if resolvedProfileId is null, it's considered primary (pre-v4)
    return resolvedProfileId == null;
  }

  Expression<bool> _profileFilter(
    $WaterIntakeLogsTable tbl,
    String? profileId,
    bool isPrimary,
  ) {
    if (isPrimary) {
      if (profileId != null) {
        return tbl.profileId.equals(profileId) | tbl.profileId.isNull();
      } else {
        return tbl.profileId.isNull();
      }
    } else {
      if (profileId != null) {
        return tbl.profileId.equals(profileId);
      } else {
        return tbl.profileId.isNull();
      }
    }
  }

  @override
  Future<WaterIntakeEntry> logWaterIntake({
    required String userId,
    required int amountMl,
    String source = 'manual',
    DateTime? timestamp,
    String? profileId,
  }) async {
    final entryTime = timestamp ?? DateTime.now();
    final effectiveProfileId = _resolveProfileId(profileId);

    String? remoteId;
    if (_remoteDataSource != null && userId.isNotEmpty && userId != 'guest_user') {
      try {
        final remoteEntry = await _remoteDataSource.logWater(
          amountMl: amountMl,
          source: source,
          timestamp: entryTime,
          profileId: effectiveProfileId,
        );
        remoteId = remoteEntry?.remoteId;
      } catch (_) {}
    }

    final companion = WaterIntakeLogsCompanion(
      userId: Value(userId),
      remoteId: Value(remoteId),
      amountMl: Value(amountMl),
      timestamp: Value(entryTime),
      source: Value(source),
      profileId: Value(effectiveProfileId),
    );

    final id = await _db.into(_db.waterIntakeLogs).insert(companion);

    return WaterIntakeEntry(
      id: id,
      remoteId: remoteId,
      userId: userId,
      amountMl: amountMl,
      timestamp: entryTime,
      source: source,
    );
  }

  /// Sends this profile's logs that never reached the server (saved while
  /// offline) and stores the server id they get back.
  Future<void> _pushPending(
    String userId,
    String? profileId,
    bool isPrimary,
  ) async {
    final remote = _remoteDataSource;
    if (remote == null) return;
    try {
      final since = DateTime.now().subtract(const Duration(days: 30));
      final rows = await (_db.select(_db.waterIntakeLogs)
            ..where((tbl) =>
                tbl.userId.equals(userId) &
                tbl.remoteId.isNull() &
                _profileFilter(tbl, profileId, isPrimary) &
                tbl.timestamp.isBiggerOrEqualValue(since))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp)]))
          .get();
      for (final row in rows) {
        final sent = await remote.logWater(
          amountMl: row.amountMl,
          source: row.source,
          timestamp: row.timestamp,
          profileId: row.profileId ?? profileId,
        );
        final remoteId = sent?.remoteId;
        if (remoteId == null) return; // Still offline: try again next load.
        await (_db.update(_db.waterIntakeLogs)
              ..where((tbl) => tbl.id.equals(row.id)))
            .write(WaterIntakeLogsCompanion(
          remoteId: Value(remoteId),
          profileId: Value(row.profileId ?? profileId),
        ));
      }
    } catch (_) {}
  }

  @override
  Future<List<WaterIntakeEntry>> getLogsForDay({
    required String userId,
    required DateTime day,
    String? profileId,
    bool? isPrimaryProfile,
  }) async {
    final startOfDay = DateTime(day.year, day.month, day.day, 0, 0, 0);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    final effectiveProfileId = _resolveProfileId(profileId);
    final isPrimary = _resolveIsPrimary(effectiveProfileId, isPrimaryProfile);

    // Server ids of this profile's logs for the day, when the server answered.
    var serverIds = const <String>{};

    // Sync with remote database when user is authenticated
    if (_remoteDataSource != null && userId.isNotEmpty && userId != 'guest_user') {
      // Water logged while offline goes up first, so the server's answer
      // below already includes it.
      await _pushPending(userId, effectiveProfileId, isPrimary);
      try {
        final remoteLogs = await _remoteDataSource.getTodayLogs(
          date: day,
          profileId: effectiveProfileId,
        );
        if (remoteLogs != null) {
          final existingRows = await (_db.select(_db.waterIntakeLogs)
                ..where((tbl) =>
                    tbl.userId.equals(userId) &
                    _profileFilter(tbl, effectiveProfileId, isPrimary) &
                    tbl.timestamp.isBiggerOrEqualValue(startOfDay) &
                    tbl.timestamp.isSmallerOrEqualValue(endOfDay)))
              .get();

          final remoteIdSet = remoteLogs
              .map((r) => r.remoteId)
              .whereType<String>()
              .toSet();
          serverIds = remoteIdSet;

          // Purge local Drift records that were synced before but deleted on server
          for (final row in existingRows) {
            if (row.remoteId != null && !remoteIdSet.contains(row.remoteId)) {
              await (_db.delete(_db.waterIntakeLogs)
                    ..where((tbl) => tbl.id.equals(row.id)))
                  .go();
            }
          }

          // Match server logs to local rows by remoteId across every profile
          // of this user: a load that ran before the active profile was known
          // (right after login) stores them without a profile, and must not
          // be counted again next to the copy that has one.
          final userDayRows = await (_db.select(_db.waterIntakeLogs)
                ..where((tbl) =>
                    tbl.userId.equals(userId) &
                    tbl.remoteId.isNotNull() &
                    tbl.timestamp.isBiggerOrEqualValue(
                        startOfDay.subtract(const Duration(days: 1))) &
                    tbl.timestamp.isSmallerOrEqualValue(
                        endOfDay.add(const Duration(days: 1))))
                ..orderBy([(tbl) => OrderingTerm(expression: tbl.id)]))
              .get();

          final existingByRemoteId = <String, local_db.WaterIntakeLog>{};
          for (final row in userDayRows) {
            final rid = row.remoteId!;
            if (!remoteIdSet.contains(rid)) continue;
            final kept = existingByRemoteId[rid];
            if (kept == null) {
              existingByRemoteId[rid] = row;
            } else {
              // Prefer the copy that already carries the profile.
              final keepRow = kept.profileId == null && row.profileId != null
                  ? row
                  : kept;
              final dropRow = identical(keepRow, row) ? kept : row;
              existingByRemoteId[rid] = keepRow;
              await (_db.delete(_db.waterIntakeLogs)
                    ..where((tbl) => tbl.id.equals(dropRow.id)))
                  .go();
            }
          }
          if (effectiveProfileId != null) {
            for (final row in existingByRemoteId.values) {
              if (row.profileId == null) {
                await (_db.update(_db.waterIntakeLogs)
                      ..where((tbl) => tbl.id.equals(row.id)))
                    .write(WaterIntakeLogsCompanion(
                        profileId: Value(effectiveProfileId)));
              }
            }
          }

          for (final r in remoteLogs) {
            if (r.remoteId != null && existingByRemoteId.containsKey(r.remoteId)) {
              continue;
            }
            final companion = WaterIntakeLogsCompanion(
              userId: Value(userId),
              remoteId: Value(r.remoteId),
              amountMl: Value(r.amountMl),
              timestamp: Value(r.timestamp),
              source: Value(r.source),
              profileId: Value(effectiveProfileId),
            );
            await _db.into(_db.waterIntakeLogs).insert(companion);
          }
        }
      } catch (_) {}
    }

    final query = _db.select(_db.waterIntakeLogs)
      ..where((tbl) =>
          tbl.userId.equals(userId) &
          (serverIds.isEmpty
              ? _profileFilter(tbl, effectiveProfileId, isPrimary)
              : (_profileFilter(tbl, effectiveProfileId, isPrimary) |
                  tbl.remoteId.isIn(serverIds))) &
          tbl.timestamp.isBiggerOrEqualValue(startOfDay) &
          tbl.timestamp.isSmallerOrEqualValue(endOfDay))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.asc)
      ]);

    final rows = await query.get();

    return rows
        .map((r) => WaterIntakeEntry(
              id: r.id,
              remoteId: r.remoteId,
              userId: r.userId,
              amountMl: r.amountMl,
              timestamp: r.timestamp,
              source: r.source,
            ))
        .toList();
  }

  @override
  Future<int> getTodayTotalMl({
    required String userId,
    String? profileId,
    bool? isPrimaryProfile,
  }) async {
    final logs = await getLogsForDay(
      userId: userId,
      day: DateTime.now(),
      profileId: profileId,
      isPrimaryProfile: isPrimaryProfile,
    );
    return logs.fold<int>(0, (int sum, WaterIntakeEntry item) => sum + item.amountMl);
  }

  @override
  Future<Map<DateTime, int>> getDailyTotals({
    required String userId,
    int days = 30,
    DateTime? referenceDate,
    String? profileId,
    bool? isPrimaryProfile,
  }) async {
    final refDate = referenceDate ?? DateTime.now();
    final effectiveProfileId = _resolveProfileId(profileId);
    final isPrimary = _resolveIsPrimary(effectiveProfileId, isPrimaryProfile);

    // Try remote database first if authenticated
    if (_remoteDataSource != null && userId.isNotEmpty && userId != 'guest_user') {
      try {
        final remoteTotals = await _remoteDataSource.getHistoryTotals(
          days: days,
          referenceDate: refDate,
          profileId: effectiveProfileId,
        );
        if (remoteTotals != null && remoteTotals.isNotEmpty) {
          return remoteTotals;
        }
      } catch (_) {}
    }

    // Fallback to local Drift DB calculation
    final totals = <DateTime, int>{};

    for (int i = days - 1; i >= 0; i--) {
      final targetDate = refDate.subtract(Duration(days: i));
      final normalizedDate =
          DateTime(targetDate.year, targetDate.month, targetDate.day);
      final logs = await getLogsForDay(
        userId: userId,
        day: normalizedDate,
        profileId: effectiveProfileId,
        isPrimaryProfile: isPrimary,
      );
      final daySum = logs.fold<int>(0, (int sum, WaterIntakeEntry log) => sum + log.amountMl);
      totals[normalizedDate] = daySum;
    }

    return totals;
  }

  @override
  Future<void> deleteLog(int id) async {
    try {
      final row = await (_db.select(_db.waterIntakeLogs)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
      if (row?.remoteId != null && row!.remoteId!.isNotEmpty) {
        if (_remoteDataSource != null) {
          await _remoteDataSource.deleteLog(row.remoteId!, profileId: row.profileId);
        }
      }
    } catch (_) {}

    await (_db.delete(_db.waterIntakeLogs)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteRemoteLog(String remoteId, {String? profileId}) async {
    try {
      await (_db.delete(_db.waterIntakeLogs)
            ..where((tbl) => tbl.remoteId.equals(remoteId)))
          .go();
    } catch (_) {}

    if (_remoteDataSource != null) {
      try {
        await _remoteDataSource.deleteLog(remoteId, profileId: profileId);
      } catch (_) {}
    }
  }

  /// Remote first: the account's settings on the server win. The device's
  /// copy is used when the server does not answer, and a change saved while
  /// offline is sent before reading so it is not overwritten.
  @override
  Future<HydrationSettings> getSettings() async {
    final local = await _localSettings();
    final remote = _remoteDataSource;
    if (remote == null) return local ?? const HydrationSettings();
    try {
      final pending =
          await _storage.read(key: SecureStorageService.keyHydrationSettingsPending) == '1';
      if (pending && local != null) {
        if (await remote.saveSettings(local)) {
          await _storage.delete(key: SecureStorageService.keyHydrationSettingsPending);
        }
        return local;
      }
      final answer = await remote.getSettings();
      if (!answer.answered) return local ?? const HydrationSettings();
      final server = answer.settings;
      if (server == null) {
        // Nothing on the server yet: keep this device's choices and send them.
        if (local != null) await remote.saveSettings(local);
        return local ?? const HydrationSettings();
      }
      await _writeLocalSettings(server);
      return server;
    } catch (_) {
      return local ?? const HydrationSettings();
    }
  }

  @override
  Future<void> saveSettings(HydrationSettings settings) async {
    await _writeLocalSettings(settings);
    var sent = false;
    try {
      sent = await _remoteDataSource?.saveSettings(settings) ?? false;
    } catch (_) {}
    if (sent) {
      await _storage.delete(key: SecureStorageService.keyHydrationSettingsPending);
    } else {
      await _storage.write(
        key: SecureStorageService.keyHydrationSettingsPending,
        value: '1',
      );
    }
  }

  Future<HydrationSettings?> _localSettings() async {
    try {
      final raw = await _storage.read(key: _settingsKey);
      if (raw == null || raw.isEmpty) return null;
      return HydrationSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLocalSettings(HydrationSettings settings) async {
    try {
      await _storage.write(key: _settingsKey, value: jsonEncode(settings.toJson()));
    } catch (_) {}
  }
}

final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  final remoteDataSource = ref.watch(hydrationRemoteDataSourceProvider);
  return HydrationRepositoryImpl(
    db: db,
    storage: storage,
    remoteDataSource: remoteDataSource,
    ref: ref,
  );
});
