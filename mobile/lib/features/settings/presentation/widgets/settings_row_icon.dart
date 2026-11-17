import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';

/// Duotone icon holder used as the leading glyph of every settings row.
class SettingsRowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const SettingsRowIcon(
    this.icon, {
    super.key,
    this.color = AppColors.dualisNavy,
  });

  @override
  Widget build(BuildContext context) {
    return DuotoneIconTile(
      size: 38,
      radius: 12,
      background: color == AppColors.emergencyCrimson
          ? AppColors.emergencyCrimson.withValues(alpha: 0.10)
          : null,
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// Hairline between rows of a grouped card, inset to start under the title.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      endIndent: 16,
      color: AppColors.dualisNavy.withValues(alpha: 0.08),
    );
  }
}
