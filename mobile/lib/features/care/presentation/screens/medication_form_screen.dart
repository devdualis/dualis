import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../care_routes.dart';
import '../widgets/care_widgets.dart';

/// Official ANVISA leaflet search for [name] (Bulário Eletrônico). The app
/// shows no leaflet text of its own.
Uri anvisaBulaUri(String name) =>
    Uri.parse('https://consultas.anvisa.gov.br/#/bulario/q/?nomeProduto=${Uri.encodeComponent(name.trim())}');

/// Medication form. Everything is typed by the person; from a prescription,
/// name/strength/instructions arrive pre-filled and times stay empty until the
/// person picks them (the app never turns "12/12h" into times).
class MedicationFormScreen extends ConsumerStatefulWidget {
  const MedicationFormScreen({super.key, required this.args});
  final MedicationFormArgs args;

  @override
  ConsumerState<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Medication? _med = widget.args.medication;
  late final _name = TextEditingController(text: _med?.name ?? widget.args.fromPrescription?.name);
  late final _strength = TextEditingController(text: _med?.strength ?? widget.args.fromPrescription?.strength);
  late final _formField = TextEditingController(text: _med?.form);
  late final _amount = TextEditingController(text: _med?.amountPerIntake);
  late final _instructions = TextEditingController(text: _med?.instructions ?? widget.args.fromPrescription?.instructions);
  late final _stock = TextEditingController(text: _med?.stockCount?.toString());
  late final _perIntake = TextEditingController(text: (_med?.record.integer('stockPerIntake') ?? 1).toString());
  late final _warnAt = TextEditingController(text: _med?.stockWarnAt?.toString());
  late final List<String> _times = [...?_med?.times];
  late final Set<int> _weekdays = {...?_med?.weekdays};
  late DateTime? _until = _med?.untilOn != null ? DateTime.tryParse(_med!.untilOn!) : null;
  late bool _active = _med?.active ?? true;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _strength, _formField, _amount, _instructions, _stock, _perIntake, _warnAt]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (picked == null) return;
    final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (!_times.contains(value)) _times.add(value);
      _times.sort();
    });
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_times.isEmpty) {
      careSnack(context, l10n.careMedTimesRequired);
      return;
    }
    setState(() => _busy = true);
    String? t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    try {
      await ref.read(careActionsProvider).save(
        CareKind.medication,
        {
          'name': _name.text.trim(),
          if (t(_strength) != null) 'strength': t(_strength),
          if (t(_formField) != null) 'form': t(_formField),
          if (t(_amount) != null) 'amountPerIntake': t(_amount),
          if (t(_instructions) != null) 'instructions': t(_instructions),
          'times': _times,
          'weekdays': _weekdays.toList()..sort(),
          if (_until != null) 'untilOn': isoDay(_until!),
          if (_int(_stock) != null) 'stockCount': _int(_stock),
          if (_int(_stock) != null) 'stockPerIntake': (_int(_perIntake) ?? 1).clamp(1, 100),
          if (_int(_warnAt) != null) 'stockWarnAt': _int(_warnAt),
          'active': _active,
          if (widget.args.sourceDocumentId != null || _med?.record.str('sourceDocumentId') != null)
            'sourceDocumentId': widget.args.sourceDocumentId ?? _med!.record.str('sourceDocumentId'),
        },
        id: _med?.id,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) careSnack(context, l10n.careSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmCareDelete(context)) return;
    await ref.read(careActionsProvider).delete(CareKind.medication, _med!.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weekdayLabels = [l10n.careMon, l10n.careTue, l10n.careWed, l10n.careThu, l10n.careFri, l10n.careSat, l10n.careSun];
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: careAppBar(context, _med == null ? l10n.careMedicationAdd : l10n.careMedicationEdit, actions: [
        if (_med != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
      ]),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (widget.args.fromPrescription != null) ...[CareNote(l10n.careMedFromPrescriptionNote), const SizedBox(height: 10)],
            CareField(
              fieldKey: const Key('med_name'),
              controller: _name,
              label: l10n.careMedName,
              maxLength: 120,
              validator: (v) => (v ?? '').trim().isEmpty ? l10n.careFillRequired : null,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: CareField(fieldKey: const Key('med_strength'), controller: _strength, label: l10n.careMedStrength, maxLength: 40)),
              const SizedBox(width: 10),
              Expanded(child: CareField(controller: _formField, label: l10n.careMedForm, maxLength: 40)),
            ]),
            const SizedBox(height: 10),
            CareField(fieldKey: const Key('med_amount'), controller: _amount, label: l10n.careMedAmount, maxLength: 80),
            const SizedBox(height: 10),
            CareField(controller: _instructions, label: l10n.careMedInstructions, maxLength: 300, maxLines: 2),
            const SizedBox(height: 16),
            Text(l10n.careMedTimes, style: careTitle()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final time in _times)
                  InputChip(
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: Text(time),
                    onDeleted: () => setState(() => _times.remove(time)),
                  ),
                ActionChip(key: const Key('med_add_time'), avatar: const Icon(Icons.add, size: 18), label: Text(l10n.careMedAddTime), onPressed: _addTime),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.careMedDays, style: careTitle()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(label: Text(l10n.careMedEveryDay), selected: _weekdays.isEmpty, onSelected: (_) => setState(_weekdays.clear)),
                for (var d = 1; d <= 7; d++)
                  FilterChip(
                    label: Text(weekdayLabels[d - 1]),
                    selected: _weekdays.contains(d),
                    onSelected: (on) => setState(() => on ? _weekdays.add(d) : _weekdays.remove(d)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            CareDateField(label: l10n.careMedUntil, value: _until, onChanged: (d) => setState(() => _until = d), firstDate: DateTime.now()),
            const SizedBox(height: 16),
            Text(l10n.careMedStockSection, style: careTitle()),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: CareField(fieldKey: const Key('med_stock'), controller: _stock, label: l10n.careMedStockHave, keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: CareField(controller: _perIntake, label: l10n.careMedStockPerIntake, keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: CareField(fieldKey: const Key('med_warn'), controller: _warnAt, label: l10n.careMedStockWarn, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            CareRow(
              leading: const CareIconTile(Icons.description_outlined, background: CareColors.slateBg, foreground: CareColors.slate),
              title: l10n.careMedBula,
              subtitle: l10n.careMedBulaHint,
              trailing: const Icon(Icons.open_in_new, color: Color(0xFF94A3B8)),
              onTap: () {
                if (_name.text.trim().isEmpty) return careSnack(context, l10n.careMedBulaNeedsName);
                launchUrl(anvisaBulaUri(_name.text), mode: LaunchMode.externalApplication);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.careMedActive, style: careTitle(14)),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 4),
            CareNote(l10n.careMedNote),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('med_save'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(52)),
              onPressed: _busy ? null : _save,
              child: Text(l10n.careMedSave),
            ),
          ],
        ),
      ),
    );
  }
}
