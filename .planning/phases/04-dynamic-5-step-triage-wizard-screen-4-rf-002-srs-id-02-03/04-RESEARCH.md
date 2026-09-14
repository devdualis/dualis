# Phase 4: Dynamic 5-Step Triage Wizard — Research

**Researched:** 2026-09-14  
**Domain:** Flutter Riverpod state machine · Animated theming · Clinical decision tree · Emergency interception  
**Confidence:** HIGH

---

## User Constraints

### Locked Decisions
- Free Tier only — skip all premium features (no AI classification in this phase).
- Trilingual localization: `pt-BR`, `es`, `en` via existing `.arb` bundles.
- State must use Riverpod `autoDispose` for LGPD Art. 11 in-memory data destruction.
- Emergency gate must use existing `RedFlagEvaluator.evaluateStructured()` and `EmergencyController.triggerEmergency()`.
- Color palette fixed: Soft Indigo `#3F51B5` for Psico-Emocional, Clinical Teal `#00796B` for Física.
- Exact 5 clinical questions per vertical from SRS Section 3.1 (not modifiable).

### Deferred (OUT OF SCOPE for Phase 4)
- Gemini 1.5 Flash AI classification (Phase 5).
- ANTI-01 Antiburla temporal scanning (Phase 7).
- Offline Drift SQLite submission (Phase 8).
- Actual article cross-referencing in Step 5 (Phase 6/5 — Step 5 is preview/confirm only).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Rationale |
|---|---|---|
| 5-step clinical decision tree state machine | Flutter client (Riverpod Notifier autoDispose) | Pure in-memory session data, LGPD Art. 11 |
| Chromatic vertical theme transition (Indigo ↔ Teal) | Flutter client (TweenAnimationBuilder) | Visual-only, no backend |
| Emergency red-flag interception at Step 1/Step 3 | Flutter client (RedFlagEvaluator deterministic) | <1ms gate must be synchronous client-side |
| Question answer persistence during session | Flutter client (TriageWizardNotifier state) | Ephemeral, autoDispose on exit |
| ARB localization of all question text/labels | Flutter client (AppLocalizations) | Already wired I18N-01 |
| Triage summary preview (Step 5) | Flutter client (read-only state display) | Submission deferred to Phase 5 |

---

## Research Summary

Phase 4 builds Screen 4: the Dynamic 5-Step Triage Wizard. This is a pure Flutter client feature with no new backend dependencies — the wizard collects structured answers across 2 verticals (Psico-Emocional and Física), each with exactly 5 clinical steps from SRS Section 3.1, enforces red-flag interception at Step 1 and Step 3, and manages the entire triage session in Riverpod `autoDispose` state.

The architecture mirrors the existing `EmergencyController` pattern (a Riverpod `Notifier`), using `TriageWizardNotifier extends AutoDisposeNotifier<TriageWizardState>`. When the route is popped, Riverpod wipes state immediately from memory (LGPD Art. 11).

Visual theme tweening is via `TweenAnimationBuilder<Color?>` at the Scaffold level. 300ms `Curves.easeInOut` matches Material 3 motion specification.

---

## Key Technical Findings

### 1. State Machine Design

```
TriageWizardState (Freezed immutable)
  - activeVertical: TriageVertical  // psicoEmocional | fisica
  - currentStep: int                // 0..4
  - answers: Map<int, String>       // stepIndex -> selectedOptionKey
  - isCompleting: bool

TriageWizardNotifier (AutoDisposeNotifier<TriageWizardState>)
  - selectOption(stepIndex, optionKey) → saves answer + runs emergency gate
  - advance() → validated: blocked if current step unanswered
  - goBack() → returns to previous step
  - complete() → marks isCompleting = true (used by Phase 5 to submit)
```

autoDispose: declared via `@riverpod` (riverpod_annotation) with default keepAlive: false. Immediately destroyed on screen exit — no manual dispose needed.

### 2. Clinical Question Definitions (exact SRS 3.1)

#### Vertical A — Psico-Emocional

| Step | ID | Question (pt-BR) | Options (key → display) |
|---|---|---|---|
| 0 | `natureEmotional` | "Olhando para o seu lado emocional e mental, qual palavra descreve melhor o que você está sentindo agora?" | `ansiedade_agitacao` → Ansiedade/Agitação · `tristeza_desanimo` → Tristeza/Desânimo · `estresse_irritabilidade` → Estresse/Irritabilidade · `cansaco_mental` → Cansaço Mental |
| 1 | `persistenceEmotional` | "Você tem se sentido assim frequentemente nos últimos dias ou é algo muito específico de hoje?" | `comecou_hoje` → Começou hoje · `ja_faz_alguns_dias` → Já faz alguns dias · `algo_constante_semanas` → É algo constante há semanas |
| 2 | `intensityEmotional` | "Essa sensação está parecendo um leve incômodo de fundo ou algo forte que está acelerando seus pensamentos?" | `leve_controlavel`→ Leve e controlável (maps to intensity 2) · `moderada` → Moderada (maps to 3) · `muito_forte` → Muito forte e difícil de segurar (maps to 4) |
| 3 | `triggersEmotional` | "Você consegue identificar se existe um motivo principal para isso estar acontecendo hoje?" | `trabalho_estudos` · `familia_relacionamentos` · `noite_ruim_sono` · `nao_sei_dizer` |
| 4 | Preview | "Revisão da sua Autoavaliação Psico-Emocional" | Confirm CTA only (no selection) |

**Emergency gate — Step 0 (Nature):**
- `tristeza_desanimo` → `evaluateStructured('depressive_hopelessness', 4, true)` → suicidalCrisis
- `ansiedade_agitacao` → `evaluateStructured('anxious_agitation', 4, true)` → anxiousPanicCollapse
- Other options → no gate

