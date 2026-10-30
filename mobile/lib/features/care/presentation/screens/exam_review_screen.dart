import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../widgets/care_widgets.dart';

/// Shows the original document (photo inline; PDF through the system viewer).
Future<void> openOriginalDocument(BuildContext context, WidgetRef ref, CareDocument doc) async {
  final l10n = AppLocalizations.of(context);
  try {
    final bytes = await ref.read(careDocumentFileProvider(doc.id).future);
    if (!context.mounted) return;
    if (doc.isPdf) {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: 'documento.pdf')],
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(bytes))),
      ),
    ));
  } catch (_) {
    if (context.mounted) careSnack(context, l10n.careLoadError);
  }
}

/// Sends the stored file through the reader again, then returns to the list,
/// which shows it as "reading" until it finishes.
class ReprocessDocumentButton extends ConsumerStatefulWidget {
  const ReprocessDocumentButton({super.key, required this.documentId});
  final String documentId;

  @override
  ConsumerState<ReprocessDocumentButton> createState() => _ReprocessDocumentButtonState();
}

class _ReprocessDocumentButtonState extends ConsumerState<ReprocessDocumentButton> {
  bool _busy = false;

  Future<void> _reprocess() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(careActionsProvider).reprocess(widget.documentId);
      if (!mounted) return;
      careSnack(context, l10n.careReadingAgain);
      await Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) careSnack(context, l10n.careSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('document_reprocess'),
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(46)),
      onPressed: _busy ? null : _reprocess,
      icon: _busy
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.refresh),
      label: Text(AppLocalizations.of(context).careReadAgain),
    );
  }
}

/// Asks first, deletes the document and returns to the list.
class DeleteDocumentButton extends ConsumerWidget {
  const DeleteDocumentButton({super.key, required this.documentId});
  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      key: const Key('document_delete'),
      style: OutlinedButton.styleFrom(foregroundColor: CareColors.slate, minimumSize: const Size.fromHeight(46)),
      onPressed: () async {
        if (!await confirmCareDelete(context)) return;
        await ref.read(careActionsProvider).deleteDocument(documentId);
        if (context.mounted) await Navigator.of(context).maybePop();
      },
      icon: const Icon(Icons.delete_outline),
      label: Text(AppLocalizations.of(context).careDelete),
    );
  }
}

/// "Read again" (when the reading can still change) and "Delete", side by side.
class DocumentActions extends StatelessWidget {
  const DocumentActions({super.key, required this.doc});
  final CareDocument doc;

  @override
  Widget build(BuildContext context) {
    final canReread = doc.status == DocumentStatus.failed || doc.status == DocumentStatus.review;
    return Row(children: [
      if (canReread) ...[Expanded(flex: 3, child: ReprocessDocumentButton(documentId: doc.id)), const SizedBox(width: 10)],
      Expanded(flex: 2, child: DeleteDocumentButton(documentId: doc.id)),
    ]);
  }
}

/// Row-by-row check of a transcribed lab report. Values and references are the
/// lab's; there are no colours, arrows or judgments, and saving needs every
/// row confirmed.
class ExamReviewScreen extends ConsumerStatefulWidget {
  const ExamReviewScreen({super.key, required this.documentId});
  final String documentId;

