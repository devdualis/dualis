import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Shared look of the "Meus cuidados" screens (docs/design/premium-v2).
abstract final class CareColors {
  static const amberBg = Color(0xFFFFF8E1);
  static const amber = Color(0xFFB26A00);
  static const greenBg = Color(0xFFE8F5E9);
  static const green = Color(0xFF2E7D32);
  static const slateBg = Color(0xFFF1F5F9);
  static const slate = Color(0xFF334155);
}

TextStyle careTitle([double size = 15]) =>
    GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight);

TextStyle careBody([double size = 13]) =>
    GoogleFonts.plusJakartaSans(fontSize: size, color: AppColors.textSecondaryLight, height: 1.35);

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
    return Material(
      color: color ?? AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor ?? (dashed ? AppColors.clinicalTeal.withValues(alpha: 0.4) : AppColors.outlineLight)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: child),
      ),
    );
  }
}

class CareIconTile extends StatelessWidget {
  const CareIconTile(this.icon, {super.key, this.background = AppColors.clinicalTealLight, this.foreground = AppColors.clinicalTealDark});

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(13)),
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
    return CareCard(
      onTap: onTap,
      color: color,
      borderColor: borderColor,
      child: Row(
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
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
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
      PillTone.neutral => (CareColors.slateBg, const Color(0xFF475569)),
      PillTone.blue => (AppColors.clinicalTealLight, AppColors.clinicalTealDark),
      PillTone.amber => (CareColors.amberBg, CareColors.amber),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
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
        decoration: BoxDecoration(color: CareColors.slateBg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondaryLight),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: careBody(12).copyWith(color: const Color(0xFF475569)))),
          ],
        ),
      );
}

class CareSection extends StatelessWidget {
  const CareSection(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 8, bottom: 2), child: Text(title, style: careTitle()));
}

class CareEmpty extends StatelessWidget {
  const CareEmpty(this.text, {super.key, this.icon = Icons.inbox_outlined});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: careBody(14)),
          ],
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
      borderRadius: BorderRadius.circular(12),
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
        child: Text(value == null ? '—' : careDate(context, value!), style: GoogleFonts.plusJakartaSans(fontSize: 15)),
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
    backgroundColor: AppColors.surfaceLight,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
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
PreferredSizeWidget careAppBar(BuildContext context, String title, {List<Widget> actions = const []}) {
  return AppBar(
    backgroundColor: AppColors.surfaceLight,
    elevation: 0,
    scrolledUnderElevation: 1,
    title: Text(title, style: careTitle(19)),
    // Space for the global urgent-help button (UrgentHelpOverlay).
    actions: [...actions, const SizedBox(width: 56)],
  );
}
