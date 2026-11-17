import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import 'app_notification_center.dart';

/// Whether the phone lets this app show notifications. Re-read with
/// `ref.invalidate` (the notice does it when the app comes back to front).
final notificationsAllowedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(appNotificationCenterProvider).notificationsAllowed(),
);

const _appSettingsChannel = MethodChannel('dualis/app_settings');

/// Opens this app's notification settings on the phone.
final openNotificationSettingsProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    try {
      if (Platform.isAndroid) {
        await _appSettingsChannel.invokeMethod<void>('openNotificationSettings');
      } else if (Platform.isIOS) {
        await launchUrl(Uri.parse('app-settings:'));
      }
    } catch (_) {}
  },
);

/// Shown where reminders are set up: says when the phone blocks this app's
/// notifications (so reminders will not appear) and opens the settings.
/// Shows nothing while notifications are allowed or unknown.
class NotificationsBlockedNotice extends ConsumerStatefulWidget {
  const NotificationsBlockedNotice({super.key});

  @override
  ConsumerState<NotificationsBlockedNotice> createState() =>
      _NotificationsBlockedNoticeState();
}

class _NotificationsBlockedNoticeState
    extends ConsumerState<NotificationsBlockedNotice>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone settings: read the permission again.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationsAllowedProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref.watch(notificationsAllowedProvider).value ?? true;
    if (allowed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('notifications_blocked_notice'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.noticeAmberSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.noticeAmberBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.noticeAmberText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notificationsBlockedTitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.noticeAmberText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.notificationsBlockedBody,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.noticeAmberText,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    key: const Key('notifications_open_settings'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.noticeAmberText,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => ref.read(openNotificationSettingsProvider)(),
                    child: Text(l10n.notificationsOpenSettings),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
