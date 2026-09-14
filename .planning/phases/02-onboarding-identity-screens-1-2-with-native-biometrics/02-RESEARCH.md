# Phase 2 Research: Onboarding & Identity (Screens 1 & 2) with Native Biometrics

**Phase:** 2  
**Padded Phase:** 02  
**Phase Name:** Onboarding & Identity (Screens 1 & 2) with Native Biometrics  
**Requirements Covered:** ONBD-01, AUTH-01 (RF-007), AUTH-02, I18N-01  
**Target Milestone:** Vertical MVP — Module 1  
**Researched:** 2026-09-14  
**Confidence:** HIGH  

---

## Executive Summary

Phase 2 delivers **Module 1: Onboarding & Identity** for **DualisCheckUp**, encompassing **Screen 1 (Onboarding & Auth Choice - ONBD-01)** and **Screen 2 (Simplified Registration - AUTH-01 / RF-007)**, hardened with native hardware biometrics (FaceID/TouchID/Android BiometricPrompt - AUTH-02) and backed by a trilingual localization foundation (`pt-BR`, `es`, `en` - I18N-01).

This phase bridges the hardened PostgreSQL Row-Level Security (RLS) backend established in Phase 1 to a brand-new Flutter 3.29+ / Dart 3.7+ cross-platform mobile client residing in `mobile/`. It enforces a zero-trust mobile architecture:
1. Client-side authentication tokens are persisted exclusively within hardware-backed security modules (`flutter_secure_storage` using Android KeyStore / iOS Keychain).
2. Screen 1 provides a fluid, branded introduction with a 3-card value proposition carousel articulating DualisCheckUp's core pillars: **Dual Triage**, **Encrypted Records**, and **Evidence-Based Preventive Insights**.
3. Screen 2 strictly enforces simplified registration (Full Name, Date of Birth, Biological Sex, Email, Password) with explicit, non-bypassable LGPD Art. 11 health data consent gating prior to submission.
4. App lifecycle states are actively monitored via `WidgetsBindingObserver` to project a privacy veil over sensitive health data and enforce biometric re-authentication whenever the application enters or resumes from the background (`AUTH-02`).
5. The backend expands with a modular NestJS Authentication Module (`/v1/auth/register`, `/v1/auth/login`, `/v1/auth/me`), utilizing Argon2id hashing, short-lived JWT access tokens (15m), rotating refresh tokens (7d), and atomic RLS-isolated transaction logging of user disclaimer consents.

---

## 1. Flutter Client Architecture & Workspace Layout

### 1.1 Directory Organization

The Flutter client will be initialized in `dualis/mobile/` at the workspace root, keeping presentation and mobile state strictly segregated from the NestJS backend:

