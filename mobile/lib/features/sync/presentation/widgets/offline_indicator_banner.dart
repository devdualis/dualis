import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../l10n/app_localizations.dart';
import 'dart:async';

import '../../../journal/data/journal_local_store.dart';
import '../../data/triage_outbox_repository.dart';
import '../controllers/sync_outbox_worker.dart';

/// Items waiting to sync: legacy check-ins plus journal v2 entries.
final pendingOutboxCountProvider = StreamProvider<int>((ref) {
  final legacy = ref.watch(triageOutboxRepositoryProvider).getPendingCountStream();
  final journal = ref.watch(journalLocalStoreProvider).pendingCountStream();
  return _sumLatest(legacy, journal);
});

final rejectedOutboxCountProvider = StreamProvider<int>((ref) {
  return ref.watch(journalLocalStoreProvider).rejectedCountStream();
});

Stream<int> _sumLatest(Stream<int> a, Stream<int> b) {
  var lastA = 0;
  var lastB = 0;
  final subs = <StreamSubscription<int>>[];
  late final StreamController<int> controller;
  controller = StreamController<int>(
    onListen: () {
      subs
        ..add(a.listen((v) => controller.add((lastA = v) + lastB),
            onError: controller.addError))
        ..add(b.listen((v) => controller.add(lastA + (lastB = v)),
            onError: controller.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}

/// True while the banner has something to say: offline, items waiting to
/// sync, or items the server rejected.
bool offlineBannerVisible(WidgetRef ref) {
  final isOnline = ref.watch(isOnlineProvider).value ?? true;
  final pendingCount = ref.watch(pendingOutboxCountProvider).value ?? 0;
  final rejectedCount = ref.watch(rejectedOutboxCountProvider).value ?? 0;
  return !isOnline || pendingCount > 0 || rejectedCount > 0;
}

/// Puts the banner above every screen of the app. While it shows, it takes
/// the status-bar area and the screens below lose their top inset, so app
/// bars and the urgent-help button sit right under it.
class OfflineBannerFrame extends ConsumerWidget {
  const OfflineBannerFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!offlineBannerVisible(ref)) return child;
    final topInset = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        OfflineIndicatorBanner(topInset: topInset),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

class OfflineIndicatorBanner extends ConsumerWidget {
  const OfflineIndicatorBanner({super.key, this.topInset = 0});

  /// Extra space on top so the banner color fills the status-bar area.
  final double topInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!offlineBannerVisible(ref)) return const SizedBox.shrink();

    final isOnline = ref.watch(isOnlineProvider).value ?? true;
    final pendingCount = ref.watch(pendingOutboxCountProvider).value ?? 0;
    final rejectedCount = ref.watch(rejectedOutboxCountProvider).value ?? 0;

    final l10n = AppLocalizations.of(context);
    final isOffline = !isOnline;
    final backgroundColor = rejectedCount > 0
        ? const Color(0xFFB45309)
        : isOffline
            ? const Color(0xFFD97706)
            : AppColors.clinicalTeal;

    final message = rejectedCount > 0
        ? l10n.jv2OutboxRejectedNotice
        : isOffline
            ? (pendingCount > 0
                ? '${l10n.offlineBannerText} (${l10n.offlineSyncPendingCount(pendingCount)})'
                : l10n.offlineBannerText)
            : l10n.offlineSyncPendingCount(pendingCount);

    return Semantics(
      liveRegion: true,
      label: message,
      button: !isOffline && pendingCount > 0,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: !isOffline && pendingCount > 0
              ? () => unawaited(
                    ref.read(syncOutboxWorkerProvider.notifier).syncPendingOutbox(),
                  )
              : null,
          child: Container(
        key: const Key('offline_indicator_banner'),
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 9 + topInset, 16, 9),
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
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isOffline && pendingCount > 0) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
          ),
        ),
      ),
    );
  }
}
