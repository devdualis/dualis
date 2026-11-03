import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/domain/models/share_category.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../care_routes.dart';
import '../widgets/care_widgets.dart';

/// Shows the original document inside the app: the photo, or the PDF pages as
/// images, with zoom. A PDF can also be shared from there.
Future<void> openOriginalDocument(BuildContext context, WidgetRef ref, CareDocument doc) async {
  final l10n = AppLocalizations.of(context);
  try {
    final bytes = await ref.read(careDocumentFileProvider(doc.id).future);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => OriginalDocumentScreen(bytes: bytes, isPdf: doc.isPdf),
    ));
  } catch (_) {
    if (context.mounted) careSnack(context, l10n.careLoadError);
  }
}

class OriginalDocumentScreen extends StatefulWidget {
  const OriginalDocumentScreen({super.key, required this.bytes, required this.isPdf});
  final Uint8List bytes;
  final bool isPdf;

  @override
  State<OriginalDocumentScreen> createState() => _OriginalDocumentScreenState();
}

class _OriginalDocumentScreenState extends State<OriginalDocumentScreen> {
  final List<Uint8List> _pages = [];
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isPdf) _load();
  }

  /// Pages arrive one by one; leaving the screen ends the loop (and the rendering).
  Future<void> _load() async {
    try {
      // 150 dpi keeps small print readable when zoomed, without heavy memory use.
      await for (final page in Printing.raster(widget.bytes, dpi: 150)) {
        final png = await page.toPng();
        if (!mounted) return;
        setState(() => _pages.add(png));
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _share() async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(widget.bytes, mimeType: 'application/pdf', name: 'exame.pdf')],
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.careExamOriginalTitle),
        actions: [
          if (widget.isPdf)
            TextButton.icon(
              onPressed: _share,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.ios_share),
              label: Text(l10n.careExamOriginalShare),
            ),
        ],
      ),
      body: !widget.isPdf
          ? InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(widget.bytes)))
          : _failed
              ? Center(child: Text(l10n.careLoadError, style: const TextStyle(color: Colors.white)))
              : _pages.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : InteractiveViewer(
                      maxScale: 6,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => Image.memory(_pages[i], key: Key('original_page_$i')),
                      ),
                    ),
    );
  }
}

/// Sends the stored file through the reader again, then returns to the list,
/// which shows it as "reading" until it finishes. With [asExam] the file is
/// read as an exam (a lab report uploaded as a prescription).
class ReprocessDocumentButton extends ConsumerStatefulWidget {
  const ReprocessDocumentButton({super.key, required this.documentId, this.asExam = false});
  final String documentId;
  final bool asExam;

  @override
  ConsumerState<ReprocessDocumentButton> createState() => _ReprocessDocumentButtonState();
}

class _ReprocessDocumentButtonState extends ConsumerState<ReprocessDocumentButton> {
  bool _busy = false;

  Future<void> _reprocess() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(careActionsProvider).reprocess(widget.documentId, kind: widget.asExam ? DocumentKind.lab : null);
      if (!mounted) return;
      careSnack(context, widget.asExam ? l10n.careReadingAsExam : l10n.careReadingAgain);
      await Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) careSnack(context, l10n.careSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      key: Key(widget.asExam ? 'document_reprocess_as_exam' : 'document_reprocess'),
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(46)),
      onPressed: _busy ? null : _reprocess,
      icon: _busy
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(widget.asExam ? Icons.science_outlined : Icons.refresh),
      label: Text(widget.asExam ? l10n.careReadAsExam : l10n.careReadAgain),
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