```
dualis/
├── backend/                       # NestJS Fastify Backend (from Phase 1)
└── mobile/                        # Flutter 3.29+ Cross-Platform Client
    ├── android/                   # Android wrapper (MainActivity extends FlutterFragmentActivity)
    ├── ios/                       # iOS wrapper (NSFaceIDUsageDescription configured)
    ├── assets/
    │   ├── icons/                 # SVG icons for value cards and auth branding
    │   └── branding/              # DualisCheckUp logos & shield vectors
    ├── lib/
    │   ├── core/                  # Core infrastructure & cross-cutting concerns
    │   │   ├── constants/
    │   │   │   ├── api_endpoints.dart    # Base URLs, /v1/auth/*, /v1/legal/*
    │   │   │   └── app_colors.dart       # Material 3 dual palette tokens
    │   │   ├── network/
    │   │   │   ├── api_client.dart       # Dio instance with timeouts & interceptors
    │   │   │   ├── auth_interceptor.dart # JWT Bearer injection & 401 token refresh
    │   │   │   └── network_error.dart    # Typed domain network exceptions
    │   │   ├── router/
    │   │   │   ├── app_router.dart       # GoRouter configuration with auth redirects
    │   │   │   └── route_paths.dart      # Static route name constants
    │   │   ├── security/
    │   │   │   ├── biometric_service.dart          # local_auth hardware wrapper
    │   │   │   ├── secure_storage_service.dart    # flutter_secure_storage wrapper
    │   │   │   └── app_lifecycle_observer.dart    # Privacy veil & auto-lock controller
    │   │   └── theme/
    │   │       ├── app_theme.dart                 # ThemeData with M3 ColorScheme
    │   │       └── dynamic_theme_provider.dart    # ThemeMode & vertical palette provider
    │   ├── features/              # Feature-first domain modules
    │   │   ├── onboarding/        # Screen 1: Splash & Value Carousel
    │   │   │   ├── domain/
    │   │   │   │   └── value_card_item.dart
    │   │   │   └── presentation/
    │   │   │       ├── controllers/onboarding_controller.dart
    │   │   │       ├── screens/onboarding_screen.dart
    │   │   │       └── widgets/
    │   │   │           ├── carousel_card.dart
    │   │   │           └── animated_page_indicator.dart
    │   │   └── auth/              # Screen 2: Simplified Registration & Login
    │   │       ├── data/
    │   │       │   ├── auth_remote_data_source.dart
    │   │       │   └── auth_repository_impl.dart
    │   │       ├── domain/
    │   │       │   ├── auth_repository.dart
    │   │       │   ├── auth_state.dart
    │   │       │   ├── user_profile.dart
    │   │       │   └── form_validators.dart
    │   │       └── presentation/
    │   │           ├── controllers/auth_controller.dart
    │   │           ├── screens/register_screen.dart
    │   │           ├── screens/login_screen.dart
    │   │           └── widgets/
    │   │               ├── lgpd_consent_checkbox.dart
    │   │               ├── biological_sex_selector.dart
    │   │               └── biometric_setup_dialog.dart
    │   ├── l10n/                  # Trilingual Internationalization (I18N-01)
    │   │   ├── app_pt.arb         # Brazilian Portuguese (Default fallback)
    │   │   ├── app_es.arb         # Spanish
    │   │   ├── app_en.arb         # English
    │   │   └── locale_provider.dart # Dynamic runtime language switching
    │   ├── shared/                # Cross-cutting reusable UI components
    │   │   └── widgets/
    │   │       ├── dualis_primary_button.dart
    │   │       ├── dualis_text_field.dart
    │   │       ├── privacy_veil_overlay.dart
    │   │       └── language_picker_button.dart
    │   └── main.dart              # Entry point with ProviderScope & lifecycle observer
    ├── l10n.yaml                  # Flutter localization generation config
    ├── pubspec.yaml               # Client dependencies
    └── test/                      # Unit, widget, and mock verification suites
```

### 1.2 Flutter Dependencies (`pubspec.yaml`)

```yaml
name: dualis_mobile
description: DualisCheckUp Mobile Preventive Health Platform
version: 1.0.0+1

environment:
  sdk: '>=3.7.0 <4.0.0'
  flutter: '>=3.29.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2
  
  # Reactive State Management
  flutter_riverpod: ^3.4.3
  riverpod_annotation: ^4.0.7
  
  # Navigation & Routing
  go_router: ^18.0.1
  
  # Networking & HTTP
  dio: ^5.11.1
  
  # Hardware Security & Biometrics
  local_auth: ^3.0.0
  flutter_secure_storage: ^11.1.1
  
  # UI, Typography & Visuals
  google_fonts: ^8.2.1
  flutter_svg: ^2.3.0
  
  # Immutability & Serialization
  freezed_annotation: ^4.0.1
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.15
  riverpod_generator: ^2.6.5
  freezed: ^4.0.1
  json_serializable: ^6.9.4
  mocktail: ^1.0.4
```

### 1.3 Material 3 Dual Palette Theme Tokens

DualisCheckUp employs a chromatic dual-axis design system mirroring its physical and psycho-emotional triage capabilities:
- **Soft Indigo (`#3F51B5`)**: The core brand color used for Onboarding, Identity, Trust, and the Psycho-Emotional triage vertical.
- **Clinical Teal (`#00796B`)**: The somatic anchor representing medical rigor, used for physical examinations and health records.
- **Emergency Crimson (`#D32F2F`)**: Reserved strictly for Level 4–5 emergency interventions.
- **Clinical Surface Colors**: Clean slate neutrals (`#F8FAFC` light background, `#0F172A` dark slate container) preventing visual fatigue.

