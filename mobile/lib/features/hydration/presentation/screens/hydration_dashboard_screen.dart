import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/domain/home_greeting.dart';
import '../../../house_ads/data/house_ads_repository.dart';
import '../../../house_ads/presentation/house_ad_card.dart';
import '../../../journal_insights/presentation/widgets/journal_line_charts.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../controllers/hydration_controller.dart';
import '../widgets/hydration_visuals.dart';
import '../widgets/water_intake_modal.dart';

/// Interactive hydration screen (strategy §11): one action at a time, a glass
/// that fills, quick buttons 200 ml / 500 ml / Outro, the person's own daily
/// goal as a ring, a streak and 30 days of history. After logging water, the
/// house ad card may appear at most once per day (strategy §14).
class HydrationDashboardScreen extends ConsumerStatefulWidget {
  static const int historyDays = 30;

  final bool isEmbedded;
  const HydrationDashboardScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<HydrationDashboardScreen> createState() =>
      _HydrationDashboardScreenState();
}

class _HydrationDashboardScreenState
    extends ConsumerState<HydrationDashboardScreen> {
  bool _showAd = false;

  Future<void> _onWaterLogged() async {
    if (_showAd) return;
    final now = ref.read(homeClockProvider)();
    final allowed =
        await ref.read(houseAdsRepositoryProvider).takeWaterAdSlot(now);
    if (allowed && mounted) setState(() => _showAd = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(hydrationControllerProvider);
    final notifier = ref.read(hydrationControllerProvider.notifier);
    final viewOnly = activeProfileIsViewOnly(ref);

    ref.listen<HydrationState>(hydrationControllerProvider, (prev, next) {
      if (prev != null &&
          !prev.isLoading &&
          next.todayLogs.length > prev.todayLogs.length) {
        _onWaterLogged();
      }
    });

    final content = state.isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => notifier.loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ActiveProfileBanner(),
                  if (viewOnly) const ActiveProfileReadOnlyNote(),
                  const SizedBox(height: 8),
                  _TodayCard(state: state, viewOnly: viewOnly),
                  if (_showAd) ...[
                    const SizedBox(height: 16),
                    const HouseAdCard(),
                  ],
                  const SizedBox(height: 24),
                  _SectionTitle(l10n.xv2WaterTodayLogs),
                  const SizedBox(height: 12),
                  _TodayLogs(state: state, viewOnly: viewOnly),
                  const SizedBox(height: 24),
                  _SectionTitle(l10n.xv2WaterHistoryTitle),
                  const SizedBox(height: 12),
                  _Panel(
                    child: WaterLine(
                      dailyTotals: state.last30DaysTotals,
                      goalMl: state.dailyTargetMl,
                      today: ref.read(homeClockProvider)(),
                      windowDays: HydrationDashboardScreen.historyDays,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(l10n.xv2WaterRemindersTitle),
                  const SizedBox(height: 12),
                  _ReminderSettings(state: state, viewOnly: viewOnly),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          );

    if (widget.isEmbedded) return content;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.xv2WaterTitle,
          style: GoogleFonts.plusJakartaSans(
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
        actions: const [SizedBox(width: 56)],
      ),
      body: content,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: child,
    );
  }
}

class _TodayCard extends ConsumerWidget {
  final HydrationState state;
  final bool viewOnly;

  const _TodayCard({required this.state, required this.viewOnly});

  Future<void> _editGoal(BuildContext context, WidgetRef ref) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => _GoalDialog(initialMl: state.dailyTargetMl),
    );
    if (value != null) {
      await ref.read(hydrationControllerProvider.notifier).setDailyTarget(value);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(hydrationControllerProvider.notifier);
    final streak = state.streakDays(ref.read(homeClockProvider)());

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedWaterGlass(fill: state.progressRatio),
              HydrationGoalRing(
                progress: state.progressRatio,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${state.todayTotalMl} / ${state.dailyTargetMl} ml',
                      key: const Key('hydration_today_total'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${state.progressPercent}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                key: const Key('hydration_streak'),
                avatar: const Icon(Icons.local_fire_department_outlined,
                    size: 18, color: AppColors.clinicalTealDark),
                label: Text(l10n.xv2WaterStreak(streak)),
              ),
              ActionChip(
                key: const Key('hydration_goal_edit'),
                avatar: const Icon(Icons.flag_outlined,
                    size: 18, color: AppColors.clinicalTealDark),
                label: Text(l10n.xv2WaterGoalChip(state.dailyTargetMl)),
                onPressed: viewOnly ? null : () => _editGoal(context, ref),
              ),
            ],
          ),
          if (!viewOnly) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickButton(
                    key: const Key('hydration_quick_add_200'),
                    emoji: '🥛',
                    label: '200 ml',
                    onTap: () =>
                        notifier.logWater(amountMl: 200, source: 'quick_chip'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickButton(
                    key: const Key('hydration_quick_add_500'),
                    emoji: '🍶',
                    label: '500 ml',
                    onTap: () =>
                        notifier.logWater(amountMl: 500, source: 'quick_chip'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickButton(
                    key: const Key('dashboard_add_water_button'),
                    emoji: '✏️',
                    label: l10n.xv2WaterOther,
                    onTap: () =>
                        WaterIntakeModal.show(context, source: 'dashboard'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The person's own daily goal (strategy §11): no formula, no "você precisa".
class _GoalDialog extends StatefulWidget {
  final int initialMl;
  const _GoalDialog({required this.initialMl});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialMl.toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = int.tryParse(_controller.text);
    if (parsed != null && parsed >= 250 && parsed <= 10000) {
      Navigator.of(context).pop(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.xv2WaterGoalDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('hydration_goal_field'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(suffixText: 'ml'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.xv2WaterGoalHint,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('hydration_goal_save'),
          onPressed: _save,
          child: Text(l10n.xv2WaterGoalSave),
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QuickButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 64),
        side: const BorderSide(color: AppColors.clinicalTeal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.clinicalTealDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayLogs extends ConsumerWidget {
  final HydrationState state;
  final bool viewOnly;

  const _TodayLogs({required this.state, required this.viewOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (state.todayLogs.isEmpty) {
      return _Panel(
        child: Center(
          child: Text(
            l10n.xv2WaterNoLogsToday,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      );
    }
    return Column(
      children: state.todayLogs.reversed.map((log) {
        final time = DateFormat('HH:mm').format(log.timestamp);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0.5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: AppColors.surfaceLight,
          child: ListTile(
            leading: const Icon(
              Icons.local_drink_rounded,
              color: AppColors.clinicalTealDark,
            ),
            title: Text(
              '${log.amountMl} ml',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              log.source == 'reminder_alarm'
                  ? l10n.xv2WaterLoggedViaReminder(time)
                  : l10n.xv2WaterLoggedAt(time),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
            trailing: viewOnly
                ? null
                : IconButton(
                    key: Key(
                        'delete_water_log_${log.id ?? log.remoteId ?? log.timestamp.millisecondsSinceEpoch}'),
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    tooltip: l10n.xv2WaterDeleteLog,
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.grey),
                    onPressed: () => ref
                        .read(hydrationControllerProvider.notifier)
                        .deleteLog(log),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

class _ReminderSettings extends ConsumerWidget {
  final HydrationState state;
  final bool viewOnly;

  const _ReminderSettings({required this.state, required this.viewOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(hydrationControllerProvider.notifier);
    final settings = state.settings;
    final titleStyle = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: AppColors.textPrimaryLight,
    );
    final subtitleStyle = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      color: AppColors.textSecondaryLight,
    );

    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const Key('settings_water_reminder_switch'),
              title: Text(l10n.registerWaterReminderTitle, style: titleStyle),
              subtitle: Text(
                l10n.registerWaterReminderSubtitle,
                style: subtitleStyle,
              ),
              value: settings.reminderEnabled,
              activeThumbColor: AppColors.clinicalTeal,
              onChanged: viewOnly ? null : notifier.toggleReminders,
            ),
          ],
        ),
      ),
    );
  }
}
