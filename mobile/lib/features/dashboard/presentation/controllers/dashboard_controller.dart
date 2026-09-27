import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/triage_history_remote_data_source.dart';
import '../../domain/models/triage_history_models.dart';
import '../widgets/dashboard_segmented_tab.dart';

class DashboardState {
  final DashboardTab selectedTab;
  final TriageHistoryResponse history;
  final String? selectedRegionKey;

  const DashboardState({
    this.selectedTab = DashboardTab.emotional,
    required this.history,
    this.selectedRegionKey,
  });

  DashboardState copyWith({
    DashboardTab? selectedTab,
    TriageHistoryResponse? history,
    String? selectedRegionKey,
  }) {
    return DashboardState(
      selectedTab: selectedTab ?? this.selectedTab,
      history: history ?? this.history,
      selectedRegionKey: selectedRegionKey ?? this.selectedRegionKey,
    );
  }
}

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    final dataSource = ref.watch(triageHistoryDataSourceProvider);
    final history = await dataSource.fetchHistory(days: 14);
    return DashboardState(
      selectedTab: DashboardTab.emotional,
      history: history,
    );
  }

  void switchTab(DashboardTab tab) {
    state.whenData((current) {
      state = AsyncData(current.copyWith(selectedTab: tab));
    });
  }

  void selectRegion(String regionKey) {
    state.whenData((current) {
      state = AsyncData(current.copyWith(selectedRegionKey: regionKey));
    });
  }

  Future<void> refreshHistory() async {
    final currentTab = state.asData?.value.selectedTab ?? DashboardTab.emotional;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dataSource = ref.read(triageHistoryDataSourceProvider);
      final history = await dataSource.fetchHistory(days: 14);
      return DashboardState(
        selectedTab: currentTab,
        history: history,
      );
    });
  }

  Future<bool> deleteHistoryEntry(String id) async {
    final dataSource = ref.read(triageHistoryDataSourceProvider);
    final success = await dataSource.deleteHistoryItem(id);
    if (success) {
      final current = state.asData?.value;
      if (current != null) {
        final updatedLogs = current.history.logs.where((e) => e.id != id).toList();
        state = AsyncData(
          current.copyWith(
            history: current.history.copyWith(logs: updatedLogs),
          ),
        );
      }
      try {
        final history = await dataSource.fetchHistory(days: 14);
        final currentTab = state.asData?.value.selectedTab ?? DashboardTab.emotional;
        state = AsyncData(
          DashboardState(
            selectedTab: currentTab,
            history: history,
            selectedRegionKey: state.asData?.value.selectedRegionKey,
          ),
        );
      } catch (_) {}
      return true;
    }
    return false;
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