```dart
// mobile/lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Brand Anchors
  static const Color softIndigo = Color(0xFF3F51B5);
  static const Color softIndigoDark = Color(0xFF303F9F);
  static const Color softIndigoLight = Color(0xFFC5CAE9);

  static const Color clinicalTeal = Color(0xFF00796B);
  static const Color clinicalTealDark = Color(0xFF004D40);
  static const Color clinicalTealLight = Color(0xFFB2DFDB);

  static const Color emergencyCrimson = Color(0xFFD32F2F);
  
  // Surfaces & Backgrounds
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color backgroundDark = Color(0xFF0F172A);

  // Text & Typography Neutrals
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  
  // Borders & Dividers
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color outlineDark = Color(0xFF334155);
}
```

---

## 2. Screen 1: Onboarding & Auth Choice (ONBD-01)

### 2.1 Screen Architecture & Flow

1. **Brand Intro / Splash Header**:
   - Subtle animated SVG shield logo transition with fade-in/scale curve (`Curves.easeOutCubic`, 600ms).
   - Dynamic Language Selector (`PT-BR | ES | EN`) in the top-right app bar for immediate accessibility before account creation.
2. **Value Proposition Carousel (3-Card Carousel)**:
   - Uses Flutter `PageView.builder` with physics `BouncingScrollPhysics`.
   - Card 1 — **Triagem Preventiva Unificada**:
     - *Title*: "Triagem Preventiva Unificada"
     - *Body*: "Conecte sua saúde física e estado psico-emocional em um único fluxo diário inteligente, garantindo cuidado holístico e sem ruídos."
     - *Visual Accent*: Dual-colored circular vector gradient (Clinical Teal + Soft Indigo).
   - Card 2 — **Registros Médicos Blindados (LGPD)**:
     - *Title*: "Registros Médicos Blindados"
     - *Body*: "Seu histórico clínico protegido por criptografia AES-256 e custodiado sob os mais rigorosos padrões da LGPD. Você é o único dono dos seus dados."
     - *Visual Accent*: Security Shield vector with cryptographic lock badge.
   - Card 3 — **Orientações Preventivas Precisas**:
     - *Title*: "Orientações Preventivas Precisas"
     - *Body*: "Recomendações e artigos de especialistas médicos renomados sem diagnósticos falsos ou alarmismos desnecessários."
     - *Visual Accent*: Medical stethoscope + verified pulse indicator.
3. **Animated Page Indicator**:
   - Animated container indicators tracking `pageController.page`.
   - Active dot expands from 8px width to a 24px rounded pill (`BorderRadius.circular(12)`) styled in `AppColors.softIndigo`.
4. **Primary and Secondary Action CTAs**:
   - **Primary Action ("Criar Conta" / "Create Account")**: Material 3 `FilledButton` spanning full width, routing to `/register` (Screen 2).
   - **Secondary Action ("Entrar" / "Sign In")**: Material 3 `OutlinedButton` spanning full width, routing to `/login`.

---

## 3. Screen 2: Simplified Registration (AUTH-01 / RF-007)

### 3.1 Clinical & Regulatory Input Fields

Screen 2 implements the exact mandatory fields defined in SRS RF-007:

| Field | Clinical / System Purpose | UI Input Pattern | Validation Invariant |
|-------|---------------------------|------------------|----------------------|
| **Nome Completo** (Full Name) | Personalization of disclaimers & formal medical audit trail under LGPD Art. 11. | Text Field with `TextInputType.name` and title capitalization. | Minimum 3 characters, requires at least two distinct words (first and last name). |
| **Data de Nascimento** (Date of Birth) | Calculation of age brackets for clinical risk stratification and privacy-preserving AdMob local ad targeting (RF-009). | Formatted date input (`DD/MM/YYYY`) with calendar picker modal. | Must represent a valid date in the past; user age must be between 13 and 120 years. |
| **Sexo Biológico** (Biological Sex) | Essential biological baseline to eliminate anatomical hallucinations in symptom classification and Antiburla verification (RF-003). | Material 3 `SegmentedButton<Gender>` (`Masculino`, `Feminino`, `Outro`). | Selection must be non-null and belong to `['masculino', 'feminino', 'outro']`. |
| **E-mail** | Unique account credential and communication channel for security notices. | Text Field with `TextInputType.emailAddress`, lowercase trimming. | Strict RFC 5322 regex validation (`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`). |
| **Senha** (Password) | Authentication secret hashed with Argon2id on the backend. | Obscured text field with toggleable eye icon. | Minimum 8 characters, at least 1 uppercase letter, 1 lowercase letter, 1 number, and 1 special symbol. |
| **Consentimento LGPD Art. 11** | Mandatory legal basis for processing sensitive health data under Brazilian law (Lei nº 13.709/2018). | Interactive Checkbox paired with rich text linking to the Privacy Policy. | **Boolean invariant: Must be checked (`true`). The submission button is strictly disabled while unchecked.** |

