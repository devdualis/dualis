import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/presentation/screens/check_in_summary_screen.dart';
import '../../../home/domain/home_greeting.dart' as greeting;
import '../../../home/domain/trigger_checkin_state.dart';
import '../../../home/presentation/controllers/trigger_checkin_controller.dart';
import '../../../triage/domain/triage_vertical.dart';
import '../../data/journal_repository.dart';
import '../../domain/journal_keys.dart';
import '../../domain/journal_models.dart';
import '../controllers/journal_flow_controller.dart';
import '../controllers/journal_flow_state.dart';
import '../journal_item_text.dart';
import '../journal_labels.dart';
import '../widgets/body_region_map.dart';
import '../widgets/intensity_scale.dart';

/// Starting point when the flow is opened from a Home card.
class JournalFlowArgs {
  /// Axis of the entry: the Home card that was tapped. Null = emotional.
  final JournalArea? initialArea;

  const JournalFlowArgs({this.initialArea});
}

/// Daily journal flow (strategy sections 5, 6, 8 and 18): one axis per
/// entry, few options per screen, animated transitions. Saves what the user chose, in
/// their words. The universal help button is added by `UrgentHelpOverlay`.
class JournalFlowScreen extends ConsumerStatefulWidget {
  final JournalFlowArgs args;

  const JournalFlowScreen({super.key, this.args = const JournalFlowArgs()});

  @override
  ConsumerState<JournalFlowScreen> createState() => _JournalFlowScreenState();
}

class _JournalFlowScreenState extends ConsumerState<JournalFlowScreen> {
  final _customController = TextEditingController();
  final _triggerNoteController = TextEditingController();
  final _noteController = TextEditingController();
  bool _writingCustom = false;
  bool _suggestingCustom = false;

  JournalFlowController get _controller =>
      ref.read(journalFlowControllerProvider.notifier);

  JournalArea get _area => widget.args.initialArea ?? JournalArea.emotional;

