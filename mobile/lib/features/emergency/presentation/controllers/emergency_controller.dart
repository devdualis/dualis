import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
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

  /// Resets active emergency state and returns user to the home screen after confirming exit risks.
  void recordExitConfirmed([BuildContext? context]) {
    state = const AsyncValue.data(null);
    if (context != null && context.mounted) {
      context.go(RoutePaths.home);
    }
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