**Emergency gate — Step 2 (Intensity):**
- `muito_forte` → intensity 4 → evaluate with system from Step 0 answer mapping

#### Vertical B — Física

| Step | ID | Question (pt-BR) | Options (key → systemKey) |
|---|---|---|---|
| 0 | `locationPhysical` | "Vamos falar sobre a parte física. Onde você está sentindo esse desconforto ou dor principal?" | `cabeca` → `head_neck` · `costas_coluna` → `musculoskeletal_back` · `articulacoes` → `musculoskeletal_joints` · `abdomen_estomago` → `gastrointestinal` |
| 1 | `persistencePhysical` | "Há quanto tempo essa dor ou anomalia persiste?" | `comecou_agora` · `ha_alguns_dias` · `e_cronica` |
| 2 | `intensityPhysical` | "Em uma escala de 1 a 5 (onde 1 é quase imperceptível e 5 é insuportável), como está agora?" | Numeric 1–5 visual selector |
| 3 | `triggersPhysical` | "Você lembra de ter feito algum esforço atípico, exercício pesado ou sofrido alguma batida/queda recentemente?" | `sim_exercicio_intenso` · `sim_sofri_queda` · `nao_comecou_do_nada` |
| 4 | Preview | "Revisão da sua Avaliação Física" | Confirm CTA only |

**Emergency gate — Step 2 (Intensity):**
Direct numeric 1–5. Call `evaluateStructured(systemKey, selectedInt, false)`.
Per RedFlagEvaluator: intensity 5 on any system → emergency; intensity 4 on `cardiovascular_chest`, `respiratory`, `neurological`, `head_neck` → emergency.
Note: `cabeca` maps to `head_neck` → Level 4 triggers emergency.

### 3. Chromatic Theme Transition Engine

Active color derived from `state.activeVertical`:
- `psicoEmocional` → `AppColors.softIndigo` (#3F51B5)
- `fisica` → `AppColors.clinicalTeal` (#00796B)

`TweenAnimationBuilder<Color?>` at Scaffold level, duration 300ms, `Curves.easeInOut`. Active color applied to: AppBar background, step progress indicator, option chip selection highlight, CTA button background.

### 4. Route Integration

New route `/triage` in `app_router.dart`. Receives `TriageVertical` enum via `GoRouterState.extra`.
New path in `route_paths.dart`: `static const String triage = '/triage';`

For Phase 4 standalone testing: default to `TriageVertical.psicoEmocional` if no extra provided.

### 5. ARB Localization Keys

New keys required in `app_pt.arb` / `app_es.arb` / `app_en.arb`:
- `triageStep` (with `{step}`, `{total}` placeholders)
- `triageBannerEmotional`, `triageBannerPhysical`
- `triageNext`, `triageBack`, `triageConfirm`
- `triagePreviewTitle`, `triagePreviewSubmit`
- All question texts and option labels (full list in PLAN.md)

### 6. Directory Structure

```
lib/features/triage/
  domain/
    triage_question.dart              # Immutable question + option model
    triage_vertical.dart              # TriageVertical enum  
    triage_wizard_state.dart          # Freezed state class
  presentation/
    controllers/
      triage_wizard_notifier.dart     # AutoDisposeNotifier with emergency gate
    screens/
      triage_wizard_screen.dart       # Main scaffold + TweenAnimationBuilder
    widgets/
      triage_step_banner.dart         # Colored AppBar with step progress bar
      triage_option_chip.dart         # Selectable answer chip
      triage_intensity_selector.dart  # 1-5 numeric visual selector (Vertical B Step 2)
      triage_preview_card.dart        # Step 4 summary review card
```

### 7. Emergency Interception Flow

```
User selects answer at Step 0 or Step 2
  ↓
selectOption() in TriageWizardNotifier
  ↓
_evaluateEmergencyGate(step, optionKey, vertical)   [synchronous <1ms]
  ↓
RedFlagEvaluator.evaluateStructured(system, intensity, isEmotional)
  ↓ result != null?
  YES → emergencyControllerProvider.notifier.triggerEmergency(context, emergencyContext)
        → GoRouter pushes /emergency with EmergencyContext extra
        → Screen pops → TriageWizardNotifier autoDispose clears sensitive data
  NO  → wizard continues normally
```

---

## Validation Architecture

### Unit Tests — `test/features/triage/triage_wizard_notifier_test.dart`

1. Initial state: step 0, psicoEmocional vertical, empty answers
2. `advance()` blocked if current step has no answer (state unchanged)
3. `advance()` increments step when answered
4. `goBack()` from step 2 returns to step 1 (answers preserved)
5. `selectOption()` at Step 2, `muito_forte` (emotional) → evaluates intensity 4 → returns EmergencyContext
6. `selectOption()` at Step 2 intensity 5 (physical, `head_neck`) → emergency triggered
7. `selectOption()` at Step 2 intensity 3 (physical) → no emergency, wizard continues
8. ProviderContainer teardown verifies state is disposed (autoDispose semantics)

### Widget Tests — `test/features/triage/triage_wizard_screen_test.dart`

1. Renders banner "Iniciando Autoavaliação Psico-Emocional" on psicoEmocional vertical
2. Renders banner "Iniciando Autoavaliação Física" on fisica vertical
3. "Próximo" button disabled when no option selected
4. Tapping option chip enables "Próximo" button
5. Tapping "Próximo" advances to step 2 view
6. Step 4 (preview) shows summary cards of collected answers
7. "Confirmar e Finalizar" CTA visible at step 4

### Test Commands

```bash
cd mobile && flutter analyze
cd mobile && flutter test test/features/triage/triage_wizard_notifier_test.dart
cd mobile && flutter test test/features/triage/triage_wizard_screen_test.dart
```
