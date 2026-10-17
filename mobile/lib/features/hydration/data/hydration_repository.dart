import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' hide WaterIntakeLog;
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

  Future<Map<DateTime, int>> getLast7DaysTotals({
    required String userId,
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

  static const _settingsKey = 'dualis_hydration_settings';

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

    // Sync with remote database when user is authenticated
    if (_remoteDataSource != null && userId.isNotEmpty && userId != 'guest_user') {
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

          // Purge local Drift records that were synced before but deleted on server
          for (final row in existingRows) {
            if (row.remoteId != null && !remoteIdSet.contains(row.remoteId)) {
              await (_db.delete(_db.waterIntakeLogs)
                    ..where((tbl) => tbl.id.equals(row.id)))
                  .go();
            }
          }

          // Insert or update entries from remoteLogs into Drift
          final updatedExisting = await (_db.select(_db.waterIntakeLogs)
                ..where((tbl) =>
                    tbl.userId.equals(userId) &
                    _profileFilter(tbl, effectiveProfileId, isPrimary) &
                    tbl.timestamp.isBiggerOrEqualValue(startOfDay) &
                    tbl.timestamp.isSmallerOrEqualValue(endOfDay)))
              .get();

          final existingByRemoteId = {
            for (final row in updatedExisting)
              if (row.remoteId != null) row.remoteId!: row
          };

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
          _profileFilter(tbl, effectiveProfileId, isPrimary) &
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
  Future<Map<DateTime, int>> getLast7DaysTotals({
    required String userId,
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
          days: 7,
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

    for (int i = 6; i >= 0; i--) {
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

  @override
  Future<HydrationSettings> getSettings() async {
    try {
      final raw = await _storage.read(key: _settingsKey);
      if (raw == null || raw.isEmpty) {
        return const HydrationSettings();
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return HydrationSettings.fromJson(json);
    } catch (_) {
      return const HydrationSettings();
    }
  }

  @override
  Future<void> saveSettings(HydrationSettings settings) async {
    final raw = jsonEncode(settings.toJson());
    await _storage.write(key: _settingsKey, value: raw);
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
