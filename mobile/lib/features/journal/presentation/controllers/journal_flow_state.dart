import 'package:flutter/foundation.dart';

import '../../domain/journal_models.dart';

/// Screens of the daily journal flow (strategy sections 5, 6, 8 and 18).
enum JournalStep {
  mood,
  areas,
  time,
  branch,
  options,
  moreEmotional,
  body,
  regionBranch,
  regionOptions,
  moreBody,
  intensity,
  triggers,
  note,
}

/// Areas the user can choose to record after "Não tão bem".
enum JournalArea { emotional, physical }

/// A region tapped on the body map and the side it was tapped on.
@immutable
class SelectedRegion {
  final String region;
  final String side;
  const SelectedRegion(this.region, this.side);

  @override
  bool operator ==(Object other) =>
      other is SelectedRegion && other.region == region && other.side == side;

  @override
  int get hashCode => Object.hash(region, side);
}

@immutable
class JournalFlowState {
  final JournalStep step;
  final String? mood;
  final Set<JournalArea> areas;
  final Set<String> selectedConditionIds;
  final List<UserCondition> conditions;

  /// Areas still to visit, in order.
  final List<JournalArea> pendingAreas;

  // Emotional path.
  final String? time;
  final String? branch;

  // Physical path.
  final String bodySide;
  final List<SelectedRegion> selectedRegions;
  final int regionIndex;

  /// Options and custom labels picked on the current options screen.
  final Set<String> selectedOptions;
  final List<String> customLabels;

  final List<JournalItem> items;
  final Set<String> triggers;
  final String triggerNote;
  final String note;

  /// Phrase variant shown on the current screen, if any.
  final String? phraseId;

  /// Every phrase variant shown in this flow (UX analytics only).
  final List<String> shownPhraseIds;

  final bool itemLimitReached;
  final bool isSaving;

  const JournalFlowState({
    this.step = JournalStep.mood,
    this.mood,
    this.areas = const {},
    this.selectedConditionIds = const {},
    this.conditions = const [],
    this.pendingAreas = const [],
    this.time,
    this.branch,
    this.bodySide = 'front',
    this.selectedRegions = const [],
    this.regionIndex = 0,
    this.selectedOptions = const {},
    this.customLabels = const [],
    this.items = const [],
    this.triggers = const {},
    this.triggerNote = '',
    this.note = '',
    this.phraseId,
    this.shownPhraseIds = const [],
    this.itemLimitReached = false,
    this.isSaving = false,
  });

  SelectedRegion? get currentRegion =>
      regionIndex < selectedRegions.length ? selectedRegions[regionIndex] : null;

  bool get hasPhysicalItem => items.any((i) => i.kind == 'physical');

  /// Every item has an intensity, and a persistence unless it is a condition
  /// (optional there).
  bool get allItemsReady => items.every(
        (i) =>
            i.intensity != null &&
            (i.kind == 'condition' || i.persistence != null),
      );

  bool get hasAreaSelection =>
      areas.isNotEmpty || selectedConditionIds.isNotEmpty;

  bool get hasOptionSelection =>
      selectedOptions.isNotEmpty || customLabels.isNotEmpty;

  JournalFlowState copyWith({
    JournalStep? step,
    String? mood,
    Set<JournalArea>? areas,
    Set<String>? selectedConditionIds,
    List<UserCondition>? conditions,
    List<JournalArea>? pendingAreas,
    String? time,
    String? branch,
    bool clearBranch = false,
    String? bodySide,
    List<SelectedRegion>? selectedRegions,
    int? regionIndex,
    Set<String>? selectedOptions,
    List<String>? customLabels,
    List<JournalItem>? items,
    Set<String>? triggers,
    String? triggerNote,
    String? note,
    String? phraseId,
    bool clearPhrase = false,
    List<String>? shownPhraseIds,
    bool? itemLimitReached,
    bool? isSaving,
  }) {
    return JournalFlowState(
      step: step ?? this.step,
      mood: mood ?? this.mood,
      areas: areas ?? this.areas,
      selectedConditionIds: selectedConditionIds ?? this.selectedConditionIds,
      conditions: conditions ?? this.conditions,
      pendingAreas: pendingAreas ?? this.pendingAreas,
      time: time ?? this.time,
      branch: clearBranch ? null : (branch ?? this.branch),
      bodySide: bodySide ?? this.bodySide,
      selectedRegions: selectedRegions ?? this.selectedRegions,
      regionIndex: regionIndex ?? this.regionIndex,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      customLabels: customLabels ?? this.customLabels,
      items: items ?? this.items,
      triggers: triggers ?? this.triggers,
      triggerNote: triggerNote ?? this.triggerNote,
      note: note ?? this.note,
      phraseId: clearPhrase ? null : (phraseId ?? this.phraseId),
      shownPhraseIds: shownPhraseIds ?? this.shownPhraseIds,
      itemLimitReached: itemLimitReached ?? this.itemLimitReached,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
