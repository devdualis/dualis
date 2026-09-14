# 04-VERIFICATION: Phase 4 Plan Review

**Reviewed:** 2026-09-14  
**Reviewer:** GSD Plan Checker  
**Documents reviewed:**
- `REQUIREMENTS.md` (TRG-03, TRG-04, TRG-05, EMRG-01–03)
- `ROADMAP.md` (Phase 4 section)
- `04-RESEARCH.md`
- `04-01-PLAN.md`
- `04-02-PLAN.md`
- `red_flag_evaluator.dart`
- `emergency_controller.dart`
- `app_router.dart`
- `app_colors.dart`

---

## VERDICT: PASS_WITH_NOTES

The Phase 4 plans are **approved for execution** with one mandatory fix before coding begins (W1) and two informational notes.

---

### Passed Checks

1. **TRG-03 — Vertical banners designed:** Both banners are fully specified.
   - Vertical A: *"Iniciando Autoavaliação Psico-Emocional"* with `AppColors.softIndigo` (`#3F51B5`) ✓
   - Vertical B: *"Iniciando Autoavaliação Física"* with `AppColors.clinicalTeal` (`#00796B`) ✓
   - Both colors confirmed present in `app_colors.dart`. Color values match REQUIREMENTS exactly. ✓

2. **TRG-04 — All 10 questions with exact SRS 3.1 text present:** All question texts and option keys for both verticals are specified verbatim in `04-01-PLAN.md` T4 and T8, cross-verified against REQUIREMENTS.md Section 3.1.
   - Vertical A (5 steps): Natureza, Tempo/Persistência, Intensidade, Causas/Gatilhos, Preview ✓
   - Vertical B (5 steps): Localização, Tempo/Persistência, Intensidade (numeric 1–5), Causas/Gatilhos, Preview ✓

3. **TRG-05 — Riverpod `autoDispose` specified and explained:**
   - RESEARCH.md explicitly links `autoDispose` to LGPD Art. 11 in-memory data destruction. ✓
   - `04-01-PLAN.md` declares `@riverpod` annotation (which defaults to `keepAlive: false` / autoDispose) on `TriageWizardNotifier`. ✓
   - `04-02-PLAN.md` T5 explicitly documents the LGPD rationale in the screen's autoDispose note. ✓
   - Unit test case 9 (04-01) validates `ProviderContainer` dispose semantics. ✓

4. **Emergency gate — `evaluateStructured()` wired correctly at Step 0 and Step 2 (see W1 below for gate scope issue):**
   - Gate fires at Step 0 (emotional nature) and Step 2 (intensity) for Vertical A. ✓
   - Gate fires at Step 2 (numeric intensity) for Vertical B. ✓
   - Correct use of `RedFlagEvaluator.evaluateStructured()` API signature (named parameters). ✓
   - `_emotionalDimensionFromStep0()` and `_physicalSystemFromStep0()` correctly back-reference Step 0 answers. ✓

5. **Zero-failure safety routing:**
   - Physical Vertical: intensity 5 on any system → emergency; intensity 4 on `head_neck` (mapped from `cabeca`) → emergency (`anaphylaxisAirway`). ✓
   - `cardiovascular_chest`, `respiratory`, `neurological` at intensity 4/5 → emergency per evaluator. ✓
   - `EmergencyController.triggerEmergency()` pushes `/emergency` via GoRouter. `/emergency` route confirmed in `app_router.dart`. ✓

6. **LGPD compliance — autoDispose wipes draft health data on exit:**
   - `TriageWizardNotifier` uses `@riverpod` (autoDispose). When screen is popped, Riverpod immediately disposes the provider, wiping `answers: Map<int, String>` from memory. ✓
   - `EmergencyController` is correctly `Notifier` (non-autoDispose) — emergency state must survive screen transitions. ✓
   - No sensitive data persisted to disk or backend in Phase 4 (pure in-memory). ✓

7. **Trilingual localization — ARB keys defined for all texts:**
   - `04-01-PLAN.md` T8 lists complete pt-BR ARB key set (both banners, step indicator, all navigation labels, all 10 question texts, all 27 option labels, intensity scale labels). ✓
   - es and en translations are stated as required counterparts. ✓

8. **Unit test coverage:**
   - 9 unit test cases for `TriageWizardNotifier`: initial state, advance() gating, step traversal, goBack(), emergency gate (emotional step 0), emergency gate (emotional step 2 intensity 4), emergency gate (physical step 2 intensity 5 head_neck), no-emergency (intensity 3), and autoDispose lifecycle. ✓
   - 5 unit tests for `TriageQuestionBank`: step counts, option minimums, numeric scale flag, preview flag. ✓

9. **Widget test coverage:**
   - 8 widget test cases for `TriageWizardScreen`: both banners, disabled/enabled "Próximo", chip interaction, advance, back-arrow, step 4 preview card, confirm CTA. ✓
   - Uses `ProviderScope` + mock GoRouter + mocktail for `EmergencyController`. ✓

10. **No premium features included:** Zero references to subscription, premium, or PREM-* features anywhere in Phase 4 documents. ✓

11. **No AI/Gemini calls in Phase 4:** Confirmed — no Gemini, AI, or LLM references exist in any Phase 4 document. AI classification explicitly deferred to Phase 5. ✓

12. **No backend dependencies introduced:** All capability is pure Flutter client / Riverpod in-memory. No HTTP calls, no Supabase queries, no NestJS endpoints. ✓

