import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/router/route_paths.dart';
import '../../../home/presentation/controllers/trigger_checkin_controller.dart';
import '../../../sync/data/triage_outbox_repository.dart';
import '../../../triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import '../../domain/emergency_context.dart';

/// Riverpod controller managing the active emergency triage state and navigation.
class EmergencyController extends Notifier<AsyncValue<EmergencyContext?>> {
  @override
  AsyncValue<EmergencyContext?> build() {
    return const AsyncValue.data(null);
  }

  /// Triggers an immediate transition to the emergency screen.
  void triggerEmergency(BuildContext context, EmergencyContext emergencyContext) {
    state = AsyncValue.data(emergencyContext);
    context.push(RoutePaths.emergency, extra: emergencyContext);
  }

  /// Patient confirmed exit from emergency screen after warning dialog.
  /// Returns to triage wizard without discarding in-progress answers so
  /// the user can finish and save their triage.
  Future<void> recordExitConfirmed([BuildContext? context]) async {
    state = const AsyncValue.data(null);

    if (context != null && context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.home);
      }
    }
  }

  /// Records the emergency-flagged session with severity 5 in database/outbox
  /// and marks today's check-in as done.
  Future<void> persistEmergencyTriage(EmergencyContext emergency) async {
    ref.read(triggerCheckInProvider.notifier).markCompletedToday();

    final vertical = emergency.sourceVertical ?? (emergency.isEmotional ? 'emotional' : 'physical');
    final answers = Map<int, String>.from(emergency.sourceAnswers ?? {});
    answers[3] = '5';
    answers[2] = answers[2] ?? '5';
    if (!answers.containsKey(0)) {
      answers[0] = emergency.category.name;
    }
    final clientSessionId = const Uuid().v4();

    try {
      final isOnline = await ref.read(connectivityServiceProvider).checkOnline();
      if (isOnline) {
        await ref.read(triageOutcomeDataSourceProvider).submitTriage(
              vertical: vertical,
              answers: answers,
              narrative: emergency.rawTriggerPhrase ?? 'Chamada de emergência acionada',
              clientSessionId: clientSessionId,
            );
      } else {
        await ref.read(triageOutboxRepositoryProvider).enqueueTriageCheckIn(
              vertical: vertical,
              answers: answers,
              narrative: emergency.rawTriggerPhrase ?? 'Chamada de emergência acionada',
              clientSessionId: clientSessionId,
            );
      }
    } catch (_) {
      await ref.read(triageOutboxRepositoryProvider).enqueueTriageCheckIn(
            vertical: vertical,
            answers: answers,
            narrative: emergency.rawTriggerPhrase ?? 'Chamada de emergência acionada',
            clientSessionId: clientSessionId,
          );
    }

    ref.read(triggerCheckInProvider.notifier).markCompletedToday();
  }

  /// Sets or updates the active emergency context in memory.
  void setEmergency(EmergencyContext context) {
    state = AsyncValue.data(context);
  }

  /// Clears in-memory emergency state without navigation side effects.
  void clearEmergency() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for [EmergencyController].
final emergencyControllerProvider =
    NotifierProvider<EmergencyController, AsyncValue<EmergencyContext?>>(
  EmergencyController.new,
);
