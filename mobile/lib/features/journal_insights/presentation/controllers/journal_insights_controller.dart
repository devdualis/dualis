import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../journal/data/journal_local_store.dart';
import '../../../journal/domain/journal_models.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../data/journal_insights_remote_data_source.dart';
import '../../domain/journal_insights_models.dart';

class JournalInsightsState {
  /// Longest period on the history screen (chips 7 / 30 / 90 dias). Shorter
  /// periods are filtered on the device from these entries.
  static const int fetchDays = 90;

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
    final profileId = ref.read(
      activeProfileControllerProvider.select((s) => s.activeProfile?.id),
    );
    final remoteEntries =
        await dataSource.fetchEntries(days: JournalInsightsState.fetchDays);
    List<JournalEntry> pending = const [];
    try {
      pending = await ref
          .read(journalLocalStoreProvider)
          .pendingEntries(profileId: profileId);
    } catch (_) {}
    final pendingViews = [
      for (final entry in pending) JournalEntryView.fromEntry(entry),
    ];
    final remoteIds = remoteEntries.map((e) => e.id).toSet();
    final entries = [
      ...pendingViews.where((e) => !remoteIds.contains(e.id)),
      ...remoteEntries,
    ];
    return JournalInsightsState(
      entries: entries,
      // Counted on the device: each period chip needs its own counts.
      summary: JournalSummary.compute(entries),
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
