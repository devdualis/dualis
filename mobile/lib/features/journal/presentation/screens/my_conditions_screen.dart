import '../../../care/presentation/widgets/care_widgets.dart' show careAppBar;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/glass_card.dart';
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
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.chronicTrackEdit,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.dualisNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('chronicTrack_edit_label'),
                      controller: label,
                      maxLength: JournalKeys.conditionLabelMaxLength,
                      decoration: InputDecoration(
                        hintText: l10n.jv2ConditionsFieldHint,
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
                      onPressed: canSave ? () => Navigator.of(ctx).pop(true) : null,
                      child: Text(l10n.chronicTrackSave),
                    ),
                  ],
                ),
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
        content: Text(
          l10n.jv2ConditionsArchiveConfirm(condition.label),
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.4,
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.dualisNavy),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.jv2Cancel),
          ),
          FilledButton(
            key: const Key('jv2_conditions_archive_confirm'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
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
      backgroundColor: AppColors.backgroundDepth,
      appBar: careAppBar(context, l10n.careConditionsTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              premium ? l10n.chronicTrackConditionsSubtitle : l10n.jv2ConditionsSubtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                            ),
                            onSubmitted: (_) => _add(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          l10n.jv2ConditionsLimit(JournalKeys.maxActiveConditions),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (conditions.isLoading && list.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (list.isEmpty)
              GlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                child: Column(
                  children: [
                    const DuotoneIconTile(
                      size: 48,
                      radius: 14,
                      child: Icon(
                        Icons.healing_outlined,
                        size: 24,
                        color: AppColors.dualisNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.jv2ConditionsEmpty,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final c in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ConditionCard(
                    key: Key('jv2_condition_row_${c.id}'),
                    condition: c,
                    premium: premium,
                    busy: _busy,
                    onOpen: () {
                      if (premium && c.isTracked) {
                        context.push(
                          RoutePaths.conditionReadingsOf(c.id),
                          extra: c.label,
                        );
                      } else {
                        _edit(c);
                      }
                    },
                    onEdit: () => _edit(c),
                    onArchive: () => _archive(c),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// One condition: duotone icon, name, the kinds it tracks and the edit /
/// archive round buttons; Premium builds add a "view readings" pill.
class _ConditionCard extends StatelessWidget {
  final UserCondition condition;
  final bool premium;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _ConditionCard({
    super.key,
    required this.condition,
    required this.premium,
    required this.busy,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
  });

  static final ButtonStyle _roundButton = IconButton.styleFrom(
    backgroundColor: AppColors.iconTileTint,
    foregroundColor: AppColors.dualisNavy,
    disabledBackgroundColor: AppColors.iconTileTint.withValues(alpha: 0.5),
    shape: const CircleBorder(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = condition;
    return GlassCard(
      radius: 22,
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  children: [
                    DuotoneIconTile(
                      child: Icon(
                        c.isTracked ? Icons.monitor_heart_outlined : Icons.healing_outlined,
                        size: 22,
                        color: AppColors.dualisNavy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.label,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: -0.1,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          if (premium && c.isTracked)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                c.tracking.map((k) => readingKindLabel(l10n, k)).join(' · '),
                                key: Key('chronicTrack_kinds_${c.id}'),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: Key('chronicTrack_edit_${c.id}'),
                      tooltip: l10n.chronicTrackEdit,
                      style: _roundButton,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: busy ? null : onEdit,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: Key('jv2_condition_archive_${c.id}'),
                      tooltip: l10n.jv2ConditionsArchive,
                      style: _roundButton,
                      icon: const Icon(Icons.archive_outlined, size: 20),
                      onPressed: busy ? null : onArchive,
                    ),
                  ],
                ),
              ),
            ),
            if (premium && c.isTracked)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: Key('chronicTrack_view_readings_${c.id}'),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.iconTileTint,
                      foregroundColor: AppColors.dualisNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.show_chart_rounded, size: 18),
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

  static const Widget _toggleIcon = DuotoneIconTile(
    size: 36,
    radius: 10,
    child: Icon(Icons.monitor_heart_outlined, size: 20, color: AppColors.dualisNavy),
  );

  static IconData _kindIcon(String kind) => switch (kind) {
        JournalKeys.trackingBloodPressure => Icons.favorite_border_rounded,
        JournalKeys.trackingGlucose => Icons.water_drop_outlined,
        _ => Icons.monitor_weight_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = Text(
      l10n.chronicTrackToggle,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
    );
    if (!premium) {
      return ListTile(
        key: const Key('chronicTrack_toggle'),
        contentPadding: EdgeInsets.zero,
        leading: _toggleIcon,
        title: title,
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            key: const Key('chronicTrack_premium_badge'),
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.dualisNavy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.chronicTrackPremiumBadge,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        trailing: Switch(
          value: false,
          activeTrackColor: AppColors.dualisNavy,
          activeThumbColor: Colors.white,
          onChanged: (_) => onPremiumTap(),
        ),
        onTap: onPremiumTap,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('chronicTrack_toggle'),
          contentPadding: EdgeInsets.zero,
          secondary: _toggleIcon,
          title: title,
          value: on,
          activeTrackColor: AppColors.dualisNavy,
          activeThumbColor: Colors.white,
          onChanged: (v) => onChanged(v, v ? kinds : const {}),
        ),
        if (on)
          for (final k in JournalKeys.trackingKinds)
            CheckboxListTile(
              key: Key('chronicTrack_kind_$k'),
              contentPadding: const EdgeInsets.only(left: 4),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.dualisNavy,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              secondary: DuotoneIconTile(
                size: 32,
                radius: 10,
                child: Icon(_kindIcon(k), size: 18, color: AppColors.dualisNavy),
              ),
              title: Text(
                switch (k) {
                  JournalKeys.trackingBloodPressure => l10n.chronicTrackKindBloodPressureLong,
                  JournalKeys.trackingGlucose => l10n.chronicTrackKindGlucoseLong,
                  _ => l10n.chronicTrackKindWeightLong,
                },
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimaryLight,
                ),
              ),
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
