import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Semantic tones of the "Meus cuidados" screens, built from brand tokens:
/// amber is a warning, green is ok, slate is neutral (navy on the cyan tint).
abstract final class CareColors {
  static const amberBg = AppColors.intensityMildBg;
  static const amber = AppColors.intensityMildText;
  // 16% of dualisSymbolGreen; the text shade is a dark green for contrast on it.
  static const greenBg = Color(0x2966BE71);
  static const green = Color(0xFF2E7D32);
  static const slateBg = AppColors.iconTileTint;
  static const slate = AppColors.dualisNavy;
}

TextStyle careTitle([double size = 15]) =>
    GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w700, letterSpacing: -0.1, color: AppColors.textPrimaryLight);

TextStyle careBody([double size = 13]) =>
    GoogleFonts.inter(fontSize: size, color: AppColors.textSecondaryLight, height: 1.35);

String careDate(BuildContext context, DateTime date) =>
    DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).format(date.toLocal());

/// A date-only field ("2026-10-21") as the calendar day it names, never shifted by time zone.
DateTime? careDay(String? iso) => iso == null ? null : DateTime.tryParse(iso.length >= 10 ? iso.substring(0, 10) : iso);

String careTime(DateTime date) => DateFormat.Hm().format(date.toLocal());

String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class CareCard extends StatelessWidget {
  const CareCard({super.key, required this.child, this.onTap, this.color, this.borderColor, this.padding, this.dashed = false});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final inset = padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    if (color != null || borderColor != null || dashed) {
      // Tinted card (warning banner, dashed "add" card): flat fill, no glass.
      return Material(
        color: color ?? AppColors.brandBgLightBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor ?? (dashed ? AppColors.clinicalTeal.withValues(alpha: 0.4) : Colors.transparent)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: inset, child: child)),
      );
    }
    final glass = GlassCard(radius: 22, padding: inset, child: child);
    if (onTap == null) return glass;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: glass),
    );
  }
}

class CareIconTile extends StatelessWidget {
  const CareIconTile(this.icon, {super.key, this.background = AppColors.iconTileTint, this.foreground = AppColors.dualisNavy});

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => DuotoneIconTile(
        background: background,
        child: Icon(icon, color: foreground, size: 22),
      );
}

/// Card row: icon tile, title, subtitle, optional trailing.
class CareRow extends StatelessWidget {
  const CareRow({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.onTap, this.color, this.borderColor});

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final effectiveCrossAlign = (subtitle != null && subtitle!.length > 36)
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;
    return CareCard(
      onTap: onTap,
      color: color,
      borderColor: borderColor,
      child: Row(
        crossAxisAlignment: effectiveCrossAlign,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: careTitle()),
                if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: careBody())],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!]
          else if (onTap != null)
            Padding(
              padding: EdgeInsets.only(top: effectiveCrossAlign == CrossAxisAlignment.start ? 6 : 0),
              child: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
            ),
        ],
      ),
    );
  }
}

enum PillTone { done, neutral, blue, amber }

class CarePill extends StatelessWidget {
  const CarePill(this.label, {super.key, this.tone = PillTone.neutral});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.done => (CareColors.greenBg, CareColors.green),
      PillTone.neutral => (AppColors.dualisNavy.withValues(alpha: 0.08), AppColors.textSecondaryLight),
      PillTone.blue => (AppColors.clinicalTealLight, AppColors.clinicalTealDark),
      PillTone.amber => (CareColors.amberBg, CareColors.amber),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// Grey note with an info icon (fixed disclaimers such as "não verifica conflitos").
class CareNote extends StatelessWidget {
  const CareNote(this.text, {super.key, this.icon = Icons.info_outline_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.dualisNavy.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 18, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: careBody(12))),
          ],
        ),
      );
}

class CareSection extends StatelessWidget {
  const CareSection(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 10, bottom: 2), child: Text(title, style: careTitle(16)));
}

class CareEmpty extends StatelessWidget {
  const CareEmpty(this.text, {super.key, this.icon = Icons.inbox_outlined});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: AppColors.textSecondaryLight.withValues(alpha: 0.6)),
              const SizedBox(height: 8),
              Text(text, textAlign: TextAlign.center, style: careBody(14)),
            ],
          ),
        ),
      );
}

/// Loading / error / data for a list screen; error offers a retry.
class CareAsync<T> extends StatelessWidget {
  const CareAsync({super.key, required this.value, required this.data, required this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return value.when(
      data: data,
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.careLoadError, textAlign: TextAlign.center, style: careBody(14)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: Text(l10n.careRetry)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Labelled text field with the app's rounded style.
const _plain = {'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n'};

/// Lower case without accents, so "hematocrito" finds "Hematócrito".
String foldText(String text) => text.toLowerCase().split('').map((c) => _plain[c] ?? c).join();

class CareField extends StatelessWidget {
  const CareField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.fieldKey,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int maxLines;
  final Key? fieldKey;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        key: fieldKey,
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(labelText: label, counterText: '', filled: true, fillColor: AppColors.surfaceLight),
      );
}

/// Tappable field that opens a date picker; shows [value] formatted.
class CareDateField extends StatelessWidget {
  const CareDateField({super.key, required this.label, required this.value, required this.onChanged, this.firstDate, this.lastDate, this.fieldKey});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: fieldKey,
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime(now.year + 30),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, filled: true, fillColor: AppColors.surfaceLight),
        child: Text(value == null ? '—' : careDate(context, value!), style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimaryLight)),
      ),
    );
  }
}

/// Standard bottom sheet container used by the forms.
Future<T?> showCareSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    // Background and corners come from the glass bottom-sheet theme.
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), child: builder(ctx))),
    ),
  );
}

Future<bool> confirmCareDelete(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.careDeleteTitle),
      content: Text(l10n.careDeleteBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.careCancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.careDelete)),
      ],
    ),
  );
  return ok == true;
}

void careSnack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

/// App bar used by the pushed "Meus cuidados" screens, with the help button.
PreferredSizeWidget careAppBar(BuildContext context, String title, {List<Widget> actions = const [], PreferredSizeWidget? bottom}) {
  return AppBar(
    bottom: bottom,
    backgroundColor: AppColors.backgroundDepth,
    elevation: 0,
    scrolledUnderElevation: 0,
    title: Text(title, style: careTitle(19).copyWith(color: AppColors.dualisNavy)),
    // Space for the global urgent-help button (UrgentHelpOverlay).
    actions: [...actions, const SizedBox(width: 56)],
  );
}
