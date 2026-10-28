import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../l10n/app_localizations.dart';

final hydrationReminderOfferProvider = Provider<HydrationReminderOffer>(
  (ref) => HydrationReminderOffer(ref.watch(secureStorageServiceProvider)),
);

/// Registration no longer asks about water reminders (strategy §13). It marks
/// the offer as pending, and the first Home visit asks once:
/// "Quer lembretes para beber água?".
class HydrationReminderOffer {
  static const String storageKey = 'dualis_xv2_hydration_offer_pending';

  final SecureStorageService _storage;

  HydrationReminderOffer(this._storage);

  Future<void> markPending() async {
    try {
      await _storage.write(key: storageKey, value: '1');
    } catch (_) {}
  }

  /// True only once: the flag is cleared as soon as it is read.
  Future<bool> takePending() async {
    try {
      final pending = await _storage.read(key: storageKey) == '1';
      if (pending) await _storage.delete(key: storageKey);
      return pending;
    } catch (_) {
      return false;
    }
  }

  /// Shows the offer if pending. "Sim" opens the existing hydration settings.
  Future<void> maybeShow(BuildContext context) async {
    if (!await takePending() || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('hydration_reminder_offer_dialog'),
        icon: const Icon(Icons.water_drop_rounded),
        title: Text(l10n.xv2HydrationOfferTitle),
        content: Text(l10n.xv2HydrationOfferBody),
        actions: [
          TextButton(
            key: const Key('hydration_reminder_offer_no'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.xv2HydrationOfferNo),
          ),
          FilledButton(
            key: const Key('hydration_reminder_offer_yes'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.xv2HydrationOfferYes),
          ),
        ],
      ),
    );
    if (accepted == true && context.mounted) {
      context.push(RoutePaths.hydration);
    }
  }
}
