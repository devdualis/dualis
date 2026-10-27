import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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

  /// Records the general mood. Returns true when the entry is ready to save
  /// right away (Bem / Normal).
  bool chooseMood(String mood) {
    if (mood == JournalKeys.moodNaoTaoBem) {
      _go(state.copyWith(mood: mood, step: JournalStep.areas));
      return false;
    }
    state = state.copyWith(mood: mood);
    return true;
  }

  // ---- Areas ------------------------------------------------------------

  void toggleArea(JournalArea area) {
    final next = {...state.areas};
    next.contains(area) ? next.remove(area) : next.add(area);
    state = state.copyWith(areas: next);
  }

  void toggleCondition(String conditionId) {
    final next = {...state.selectedConditionIds};
    next.contains(conditionId) ? next.remove(conditionId) : next.add(conditionId);
    state = state.copyWith(selectedConditionIds: next);
  }

  void confirmAreas({List<UserCondition>? conditions}) {
    if (!state.hasAreaSelection) return;
    final conditionItems = [
      for (final c in conditions ?? state.conditions)
        if (state.selectedConditionIds.contains(c.id))
          JournalItem(
            kind: JournalKeys.kindCondition,
            conditionId: c.id,
            conditionLabel: c.label,
          ),
    ];
    final pending = [
      for (final a in JournalArea.values)
        if (state.areas.contains(a)) a,
    ];
    final base = state.copyWith(items: _capped(conditionItems), pendingAreas: pending);
    _go(_nextArea(base));
  }

  JournalFlowState _nextArea(JournalFlowState s) {
    if (s.pendingAreas.isEmpty) {
      return s.copyWith(
        step: s.items.isEmpty ? JournalStep.triggers : JournalStep.intensity,
      );
    }
    final area = s.pendingAreas.first;
    final rest = s.pendingAreas.sublist(1);
    return area == JournalArea.emotional
        ? s.copyWith(step: JournalStep.time, pendingAreas: rest)
        : s.copyWith(
            step: JournalStep.body,
            pendingAreas: rest,
            selectedRegions: const [],
            regionIndex: 0,
          );
  }

  // ---- Emotional --------------------------------------------------------

  void chooseTime(String time) {
    _go(state.copyWith(time: time, clearBranch: true, step: JournalStep.branch));
  }

  void chooseBranch(String branch) {
    _go(state.copyWith(
      branch: branch,
      step: state.step == JournalStep.regionBranch
          ? JournalStep.regionOptions
          : JournalStep.options,
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

  void confirmEmotionalOptions() {
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
    _go(state.copyWith(
      items: _merge(state.items, added),
      step: JournalStep.moreEmotional,
      selectedOptions: const {},
      customLabels: const [],
    ));
  }

  void answerMoreEmotional(bool more) {
    if (more && !state.itemLimitReached) {
      _go(state.copyWith(step: JournalStep.time, clearBranch: true));
    } else {
      _go(_nextArea(state));
    }
  }

  // ---- Physical ---------------------------------------------------------

  void setBodySide(String side) {
    state = state.copyWith(bodySide: side);
  }

  void toggleRegion(String region) {
    final current = [...state.selectedRegions];
    final index = current.indexWhere((r) => r.region == region);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.add(SelectedRegion(region, state.bodySide));
    }
    state = state.copyWith(selectedRegions: current);
  }

  void confirmRegions() {
    if (state.selectedRegions.isEmpty) return;
    _go(state.copyWith(
      step: JournalStep.regionBranch,
      regionIndex: 0,
      clearBranch: true,
    ));
  }

  void confirmPhysicalOptions() {
    final region = state.currentRegion;
    if (!state.hasOptionSelection || region == null) return;
    final added = [
      for (final key in state.selectedOptions)
        JournalItem(
          kind: JournalKeys.kindPhysical,
          optionKey: key,
          bodySide: region.side,
        ),
      for (final label in state.customLabels)
        JournalItem(
          kind: JournalKeys.kindPhysical,
          optionKey: JournalKeys.customKey(region.region),
          customLabel: label,
          bodySide: region.side,
        ),
    ];
    final items = _merge(state.items, added);
    final nextIndex = state.regionIndex + 1;
    final cleared = state.copyWith(
      items: items,
      selectedOptions: const {},
      customLabels: const [],
      clearBranch: true,
    );
    if (nextIndex < state.selectedRegions.length && !cleared.itemLimitReached) {
      _go(cleared.copyWith(step: JournalStep.regionBranch, regionIndex: nextIndex));
    } else {
      _go(cleared.copyWith(step: JournalStep.moreBody));
    }
  }

  void answerMoreBody(bool more) {
    if (more && !state.itemLimitReached) {
      _go(state.copyWith(
        step: JournalStep.body,
        selectedRegions: const [],
        regionIndex: 0,
      ));
    } else {
      _go(_nextArea(state));
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

  void toggleTrigger(String trigger) {
    final next = {...state.triggers};
    next.contains(trigger) ? next.remove(trigger) : next.add(trigger);
    state = state.copyWith(triggers: next);
  }

  void setTriggerNote(String note) {
    state = state.copyWith(
      triggerNote: JournalKeys.limitChars(note, JournalKeys.triggerNoteMaxLength),
    );
  }

  void confirmTriggers({bool skip = false}) {
    _go(state.copyWith(
      step: JournalStep.note,
      triggers: skip ? const {} : state.triggers,
      triggerNote: skip ? '' : state.triggerNote,
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
    return JournalEntry(
      clientId: _clientId,
      recordedAt: now ?? DateTime.now(),
      mood: state.mood ?? JournalKeys.moodNaoTaoBem,
      triggers: triggers,
      triggerNote: triggers.contains(JournalKeys.triggerOutro) && triggerNote.isNotEmpty
          ? triggerNote
          : null,
      note: quick || note.isEmpty ? null : note,
      transitionVariantIds: state.shownPhraseIds,
      items: quick ? const [] : state.items,
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
      case JournalStep.branch:
        return s.time;
      case JournalStep.body:
        return 'body';
      case JournalStep.regionBranch:
        return 'region';
      case JournalStep.intensity:
        return 'intensity';
      case JournalStep.triggers:
        return 'triggers';
      default:
        return null;
    }
  }
}
