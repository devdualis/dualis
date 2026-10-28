import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/domain/home_greeting.dart';
import '../../../journal_insights/domain/journal_insights_models.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../../journal_insights/presentation/controllers/journal_insights_controller.dart';
import '../../../journal_insights/presentation/widgets/journal_line_charts.dart';
import '../../../journal_insights/presentation/widgets/journal_overview_widgets.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../../profile/presentation/widgets/profile_app_bar_pill.dart';

/// Dashboard of the last 30 days (strategy §9): what the person recorded,
/// counted and drawn, never interpreted.
///
/// Top: Passado / Presente / Futuro bar and the body map with marked regions.
/// Below: one intensity line per item (5 visible, then "ver mais"),
/// count-only co-occurrence sentences (§9.2) and the entries list.
class HistoricalDashboardScreen extends ConsumerWidget {
  final bool isEmbedded;
  const HistoricalDashboardScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final insightsAsync = ref.watch(journalInsightsControllerProvider);

    final content = insightsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.errorLoadHistory,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                key: const Key('dashboard_retry_button'),
                onPressed: () => ref
                    .read(journalInsightsControllerProvider.notifier)
                    .refresh(),
                child: Text(l10n.xv2DashRetry),
              ),
            ],
          ),
        ),
      ),
      data: (state) => RefreshIndicator(
        onRefresh: () =>
            ref.read(journalInsightsControllerProvider.notifier).refresh(),
        child: _DashboardBody(state: state),
      ),
    );

    if (isEmbedded) return content;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.xv2DashTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        actions: [
          if (ref.watch(premiumProfilesEnabledProvider)) ...[
            const ProfileAppBarPill(),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () =>
                ref.read(journalInsightsControllerProvider.notifier).refresh(),
          ),
          // Space for the global urgent-help button (UrgentHelpOverlay).
          const SizedBox(width: 56),
        ],
      ),
      body: content,
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final JournalInsightsState state;

  const _DashboardBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.read(homeClockProvider)();
    const window = JournalInsightsState.windowDays;
    final series = buildItemSeries(
      l10n,
      state.entries,
      today: today,
      windowDays: window,
    );
    final sentences =
        cooccurrenceSentences(l10n, state.summary, state.entries);

    return ListView(
      key: const Key('journal_dashboard'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const ActiveProfileBanner(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            l10n.xv2DashWindow(window),
            key: const Key('dashboard_window_label'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        InsightsCard(
          title: l10n.xv2DashTimeTitle,
          child: TimeDistributionBar(byTime: state.summary.byTime),
        ),
        InsightsCard(
          title: l10n.xv2DashBodyTitle,
          child: JournalBodyMap(byRegion: state.summary.byRegion),
        ),
        InsightsCard(
          title: l10n.xv2DashLinesTitle,
          subtitle: l10n.xv2DashLinesSubtitle,
          child: ItemIntensityLines(series: series, windowDays: window),
        ),
        if (sentences.isNotEmpty)
          InsightsCard(
            title: l10n.xv2DashTogetherTitle,
            child: Column(
              key: const Key('cooccurrence_sentences'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in sentences)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      s,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        InsightsCard(
          title: l10n.xv2DashEntriesTitle,
          child: _EntriesList(entries: state.entries),
        ),
      ],
    );
  }
}

class _EntriesList extends ConsumerWidget {
  final List<JournalEntryView> entries;

  const _EntriesList({required this.entries});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    JournalEntryView entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.xv2DashDeleteTitle),
        content: Text(l10n.xv2DashDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('dashboard_delete_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.xv2DashDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(journalInsightsControllerProvider.notifier)
          .deleteEntry(entry.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (entries.isEmpty) {
      return Text(
        l10n.xv2DashNoEntries,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
        ),
      );
    }
    final canDelete = !activeProfileIsViewOnly(ref);
    final dateFormat =
        DateFormat.yMd(Localizations.localeOf(context).toLanguageTag());
    return Column(
      children: [
        for (final entry in entries)
          Container(
            key: Key('journal_entry_${entry.id}'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(entry.recordedAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      if (entry.pendingSync) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.jv2PendingSync,
                          key: Key('journal_entry_pending_${entry.id}'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      if (entry.items.isEmpty && entry.mood != null)
                        _line(l10n.xv2DashMoodLine(
                            JournalLabels.mood(l10n, entry.mood!))),
                      for (final item in entry.items)
                        _line(
                          item.intensity != null
                              ? '${item.label(l10n)} · ${l10n.xv2ReportedIntensity(item.intensity!)}'
                              : item.label(l10n),
                        ),
                    ],
                  ),
                ),
                if (canDelete && !entry.legacy && !entry.pendingSync)
                  IconButton(
                    key: Key('journal_entry_delete_${entry.id}'),
                    tooltip: l10n.xv2DashDeleteTitle,
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.textSecondaryLight),
                    onPressed: () => _confirmDelete(context, ref, entry),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _line(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textPrimaryLight,
          ),
        ),
      );
}
