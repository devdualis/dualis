import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/motion.dart';
import '../../../../shared/widgets/fluent_emoji.dart';

/// Modal header for habit sheets (sleep, movement).
class HabitModalHeader extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final bool saved;
  final String savedLabel;

  const HabitModalHeader({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    this.saved = false,
    this.savedLabel = 'Salvo',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DuotoneIconTile(
          size: 40,
          radius: 12,
          child: Icon(icon, size: 22, color: AppColors.dualisNavy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.clinicalTeal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
        if (saved) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PopIn(
                  child: Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Color(0xFF2E7D32),
                ),
                ),
                const SizedBox(width: 4),
                Text(
                  savedLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        ),
      ],
    );
  }
}

/// Option surface shared by the sleep, yes/no and chip answers:
/// soft navy tint, cyan fill and navy border when picked.
class OptionSurface extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const OptionSurface({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    const radius = 16.0;
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        enabled: onTap != null,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: selected
              ? AppColors.dualisSymbolCyan.withValues(alpha: 0.14)
              : AppColors.dualisNavy.withValues(alpha: 0.04),
          border: Border.all(
            color: selected ? AppColors.dualisNavy : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
      ),
    );
  }
}

class EmojiOptionButton extends StatelessWidget {
  final String sleepKey;
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const EmojiOptionButton({
    super.key,
    required this.sleepKey,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OptionSurface(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SelectPop(
            selected: selected,
            child: FluentEmoji.forSleep(
              sleepKey,
              size: 42,
              fallback: ExcludeSemantics(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.dualisNavy,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class YesNoButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const YesNoButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OptionSurface(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.dualisNavy,
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 6),
            const PopIn(
              child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.dualisNavy,
            ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const ChipOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      selectedColor: AppColors.dualisSymbolCyan.withValues(alpha: 0.14),
      backgroundColor: AppColors.dualisNavy.withValues(alpha: 0.04),
      side: BorderSide(
        color: selected ? AppColors.dualisNavy : Colors.transparent,
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      labelStyle: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: AppColors.dualisNavy,
      ),
    );
  }
}
