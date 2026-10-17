import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

/// Top banner displaying the active clinical vertical and dynamic step progress.
class TriageStepBanner extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int currentStep;
  final int totalSteps;
  final Color activeColor;
  final VoidCallback? onBack;

  const TriageStepBanner({
    super.key,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
    required this.activeColor,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 28);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = totalSteps > 0
        ? ((currentStep + 1) / totalSteps).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      color: activeColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (onBack != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack,
                    tooltip: l10n.triageBack,
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Space for the global urgent-help button (UrgentHelpOverlay).
                const SizedBox(width: 56),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Semantics(
                label: l10n.triageStep(currentStep + 1, totalSteps),
                value: '${(progress * 100).toInt()}%',
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: progress),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          builder: (context, animatedValue, _) {
                            return LinearProgressIndicator(
                              value: animatedValue,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 6,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.triageStep(currentStep + 1, totalSteps),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