/// Asks about a reading that holds the same exams as another document of the profile.
/// Nothing is removed unless the person chooses "Discard this one".
class PossibleDuplicateCard extends ConsumerWidget {
  const PossibleDuplicateCard({super.key, required this.doc, required this.onKeep});
  final CareDocument doc;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final otherId = doc.possibleDuplicateOf!;
    return CareCard(
      key: const Key('exam_possible_duplicate'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CareNote(l10n.careExamPossibleDuplicate, icon: Icons.content_copy_outlined),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('duplicate_see_other'),
              onPressed: () => context.push(CarePaths.examReview(otherId)),
              child: Text(l10n.careExamDuplicateSeeOther),
            ),
          ),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('duplicate_discard'),
                style: OutlinedButton.styleFrom(foregroundColor: CareColors.slate, minimumSize: const Size.fromHeight(46)),
                onPressed: () async {
                  if (!await confirmCareDelete(context)) return;
                  await ref.read(careActionsProvider).deleteDocument(doc.id);
                  if (context.mounted) await Navigator.of(context).maybePop();
                },
                child: Text(l10n.careExamDuplicateDiscard),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                key: const Key('duplicate_keep'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(46)),
                onPressed: onKeep,
                child: Text(l10n.careExamDuplicateKeep),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// One exam of the document: its heading and its items, in printed order.
class _Group {
  _Group(this.section);
  final String? section;
  final List<_Item> items = [];

  /// One item named like its exam ("Ferritina" under "FERRITINA"): the name is shown once.
  bool get single => items.length == 1 && (section == null || items.first.name.toLowerCase() == section!.toLowerCase());
  String? get title => single ? items.first.name : section;
}

/// One analyte and its results (for example % and /mm³), as indexes into the rows.
class _Item {
  _Item(this.name);
  final String name;
  final List<int> rows = [];
}

List<_Group> _groupsOf(List<ExamValue> rows) {
  final groups = <_Group>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (groups.isEmpty || groups.last.section != row.section) groups.add(_Group(row.section));
    final items = groups.last.items;
    if (items.isEmpty || items.last.name.toLowerCase() != row.item.toLowerCase()) items.add(_Item(row.item));
    items.last.rows.add(i);
  }
  return groups;
}

