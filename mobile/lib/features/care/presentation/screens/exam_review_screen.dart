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

  @override
  void dispose() {
    _title.dispose();
    _lab.dispose();
    super.dispose();
  }

  void _init(CareDocument doc) {
    if (_rows != null) return;
    _rows = doc.values;
    _title.text = doc.title ?? '';
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
              if (!archiveOnly) ...[
                const SizedBox(height: 12),
                CareField(controller: _title, label: l10n.careExamTitleField, maxLength: 120),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: CareField(controller: _lab, label: l10n.careExamLab, maxLength: 120)),
                  const SizedBox(width: 10),
                  Expanded(child: CareDateField(label: l10n.careExamCollected, value: _collected, onChanged: (d) => setState(() => _collected = d), lastDate: DateTime.now())),
                ]),
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
                      for (var i = 0; i < rows.length; i++)
                        InkWell(
                          onTap: canEdit ? () => _editRow(i) : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(children: [
                              Expanded(flex: 4, child: Text(rows[i].item, style: careTitle(13))),
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
