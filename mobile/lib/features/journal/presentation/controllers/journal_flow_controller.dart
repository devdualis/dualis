import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/feature_flags.dart';
import '../../data/journal_repository.dart';
import '../../domain/journal_keys.dart';
import '../../domain/journal_models.dart';
import '../journal_labels.dart';
import 'journal_flow_state.dart';

/// Source of randomness for transition phrases; overridden in tests.
final journalRandomProvider = Provider<Random>((ref) => Random());

/// Active conditions of the current profile (cached for offline use).
final userConditionsProvider = FutureProvider.autoDispose<List<UserCondition>>(
  (ref) => ref.watch(journalRepositoryProvider).conditions(),
);

final journalFlowControllerProvider =
    NotifierProvider.autoDispose<JournalFlowController, JournalFlowState>(
  JournalFlowController.new,
);

/// Drives the daily journal flow. Stores only what the user picked or wrote;
/// no step depends on what was recorded except to show the next question.
class JournalFlowController extends Notifier<JournalFlowState> {
  final List<JournalFlowState> _history = [];
  late String _clientId;

  @override
  JournalFlowState build() {
    _clientId = const Uuid().v4();
    return const JournalFlowState();
  }

  /// Keeps an id stable for the whole flow, so a retried save is idempotent.
  String get clientId => _clientId;

  bool get canGoBack => _history.isNotEmpty;

  void _go(JournalFlowState next) {
    _history.add(state);
    state = _withPhrase(next);
  }

  /// Back to the previous screen with its answers.
  bool back() {
    if (_history.isEmpty) return false;
    state = _history.removeLast();
    return true;
  }

  void setConditions(List<UserCondition> conditions) {
    state = state.copyWith(conditions: conditions);
  }

  // ---- Mood -------------------------------------------------------------

  /// Records the general mood for the axis picked on Home ([area]). Returns
  /// true when the entry is ready to save right away (Bem on the physical
  /// axis). Bem on the emotional axis offers "Só registrar" or good moments;
  /// on the physical axis, with tracked [conditions] on a Premium build, it
  /// opens the readings screen. "Não tão bem" goes straight to the first
  /// question of that axis.
  bool chooseMood(
    String mood, {
    JournalArea area = JournalArea.emotional,
    List<UserCondition>? conditions,
  }) {
    if (mood == JournalKeys.moodNaoTaoBem) {
      _go(state.copyWith(
        mood: mood,
        area: area,
        step: area == JournalArea.emotional ? JournalStep.time : JournalStep.body,
        selectedRegions: const [],
        regionIndex: 0,
      ));
      return false;
    }
    if (area == JournalArea.emotional) {
      _go(state.copyWith(
        mood: mood,
        area: area,
        step: JournalStep.positiveStart,
        items: const [],
      ));
      return false;
    }
    final list = conditions ?? state.conditions;
    if (_premium && list.any((c) => c.isTracked)) {
      _go(state.copyWith(
        mood: mood,
        area: area,
        conditions: list,
        step: JournalStep.conditions,
        items: const [],
      ));
      return false;
    }
    state = state.copyWith(mood: mood, area: area);
    return true;
  }

  /// Tracked conditions take readings only on Premium builds; on Free builds
  /// every condition uses the 1-5 card.
  bool get _premium => ref.read(premiumProfilesEnabledProvider);

  /// The condition takes readings (and no 1-5 answer) in this build.
  bool tracksReadings(UserCondition condition) => _premium && condition.isTracked;

  // ---- Good moments (Bem, v2.2) ------------------------------------------


  /// Puts the good moments picked on screen in the entry. Returns true when
  /// there is something to save.
  bool confirmPositiveOptions() {
    if (!state.hasOptionSelection || state.time == null) return false;
    final time = state.time!;
    state = state.copyWith(items: _capped([
      for (final key in state.selectedOptions)
        JournalItem(kind: JournalKeys.kindPositive, optionKey: key),
      for (final label in state.customLabels)
        JournalItem(
          kind: JournalKeys.kindPositive,
          optionKey: JournalKeys.customKey(time),
          customLabel: label,
        ),
    ]));
    return true;
  }

  // ---- Conditions (body screen) -----------------------------------------

  void toggleCondition(String conditionId) {
    final next = {...state.selectedConditionIds};
    next.contains(conditionId) ? next.remove(conditionId) : next.add(conditionId);
    state = state.copyWith(selectedConditionIds: next);
  }

