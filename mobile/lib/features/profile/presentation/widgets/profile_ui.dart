import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';

/// Small building blocks shared by the profile switcher, the claim sheet, the
/// add-dependent modal and family sharing, in the redesign language (brand
/// pills, duotone icon rows, glass sheet surface, navy code box).

/// Translucent white surface used by the profile bottom sheets (same value as
/// the app bottom sheet theme).
const Color profileSheetFill = Color(0xF7FFFFFF);

/// Rounded top of the profile bottom sheets.
const BorderRadius profileSheetRadius =
    BorderRadius.vertical(top: Radius.circular(30));

/// Short grab handle at the top of a bottom sheet.
class ProfileSheetHandle extends StatelessWidget {
  const ProfileSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.dualisNavy.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Brand pill used for badges and status labels.
class ProfilePill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final int maxLines;

  const ProfilePill(
    this.label, {
    super.key,
    this.color = AppColors.dualisNavy,
    this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase section caption.
class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;

  const ProfileSectionHeader(
    this.title, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 6),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Round tinted icon button (rename, delete, close).
class ProfileRoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  const ProfileRoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.dualisNavy,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size * 0.5),
      color: color,
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: color == AppColors.emergencyCrimson
            ? AppColors.emergencyCrimson.withValues(alpha: 0.10)
            : AppColors.iconTileTint,
        shape: const CircleBorder(),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Tappable row with a duotone icon, title and optional chevron, meant to sit
/// inside a glass group.
class ProfileActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ProfileActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            DuotoneIconTile(
              size: 38,
              radius: 12,
              child: Icon(icon, size: 20, color: AppColors.dualisNavy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft tinted panel with a duotone icon, used for notices and banners.
class ProfileNoticePanel extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const ProfileNoticePanel({
    super.key,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.dualisSymbolBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.dualisSymbolBlue.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DuotoneIconTile(
            size: 32,
            radius: 10,
            background: Colors.white.withValues(alpha: 0.8),
            child: Icon(icon, size: 18, color: AppColors.dualisNavy),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Navy code box with big letter-spaced code text.
class ProfileCodeBox extends StatelessWidget {
  final Widget child;

  const ProfileCodeBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: child),
    );
  }
}

/// Style of the text inside a [ProfileCodeBox].
TextStyle profileCodeTextStyle() => GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: 3,
      color: Colors.white,
    );

/// Option surface in the check-in wizard style: white and rounded with a soft
/// shadow; selected is a navy border over a cyan tint.
BoxDecoration profileOptionDecoration({
  required bool selected,
  double radius = 18,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: selected
        ? AppColors.dualisSymbolCyan.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.86),
    border: Border.all(
      color: selected
          ? AppColors.dualisNavy
          : AppColors.dualisNavy.withValues(alpha: 0.08),
      width: selected ? 2 : 1,
    ),
    boxShadow: selected
        ? null
        : [
            BoxShadow(
              color: AppColors.dualisNavy.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: -12,
            ),
          ],
  );
}
