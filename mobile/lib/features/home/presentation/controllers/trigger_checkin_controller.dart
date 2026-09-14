import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/trigger_checkin_state.dart';

/// Riverpod controller managing the dual-axis trigger check-in state.
class TriggerCheckInNotifier extends Notifier<TriggerCheckInState> {
  @override
  TriggerCheckInState build() => const TriggerCheckInState();

  void setEmotionalStatus(TriggerStatus status) {
    state = state.copyWith(emotionalStatus: status);
  }

  void setPhysicalStatus(TriggerStatus status) {
    state = state.copyWith(physicalStatus: status);
  }

  void setNaturalLanguageText(String text) {
    state = state.copyWith(naturalLanguageText: text);
  }

  void reset() {
    state = const TriggerCheckInState();
  }
}

final triggerCheckInProvider =
    NotifierProvider<TriggerCheckInNotifier, TriggerCheckInState>(
  TriggerCheckInNotifier.new,
);