  /// Readings typed on a tracked condition's card (complete ones only).
  void setConditionReadings(String conditionId, List<ConditionReading> readings) {
    state = state.copyWith(conditionReadings: {
      ...state.conditionReadings,
      conditionId: List.unmodifiable(readings),
    });
  }

  /// Picked untracked conditions, and tracked ones with at least one reading.
  List<JournalItem> _conditionItems(List<UserCondition>? conditions) => [
    for (final c in conditions ?? state.conditions)
      if (tracksReadings(c)) ...[
        if ((state.conditionReadings[c.id] ?? const []).isNotEmpty)
          JournalItem(
            kind: JournalKeys.kindCondition,
            conditionId: c.id,
            conditionLabel: c.label,
            readings: state.conditionReadings[c.id]!,
          ),
      ] else if (state.selectedConditionIds.contains(c.id))
        JournalItem(
          kind: JournalKeys.kindCondition,
          conditionId: c.id,
          conditionLabel: c.label,
        ),
  ];

  /// "Só registrar medições" (Bem with tracked conditions): the entry gets
  /// the conditions with readings. Returns true when there is one to save.
  bool confirmReadingsOnly({List<UserCondition>? conditions}) {
    final items = _conditionItems(conditions)
        .where((i) => i.readings.isNotEmpty)
        .toList();
    if (items.isEmpty) return false;
    state = state.copyWith(items: _capped(items));
    return true;
  }

  /// "Salvar sem medições": the Bem entry as it was before readings.
  void clearReadingsForSave() {
    state = state.copyWith(items: const [], conditionReadings: const {});
  }

  /// After the last question of the axis: intensity of everything recorded
  /// that takes a 1-5 answer.
  JournalFlowState _finish(JournalFlowState s) => s.copyWith(
    step: s.itemsNeedingIntensity.isEmpty ? JournalStep.triggers : JournalStep.intensity,
  );

  // ---- Emotional --------------------------------------------------------

  /// Time and branch are picked on one screen (v2.3): the branch tells the
  /// time. From "Bem" it opens the good moments, otherwise the options.
  void chooseTimeBranch(String time, String branch) {
    _go(state.copyWith(
      time: time,
      branch: branch,
      step: state.step == JournalStep.positiveStart
          ? JournalStep.positiveOptions
          : JournalStep.options,
      selectedOptions: const {},
      customLabels: const [],
    ));
  }

  /// Branch of the body region on screen.
  void chooseBranch(String branch) {
    _go(state.copyWith(
      branch: branch,
      step: JournalStep.regionOptions,
      selectedOptions: const {},
      customLabels: const [],
    ));
  }

  void toggleOption(String optionKey) {
    final next = {...state.selectedOptions};
    next.contains(optionKey) ? next.remove(optionKey) : next.add(optionKey);
    state = state.copyWith(selectedOptions: next);
  }

  /// Adds a label the user wrote ("Escrever o meu"), kept exactly as typed
  /// apart from surrounding spaces and the 40-character limit.
  void addCustomLabel(String label) {
    var clean = JournalKeys.limitChars(label.trim(), JournalKeys.customLabelMaxLength);
    if (clean.isEmpty) return;
    if (state.customLabels.contains(clean)) return;
    state = state.copyWith(customLabels: [...state.customLabels, clean]);
  }

  void removeCustomLabel(String label) {
    state = state.copyWith(
      customLabels: [for (final l in state.customLabels) if (l != label) l],
    );
  }

  /// Puts the options on screen in the entry. [more] ("+ Registrar outra
  /// coisa") goes back to the feelings; otherwise on to the intensity.
  void confirmEmotionalOptions({bool more = false}) {
    if (!state.hasOptionSelection || state.time == null) return;
    final time = state.time!;
    final added = [
      for (final key in state.selectedOptions)
        JournalItem(kind: JournalKeys.kindEmotional, optionKey: key),
      for (final label in state.customLabels)
        JournalItem(
          kind: JournalKeys.kindEmotional,
          optionKey: JournalKeys.customKey(time),
          customLabel: label,
        ),
    ];
    final next = state.copyWith(
      items: _merge(state.items, added),
      selectedOptions: const {},
      customLabels: const [],
    );
    if (more && !next.itemLimitReached) {
      _go(next.copyWith(step: JournalStep.time, clearBranch: true));
    } else {
      _go(_finish(next));
    }
  }

  // ---- Physical ---------------------------------------------------------

  void setBodySide(String side) {
    state = state.copyWith(bodySide: side);
  }