  @override
  void dispose() {
    _customController.dispose();
    _triggerNoteController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _back() {
    setState(() => _writingCustom = false);
    if (!_controller.back()) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.home);
      }
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final entry = await _controller.save();
      if (!mounted) return;
      _updateHome(l10n, entry);
      if (entry.pendingSync) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.jv2SavedOffline)));
      }
      context.go(
        RoutePaths.checkInSummary,
        extra: CheckInSummaryArgs(
          showBodyMap: entry.hasPhysicalItem,
          showEmotionalTrend: !entry.hasPhysicalItem || entry.hasEmotionalItem,
          entry: entry,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.jv2SaveError)));
    }
  }

  /// Marks today's check-in as done on Home, with the user's own words.
  /// Only the axis of the entry is marked; entries without one (older
  /// outbox items) keep marking both.
  void _updateHome(AppLocalizations l10n, JournalEntry entry) {
    final home = ref.read(triggerCheckInProvider.notifier);
    final axes = switch (entry.area) {
      JournalKeys.areaEmotional => const [TriageVertical.psicoEmocional],
      JournalKeys.areaPhysical => const [TriageVertical.fisica],
      _ => TriageVertical.values,
    };
    if (entry.items.isEmpty) {
      final summary = JournalLabels.mood(l10n, entry.mood);
      for (final v in axes) {
        home.completeStage(
          vertical: v,
          summary: summary,
          status: TriggerStatus.goodNormal,
          intensity: 0,
        );
      }
      return;
    }
    void complete(TriageVertical vertical, Iterable<JournalItem> items) {
      if (items.isEmpty || !axes.contains(vertical)) return;
      home.completeStage(
        vertical: vertical,
        summary: items.map((i) => journalItemText(l10n, i)).join(' · '),
        narrative: entry.note,
        intensity: items
            .map((i) => i.intensity ?? 0)
            .reduce((a, b) => a > b ? a : b),
      );
    }

    complete(
      TriageVertical.fisica,
      entry.items.where((i) => i.kind == JournalKeys.kindPhysical),
    );
    complete(
      TriageVertical.psicoEmocional,
      entry.items.where((i) => i.kind == JournalKeys.kindEmotional),
    );
    // Conditions get their own line on Home and never fill an axis.
    final conditions =
        entry.items.where((i) => i.kind == JournalKeys.kindCondition);
    home.completeConditions(
      conditions.isEmpty
          ? null
          : conditions.map((i) => journalItemText(l10n, i)).join(' · '),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(journalFlowControllerProvider);
    final conditions = ref.watch(userConditionsProvider).value ?? const [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('jv2_back'),
            tooltip: l10n.jv2Back,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _back,
          ),
          title: Text(
            l10n.jv2FlowTitle,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(
                '${state.step.name}-${state.time}-${state.regionIndex}-${state.branch}',
              ),
              child: _buildStep(context, l10n, state, conditions),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    AppLocalizations l10n,
    JournalFlowState state,
    List<UserCondition> conditions,
  ) {
    switch (state.step) {
      case JournalStep.mood:
        return _moodStep(l10n, state);
      case JournalStep.time:
        return _timeStep(l10n, state);
      case JournalStep.branch:
        return _branchStep(l10n, state, JournalKeys.emotionalTree[state.time]!,
            state.time!);
      case JournalStep.options:
        return _optionsStep(
          l10n,
          state,
          JournalKeys.emotionalTree[state.time]![state.branch]!,
          '${state.time}.${state.branch}',
          _controller.confirmEmotionalOptions,
        );
      case JournalStep.moreEmotional:
        return _moreStep(l10n, state, l10n.jv2MoreQuestion,
            _controller.answerMoreEmotional);
      case JournalStep.body:
        return _bodyStep(l10n, state, conditions);
      case JournalStep.regionBranch:
        return _regionBranchStep(l10n, state);
      case JournalStep.regionOptions:
        final region = state.currentRegion!.region;
        return _optionsStep(
          l10n,
          state,
          JournalKeys.physicalTree[region]![state.branch]!,
          '$region.${state.branch}',
          _controller.confirmPhysicalOptions,
        );
      case JournalStep.moreBody:
        return _moreStep(l10n, state, l10n.jv2MoreBodyQuestion,
            _controller.answerMoreBody);
      case JournalStep.intensity:
        return _intensityStep(l10n, state);
      case JournalStep.triggers:
        return _triggersStep(l10n, state);
      case JournalStep.note:
        return _noteStep(l10n, state);
    }
  }

  // ---- Steps ------------------------------------------------------------

  Widget _moodStep(AppLocalizations l10n, JournalFlowState state) {
    final name = ref.watch(authControllerProvider).user?.name.trim() ?? '';
    final firstName = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    // Same periods as the Home greeting, so both screens agree after midnight.
    final dayPart = switch (greeting.dayPeriodFor(ref.watch(greeting.homeClockProvider)())) {
      greeting.DayPeriod.morning => l10n.jv2GoodMorning,
      greeting.DayPeriod.afternoon => l10n.jv2GoodAfternoon,
      greeting.DayPeriod.evening => l10n.jv2GoodEvening,
    };
    final hello = firstName.isEmpty ? l10n.jv2Hello : l10n.jv2HelloName(firstName);
    final emotional = _area == JournalArea.emotional;
    return _StepLayout(
      lead: '$hello $dayPart',
      axisLabel: JournalLabels.axis(l10n, _area.key),
      axisColor: emotional ? AppColors.dualisSymbolGreen : AppColors.dualisSymbolBlue,
      question: l10n.jv2MoodQuestion,
      children: [
        for (final mood in JournalKeys.newEntryMoods)
          _ChoiceTile(
            key: Key('jv2_mood_$mood'),
            leading: _MoodIcon(mood),
            label: JournalLabels.mood(l10n, mood),
            large: true,
            enabled: !state.isSaving,
            onTap: () {
              if (_controller.chooseMood(mood, area: _area)) _save();
            },
          ),
        if (state.isSaving)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _timeStep(AppLocalizations l10n, JournalFlowState state) {
    return _StepLayout(
      lead: _phrase(l10n, state),
      question: l10n.jv2TimeQuestion,
      children: [
        for (final time in JournalKeys.times)
          _ChoiceTile(
            key: Key('jv2_time_$time'),
            emoji: journalEmojis[time],
            label: JournalLabels.root(l10n, time),
            onTap: () => _controller.chooseTime(time),
          ),
      ],
    );
  }

  Widget _branchStep(
    AppLocalizations l10n,
    JournalFlowState state,
    Map<String, List<String>> branches,
    String root,
  ) {
    return _StepLayout(
      eyebrow: JournalLabels.root(l10n, root),
      lead: _phrase(l10n, state),
      question: l10n.jv2BranchQuestion,
      children: [
        for (final branch in branches.keys)
          _ChoiceTile(
            key: Key('jv2_branch_$root.$branch'),
            emoji: journalEmojis['$root.$branch'],
            label: JournalLabels.branch(l10n, '$root.$branch'),
            onTap: () => _controller.chooseBranch(branch),
          ),
      ],
    );
  }

  /// "É dor ou incômodo?" (required) and the branches of the region, for
  /// the side it was marked on.
  Widget _regionBranchStep(AppLocalizations l10n, JournalFlowState state) {
    final current = state.currentRegion!;
    final region = current.region;
    final side = current.side;
    final sideLabel = side == null
        ? null
        : (side == JournalKeys.sideBack ? l10n.jv2BodyBack : l10n.jv2BodyFront);
    final rootLabel = JournalLabels.root(l10n, region);
    final branches = JournalKeys.branchesFor(region, side);
    final hasSensation = state.sensation != null;
    return _StepLayout(
      eyebrow: sideLabel == null ? rootLabel : '$rootLabel · $sideLabel',
      lead: _phrase(l10n, state),
      question: l10n.jv2SensationQuestion,
      children: [
        for (final sensation in JournalKeys.sensations)
          _ChoiceTile(
            key: Key('jv2_sensation_$sensation'),
            label: JournalLabels.sensation(l10n, sensation),
            selected: state.sensation == sensation,
            onTap: () => _controller.chooseSensation(sensation),
          ),
        const SizedBox(height: 8),
        _SectionLabel(l10n.jv2BranchQuestion, strong: true),
        for (final branch in branches.keys)
          _ChoiceTile(
            key: Key('jv2_branch_$region.$branch'),
            emoji: journalEmojis['$region.$branch'],
            label: JournalLabels.branch(l10n, '$region.$branch'),
            enabled: hasSensation,
            onTap: () => _controller.chooseBranch(branch),
          ),
      ],
    );
  }

  Widget _optionsStep(
    AppLocalizations l10n,
    JournalFlowState state,
    List<String> options,
    String prefix,
    VoidCallback onConfirm,
  ) {
    return _StepLayout(
      eyebrow: JournalLabels.branch(l10n, prefix),
      question: l10n.jv2OptionsQuestion,
      hint: l10n.jv2MultiSelectHint,
      bottom: _ContinueButton(
        label: l10n.jv2Continue,
        onPressed: state.hasOptionSelection ? onConfirm : null,
      ),
      children: [
        for (final option in options)
          _ChoiceTile(
            key: Key('jv2_option_$prefix.$option'),
            emoji: journalEmojis['$prefix.$option'],
            label: JournalLabels.option(l10n, '$prefix.$option'),
            selected: state.selectedOptions.contains('$prefix.$option'),
            multi: true,
            onTap: () => _controller.toggleOption('$prefix.$option'),
          ),
        if (state.customLabels.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in state.customLabels)
                InputChip(
                  key: Key('jv2_custom_chip_$label'),
                  label: Text(label),
                  selected: true,
                  onDeleted: () => _controller.removeCustomLabel(label),
                  deleteButtonTooltipMessage: l10n.jv2Remove,
                ),
            ],
          ),
        const SizedBox(height: 8),
        if (_writingCustom)
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('jv2_custom_field'),
                  controller: _customController,
                  autofocus: true,
                  maxLength: JournalKeys.customLabelMaxLength,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(hintText: l10n.jv2WriteMineHint),
                  onSubmitted: (_) => _addCustom(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('jv2_custom_add'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: _suggestingCustom ? null : _addCustom,
                child: Text(l10n.jv2WriteMineAdd),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            key: const Key('jv2_write_mine'),
            onPressed: () => setState(() => _writingCustom = true),
            icon: const Text('✏️'),
            label: Text(l10n.jv2WriteMine),
          ),
      ],
    );
  }

  Future<void> _addCustom() async {
    final clean = JournalKeys.limitChars(
      _customController.text.trim(),
      JournalKeys.customLabelMaxLength,
    );
    if (clean.isEmpty) return;
    final state = ref.read(journalFlowControllerProvider);
    final physical = state.step == JournalStep.regionOptions;
    final kind =
        physical ? JournalKeys.kindPhysical : JournalKeys.kindEmotional;
    // Only options of the branch on screen, so an accepted one shows up here.
    final branch = physical
        ? '${state.currentRegion!.region}.${state.branch}'
        : '${state.time}.${state.branch}';
    setState(() => _suggestingCustom = true);
    String? key;
    try {
      key = await ref.read(journalRepositoryProvider).suggestOption(
            text: clean,
            kind: kind,
            branch: branch,
          );
      if (key != null && !key.startsWith('$branch.')) key = null;
    } catch (_) {
      key = null;
    }
    if (!mounted) return;
    setState(() => _suggestingCustom = false);
    final l10n = AppLocalizations.of(context);
    final optionLabel = key == null ? '' : JournalLabels.option(l10n, key);
    if (key != null && optionLabel.isNotEmpty) {
      final useChip = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('jv2_suggest_dialog'),
          title: Text(l10n.jv2SuggestTitle),
          content: Text(l10n.jv2SuggestBody(optionLabel)),
          actions: [
            TextButton(
              key: const Key('jv2_suggest_no'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.jv2SuggestNo),
            ),
            FilledButton(
              key: const Key('jv2_suggest_yes'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.jv2SuggestYes),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (useChip == true) {
        _controller.toggleOption(key);
        _customController.clear();
        setState(() => _writingCustom = false);
        return;
      }
    }
    _controller.addCustomLabel(clean);
    _customController.clear();
    setState(() => _writingCustom = false);
  }

  Widget _moreStep(
    AppLocalizations l10n,
    JournalFlowState state,
    String question,
    ValueChanged<bool> onAnswer,
  ) {
    return _StepLayout(
      question: question,
      children: [
        if (state.itemLimitReached)
          _SectionLabel(l10n.jv2ItemLimit(JournalKeys.maxItems)),
        _ChoiceTile(
          key: const Key('jv2_more_yes'),
          emoji: '➕',
          label: l10n.jv2Yes,
          enabled: !state.itemLimitReached,
          onTap: () => onAnswer(true),
        ),
        _ChoiceTile(
          key: const Key('jv2_more_no'),
          emoji: '➡️',
          label: l10n.jv2No,
          onTap: () => onAnswer(false),
        ),
      ],
    );
  }

  Widget _bodyStep(
    AppLocalizations l10n,
    JournalFlowState state,
    List<UserCondition> conditions,
  ) {
    final selected = {for (final r in state.selectedRegions) r.region};
    final visible = BodyRegionMap.regionsFor(state.bodySide);
    return _StepLayout(
      lead: _phrase(l10n, state),
      question: l10n.jv2BodyQuestion,
      hint: l10n.jv2BodyHint,
      bottom: _ContinueButton(
        label: l10n.jv2Continue,
        onPressed: state.hasBodySelection
            ? () => _controller.confirmBody(conditions: conditions)
            : null,
      ),
      children: [
        Center(
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: JournalKeys.sideFront,
                label: Text(l10n.jv2BodyFront, key: const Key('jv2_side_front')),
              ),
              ButtonSegment(
                value: JournalKeys.sideBack,
                label: Text(l10n.jv2BodyBack, key: const Key('jv2_side_back')),
              ),
            ],
            selected: {state.bodySide},
            onSelectionChanged: (s) => _controller.setBodySide(s.first),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: BodyRegionMap(
              side: state.bodySide,
              selected: selected,
              onToggle: _controller.toggleRegion,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final region in JournalKeys.bodyRegions)
              if (visible.contains(region) || selected.contains(region))
                FilterChip(
                  key: Key('jv2_region_$region'),
                  label: Text(JournalLabels.root(l10n, region)),
                  selected: selected.contains(region),
                  onSelected: (_) => _controller.toggleRegion(region),
                ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionLabel(l10n.jv2WholeBody),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final region in JournalKeys.wholeBodyAreas)
              FilterChip(
                key: Key('jv2_region_$region'),
                label: Text(JournalLabels.root(l10n, region)),
                selected: selected.contains(region),
                onSelected: (_) => _controller.toggleRegion(region),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionLabel(l10n.jv2AreaConditions),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in conditions)
              FilterChip(
                key: Key('jv2_condition_${c.id}'),
                label: Text(c.label),
                selected: state.selectedConditionIds.contains(c.id),
                onSelected: (_) => _controller.toggleCondition(c.id),
              ),
            ActionChip(
              key: const Key('jv2_condition_add'),
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.jv2ConditionsAdd),
              onPressed: _addCondition,
            ),
          ],
        ),
      ],
    );
  }

  /// Opens "Minhas condições"; the list is read again on return.
  Future<void> _addCondition() async {
    await context.push(RoutePaths.myConditions);
    if (!mounted) return;
    ref.invalidate(userConditionsProvider);
  }

  Widget _intensityStep(AppLocalizations l10n, JournalFlowState state) {
    final items = state.items;
    final single = items.length == 1;
    return _StepLayout(
      lead: _phrase(l10n, state),
      question: single
          ? (items.first.kind == JournalKeys.kindCondition
              ? l10n.jv2ConditionCardQuestion(items.first.conditionLabel ?? '')
              : l10n.jv2IntensityQuestion)
          : l10n.jv2IntensityCompactQuestion,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const JournalEmergencyLine(),
          _ContinueButton(
            label: l10n.jv2Continue,
            onPressed: state.allItemsReady ? _controller.confirmIntensity : null,
          ),
        ],
      ),
      children: [
        for (var index = 0; index < items.length; index++)
          single
              ? _singleItemIntensity(l10n, items.first)
              : _compactItemRow(l10n, items[index], index),
      ],
    );
  }

  Widget _persistenceChips(AppLocalizations l10n, JournalItem item, int index) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final p in JournalKeys.persistences)
          ChoiceChip(
            key: Key('jv2_persistence_${index}_$p'),
            label: Text('${journalEmojis[p]} ${JournalLabels.persistence(l10n, p)}'),
            selected: item.persistence == p,
            onSelected: (_) => _controller.setPersistence(item.draftId, p),
          ),
      ],
    );
  }

  Widget _singleItemIntensity(AppLocalizations l10n, JournalItem item) {
    final isCondition = item.kind == JournalKeys.kindCondition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isCondition) _SectionLabel(journalItemTitle(l10n, item)),
        _SectionLabel(
          isCondition ? l10n.jv2PersistenceOptional : l10n.jv2PersistenceQuestion,
        ),
        _persistenceChips(l10n, item, 0),
        const SizedBox(height: 16),
        if (!isCondition) _SectionLabel(l10n.jv2IntensityQuestion, strong: true),
        IntensityScaleFull(
          keyPrefix: 'jv2_intensity_0',
          value: item.intensity,
          physical: item.kind == JournalKeys.kindPhysical,
          onChanged: (v) => _controller.setIntensity(item.draftId, v),
        ),
      ],
    );
  }

  Widget _compactItemRow(AppLocalizations l10n, JournalItem item, int index) {
    final isCondition = item.kind == JournalKeys.kindCondition;
    return Card(
      key: Key('jv2_item_row_$index'),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isCondition
                  ? l10n.jv2ConditionCardQuestion(item.conditionLabel ?? '')
                  : journalItemTitle(l10n, item),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (isCondition)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l10n.jv2PersistenceOptional,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            _persistenceChips(l10n, item, index),
            const SizedBox(height: 8),
            IntensityScaleCompact(
              keyPrefix: 'jv2_intensity_$index',
              value: item.intensity,
              physical: item.kind == JournalKeys.kindPhysical,
              onChanged: (v) => _controller.setIntensity(item.draftId, v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _triggersStep(AppLocalizations l10n, JournalFlowState state) {
    final offered = JournalKeys.triggersFor(hasPhysicalItem: state.hasPhysicalItem);
    return _StepLayout(
      lead: _phrase(l10n, state),
      question: l10n.jv2TriggersQuestion,
      hint: l10n.jv2MultiSelectHint,
      bottom: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('jv2_skip'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () {
                _triggerNoteController.clear();
                _controller.confirmTriggers(skip: true);
              },
              child: Text(l10n.jv2Skip),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ContinueButton(
              label: l10n.jv2Continue,
              onPressed: () => _controller.confirmTriggers(),
            ),
          ),
        ],
      ),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in offered)
              FilterChip(
                key: Key('jv2_trigger_$t'),
                label: Text('${journalEmojis[t]} ${JournalLabels.trigger(l10n, t)}'),
                selected: state.triggers.contains(t),
                onSelected: (_) => _controller.toggleTrigger(t),
              ),
          ],
        ),
        if (state.triggers.contains(JournalKeys.triggerOutro)) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('jv2_trigger_note'),
            controller: _triggerNoteController,
            maxLength: JournalKeys.triggerNoteMaxLength,
            decoration: InputDecoration(hintText: l10n.jv2TriggerNoteHint),
            onChanged: _controller.setTriggerNote,
          ),
        ],
      ],
    );
  }

  Widget _noteStep(AppLocalizations l10n, JournalFlowState state) {
    return _StepLayout(
      question: l10n.jv2NoteQuestion,
      bottom: _ContinueButton(
        key: const Key('jv2_save'),
        label: l10n.jv2Save,
        busy: state.isSaving,
        onPressed: state.isSaving ? null : _save,
      ),
      children: [
        TextField(
          key: const Key('jv2_note_field'),
          controller: _noteController,
          minLines: 4,
          maxLines: 8,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: l10n.jv2NoteHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: _controller.setNote,
        ),
      ],
    );
  }

  String? _phrase(AppLocalizations l10n, JournalFlowState state) {
    final id = state.phraseId;
    return id == null ? null : JournalLabels.phrase(l10n, id);
  }
}

