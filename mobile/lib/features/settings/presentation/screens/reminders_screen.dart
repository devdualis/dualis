import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/notifications/daily_checkin_notification_service.dart';
import '../../../../core/notifications/notifications_blocked_notice.dart';
import '../../../care/presentation/care_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/load_error_view.dart';
import '../../../../shared/widgets/urgent_help_button.dart';
import '../../../hydration/presentation/controllers/hydration_controller.dart';
import '../../../profile/domain/models/share_category.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../widgets/settings_row_icon.dart';

/// 8 -> "08:00".
String _hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

/// Settings > Lembretes (sketch 002, layout B "Lista + folha").
///
/// Shows when DualisCheckUp reminds the person. Only the water reminder has a
/// switch; check-in and care are read-only summaries. The screen reads the
/// hydration settings only, never care records.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final showCare = ref.watch(premiumProfilesEnabledProvider);
    const checkInHours = DailyCheckinNotificationService.reminderHours;
    final checkInFrom = _hourLabel(checkInHours.first);
    final checkInTo = _hourLabel(checkInHours.last);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.remindersTitle,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // The global UrgentHelpOverlay button sits in this strip.
        actions: const [SizedBox(width: UrgentHelpButton.reservedEdgeWidth)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            l10n.remindersLead,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          const NotificationsBlockedNotice(),
          const SizedBox(height: 4),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  _ReminderRow(
                    key: const Key('reminders_checkin_row'),
                    icon: Icons.event_available_outlined,
                    iconColor: AppColors.dualisNavy,
                    tint: AppColors.softIndigoLight,
                    title: l10n.remindersCheckInTitle,
                    summary: l10n.remindersCheckInSummary(
                      checkInFrom,
                      checkInTo,
                    ),
                    onTap: () => _showCheckInSheet(
                      context,
                      from: checkInFrom,
                      to: checkInTo,
                    ),
                  ),
                  const SettingsDivider(),
                  const _WaterReminderRow(),
                  if (showCare) ...[
                    const SettingsDivider(),
                    _ReminderRow(
                      key: const Key('reminders_care_row'),
                      icon: Icons.favorite_border_rounded,
                      iconColor: AppColors.dualisCareGreen,
                      tint: AppColors.dualisCareGreenLight,
                      title: l10n.remindersCareTitle,
                      summary: l10n.remindersCareSummary,
                      onTap: () => _showCareSheet(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _PrivacyNote(),
        ],
      ),
    );
  }
}

class _ReminderIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color tint;

  const _ReminderIconTile({
    required this.icon,
    required this.color,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }
}

TextStyle _rowTitleStyle() => GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    );

TextStyle _rowSummaryStyle() => GoogleFonts.inter(
      fontSize: 13,
      color: AppColors.textSecondaryLight,
    );

class _ReminderRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String summary;
  final VoidCallback? onTap;

  const _ReminderRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.title,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _ReminderIconTile(icon: icon, color: iconColor, tint: tint),
      title: Text(title, style: _rowTitleStyle()),
      subtitle: Text(summary, style: _rowSummaryStyle()),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondaryLight,
      ),
      onTap: onTap,
    );
  }
}

class _WaterReminderRow extends ConsumerWidget {
  const _WaterReminderRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(hydrationControllerProvider);
    final settings = state.settings;
    // Same guard as the hydration dashboard: water is part of habits.
    final viewOnly =
        activeProfileIsViewOnly(ref) ||
        !activeProfileCanWrite(ref, ShareCategory.habits);

    final hours = [...settings.scheduledHours]..sort();
    final summary = !settings.reminderEnabled
        ? l10n.remindersStatusOff
        : hours.isEmpty
            ? l10n.remindersStatusOn
            : l10n.remindersWaterSummaryOn(
                _hourLabel(hours.first),
                _hourLabel(hours.last),
              );

    return SwitchListTile(
      key: const Key('settings_water_reminder_switch'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: const _ReminderIconTile(
        icon: Icons.water_drop_outlined,
        color: AppColors.dualisSymbolBlue,
        tint: AppColors.clinicalTealLight,
      ),
      title: Text(l10n.remindersWaterTitle, style: _rowTitleStyle()),
      subtitle: Text(summary, style: _rowSummaryStyle()),
      value: settings.reminderEnabled,
      activeTrackColor: AppColors.dualisNavy,
      activeThumbColor: Colors.white,
      onChanged: state.isLoading || viewOnly
          ? null
          : (on) async {
              // Explain before the OS dialog: only on the off-to-on change
              // while the phone does not allow notifications yet.
              var explained = false;
              if (on) {
                final allowed =
                    await ref.read(notificationsAllowedProvider.future);
                if (!context.mounted) return;
                if (!allowed) {
                  if (!await _showPermissionSheet(context)) return;
                  explained = true;
                }
              }
              final notifier = ref.read(hydrationControllerProvider.notifier);
              // Unchanged path: scheduling asks the OS when it still can.
              final ok = await notifier.toggleReminders(on);
              if (!context.mounted) return;
              if (!ok) showSaveFailedSnackBar(context);
              // Show the OS answer in the blocked banner.
              if (explained) ref.invalidate(notificationsAllowedProvider);
            },
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.remindersPrivacyNote,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared layout B "folha": white surface, top radius 28, grab handle, title.
/// Every action sits below the title, away from the top-right strip where
/// the global help button floats.
Future<T?> _showReminderSheet<T>(
  BuildContext context, {
  required Key key,
  required String title,
  Widget? leading,
  required List<Widget> Function(BuildContext sheetContext) children,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      key: key,
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dualisNavy.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (leading != null) ...[leading, const SizedBox(width: 12)],
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dualisNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children(sheetContext),
          ],
        ),
      ),
    ),
  );
}

