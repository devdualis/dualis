import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class AnimatedPageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const AnimatedPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context)
          .pageIndicatorLabel(currentIndex + 1, count),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: isActive ? 24 : 8,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.softIndigo
                  : AppColors.dualisNavy.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ),
    );
  }
}
