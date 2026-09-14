import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/triage_outcome_remote_data_source.dart';
import '../../domain/triage_outcome_models.dart';

final triageOutcomeDataSourceProvider = Provider<TriageOutcomeRemoteDataSource>((ref) {
  return TriageOutcomeRemoteDataSource();
});

class TriageOutcomeState {
  final bool isLoading;
  final TriageOutcome? outcome;
  final String? errorMessage;

  const TriageOutcomeState({
    this.isLoading = false,
    this.outcome,
    this.errorMessage,
  });

  TriageOutcomeState copyWith({
    bool? isLoading,
    TriageOutcome? outcome,
    String? errorMessage,
  }) {
    return TriageOutcomeState(
      isLoading: isLoading ?? this.isLoading,
      outcome: outcome ?? this.outcome,
      errorMessage: errorMessage,
    );
  }
}

class TriageOutcomeNotifier extends Notifier<TriageOutcomeState> {
  @override
  TriageOutcomeState build() => const TriageOutcomeState();

  Future<void> submitOutcome({
    required String vertical,
    required Map<int, String> answers,
    String? narrative,
    String? token,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dataSource = ref.read(triageOutcomeDataSourceProvider);
      final outcome = await dataSource.submitTriage(
        vertical: vertical,
        answers: answers,
        narrative: narrative,
        token: token,
      );
      state = state.copyWith(isLoading: false, outcome: outcome);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setOutcome(TriageOutcome outcome) {
    state = state.copyWith(isLoading: false, outcome: outcome);
  }

  void reset() {
    state = const TriageOutcomeState();
  }
}

final triageOutcomeProvider =
    NotifierProvider<TriageOutcomeNotifier, TriageOutcomeState>(
  TriageOutcomeNotifier.new,
);
