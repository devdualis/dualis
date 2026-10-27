import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/domain/journal_models.dart';
import '../../domain/models/triage_history_models.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/body_map_card.dart';
import '../widgets/emotional_trend_chart.dart';

/// Which history views to show after a check-in.
class CheckInSummaryArgs {
  final bool showBodyMap;
  final bool showEmotionalTrend;

  /// Journal v2 entry that was just saved (may be waiting to sync).
  final JournalEntry? entry;

  const CheckInSummaryArgs({
    this.showBodyMap = false,
    this.showEmotionalTrend = false,
    this.entry,
  });
}

/// Shown right after the check-in wizard: the body map after the physical
/// evaluation, the emotional trend after the emotional one. Returns Home after
/// [autoReturnSeconds] unless the user touches the screen first. The global
/// urgent-help button (UrgentHelpOverlay) stays visible on this route.
class CheckInSummaryScreen extends ConsumerStatefulWidget {
  static const int autoReturnSeconds = 5;

  final CheckInSummaryArgs args;

  const CheckInSummaryScreen({super.key, required this.args});

  @override
  ConsumerState<CheckInSummaryScreen> createState() =>
      _CheckInSummaryScreenState();
}

class _CheckInSummaryScreenState extends ConsumerState<CheckInSummaryScreen> {
  Timer? _countdown;
  int _secondsLeft = CheckInSummaryScreen.autoReturnSeconds;
  TriageHistoryResponse? _cachedHistory;

  @override
  void initState() {
    super.initState();
    // A cached history predates the entry that was just saved.
    if (ref.exists(dashboardControllerProvider)) {
      _cachedHistory = ref.read(dashboardControllerProvider).value?.history;
      Future.microtask(() {
        if (mounted) ref.invalidate(dashboardControllerProvider);
      });
    }
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      // The urgent-help screen is pushed on top of this one: never pull the
      // user out of it.
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

  /// The user is looking at the screen: stop the automatic return.
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
    final historyAsync = ref.watch(dashboardControllerProvider);
    // While refreshing, or offline, fall back to the history already loaded.
    final history = historyAsync.value?.history ?? _cachedHistory;
    final accentColor =
        widget.args.showBodyMap ? AppColors.clinicalTeal : AppColors.softIndigo;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Listener(
        onPointerDown: (_) => _stopCountdown(),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              l10n.checkInSummaryTitle,
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
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child:
                      history != null
                          ? SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.args.showBodyMap)
                                  BodyMapCard(
                                    physicalSummary: history.physicalSummary,
                                  ),
                                if (widget.args.showBodyMap &&
                                    widget.args.showEmotionalTrend)
                                  const SizedBox(height: 16),
                                if (widget.args.showEmotionalTrend)
                                  EmotionalTrendChart(
                                    data: history.emotionalSummary,
                                  ),
                              ],
                            ),
                          )
                          : historyAsync.hasError
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                l10n.errorLoadHistory,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                          : const Center(child: CircularProgressIndicator()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton(
                    key: const Key('check_in_summary_home_button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
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
    );
  }
}
