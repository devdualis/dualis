import 'package:flutter/widgets.dart';
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

  /// Sets active emergency context and immediately redirects to the emergency screen.
  void triggerEmergency(BuildContext context, EmergencyContext emergencyContext) {
    state = AsyncValue.data(emergencyContext);
    context.push(RoutePaths.emergency, extra: emergencyContext);
  }

  /// Persists the intercepted triage session, marks today's check-in complete,
  /// resets active emergency state, and returns the user to the home screen
  /// after they've confirmed exit risks.
  Future<void> recordExitConfirmed([BuildContext? context]) async {
    final emergency = state.value;
    state = const AsyncValue.data(null);

    if (emergency != null) {
      await _persistEmergencyTriage(emergency);
    }

    if (context != null && context.mounted) {
      context.go(RoutePaths.home);
    }
  }

  /// Records the emergency-flagged session as a real triage record (falling back
  /// to the offline outbox when unreachable) so it appears in history like any
  /// other completed check-in, then marks today's check-in as done.
  Future<void> _persistEmergencyTriage(EmergencyContext emergency) async {
    final vertical = emergency.sourceVertical ?? (emergency.isEmotional ? 'emotional' : 'physical');
    final answers = emergency.sourceAnswers ??
        {0: emergency.category.name, 2: emergency.severityLevel.toString()};
    final clientSessionId = const Uuid().v4();

    try {
      final isOnline = await ref.read(connectivityServiceProvider).checkOnline();
      if (isOnline) {
        await ref.read(triageOutcomeDataSourceProvider).submitTriage(
              vertical: vertical,
              answers: answers,
              narrative: emergency.rawTriggerPhrase,
              clientSessionId: clientSessionId,
            );
      } else {
        await ref.read(triageOutboxRepositoryProvider).enqueueTriageCheckIn(
              vertical: vertical,
              answers: answers,
              narrative: emergency.rawTriggerPhrase,
              clientSessionId: clientSessionId,
            );
      }
    } catch (_) {
      await ref.read(triageOutboxRepositoryProvider).enqueueTriageCheckIn(
            vertical: vertical,
            answers: answers,
            narrative: emergency.rawTriggerPhrase,
            clientSessionId: clientSessionId,
          );
    }

    ref.read(triggerCheckInProvider.notifier).markCompletedToday();
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
