import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../widgets/care_widgets.dart';

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
                      [
                        [if (a.str('professional') != null) a.str('specialty'), careTime(at)].whereType<String>().join(' · '),
                        if (a.str('place') != null) a.str('place')!,
                      ].join('\n'),
                      style: careBody(),
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
  late String _reminder = widget.existing?.str('reminder') ?? '1d';
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_professional, _specialty, _place, _questions, _notes]) {
      c.dispose();
    }
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
        Row(children: [
          Expanded(child: CareField(controller: _specialty, label: l10n.careAppointmentSpecialty, maxLength: 80)),
          const SizedBox(width: 10),
          Expanded(child: CareField(controller: _place, label: l10n.careAppointmentPlace, maxLength: 160)),
        ]),
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
