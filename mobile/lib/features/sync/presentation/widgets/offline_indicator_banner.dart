import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/triage_outbox_repository.dart';

final pendingOutboxCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(triageOutboxRepositoryProvider);
  return repo.getPendingCountStream();
});

class OfflineIndicatorBanner extends ConsumerWidget {
  const OfflineIndicatorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final pendingCountAsync = ref.watch(pendingOutboxCountProvider);

    final isOnline = isOnlineAsync.value ?? true;
    final pendingCount = pendingCountAsync.value ?? 0;

    if (isOnline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final isOffline = !isOnline;

    return Container(
      key: const Key('offline_indicator_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isOffline ? Colors.amber.shade800 : Colors.teal.shade700,
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.sync_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isOffline
                  ? (pendingCount > 0
                      ? '${l10n.offlineBannerText} (${l10n.offlineSyncPendingCount(pendingCount)})'
                      : l10n.offlineBannerText)
                  : l10n.offlineSyncPendingCount(pendingCount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
