import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum DualisNavTab {
  home,
  todayOutcome,
  history;

  // Future features can be easily enabled here:
  // medicationReminders,
  // profile,
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
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            key: Key('nav_destination_home'),
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondaryLight),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.clinicalTealDark),
            label: 'Início',
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
            label: 'Resultado do Dia',
          ),
          const NavigationDestination(
            key: Key('nav_destination_history'),
            icon: Icon(Icons.insights_outlined, color: AppColors.textSecondaryLight),
            selectedIcon: Icon(Icons.insights_rounded, color: AppColors.clinicalTealDark),
            label: 'Histórico & Mapa',
          ),
        ],
      ),
    );
  }
}
