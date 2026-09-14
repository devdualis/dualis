---
phase: "2"
slug: "onboarding-identity-screens-1-2-with-native-biometrics"
status: pending
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-14"
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Backend Framework** | Vitest 3.x + Supertest 7.x |
| **Mobile Framework** | Flutter Test (`package:flutter_test`) + Mocktail |
| **Backend Config** | `backend/vitest.config.ts`, `backend/vitest.config.e2e.ts` |
| **Mobile Config** | `mobile/pubspec.yaml`, `mobile/analysis_options.yaml` |
| **Quick Backend Command** | `npm run test -- test/unit/auth.service.spec.ts` (in `backend/`) |
| **Quick Mobile Command** | `flutter test` (in `mobile/`) |
| **Full Phase 2 Suite** | `npm run test:e2e` (in `backend/`) && `flutter test` (in `mobile/`) |
| **Estimated runtime** | ~15–20 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick task verify command (`npm run test` or `flutter test <path>`)
- **After every plan wave:** Run full verification suite
- **Before `/gsd-verify-work`:** All backend and mobile tests must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | ONBD-01, I18N-01 | T-02-01 | Flutter project initializes with Material 3 dual palette, dependencies, and trilingual intl bundles (pt-BR, es, en) | unit | `cd mobile && flutter analyze` | ⬜ | ⬜ pending |
| 02-01-02 | 01 | 1 | ONBD-01, I18N-01 | T-02-02 | Screen 1 renders 3-card value carousel, animated pill indicators, and language switcher dynamically updating UI | widget | `cd mobile && flutter test test/features/onboarding/onboarding_screen_test.dart` | ⬜ | ⬜ pending |
| 02-01-03 | 01 | 1 | ONBD-01 | T-02-03 | GoRouter declarative routes navigate cleanly between `/onboarding`, `/register`, and `/login` | widget | `cd mobile && flutter test test/core/router/app_router_test.dart` | ⬜ | ⬜ pending |
| 02-02-01 | 02 | 2 | AUTH-01 | T-02-04 | NestJS AuthModule hashes passwords with Argon2id, verifies credentials, issues 15m JWT, and logs LGPD consent atomically with SHA-256 IP hash | unit/integration | `cd backend && npm run test -- test/unit/auth.service.spec.ts` | ⬜ | ⬜ pending |
| 02-02-02 | 02 | 2 | AUTH-01 | T-02-05 | POST /v1/auth/register rejects unconsented LGPD requests (HTTP 400), duplicate emails (HTTP 409), and authenticates valid login | e2e | `cd backend && npm run test:e2e -- test/e2e/auth.e2e-spec.ts` | ⬜ | ⬜ pending |
| 02-02-03 | 02 | 2 | AUTH-01 (RF-007) | T-02-06 | Screen 2 registration form validates all 5 fields and strictly disables submit button when LGPD consent checkbox is unchecked | widget | `cd mobile && flutter test test/features/auth/register_screen_test.dart` | ⬜ | ⬜ pending |
| 02-02-04 | 02 | 2 | AUTH-02 | T-02-07 | App lifecycle observer injects privacy blur veil on backgrounding and requires biometric/passcode verification before revealing sensitive health views | widget/unit | `cd mobile && flutter test test/core/security/privacy_veil_test.dart` | ⬜ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mobile/pubspec.yaml` with required dependencies (`flutter_riverpod`, `go_router`, `dio`, `local_auth`, `flutter_secure_storage`, `intl`, `mocktail`)
- [ ] `mobile/l10n.yaml` and `.arb` templates (`app_pt.arb`, `app_es.arb`, `app_en.arb`)
- [ ] `backend/test/unit/auth.service.spec.ts` — Auth service unit test stubs
- [ ] `backend/test/e2e/auth.e2e-spec.ts` — Auth E2E test stubs

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Physical Device Biometric Sensor (FaceID / TouchID / BiometricPrompt) | AUTH-02 | Hardware sensors cannot be actuated automatically in headless CI without physical hardware | Build and run app on physical iOS/Android device, trigger registration/login, confirm biometric modal appears, authenticate with fingerprint/face, verify successful unlock |
| System App Switcher Privacy Snapshot | AUTH-02 | OS-level window manager rendering of backgrounded apps | Send app to background while on an authenticated screen, open the recent apps carousel, verify the snapshot shows the opaque privacy blur shield instead of user medical data |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all test scaffold prerequisites
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
