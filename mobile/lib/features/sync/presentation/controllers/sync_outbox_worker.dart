import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../triage_outcome/data/triage_outcome_remote_data_source.dart';
import '../../../triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import '../../data/triage_outbox_repository.dart';

class SyncState {
  final bool isSyncing;
  final int syncedCount;
  final int lastErrorCount;

  const SyncState({
    this.isSyncing = false,
    this.syncedCount = 0,
    this.lastErrorCount = 0,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? syncedCount,
    int? lastErrorCount,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      syncedCount: syncedCount ?? this.syncedCount,
      lastErrorCount: lastErrorCount ?? this.lastErrorCount,
    );
  }
}

class SyncOutboxWorker extends Notifier<SyncState> {
  late final TriageOutboxRepository _repository;
  late final TriageOutcomeRemoteDataSource _dataSource;

  @override
  SyncState build() {
    _repository = ref.watch(triageOutboxRepositoryProvider);
    _dataSource = ref.watch(triageOutcomeDataSourceProvider);

    // Automatically trigger sync when connectivity is restored to online
    ref.listen(isOnlineProvider, (previous, next) {
      next.whenData((online) {
        if (online) {
          syncPendingOutbox();
        }
      });
    });

    return const SyncState();
  }

  Future<int> syncPendingOutbox() async {
    if (state.isSyncing) return 0;

    state = state.copyWith(isSyncing: true);
    int successfullySynced = 0;

    try {
      final pendingItems = await _repository.getPendingOutboxItems();

      for (final item in pendingItems) {
        await _repository.updateOutboxStatus(item.id, 'syncing');

        try {
          final Map<String, dynamic> rawAnswers = jsonDecode(item.stepAnswersJson);
          final answers = rawAnswers.map((k, v) => MapEntry(int.parse(k), v.toString()));

          await _dataSource.submitTriage(
            vertical: item.vertical,
            answers: answers,
            narrative: item.narrative,
            clientSessionId: item.clientSessionId,
          );

          await _repository.markOutboxItemSynced(item.id);
          successfullySynced++;
        } catch (e) {
          await _repository.updateOutboxStatus(
            item.id,
            'failed',
            lastError: e.toString(),
            incrementAttempt: true,
          );
        }
      }

      state = state.copyWith(
        isSyncing: false,
        syncedCount: state.syncedCount + successfullySynced,
      );
      return successfullySynced;
    } catch (_) {
      state = state.copyWith(isSyncing: false);
      return successfullySynced;
    }
  }
}

final syncOutboxWorkerProvider =
    NotifierProvider<SyncOutboxWorker, SyncState>(SyncOutboxWorker.new);
