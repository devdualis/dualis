import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/notifications/daily_checkin_notification_service.dart';
import '../../../../core/notifications/notifications_blocked_notice.dart';
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
              final notifier = ref.read(hydrationControllerProvider.notifier);
              final ok = await notifier.toggleReminders(on);
              if (!ok && context.mounted) showSaveFailedSnackBar(context);
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
