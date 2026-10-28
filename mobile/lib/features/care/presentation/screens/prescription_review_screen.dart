import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../care_routes.dart';
import '../widgets/care_widgets.dart';
import 'exam_review_screen.dart';

/// What was read from a prescription, field by field. Nothing becomes a
/// reminder automatically: each medicine opens the medication form, where the
/// person chooses the times.
class PrescriptionReviewScreen extends ConsumerStatefulWidget {
  const PrescriptionReviewScreen({super.key, required this.documentId});
  final String documentId;

  @override
  ConsumerState<PrescriptionReviewScreen> createState() => _PrescriptionReviewScreenState();
}

class _PrescriptionReviewScreenState extends ConsumerState<PrescriptionReviewScreen> {
  List<PrescribedItem>? _items;
  final Map<int, Set<String>> _checked = {};
  final Set<int> _created = {};

  void _init(CareDocument doc) {
    _items ??= doc.medications;
  }

  bool _allChecked(int i) {
    final item = _items![i];
    final needed = {'name', if (item.strength != null) 'strength', if (item.instructions != null) 'instructions'};
    return (_checked[i] ?? const {}).containsAll(needed);
  }

  Future<void> _edit(int i, String field) async {
    final l10n = AppLocalizations.of(context);
    final item = _items![i];
    final controller = TextEditingController(
      text: switch (field) { 'name' => item.name, 'strength' => item.strength, _ => item.instructions },
    );
    final value = await showCareSheet<String>(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.careRxEditField, style: careTitle(19)),
          const SizedBox(height: 12),
          CareField(controller: controller, label: l10n.careRxFieldLabel(field), maxLength: field == 'instructions' ? 300 : 120, maxLines: field == 'instructions' ? 3 : 1),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(50)),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.careSave),
          ),
        ],
      ),
    );
    if (value == null) return;
    setState(() {
      _items![i] = PrescribedItem(
        name: field == 'name' && value.isNotEmpty ? value : item.name,
        strength: field == 'strength' ? (value.isEmpty ? null : value) : item.strength,
        instructions: field == 'instructions' ? (value.isEmpty ? null : value) : item.instructions,
      );
      (_checked[i] ??= {}).add(field);
    });
  }

  Future<void> _createReminder(int i) async {
    final created = await context.push<bool>(
      CarePaths.medicationForm,
      extra: MedicationFormArgs(fromPrescription: _items![i], sourceDocumentId: widget.documentId),
    );
    if (created == true) {
      setState(() => _created.add(i));
      await ref.read(careActionsProvider).review(widget.documentId, {'medications': _items!.map((m) => m.toJson()).toList()});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(careDocumentProvider(widget.documentId));
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: careAppBar(context, l10n.careRxTitle, actions: [
        IconButton(
          onPressed: () async {
            if (!await confirmCareDelete(context)) return;
            await ref.read(careActionsProvider).deleteDocument(widget.documentId);
            if (context.mounted) Navigator.of(context).pop();
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ]),
      body: CareAsync<CareDocument>(
        value: async,
        onRetry: () => ref.invalidate(careDocumentProvider(widget.documentId)),
        data: (doc) {
          _init(doc);
          final items = _items!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              CareRow(
                leading: CareIconTile(doc.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                    background: CareColors.slateBg, foreground: CareColors.slate),
                title: l10n.careExamSeeOriginal,
                subtitle: l10n.careRxCompareHint,
                onTap: () => openOriginalDocument(context, ref, doc),
              ),
              const SizedBox(height: 10),
              if (doc.status == DocumentStatus.failed) CareNote(l10n.careExamFailedHint),
              if (items.isEmpty && doc.status != DocumentStatus.failed) CareEmpty(l10n.careRxNothingRead, icon: Icons.receipt_long_outlined),
              for (var i = 0; i < items.length; i++) ...[
                const SizedBox(height: 10),
                CareCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (field, label, value) in [
                        ('name', l10n.careRxName, items[i].name),
                        if (items[i].strength != null) ('strength', l10n.careRxStrength, items[i].strength!),
                        if (items[i].instructions != null) ('instructions', l10n.careRxInstructions, '"${items[i].instructions!}"'),
                      ]) ...[
                        Row(children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _edit(i, field),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(label, style: careBody(11)),
                                Text(value, style: careTitle()),
                              ]),
                            ),
                          ),
                          Checkbox(
                            key: Key('rx_${i}_$field'),
                            shape: const CircleBorder(),
                            value: _checked[i]?.contains(field) ?? false,
                            onChanged: (v) => setState(() => v == true ? (_checked[i] ??= {}).add(field) : _checked[i]?.remove(field)),
                          ),
                        ]),
                        const Divider(height: 16),
                      ],
                      Text(l10n.careRxTimesYouChoose, style: careBody(12)),
                      const SizedBox(height: 10),
                      if (_created.contains(i))
                        CarePill(l10n.careRxReminderCreated, tone: PillTone.done)
                      else
                        FilledButton(
                          key: Key('rx_create_$i'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(46)),
                          onPressed: _allChecked(i) ? () => _createReminder(i) : null,
                          child: Text(_allChecked(i) ? l10n.careRxCreateReminder : l10n.careRxCheckFirst),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              CareNote(l10n.careRxNote),
            ],
          );
        },
      ),
    );
  }
}
