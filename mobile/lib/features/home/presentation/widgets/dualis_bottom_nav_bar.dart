import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/premium_gradient_icon.dart';

class DualisBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onEmergencyTap;

  /// Adds the "Meus cuidados" tab before the help button.
  final bool showCare;

  /// Free build: the care tab shows a "PRO" badge and opens the Premium promo.
  final bool careLocked;

  /// Premium build: the water tab becomes "Hábitos" (water lives inside it).
  final bool habitsTab;

  /// Premium build: the selected icon gets the gradient and active dot; unselected icons stay gray.
  final bool premiumIcons;

  const DualisBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onEmergencyTap,
    this.showCare = false,
    this.careLocked = false,
    this.habitsTab = false,
    this.premiumIcons = false,
  });

  /// Index of the help button, always the last destination.
  int get emergencyIndex => showCare ? 4 : 3;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final homeLabel = l10n?.navHome ?? 'Início';
    final historyLabel = l10n?.navHistory ?? 'Histórico & Mapa';
    final hydrationLabel = l10n?.navHydration ?? 'Água';
    final habitsLabel = l10n?.habitsChartTitle ?? 'Hábitos';
    final emergencyLabel = l10n?.urgentHelpButton ?? 'Ajuda urgente';
    final careLabel = l10n?.careHubTitle ?? 'Meus cuidados';

    final reduceTransparency =
        MediaQuery.maybeOf(context)?.highContrast ?? false;

    // Floating glass tab bar on the left, separate red help button on the
    // right (prototype `.tabs` + `.sos`). The help entry keeps its key,
    // tooltip and `onEmergencyTap`; it is not a bar destination any more.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_barHeight / 2),
                  boxShadow: AppColors.glassShadow(blur: 30, alpha: 0.45),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_barHeight / 2),
                  child: BackdropFilter(
                    filter:
                        reduceTransparency
                            ? ImageFilter.blur()
                            : ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      height: _barHeight,
                      decoration: BoxDecoration(
                        color:
                            reduceTransparency
                                ? AppColors.surfaceLight
                                : AppColors.glassFillStrong,
                        borderRadius: BorderRadius.circular(_barHeight / 2),
                        border: Border.all(color: AppColors.glassEdge),
                      ),
                      child: NavigationBarTheme(
                        data: NavigationBarThemeData(
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          indicatorColor: AppColors.dualisNavy.withValues(
                            alpha: 0.08,
                          ),
                          indicatorShape: const StadiumBorder(),
                        ),
                        child: NavigationBar(
                          selectedIndex: currentIndex.clamp(
                            0,
                            emergencyIndex - 1,
                          ),
                          onDestinationSelected: (index) {
                            if (index == emergencyIndex) {
                              onEmergencyTap();
                              return;
                            }
                            onTap(index);
                          },
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          height: _barHeight,
                          labelBehavior:
                              NavigationDestinationLabelBehavior.alwaysHide,
                          destinations: [
                            NavigationDestination(
                              key: const Key('nav_destination_home'),
                              icon: const Icon(
                                Icons.home_outlined,
                                color: AppColors.textSecondaryLight,
                              ),
                              selectedIcon: _selected(
                                const Icon(
                                  Icons.home_rounded,
                                  color: AppColors.dualisNavy,
                                ),
                              ),
                              label: '',
                              tooltip: homeLabel,
                            ),
                            NavigationDestination(
                              key: const Key('nav_destination_history'),
                              icon: const Icon(
                                Icons.insights_outlined,
                                color: AppColors.textSecondaryLight,
                              ),
                              selectedIcon: _selected(
                                const Icon(
                                  Icons.insights_rounded,
                                  color: AppColors.dualisNavy,
                                ),
                              ),
                              label: '',
                              tooltip: historyLabel,
                            ),
                            if (habitsTab)
                              NavigationDestination(
                                key: const Key('nav_destination_habits'),
                                icon: const Icon(
                                  Icons.wb_twilight_outlined,
                                  color: AppColors.textSecondaryLight,
                                ),
                                selectedIcon: _selected(
                                  const Icon(
                                    Icons.wb_twilight_rounded,
                                    color: AppColors.dualisNavy,
                                  ),
                                ),
                                label: '',
                                tooltip: habitsLabel,
                              )
                            else
                              NavigationDestination(
                                key: const Key('nav_destination_hydration'),
                                icon: const Icon(
                                  Icons.water_drop_outlined,
                                  color: AppColors.textSecondaryLight,
                                ),
                                selectedIcon: _selected(
                                  const Icon(
                                    Icons.water_drop_rounded,
                                    color: AppColors.dualisNavy,
                                  ),
                                ),
                                label: '',
                                tooltip: hydrationLabel,
                              ),
                            if (showCare)
                              NavigationDestination(
                                key: const Key('nav_destination_care'),
                                icon: _careGlyph(
                                  const Icon(
                                    Icons.favorite_border_rounded,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                                selectedIcon: _careGlyph(
                                  _selected(
                                    const Icon(
                                      Icons.favorite_rounded,
                                      color: AppColors.dualisNavy,
                                    ),
                                  ),
                                ),
                                label: '',
                                tooltip:
                                    careLocked
                                        ? (l10n?.navCareLockedTooltip ??
                                            careLabel)
                                        : careLabel,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: emergencyLabel,
              child: Semantics(
                button: true,
                label: emergencyLabel,
                excludeSemantics: true,
                child: Material(
                  key: const Key('nav_destination_emergency'),
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onEmergencyTap,
                    customBorder: const CircleBorder(),
                    child: _emergencyGlyph(Icons.emergency_outlined),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _barHeight = 62;

  Widget _selected(Icon icon) {
    return premiumIcons
        ? PremiumGradientIcon(icon: icon, showActiveDot: true)
        : icon;
  }

  Widget _careGlyph(Widget icon) {
    if (!careLocked) return icon;
    return Badge(
      key: const Key('nav_care_pro_badge'),
      offset: const Offset(14, -6),
      backgroundColor: AppColors.dualisSymbolBlue,
      label: const Text(
        'PRO',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      child: icon,
    );
  }

  Widget _emergencyGlyph(IconData icon) {
    return Container(
      width: _barHeight,
      height: _barHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.emergencyCrimson,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyCrimson.withValues(alpha: 0.6),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Icon(icon, size: 26, color: Colors.white),
    );
  }
}