// ---- Building blocks ----------------------------------------------------

class _StepLayout extends StatelessWidget {
  final String? eyebrow;
  final String? lead;

  /// Short label between the lead and the question (the entry axis).
  final String? axisLabel;
  final Color? axisColor;
  final String? question;
  final String? hint;
  final List<Widget> children;
  final Widget? bottom;

  const _StepLayout({
    this.eyebrow,
    this.lead,
    this.axisLabel,
    this.axisColor,
    this.question,
    this.hint,
    required this.children,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dualisSymbolBlue,
                  ),
                ),
              if (lead != null) ...[
                const SizedBox(height: 4),
                Text(
                  lead!,
                  key: const Key('jv2_phrase'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, color: secondary),
                ),
              ],
              if (axisLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  axisLabel!,
                  key: const Key('jv2_axis_label'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: axisColor ?? AppColors.dualisSymbolBlue,
                  ),
                ),
              ],
              if (question != null) ...[
                const SizedBox(height: 6),
                Text(
                  question!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  hint!,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: secondary),
                ),
              ],
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
        if (bottom != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: bottom,
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool strong;

  const _SectionLabel(this.text, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: strong ? 16 : 14,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String? emoji;

  /// Drawn instead of [emoji] when set.
  final Widget? leading;
  final String label;
  final bool selected;
  final bool multi;
  final bool large;
  final bool enabled;
  final VoidCallback onTap;

  const _ChoiceTile({
    super.key,
    this.emoji,
    this.leading,
    required this.label,
    this.selected = false,
    this.multi = false,
    this.large = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: multi ? selected : null,
        child: Material(
          color: selected
              ? AppColors.dualisSymbolBlue.withValues(alpha: 0.12)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: large ? 20 : 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? AppColors.dualisSymbolBlue
                      : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 14),
                  ] else if (emoji != null) ...[
                    Text(emoji!, style: TextStyle(fontSize: large ? 34 : 26)),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: large ? 18 : 15,
                            fontWeight: FontWeight.w600,
                            color: enabled ? null : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (multi)
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected
                          ? AppColors.dualisSymbolBlue
                          : AppColors.outlineLight,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mood icon: green check for "Bem", amber face for "Não tão bem". Same
/// size and shape for both; nothing else on screen depends on the choice.
class _MoodIcon extends StatelessWidget {
  final String mood;

  const _MoodIcon(this.mood);

  static const Color _amber = Color(0xFFE0A100);

  @override
  Widget build(BuildContext context) {
    final bem = mood == JournalKeys.moodBem;
    final color = bem ? AppColors.dualisSymbolGreen : _amber;
    return Container(
      key: Key('jv2_mood_icon_$mood'),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        bem ? Icons.check_circle_rounded : Icons.sentiment_dissatisfied_rounded,
        color: color,
        size: 32,
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const _ContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: key == null ? const Key('jv2_continue') : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.dualisSymbolBlue,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
