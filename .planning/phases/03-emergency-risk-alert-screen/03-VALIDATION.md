---
phase: "3"
slug: "emergency-risk-alert-screen"
status: pending
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-14"
---

# Phase 3 — Validation Strategy: Emergency Risk Alert Screen (Screen 8 / RF-006)

> Per-phase validation contract for feedback sampling during execution of Phase 3.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Backend Framework** | Vitest 3.x + Supertest 7.x |
| **Mobile Framework** | Flutter Test (`package:flutter_test`) + Mocktail |
| **Backend Config** | `backend/vitest.config.ts`, `backend/vitest.config.e2e.ts` |
| **Mobile Config** | `mobile/pubspec.yaml`, `mobile/analysis_options.yaml` |
| **Quick Mobile Test** | `cd mobile && flutter test test/features/emergency/red_flag_evaluator_test.dart` |
| **Full Emergency Test Suite** | `cd mobile && flutter test test/features/emergency/` |
| **Backend Audit Suite** | `cd backend && npm run test:e2e -- test/e2e/emergency-event.e2e-spec.ts` |
| **Estimated runtime** | ~10–15 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick task verify command (`flutter test <file>` or `npm test`)
- **After every plan wave:** Run full emergency verification suite
- **Before `/gsd-verify-work`:** All backend and mobile emergency tests must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | EMRG-01, EMRG-03 | T-03-01 | `url_launcher` dependency, Android intent `<queries>` (`tel`, `geo`, `https`), iOS `LSApplicationQueriesSchemes`, domain models (`EmergencyTriggerCategory`, `EmergencyContext`) | unit | `cd mobile && flutter analyze` | ⬜ | ⬜ pending |
| 03-01-02 | 01 | 1 | EMRG-01 | T-03-02 | `RedFlagEvaluator` deterministically intercepts Level 4–5 critical organ intensities and trilingual high-risk keywords in <1ms without LLM | unit | `cd mobile && flutter test test/features/emergency/red_flag_evaluator_test.dart` | ⬜ | ⬜ pending |
| 03-01-03 | 01 | 1 | EMRG-01, EMRG-03 | T-03-03 | `TelephonyService` dispatches dialer intents and `emergencyControllerProvider` routes to `/emergency` while dropping active triage session drafts | unit | `cd mobile && flutter test test/features/emergency/telephony_service_test.dart` | ⬜ | ⬜ pending |
| 03-02-01 | 02 | 2 | I18N-01 | T-03-04 | Trilingual ARB bundles (`app_pt.arb`, `app_es.arb`, `app_en.arb`) contain complete emergency keys (titles, instructions, dialogs, buttons) | unit | `cd mobile && flutter test test/features/emergency/emergency_screen_test.dart -t "localization"` | ⬜ | ⬜ pending |
| 03-02-02 | 02 | 2 | EMRG-02, EMRG-03 | T-03-05 | Screen 8 renders `#D32F2F` modal, locks navigation with `PopScope(canPop: false)`, displays exit risk confirmation, and provides telephony fallback dialog | widget | `cd mobile && flutter test test/features/emergency/emergency_screen_test.dart` | ⬜ | ⬜ pending |
| 03-02-03 | 02 | 2 | SEC-01, EMRG-01 | T-03-06 | NestJS `TriageAuditModule` records emergency events asynchronously at `POST /v1/triage/emergency-event` under RLS tenant isolation | e2e/unit | `cd backend && npm run test:e2e -- test/e2e/emergency-event.e2e-spec.ts` | ⬜ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mobile/pubspec.yaml` with `url_launcher: ^6.3.2`
- [ ] `mobile/android/app/src/main/AndroidManifest.xml` with `<queries>` declarations for `tel`, `geo`, `https`
- [ ] `mobile/ios/Runner/Info.plist` with `LSApplicationQueriesSchemes`
- [ ] `backend/src/database/schema/triage-emergency-events.schema.ts`
- [ ] `mobile/test/features/emergency/red_flag_evaluator_test.dart` — Evaluator test stubs
- [ ] `mobile/test/features/emergency/emergency_screen_test.dart` — Screen 8 test stubs

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Telephony Call Handoff (SAMU 192 / CVV 188) | EMRG-03 | Native OS dialer application handoff cannot place cellular calls automatically in headless test runner | Run on physical iOS/Android phone with SIM card, tap "Ligar SAMU (192)", verify OS phone dialer opens pre-filled with 192 |
| Edge Swipe / Hardware Back Dismissal Prevention | EMRG-02 | Physical gesture navigation on modern gesture-based Android/iOS devices | On Screen 8, perform edge swipe or press hardware back button, confirm screen does NOT close and warning dialog appears |
| Offline Emergency Triggering | EMRG-01 | Network disconnect verification | Put device in Airplane mode, enter crushing chest pain / level 5 symptom, confirm instant transition to Screen 8 with zero error spinners |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all test scaffold prerequisites
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved
