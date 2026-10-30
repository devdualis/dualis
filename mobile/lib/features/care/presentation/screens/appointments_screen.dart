import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../domain/care_models.dart';
import '../../domain/specialties.dart';
import '../care_providers.dart';
import '../widgets/care_widgets.dart';
import 'place_picker_screen.dart';

/// Opens Google Maps (app if installed, else web) on the picked point, or searching for [place].
Future<void> _openInMaps(String place, {double? lat, double? lng}) => launchUrl(
      Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': lat != null && lng != null ? '$lat,$lng' : place}),
      mode: LaunchMode.externalApplication,
    );

/// Appointment agenda: date, professional, place, "perguntas que quero fazer"
/// and the person's notes afterwards.
class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canEdit = ref.watch(activeProfileControllerProvider).activeProfile?.canEdit ?? true;
    final async = ref.watch(careRecordsProvider(CareKind.appointment));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: careAppBar(context, l10n.careAppointmentsTitle),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('appointments_add'),
              backgroundColor: AppColors.dualisNavy,
              foregroundColor: Colors.white,
              onPressed: () => showCareSheet(context, (_) => const _AppointmentForm()),
              icon: const Icon(Icons.add),
              label: Text(l10n.careAppointmentAdd),
            )
          : null,
      body: CareAsync<List<CareRecord>>(
        value: async,
        onRetry: () => ref.invalidate(careRecordsProvider(CareKind.appointment)),
        data: (items) {
          final now = DateTime.now();
          final upcoming = items.where((a) => a.occursAt!.isAfter(now)).toList()..sort((a, b) => a.occursAt!.compareTo(b.occursAt!));
          final past = items.where((a) => !a.occursAt!.isAfter(now)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (items.isEmpty) CareEmpty(l10n.careAppointmentEmpty, icon: Icons.event_outlined),
              if (upcoming.isNotEmpty) CareSection(l10n.careAppointmentUpcoming),
              for (final a in upcoming) ...[const SizedBox(height: 8), _AppointmentCard(a, canEdit: canEdit, highlight: true)],
              if (past.isNotEmpty) CareSection(l10n.careAppointmentPast),
              for (final a in past) ...[const SizedBox(height: 8), _AppointmentCard(a, canEdit: canEdit)],
            ],
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard(this.a, {required this.canEdit, this.highlight = false});
  final CareRecord a;
  final bool canEdit;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final at = a.occursAt!.toLocal();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final questions = a.str('questions');
    final notes = a.str('notes');
    return CareCard(
      onTap: canEdit ? () => showCareSheet(context, (_) => _AppointmentForm(existing: a)) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: highlight ? CareColors.greenBg : CareColors.slateBg, borderRadius: BorderRadius.circular(13)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${at.day}', style: careTitle(18).copyWith(color: highlight ? CareColors.green : CareColors.slate)),
                    Text(DateFormat.MMM(locale).format(at).toUpperCase(),
                        style: careBody(11).copyWith(fontWeight: FontWeight.w700, color: highlight ? CareColors.green : CareColors.slate)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.str('professional') ?? a.str('specialty') ?? l10n.careAppointmentTitleFallback, style: careTitle()),
                    Text(
                      [if (a.str('professional') != null) a.str('specialty'), careTime(at)].whereType<String>().join(' · '),
                      style: careBody(),
                    ),
                    if (a.str('place') != null)
                      InkWell(
                        key: const Key('appt_card_place'),
                        onTap: () => _openInMaps(a.str('place')!, lat: a.number('placeLat'), lng: a.number('placeLng')),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            const Icon(Icons.place_outlined, size: 16, color: AppColors.dualisNavy),
                            const SizedBox(width: 4),
                            Expanded(child: Text(a.str('place')!, style: careBody().copyWith(color: AppColors.dualisNavy, decoration: TextDecoration.underline))),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (questions != null) ...[
            const Divider(height: 20),
            Text(l10n.careAppointmentQuestions, style: careTitle(12)),
            const SizedBox(height: 2),
            Text(questions, style: careBody()),
          ],
          if (notes != null) ...[
            const Divider(height: 20),
            Text(l10n.careAppointmentNotes, style: careTitle(12)),
            const SizedBox(height: 2),
            Text(notes, style: careBody()),
          ],
          if (highlight && a.str('reminder') != null && a.str('reminder') != 'none') ...[
            const SizedBox(height: 10),
            CarePill(a.str('reminder') == '1d' ? l10n.careAppointmentReminder1d : l10n.careAppointmentReminder2h, tone: PillTone.blue),
          ],
        ],
      ),
    );
  }
}

class _AppointmentForm extends ConsumerStatefulWidget {
  const _AppointmentForm({this.existing});
  final CareRecord? existing;

  @override
  ConsumerState<_AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends ConsumerState<_AppointmentForm> {
  late DateTime? _date = widget.existing?.occursAt?.toLocal();
  late TimeOfDay? _time = _date == null ? null : TimeOfDay.fromDateTime(_date!);
  late final _professional = TextEditingController(text: widget.existing?.str('professional'));
  late final _specialty = TextEditingController(text: widget.existing?.str('specialty'));
  late final _place = TextEditingController(text: widget.existing?.str('place'));
  late final _questions = TextEditingController(text: widget.existing?.str('questions'));
  late final _notes = TextEditingController(text: widget.existing?.str('notes'));
  final _specialtyFocus = FocusNode();
  /// Point picked on the map; dropped when the place text no longer matches it.
  late PickedPlace? _picked = switch ((widget.existing?.str('place'), widget.existing?.number('placeLat'), widget.existing?.number('placeLng'))) {
    (final String place, final double lat, final double lng) => PickedPlace(place, lat, lng),
    _ => null,
  };
  late String _reminder = widget.existing?.str('reminder') ?? '1d';
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_professional, _specialty, _place, _questions, _notes]) {
      c.dispose();
    }
    _specialtyFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_date == null || _time == null) {
      careSnack(context, l10n.careFillRequired);
      return;
    }
    final startsAt = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    String? t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    setState(() => _busy = true);
    try {
      await ref.read(careActionsProvider).save(
        CareKind.appointment,
        {
          'startsAt': startsAt.toUtc().toIso8601String(),
          if (t(_professional) != null) 'professional': t(_professional),
          if (t(_specialty) != null) 'specialty': t(_specialty),
          if (t(_place) != null) 'place': t(_place),
          if (_picked != null && _picked!.address == t(_place)) ...{'placeLat': _picked!.lat, 'placeLng': _picked!.lng},
          if (t(_questions) != null) 'questions': t(_questions),
          if (t(_notes) != null) 'notes': t(_notes),
          'reminder': _reminder,
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

  Future<void> _pickOnMap() async {
    final text = _place.text.trim();
    final keep = _picked != null && _picked!.address == text ? _picked : null;
    final picked = await ref.read(placePickerProvider)(context, query: text, initial: keep);
    if (picked == null || !mounted) return;
    setState(() {
      _picked = picked;
      _place.text = picked.address.length > 160 ? picked.address.substring(0, 160) : picked.address;
    });
  }

  Future<void> _delete() async {
    if (!await confirmCareDelete(context)) return;
    await ref.read(careActionsProvider).delete(CareKind.appointment, widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: Text(widget.existing == null ? l10n.careAppointmentAdd : l10n.careAppointmentEdit, style: careTitle(19))),
          if (widget.existing != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CareDateField(fieldKey: const Key('appt_date'), label: l10n.careAppointmentDate, value: _date, onChanged: (d) => setState(() => _date = d))),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              key: const Key('appt_time'),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0));
                if (picked != null) setState(() => _time = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(labelText: l10n.careAppointmentTime, filled: true, fillColor: AppColors.surfaceLight),
                child: Text(_time == null ? '—' : _time!.format(context)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        CareField(fieldKey: const Key('appt_professional'), controller: _professional, label: l10n.careAppointmentProfessional, maxLength: 120),
        const SizedBox(height: 10),
        Autocomplete<String>(
          textEditingController: _specialty,
          focusNode: _specialtyFocus,
          optionsViewOpenDirection: OptionsViewOpenDirection.mostSpace,
          optionsBuilder: (value) {
            final query = foldText(value.text.trim());
            final all = specialtiesFor(Localizations.localeOf(context).languageCode);
            return query.isEmpty ? all : all.where((s) => foldText(s).contains(query));
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: AlignmentDirectional.topStart,
            child: Material(
              elevation: 6,
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  children: [
                    for (final option in options)
                      InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(option, style: careBody(15).copyWith(color: AppColors.textPrimaryLight)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextFormField(
            key: const Key('appt_specialty'),
            controller: controller,
            focusNode: focusNode,
            maxLength: 80,
            onFieldSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              labelText: l10n.careAppointmentSpecialty,
              counterText: '',
              filled: true,
              fillColor: AppColors.surfaceLight,
              suffixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('appt_place'),
          controller: _place,
          maxLength: 160,
          decoration: InputDecoration(
            labelText: l10n.careAppointmentPlace,
            counterText: '',
            filled: true,
            fillColor: AppColors.surfaceLight,
            suffixIcon: IconButton(
              key: const Key('appt_place_map'),
              tooltip: l10n.careAppointmentOpenMap,
              icon: Icon(_picked != null && _picked!.address == _place.text.trim() ? Icons.where_to_vote : Icons.map_outlined),
              color: AppColors.dualisNavy,
              onPressed: _pickOnMap,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        CareField(controller: _questions, label: l10n.careAppointmentQuestions, maxLength: 1000, maxLines: 3),
        const SizedBox(height: 10),
        CareField(controller: _notes, label: l10n.careAppointmentNotes, maxLength: 2000, maxLines: 3),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          for (final (key, label) in [
            ('none', l10n.careAppointmentReminderNone),
            ('1d', l10n.careAppointmentReminder1d),
            ('2h', l10n.careAppointmentReminder2h),
          ])
            ChoiceChip(label: Text(label), selected: _reminder == key, onSelected: (_) => setState(() => _reminder = key)),
        ]),
        const SizedBox(height: 14),
        FilledButton(
          key: const Key('appt_save'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(52)),
          onPressed: _busy ? null : _save,
          child: Text(l10n.careSave),
        ),
      ],
    );
  }
}
