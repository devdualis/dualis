import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../care_routes.dart';
import '../widgets/care_widgets.dart';
import '../widgets/exam_values_list.dart';

const _readingConsentKey = 'care_document_reading_consent_v1';
const _maxBytes = 10 * 1024 * 1024;

/// Exam documents, or prescriptions when [prescriptions] is set (own entry in
/// "Meus cuidados"). Reading only pre-fills: the person checks every value
/// (docs/bienestar/PROPUESTA-CLIENTE-BIENESTAR.md §5).
class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key, this.prescriptions = false});

  final bool prescriptions;

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> {
  Timer? _poll;
  bool _uploading = false;
  /// Swiped away; hidden until the list reloads (a dismissed row must leave the tree).
  final Set<String> _removed = {};

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Polls while a document is being read in the background.
  void _syncPolling(List<CareDocument> docs) {
    final processing = docs.any((d) => d.status == DocumentStatus.processing);
    if (processing && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 3), (_) => ref.invalidate(careDocumentsProvider));
    } else if (!processing && _poll != null) {
      _poll!.cancel();
      _poll = null;
    }
  }

  Future<bool> _ensureConsent() async {
    final storage = ref.read(secureStorageServiceProvider);
    if (await storage.read(key: _readingConsentKey) == 'yes') return true;
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.careReadConsentTitle),
        content: SingleChildScrollView(child: Text(l10n.careReadConsentBody)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.careReadConsentDecline)),
          FilledButton(key: const Key('reading_consent_accept'), onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.careReadConsentAccept)),
        ],
      ),
    );
    if (ok == true) await storage.write(key: _readingConsentKey, value: 'yes');
    return ok == true;
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final source = await showCareSheet<String>(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.prescriptions ? l10n.careRxListAdd : l10n.careExamAdd, style: careTitle(19)),
          const SizedBox(height: 12),
          for (final (key, icon, label) in [
            ('camera', Icons.photo_camera_outlined, l10n.careExamFromCamera),
            ('gallery', Icons.photo_library_outlined, l10n.careExamFromGallery),
            ('pdf', Icons.picture_as_pdf_outlined, l10n.careExamFromPdf),
          ]) ...[
            CareRow(key: Key('exam_source_$key'), leading: CareIconTile(icon), title: label, onTap: () => Navigator.pop(ctx, key)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
    if (source == null || !mounted) return;

    final kind = widget.prescriptions ? 'prescription' : await showCareSheet<String>(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.careExamWhatIsIt, style: careTitle(19)),
          const SizedBox(height: 12),
          for (final (key, icon, title, sub) in [
            ('lab', Icons.science_outlined, l10n.careExamKindLab, l10n.careExamKindLabHint),
            ('archive', Icons.inventory_2_outlined, l10n.careExamKindArchive, l10n.careExamKindArchiveHint),
          ]) ...[
            CareRow(key: Key('exam_kind_$key'), leading: CareIconTile(icon), title: title, subtitle: sub, onTap: () => Navigator.pop(ctx, key)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
    if (kind == null || !mounted) return;
    final read = kind != 'archive';
    if (read && !await _ensureConsent()) return;

    Uint8List? bytes;
    String mime = 'image/jpeg';
    if (source == 'pdf') {
      final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      final file = picked.isEmpty ? null : picked.first;
      bytes = file?.path != null ? await File(file!.path!).readAsBytes() : null;
      mime = 'application/pdf';
    } else {
      final image = await ImagePicker().pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      bytes = await image?.readAsBytes();
    }
    if (bytes == null || !mounted) return;
    if (bytes.length > _maxBytes) {
      careSnack(context, l10n.careExamTooLarge);
      return;
    }

    setState(() => _uploading = true);
    try {
      final doc = await ref.read(careActionsProvider).upload(
            kind: kind == 'prescription' ? DocumentKind.prescription : kind == 'lab' ? DocumentKind.lab : DocumentKind.other,
            mime: mime,
            bytes: bytes,
            read: read,
          );
      // The same file is never stored or read twice: show the one already there.
      if (doc.duplicate && mounted) {
        careSnack(context, l10n.careExamDuplicateFile);
        _open(doc);
      }
    } catch (_) {
      if (mounted) careSnack(context, l10n.careSaveError);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _open(CareDocument d) {
    if (d.status == DocumentStatus.processing) return;
    if (d.kind == DocumentKind.prescription) {
      context.push(CarePaths.prescription(d.id));
    } else {
      context.push(CarePaths.examReview(d.id));
    }
  }

  /// Swipe left to delete (asks first). Also reaches files stuck while being read.
  Widget _swipeToDelete(CareDocument d, bool canEdit, Widget child) {
    if (!canEdit) return child;
    return Dismissible(
      key: Key('doc_swipe_${d.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: CareColors.slateBg, borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.delete_outline, color: CareColors.slate),
      ),
      confirmDismiss: (_) => confirmCareDelete(context),
      onDismissed: (_) async {
        setState(() => _removed.add(d.id));
        try {
          await ref.read(careActionsProvider).deleteDocument(d.id);
        } catch (_) {
          if (!mounted) return;
          setState(() => _removed.remove(d.id));
          careSnack(context, AppLocalizations.of(context).careSaveError);
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = ref.watch(activeProfileControllerProvider).activeProfile?.canEdit ?? true;
    final rxOnly = widget.prescriptions;
    final async = ref.watch(careDocumentsProvider);
    async.whenData((docs) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncPolling(docs);
        }));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: careAppBar(context, rxOnly ? l10n.careExamSectionPrescriptions : l10n.careExamsTitle),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('exams_add'),
              backgroundColor: AppColors.dualisNavy,
              foregroundColor: Colors.white,
              onPressed: _uploading ? null : _add,
              icon: _uploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_a_photo_outlined),
              label: Text(rxOnly ? l10n.careRxListAdd : l10n.careExamAdd),
            )
          : null,
      body: CareAsync<List<CareDocument>>(
        value: async,
        onRetry: () => ref.invalidate(careDocumentsProvider),
        data: (all) {
          final docs = all
              .where((d) => !_removed.contains(d.id) && (d.kind == DocumentKind.prescription) == rxOnly)
              .toList();
          final processing = docs.where((d) => d.status == DocumentStatus.processing).toList();
          final labs = docs.where((d) => d.kind == DocumentKind.lab && d.status != DocumentStatus.processing).toList();
          final rx = docs.where((d) => d.kind == DocumentKind.prescription && d.status != DocumentStatus.processing).toList();
          final other = docs.where((d) => d.kind == DocumentKind.other).toList();
          final checked = labs.where((doc) => doc.status == DocumentStatus.ready && doc.values.isNotEmpty).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final d in processing) ...[
                _swipeToDelete(
                  d,
                  canEdit,
                  CareRow(
                    color: AppColors.softIndigoLight,
                    borderColor: const Color(0xFFC9DDF0),
                    leading: const CareIconTile(Icons.sync, background: Colors.white, foreground: AppColors.dualisNavy),
                    title: l10n.careExamReading,
                    subtitle: l10n.careExamReadingHint,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (docs.isEmpty)
                rxOnly
                    ? CareEmpty(l10n.careRxListEmpty, icon: Icons.receipt_long_outlined)
                    : CareEmpty(l10n.careExamEmpty, icon: Icons.science_outlined),
              if (labs.isNotEmpty) CareSection(l10n.careExamSectionLabs),
              for (final d in labs) ...[const SizedBox(height: 8), _swipeToDelete(d, canEdit, _DocRow(d, onTap: () => _open(d)))],
              for (final d in rx) ...[const SizedBox(height: 8), _swipeToDelete(d, canEdit, _DocRow(d, onTap: () => _open(d)))],
              if (other.isNotEmpty) CareSection(l10n.careExamSectionOther),
              for (final d in other) ...[const SizedBox(height: 8), _swipeToDelete(d, canEdit, _DocRow(d, onTap: () => _open(d)))],
              if (checked.isNotEmpty) ...[
                CareSection(l10n.careExamValuesOverTime),
                const SizedBox(height: 8),
                ExamValuesList(checked),
              ],
              const SizedBox(height: 14),
              CareNote(rxOnly ? l10n.careRxListNote : l10n.careExamNote),
            ],
          );
        },
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow(this.d, {required this.onTap});
  final CareDocument d;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unconfirmed = d.values.where((v) => !v.confirmed).length;
    final pill = switch (d.status) {
      DocumentStatus.review => CarePill(
          d.kind == DocumentKind.lab && unconfirmed > 0 ? l10n.careExamToCheck(unconfirmed) : l10n.careExamCheck,
          tone: PillTone.blue,
        ),
      DocumentStatus.ready => CarePill(l10n.careExamChecked, tone: PillTone.done),
      DocumentStatus.failed => CarePill(l10n.careExamReadFailed, tone: PillTone.amber),
      _ => CarePill(l10n.careExamArchived),
    };
    final sections = d.sections;
    final title = d.title ??
        (sections.length > 1 ? l10n.careExamTitleMany(sections.first, sections.length - 1) : null) ??
        (sections.length == 1 ? sections.first : null) ??
        switch (d.kind) {
          DocumentKind.lab => l10n.careExamKindLab,
          DocumentKind.prescription => l10n.careExamKindPrescription,
          DocumentKind.other => l10n.careExamKindArchive,
        };
    return CareRow(
      leading: CareIconTile(
        d.isPdf ? Icons.picture_as_pdf_outlined : d.kind == DocumentKind.prescription ? Icons.receipt_long_outlined : Icons.science_outlined,
        background: CareColors.slateBg,
        foreground: CareColors.slate,
      ),
      title: title,
      subtitle: [d.labName, careDate(context, careDay(d.collectedOn) ?? d.createdAt)].whereType<String>().join(' · '),
      trailing: pill,
      onTap: onTap,
    );
  }
}
