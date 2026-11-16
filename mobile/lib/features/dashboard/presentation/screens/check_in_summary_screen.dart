import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/landscape_background.dart';
import '../../../house_ads/presentation/house_ad_card.dart';
import '../../../journal/domain/journal_models.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../../journal_insights/domain/chart_data.dart';
import '../../../journal_insights/domain/journal_insights_models.dart';
import '../../../journal_insights/presentation/controllers/journal_insights_controller.dart';
import '../../../journal_insights/presentation/widgets/body_marker_map.dart';
import '../../../journal_insights/presentation/widgets/entry_details.dart';

/// One line of "Seu registro de hoje": what the person chose or wrote, in
/// their words, and the intensity they reported.
class CheckInSummaryItem {
  final String label;
  final int? intensity;

  const CheckInSummaryItem({required this.label, this.intensity});
}

/// What the check-in flow passes to the summary screen.
class CheckInSummaryArgs {
  final List<CheckInSummaryItem> items;

  /// General mood in the person's words ("Bem", "Normal"), shown when the
  /// entry has no items.
  final String? moodLabel;

  /// Kept for older callers; the summary no longer changes with them.
  final bool showBodyMap;
  final bool showEmotionalTrend;

  /// Journal v2 entry that was just saved (may be waiting to sync).
  final JournalEntry? entry;

  const CheckInSummaryArgs({
    this.items = const [],
    this.moodLabel,
    this.showBodyMap = false,
    this.showEmotionalTrend = false,
    this.entry,
  });
}

/// Shown right after the daily entry (strategy §5, screen 6, and §9.3):
/// the items with the person's words and reported intensity, a thank-you
/// message with a link to the general library, then a native house ad that
/// is the same for everyone. Returns Home after [autoReturnSeconds] unless
/// the user touches the screen. The global help button stays visible.
class CheckInSummaryScreen extends ConsumerStatefulWidget {
  static const int autoReturnSeconds = 10;

  final CheckInSummaryArgs args;

  const CheckInSummaryScreen({super.key, required this.args});

  @override
  ConsumerState<CheckInSummaryScreen> createState() =>
      _CheckInSummaryScreenState();
}

class _CheckInSummaryScreenState extends ConsumerState<CheckInSummaryScreen> {
  Timer? _countdown;
  int _secondsLeft = CheckInSummaryScreen.autoReturnSeconds;

