import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

enum DualisNavTab {
  home,
  history,
  hydration,
  care;
}

class DualisBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onEmergencyTap;

  /// Premium: adds the "Meus cuidados" tab before the help button.
  final bool showCare;

  const DualisBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onEmergencyTap,
    this.showCare = false,
  });

  /// Index of the help button, always the last destination.
  int get emergencyIndex => showCare ? 4 : 3;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final homeLabel = l10n?.navHome ?? 'Início';
    final historyLabel = l10n?.navHistory ?? 'Histórico & Mapa';
    final hydrationLabel = l10n?.navHydration ?? 'Água';
    final emergencyLabel = l10n?.urgentHelpButton ?? 'Ajuda urgente';
    final careLabel = l10n?.careHubTitle ?? 'Meus cuidados';

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
        selectedIndex: currentIndex.clamp(0, emergencyIndex - 1),
        onDestinationSelected: (index) {
          if (index == emergencyIndex) {
            onEmergencyTap();
            return;
          }
          onTap(index);
        },
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
          if (showCare)
            NavigationDestination(
              key: const Key('nav_destination_care'),
              icon: const Icon(Icons.favorite_border_rounded, color: AppColors.textSecondaryLight),
              selectedIcon: const Icon(Icons.favorite_rounded, color: AppColors.clinicalTealDark),
              label: '',
              tooltip: careLabel,
            ),
          NavigationDestination(
            key: const Key('nav_destination_emergency'),
            icon: _emergencyGlyph(Icons.emergency_outlined),
            selectedIcon: _emergencyGlyph(Icons.emergency),
            label: '',
            tooltip: emergencyLabel,
          ),
        ],
      ),
    );
  }

  Widget _emergencyGlyph(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.emergencyCrimson,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}