/// A transcribed lab report, checked against the original. Values and references are
/// the lab's; there are no colours, arrows or judgments. The person compares, fixes what
/// differs and confirms everything at once (every saved value is marked confirmed).
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
  /// The person answered "keep both" to the possible-duplicate question (saving clears it on the server).
  bool _keepBoth = false;
  /// Something changed in an exam that was already confirmed.
  bool _dirty = false;
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  final _groupKeys = <GlobalKey>[];
  /// The exam at the top of the screen, for the "Exame 2 de 11" bar.
  final _current = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackCurrent);
  }

  @override
  void dispose() {
    _title.dispose();
    _lab.dispose();
    _scroll.dispose();
    _current.dispose();
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

  void _trackCurrent() {
    final viewport = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) return;
    final top = viewport.localToGlobal(Offset.zero).dy + 48;
    var current = 0;
    for (var i = 0; i < _groupKeys.length; i++) {
      final box = _groupKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.attached && box.localToGlobal(Offset.zero).dy <= top) current = i;
    }
    _current.value = current;
  }

  Future<void> _chooseGroup(List<_Group> groups) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showCareSheet<int>(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.careExamJumpTitle, style: careTitle(19)),
          const SizedBox(height: 8),
          for (var i = 0; i < groups.length; i++)
            ListTile(
              key: Key('exam_jump_$i'),
              contentPadding: EdgeInsets.zero,
              minTileHeight: 52,
              title: Text(groups[i].title ?? '', style: careTitle()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx, i),
            ),
        ],
      ),
    );
    final target = picked == null ? null : _groupKeys[picked].currentContext;
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300));
    }
  }

  /// Fix ([index]) or add (null) one value. Values the person writes count as confirmed.
  Future<void> _editRow(int? index) async {
    final l10n = AppLocalizations.of(context);
    final row = index == null ? const ExamValue(item: '', value: '') : _rows![index];
    final item = TextEditingController(text: row.item);
    final value = TextEditingController(text: row.value);
    final unit = TextEditingController(text: row.unit);
    final reference = TextEditingController(text: row.reference);
    const remove = ExamValue(item: '', value: '');
    final result = await showCareSheet<ExamValue>(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(index == null ? l10n.careExamAddRow : l10n.careExamFixTitle(row.item), style: careTitle(19)),
          const SizedBox(height: 4),
          Text(l10n.careExamFixHint, style: careBody()),
          const SizedBox(height: 14),
          CareField(fieldKey: const Key('row_item'), controller: item, label: l10n.careExamItem, maxLength: 120),
          const SizedBox(height: 10),
          CareField(fieldKey: const Key('row_value'), controller: value, label: l10n.careExamValue, maxLength: 60),
          const SizedBox(height: 10),
          CareField(controller: unit, label: l10n.careExamUnit, maxLength: 30),
          const SizedBox(height: 10),
          CareField(controller: reference, label: l10n.careExamReference, maxLength: 200, maxLines: 3),
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('row_save'),
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
            TextButton.icon(
              key: const Key('row_remove'),
              style: TextButton.styleFrom(foregroundColor: AppColors.emergencyDarkRed, minimumSize: const Size.fromHeight(46)),
              onPressed: () => Navigator.pop(ctx, remove),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.careExamRowRemove),
            ),
          ],
        ],
      ),
    );
    if (result == null || !mounted) return;
    if (identical(result, remove)) {
      final removed = _rows!.removeAt(index!);
      setState(() => _dirty = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.careExamRowRemoved),
          action: SnackBarAction(
            key: const Key('row_undo'),
            label: l10n.gxUndo,
            onPressed: () => setState(() => _rows!.insert(index.clamp(0, _rows!.length), removed)),
          ),
        ));
      return;
    }
    setState(() {
      _dirty = true;
      if (index == null) {
        _rows!.add(result);
      } else {
        _rows![index] = result;
      }
    });
  }

  Future<void> _editDetails() async {
    final l10n = AppLocalizations.of(context);
    final title = TextEditingController(text: _title.text);
    final lab = TextEditingController(text: _lab.text);
    var collected = _collected;
    final saved = await showCareSheet<bool>(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.careExamDetails, style: careTitle(19)),
            const SizedBox(height: 14),
            CareField(controller: title, label: l10n.careExamTitleField, maxLength: 120),
            const SizedBox(height: 10),
            CareField(controller: lab, label: l10n.careExamLab, maxLength: 120),
            const SizedBox(height: 10),
            CareDateField(
              label: l10n.careExamCollected,
              value: collected,
              onChanged: (d) => setSheet(() => collected = d),
              lastDate: DateTime.now(),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('details_save'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(50)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.careExamRowSave),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    setState(() {
      _title.text = title.text.trim();
      _lab.text = lab.text.trim();
      _collected = collected;
      _dirty = true;
    });
  }

  Future<void> _confirmAll(int count) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.careExamConfirmTitle(count), style: careTitle(19)),
        content: Text(l10n.careExamConfirmBody, style: careBody()),
        actions: [
          TextButton(key: const Key('exam_confirm_back'), onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.careExamConfirmBack)),
          FilledButton(
            key: const Key('exam_confirm_yes'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.careExamConfirmYes),
          ),
        ],
      ),
    );
    if (ok == true) await _save();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(careActionsProvider).review(widget.documentId, {
        if (_title.text.trim().isNotEmpty) 'title': _title.text.trim(),
        if (_lab.text.trim().isNotEmpty) 'labName': _lab.text.trim(),
        if (_collected != null) 'collectedOn': isoDay(_collected!),
        // Saving is the person's confirmation that every value matches the original.
        'values': _rows!.map((r) => r.copyWith(confirmed: true).toJson()).toList(),
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

  Widget _result(int index, bool canEdit) {
    final l10n = AppLocalizations.of(context);
    final row = _rows![index];
    // Non-breaking spaces keep "1.938 /mm³" on one line.
    final printed = [row.value, if (row.unit != null && row.unit!.isNotEmpty) row.unit!].join(' ').replaceAll(' ', ' ');
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(printed, key: Key('row_value_$index'), style: careTitle().copyWith(color: AppColors.dualisNavy)),
        if (row.reference != null && row.reference!.isNotEmpty) _Reference(l10n.careExamReferenceLabel(row.reference!)),
      ],
    );
    if (!canEdit) return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: info);
    final fix = TextButton.icon(
      key: Key('row_fix_$index'),
      style: TextButton.styleFrom(foregroundColor: AppColors.dualisNavy, minimumSize: const Size(0, 40)),
      onPressed: () => _editRow(index),
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: Text(l10n.careExamFix),
    );
    // With large system text the button goes under the value instead of squeezing it.
    final roomy = MediaQuery.textScalerOf(context).scale(10) <= 13;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: roomy
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: info), const SizedBox(width: 8), fix])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, const SizedBox(height: 6), fix]),
    );
  }

  Widget _group(int i, _Group group, bool canEdit) {
    return Container(
      key: _groupKeys[i],
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (group.single)
            Text(group.title!, key: Key('exam_group_$i'), style: careTitle())
          else if (group.section != null)
            Text(group.section!.toUpperCase(), key: Key('exam_group_$i'), style: careTitle(12).copyWith(color: CareColors.slate, letterSpacing: 0.5)),
          for (var j = 0; j < group.items.length; j++) ...[
            if (j > 0) const Divider(height: 20),
            if (!group.single) ...[
              SizedBox(height: j == 0 && group.section != null ? 10 : 0),
              Text(group.items[j].name, style: careTitle()),
            ],
            for (final r in group.items[j].rows) _result(r, canEdit),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = activeProfileCanWrite(ref, ShareCategory.care);
    final async = ref.watch(careDocumentProvider(widget.documentId));
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: careAppBar(context, l10n.careExamReviewTitle, actions: [
        if (canEdit) IconButton(tooltip: l10n.careDelete, onPressed: _delete, icon: const Icon(Icons.delete_outline)),
      ]),
      body: CareAsync<CareDocument>(
        value: async,
        onRetry: () => ref.invalidate(careDocumentProvider(widget.documentId)),
        data: (doc) {
          _init(doc);
          final rows = _rows!;
          final groups = _groupsOf(rows);
          while (_groupKeys.length < groups.length) {
            _groupKeys.add(GlobalKey());
          }
          final archiveOnly = doc.status == DocumentStatus.archived;
          final reading = doc.status == DocumentStatus.review || doc.status == DocumentStatus.failed;
          final confirm = canEdit && !archiveOnly && reading && rows.isNotEmpty;
          final saveChanges = canEdit && doc.status == DocumentStatus.ready && _dirty;
          // Asked only while the other document still exists.
          final otherExists = ref.watch(careDocumentsProvider).value?.any((d) => d.id == doc.possibleDuplicateOf) ?? false;
          final askDuplicate = canEdit && !_keepBoth && doc.status == DocumentStatus.review && otherExists;
          final details = [
            if (_lab.text.trim().isNotEmpty) _lab.text.trim(),
            if (_collected != null) l10n.careExamCollectedOn(careDate(context, _collected!)),
          ].join(' · ');

          return Column(children: [
            if (!archiveOnly && groups.length > 1)
              Material(
                color: AppColors.surfaceLight,
                child: InkWell(
                  key: const Key('exam_progress'),
                  onTap: () => _chooseGroup(groups),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                    child: Row(children: [
                      Expanded(
                        child: ValueListenableBuilder<int>(
                          valueListenable: _current,
                          builder: (_, i, _) {
                            final at = i.clamp(0, groups.length - 1);
                            return Text(l10n.careExamProgress(at + 1, groups.length, groups[at].title ?? ''), style: careTitle(13));
                          },
                        ),
                      ),
                      const Icon(Icons.expand_more, color: AppColors.dualisNavy),
                    ]),
                  ),
                ),
              ),
            Expanded(
              child: KeyedSubtree(
                key: _viewportKey,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (confirm && doc.status == DocumentStatus.review)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.brandBgLightBlue, borderRadius: BorderRadius.circular(18)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l10n.careExamCompareTitle, style: careTitle()),
                            const SizedBox(height: 6),
                            Text(l10n.careExamCompareBody, style: careBody()),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              key: const Key('exam_original'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.dualisNavy,
                                minimumSize: const Size(0, 44),
                                side: const BorderSide(color: AppColors.dualisNavy),
                              ),
                              onPressed: () => openOriginalDocument(context, ref, doc),
                              icon: Icon(doc.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined),
                              label: Text(l10n.careExamSeeOriginal),
                            ),
                          ]),
                        )
                      else
                        CareRow(
                          key: const Key('exam_original'),
                          leading: CareIconTile(doc.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                              background: CareColors.slateBg, foreground: CareColors.slate),
                          title: l10n.careExamSeeOriginal,
                          subtitle: archiveOnly ? l10n.careExamArchivedHint : l10n.careExamCompareHint,
                          onTap: () => openOriginalDocument(context, ref, doc),
                        ),
                      if (doc.status == DocumentStatus.failed) ...[const SizedBox(height: 10), CareNote(l10n.careExamFailedHint)],
                      if (askDuplicate) ...[
                        const SizedBox(height: 10),
                        PossibleDuplicateCard(doc: doc, onKeep: () => setState(() => _keepBoth = true)),
                      ],
                      if (!archiveOnly) ...[
                        const SizedBox(height: 16),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (_title.text.trim().isNotEmpty) Text(_title.text.trim(), key: const Key('exam_title'), style: careTitle()),
                              Text(details.isEmpty ? l10n.careExamDetailsMissing : details, style: careBody()),
                              if (groups.isNotEmpty) Text(l10n.careExamSummary(groups.length, rows.length), style: careBody()),
                            ]),
                          ),
                          if (canEdit)
                            TextButton(
                              key: const Key('exam_details_fix'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.dualisNavy, minimumSize: const Size(0, 40)),
                              onPressed: _editDetails,
                              child: Text(l10n.careExamFix),
                            ),
                        ]),
                        const SizedBox(height: 12),
                        for (var i = 0; i < groups.length; i++) _group(i, groups[i], canEdit),
                        if (rows.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.careExamNoRows, style: careBody())),
                        if (canEdit)
                          OutlinedButton.icon(
                            key: const Key('exam_add_row'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(46)),
                            onPressed: () => _editRow(null),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.careExamAddRow),
                          ),
                        const SizedBox(height: 14),
                        CareNote(l10n.careExamNote),
                      ],
                      if (canEdit) ...[const SizedBox(height: 14), DocumentActions(doc: doc)],
                    ],
                  ),
                ),
              ),
            ),
            if (confirm || saveChanges)
              Material(
                color: AppColors.surfaceLight,
                elevation: 8,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      FilledButton.icon(
                        key: const Key('exam_save'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(50)),
                        onPressed: _busy ? null : (confirm ? () => _confirmAll(rows.length) : _save),
                        icon: Icon(confirm ? Icons.check_circle_outline : Icons.save_outlined),
                        label: Text(confirm ? l10n.careExamConfirmAll : l10n.careExamSaveChanges),
                      ),
                      if (confirm) ...[
                        const SizedBox(height: 6),
                        Text(l10n.careExamConfirmAllHint, style: careBody(12), textAlign: TextAlign.center),
                      ],
                    ]),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

/// A printed reference: two lines, then "Ver referência completa" (some labs print
/// a range for every age group).
class _Reference extends StatefulWidget {
  const _Reference(this.text);
  final String text;

  @override
  State<_Reference> createState() => _ReferenceState();
}

class _ReferenceState extends State<_Reference> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = careBody(12);
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: 2,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final long = painter.didExceedMaxLines;
      painter.dispose();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.text, style: style, maxLines: long && !_open ? 2 : null, overflow: long && !_open ? TextOverflow.ellipsis : null),
        if (long)
          TextButton(
            key: const Key('reference_more'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36), foregroundColor: AppColors.dualisNavy),
            onPressed: () => setState(() => _open = !_open),
            child: Text(_open ? l10n.careExamReferenceLess : l10n.careExamReferenceMore, style: careTitle(12).copyWith(color: AppColors.dualisNavy)),
          ),
      ]);
    });
  }
}