  @override
  void initState() {
    super.initState();
    // The dashboard must include the entry that was just saved.
    if (ref.exists(journalInsightsControllerProvider)) {
      Future.microtask(() {
        if (mounted) ref.invalidate(journalInsightsControllerProvider);
      });
    }
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      // The help screen is pushed on top of this one: never pull the user
      // out of it.
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
        _stopCountdown();
        return;
      }
      if (_secondsLeft <= 1) {
        _goHome();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _stopCountdown() {
    if (_countdown == null) return;
    _countdown!.cancel();
    setState(() => _countdown = null);
  }

  void _goHome() {
    _countdown?.cancel();
    if (mounted) context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = widget.args.entry;
    final items = widget.args.items.isNotEmpty || entry == null
        ? widget.args.items
        : [
            for (final item in entry.items)
              CheckInSummaryItem(
                label: item.customLabel ??
                    item.conditionLabel ??
                    item.legacyLabel ??
                    (item.optionKey == null
                        ? ''
                        : JournalLabels.option(l10n, item.optionKey!)),
                intensity: item.intensity,
              ),
          ];
    final moodLabel = widget.args.moodLabel ??
        (entry == null ? null : JournalLabels.mood(l10n, entry.mood));
    // The saved entry in full: every item with how long and how much, the
    // closing answers and the note, plus the body map of a physical entry.
    final view = entry == null ? null : JournalEntryView.fromEntry(entry);
    final bodyRegions = view == null
        ? const <RegionSummary>[]
        : regionSummaries(physicalPoints(l10n, [view]));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Listener(
        onPointerDown: (_) => _stopCountdown(),
        child: Scaffold(
          backgroundColor: AppColors.backgroundDepth,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 60,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.glassFillStrong,
                    foregroundColor: AppColors.dualisNavy,
                    fixedSize: const Size(40, 40),
                    side: BorderSide(color: AppColors.dualisNavy.withValues(alpha: 0.08)),
                  ),
                  onPressed: _goHome,
                ),
              ),
            ),
            actions: const [
              // Space for the global urgent-help button (UrgentHelpOverlay).
              SizedBox(width: 56),
            ],
          ),
          body: LandscapeBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _SummaryHeader(
                          title: l10n.xv2SummaryTitle,
                          subtitle: l10n.xv2SummarySaved,
                        ),
                        if (view != null) ...[
                          _SummaryCard(
                            key: const Key('check_in_summary_details'),
                            title: l10n.jv24SummaryDetailsTitle,
                            child: JournalEntryDetails(entry: view),
                          ),
                          if (bodyRegions.isNotEmpty)
                            _SummaryCard(
                              key: const Key('check_in_summary_body'),
                              title: l10n.jv24SummaryBodyTitle,
                              child: BodyMarkerMap(
                                regions: bodyRegions,
                                onSeeEvolution: (_) {
                                  _stopCountdown();
                                  context.go(RoutePaths.history);
                                },
                              ),
                            ),
                        ] else if (items.isEmpty)
                          _SummaryItemTile(
                            label: moodLabel ?? l10n.xv2SummarySaved,
                          )
                        else
                          for (var i = 0; i < items.length; i++)
                            _SummaryItemTile(
                              key: Key('check_in_summary_item_$i'),
                              label: items[i].label,
                              intensity: items[i].intensity,
                            ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientNavy,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.xv2SummaryThanks,
                                key: const Key('check_in_summary_thanks'),
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  height: 1.45,
                                  color: const Color(0xFFDCE8F4),
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                key: const Key('check_in_summary_library'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.dualisNavy,
                                  minimumSize: const Size.fromHeight(48),
                                  textStyle: GoogleFonts.inter(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                icon: const Icon(Icons.menu_book_rounded, size: 20),
                                label: Text(l10n.xv2SummaryOpenLibrary),
                                onPressed: () {
                                  _stopCountdown();
                                  context.push(RoutePaths.library);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const HouseAdCard(),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00F0F7FB), AppColors.backgroundDepth],
                        stops: [0.0, 0.35],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: FilledButton(
                        key: const Key('check_in_summary_home_button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.dualisNavy,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          shape: const StadiumBorder(),
                        ).copyWith(
                          shadowColor: WidgetStatePropertyAll(
                            AppColors.softIndigoDark.withValues(alpha: 0.7),
                          ),
                          elevation: const WidgetStatePropertyAll(6),
                        ),
                        onPressed: _goHome,
                        child: Text(
                          _countdown != null
                              ? l10n.checkInSummaryBackHomeCountdown(_secondsLeft)
                              : l10n.checkInSummaryBackHome,
                          style: GoogleFonts.inter(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Check ring plus "Seu registro de hoje": the page header.
class _SummaryHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SummaryHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.dualisSymbolBlue, width: 5),
              boxShadow: AppColors.glassShadow(blur: 20, alpha: 0.2),
            ),
            child: const ExcludeSemantics(
              child: Icon(Icons.check_rounded, size: 34, color: AppColors.dualisNavy),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    height: 1.15,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dualisNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
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

BoxDecoration _glassDecoration({required double radius}) => BoxDecoration(
      color: AppColors.glassFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassEdge),
      boxShadow: AppColors.glassShadow(blur: 24, alpha: 0.2),
    );

class _SummaryCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SummaryCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _glassDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SummaryItemTile extends StatelessWidget {
  final String label;
  final int? intensity;

  const _SummaryItemTile({super.key, required this.label, this.intensity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: _glassDecoration(radius: 20),
      child: Row(
        children: [
          const DuotoneIconTile(
            size: 36,
            radius: 11,
            child: Icon(Icons.check_rounded, size: 20, color: AppColors.dualisNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dualisNavy,
                  ),
                ),
                if (intensity != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.xv2ReportedIntensity(intensity!),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (intensity != null)
            ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minWidth: 26),
                height: 26,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.dualisNavy,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  '$intensity',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