### 3.2 Gating & LGPD Consent Text Specifications

The consent text must explicitly reference Article 11 of the LGPD:

- **Brazilian Portuguese (`pt-BR`)**:
  > *"Li e concordo com a Política de Privacidade e consinto expressamente com o tratamento de meus dados pessoais sensíveis de saúde para fins de triagem preventiva e acompanhamento longitudinal, nos termos do Art. 11 da LGPD."*
- **Spanish (`es`)**:
  > *"He leído y acepto la Política de Privacidad y consiento expresamente el tratamiento de mis datos personales sensibles de salud para fines de triaje preventivo y seguimiento longitudinal, conforme al Art. 11 de la LGPD."*
- **English (`en`)**:
  > *"I have read and agree to the Privacy Policy and explicitly consent to the processing of my sensitive personal health data for preventive triage and longitudinal tracking purposes, pursuant to Art. 11 of the LGPD."*

Tapping "Política de Privacidade" launches a modal bottom sheet displaying the active medical disclaimer returned by `GET /v1/legal/disclaimer` (Anvisa RDC 657/2022 and CFM Res. 2.314/2022 citations).

---

## 4. Native Biometrics & Session Security (AUTH-02)

### 4.1 Hardware Integration via `local_auth`

```dart
// mobile/lib/core/security/biometric_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  Future<bool> isHardwareSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return const [];
    }
  }

  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,      // Preserves auth flow if app enters background momentarily
          biometricOnly: false,  // Allows OS passcode/PIN fallback if biometrics fail
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
```

### 4.2 Platform Configuration Requirements

