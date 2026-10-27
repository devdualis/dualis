import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/landscape_background.dart';
import '../../../house_ads/presentation/house_ad_card.dart';
import '../../../journal_insights/presentation/controllers/journal_insights_controller.dart';

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

  const CheckInSummaryArgs({
    this.items = const [],
    this.moodLabel,
    this.showBodyMap = false,
    this.showEmotionalTrend = false,
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
    final items = widget.args.items;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Listener(
        onPointerDown: (_) => _stopCountdown(),
        child: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              l10n.xv2SummaryTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: _goHome,
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
                        if (items.isEmpty)
                          _SummaryItemTile(
                            label: widget.args.moodLabel ?? l10n.xv2SummarySaved,
                          )
                        else
                          for (var i = 0; i < items.length; i++)
                            _SummaryItemTile(
                              key: Key('check_in_summary_item_$i'),
                              label: items[i].label,
                              intensity: items[i].intensity,
                            ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.xv2SummaryThanks,
                          key: const Key('check_in_summary_thanks'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            height: 1.4,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('check_in_summary_library'),
                            icon: const Icon(Icons.menu_book_rounded),
                            label: Text(l10n.xv2SummaryOpenLibrary),
                            onPressed: () {
                              _stopCountdown();
                              context.push(RoutePaths.library);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const HouseAdCard(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: FilledButton(
                      key: const Key('check_in_summary_home_button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.softIndigo,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _goHome,
                      child: Text(
                        _countdown != null
                            ? l10n.checkInSummaryBackHomeCountdown(_secondsLeft)
                            : l10n.checkInSummaryBackHome,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

class _SummaryItemTile extends StatelessWidget {
  final String label;
  final int? intensity;

  const _SummaryItemTile({super.key, required this.label, this.intensity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          if (intensity != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.xv2ReportedIntensity(intensity!),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
