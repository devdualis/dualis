---
phase: "02-onboarding-identity-screens-1-2-with-native-biometrics"
plan: "02"
title: "NestJS AuthModule (Argon2id & LGPD Audit Trail), Screen 2 Simplified Registration & Native Biometric Hardware Security"
status: complete
completed_at: "2026-09-14T07:04:00Z"
requirements:
  - AUTH-01
  - AUTH-02
commits:
  - 27deb8a: feat(02-02): implement NestJS AuthModule with Argon2id and LGPD consent logging
  - 1265160: test(02-02): add comprehensive e2e test suite for auth endpoints
  - 6bf6235: feat(02-02): implement Screen 2 simplified registration form with LGPD consent gating
  - a368571: feat(02-02): implement native biometrics, secure storage, and privacy veil overlay
---

# Plan 02-02: Summary & Outcomes

## Executive Summary
Successfully implemented the full-stack authentication and identity foundation for **DualisCheckUp**:
1. **Backend Auth Engine (`AuthModule`)**: Implemented in NestJS with memory-hard Argon2id password hashing (`memoryCost: 65536, timeCost: 3, parallelism: 4`), short-lived JWT access tokens (15m), and atomic regulatory consent logging into `user_disclaimer_consents` under LGPD Art. 11 with SHA-256 IP address hashing.
2. **Database & Isolation Security**: Configured service-scoped user lookup migration (`0002_auth_lookup_policy.sql`) and Drizzle schema update (`users.schema.ts`) using transaction-isolated PostgreSQL settings (`set_config('app.is_auth_service', 'true', true)`), preserving tenant RLS boundaries.
3. **Screen 2: Simplified Registration (AUTH-01 / RF-007)**: Implemented in Flutter with strict client-side validation across all 5 mandatory fields (Full Name, Date of Birth, Biological Sex, Email, Password) and absolute gating preventing registration until the explicit LGPD Art. 11 consent checkbox is accepted.
4. **Native Biometrics & Hardware Security (AUTH-02)**: Integrated `local_auth` and `flutter_secure_storage` (KeyStore/Keychain), migrated Android `MainActivity.kt` to `FlutterFragmentActivity` (eliminating `BiometricPrompt` runtime crashes), declared native permissions (`USE_BIOMETRIC`, `NSFaceIDUsageDescription`), and mounted a 25px Gaussian blur `PrivacyVeilOverlay` driven by `AppLifecycleObserver` to obscure sensitive medical data upon app backgrounding.

---

## Completed Tasks

### Task 02-02-01: NestJS AuthModule with Argon2id & LGPD Audit Trail
- **Status:** Complete ✅
- **Delivered:**
  - Installed runtime dependencies (`argon2`, `@nestjs/jwt`, `@nestjs/passport`, `passport`, `passport-jwt`, `@types/passport-jwt`).
  - Created migration `backend/src/database/migrations/0002_auth_lookup_policy.sql` and updated `backend/src/database/schema/users.schema.ts` to support service-scoped user lookup (`OR current_setting('app.is_auth_service', true) = 'true'`).
  - Implemented `backend/src/modules/auth/utils/password.util.ts` exporting `hashPassword` and `verifyPassword` using OWASP-compliant Argon2id parameters.
  - Implemented DTOs (`RegisterDto`, `LoginDto`, `AuthResponseDto`, `SanitizedUser`) with strict `class-validator` rules enforcing at least two words for name, RFC 5322 email, password complexity (uppercase, lowercase, number, special char), ISO8601 birth date, and `@Equals(true)` on `lgpdConsent`.
  - Implemented `AuthService` handling registration with atomic consent logging in `user_disclaimer_consents` and transaction-isolated user login.
  - Implemented `JwtStrategy`, `JwtAuthGuard`, `AuthController` exposing `POST /v1/auth/register` (201), `POST /v1/auth/login` (200), and `GET /v1/auth/me` (200, guarded).
  - Wired `AuthModule` into `AppModule`.
  - Created `backend/test/unit/auth.service.spec.ts` testing 5 scenarios: happy path, unconsented rejection, duplicate email conflict, valid login, invalid credentials.