#### Android (`android/app/src/main/`)
1. **Manifest Permissions** (`AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
   ```
2. **Activity Heritage** (`MainActivity.kt`):
   **CRITICAL PITFALL**: The Android `BiometricPrompt` API strictly requires a `FragmentActivity`. If `MainActivity` extends the default `FlutterActivity`, invoking `authenticate()` will crash at runtime with `IllegalStateException: ... requires a FragmentActivity`.
   ```kotlin
   package com.dualischeckup.app

   import io.flutter.embedding.android.FlutterFragmentActivity

   class MainActivity: FlutterFragmentActivity()
   ```

#### iOS (`ios/Runner/Info.plist`)
Must declare the usage description explaining why biometric sensors are accessed:
```xml
<key>NSFaceIDUsageDescription</key>
<string>O DualisCheckUp utiliza biometria para proteger o acesso aos seus dados médicos confidenciais e registros de triagem.</string>
```

### 4.3 App Lifecycle & Privacy Veil Architecture

DualisCheckUp implements a double-layered defense against task switcher leaks:
1. **Immediate Visual Veil (`PrivacyVeilOverlay`)**: An application-level widget listening to `WidgetsBindingObserver`. Upon receiving `AppLifecycleState.paused` or `AppLifecycleState.inactive`, it immediately injects an opaque Gaussian blur backdrop (`ImageFilter.blur(sigmaX: 25, sigmaY: 25)`) with a dark slate overlay and branded shield logo, completely occluding all health data.
2. **Session Auto-Lock Invariant**:
   - When entering the background, an in-memory timestamp is saved: `lastPausedTimestamp = DateTime.now()`.
   - On `AppLifecycleState.resumed`, if biometric protection is enabled, the application state is locked.
   - The user must successfully complete biometric verification or enter their device PIN before the privacy veil is lifted.

### 4.4 Hardware-Backed Token Storage (`flutter_secure_storage`)

Authentication credentials and session tokens must never be persisted in plaintext `SharedPreferences` or iOS `UserDefaults`:

```dart
// mobile/lib/core/security/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _keyAccessToken = 'dualis_access_token';
  static const _keyRefreshToken = 'dualis_refresh_token';
  static const _keyBiometricEnabled = 'dualis_biometric_enabled';
  static const _keyUserId = 'dualis_user_id';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyUserId, value: userId),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled ? 'true' : 'false');
  }

  Future<void> clearAll() => _storage.deleteAll();
}
```

---

## 5. Backend Authentication Module Architecture (NestJS)

### 5.1 Module Structure

The NestJS backend established in Phase 1 will be extended with a dedicated `AuthModule` located at `backend/src/modules/auth/`:

- `auth.controller.ts`: Handles `POST /v1/auth/register`, `POST /v1/auth/login`, `POST /v1/auth/refresh`, `GET /v1/auth/me`.
- `auth.service.ts`: Argon2id hashing, user creation, transaction-scoped disclaimer consent logging, JWT token signing.
- `dto/register.dto.ts`: Class-validator rules for Screen 2 inputs.
- `guards/jwt-auth.guard.ts` & `strategies/jwt.strategy.ts`: Passport Bearer JWT token authentication.

### 5.2 Password Hashing with Argon2id

In adherence to OWASP recommendations, password hashing uses **Argon2id** (via `argon2: ^0.41.1`), providing memory-hard protection against GPU and ASIC cracking attempts.

```typescript
import * as argon2 from 'argon2';

export async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 65536, // 64 MB
    timeCost: 3,       // 3 iterations
    parallelism: 4,
  });
}

export async function verifyPassword(hash: string, plain: string): Promise<boolean> {
  return argon2.verify(hash, plain);
}
```

### 5.3 PostgreSQL RLS Handling During Registration & Login

#### Registration Invariant (New User Creation)
```typescript
const newUserId = crypto.randomUUID();
const passwordHash = await hashPassword(dto.password);
const ipHash = crypto.createHash('sha256').update(clientIp).digest('hex');

await this.db.transaction(async (tx) => {
  // 1. Set the RLS session context to the newly created UUID
  await tx.execute(
    sql`SELECT set_config('app.current_user_id', ${newUserId}, true)`,
  );

  // 2. Insert into users satisfies WITH CHECK (id = current_setting('app.current_user_id'))
  await tx.insert(users).values({
    id: newUserId,
    name: dto.name,
    email: dto.email.toLowerCase().trim(),
    passwordHash,
    gender: dto.gender,
    dateOfBirth: dto.dateOfBirth,
  });

  // 3. Insert into user_disclaimer_consents satisfies WITH CHECK (user_id = current_setting('app.current_user_id'))
  await tx.insert(userDisclaimerConsents).values({
    userId: newUserId,
    disclaimerVersion: dto.disclaimerVersion || '2026.1',
    ipAddressHash: ipHash,
    userAgent: userAgent || 'Unknown',
  });
});
```

#### Login Invariant (Finding User by Email)
```sql
-- Migration: 0002_auth_lookup_policy.sql
DROP POLICY IF EXISTS users_patient_isolation ON users;

CREATE POLICY users_patient_isolation ON users
  FOR ALL
  USING (
    id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR current_setting('app.is_auth_service', true) = 'true'
  )
  WITH CHECK (
    id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );
```
During `AuthService.validateUser(email, password)`:
```typescript
const user = await this.db.transaction(async (tx) => {
  await tx.execute(sql`SELECT set_config('app.is_auth_service', 'true', true)`);
  const [record] = await tx
    .select()
    .from(users)
    .where(eq(users.email, email.toLowerCase().trim()))
    .limit(1);
  return record;
});
```
This guarantees zero-trust tenant isolation: no standard user query can ever read another user's profile, and the auth service flag is transaction-isolated (`is_local = true`), preventing connection pool leakage.

### 5.4 LGPD Disclaimer Consent Audit Trail

When Screen 2 registers a user, the backend atomically logs the consent event in `user_disclaimer_consents`:
- `userId`: UUID referencing `users.id`.
- `disclaimerVersion`: The active regulatory version (e.g., `'2026.1'`).
- `acceptedAt`: Timestamp with timezone (`now()`).
- `ipAddressHash`: SHA-256 hash of the client IP address (obfuscating PII while retaining non-repudiation auditability).
- `userAgent`: Client platform identifier (e.g., `DualisCheckUp-Flutter-Android/1.0.0`).

---

## 6. Trilingual Internationalization Foundation (I18N-01)

### 6.1 Flutter `intl` Architecture

DualisCheckUp natively supports Brazilian Portuguese (`pt-BR`, default fallback), Spanish (`es`), and English (`en`) from the very first screen.

Configuration in `mobile/l10n.yaml`:
```yaml
arb-dir: lib/l10n
template-arb-file: app_pt.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

### 6.2 Key-Value Summary Across `.arb` Bundles

- **Brazilian Portuguese (`app_pt.arb`)**: Default locale, clinically calibrated for Brazilian users (*"Triagem Preventiva Unificada"*, *"Registros Médicos Blindados"*, *"Orientações Preventivas Precisas"*, explicit LGPD Art. 11 text).
- **Spanish (`app_es.arb`)**: Natural Latin American Spanish translations (*"Triaje Preventivo Unificado"*, *"Historial Médico Blindado"*, *"Orientaciones Preventivas Precisas"*).
- **English (`app_en.arb`)**: Clean, accessible clinical English (*"Unified Preventive Triage"*, *"Armored Medical Records"*, *"Accurate Preventive Guidance"*).
- Dynamic runtime language switching via Riverpod `localeProvider` backed by `SharedPreferences`.

---

## 7. Common Pitfalls & Prevention Strategies (Phase 2 Specific)

| Pitfall | Root Cause | Impact | Architectural Prevention Strategy |
|---------|------------|--------|-----------------------------------|
| **Android Biometric Crash (`IllegalStateException`)** | `MainActivity` inherits from `FlutterActivity` instead of `FlutterFragmentActivity`. | App crashes instantly when triggering Face/Fingerprint prompt on Android 10+. | Explicitly declare `MainActivity : FlutterFragmentActivity()` in Kotlin source and verify in CI. |
| **Health Data Leaks in App Switcher Bitmaps** | Mobile OS captures un-obscured snapshot of the last active view when backgrounded. | Sensitive medical notes visible to anyone viewing the recent apps carousel. | Implement `WidgetsBindingObserver` + Gaussian blur `PrivacyVeilOverlay` triggered on `AppLifecycleState.paused`/`inactive`. |
| **Bypassing LGPD Art. 11 Consent** | Client-only checkbox check or optional API payload. | Severe Brazilian ANPD regulatory sanctions (up to R$ 50M fine) and non-compliance. | Dual-layer invariant: Client button remains disabled; NestJS `RegisterDto` strictly enforces `@Equals(true)` and rejects unconsented requests with HTTP 400. |
| **Cross-Tenant Bleed in Recycled DB Pool** | Connection acquired from `pg.Pool` without setting or clearing `app.current_user_id`. | Potential data leakage or policy confusion across concurrent requests. | All transactional modifications use `is_local = true` (`set_config(..., true)`), automatically resetting context upon commit or rollback. |
| **Plaintext Token Storage** | Storing JWTs or refresh tokens in `SharedPreferences` or unencrypted SQLite. | Vulnerable to extraction on rooted/jailbroken devices. | Enforce `flutter_secure_storage` utilizing Android KeyStore and iOS Keychain. |

---

## 8. Validation Architecture

### 8.1 Backend Verification Suite (Vitest)

#### Commands
```bash
# In backend/ directory:
npm run test:unit       # Runs auth.service.spec.ts
npm run test:e2e        # Runs auth.e2e-spec.ts against live Fastify HTTP app
npm run test:rls        # Confirms RLS isolation across tenant boundaries
```

#### Key Test Scenarios & Fixtures

1. **`auth.service.spec.ts` (Unit Tests)**:
   - *Scenario 1: Happy Path Registration*: Provides valid `RegisterDto` with `lgpdConsent: true`. Verifies password is hashed with Argon2id, user is created, consent is logged in `userDisclaimerConsents` with SHA-256 hashed IP, and token pair is returned.
   - *Scenario 2: Consent Rejection*: Submits `lgpdConsent: false`. Asserts `BadRequestException` is thrown before calling database.
   - *Scenario 3: Duplicate Email*: Attempts registration with an already existing email. Asserts `ConflictException('E-mail já cadastrado.')` is thrown.
   - *Scenario 4: Login Verification*: Successfully verifies valid credentials with `argon2.verify`, generates JWT with 15m expiration. Rejects incorrect password with `UnauthorizedException`.

2. **`auth.e2e-spec.ts` (Fastify End-to-End Tests)**:
   - *Test 1: `POST /v1/auth/register`*: Returns 201 Created with `{ accessToken, refreshToken, user }`.
   - *Test 2: `POST /v1/auth/register` with `lgpdConsent: false`*: Returns 400 Bad Request.
   - *Test 3: `POST /v1/auth/login`*: Returns 200 OK with valid tokens.
   - *Test 4: `GET /v1/auth/me` with Bearer JWT*: Returns 200 OK with authenticated user profile.

### 8.2 Flutter Mobile Verification Suite

#### Commands
```bash
# In mobile/ directory:
flutter test test/features/auth/
flutter test test/features/onboarding/
flutter test test/core/security/
```

#### Key Test Scenarios & Widget Tests

1. **`test/features/onboarding/onboarding_screen_test.dart`**:
   - Renders Screen 1 with 3 value cards.
   - Verifies swiping `PageView` updates animated indicator pill.
   - Asserts tapping "Criar Conta" navigates to `/register`.
   - Asserts tapping "Entrar" navigates to `/login`.
   - Verifies language switcher updates UI strings dynamically.

2. **`test/features/auth/register_screen_test.dart`**:
   - *Gating Test*: When form is completely filled but `lgpdConsentCheckbox` is unchecked, the "Finalizar Cadastro" button widget has `onPressed == null` (strictly disabled).
   - Checking the checkbox immediately enables the button.
   - Unchecking immediately disables the button.
   - Entering invalid email (e.g. `carlos@`) displays localized error message on blur.
   - Entering weak password displays complexity hint.

3. **`test/core/security/privacy_veil_test.dart`**:
   - Simulates `AppLifecycleState.paused`.
   - Asserts `PrivacyVeilOverlay` renders with `BackdropFilter` and visibility `true`.
   - Simulates `AppLifecycleState.resumed` with mocked `BiometricService` returning `false`.
   - Asserts screen remains locked and obscured.
   - Simulates successful biometric authentication: asserts veil lifts and child content is visible.

4. **`test/core/security/secure_storage_service_test.dart`**:
   - Mocks `FlutterSecureStorage` calls.
   - Asserts access and refresh tokens are written with encrypted options enabled.
   - Asserts session wipe on logout.

---

## 9. Recommended Plan Breakdown for Phase 2

- **Plan 02-01: Client Foundation, Screen 1 Onboarding & Internationalization**:
  - Initialize Flutter 3.29+ client in `mobile/` with Material 3 theming (Clinical Teal + Soft Indigo).
  - Setup trilingual `intl` bundles (`app_pt.arb`, `app_es.arb`, `app_en.arb`) and runtime `localeProvider`.
  - Implement Screen 1: Splash animation, 3-card value carousel, animated indicators, and navigation routes.
  - Setup Dio network client with base configuration.
- **Plan 02-02: Screen 2 Simplified Registration, Native Biometrics & Backend Auth Module**:
  - Implement NestJS `AuthModule` (`POST /v1/auth/register`, `/login`, `/me`) with Argon2id, JWT, and LGPD consent logging.
  - Implement Screen 2: Form validation, biological sex selector, formatted date picker, and mandatory LGPD Art. 11 consent gating.
  - Implement native biometrics (`local_auth`), `FlutterFragmentActivity` configuration, hardware secure storage (`flutter_secure_storage`), and the background privacy blur veil (`WidgetsBindingObserver`).
  - Run end-to-end integration tests confirming zero-leakage session persistence and complete requirement coverage.
