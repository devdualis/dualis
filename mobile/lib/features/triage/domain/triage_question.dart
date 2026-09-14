import 'package:flutter/foundation.dart';

/// Represents a single option within a triage question step.
@immutable
class TriageOption {
  final String key;          // machine-readable option identifier
  final String labelKey;     // ARB localization key for display label
  final String? systemKey;   // maps to RedFlagEvaluator system/dimension key
  final int? intensityValue; // numeric intensity for emergency gate (null if N/A)

  const TriageOption({
    required this.key,
    required this.labelKey,
    this.systemKey,
    this.intensityValue,
  });
}

/// Represents a single step in the 5-step triage wizard.
@immutable
class TriageQuestion {
  final int stepIndex;        // 0..4
  final String questionKey;   // ARB localization key for question text
  final List<TriageOption> options; // empty for preview step (step 4)
  final bool isPreview;       // true for Step 4 (no selection required)
  final bool isNumericScale;  // true for Vertical B Step 2 (1-5 scale)

  const TriageQuestion({
    required this.stepIndex,
    required this.questionKey,
    required this.options,
    this.isPreview = false,
    this.isNumericScale = false,
  });
}
