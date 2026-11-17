import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/app_notification_center.dart';
import '../../../core/notifications/notification_action_queue.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../care/data/care_api.dart';
import '../../care/domain/care_models.dart';
import '../../care/presentation/care_providers.dart';
import '../../hydration/data/hydration_repository.dart';
import '../../hydration/presentation/controllers/hydration_controller.dart';

/// Turns queued notification button taps into real records through the
/// existing repositories. Runs on the main isolate only.
class NotificationActionSync {
  NotificationActionSync({
    required NotificationActionQueue queue,
    required String? Function() userId,
    required Future<void> Function({
      required String userId,
      required int amountMl,
      required DateTime timestamp,
    }) logWater,
    Future<void> Function()? onWaterLogged,
    CareApi Function()? careApi,
    void Function(String medicationId)? onMedicationLogged,
    DateTime Function()? clock,
  })  : _userId = userId,
        _logWater = logWater,
        _onWaterLogged = onWaterLogged,
        _careApi = careApi,
        _onMedicationLogged = onMedicationLogged {
    _drain = NotificationActionDrain(queue, handle: handle, clock: clock);
  }

  final String? Function() _userId;
  final Future<void> Function({
    required String userId,
    required int amountMl,
    required DateTime timestamp,
  }) _logWater;
  final Future<void> Function()? _onWaterLogged;
  final CareApi Function()? _careApi;
  final void Function(String medicationId)? _onMedicationLogged;
  late final NotificationActionDrain _drain;
  bool _loggedWater = false;

  /// Applies every queued action; returns how many were applied.
  Future<int> drain() async {
    _loggedWater = false;
    final done = await _drain.drain();
    if (_loggedWater) {
      try {
        await _onWaterLogged?.call();
      } catch (e) {
        debugPrint('Water totals not refreshed: $e');
      }
    }
    return done;
  }

  @visibleForTesting
  Future<DrainOutcome> handle(PendingNotificationAction action) async {
    switch (action.kind) {
      case PendingNotificationActionKind.water:
        return _water(action);
      case PendingNotificationActionKind.medicationTaken:
        return _medication(action);
    }
  }

  Future<DrainOutcome> _water(PendingNotificationAction action) async {
    final userId = _userId();
    if (userId == null || userId.isEmpty) return DrainOutcome.retry;
    final amount = action.amountMl;
    if (amount == null || amount <= 0) return DrainOutcome.drop;
    // The repository saves locally when offline and pushes later. A crash
    // between this insert and the queue file removal can repeat one 250 ml;
    // accepted rather than changing the HydrationRepository interface.
    await _logWater(userId: userId, amountMl: amount, timestamp: action.at.toLocal());
    _loggedWater = true;
    return DrainOutcome.done;
  }

  /// "Tomei": the backend has no idempotency key, so the slot is checked
  /// first. A dose already marked (in the app, or by a retry whose answer was
  /// lost) is never sent twice.
  Future<DrainOutcome> _medication(PendingNotificationAction action) async {
    final userId = _userId();
    if (userId == null || userId.isEmpty) return DrainOutcome.retry;
    final medicationId = action.medicationId;
    final scheduledFor = action.scheduledFor;
    final careApi = _careApi?.call();
    if (medicationId == null || scheduledFor == null || careApi == null) {
      return DrainOutcome.drop;
    }
    try {
      final intakes =
          await careApi.list(CareKind.medicationIntake, parentId: medicationId);
      final slot = _minuteUtc(scheduledFor);
      final alreadyTaken = intakes.any((intake) =>
          intake.str('action') == IntakeAction.taken.name &&
          intake.occursAt != null &&
          _minuteUtc(intake.occursAt!) == slot);
      if (!alreadyTaken) {
        await careApi.logIntake(medicationId, scheduledFor, IntakeAction.taken);
      }
      _onMedicationLogged?.call(medicationId);
      return DrainOutcome.done;
    } on DioException catch (e) {
      const rejected = {400, 403, 404, 422};
      return rejected.contains(e.response?.statusCode)
          ? DrainOutcome.drop
          : DrainOutcome.retry;
    }
  }

  static DateTime _minuteUtc(DateTime d) {
    final u = d.toUtc();
    return DateTime.utc(u.year, u.month, u.day, u.hour, u.minute);
  }
}

final notificationActionSyncProvider = Provider<NotificationActionSync>((ref) {
  return NotificationActionSync(
    queue: ref.watch(notificationActionQueueProvider),
    userId: () => ref.read(authControllerProvider).user?.id,
    logWater: ({
      required String userId,
      required int amountMl,
      required DateTime timestamp,
    }) =>
        ref.read(hydrationRepositoryProvider).logWaterIntake(
              userId: userId,
              amountMl: amountMl,
              source: 'notification',
              timestamp: timestamp,
            ),
    onWaterLogged: () =>
        ref.read(hydrationControllerProvider.notifier).loadData(),
    careApi: () => ref.read(careApiProvider),
    onMedicationLogged: (medicationId) {
      ref.invalidate(intakesProvider(medicationId));
      ref.invalidate(careRecordsProvider(CareKind.medication));
    },
  );
});
