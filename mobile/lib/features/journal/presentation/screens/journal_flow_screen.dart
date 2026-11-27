import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/voice/voice_matcher.dart';
import '../../../../core/voice/voice_targets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/fluent_emoji.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../consent/presentation/ai_consent_controller.dart';
import '../../../consent/presentation/ai_consent_widgets.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../../voice/presentation/voice_widgets.dart';
import '../../../dashboard/presentation/screens/check_in_summary_screen.dart';
import '../../../home/domain/home_greeting.dart' as greeting;
import '../../../home/presentation/controllers/trigger_checkin_controller.dart';
import '../../data/journal_repository.dart';
import '../../domain/journal_keys.dart';
import '../../domain/journal_models.dart';
import '../controllers/journal_flow_controller.dart';
import '../controllers/journal_flow_state.dart';
import '../journal_item_text.dart';
import '../journal_marks.dart';
import '../journal_labels.dart';
import '../widgets/body_region_map.dart';
import '../widgets/condition_readings_card.dart';
import '../widgets/describe_sheet.dart';
import '../../../../shared/widgets/motion.dart';
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

  /// Tracked conditions whose reading card is open.
  final Set<String> _openConditions = {};
  String _triggerTab = 'dia';

  JournalFlowController get _controller =>
      ref.read(journalFlowControllerProvider.notifier);

  JournalArea get _area => widget.args.initialArea ?? JournalArea.emotional;

  bool get _isMale {
    final activeGender = ref.watch(activeProfileControllerProvider).activeProfile?.gender;
    if (activeGender != null && activeGender.isNotEmpty) {
      return activeGender.toLowerCase() == 'masculino';
    }
    final userGender = ref.watch(authControllerProvider).user?.gender;
    return userGender == Gender.masculino;
  }

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
      final entry = await _controller.save(isMale: _isMale);
      if (!mounted) return;
      unawaited(HapticFeedback.lightImpact());
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
  void _updateHome(AppLocalizations l10n, JournalEntry entry) {
    ref.read(triggerCheckInProvider.notifier).applyJournalEntry(l10n, entry);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(journalFlowControllerProvider);
    final conditions = ref.watch(userConditionsProvider).value ?? const [];
    final stepToken =
        '${state.step.name}-${state.time}-${state.regionIndex}-${state.branch}';
    ref.read(voiceTargetRegistryProvider).activeStep = stepToken;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: VoiceTarget(
              labels: [l10n.jv2Back, ...VoiceMatcher.aliases(l10n.voiceAliasBack)],
              onSelect: _back,
              role: VoiceTargetRole.back,
              child: Center(
                child: IconButton(
                  key: const Key('jv2_back'),
                  tooltip: l10n.jv2Back,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.glassFillStrong,
                    foregroundColor: AppColors.dualisNavy,
                    fixedSize: const Size(40, 40),
                    side: BorderSide(color: AppColors.dualisNavy.withValues(alpha: 0.08)),
                  ),
                  onPressed: _back,
                ),
              ),
            ),
          ),
          title: Text(
            l10n.jv2FlowTitle,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.dualisNavy,
            ),
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
              key: ValueKey(stepToken),
              // Voice answers only the step coming in, not the one leaving.
              child: VoiceStep(
                token: stepToken,
                child: _buildStep(context, l10n, state, conditions),
              ),
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
      case JournalStep.positiveStart:
        return _positiveStartStep(l10n, state);
      case JournalStep.positiveOptions:
        return _optionsStep(
          l10n,
          state,
          JournalKeys.positiveTree[state.time]![state.branch]!,
          '${state.time}.${state.branch}',
          () {
            if (_controller.confirmPositiveOptions()) _save();
          },
          confirmKey: const Key('jv2_save'),
          confirmLabel: l10n.jv2Save,
          confirmSaves: true,
        );
      case JournalStep.time:
        return _timeStep(l10n, state);
      case JournalStep.branch:
        return _branchStep(l10n, state);
      case JournalStep.options:
        return _optionsStep(
          l10n,
          state,
          JournalKeys.emotionalTree[state.time]![state.branch]!,
          '${state.time}.${state.branch}',
          _controller.confirmEmotionalOptions,
          moreLabel: l10n.jv23MoreEmotional,
          onMore: () => _controller.confirmEmotionalOptions(more: true),
        );
      case JournalStep.body:
        return _bodyStep(l10n, state, conditions);
      case JournalStep.conditions:
        return _bemConditionsStep(l10n, state, conditions);
      case JournalStep.regionBranch:
        return _regionBranchStep(l10n, state);
      case JournalStep.regionOptions:
        final region = state.currentRegion!.region;
        final lastRegion = state.regionIndex == state.selectedRegions.length - 1;
        final branches = JournalKeys.branchesFor(region, state.currentRegion!.side, isMale: _isMale);
        final options = branches[state.branch] ?? JournalKeys.physicalTree[region]![state.branch]!;
        return _optionsStep(
          l10n,
          state,
          options,
          '$region.${state.branch}',
          _controller.confirmPhysicalOptions,
          moreLabel: lastRegion ? l10n.jv23MoreBody : null,
          onMore: () => _controller.confirmPhysicalOptions(more: true),
        );
      case JournalStep.persistence:
        return _persistenceStep(l10n, state);
      case JournalStep.intensity:
        return _intensityStep(l10n, state);
      case JournalStep.triggers:
        return _triggersStep(l10n, state);
      case JournalStep.closing:
        return _closingStep(l10n, state);
      case JournalStep.note:
        return _noteStep(l10n, state);
    }
  }

  /// Screen number and screen count of the path (v2.3 progress bar).
  (int, int) _progress(JournalFlowState state) {
    if (_area == JournalArea.physical) {
      final index = switch (state.step) {
        JournalStep.mood => 1,
        JournalStep.body || JournalStep.conditions => 2,
        JournalStep.regionBranch => 3,
        JournalStep.regionOptions => 4,
        JournalStep.persistence => 5,
        JournalStep.intensity => 6,
        JournalStep.triggers => 7,
        JournalStep.closing => 8,
        _ => 9,
      };
      return (index, 9);
    }
    if (state.mood == JournalKeys.moodBem) {
      final index = switch (state.step) {
        JournalStep.mood => 1,
        JournalStep.positiveStart => 2,
        _ => 3,
      };
      return (index, 3);
    }
    final index = switch (state.step) {
      JournalStep.mood => 1,
      JournalStep.time => 2,
      JournalStep.branch => 3,
      JournalStep.options => 4,
      JournalStep.persistence => 5,
      JournalStep.intensity => 6,
      JournalStep.triggers => 7,
      JournalStep.closing => 8,
      _ => 9,
    };
    return (index, 9);
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
      progress: _progress(state),
      lead: '$hello $dayPart',
      axisLabel: JournalLabels.axis(l10n, _area.key),
      axisColor: emotional ? AppColors.dualisSymbolGreen : AppColors.dualisSymbolBlue,
      question: l10n.jv2MoodQuestion,
      hint: l10n.jv23TapOneHint,
      children: [
        _CardGrid(
          columns: 2,
          children: [
            for (final mood in JournalKeys.newEntryMoods)
              _ChoiceCard(
                key: Key('jv2_mood_$mood'),
                leading: _MoodIcon(mood),
                label: JournalLabels.mood(l10n, mood),
                large: true,
                showCheck: false,
                enabled: !state.isSaving,
                // Physical "Bem" may save at once (no tracked conditions):
                // only said alone, never from a multi-answer phrase.
                saves: !emotional && mood == JournalKeys.moodBem,
                onTap: () => _chooseMood(mood),
              ),
          ],
        ),
        if (state.isSaving)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  /// Branches of a tree under the label of their time: one tap picks both.
  List<Widget> _branchRows(
    AppLocalizations l10n,
    Map<String, Map<String, List<String>>> tree, {
    bool enabled = true,
  }) =>
      [
        for (final time in tree.keys) ...[
          _CapsLabel(JournalLabels.root(l10n, time)),
          for (final branch in tree[time]!.keys)
            _ChoiceTile(
              key: Key('jv2_branch_$time.$branch'),
              emoji: journalEmojis['$time.$branch'],
              emojiKey: '$time.$branch',
              label: JournalLabels.branch(l10n, '$time.$branch'),
              dense: true,
              enabled: enabled,
              onTap: () => _controller.chooseTimeBranch(time, branch),
            ),
        ],
      ];

  void _chooseMood(String mood) {
    final conditions = ref.read(userConditionsProvider).value ?? const <UserCondition>[];
    if (_controller.chooseMood(mood, area: _area, conditions: conditions)) {
      _save();
      return;
    }
    if (ref.read(journalFlowControllerProvider).step == JournalStep.conditions) {
      // Bem with tracked conditions: every reading card starts open.
      setState(() => _openConditions.addAll([
            for (final c in conditions)
              if (_controller.tracksReadings(c)) c.id,
          ]));
    }
  }

  /// Bem on the physical axis with tracked conditions (v2.4, Premium): the
  /// reading cards, "Só registrar medições" and "Salvar sem medições".
  Widget _bemConditionsStep(
    AppLocalizations l10n,
    JournalFlowState state,
    List<UserCondition> conditions,
  ) {
    return _StepLayout(
      progress: _progress(state),
      question: l10n.jv2AreaConditions,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ContinueButton(
            key: const Key('chronicTrack_just_log'),
            label: l10n.chronicTrackJustLog,
            saves: true,
            busy: state.isSaving,
            onPressed: state.hasReadings && !state.isSaving
                ? () {
                    if (_controller.confirmReadingsOnly(conditions: conditions)) _save();
                  }
                : null,
          ),
          const SizedBox(height: 4),
          VoiceTarget(
            labels: [l10n.chronicTrackSaveWithout],
            role: VoiceTargetRole.other,
            onSelect: state.isSaving
                ? null
                : () {
                    _controller.clearReadingsForSave();
                    _save();
                  },
            child: const SizedBox.shrink(),
          ),
          TextButton(
            key: const Key('chronicTrack_save_without'),
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: state.isSaving
                ? null
                : () {
                    _controller.clearReadingsForSave();
                    _save();
                  },
            child: Text(
              l10n.chronicTrackSaveWithout,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      children: [
        Container(
          key: const Key('chronicTrack_bem_banner'),
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.dualisSymbolBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            l10n.chronicTrackBemBanner,
            style: GoogleFonts.inter(fontSize: 14, height: 1.4),
          ),
        ),
        ..._conditionTiles(l10n, state, conditions, trackedOnly: true),
      ],
    );
  }

  /// "Minhas condições" as a list: an untracked condition is picked for the
  /// 1-5 card; a tracked one (Premium) opens its reading card.
  List<Widget> _conditionTiles(
    AppLocalizations l10n,
    JournalFlowState state,
    List<UserCondition> conditions, {
    bool trackedOnly = false,
  }) {
    return [
      for (final c in conditions)
        if (_controller.tracksReadings(c))
          _ConditionTile(
            key: Key('jv2_condition_${c.id}'),
            label: c.label,
            subtitle: (state.conditionReadings[c.id] ?? const []).isEmpty
                ? l10n.chronicTrackTapToLog
                : l10n.chronicTrackReadingsCount(state.conditionReadings[c.id]!.length),
            selected: (state.conditionReadings[c.id] ?? const []).isNotEmpty,
            expandable: true,
            open: _openConditions.contains(c.id),
            onTap: () => setState(() {
              if (!_openConditions.remove(c.id)) _openConditions.add(c.id);
            }),
            child: ConditionReadingsCard(
              keyPrefix: 'chronicTrack_${c.id}',
              tracking: c.tracking,
              initialReadings: state.conditionReadings[c.id] ?? const [],
              onChanged: (readings) => _controller.setConditionReadings(c.id, readings),
            ),
          )
        else if (!trackedOnly)
          _ConditionTile(
            key: Key('jv2_condition_${c.id}'),
            label: c.label,
            selected: state.selectedConditionIds.contains(c.id),
            onTap: () => _controller.toggleCondition(c.id),
          ),

    ];
  }

  /// "Bem": "Só registrar" saves at once; a good moment opens its options.
  Widget _positiveStartStep(AppLocalizations l10n, JournalFlowState state) {
    return _StepLayout(
      progress: _progress(state),
      question: l10n.jv22PositiveQuestion,
      children: [
        _ContinueButton(
          key: const Key('jv22_just_save'),
          label: l10n.jv22JustSave,
          saves: true,
          busy: state.isSaving,
          onPressed: state.isSaving ? null : _save,
        ),
        const SizedBox(height: 16),
        _SectionLabel(l10n.jv22PositiveTimeHint),
        ..._branchRows(l10n, JournalKeys.positiveTree, enabled: !state.isSaving),
      ],
    );
  }

  /// Screen 1 of "Não tão bem": three big cards, one per time.
  Widget _timeStep(AppLocalizations l10n, JournalFlowState state) {
    return _StepLayout(
      progress: _progress(state),
      lead: _phrase(l10n, state),
      question: l10n.jv2TimeQuestion,
      hint: l10n.jv23TapOneHint,
      children: [
        for (final time in JournalKeys.times)
          _ChoiceTile(
            key: Key('jv2_time_$time'),
            emojiKey: time,
            label: JournalLabels.root(l10n, time),
            onTap: () => _controller.chooseTime(time),
          ),
        if (describeAvailable(ref)) _describeTile(l10n),
      ],
    );
  }

  /// "Descrever com minhas palavras" (Premium): an action row like
  /// "Escrever o meu".
  Widget _describeTile(AppLocalizations l10n) {
    final isMale = _isMale;
    return _ChoiceTile(
      key: const Key('jv2_describe'),
      emojiKey: 'descrever',
      label: l10n.jv2DescribeTile,
      accent: true,
      voiceRole: VoiceTargetRole.other,
      onTap: () => _describe(isMale: isMale),
    );
  }

  /// Opens the free description. Only the options the person turned on
  /// reach the entry; the text becomes the note only when they asked.
  Future<void> _describe({required bool isMale}) async {
    final area = ref.read(journalFlowControllerProvider).area;
    final result = await showDescribeSheet(context, area: area, isMale: isMale);
    if (!mounted || result == null) return;
    if (result.keepAsNote && result.text.isNotEmpty) {
      // Added after what the note already says, never in its place.
      final current = _noteController.text.trim();
      final merged = current.isEmpty ? result.text : '$current\n\n${result.text}';
      final note = JournalKeys.limitChars(merged, JournalKeys.noteMaxLength);
      _noteController.text = note;
      _controller.setNote(note);
    }
    if (result.keys.isNotEmpty) {
      _controller.applySuggestedOptions(result.keys, isMale: isMale);
    }
  }

  /// Screen 2: the branches of the time picked on screen 1.
  Widget _branchStep(AppLocalizations l10n, JournalFlowState state) {
    final time = state.time!;
    final question = switch (time) {
      'passado' => l10n.jv24BranchQuestionPassado,
      'presente' => l10n.jv24BranchQuestionPresente,
      _ => l10n.jv24BranchQuestionFuturo,
    };
    return _StepLayout(
      progress: _progress(state),
      eyebrow: JournalLabels.root(l10n, time),
      eyebrowMark: time,
      lead: _phrase(l10n, state),
      question: question,
      hint: l10n.jv23TapOneHint,
      children: [
        for (final branch in JournalKeys.emotionalTree[time]!.keys)
          _ChoiceTile(
            key: Key('jv2_branch_$time.$branch'),
            emoji: journalEmojis['$time.$branch'],
            emojiKey: '$time.$branch',
            label: JournalLabels.branch(l10n, '$time.$branch'),
            onTap: () => _controller.chooseTimeBranch(time, branch),
          ),
      ],
    );
  }

  /// The branches of the region, for the side it was marked on. Since v2.5
  /// there is no "É dor ou incômodo?" step and at most 2 branches.
  Widget _regionBranchStep(AppLocalizations l10n, JournalFlowState state) {
    final current = state.currentRegion!;
    final region = current.region;
    final side = current.side;
    final sideLabel = side == null
        ? null
        : (side == JournalKeys.sideBack ? l10n.jv2BodyBack : l10n.jv2BodyFront);
    final rootLabel = JournalLabels.root(l10n, region);
    final branches = JournalKeys.branchesFor(region, side, isMale: _isMale);
    return _StepLayout(
      progress: _progress(state),
      eyebrow: sideLabel == null ? rootLabel : '$rootLabel · $sideLabel',
      lead: _phrase(l10n, state),
      question: l10n.jv23WhereExactly,
      hint: l10n.jv23TapOneHint,
      children: [
        for (final branch in branches.keys)
          _ChoiceTile(
            key: Key('jv2_branch_$region.$branch'),
            emojiKey: '$region.$branch',
            label: JournalLabels.branch(l10n, '$region.$branch'),
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
    VoidCallback onConfirm, {
    Key? confirmKey,
    String? confirmLabel,
    bool confirmSaves = false,
    String? moreLabel,
    VoidCallback? onMore,
  }) {
    final canConfirm = state.hasOptionSelection && !state.isSaving;
    final showMore = moreLabel != null && onMore != null && !state.itemLimitReached;
    return _StepLayout(
      progress: _progress(state),
      eyebrow: JournalLabels.branch(l10n, prefix),
      lead: _phrase(l10n, state),
      question: l10n.jv2OptionsQuestion,
      hint: l10n.jv2MultiSelectHint,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showMore)
            VoiceTarget(
              labels: [moreLabel],
              onSelect: canConfirm ? onMore : null,
              role: VoiceTargetRole.other,
              child: const SizedBox.shrink(),
            ),
          if (showMore)
            TextButton(
              key: const Key('jv23_more'),
              onPressed: canConfirm ? onMore : null,
              child: Text(
                '+ $moreLabel',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          _ContinueButton(
            key: confirmKey,
            label: confirmLabel ?? l10n.jv2Continue,
            saves: confirmSaves,
            busy: state.isSaving,
            onPressed: canConfirm ? onConfirm : null,
          ),
        ],
      ),
      children: [
        for (final option in options)
          _ChoiceTile(
            key: Key('jv2_option_$prefix.$option'),
            emojiKey: '$prefix.$option',
            label: JournalLabels.option(l10n, '$prefix.$option'),
            selected: state.selectedOptions.contains('$prefix.$option'),
            multi: true,
            onTap: () => _controller.toggleOption('$prefix.$option'),
          ),
        // What the person wrote: a row like the others; tapping removes it.
        for (final label in state.customLabels)
          _ChoiceTile(
            key: Key('jv2_custom_chip_$label'),
            emojiKey: 'outro',
            label: label,
            selected: true,
            multi: true,
            semanticsHint: l10n.jv2Remove,
            voiceRole: VoiceTargetRole.other,
            personal: true,
            onTap: () => _controller.removeCustomLabel(label),
          ),
        const SizedBox(height: 8),
        if (_writingCustom)
          Row(
            children: [
              Expanded(
                child: VoiceTextSink(
                  // Hands-free: what is said becomes the label, as if typed.
                  onText: _suggestingCustom
                      ? null
                      : (text) {
                          _customController.text = text;
                          _addCustom();
                        },
                  child: TextField(
                    key: const Key('jv2_custom_field'),
                    controller: _customController,
                    autofocus: true,
                    maxLength: JournalKeys.customLabelMaxLength,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l10n.jv2WriteMineHint,
                      suffixIcon: voiceAvailable(ref)
                          ? VoiceDictationButton(
                              controller: _customController,
                              fieldKey: 'custom',
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _addCustom(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              VoiceTarget(
                labels: [l10n.jv2WriteMineAdd],
                onSelect: _suggestingCustom ? null : _addCustom,
                role: VoiceTargetRole.other,
                child: const SizedBox.shrink(),
              ),
              FilledButton(
                key: const Key('jv2_custom_add'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: _suggestingCustom ? null : _addCustom,
                child: Text(l10n.jv2WriteMineAdd),
              ),
            ],
          )
        else
          _ChoiceTile(
            key: const Key('jv2_write_mine'),
            emojiKey: 'outro',
            label: l10n.jv2WriteMine,
            accent: true,
            voiceRole: VoiceTargetRole.other,
            onTap: () => setState(() => _writingCustom = true),
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
    // Good moments are never sent to the AI suggestion.
    if (state.step == JournalStep.positiveOptions) {
      _controller.addCustomLabel(clean);
      _customController.clear();
      setState(() => _writingCustom = false);
      return;
    }
    final physical = state.step == JournalStep.regionOptions;
    final kind =
        physical ? JournalKeys.kindPhysical : JournalKeys.kindEmotional;
    // Only options of the branch on screen, so an accepted one shows up here.
    final branch = physical
        ? '${state.currentRegion!.region}.${state.branch}'
        : '${state.time}.${state.branch}';
    setState(() => _suggestingCustom = true);
    final repository = ref.read(journalRepositoryProvider);
    String? key;
    try {
      // Offline the label is kept as typed: no consent dialog, no request.
      // Without the AI consent (declined now or before on this device)
      // nothing is sent either, and a profile shared by another account
      // never gets AI suggestions (nor the consent dialog).
      final online = await repository.isOnline();
      if (!mounted) return;
      final allowed = online &&
          aiProfileAllowed(ref.read(activeProfileControllerProvider).activeProfile) &&
          await ensureAiConsent(context, ref, ask: AiConsentAsk.unlessDeclined);
      if (!mounted) return;
      if (allowed) {
        key = await repository.suggestOption(
          text: clean,
          kind: kind,
          branch: branch,
        );
        if (key != null && !key.startsWith('$branch.')) key = null;
      }
    } on AiSuggestException catch (e) {
      key = null;
      // The server is the authority: read the consent state again.
      if (e.reason == AiSuggestFailure.consentRequired && mounted) {
        await ref.read(aiConsentControllerProvider.notifier).refresh();
      }
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
            VoiceTarget(
              labels: [l10n.jv2SuggestNo, ...VoiceMatcher.aliases(l10n.voiceAliasNo)],
              onSelect: () => Navigator.of(ctx).pop(false),
              role: VoiceTargetRole.other,
              child: TextButton(
                key: const Key('jv2_suggest_no'),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.jv2SuggestNo),
              ),
            ),
            VoiceTarget(
              labels: [l10n.jv2SuggestYes, ...VoiceMatcher.aliases(l10n.voiceAliasYes)],
              onSelect: () => Navigator.of(ctx).pop(true),
              role: VoiceTargetRole.other,
              child: FilledButton(
                key: const Key('jv2_suggest_yes'),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.jv2SuggestYes),
              ),
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

  Widget _bodyStep(
    AppLocalizations l10n,
    JournalFlowState state,
    List<UserCondition> conditions,
  ) {
    final selected = {for (final r in state.selectedRegions) r.region};
    final onMap = [
      for (final r in state.selectedRegions)
        if (!JournalKeys.isWholeBody(r.region)) r,
    ];
    final wholeCount = JournalKeys.wholeBodyAreas.where(selected.contains).length;
    return _StepLayout(
      progress: _progress(state),
      lead: _phrase(l10n, state),
      question: l10n.jv2BodyQuestion,
      hint: l10n.jv23BodyMapHint,
      bottom: _ContinueButton(
        label: l10n.jv2Continue,
        onPressed: state.hasBodySelection
            ? () => _controller.confirmBody(conditions: conditions)
            : null,
      ),
      children: [
        if (conditions.isNotEmpty) ...[
          _SectionLabel(l10n.jv2AreaConditions, strong: true),
          ..._conditionTiles(l10n, state, conditions),
          const SizedBox(height: 16),
        ],
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
            showSelectedIcon: false,
            onSelectionChanged: (s) => _controller.setBodySide(s.first),
          ),
        ),
        // By voice, the side not on screen ("Costas" turns the map around;
        // said again on the back view it marks the back region).
        for (final side in [JournalKeys.sideFront, JournalKeys.sideBack])
          VoiceTarget(
            labels: [side == JournalKeys.sideBack ? l10n.jv2BodyBack : l10n.jv2BodyFront],
            onSelect: state.bodySide == side ? null : () => _controller.setBodySide(side),
            role: VoiceTargetRole.other,
            child: const SizedBox.shrink(),
          ),
        const SizedBox(height: 12),
        _GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: BodyRegionMap(
                side: state.bodySide,
                selected: selected,
                onToggle: _controller.toggleRegion,
                labelOf: (region) => JournalLabels.root(l10n, region),
              ),
            ),
          ),
        ),
        if (onMap.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            key: const Key('jv2_marked'),
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                l10n.jv23BodyMarked,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              for (final r in onMap)
                _MarkedPill(
                  key: Key('jv2_marked_${r.region}'),
                  markKey: r.region,
                  label: r.side == JournalKeys.sideBack && r.region != 'costas'
                      ? '${JournalLabels.root(l10n, r.region)} · ${l10n.jv2BodyBack}'
                      : JournalLabels.root(l10n, r.region),
                  removeLabel: l10n.jv23BodyRemove(JournalLabels.root(l10n, r.region)),
                  onRemove: () => _controller.toggleRegion(r.region),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        _TopicCard(
          headerKey: const Key('jv2_topic_whole_body'),
          emoji: '',
          markKey: 'physical',
          title: l10n.jv2WholeBody,
          subtitle: l10n.jv23WholeBodyHint,
          count: wholeCount,
          countLabel: l10n.jv23TopicMarked(wholeCount),
          initiallyOpen: wholeCount > 0,
          children: [
            for (final area in JournalKeys.wholeBodyAreas)
              _OptionCell(
                key: Key('jv2_region_$area'),
                markKey: area,
                label: JournalLabels.root(l10n, area),
                selected: selected.contains(area),
                onTap: () => _controller.toggleRegion(area),
              ),
          ],
        ),
        if (describeAvailable(ref)) ...[
          const SizedBox(height: 12),
          _describeTile(l10n),
        ],
      ],
    );
  }

  /// "Há quanto tempo?" on its own screen (client spec). One item: three big
  /// cards, a tap answers and moves on. Several: one row per item.
  Widget _persistenceStep(AppLocalizations l10n, JournalFlowState state) {
    final items = state.itemsNeedingPersistence;
    final single = items.length == 1;
    final voiceRow = items.indexWhere((i) => i.persistence == null);
    return _StepLayout(
      progress: _progress(state),
      lead: _phrase(l10n, state),
      question: single ? l10n.jv2PersistenceQuestion : l10n.jv24PersistenceCompactQuestion,
      hint: single ? l10n.jv23TapOneHint : null,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const JournalEmergencyLine(),
          if (!single)
            _ContinueButton(
              label: l10n.jv2Continue,
              onPressed: state.allPersistenceReady ? _controller.confirmPersistence : null,
            ),
        ],
      ),
      children: [
        if (single) ...[
          _SectionLabel(journalItemTitle(l10n, items.first)),
          _CardGrid(
            columns: 3,
            children: [
              for (final p in JournalKeys.persistences)
                _ChoiceCard(
                  key: Key('jv2_persistence_0_$p'),
                  markKey: p,
                  label: JournalLabels.persistence(l10n, p),
                  selected: items.first.persistence == p,
                  onTap: () => _controller.choosePersistence(items.first.draftId, p),
                ),
            ],
          ),
        ] else
          for (var index = 0; index < items.length; index++)
            _itemRow(
              l10n,
              items[index],
              index,
              child: _persistencePicker(
                l10n,
                items[index],
                index,
                compact: false,
                voice: index == voiceRow,
              ),
            ),
      ],
    );
  }

  Widget _intensityStep(AppLocalizations l10n, JournalFlowState state) {
    final items = state.itemsNeedingIntensity;
    final single = items.length == 1;
    // Row answered by voice: the first one with an answer missing.
    final voiceRow = items.indexWhere((i) => i.intensity == null);
    return _StepLayout(
      progress: _progress(state),
      lead: _phrase(l10n, state),
      question: single
          ? (items.first.kind == JournalKeys.kindCondition
              ? l10n.jv2ConditionCardQuestion(items.first.conditionLabel ?? '')
              : l10n.jv2IntensityQuestion)
          : l10n.jv2IntensityCompactQuestion,
      // The condition name is the person's own text: never read aloud.
      spokenQuestion: single ? l10n.jv2IntensityQuestion : null,
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
              : _compactItemRow(l10n, items[index], index, voice: index == voiceRow),
      ],
    );
  }

  /// "Há quanto tempo?": three cards (one item) or a compact row (several).
  Widget _persistencePicker(
    AppLocalizations l10n,
    JournalItem item,
    int index, {
    required bool compact,
    bool voice = true,
  }) {
    if (!compact) {
      return _CardGrid(
        columns: 3,
        children: [
          for (final p in JournalKeys.persistences)
            _ChoiceCard(
              key: Key('jv2_persistence_${index}_$p'),
              markKey: p,
              label: JournalLabels.persistence(l10n, p),
              selected: item.persistence == p,
              voice: voice,
              onTap: () => _controller.setPersistence(item.draftId, p),
            ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final p in JournalKeys.persistences)
            VoiceTarget(
              labels: [JournalLabels.persistence(l10n, p)],
              onSelect: voice ? () => _controller.setPersistence(item.draftId, p) : null,
              role: VoiceTargetRole.other,
              child: const SizedBox.shrink(),
            ),
          for (final p in JournalKeys.persistences)
            Expanded(
              child: Semantics(
                button: true,
                selected: item.persistence == p,
                child: InkWell(
                  key: Key('jv2_persistence_${index}_$p'),
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => _controller.setPersistence(item.draftId, p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.persistence == p ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: item.persistence == p
                            ? AppColors.dualisSymbolBlue
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      JournalLabels.persistence(l10n, p),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: item.persistence == p
                            ? AppColors.dualisNavy
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _singleItemIntensity(AppLocalizations l10n, JournalItem item) {
    final isCondition = item.kind == JournalKeys.kindCondition;
    return _GlassCard(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isCondition) _SectionLabel(journalItemTitle(l10n, item)),
        // Conditions keep their optional persistence here (Premium).
        if (isCondition) ...[
          _CapsLabel(l10n.jv2PersistenceOptional),
          _persistencePicker(l10n, item, 0, compact: false),
          _CapsLabel(l10n.jv23HowMuchLabel),
        ],
        IntensityScaleFull(
          keyPrefix: 'jv2_intensity_0',
          value: item.intensity,
          physical: item.kind == JournalKeys.kindPhysical,
          onChanged: (v) => _controller.setIntensity(item.draftId, v),
        ),
      ],
      ),
    );
  }

  /// Several items: by voice, answers go to the first item still missing
  /// an answer, so "três" never lands on two rows at once.
  Widget _compactItemRow(
    AppLocalizations l10n,
    JournalItem item,
    int index, {
    bool voice = false,
  }) {
    final isCondition = item.kind == JournalKeys.kindCondition;
    return _itemRow(
      l10n,
      item,
      index,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conditions keep their optional persistence here (Premium).
          if (isCondition) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.jv2PersistenceOptional,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
            _persistencePicker(l10n, item, index, compact: true, voice: voice),
            const SizedBox(height: 10),
          ],
          IntensityScaleCompact(
            keyPrefix: 'jv2_intensity_$index',
            value: item.intensity,
            physical: item.kind == JournalKeys.kindPhysical,
            voice: voice,
            onChanged: (v) => _controller.setIntensity(item.draftId, v),
          ),
        ],
      ),
    );
  }

  /// One item of the persistence or intensity screen: its title, then [child].
  Widget _itemRow(
    AppLocalizations l10n,
    JournalItem item,
    int index, {
    required Widget child,
  }) {
    final isCondition = item.kind == JournalKeys.kindCondition;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
      key: Key('jv2_item_row_$index'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isCondition
                ? l10n.jv2ConditionCardQuestion(item.conditionLabel ?? '')
                : journalItemTitle(l10n, item),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.dualisNavy,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
      ),
    );
  }

  String _triggerTopicTitle(AppLocalizations l10n, String topic) => switch (topic) {
        'dia' => l10n.jv23TriggerTopicDia,
        'pessoas' => l10n.jv23TriggerTopicPessoas,
        _ => l10n.jv23TriggerTopicCorpo,
      };

  /// Triggers in three tabs of icon cards (v2.3). "Não sei" and "Outro"
  /// sit below the tabs.
  Widget _triggersStep(AppLocalizations l10n, JournalFlowState state) {
    final offered = JournalKeys.triggersFor(
      physicalOptionKeys: state.physicalOptionKeys,
      isMale: _isMale,
    );
    final topics = [
      for (final e in JournalKeys.triggerTopics.entries)
        (e.key, [for (final t in e.value) if (offered.contains(t)) t]),
    ].where((t) => t.$2.isNotEmpty).toList();
    final tab = topics.any((t) => t.$1 == _triggerTab) ? _triggerTab : topics.first.$1;
    final shown = topics.firstWhere((t) => t.$1 == tab).$2;
    return _StepLayout(
      progress: _progress(state),
      lead: _phrase(l10n, state),
      question: l10n.jv2TriggersQuestion,
      hint: l10n.jv23TriggersHint,
      bottom: _skipOrContinue(
        l10n,
        skipKey: const Key('jv2_skip'),
        onSkip: () {
          _triggerNoteController.clear();
          _controller.confirmTriggers(skip: true);
        },
        onContinue: () => _controller.confirmTriggers(),
      ),
      children: [
        _TopicTabs(
          tabs: [
            for (final (topic, triggers) in topics)
              (
                key: Key('jv2_topic_$topic'),
                label: _triggerTopicTitle(l10n, topic),
                count: triggers.where(state.triggers.contains).length,
                countLabel: l10n.jv23TopicMarked(
                  triggers.where(state.triggers.contains).length,
                ),
                selected: topic == tab,
                onTap: () => setState(() => _triggerTab = topic),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _CardGrid(
          columns: 3,
          children: [
            for (final t in shown)
              _ChoiceCard(
                key: Key('jv2_trigger_$t'),
                markKey: t,
                label: JournalLabels.trigger(l10n, t),
                selected: state.triggers.contains(t),
                multi: true,
                onTap: () => _controller.toggleTrigger(t),
              ),
          ],
        ),
        const SizedBox(height: 6),
        _CardGrid(
          columns: 2,
          children: [
            for (final t in [JournalKeys.triggerNaoSei, JournalKeys.triggerOutro])
              _ChoiceCard(
                key: Key('jv2_trigger_$t'),
                markKey: t,
                label: JournalLabels.trigger(l10n, t),
                selected: state.triggers.contains(t),
                multi: true,
                wide: true,
                onTap: () => _controller.toggleTrigger(t),
              ),
          ],
        ),
        if (state.triggers.contains(JournalKeys.triggerOutro)) ...[
          const SizedBox(height: 4),
          VoiceTextSink(
            onText: (text) {
              appendDictation(_triggerNoteController, text);
              _controller.setTriggerNote(_triggerNoteController.text);
            },
            child: TextField(
              key: const Key('jv2_trigger_note'),
              controller: _triggerNoteController,
              maxLength: JournalKeys.triggerNoteMaxLength,
              decoration: InputDecoration(
                hintText: l10n.jv2TriggerNoteHint,
                suffixIcon: voiceAvailable(ref)
                    ? VoiceDictationButton(
                        controller: _triggerNoteController,
                        fieldKey: 'trigger_note',
                        onChanged: _controller.setTriggerNote,
                      )
                    : null,
              ),
              onChanged: _controller.setTriggerNote,
            ),
          ),
        ],
      ],
    );
  }

  Widget _skipOrContinue(
    AppLocalizations l10n, {
    required Key skipKey,
    required VoidCallback onSkip,
    required VoidCallback onContinue,
  }) {
    return Row(
      children: [
        VoiceTarget(
          labels: [l10n.jv2Skip, ...VoiceMatcher.aliases(l10n.voiceAliasSkip)],
          onSelect: onSkip,
          role: VoiceTargetRole.skip,
          child: const SizedBox.shrink(),
        ),
        Expanded(
          child: OutlinedButton(
            key: skipKey,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              side: BorderSide.none,
              backgroundColor: AppColors.dualisNavy.withValues(alpha: 0.08),
            ),
            onPressed: onSkip,
            child: Text(l10n.jv2Skip),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ContinueButton(label: l10n.jv2Continue, onPressed: onContinue),
        ),
      ],
    );
  }

  /// Optional closing questions; "Pular" stays visible. Both questions use
  /// the same card (v2.3).
  Widget _closingStep(AppLocalizations l10n, JournalFlowState state) {
    final isPhysical = _area == JournalArea.physical || state.hasPhysicalItem;
    final helpers = JournalKeys.helpersFor(isPhysical: isPhysical);
    return _StepLayout(
      progress: _progress(state),
      lead: _phrase(l10n, state),
      question: l10n.jv23ClosingTitle,
      hint: l10n.jv23ClosingHint,
      bottom: _skipOrContinue(
        l10n,
        skipKey: const Key('jv22_closing_skip'),
        onSkip: () => _controller.confirmClosing(skip: true),
        onContinue: () => _controller.confirmClosing(),
      ),
      children: [
        _CapsLabel(
          isPhysical
              ? l10n.jv22CopingPhysicalQuestion
              : l10n.jv22CopingQuestion,
        ),
        _CardGrid(
          columns: 3,
          children: [
            for (final c in JournalKeys.copings)
              _ChoiceCard(
                key: Key('jv22_coping_$c'),
                markKey: c,
                label: JournalLabels.coping(l10n, c),
                selected: state.coping == c,
                onTap: () => _controller.chooseCoping(c),
              ),
          ],
        ),
        _CapsLabel(
          isPhysical
              ? l10n.jv22HelpersPhysicalQuestion
              : l10n.jv22HelpersQuestion,
        ),
        _CardGrid(
          columns: 3,
          children: [
            for (final h in helpers)
              _ChoiceCard(
                key: Key('jv22_helper_$h'),
                markKey: h,
                label: JournalLabels.helper(l10n, h),
                selected: state.helpers.contains(h),
                multi: true,
                onTap: () => _controller.toggleHelper(h),
              ),
          ],
        ),
      ],
    );
  }

  Widget _noteStep(AppLocalizations l10n, JournalFlowState state) {
    return _StepLayout(
      progress: _progress(state),
      question: l10n.jv2NoteQuestion,
      bottom: _ContinueButton(
        key: const Key('jv2_save'),
        label: l10n.jv2Save,
        saves: true,
        busy: state.isSaving,
        onPressed: state.isSaving ? null : _save,
      ),
      children: [
        VoiceTextSink(
          onText: (text) {
            appendDictation(_noteController, text);
            _controller.setNote(_noteController.text);
          },
          child: TextField(
            key: const Key('jv2_note_field'),
            controller: _noteController,
            minLines: 4,
            maxLines: 8,
            maxLength: JournalKeys.noteMaxLength,
            decoration: InputDecoration(
              hintText: l10n.jv2NoteHint,
              border: _noteBorder(),
              enabledBorder: _noteBorder(),
              focusedBorder: _noteBorder(focused: true),
              suffixIcon: voiceAvailable(ref)
                  ? VoiceDictationButton(
                      controller: _noteController,
                      fieldKey: 'note',
                      onChanged: _controller.setNote,
                    )
                  : null,
            ),
            onChanged: _controller.setNote,
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _noteBorder({bool focused = false}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: focused ? AppColors.dualisNavy : AppColors.dualisNavy.withValues(alpha: 0.12),
          width: focused ? 2 : 1,
        ),
      );

  String? _phrase(AppLocalizations l10n, JournalFlowState state) {
    final id = state.phraseId;
    return id == null ? null : JournalLabels.phrase(l10n, id);
  }
}

// ---- Building blocks ----------------------------------------------------

class _StepLayout extends StatelessWidget {
  final String? eyebrow;

  /// Mark drawn before [eyebrow]. The body map is never used here.
  final String? eyebrowMark;
  final String? lead;

  /// Short label between the lead and the question (the entry axis).
  final String? axisLabel;
  final Color? axisColor;
  final String? question;

  /// Read aloud instead of [question] (one that holds the person's text).
  final String? spokenQuestion;
  final String? hint;
  final List<Widget> children;
  final Widget? bottom;

  /// Screen number and screen count, shown as a bar with "2 de 7".
  final (int, int)? progress;

  const _StepLayout({
    this.progress,
    this.eyebrow,
    this.eyebrowMark,
    this.lead,
    this.axisLabel,
    this.axisColor,
    this.question,
    this.spokenQuestion,
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (progress != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Semantics(
              label: l10n.jv23StepOf(progress!.$1, progress!.$2),
              excludeSemantics: true,
              child: Row(
                key: const Key('jv23_progress'),
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            ColoredBox(
                              color: AppColors.dualisNavy.withValues(alpha: 0.1),
                              child: const SizedBox.expand(),
                            ),
                            FractionallySizedBox(
                              widthFactor: (progress!.$1 / progress!.$2).clamp(0.0, 1.0),
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradientBlueCyan,
                                  borderRadius: BorderRadius.all(Radius.circular(3)),
                                ),
                                child: SizedBox.expand(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.jv23StepOf(progress!.$1, progress!.$2),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            children: [
              if (eyebrow != null)
                Row(
                  children: [
                    if (JournalMarks.box(eyebrowMark, size: 16) case final mark?) ...[
                      mark,
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        eyebrow!,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: AppColors.dualisSymbolBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              if (lead != null) ...[
                const SizedBox(height: 4),
                _TypingText(
                  lead!,
                  key: const Key('jv2_phrase'),
                  style: GoogleFonts.inter(fontSize: 15, color: secondary),
                ),
              ],
              if (axisLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  axisLabel!,
                  key: const Key('jv2_axis_label'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: axisColor ?? AppColors.dualisSymbolBlue,
                  ),
                ),
              ],
              if (question != null) ...[
                const SizedBox(height: 6),
                // Read aloud in the hands-free check-in (Premium).
                VoicePrompt(
                  text: spokenQuestion ?? question!,
                  child: Text(
                    question!,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.14,
                      letterSpacing: -0.5,
                      color: AppColors.dualisNavy,
                    ),
                  ),
                ),
              ],
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  hint!,
                  style: GoogleFonts.inter(fontSize: 13, color: secondary),
                ),
              ],
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
        if (bottom != null)
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00F0F7FB), AppColors.backgroundDepth],
                stops: [0.0, 0.3],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: bottom,
            ),
          ),
      ],
    );
  }
}

/// Transition phrase typed in softly (client spec 2.7). The rest of the text
/// is laid out but transparent, so nothing below moves while it types. Shown
/// whole at once when the system asks for no animations.
class _TypingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _TypingText(this.text, {super.key, required this.style});

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  static Duration _durationFor(String text) =>
      Duration(milliseconds: (text.characters.length * 22).clamp(300, 1400));

  @override
  void initState() {
    super.initState();
    _controller
      ..duration = _durationFor(widget.text)
      ..forward();
  }

  @override
  void didUpdateWidget(_TypingText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _controller
        ..duration = _durationFor(widget.text)
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text(widget.text, style: widget.style);
    }
    final chars = widget.text.characters;
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final shown = (chars.length * _controller.value).ceil();
          return Text.rich(
            TextSpan(children: [
              TextSpan(text: chars.take(shown).toString()),
              TextSpan(
                text: chars.skip(shown).toString(),
                style: const TextStyle(color: Colors.transparent),
              ),
            ]),
            style: widget.style,
          );
        },
      ),
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
        style: GoogleFonts.inter(
          fontSize: strong ? 16 : 14,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

/// Small grey label over a set of options.
class _CapsLabel extends StatelessWidget {
  final String text;

  const _CapsLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

/// Lays cards out in rows of [columns], each row as tall as its tallest card.
class _CardGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;

  const _CardGrid({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += columns)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + columns; j++) ...[
                    if (j > i) const SizedBox(width: 10),
                    Expanded(
                      child: j < children.length ? children[j] : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Card with a big icon for short answers (v2.3). Long answers use
/// [_ChoiceTile] rows instead.
class _ChoiceCard extends StatelessWidget {
  /// Journal key drawn as a fixed-size mark.
  final String? markKey;

  /// Optional custom leading widget.
  final Widget? leading;
  final String label;
  final bool selected;
  final bool enabled;

  /// Mood cards: taller, bigger text.
  final bool large;

  /// Icon beside the text, for answers about the question ("Não sei").
  final bool wide;
  final bool showCheck;

  /// Answers by voice; off on all rows but one when the same labels repeat.
  final bool voice;
  final VoidCallback onTap;

  const _ChoiceCard({
    super.key,
    this.markKey,
    this.leading,
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.large = false,
    this.wide = false,
    this.showCheck = true,
    this.voice = true,
    this.multi = false,
    this.saves = false,
    required this.onTap,
  });

  /// Several answers can be picked (read aloud as options, not choices).
  final bool multi;

  /// [onTap] may save the entry: a multi-answer phrase never presses it.
  final bool saves;

  @override
  Widget build(BuildContext context) => VoiceTarget(
        labels: [label],
        onSelect: enabled && voice ? onTap : null,
        role: multi ? VoiceTargetRole.option : VoiceTargetRole.choice,
        saves: saves,
        selected: selected,
        child: _content(context),
      );

  Widget _content(BuildContext context) {
    final icon = JournalMarks.box(markKey, size: large ? 64 : (wide ? 28 : 36)) ?? leading;
    final text = Text(
      label,
      textAlign: wide ? TextAlign.start : TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: large ? 19 : 13.5,
        fontWeight: large ? FontWeight.w700 : FontWeight.w600,
        height: 1.22,
        color: enabled ? AppColors.dualisNavy : AppColors.textSecondaryLight,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        enabled: enabled,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: BoxConstraints(minHeight: large ? 170 : (wide ? 56 : 96)),
        decoration: _optionDecoration(selected: selected, radius: 22),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 8, vertical: 10),
              child: Stack(
                children: [
                  if (wide)
                    Row(
                      children: [
                        if (icon != null) ...[
                          SelectPop(selected: selected, child: icon),
                          const SizedBox(width: 10),
                        ],
                        Expanded(child: text),
                      ],
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            SelectPop(selected: selected, child: icon),
                            SizedBox(height: large ? 12 : 6),
                          ],
                          text,
                        ],
                      ),
                    ),
                  if (showCheck)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconStateSwitcher(
                        child: selected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                key: ValueKey(true),
                                size: 20,
                                color: AppColors.dualisNavy,
                              )
                            : const SizedBox(key: ValueKey(false), width: 20, height: 20),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Translucent white card with a soft navy shadow: the body map and the
/// intensity cards sit on one.
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassEdge),
        boxShadow: AppColors.glassShadow(blur: 24, alpha: 0.2),
      ),
      child: child,
    );
  }
}

/// Glass option surface shared by the choice cards and rows: white and
/// rounded with a soft shadow; selected is a navy border over a cyan tint.
BoxDecoration _optionDecoration({required bool selected, required double radius}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: selected
        ? AppColors.dualisSymbolCyan.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.86),
    border: Border.all(
      color: selected ? AppColors.dualisNavy : AppColors.dualisNavy.withValues(alpha: 0.08),
      width: selected ? 2 : 1,
    ),
    boxShadow: selected
        ? null
        : [
            BoxShadow(
              color: AppColors.dualisNavy.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: -12,
            ),
          ],
  );
}

/// Tabs over the trigger cards, with how many are marked in each tab.
class _TopicTabs extends StatelessWidget {
  final List<
      ({
        Key key,
        String label,
        int count,
        String countLabel,
        bool selected,
        VoidCallback onTap,
      })> tabs;

  const _TopicTabs({required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.dualisNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final t in tabs)
            VoiceTarget(
              labels: [t.label],
              onSelect: t.onTap,
              role: VoiceTargetRole.other,
              child: const SizedBox.shrink(),
            ),
          for (final t in tabs)
            Expanded(
              child: Semantics(
                button: true,
                selected: t.selected,
                label: t.count > 0 ? '${t.label}, ${t.countLabel}' : t.label,
                excludeSemantics: true,
                child: InkWell(
                  key: t.key,
                  borderRadius: BorderRadius.circular(13),
                  onTap: t.onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: t.selected
                          ? [
                              BoxShadow(
                                color: AppColors.dualisNavy.withValues(alpha: 0.14),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            t.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: t.selected
                                  ? AppColors.dualisNavy
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        if (t.count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.dualisSymbolBlue,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '${t.count}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Row for answers with longer text (v2.3). Short answers use [_ChoiceCard].
class _ChoiceTile extends StatelessWidget {
  final String? emoji;

  /// Journal key of the option: when it has a Fluent emoji, that is drawn
  /// instead of [emoji].
  final String? emojiKey;
  final String label;
  final bool selected;
  final bool multi;
  final bool enabled;

  /// Shorter row, for lists of several options.
  final bool dense;

  /// Blue text: an action row ("Escrever o meu").
  final bool accent;
  final String? semanticsHint;
  final VoidCallback onTap;

  const _ChoiceTile({
    super.key,
    this.emoji,
    this.emojiKey,
    required this.label,
    this.selected = false,
    this.multi = false,
    this.enabled = true,
    this.dense = false,
    this.accent = false,
    this.semanticsHint,
    this.voiceRole,
    this.personal = false,
    required this.onTap,
  });

  /// Role for voice; by default an option (multi) or a choice.
  final VoiceTargetRole? voiceRole;

  /// [label] is the person's own text: never read aloud.
  final bool personal;

  @override
  Widget build(BuildContext context) => VoiceTarget(
        labels: [label],
        onSelect: enabled ? onTap : null,
        role: voiceRole ?? (multi ? VoiceTargetRole.option : VoiceTargetRole.choice),
        personal: personal,
        selected: selected,
        child: _content(context),
      );

  Widget _content(BuildContext context) {
    final mark = JournalMarks.box(emojiKey, size: dense ? 22 : 26);
    final fluent = mark != null || emojiKey == null
        ? null
        : FluentEmoji.assetForJournalKey(emojiKey!);
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 8 : 10),
      child: Semantics(
        button: true,
        selected: multi ? selected : null,
        hint: semanticsHint,
        child: PressScale(
          enabled: enabled,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: _optionDecoration(selected: selected, radius: 20),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: dense ? 10 : 13,
                ),
                child: Row(
                  children: [
                    if (mark != null) ...[
                      SelectPop(
                        selected: selected,
                        child: DuotoneIconTile(
                          size: dense ? 36 : 40,
                          radius: 11,
                          child: mark,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ] else if (fluent != null) ...[
                      FluentEmoji.image(fluent, size: dense ? 34 : 38),
                      const SizedBox(width: 12),
                    ] else if (emoji != null) ...[
                      DuotoneIconTile(
                        size: dense ? 36 : 40,
                        radius: 11,
                        child: ExcludeSemantics(
                          child: Text(emoji!, style: TextStyle(fontSize: dense ? 19 : 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: accent ? FontWeight.w700 : FontWeight.w600,
                          color: !enabled
                              ? AppColors.textSecondaryLight
                              : (accent ? AppColors.dualisSymbolBlue : AppColors.dualisNavy),
                        ),
                      ),
                    ),
                    if (multi)
                      IconStateSwitcher(
                        child: Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          key: ValueKey(selected),
                          color: selected
                              ? AppColors.dualisNavy
                              : AppColors.dualisNavy.withValues(alpha: 0.22),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// A topic that opens to show a few options in two columns (v2.3). The
/// number shows how many options of the topic are marked.
class _TopicCard extends StatefulWidget {
  final Key headerKey;
  final String emoji;

  /// Drawn in the header tile instead of [emoji] when it has a mark.
  final String? markKey;
  final String title;
  final String subtitle;
  final int count;
  final String countLabel;
  final bool initiallyOpen;
  final List<Widget> children;

  const _TopicCard({
    required this.headerKey,
    required this.emoji,
    this.markKey,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.countLabel,
    required this.initiallyOpen,
    required this.children,
  });

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = <Widget>[];
    for (var i = 0; i < widget.children.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: widget.children[i]),
              const SizedBox(width: 8),
              Expanded(
                child: i + 1 < widget.children.length
                    ? widget.children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: _optionDecoration(selected: false, radius: 20).copyWith(
          border: Border.all(
            color: _open ? AppColors.dualisNavy : AppColors.dualisNavy.withValues(alpha: 0.08),
            width: _open ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              child: InkWell(
                key: widget.headerKey,
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      DuotoneIconTile(
                        size: 44,
                        radius: 14,
                        child: JournalMarks.box(widget.markKey, size: 26) ??
                            ExcludeSemantics(
                              child: Text(widget.emoji, style: const TextStyle(fontSize: 22)),
                            ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dualisNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.count > 0) ...[
                        const SizedBox(width: 8),
                        Semantics(
                          label: widget.countLabel,
                          child: ExcludeSemantics(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.dualisNavy,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${widget.count}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.expand_more_rounded,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
                child: Column(children: rows),
              ),
          ],
        ),
      ),
    );
  }
}

/// One condition in the "Minhas condições" list. A tracked one opens its
/// reading card ([child]) below the row.
class _ConditionTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final bool expandable;
  final bool open;
  final VoidCallback onTap;
  final Widget? child;

  const _ConditionTile({
    super.key,
    required this.label,
    this.subtitle,
    required this.selected,
    this.expandable = false,
    this.open = false,
    required this.onTap,
    this.child,
  });

  /// The condition name is the person's own text: it can be said, but it
  /// is never read aloud and never picked by a multi-answer phrase.
  @override
  Widget build(BuildContext context) => VoiceTarget(
        labels: [label],
        onSelect: onTap,
        role: VoiceTargetRole.other,
        personal: true,
        selected: selected,
        child: _content(context),
      );

  Widget _content(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlighted = selected || open;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: _optionDecoration(selected: selected, radius: 18).copyWith(
          border: Border.all(
            color: highlighted ? AppColors.dualisNavy : AppColors.dualisNavy.withValues(alpha: 0.08),
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              selected: expandable ? null : selected,
              expanded: expandable ? open : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dualisNavy,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (expandable)
                        AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.textSecondaryLight,
                          ),
                        )
                      else
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 22,
                          color: selected
                              ? AppColors.dualisNavy
                              : AppColors.dualisNavy.withValues(alpha: 0.22),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (expandable && open && child != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

/// One option inside a [_TopicCard].
class _OptionCell extends StatelessWidget {
  final String? markKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCell({
    super.key,
    this.markKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => VoiceTarget(
        labels: [label],
        onSelect: onTap,
        selected: selected,
        child: _content(context),
      );

  Widget _content(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? AppColors.dualisSymbolCyan.withValues(alpha: 0.14)
              : AppColors.dualisNavy.withValues(alpha: 0.04),
          border: Border.all(
            color: selected ? AppColors.dualisNavy : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  if (JournalMarks.box(markKey, size: 24) case final mark?) ...[
                    mark,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dualisNavy,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.dualisNavy,
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

/// A part marked on the map, with a button to take it off.
class _MarkedPill extends StatelessWidget {
  final String label;
  final String? markKey;
  final String removeLabel;
  final VoidCallback onRemove;

  const _MarkedPill({
    super.key,
    required this.label,
    this.markKey,
    required this.removeLabel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => VoiceTarget(
        labels: [removeLabel],
        onSelect: onRemove,
        role: VoiceTargetRole.other,
        child: _content(context),
      );

  Widget _content(BuildContext context) {
    return Semantics(
      button: true,
      label: removeLabel,
      excludeSemantics: true,
      child: Material(
        color: AppColors.dualisSymbolCyan.withValues(alpha: 0.16),
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.dualisNavy.withValues(alpha: 0.25)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onRemove,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: EdgeInsets.fromLTRB(markKey == null ? 12 : 6, 6, 8, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (JournalMarks.box(markKey, size: 20) case final mark?) ...[
                  mark,
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dualisNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.close_rounded, size: 18, color: AppColors.dualisNavy),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mood emoji (Fluent 3D: Bem, Não tão bem). Same size for both; nothing
/// else on screen depends on the choice.
class _MoodIcon extends StatelessWidget {
  final String mood;

  const _MoodIcon(this.mood);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('jv2_mood_icon_$mood'),
      width: 80,
      height: 80,
      child: Center(
        child: JournalMarks.box(mood, size: 64) ??
            ExcludeSemantics(
              child: Text(journalEmojis[mood] ?? '', style: const TextStyle(fontSize: 52)),
            ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  /// [onPressed] saves the entry ("Salvar", "Só registrar", "Só registrar
  /// medições"): for voice it is "Salvar", never a "Continuar" that a
  /// multi-answer phrase may press.
  final bool saves;

  const _ContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.saves = false,
  });

  @override
  Widget build(BuildContext context) => VoiceTarget(
        labels: _voiceLabels(context),
        onSelect: busy ? null : onPressed,
        role: saves ? VoiceTargetRole.save : VoiceTargetRole.advance,
        child: _content(context),
      );

  /// "Continuar" and "Salvar" also answer to their usual synonyms.
  List<String> _voiceLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      label,
      if (label == l10n.jv2Continue) ...VoiceMatcher.aliases(l10n.voiceAliasContinue),
      if (label == l10n.jv2Save || label == l10n.jv22JustSave)
        ...VoiceMatcher.aliases(l10n.voiceAliasSave),
    ];
  }

  Widget _content(BuildContext context) {
    return FilledButton(
      key: key == null ? const Key('jv2_continue') : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.dualisNavy,
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
      ).copyWith(
        shadowColor: WidgetStatePropertyAll(AppColors.softIndigoDark.withValues(alpha: 0.7)),
        elevation: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled) ? 0 : 6,
        ),
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
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
