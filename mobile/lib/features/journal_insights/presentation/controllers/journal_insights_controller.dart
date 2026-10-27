import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../data/journal_insights_remote_data_source.dart';
import '../../domain/journal_insights_models.dart';

class JournalInsightsState {
  /// Free shows 30 days (strategy §9.1); data is kept per retention policy.
  static const int windowDays = 30;

  final List<JournalEntryView> entries;
  final JournalSummary summary;

  const JournalInsightsState({required this.entries, required this.summary});

  JournalInsightsState withoutEntry(String id) {
    final remaining = entries.where((e) => e.id != id).toList();
    return JournalInsightsState(
      entries: remaining,
      summary: JournalSummary.compute(remaining),
    );
  }
}

class JournalInsightsController extends AsyncNotifier<JournalInsightsState> {
  String? _lastProfileId;

  @override
  Future<JournalInsightsState> build() async {
    final profileId = ref.watch(
      activeProfileControllerProvider.select((s) => s.activeProfile?.id),
    );
    // Never show the previous profile's entries while loading another one.
    if (_lastProfileId != profileId) {
      _lastProfileId = profileId;
      state = const AsyncLoading();
    }
    return _load();
  }

  Future<JournalInsightsState> _load() async {
    final dataSource = ref.read(journalInsightsDataSourceProvider);
    final results = await Future.wait([
      dataSource.fetchEntries(days: JournalInsightsState.windowDays),
      dataSource.fetchSummary(days: JournalInsightsState.windowDays),
    ]);
    final entries = results[0] as List<JournalEntryView>;
    final remote = results[1] as JournalSummary?;
    return JournalInsightsState(
      entries: entries,
      summary: remote ?? JournalSummary.compute(entries),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<bool> deleteEntry(String id) async {
    final ok = await ref.read(journalInsightsDataSourceProvider).deleteEntry(id);
    final current = state.value;
    if (ok && current != null) {
      state = AsyncData(current.withoutEntry(id));
    }
    return ok;
  }
}

final journalInsightsControllerProvider =
    AsyncNotifierProvider<JournalInsightsController, JournalInsightsState>(
  JournalInsightsController.new,
);
