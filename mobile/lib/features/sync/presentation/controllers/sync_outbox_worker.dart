import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../journal/data/journal_repository.dart';
import '../../data/notification_action_sync.dart';
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
      } else {
        // Water taps from a notification need no network.
        drainNotificationActions();
      }
    });
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));

    return const SyncState();
  }

  bool _drainingNotificationActions = false;

  /// Applies notification button taps queued while the app was closed.
  /// Never throws; returns 0 on any error or when a drain is already running.
  Future<int> drainNotificationActions() async {
    if (_drainingNotificationActions) return 0;
    _drainingNotificationActions = true;
    try {
      return await ref.read(notificationActionSyncProvider).drain();
    } catch (_) {
      return 0;
    } finally {
      _drainingNotificationActions = false;
    }
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

      // Water / medication taps from notification buttons.
      successfullySynced += await drainNotificationActions();

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
