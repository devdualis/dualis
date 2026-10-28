import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../domain/care_models.dart';
import '../../domain/pni_calendar.dart';
import '../care_providers.dart';
import '../widgets/care_widgets.dart';

/// Vaccination booklet: the official calendar as published (counts only) and
/// the doses the person registered.
class VaccinesScreen extends ConsumerStatefulWidget {
  const VaccinesScreen({super.key});

  @override
  ConsumerState<VaccinesScreen> createState() => _VaccinesScreenState();
}

class _VaccinesScreenState extends ConsumerState<VaccinesScreen> {
  int _tab = 0;
  PniStage? _stage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(activeProfileControllerProvider).activeProfile;
    final stage = _stage ?? pniStageFor(profile?.dateOfBirth);
    final dosesAsync = ref.watch(careRecordsProvider(CareKind.vaccineDose));
    final canEdit = profile?.canEdit ?? true;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: careAppBar(context, l10n.careVaccinesTitle),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('vaccines_add'),
              backgroundColor: AppColors.dualisNavy,
              foregroundColor: Colors.white,
              onPressed: () => showDoseSheet(context, ref, stage: stage),
              icon: const Icon(Icons.add),
              label: Text(l10n.careVaccineRegister),
            )
          : null,
      body: CareAsync<List<CareRecord>>(
        value: dosesAsync,
        onRetry: () => ref.invalidate(careRecordsProvider(CareKind.vaccineDose)),
        data: (doses) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(l10n.careVaccineTabCalendar)),
                ButtonSegment(value: 1, label: Text(l10n.careVaccineTabMine)),
              ],
              selected: {_tab},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
            const SizedBox(height: 12),
            if (_tab == 0) ..._calendar(context, l10n, stage, doses, canEdit) else ..._mine(context, l10n, doses, canEdit),
          ],
        ),
      ),
    );
  }

  List<Widget> _calendar(BuildContext context, AppLocalizations l10n, PniStage stage, List<CareRecord> doses, bool canEdit) {
    final stageLabels = {
      PniStage.child: l10n.carePniChild,
      PniStage.teen: l10n.carePniTeen,
      PniStage.adult: l10n.carePniAdult,
      PniStage.elderly: l10n.carePniElderly,
      PniStage.pregnant: l10n.carePniPregnant,
    };
    return [
      CareNote(l10n.careVaccineCalendarNote(pniSourceLabel)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in PniStage.values)
            ChoiceChip(label: Text(stageLabels[s]!), selected: s == stage, onSelected: (_) => setState(() => _stage = s)),
        ],
      ),
      const SizedBox(height: 4),
      for (final v in pniCalendar[stage]!) ...[
        const SizedBox(height: 10),
        _calendarCard(context, l10n, v, doses.where((d) => d.str('vaccineKey') == v.key).toList(), stage, canEdit),
      ],
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: () => launchUrl(Uri.parse(pniSourceUrl), mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(l10n.careVaccineOfficialLink),
      ),
    ];
  }

  Widget _calendarCard(BuildContext context, AppLocalizations l10n, PniVaccine v, List<CareRecord> mine, PniStage stage, bool canEdit) {
    final count = mine.length;
    final last = mine.isEmpty ? null : careDay(mine.first.str('appliedOn'));
    final lines = <String>[
      v.doses == null ? l10n.careVaccineByCampaign : l10n.careVaccineDosesInCalendar(v.doses!),
      if (v.boosterYears != null) l10n.careVaccineBoosterEvery(v.boosterYears!),
      if (last != null) l10n.careVaccineLastDose(careDate(context, last)),
    ];
    final pill = count == 0
        ? CarePill(l10n.careVaccineNoRecord)
        : v.doses != null && count >= v.doses!
            ? CarePill(l10n.careVaccineCount(count, v.doses!), tone: PillTone.done)
            : CarePill(v.doses == null ? l10n.careVaccineCountOnly(count) : l10n.careVaccineCount(count, v.doses!), tone: PillTone.blue);
    return CareCard(
      onTap: canEdit ? () => showDoseSheet(context, ref, stage: stage, vaccineKey: v.key) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name, style: careTitle()),
                const SizedBox(height: 2),
                Text(lines.join('\n'), style: careBody()),
                if (v.doses != null && count > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (count / v.doses!).clamp(0, 1).toDouble(),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFEEF2F6),
                      color: AppColors.clinicalTeal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          pill,
        ],
      ),
    );
  }

  List<Widget> _mine(BuildContext context, AppLocalizations l10n, List<CareRecord> doses, bool canEdit) {
    if (doses.isEmpty) return [CareEmpty(l10n.careVaccineEmpty, icon: Icons.vaccines_outlined)];
    return [
      for (final d in doses) ...[
        CareRow(
          title: d.str('customName') ?? pniVaccineByKey(d.str('vaccineKey'))?.name ?? '',
          subtitle: [
            [d.str('doseLabel'), if (careDay(d.str('appliedOn')) != null) careDate(context, careDay(d.str('appliedOn'))!)].whereType<String>().join(' · '),
            if (d.str('batch') != null) l10n.careVaccineBatch(d.str('batch')!),
            if (d.str('place') != null) d.str('place')!,
            if (d.str('boosterOn') != null) l10n.careVaccineBoosterReminder(careDate(context, DateTime.parse(d.str('boosterOn')!))),
          ].join('\n'),
          leading: CareIconTile(d.str('receiptDocumentId') != null ? Icons.receipt_long_outlined : Icons.vaccines_outlined),
          onTap: canEdit ? () => showDoseSheet(context, ref, existing: d) : null,
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}

List<String> _doseLabels(AppLocalizations l10n) =>
    [l10n.careDose1, l10n.careDose2, l10n.careDose3, l10n.careDoseBooster, l10n.careDoseSingle, l10n.careDoseYearly];

Future<void> showDoseSheet(BuildContext context, WidgetRef ref, {PniStage? stage, String? vaccineKey, CareRecord? existing}) {
  return showCareSheet(context, (ctx) => _DoseForm(stage: stage ?? PniStage.adult, vaccineKey: vaccineKey, existing: existing));
}

class _DoseForm extends ConsumerStatefulWidget {
  const _DoseForm({required this.stage, this.vaccineKey, this.existing});
  final PniStage stage;
  final String? vaccineKey;
  final CareRecord? existing;

  @override
  ConsumerState<_DoseForm> createState() => _DoseFormState();
}

class _DoseFormState extends ConsumerState<_DoseForm> {
  static const _custom = '__custom__';
  late String _vaccine;
  String? _dose;
  DateTime? _applied;
  DateTime? _booster;
  bool _remind = false;
  String? _receiptId;
  bool _busy = false;
  final _customName = TextEditingController();
  final _batch = TextEditingController();
  final _place = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _vaccine = e?.str('vaccineKey') ?? (e != null ? _custom : widget.vaccineKey ?? pniCalendar[widget.stage]!.first.key);
    _dose = e?.str('doseLabel');
    _applied = careDay(e?.str('appliedOn')) ?? DateTime.now();
    _booster = DateTime.tryParse(e?.str('boosterOn') ?? '');
    _remind = _booster != null;
    _receiptId = e?.str('receiptDocumentId');
    _customName.text = e?.str('customName') ?? '';
    _batch.text = e?.str('batch') ?? '';
    _place.text = e?.str('place') ?? '';
  }

  @override
  void dispose() {
    _customName.dispose();
    _batch.dispose();
    _place.dispose();
    super.dispose();
  }

  List<PniVaccine> get _options {
    final list = [...pniCalendar[widget.stage]!];
    final current = pniVaccineByKey(_vaccine);
    if (current != null && !list.any((v) => v.key == current.key)) list.insert(0, current);
    return list;
  }

  void _onAppliedChanged(DateTime? d) {
    setState(() {
      _applied = d;
      if (_remind && d != null) _booster = pniBoosterDate(_vaccine, d) ?? _booster;
    });
  }

  Future<void> _pickReceipt() async {
    final l10n = AppLocalizations.of(context);
    final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 2000);
    if (image == null) return;
    setState(() => _busy = true);
    try {
      final doc = await ref.read(careActionsProvider).upload(
            kind: DocumentKind.other,
            mime: 'image/jpeg',
            bytes: await image.readAsBytes(),
            read: false,
            title: l10n.careVaccineReceipt,
          );
      setState(() => _receiptId = doc.id);
    } catch (_) {
      if (mounted) careSnack(context, l10n.careSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_applied == null || (_vaccine == _custom && _customName.text.trim().isEmpty)) {
      careSnack(context, l10n.careFillRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(careActionsProvider).save(
        CareKind.vaccineDose,
        {
          if (_vaccine != _custom) 'vaccineKey': _vaccine else 'customName': _customName.text.trim(),
          'doseLabel': _dose ?? _doseLabels(l10n).first,
          'appliedOn': isoDay(_applied!),
          if (_batch.text.trim().isNotEmpty) 'batch': _batch.text.trim(),
          if (_place.text.trim().isNotEmpty) 'place': _place.text.trim(),
          if (_remind && _booster != null) 'boosterOn': isoDay(_booster!),
          if (_receiptId != null) 'receiptDocumentId': _receiptId,
        },
        id: widget.existing?.id,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) careSnack(context, l10n.careSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmCareDelete(context)) return;
    await ref.read(careActionsProvider).delete(CareKind.vaccineDose, widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final interval = pniVaccineByKey(_vaccine)?.boosterYears;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.existing == null ? l10n.careVaccineRegister : l10n.careVaccineEdit, style: careTitle(19))),
            if (widget.existing != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('dose_vaccine'),
          initialValue: _vaccine,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.careVaccineField, filled: true, fillColor: AppColors.surfaceLight),
          items: [
            for (final v in _options) DropdownMenuItem(value: v.key, child: Text(v.name, overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: _custom, child: Text(l10n.careVaccineCustom)),
          ],
          onChanged: (v) => setState(() {
            _vaccine = v ?? _vaccine;
            if (_remind && _applied != null) _booster = pniBoosterDate(_vaccine, _applied!);
          }),
        ),
        if (_vaccine == _custom) ...[
          const SizedBox(height: 10),
          CareField(fieldKey: const Key('dose_custom_name'), controller: _customName, label: l10n.careVaccineCustomName, maxLength: 80),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _doseLabels(l10n))
              ChoiceChip(label: Text(d), selected: (_dose ?? _doseLabels(l10n).first) == d, onSelected: (_) => setState(() => _dose = d)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: CareDateField(fieldKey: const Key('dose_date'), label: l10n.careVaccineAppliedOn, value: _applied, onChanged: _onAppliedChanged, lastDate: DateTime.now())),
            const SizedBox(width: 10),
            Expanded(child: CareField(controller: _batch, label: l10n.careVaccineBatchField, maxLength: 40)),
          ],
        ),
        const SizedBox(height: 10),
        CareField(controller: _place, label: l10n.careVaccinePlace, maxLength: 120),
        const SizedBox(height: 10),
        CareRow(
          leading: CareIconTile(_receiptId == null ? Icons.add_a_photo_outlined : Icons.check_circle_outline,
              background: CareColors.slateBg, foreground: CareColors.slate),
          title: _receiptId == null ? l10n.careVaccineReceiptAdd : l10n.careVaccineReceiptSaved,
          subtitle: l10n.careVaccineReceiptHint,
          onTap: _busy ? null : _pickReceipt,
          trailing: const SizedBox.shrink(),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          key: const Key('dose_booster_switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.careVaccineRemindBooster, style: careTitle(14)),
          value: _remind,
          onChanged: (on) => setState(() {
            _remind = on;
            if (on && _applied != null) _booster = pniBoosterDate(_vaccine, _applied!) ?? _booster;
          }),
        ),
        if (_remind) ...[
          CareDateField(label: l10n.careVaccineBoosterDate, value: _booster, onChanged: (d) => setState(() => _booster = d), firstDate: DateTime.now()),
          const SizedBox(height: 6),
          Text(interval != null ? l10n.careVaccineBoosterHint(interval) : l10n.careVaccineBoosterHintNone, style: careBody(12)),
        ],
        const SizedBox(height: 14),
        FilledButton(
          key: const Key('dose_save'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(52)),
          onPressed: _busy ? null : _save,
          child: Text(l10n.careSave),
        ),
      ],
    );
  }
}