- **Verification:** 13/13 unit tests passed (100%).
- **Commit:** `27deb8a: feat(02-02): implement NestJS AuthModule with Argon2id and LGPD consent logging`

### Task 02-02-02: End-to-End Integration Test Suite for Auth Endpoints
- **Status:** Complete ✅
- **Delivered:**
  - Implemented `backend/test/e2e/auth.e2e-spec.ts` using Fastify HTTP testing and global `ValidationPipe({ transform: true, whitelist: true })`.
  - Verified Scenario 1: `POST /v1/auth/register` returns 201 with sanitized user profile (no `passwordHash`) and JWT token pair.
  - Verified Scenario 2: `POST /v1/auth/register` with `lgpdConsent: false` returns 400 Bad Request with localized validation error.
  - Verified Scenario 3: `POST /v1/auth/register` with duplicate email returns 409 Conflict.
  - Verified Scenario 4: `POST /v1/auth/login` with valid credentials returns 200 OK with valid tokens.
  - Verified Scenario 5: `POST /v1/auth/login` with incorrect password returns 401 Unauthorized.
  - Verified Scenario 6: `GET /v1/auth/me` with Bearer token returns 200 OK with authenticated user profile; unauthenticated returns 401.
- **Verification:** 10/10 E2E tests passed green (`legal-disclaimer` and `auth`).
- **Commit:** `1265160: test(02-02): add comprehensive e2e test suite for auth endpoints`

### Task 02-02-03: Screen 2 Simplified Registration Form with LGPD Consent Gating
- **Status:** Complete ✅
- **Delivered:**
  - `mobile/lib/features/auth/domain/form_validators.dart`: Static clinical validators for name (>=3 chars, >=2 words), email (RFC 5322 regex), password (>=8 chars, upper, lower, digit, symbol), date of birth (13-120 age bracket, non-future).
  - `mobile/lib/features/auth/domain/user_profile.dart`: `UserProfile` model and `Gender` enum (`masculino`, `feminino`, `outro`).
  - `mobile/lib/features/auth/domain/auth_state.dart`: Reactive state container for authentication status.
  - `mobile/lib/features/auth/data/auth_remote_data_source.dart`: Dio HTTP client calling `/v1/auth/register`, `/v1/auth/login`, `/v1/auth/me`.
  - `mobile/lib/features/auth/data/auth_repository_impl.dart`: Repository layer integrating remote data source.
  - `mobile/lib/features/auth/presentation/controllers/auth_controller.dart`: Modern Riverpod `NotifierProvider` managing auth state and token lifecycle.
  - `mobile/lib/features/auth/presentation/widgets/biological_sex_selector.dart`: Material 3 `SegmentedButton<Gender>` control.
  - `mobile/lib/features/auth/presentation/widgets/lgpd_consent_checkbox.dart`: `CheckboxListTile` with localized LGPD Art. 11 consent copy and bottom sheet disclaimer modal.
  - `mobile/lib/features/auth/presentation/screens/register_screen.dart`: Screen 2 form collecting 5 mandatory fields with strict submit button gating (`onPressed == null` until all fields valid and LGPD checkbox checked).
  - `mobile/lib/features/auth/presentation/screens/login_screen.dart`: Login screen with email and password inputs and navigation to registration.
  - `mobile/lib/core/router/app_router.dart`: Wired `RegisterScreen` and `LoginScreen` into GoRouter.
  - `mobile/test/features/auth/register_screen_test.dart`: Widget test suite verifying disabled state on empty inputs, disabled state when unconsented, enablement upon checking LGPD, and inline validator error feedback.
- **Verification:** 5/5 widget tests passed green.
- **Commit:** `6bf6235: feat(02-02): implement Screen 2 simplified registration form with LGPD consent gating`

