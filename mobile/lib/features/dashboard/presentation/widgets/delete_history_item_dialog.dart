import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/triage_history_models.dart';
import 'retrospective_list_view.dart';

/// Modal dialog for confirming the permanent deletion / discarding of a triage history record.
class DeleteHistoryItemDialog extends StatefulWidget {
  final TriageHistoryEntry entry;
  final Future<bool> Function(String id)? onDelete;

  const DeleteHistoryItemDialog({
    super.key,
    required this.entry,
    this.onDelete,
  });

  static Future<bool?> show(
    BuildContext context, {
    required TriageHistoryEntry entry,
    Future<bool> Function(String id)? onDelete,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DeleteHistoryItemDialog(
        entry: entry,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<DeleteHistoryItemDialog> createState() => _DeleteHistoryItemDialogState();
}

class _DeleteHistoryItemDialogState extends State<DeleteHistoryItemDialog> {
  bool _isDeleting = false;

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }

  Future<void> _handleConfirm() async {
    if (widget.onDelete == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final success = await widget.onDelete!(widget.entry.id);

    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    final intensityColor = RetrospectiveListView.getIntensityColor(widget.entry.intensity);
    final categoryText = RetrospectiveListView.formatCategory(widget.entry);

    final rawNarrative = widget.entry.narrative ??
        widget.entry.stepAnswers?['naturalLanguageText'] as String? ??
        widget.entry.stepAnswers?['narrative'] as String? ??
        widget.entry.stepAnswers?['causes'] as String? ??
        widget.entry.stepAnswers?['gatilhos'] as String? ??
        widget.entry.stepAnswers?['motivo'] as String?;

    final narrativeSnippet = (rawNarrative != null &&
            rawNarrative.trim().isNotEmpty &&
            int.tryParse(rawNarrative.trim()) == null)
        ? rawNarrative.trim()
        : null;

    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Danger Icon Circular Badge
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.emergencyCrimson.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.emergencyCrimson,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Dialog Title
            Text(
              l10n?.deleteHistoryItemTitle ?? 'Descartar Registro',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Explanation Message
            Text(
              l10n?.deleteHistoryItemConfirm ??
                  'Tem certeza de que deseja descartar este registro de triagem do seu histórico? Esta ação é irreversível.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: subtitleColor,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // Record Snapshot Card Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13.5,
                        color: subtitleColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateTime(widget.entry.recordedAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: intensityColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Nível ${widget.entry.intensity}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: intensityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (narrativeSnippet != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"$narrativeSnippet"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Actions: Cancel & Confirm Discard
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      onPressed: _isDeleting ? null : () => Navigator.of(context).pop(null),
                      child: Text(
                        l10n?.cancel ?? 'Cancelar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      key: const Key('confirm_delete_history_item_button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emergencyCrimson,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isDeleting ? null : _handleConfirm,
                      child: _isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l10n?.deleteAction ?? 'Descartar',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