13. **Existing emergency infrastructure reused without duplication:**
   - `RedFlagEvaluator.evaluateStructured()` — reused directly. ✓
   - `EmergencyController.triggerEmergency()` — reused via provider reference. ✓
   - `EmergencyContext`, `EmergencyTriggerCategory` — reused as import-only types. ✓
   - No new emergency evaluation logic is duplicated. ✓

14. **Verification commands present and correct:**
   - `04-01-PLAN.md`: `build_runner build`, `flutter analyze`, notifier test, question bank test. ✓
   - `04-02-PLAN.md`: `build_runner build`, `flutter analyze`, screen test, recursive `test/features/triage/`. ✓
   - RESEARCH.md also lists standalone test commands for both test files. ✓

---

### Issues Found

#### W1 — Step 0 Emotional Emergency Gate Over-Triggers (WARNING — Must Fix Before Coding)

**Location:** `04-01-PLAN.md` T6, `_evaluateGate()` Step 0 block (lines 252–268)

**Issue:** The plan calls `RedFlagEvaluator.evaluateStructured(intensity: 4, ...)` for **all three** options at Step 0: `tristeza_desanimo`, `ansiedade_agitacao`, AND `estresse_irritabilidade`. Per `red_flag_evaluator.dart` (lines 237–263), `evaluateStructured` returns a non-null `EmergencyContext` for all three dimensions at intensity 4. This means:

- A user selecting **"Estresse / Irritabilidade"** as their emotional nature at Step 0 is **immediately hard-routed to Screen 8 (Emergency)** before being asked any intensity question.
- A user selecting **"Ansiedade / Agitação"** or **"Tristeza / Desânimo"** faces the same false escalation.
- This contradicts the clinical intent: Intensity at Step 2 gates the emergency, not nature selection alone.

**Clinical impact:** False emergency routing for routine stress/anxiety reports. A user saying "I feel anxious about exams" is routed to SAMU/CVV emergency contacts — a severe UX and clinical safety regression.

**REQUIREMENTS.md reference:** EMRG-01 states escalation requires "high intensity (Level 4 or 5) **associated with** critical red-flag areas," not nature selection alone.

**Required fix:** Remove the Step 0 gate block entirely from `_evaluateGate()`. The Step 2 gate already carries nature context via `_emotionalDimensionFromStep0()` and applies the correct intensity threshold — that is sufficient and correct.

```dart
// REMOVE this entire block from _evaluateGate():
// if (stepIndex == 0) {
//   final dimensionMap = { ... };
//   ...
//   return RedFlagEvaluator.evaluateStructured(intensity: 4, ...);
// }

// The Step 2 block below is correct and sufficient:
if (stepIndex == 2) {
  final intensityMap = {'leve_controlavel': 2, 'moderada': 3, 'muito_forte': 4};
  final intensity = intensityMap[optionKey] ?? 2;
  final dim = _emotionalDimensionFromStep0();
  return RedFlagEvaluator.evaluateStructured(
    systemOrDimension: dim,
    intensity: intensity,
    isEmotional: true,
    selectedSymptom: optionKey,
  );
}
```

Also update **unit test case 5** in `04-01-PLAN.md` T10 (currently: "`selectOption()` at step 0 with `tristeza_desanimo` → emergency context returned") to assert **no emergency** at Step 0, with emergency only at Step 2 `muito_forte`.

---

#### N1 — RESEARCH.md Step Numbering Uses 1-Indexed Labels (NOTE)

**Location:** `04-RESEARCH.md`, line 42

> "enforces red-flag interception at **Step 1** and **Step 3**"

All plans and code use 0-indexed steps (Step 0 = Nature, Step 2 = Intensity). This documentation-only inconsistency will not cause bugs but could confuse developers. Update to "Step 0 and Step 2 (0-indexed)."

---

#### N2 — ARB Key File Path Should Be Verified (NOTE)

**Location:** `04-01-PLAN.md` T8, line 334

> `mobile/lib/features/home/presentation/app_pt.arb`

ARB files under `features/home/presentation/` is non-standard. Confirm this path matches the Phase 2 established convention before modifying. Run:

```bash
find mobile/lib -name "*.arb"
```

No blocker — a precautionary check only.

---

### Recommendations

1. **Apply W1 fix to `04-01-PLAN.md` T6 and update unit test case 5 before implementation begins.** This is the only mandatory change.

2. **Add a unit test asserting Step 0 `cansaco_mental` does NOT trigger emergency** (logically confirmed, but worth an explicit assertion given the clinical context).

3. **Verify ARB path against Phase 2 output** (see N2) before T8 execution.

4. **Document in a future phase plan** that `cardiovascular_chest`, `respiratory`, and `neurological` physical locations are absent from Phase 4's question bank and must be added to `TriageQuestionBank.fisica` Step 0 in Phase 6.

5. **Consider a manual device verification note** for the intensity selector's warning icon (⚠️ at ≥4) — this clinically meaningful affordance is not easily asserted in widget tests.

---

*Plans approved for execution after W1 fix is incorporated.*  
*Reviewed: 2026-09-14 by GSD Plan Checker*

---

## Post-Fix Update — 2026-09-14

**W1 resolved:** Step 0 emergency gate block removed from `_evaluateGate()` in 04-01-PLAN.md T6. Gate now fires exclusively at Step 2 (Intensity) for both verticals, consistent with EMRG-01 ("high intensity ASSOCIATED WITH critical area"). Test case 5 updated to assert NO emergency at Step 0 nature selection.

**Final Verdict: PASS** — plans approved for execution.