### Task 02-02-04: Native Biometrics, Hardware Secure Storage & Privacy Veil Overlay
- **Status:** Complete ✅
- **Delivered:**
  - `mobile/lib/core/security/secure_storage_service.dart`: Encrypted hardware storage wrapper (`FlutterSecureStorage`) with Android KeyStore and iOS Keychain (`accessibility: KeychainAccessibility.first_unlock`), handling tokens, user IDs, and biometric configuration.
  - `mobile/lib/core/security/biometric_service.dart`: Local authentication wrapper (`LocalAuthentication`) providing hardware capability checks and biometric prompts with `persistAcrossBackgrounding: true`.
  - Configured Android `MainActivity.kt` inheriting from `FlutterFragmentActivity` (preventing `BiometricPrompt` runtime crashes) and declared `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>` in `AndroidManifest.xml`.
  - Configured iOS `Info.plist` with `<key>NSFaceIDUsageDescription</key>`.
  - `mobile/lib/core/security/app_lifecycle_observer.dart`: `WidgetsBindingObserver` tracking `paused`, `inactive`, and `resumed` states to auto-lock the session.
  - `mobile/lib/shared/widgets/privacy_veil_overlay.dart`: Application-level widget displaying a 25px Gaussian blur (`ImageFilter.blur(sigmaX: 25, sigmaY: 25)`) with `#0F172A` tint, medical shield icon, and "Desbloquear" biometric button.
  - `mobile/lib/main.dart`: Mounted `PrivacyVeilOverlay` in `MaterialApp.router`'s `builder`.
  - `mobile/test/core/security/secure_storage_service_test.dart`: 7 tests verifying encrypted token storage, retrieval, and logout deletion.
  - `mobile/test/core/security/privacy_veil_test.dart`: 4 widget tests verifying privacy veil trigger on backgrounding, persistent lock on failed authentication, and veil lifting on successful biometric unlock.
- **Verification:** 11/11 tests passed green; `flutter analyze` passed with 0 issues.
- **Commit:** `a368571: feat(02-02): implement native biometrics, secure storage, and privacy veil overlay`

---

## Key Architectural & Security Decisions

1. **Memory-Hard Password Protection (OWASP)**: Standardized on Argon2id with 64 MB memory cost, 3 iterations, and 4 threads, resisting GPU/ASIC rainbow table attacks.
2. **Transaction-Scoped Database Context**: User lookup during login executes with `set_config('app.is_auth_service', 'true', true)` where `is_local = true`, guaranteeing that connection pool recycling cannot leak elevated service permissions across tenant requests.
3. **Atomic LGPD Art. 11 Audit Trail**: When a user registers, the disclaimer version, accepted timestamp, user-agent, and SHA-256 hashed client IP address are recorded in `user_disclaimer_consents` in the same database transaction that creates the user.
4. **Android FragmentActivity Heritage**: Explicitly updated `MainActivity` to inherit from `FlutterFragmentActivity`, eliminating the fatal `IllegalStateException` that occurs when standard `FlutterActivity` invokes Android's `BiometricPrompt`.
5. **Double-Layered Task Switcher Privacy**: Combined `WidgetsBindingObserver` lifecycle listening with a 25px Gaussian blur overlay (`PrivacyVeilOverlay`) so recent apps snapshots in iOS and Android task switchers never capture plaintext health records.

---

## Verification Summary

| Suite | Scope | Result |
|-------|-------|--------|
| Backend Unit Tests | `backend/test/unit/` (`auth.service.spec.ts`, `database`, `encryption`) | 13/13 passed (100%) |
| Backend E2E Tests | `backend/test/e2e/` (`auth.e2e-spec.ts`, `legal-disclaimer.e2e-spec.ts`) | 10/10 passed (100%) |
| Mobile Analyzer | `mobile/lib/` & `mobile/test/` | 0 errors, 0 warnings, 0 lints |
| Mobile Widget Tests | `mobile/test/` (All 29 tests across onboarding, router, auth, security) | 29/29 passed (100%) |

---

## Conclusion
Phase 2 Plan 02 is complete. The application possesses a hardened backend authentication service with compliant LGPD consent audit trails, a responsive and accessible Screen 2 registration form with non-bypassable consent gating, and native hardware biometric security with background privacy blur protection.
