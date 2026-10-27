import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../l10n/app_localizations.dart';
import 'dart:async';

import '../../../journal/data/journal_local_store.dart';
import '../../data/triage_outbox_repository.dart';

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

class OfflineIndicatorBanner extends ConsumerWidget {
  const OfflineIndicatorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final pendingCountAsync = ref.watch(pendingOutboxCountProvider);
    final rejectedCountAsync = ref.watch(rejectedOutboxCountProvider);

    final isOnline = isOnlineAsync.value ?? true;
    final pendingCount = pendingCountAsync.value ?? 0;
    final rejectedCount = rejectedCountAsync.value ?? 0;

    if (isOnline && pendingCount == 0 && rejectedCount == 0) {
      return const SizedBox.shrink();
    }

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
      child: Container(
        key: const Key('offline_indicator_banner'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        color: backgroundColor,
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
    );
  }
}