  @override
  ConsumerState<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends ConsumerState<ExamReviewScreen> {
  List<ExamValue>? _rows;
  final _title = TextEditingController();
  final _lab = TextEditingController();
  DateTime? _collected;
  bool _busy = false;
  /// Section headings, to jump from the exam chips to each exam.
  final _sectionKeys = <String, GlobalKey>{};

  @override
  void dispose() {
    _title.dispose();
    _lab.dispose();
    super.dispose();
  }

  void _init(CareDocument doc) {
    if (_rows != null) return;
    _rows = doc.values;
    // A document can hold several exams: suggest "First exam + N exams"; the person can change it.
    final sections = doc.sections;
    _title.text = doc.title ??
        switch (sections.length) {
          0 => '',
          1 => sections.first,
          _ => AppLocalizations.of(context).careExamTitleMany(sections.first, sections.length - 1),
        };
    _lab.text = doc.labName ?? '';
    _collected = DateTime.tryParse(doc.collectedOn ?? '');
  }

  Future<void> _editRow(int? index) async {
    final l10n = AppLocalizations.of(context);
    final row = index == null ? const ExamValue(item: '', value: '') : _rows![index];
    final item = TextEditingController(text: row.item);
    final value = TextEditingController(text: row.value);
    final unit = TextEditingController(text: row.unit);
    final reference = TextEditingController(text: row.reference);
    final result = await showCareSheet<ExamValue>(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(index == null ? l10n.careExamAddRow : l10n.careExamEditRow, style: careTitle(19)),
          const SizedBox(height: 12),
          CareField(fieldKey: const Key('row_item'), controller: item, label: l10n.careExamItem, maxLength: 120),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: CareField(fieldKey: const Key('row_value'), controller: value, label: l10n.careExamValue, maxLength: 60)),
            const SizedBox(width: 10),
            Expanded(child: CareField(controller: unit, label: l10n.careExamUnit, maxLength: 30)),
          ]),
          const SizedBox(height: 10),
          CareField(controller: reference, label: l10n.careExamReference, maxLength: 200),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(50)),
            onPressed: () {
              if (item.text.trim().isEmpty || value.text.trim().isEmpty) return;
              Navigator.pop(
                ctx,
                ExamValue(
                  section: row.section,
                  item: item.text.trim(),
                  value: value.text.trim(),
                  unit: unit.text.trim().isEmpty ? null : unit.text.trim(),
                  reference: reference.text.trim().isEmpty ? null : reference.text.trim(),
                  confirmed: true,
                ),
              );
            },
            child: Text(l10n.careExamRowSave),
          ),
          if (index != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(ctx, const ExamValue(item: '', value: '')), child: Text(l10n.careExamRowRemove)),
          ],
        ],
      ),
    );
    if (result == null) return;
    setState(() {
      if (result.item.isEmpty) {
        _rows!.removeAt(index!);
      } else if (index == null) {
        _rows!.add(result);
      } else {
        _rows![index] = result;
      }
    });
  }

  /// Rows [a] and [b] are results of the same item in the same exam.
  static bool _sameItem(List<ExamValue> rows, int a, int b) =>
      b >= 0 && b < rows.length && rows[a].section == rows[b].section && rows[a].item.toLowerCase() == rows[b].item.toLowerCase();

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(careActionsProvider).review(widget.documentId, {
        if (_title.text.trim().isNotEmpty) 'title': _title.text.trim(),
        if (_lab.text.trim().isNotEmpty) 'labName': _lab.text.trim(),
        if (_collected != null) 'collectedOn': isoDay(_collected!),
        'values': _rows!.map((r) => r.toJson()).toList(),
      });
      if (mounted) {
        careSnack(context, l10n.careExamSaved);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) careSnack(context, l10n.careSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmCareDelete(context)) return;
    await ref.read(careActionsProvider).deleteDocument(widget.documentId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = ref.watch(activeProfileControllerProvider).activeProfile?.canEdit ?? true;
    final async = ref.watch(careDocumentProvider(widget.documentId));
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: careAppBar(context, l10n.careExamReviewTitle, actions: [
        if (canEdit) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
      ]),
      body: CareAsync<CareDocument>(
        value: async,
        onRetry: () => ref.invalidate(careDocumentProvider(widget.documentId)),
        data: (doc) {
          _init(doc);
          final rows = _rows!;
          final pending = rows.where((r) => !r.confirmed).length;
          final archiveOnly = doc.status == DocumentStatus.archived;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              CareRow(
                key: const Key('exam_original'),
                leading: CareIconTile(doc.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                    background: CareColors.slateBg, foreground: CareColors.slate),
                title: l10n.careExamSeeOriginal,
                subtitle: archiveOnly ? l10n.careExamArchivedHint : l10n.careExamCompareHint,
                onTap: () => openOriginalDocument(context, ref, doc),
              ),
              if (doc.status == DocumentStatus.failed) ...[const SizedBox(height: 10), CareNote(l10n.careExamFailedHint)],
              if (canEdit) ...[const SizedBox(height: 10), DocumentActions(doc: doc)],
              if (!archiveOnly) ...[
                const SizedBox(height: 12),
                CareField(controller: _title, label: l10n.careExamTitleField, maxLength: 120),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: CareField(controller: _lab, label: l10n.careExamLab, maxLength: 120)),
                  const SizedBox(width: 10),
                  Expanded(child: CareDateField(label: l10n.careExamCollected, value: _collected, onChanged: (d) => setState(() => _collected = d), lastDate: DateTime.now())),
                ]),
                if (doc.sections.length > 1) ...[
                  const SizedBox(height: 14),
                  Text(l10n.careExamSections(doc.sections.length), style: careTitle(13)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final section in doc.sections)
                      ActionChip(
                        label: Text(section, style: careBody(12).copyWith(color: AppColors.dualisNavy)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          final target = _sectionKeys[section]?.currentContext;
                          if (target != null) Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300));
                        },
                      ),
                  ]),
                ],
                const SizedBox(height: 12),
                CareCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(flex: 4, child: Text(l10n.careExamItem, style: careBody(11))),
                        Expanded(flex: 3, child: Text(l10n.careExamValue, style: careBody(11))),
                        Expanded(flex: 3, child: Text(l10n.careExamReferencePrinted, style: careBody(11))),
                        const SizedBox(width: 40),
                      ]),
                      const Divider(),
                      if (rows.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(l10n.careExamNoRows, style: careBody())),
                      for (var i = 0; i < rows.length; i++) ...[
                        if (rows[i].section != null && (i == 0 || rows[i].section != rows[i - 1].section))
                          Padding(
                            // Only the first heading of a section gets the jump key (keys must be unique).
                            key: rows.indexWhere((r) => r.section == rows[i].section) == i ? _sectionKeys.putIfAbsent(rows[i].section!, GlobalKey.new) : null,
                            padding: const EdgeInsets.only(top: 12, bottom: 2),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(rows[i].section!, key: Key('exam_section_$i'), style: careTitle(12).copyWith(color: AppColors.dualisNavy)),
                            ),
                          ),
                        if (_sameItem(rows, i, i + 1) && !_sameItem(rows, i, i - 1))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Align(alignment: Alignment.centerLeft, child: Text(rows[i].item, key: Key('exam_item_$i'), style: careTitle(13))),
                          ),
                        InkWell(
                          onTap: canEdit ? () => _editRow(i) : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(children: [
                              Expanded(
                                flex: 4,
                                // Several results of one item (e.g. % and /mm³) share the name above;
                                // each line can be removed to keep only the one the person wants.
                                child: _sameItem(rows, i, i - 1) || _sameItem(rows, i, i + 1)
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: canEdit
                                            ? IconButton(
                                                key: Key('row_remove_$i'),
                                                tooltip: l10n.careExamRowRemove,
                                                visualDensity: VisualDensity.compact,
                                                icon: Icon(Icons.close, size: 16, color: CareColors.slate.withValues(alpha: 0.55)),
                                                onPressed: () => setState(() => rows.removeAt(i)),
                                              )
                                            : const SizedBox.shrink(),
                                      )
                                    : Text(rows[i].item, style: careTitle(13)),
                              ),
                              Expanded(flex: 3, child: Text([rows[i].value, rows[i].unit].whereType<String>().join(' '), style: careBody(13).copyWith(color: AppColors.textPrimaryLight))),
                              Expanded(flex: 3, child: Text(rows[i].reference ?? '—', style: careBody(12))),
                              SizedBox(
                                width: 40,
                                child: Checkbox(
                                  key: Key('row_confirm_$i'),
                                  shape: const CircleBorder(),
                                  value: rows[i].confirmed,
                                  onChanged: canEdit ? (v) => setState(() => rows[i] = rows[i].copyWith(confirmed: v ?? false)) : null,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                      if (canEdit)
                        TextButton.icon(onPressed: () => _editRow(null), icon: const Icon(Icons.add), label: Text(l10n.careExamAddRow)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                CareNote(l10n.careExamNote),
                const SizedBox(height: 14),
                if (canEdit)
                  FilledButton(
                    key: const Key('exam_save'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(52)),
                    onPressed: _busy || pending > 0 ? null : _save,
                    child: Text(pending > 0 ? l10n.careExamSavePending(pending) : l10n.careSave),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
