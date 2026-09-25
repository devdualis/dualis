import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

enum DualisNavTab {
  home,
  todayOutcome,
  history,
  hydration;
}

class DualisBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool hasCompletedToday;

  const DualisBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.hasCompletedToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final homeLabel = l10n?.navHome ?? 'Início';
    final todayOutcomeLabel = l10n?.navTodayOutcome ?? 'Resultado do Dia';
    final historyLabel = l10n?.navHistory ?? 'Histórico & Mapa';
    final hydrationLabel = l10n?.navHydration ?? 'Água';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: AppColors.surfaceLight,
        indicatorColor: AppColors.clinicalTeal.withValues(alpha: 0.18),
        elevation: 0,
        height: 60,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: [
          NavigationDestination(
            key: const Key('nav_destination_home'),
            icon: const Icon(Icons.home_outlined, color: AppColors.textSecondaryLight),
            selectedIcon: const Icon(Icons.home_rounded, color: AppColors.clinicalTealDark),
            label: '',
            tooltip: homeLabel,
          ),
          NavigationDestination(
            key: const Key('nav_destination_today_outcome'),
            icon: Badge(
              isLabelVisible: hasCompletedToday,
              smallSize: 8,
              backgroundColor: AppColors.clinicalTeal,
              child: const Icon(Icons.assessment_outlined, color: AppColors.textSecondaryLight),
            ),
            selectedIcon: Badge(
              isLabelVisible: hasCompletedToday,
              smallSize: 8,
              backgroundColor: AppColors.clinicalTeal,
              child: const Icon(Icons.assessment_rounded, color: AppColors.clinicalTealDark),
            ),
            label: '',
            tooltip: todayOutcomeLabel,
          ),
          NavigationDestination(
            key: const Key('nav_destination_history'),
            icon: const Icon(Icons.insights_outlined, color: AppColors.textSecondaryLight),
            selectedIcon: const Icon(Icons.insights_rounded, color: AppColors.clinicalTealDark),
            label: '',
            tooltip: historyLabel,
          ),
          NavigationDestination(
            key: const Key('nav_destination_hydration'),
            icon: const Icon(Icons.water_drop_outlined, color: AppColors.textSecondaryLight),
            selectedIcon: const Icon(Icons.water_drop_rounded, color: AppColors.clinicalTealDark),
            label: '',
            tooltip: hydrationLabel,
          ),
        ],
      ),
    );
  }
}