TextStyle _sheetBodyStyle() => GoogleFonts.inter(
      fontSize: 15,
      height: 1.45,
      color: AppColors.textPrimaryLight,
    );

Widget _primaryButton({
  Key? key,
  required String label,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      key: key,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.dualisNavy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

/// Read-only: no switch, no times, no mode choice (MANIFEST D3).
Future<void> _showCheckInSheet(
  BuildContext context, {
  required String from,
  required String to,
}) {
  final l10n = AppLocalizations.of(context);
  return _showReminderSheet<void>(
    context,
    key: const Key('reminders_checkin_sheet'),
    title: l10n.remindersCheckInTitle,
    leading: const _ReminderIconTile(
      icon: Icons.event_available_outlined,
      color: AppColors.dualisNavy,
      tint: AppColors.softIndigoLight,
    ),
    children: (sheetContext) => [
      Text(l10n.remindersCheckInSheetBody(from, to), style: _sheetBodyStyle()),
      const SizedBox(height: 24),
      _primaryButton(
        label: l10n.remindersSheetDone,
        onPressed: () => Navigator.of(sheetContext).pop(),
      ),
    ],
  );
}

/// Links to the care screens where each reminder is set up. No care-wide
/// on/off and no record names here.
Future<void> _showCareSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  // Captured before the sheet closes so the push uses the screen's router.
  final router = GoRouter.of(context);

  Widget link(
    BuildContext sheetContext,
    String key,
    IconData icon,
    String label,
    String path,
  ) {
    return ListTile(
      key: Key(key),
      contentPadding: EdgeInsets.zero,
      leading: _ReminderIconTile(
        icon: icon,
        color: AppColors.dualisCareGreen,
        tint: AppColors.dualisCareGreenLight,
      ),
      title: Text(label, style: _rowTitleStyle()),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondaryLight,
      ),
      onTap: () {
        Navigator.of(sheetContext).pop();
        router.push(path);
      },
    );
  }

  return _showReminderSheet<void>(
    context,
    key: const Key('reminders_care_sheet'),
    title: l10n.remindersCareTitle,
    leading: const _ReminderIconTile(
      icon: Icons.favorite_border_rounded,
      color: AppColors.dualisCareGreen,
      tint: AppColors.dualisCareGreenLight,
    ),
    children: (sheetContext) => [
      Text(l10n.remindersCareSheetBody, style: _sheetBodyStyle()),
      const SizedBox(height: 8),
      Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            link(
              sheetContext,
              'reminders_care_link_medications',
              Icons.medication_outlined,
              l10n.careMedicationsTitle,
              CarePaths.medications,
            ),
            link(
              sheetContext,
              'reminders_care_link_appointments',
              Icons.event_outlined,
              l10n.careAppointmentsTitle,
              CarePaths.appointments,
            ),
            link(
              sheetContext,
              'reminders_care_link_vaccines',
              Icons.vaccines_outlined,
              l10n.careVaccinesTitle,
              CarePaths.vaccines,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _primaryButton(
        label: l10n.remindersSheetDone,
        onPressed: () => Navigator.of(sheetContext).pop(),
      ),
    ],
  );
}

/// Explains why the phone will ask, with a sample of the general water
/// notification. True only for "Permitir avisos"; dismissing counts as no.
/// Calls no permission API itself.
Future<bool> _showPermissionSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await _showReminderSheet<bool>(
    context,
    key: const Key('reminders_permission_sheet'),
    title: l10n.remindersPermissionTitle,
    children: (sheetContext) => [
      Text(l10n.remindersPermissionBody, style: _sheetBodyStyle()),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.dualisSymbolBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.remindersPermissionPreviewMeta,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.notifWaterTitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    l10n.notifWaterBodyTracking,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const _PrivacyNote(),
      const SizedBox(height: 24),
      _primaryButton(
        key: const Key('reminders_permission_allow'),
        label: l10n.remindersPermissionAllow,
        onPressed: () => Navigator.of(sheetContext).pop(true),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: TextButton(
          key: const Key('reminders_permission_not_now'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.dualisNavy,
            textStyle:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          onPressed: () => Navigator.of(sheetContext).pop(false),
          child: Text(l10n.remindersPermissionNotNow),
        ),
      ),
    ],
  );
  return result ?? false;
}
