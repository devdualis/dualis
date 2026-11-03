import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../journal/data/journal_repository.dart';
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

  @override
  SyncState build() {
    _repository = ref.watch(triageOutboxRepositoryProvider);

    // Device wifi restored.
    ref.listen(isOnlineProvider, (previous, next) {
      next.whenData((online) {
        if (online) {
          syncPendingOutbox();
        }
      });
    });

    final observer = _ResumeSyncObserver(() {
      if (ref.read(isOnlineProvider).value ?? true) {
        syncPendingOutbox();
      }
    });
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));

    return const SyncState();
  }

  Future<int> syncPendingOutbox() async {
    if (state.isSyncing) return 0;

    state = state.copyWith(isSyncing: true);
    int successfullySynced = 0;

    try {
      // Legacy triage / daily-checkin outbox items: the endpoints were retired.
      // Devices may still hold queued items; drop them permanently with no
      // retry loop, no crash and no error banner.
      final pendingLegacyItems = await _repository.getPendingOutboxItems();
      for (final item in pendingLegacyItems) {
        try {
          await _repository.markOutboxItemSynced(item.id);
        } catch (_) {}
      }

      // Journal v2 entries saved offline (idempotent by clientId).
      try {
        successfullySynced +=
            await ref.read(journalRepositoryProvider).syncPending();
      } catch (_) {}

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

class _ResumeSyncObserver with WidgetsBindingObserver {
  final VoidCallback onResume;
  _ResumeSyncObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
