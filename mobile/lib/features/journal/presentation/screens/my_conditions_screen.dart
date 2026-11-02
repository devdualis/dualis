import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/journal_repository.dart';
import '../../domain/journal_keys.dart';
import '../../domain/journal_models.dart';
import '../controllers/journal_flow_controller.dart';
import '../widgets/condition_readings_card.dart' show readingKindLabel;

/// "Minhas condições (informadas por você)" (strategy section 18.4): free text
/// written by the user, no list of illnesses, no logic attached to the name.
/// On Premium builds the person can switch on readings for a condition
/// ("Precisa de registro"); tracking is never inferred from the name.
class MyConditionsScreen extends ConsumerStatefulWidget {
  const MyConditionsScreen({super.key});

  @override
  ConsumerState<MyConditionsScreen> createState() => _MyConditionsScreenState();
}

class _MyConditionsScreenState extends ConsumerState<MyConditionsScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  /// Tracking picked for the condition being added (Premium).
  bool _track = false;
  Set<String> _kinds = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(userConditionsProvider);
    } on JournalOfflineException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.jv2ConditionsOffline)));
    } on JournalConditionLimitException {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.jv2ConditionsLimit(JournalKeys.maxActiveConditions)),
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.jv2ConditionsError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _premium => ref.read(premiumProfilesEnabledProvider);

  Future<void> _add() async {
    final label = _controller.text.trim();
    if (label.isEmpty) return;
    final tracking = _premium && _track ? _orderedKinds(_kinds) : const <String>[];
    await _run(() async {
      await ref.read(journalRepositoryProvider).addCondition(label, tracking: tracking);
      _controller.clear();
      if (mounted) {
        setState(() {
          _track = false;
          _kinds = {};
        });
      }
    });
  }

  /// Free builds: the tracking switch opens the Premium promo.
  void _openPromo() => context.push(RoutePaths.premiumPromo);

  Future<void> _edit(UserCondition condition) async {
    final l10n = AppLocalizations.of(context);
    final premium = _premium;
    final label = TextEditingController(text: condition.label);
    var track = condition.isTracked;
    var kinds = {...condition.tracking};
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final canSave = label.text.trim().isNotEmpty &&
              (!premium || !track || kinds.isNotEmpty);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              16 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.chronicTrackEdit,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('chronicTrack_edit_label'),
                    controller: label,
                    maxLength: JournalKeys.conditionLabelMaxLength,
                    decoration: InputDecoration(
                      hintText: l10n.jv2ConditionsFieldHint,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setSheet(() {}),
                  ),
                  _TrackingFields(
                    premium: premium,
                    on: track,
                    kinds: kinds,
                    onChanged: (on, k) => setSheet(() {
                      track = on;
                      kinds = k;
                    }),
                    onPremiumTap: _openPromo,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('chronicTrack_edit_save'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: canSave ? () => Navigator.of(ctx).pop(true) : null,
                    child: Text(l10n.chronicTrackSave),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    final newLabel = label.text.trim();
    label.dispose();
    if (saved != true || !mounted) return;
    await _run(() => ref.read(journalRepositoryProvider).updateCondition(
          condition.id,
          // Free builds never change what a condition tracks.
          tracking: premium ? (track ? _orderedKinds(kinds) : const []) : null,
          label: newLabel == condition.label ? null : newLabel,
        ));
  }

  static List<String> _orderedKinds(Set<String> kinds) => [
        for (final k in JournalKeys.trackingKinds)
          if (kinds.contains(k)) k,
      ];

  Future<void> _archive(UserCondition condition) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.jv2ConditionsArchiveConfirm(condition.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.jv2Cancel),
          ),
          FilledButton(
            key: const Key('jv2_conditions_archive_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.jv2ConditionsArchive),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref.read(journalRepositoryProvider).archiveCondition(condition.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final conditions = ref.watch(userConditionsProvider);
    final list = conditions.value ?? const <UserCondition>[];
    final atLimit = list.length >= JournalKeys.maxActiveConditions;
    final premium = ref.watch(premiumProfilesEnabledProvider);
    final missingKind = premium && _track && _kinds.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.jv2ConditionsTitle,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              premium ? l10n.chronicTrackConditionsSubtitle : l10n.jv2ConditionsSubtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('jv2_conditions_field'),
                    controller: _controller,
                    enabled: !atLimit && !_busy,
                    maxLength: JournalKeys.conditionLabelMaxLength,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l10n.jv2ConditionsFieldHint,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FilledButton.icon(
                    key: const Key('jv2_conditions_add'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                    onPressed: atLimit || _busy || missingKind ? null : _add,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.jv2ConditionsAdd),
                  ),
                ),
              ],
            ),
            if (atLimit)
              Text(
                l10n.jv2ConditionsLimit(JournalKeys.maxActiveConditions),
                style: GoogleFonts.plusJakartaSans(fontSize: 12),
              )
            else
              _TrackingFields(
                premium: premium,
                on: _track,
                kinds: _kinds,
                onChanged: (on, kinds) => setState(() {
                  _track = on;
                  _kinds = kinds;
                }),
                onPremiumTap: _openPromo,
              ),
            const SizedBox(height: 12),
            if (conditions.isLoading && list.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (list.isEmpty)
              Text(
                l10n.jv2ConditionsEmpty,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondaryLight,
                ),
              )
            else
              for (final c in list)
                Card(
                  key: Key('jv2_condition_row_${c.id}'),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.outlineLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        leading: const Text('📝', style: TextStyle(fontSize: 22)),
                        title: Text(c.label),
                        subtitle: premium && c.isTracked
                            ? Text(
                                c.tracking.map((k) => readingKindLabel(l10n, k)).join(' · '),
                                key: Key('chronicTrack_kinds_${c.id}'),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: Key('chronicTrack_edit_${c.id}'),
                              tooltip: l10n.chronicTrackEdit,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: _busy ? null : () => _edit(c),
                            ),
                            IconButton(
                              key: Key('jv2_condition_archive_${c.id}'),
                              tooltip: l10n.jv2ConditionsArchive,
                              icon: const Icon(Icons.archive_outlined),
                              onPressed: _busy ? null : () => _archive(c),
                            ),
                          ],
                        ),
                      ),
                      if (premium && c.isTracked)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              key: Key('chronicTrack_view_readings_${c.id}'),
                              icon: const Icon(Icons.show_chart_rounded),
                              label: Text(l10n.chronicTrackViewReadings),
                              onPressed: () => context.push(
                                RoutePaths.conditionReadingsOf(c.id),
                                extra: c.label,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// "Precisa de registro (condição crônica)" and the reading kinds. On Free
/// builds the switch carries a PREMIUM pill and opens the promo.
class _TrackingFields extends StatelessWidget {
  final bool premium;
  final bool on;
  final Set<String> kinds;
  final void Function(bool on, Set<String> kinds) onChanged;
  final VoidCallback onPremiumTap;

  const _TrackingFields({
    required this.premium,
    required this.on,
    required this.kinds,
    required this.onChanged,
    required this.onPremiumTap,
  });

  static const Color _gold = Color(0xFFB26A00);
  static const Color _goldBg = Color(0xFFFFF8E1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = Text(
      l10n.chronicTrackToggle,
      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
    );
    if (!premium) {
      return ListTile(
        key: const Key('chronicTrack_toggle'),
        contentPadding: EdgeInsets.zero,
        title: title,
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            key: const Key('chronicTrack_premium_badge'),
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _goldBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _gold),
            ),
            child: Text(
              l10n.chronicTrackPremiumBadge,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _gold,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        trailing: Switch(value: false, onChanged: (_) => onPremiumTap()),
        onTap: onPremiumTap,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('chronicTrack_toggle'),
          contentPadding: EdgeInsets.zero,
          title: title,
          value: on,
          onChanged: (v) => onChanged(v, v ? kinds : const {}),
        ),
        if (on)
          for (final k in JournalKeys.trackingKinds)
            CheckboxListTile(
              key: Key('chronicTrack_kind_$k'),
              contentPadding: const EdgeInsets.only(left: 8),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(switch (k) {
                JournalKeys.trackingBloodPressure => l10n.chronicTrackKindBloodPressureLong,
                JournalKeys.trackingGlucose => l10n.chronicTrackKindGlucoseLong,
                _ => l10n.chronicTrackKindWeightLong,
              }),
              value: kinds.contains(k),
              onChanged: (v) => onChanged(
                true,
                v == true ? {...kinds, k} : ({...kinds}..remove(k)),
              ),
            ),
      ],
    );
  }
}