  /// Body map region (on the side on screen) or whole-body area (no side).
  void toggleRegion(String region) {
    final current = [...state.selectedRegions];
    final index = current.indexWhere((r) => r.region == region);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.add(SelectedRegion(
        region,
        JournalKeys.isWholeBody(region) ? null : state.bodySide,
      ));
    }
    state = state.copyWith(selectedRegions: current);
  }

  /// Regions and conditions chosen on the body screen.
  void confirmBody({List<UserCondition>? conditions}) {
    if (!state.hasBodySelection) return;
    // Condition items are rebuilt from the screen, so changed readings and
    // unpicked conditions are up to date after "mais alguma coisa".
    final items = _merge(
      [for (final i in state.items) if (i.kind != JournalKeys.kindCondition) i],
      _conditionItems(conditions),
    );
    if (state.selectedRegions.isEmpty) {
      _go(_finish(state.copyWith(items: items)));
      return;
    }
    _go(state.copyWith(
      items: items,
      step: JournalStep.regionBranch,
      regionIndex: 0,
      clearBranch: true,
      clearSensation: true,
    ));
  }

  /// "Dor" or "Incômodo" for the region on screen (required before a branch).
  void chooseSensation(String sensation) {
    state = state.copyWith(sensation: sensation);
  }

  /// Puts the options of the region on screen in the entry, then the next
  /// marked region. After the last one, [more] ("+ Marcar outra parte")
  /// goes back to the body map; otherwise on to the intensity.
  void confirmPhysicalOptions({bool more = false}) {
    final region = state.currentRegion;
    final sensation = state.sensation;
    if (!state.hasOptionSelection || region == null || sensation == null) return;
    final added = [
      for (final key in state.selectedOptions)
        JournalItem(
          kind: JournalKeys.kindPhysical,
          optionKey: key,
          bodySide: region.side,
          sensation: sensation,
        ),
      for (final label in state.customLabels)
        JournalItem(
          kind: JournalKeys.kindPhysical,
          optionKey: JournalKeys.customKey(region.region),
          customLabel: label,
          bodySide: region.side,
          sensation: sensation,
        ),
    ];
    final items = _merge(state.items, added);
    final nextIndex = state.regionIndex + 1;
    final cleared = state.copyWith(
      items: items,
      selectedOptions: const {},
      customLabels: const [],
      clearBranch: true,
      clearSensation: true,
    );
    if (nextIndex < state.selectedRegions.length && !cleared.itemLimitReached) {
      _go(cleared.copyWith(step: JournalStep.regionBranch, regionIndex: nextIndex));
    } else if (more && !cleared.itemLimitReached) {
      _go(cleared.copyWith(
        step: JournalStep.body,
        selectedRegions: const [],
        regionIndex: 0,
      ));
    } else {
      _go(_finish(cleared));
    }
  }

  // ---- Persistence and intensity ----------------------------------------

  void setPersistence(String draftId, String persistence) {
    state = state.copyWith(items: [
      for (final i in state.items)
        if (i.draftId == draftId)
          (i.persistence == persistence
              ? i.copyWith(clearPersistence: true)
              : i.copyWith(persistence: persistence))
        else
          i,
    ]);
  }

  void setIntensity(String draftId, int intensity) {
    final value = intensity.clamp(JournalKeys.intensityMin, JournalKeys.intensityMax);
    state = state.copyWith(items: [
      for (final i in state.items)
        if (i.draftId == draftId) i.copyWith(intensity: value) else i,
    ]);
  }

  void confirmIntensity() {
    if (!state.allItemsReady) return;
    _go(state.copyWith(step: JournalStep.triggers));
  }

  // ---- Triggers and note ------------------------------------------------

  /// "Não sei" cannot be combined with a trigger: choosing one clears the other.
  void toggleTrigger(String trigger) {
    final next = {...state.triggers};
    if (next.contains(trigger)) {
      next.remove(trigger);
    } else if (trigger == JournalKeys.triggerNaoSei) {
      next
        ..clear()
        ..add(trigger);
    } else {
      next
        ..remove(JournalKeys.triggerNaoSei)
        ..add(trigger);
    }
    state = state.copyWith(triggers: next);
  }

  void setTriggerNote(String note) {
    state = state.copyWith(
      triggerNote: JournalKeys.limitChars(note, JournalKeys.triggerNoteMaxLength),
    );
  }

  void confirmTriggers({bool skip = false}) {
    _go(state.copyWith(
      step: JournalStep.closing,
      triggers: skip ? const {} : state.triggers,
      triggerNote: skip ? '' : state.triggerNote,
    ));
  }

  // ---- Closing questions (v2.2) ------------------------------------------

  /// Single choice; tapping the chosen one again clears it.
  void chooseCoping(String coping) {
    state = state.coping == coping
        ? state.copyWith(clearCoping: true)
        : state.copyWith(coping: coping);
  }

  /// "Nada ainda" never goes with another helper: picking it clears the
  /// others, and picking another one clears it.
  void toggleHelper(String helper) {
    final next = {...state.helpers};
    if (!next.remove(helper)) {
      if (helper == JournalKeys.helperNadaAinda) {
        next.clear();
      } else {
        next.remove(JournalKeys.helperNadaAinda);
      }
      next.add(helper);
    }
    state = state.copyWith(helpers: next);
  }

  void confirmClosing({bool skip = false}) {
    _go(state.copyWith(
      step: JournalStep.note,
      clearCoping: skip,
      helpers: skip ? const {} : state.helpers,
    ));
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  // ---- Save -------------------------------------------------------------

  /// The entry exactly as the user recorded it.
  JournalEntry buildEntry({DateTime? now}) {
    final quick = state.mood != JournalKeys.moodNaoTaoBem;
    final offered = JournalKeys.triggersFor(hasPhysicalItem: state.hasPhysicalItem);
    final triggers = quick
        ? <String>[]
        : [for (final t in offered) if (state.triggers.contains(t)) t];
    final note = state.note.trim();
    final triggerNote = state.triggerNote.trim();
    final positive = quick && state.area == JournalArea.emotional
        ? [for (final i in state.items) if (i.kind == JournalKeys.kindPositive) i]
        : const <JournalItem>[];
    // Physical Bem keeps only conditions with readings ("Só registrar medições").
    final withReadings = quick && state.area == JournalArea.physical
        ? [
            for (final i in state.items)
              if (i.kind == JournalKeys.kindCondition && i.readings.isNotEmpty) i,
          ]
        : const <JournalItem>[];
    return JournalEntry(
      clientId: _clientId,
      recordedAt: now ?? DateTime.now(),
      mood: state.mood ?? JournalKeys.moodNaoTaoBem,
      area: state.area.key,
      triggers: triggers,
      triggerNote: triggers.contains(JournalKeys.triggerOutro) && triggerNote.isNotEmpty
          ? triggerNote
          : null,
      note: quick || note.isEmpty ? null : note,
      transitionVariantIds: state.shownPhraseIds,
      items: quick ? [...positive, ...withReadings] : state.items,
      coping: quick ? null : state.coping,
      helpers: quick
          ? const []
          : [for (final h in JournalKeys.helpers) if (state.helpers.contains(h)) h],
    );
  }

  Future<JournalEntry> save() async {
    state = state.copyWith(isSaving: true);
    try {
      return await ref.read(journalRepositoryProvider).saveEntry(buildEntry());
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  // ---- Helpers ----------------------------------------------------------

  List<JournalItem> _capped(List<JournalItem> items) =>
      items.length > JournalKeys.maxItems
          ? items.sublist(0, JournalKeys.maxItems)
          : items;

  List<JournalItem> _merge(List<JournalItem> current, List<JournalItem> added) {
    final ids = {for (final i in current) i.draftId};
    final merged = [
      ...current,
      for (final i in added)
        if (ids.add(i.draftId)) i,
    ];
    return _capped(merged);
  }

  /// Picks a random approved phrase for the screen being shown.
  JournalFlowState _withPhrase(JournalFlowState next) {
    final limit = next.items.length >= JournalKeys.maxItems;
    final pool = _phrasePool(next);
    if (pool == null) {
      return next.copyWith(clearPhrase: true, itemLimitReached: limit);
    }
    final count = JournalLabels.phrasePools[pool] ?? 0;
    if (count == 0) return next.copyWith(clearPhrase: true, itemLimitReached: limit);
    final id = '$pool.${ref.read(journalRandomProvider).nextInt(count) + 1}';
    return next.copyWith(
      phraseId: id,
      itemLimitReached: limit,
      shownPhraseIds: next.shownPhraseIds.contains(id)
          ? next.shownPhraseIds
          : [...next.shownPhraseIds, id],
    );
  }

  String? _phrasePool(JournalFlowState s) {
    switch (s.step) {
      case JournalStep.time:
        return 'time';
      case JournalStep.options:
        return s.time;
      case JournalStep.body:
        return 'body';
      case JournalStep.regionBranch:
        return 'region';
      case JournalStep.intensity:
        return 'intensity';
      case JournalStep.triggers:
        return 'triggers';
      case JournalStep.positiveOptions:
        return 'positive';
      case JournalStep.closing:
        return 'closing';
      default:
        return null;
    }
  }
}
