import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal_insights/presentation/widgets/history_widgets.dart';
import '../../../profile/domain/models/share_category.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../care_routes.dart';
import '../widgets/care_widgets.dart';

/// Today's reminders (Tomei / Adiar / Pulei) and all medications. Times and
/// amounts are the ones the person configured from their prescription.
class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = activeProfileCanWrite(ref, ShareCategory.care);
    final async = ref.watch(medicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDepth,
      appBar: careAppBar(context, l10n.careMedicationsTitle),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('medications_add'),
              backgroundColor: AppColors.dualisNavy,
              foregroundColor: Colors.white,
              onPressed: () => context.push(CarePaths.medicationForm, extra: const MedicationFormArgs()),
              icon: const Icon(Icons.add),
              label: Text(l10n.careMedicationAdd),
            )
          : null,
      body: CareAsync<List<Medication>>(
        value: async,
        onRetry: () => ref.invalidate(careRecordsProvider(CareKind.medication)),
        data: (meds) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            HistorySegmented<int>(
              keyPrefix: 'care_med_tab',
              options: [(0, l10n.careMedTabToday), (1, l10n.careMedTabAll)],
              selected: _tab,
              onChanged: (v) => setState(() => _tab = v),
            ),
            const SizedBox(height: 8),
            if (meds.isEmpty)
              CareEmpty(l10n.careMedEmpty, icon: Icons.medication_outlined)
            else if (_tab == 0)
              ..._today(context, l10n, meds, canEdit)
            else
              ..._all(context, l10n, meds, canEdit),
            const SizedBox(height: 12),
            CareNote(l10n.careMedNote),
          ],
        ),
      ),
    );
  }

  List<Widget> _today(BuildContext context, AppLocalizations l10n, List<Medication> meds, bool canEdit) {
    final now = DateTime.now();
    final slots = [for (final m in meds) for (final s in m.slotsOn(now)) (m, s)]..sort((a, b) => a.$2.compareTo(b.$2));
    final widgets = <Widget>[];
    String? lastPeriod;
    for (final (med, at) in slots) {
      final period = at.hour < 12 ? l10n.careMedMorning : at.hour < 18 ? l10n.careMedAfternoon : l10n.careMedNight;
      if (period != lastPeriod) {
        widgets.add(CareSection(period));
        lastPeriod = period;
      }
      widgets
        ..add(const SizedBox(height: 8))
        ..add(_SlotCard(med: med, at: at, canEdit: canEdit));
    }
    if (slots.isEmpty) widgets.add(CareEmpty(l10n.careMedNoneToday, icon: Icons.event_available_outlined));
    for (final m in meds.where((m) => m.active && m.stockLow)) {
      widgets
        ..add(const SizedBox(height: 10))
        ..add(CareRow(
          color: CareColors.amberBg,
          borderColor: AppColors.intensityMildBorder.withValues(alpha: 0.4),
          leading: const CareIconTile(Icons.inventory_2_outlined, background: Colors.white, foreground: CareColors.amber),
          title: l10n.careMedStockTitle(m.title),
          subtitle: l10n.careMedStockBody(m.stockCount!, m.stockWarnAt!),
        ));
    }
    return widgets;
  }

  List<Widget> _all(BuildContext context, AppLocalizations l10n, List<Medication> meds, bool canEdit) => [
        for (final m in meds) ...[
          const SizedBox(height: 10),
          CareRow(
            leading: CareIconTile(Icons.medication_outlined,
                background: m.active ? AppColors.iconTileTint : AppColors.dualisNavy.withValues(alpha: 0.06),
                foreground: m.active ? AppColors.dualisNavy : AppColors.textSecondaryLight),
            title: m.title,
            subtitle: [
              if (m.amountPerIntake != null) m.amountPerIntake!,
              m.times.isEmpty ? l10n.careMedNoTimes : m.times.join(' · '),
              if (m.stockCount != null) l10n.careMedStockLeft(m.stockCount!),
              if (!m.active) l10n.careMedPaused,
            ].join('\n'),
            onTap: canEdit ? () => context.push(CarePaths.medicationForm, extra: MedicationFormArgs(medication: m)) : null,
          ),
        ],
      ];
}

class _SlotCard extends ConsumerStatefulWidget {
  const _SlotCard({required this.med, required this.at, required this.canEdit});
  final Medication med;
  final DateTime at;
  final bool canEdit;

  @override
  ConsumerState<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends ConsumerState<_SlotCard> {
  bool _busy = false;

  static final _slotOutlined = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    side: BorderSide(color: AppColors.dualisNavy.withValues(alpha: 0.25), width: 1.2),
    textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
  );

  Future<void> _act(IntakeAction action) async {
    setState(() => _busy = true);
    try {
      await ref.read(careActionsProvider).logIntake(widget.med, widget.at, action);
    } catch (_) {
      if (mounted) careSnack(context, AppLocalizations.of(context).careSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final intakes = ref.watch(intakesProvider(widget.med.id)).value ?? const <CareRecord>[];
    // Latest action for this slot; a snooze counts as still pending.
    final logged = intakes.where((i) => i.occursAt?.toLocal() == widget.at).toList();
    final last = logged.isEmpty ? null : logged.first;
    final action = last?.str('action');
    final done = action == 'taken' || action == 'skipped';
    final amount = widget.med.amountPerIntake;

    return CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: action == 'taken' ? AppColors.dualisSymbolCyan : Colors.transparent,
                  border: Border.all(
                    color: action == 'taken' ? AppColors.dualisSymbolCyan : AppColors.dualisNavy.withValues(alpha: 0.28),
                    width: 2,
                  ),
                ),
                child: action == 'taken' ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.med.title, style: careTitle()),
                    Text(
                      [
                        careTime(widget.at),
                        if (amount != null) amount,
                        if (action == 'taken') l10n.careMedTakenAt(careTime(last!.createdAt)),
                        if (action == 'skipped') l10n.careMedSkipped,
                        if (action == 'snoozed') l10n.careMedSnoozed,
                      ].join(' · '),
                      style: careBody(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!done && widget.canEdit) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: Key('slot_taken_${widget.med.id}_${widget.at.hour}${widget.at.minute}'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 8)),
                    onPressed: _busy ? null : () => _act(IntakeAction.taken),
                    child: Text(l10n.careMedTaken, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: _slotOutlined,
                    onPressed: _busy ? null : () => _act(IntakeAction.snoozed),
                    child: Text(l10n.careMedSnooze, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: _slotOutlined,
                    onPressed: _busy ? null : () => _act(IntakeAction.skipped),
                    child: Text(l10n.careMedSkip, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
