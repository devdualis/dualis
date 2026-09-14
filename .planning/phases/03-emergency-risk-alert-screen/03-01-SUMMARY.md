# Phase 3 Plan 01: Deterministic Red-Flag Evaluation Engine & Emergency State Machine Summary

**Phase:** 03-emergency-risk-alert-screen  
**Plan:** 01  
**Wave:** 1  
**Status:** Completed  
**Completed Date:** 2026-09-14  

---

## Executive Overview

Plan 03-01 established the clinical triage life-safety foundation for **DualisCheckUp**, implementing a deterministic, zero-network, zero-LLM red-flag symptom evaluation engine, mobile telephony intent declarations (`url_launcher`), the emergency state machine, and the GoRouter `/emergency` route.

All evaluations execute client-side in under 1 millisecond, guaranteeing immediate interception of high-acuity symptoms (Manchester Triage System Red/Orange, Emergency Severity Index Level 1-2) before detailed questionnaire workflows are presented.

---

## Key Deliverables & Accomplishments

### 1. Telephony Package Visibility & Permissions
- Added `url_launcher: ^6.3.2` to [pubspec.yaml](file:///Users/ricardorincon/workspace/dualis/mobile/pubspec.yaml).
- Configured native Android `<queries>` declarations in [AndroidManifest.xml](file:///Users/ricardorincon/workspace/dualis/mobile/android/app/src/main/AndroidManifest.xml) for:
  - `android.intent.action.DIAL` (`tel` scheme)
  - `android.intent.action.VIEW` (`geo` scheme)
  - `android.intent.action.VIEW` (`https` scheme)
- Configured iOS `LSApplicationQueriesSchemes` array in [Info.plist](file:///Users/ricardorincon/workspace/dualis/mobile/ios/Runner/Info.plist) for `tel`, `geo`, `maps`, `https`, `http`.

### 2. Clinical Emergency Domain Models
- Created [emergency_trigger_category.dart](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/domain/emergency_trigger_category.dart) declaring enum `EmergencyTriggerCategory`:
  - `chestPain`, `respiratoryDistress`, `neurologicalStroke`, `thunderclapHeadache`, `anaphylaxisAirway`, `massiveHemorrhage`, `suicidalCrisis`, `anxiousPanicCollapse`, `severePsychosisDelirium`, `generalCriticalIntensity`.
- Created [emergency_context.dart](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/domain/emergency_context.dart) declaring:
  - `EmergencyServiceType` enum (`samu192`, `cvv188`, `bombeiros193`, `policia190`, `mapsEmergencyRoom`).
  - Immutable `EmergencyContext` model with computed `primaryService` (routing emotional crises to CVV `188` and physical emergencies to SAMU `192`).

### 3. Deterministic Red-Flag Evaluator Engine
- Created [red_flag_evaluator.dart](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/domain/red_flag_evaluator.dart) with two evaluation entrypoints:
  - `evaluateText(String text)`: Trilingual regex fast-gate scanning raw user complaints across Brazilian Portuguese (`pt-BR`), Spanish (`es`), and English (`en`) for suicidal ideation, Cincinnati stroke signs, crushing chest pain, airway collapse/anaphylaxis, and thunderclap headache.
  - `evaluateStructured(...)`: Categorical gate intercepting Level 4–5 intensities on vital systems (`cardiovascular_chest`, `respiratory`, `neurological`, `head_neck`), acute emotional crises (`depressive_hopelessness`, `anxious_agitation`, `stress_burnout`), and Level 5 critical ratings across any organ.

### 4. Telephony Service & Navigation State Machine
- Created [telephony_service.dart](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/services/telephony_service.dart) wrapping `url_launcher` with `canMakeCalls()`, `callSamu()` (`tel:192`), `callBombeiros()` (`tel:193`), `callCvv()` (`tel:188`), `callPolicia()` (`tel:190`), and `openNearestEmergencyRoom()` (`geo:0,0?q=pronto+socorro` with Google Maps fallback).
- Added `RoutePaths.emergency = '/emergency'` in [route_paths.dart](file:///Users/ricardorincon/workspace/dualis/mobile/lib/core/router/route_paths.dart).
- Registered `/emergency` route in [app_router.dart](file:///Users/ricardorincon/workspace/dualis/mobile/lib/core/router/app_router.dart) receiving `state.extra as EmergencyContext?` with safe fallback.
- Created [EmergencyScreen](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/presentation/screens/emergency_screen.dart) baseline widget.
- Created [EmergencyController](file:///Users/ricardorincon/workspace/dualis/mobile/lib/features/emergency/presentation/controllers/emergency_controller.dart) (`emergencyControllerProvider`) managing emergency state and atomic teardown navigation (`triggerEmergency`, `recordExitConfirmed`, `clearEmergency`).

---

## Test Verification Summary

### Automated Tests Executed
1. **RedFlagEvaluator Unit Suite** ([red_flag_evaluator_test.dart](file:///Users/ricardorincon/workspace/dualis/mobile/test/features/emergency/red_flag_evaluator_test.dart)):
   - Physical chest pain intensity 5 -> `EmergencyTriggerCategory.chestPain` (Passed)
   - Physical dyspnea intensity 4 -> `EmergencyTriggerCategory.respiratoryDistress` (Passed)
   - Neurological deficit intensity 4 -> `EmergencyTriggerCategory.neurologicalStroke` (Passed)
   - Head/neck airway compromise intensity 4 -> `EmergencyTriggerCategory.anaphylaxisAirway` (Passed)
   - General non-critical organ intensity 5 -> `EmergencyTriggerCategory.generalCriticalIntensity` (Passed)
   - Emotional depressive hopelessness intensity 4 -> `EmergencyTriggerCategory.suicidalCrisis` (Passed)
   - Emotional panic collapse intensity 4 -> `EmergencyTriggerCategory.anxiousPanicCollapse` (Passed)
   - Emotional burnout agitation intensity 4 -> `EmergencyTriggerCategory.severePsychosisDelirium` (Passed)
   - Negative controls (mild knee pain 2, mild stress 2, headache 3, non-critical organ 4) -> `null` (Passed)
   - Trilingual regex positive matches:
     - Portuguese stroke ("boca torta e dormência no braço") -> `neurologicalStroke` (Passed)
     - Spanish stroke ("cara torcida y dificultad para hablar") -> `neurologicalStroke` (Passed)
     - English stroke ("facial droop and slurred speech") -> `neurologicalStroke` (Passed)
     - Portuguese suicide ("quero me matar") -> `suicidalCrisis` (Passed)
     - Spanish suicide ("quiero quitarme la vida") -> `suicidalCrisis` (Passed)
     - English suicide ("want to end my life") -> `suicidalCrisis` (Passed)
     - Portuguese thunderclap ("pior dor de cabeça da minha vida") -> `thunderclapHeadache` (Passed)
     - Crushing chest pain ("I have crushing chest pain and cold sweat") -> `chestPain` (Passed)
     - Airway collapse ("socorro não consigo respirar") -> `anaphylaxisAirway` (Passed)
   - Performance invariant: 1,000 evaluations complete in <1ms average (Passed)

2. **Telephony & Emergency Controller Suite** ([telephony_service_test.dart](file:///Users/ricardorincon/workspace/dualis/mobile/test/features/emergency/telephony_service_test.dart)):
   - `canMakeCalls()` positive & tablet/no-dialer negative checks (Passed)
   - `callSamu()`, `callCvv()`, `callBombeiros()`, `callPolicia()` URI formatting and dispatch (Passed)
   - `openNearestEmergencyRoom()` geo intent and web fallback URL (Passed)
   - `EmergencyController` initial state, `clearEmergency`, and `recordExitConfirmed` transitions (Passed)

3. **Full Mobile Regression Suite**:
   - `flutter test`: 80 / 80 tests passing (100% green).
   - `flutter analyze`: 0 issues found.

---

## Git Commit Log

- `feat(03-01): configure telephony permissions and emergency domain models` (`1901a77`)
- `feat(03-01): implement deterministic red-flag symptom evaluator` (`c3b26b4`)
- `feat(03-01): implement telephony service, emergency controller, and router route` (`95adb94`)
- `chore(mobile): update generated plugin registrants for url_launcher` (`61e454f`)

---

## Next Steps (Plan 03-02)

- Implement complete trilingual ARB strings in `app_pt.arb`, `app_es.arb`, `app_en.arb`.
- Build full Screen 8 UI architecture (`#D32F2F`, `PopScope(canPop: false)`, `EmergencyExitConfirmationDialog`, `TelephonyFallbackDialog`).
- Build NestJS `triage_emergency_events` Drizzle schema, service, and controller for fire-and-forget LGPD telemetry.
