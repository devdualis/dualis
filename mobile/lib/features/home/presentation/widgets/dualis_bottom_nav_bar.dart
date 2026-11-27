import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/motion.dart';
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
                      child: _SlidingTabs(
                        selectedIndex: currentIndex.clamp(
                          0,
                          emergencyIndex - 1,
                        ),
                        onSelected: onTap,
                        gradientPill: !premiumIcons,
                        tabs: [
                          _TabSpec(
                            key: const Key('nav_destination_home'),
                            icon: Icons.home_outlined,
                            selectedIcon: Icons.home_rounded,
                            label: homeLabel,
                          ),
                          _TabSpec(
                            key: const Key('nav_destination_history'),
                            icon: Icons.insights_outlined,
                            selectedIcon: Icons.insights_rounded,
                            label: _short(historyLabel),
                            tooltip: historyLabel,
                          ),
                          if (habitsTab)
                            _TabSpec(
                              key: const Key('nav_destination_habits'),
                              icon: Icons.wb_twilight_outlined,
                              selectedIcon: Icons.wb_twilight_rounded,
                              label: habitsLabel,
                            )
                          else
                            _TabSpec(
                              key: const Key('nav_destination_hydration'),
                              icon: Icons.water_drop_outlined,
                              selectedIcon: Icons.water_drop_rounded,
                              label: hydrationLabel,
                            ),
                          if (showCare)
                            _TabSpec(
                              key: const Key('nav_destination_care'),
                              icon: Icons.favorite_border_rounded,
                              selectedIcon: Icons.favorite_rounded,
                              label: _short(careLabel),
                              tooltip:
                                  careLocked
                                      ? (l10n?.navCareLockedTooltip ??
                                          careLabel)
                                      : careLabel,
                              locked: careLocked,
                            ),
                        ],
                        premiumIcons: premiumIcons,
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
                  shape: const StadiumBorder(),
                  child: InkWell(
                    onTap: onEmergencyTap,
                    customBorder: const StadiumBorder(),
                    child: _emergencyGlyph(
                      Icons.emergency_outlined,
                      l10n?.navHelpShort ?? 'Ajuda',
                    ),
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

  /// Compact name for the active pill: drops a possessive prefix
  /// ("Meus cuidados" -> "Cuidados") and any "& Mapa" / "y Mapa" suffix. The
  /// full name stays in the tooltip and semantics.
  static String _short(String label) {
    var t = label.split(RegExp(r'\s+(?:&|y)\s+')).first.trim();
    final m = RegExp(
      r'^(?:meus|mis|my)\s+',
      caseSensitive: false,
    ).firstMatch(t);
    if (m != null && t.length > m.end) {
      t = t.substring(m.end);
      t = t[0].toUpperCase() + t.substring(1);
    }
    return t;
  }

  Widget _emergencyGlyph(IconData icon, String label) {
    return Container(
      height: _barHeight,
      constraints: const BoxConstraints(minWidth: _barHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: AppColors.emergencyCrimson,
        shape: const StadiumBorder(),
        shadows: [
          BoxShadow(
            color: AppColors.emergencyCrimson.withValues(alpha: 0.6),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSpec {
  final Key key;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String tooltip;

  /// Shows the "PRO" badge (free build care tab).
  final bool locked;

  const _TabSpec({
    required this.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    String? tooltip,
    this.locked = false,
  }) : tooltip = tooltip ?? label;
}

/// Tab row with one pill that slides under the selected tab. Only the
/// selected tab shows its label; the others are icon-only (name stays in the
/// tooltip / semantics). Animation is skipped when the OS asks to reduce
/// motion.
class _SlidingTabs extends StatelessWidget {
  final List<_TabSpec> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Free build: teal→navy gradient pill with white content. Premium keeps the
  /// light tint so its gradient icon and champagne dot stay visible.
  final bool gradientPill;
  final bool premiumIcons;

  const _SlidingTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required this.gradientPill,
    required this.premiumIcons,
  });

  static const double _selectedWeight = 2.3;
  static const double _pillInset = 3;
  static const double _edgePad = 6;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 380);
    const curve = Curves.easeOutBack;

    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth - _edgePad * 2;
        final unit = total / (tabs.length - 1 + _selectedWeight);
        double left(int i) =>
            _edgePad +
            i * unit +
            (i > selectedIndex ? (_selectedWeight - 1) * unit : 0);
        double width(int i) =>
            i == selectedIndex ? _selectedWeight * unit : unit;

        return SizedBox(
          height: DualisBottomNavBar._barHeight,
          child: Stack(
            children: [
              AnimatedPositioned(
                key: const Key('nav_active_pill'),
                duration: duration,
                curve: curve,
                left: left(selectedIndex) + _pillInset,
                width: width(selectedIndex) - _pillInset * 2,
                top: _pillInset + 2,
                bottom: _pillInset + 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient:
                        gradientPill
                            ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.clinicalTeal,
                                AppColors.dualisNavy,
                              ],
                            )
                            : null,
                    color:
                        gradientPill
                            ? null
                            : AppColors.dualisNavy.withValues(alpha: 0.08),
                  ),
                ),
              ),
              for (var i = 0; i < tabs.length; i++)
                AnimatedPositioned(
                  duration: duration,
                  curve: curve,
                  left: left(i),
                  width: width(i),
                  top: 0,
                  bottom: 0,
                  child: _TabButton(
                    spec: tabs[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                    onGradient: gradientPill,
                    premiumIcons: premiumIcons,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;
  final bool onGradient;
  final bool premiumIcons;

  const _TabButton({
    required this.spec,
    required this.selected,
    required this.onTap,
    required this.onGradient,
    required this.premiumIcons,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected
            ? (onGradient ? Colors.white : AppColors.dualisNavy)
            : AppColors.textSecondaryLight;
    final icon = Icon(
      selected ? spec.selectedIcon : spec.icon,
      key: ValueKey(selected),
      color: color,
      size: 24,
    );
    Widget glyph = IconStateSwitcher(
      child: selected && premiumIcons
          ? PremiumGradientIcon(
              key: const ValueKey('premium'),
              icon: icon,
              showActiveDot: true,
            )
          : icon,
    );
    if (spec.locked) {
      glyph = Badge(
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
        child: glyph,
      );
    }

    return Tooltip(
      message: spec.tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: spec.tooltip,
        excludeSemantics: true,
        child: InkWell(
          key: spec.key,
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: PressScale(
            pressedScale: 0.94,
            child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                glyph,
                if (selected)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          spec.label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
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
