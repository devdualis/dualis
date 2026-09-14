# Phase 2 Context: Onboarding & Identity (Screens 1 & 2) with Native Biometrics

**Phase:** 2  
**Status:** In Planning  
**Requirements Covered:** ONBD-01, AUTH-01 (RF-007), AUTH-02, I18N-01  

## User Decisions & Directives

### 1. Screen 1: Onboarding & Auth Choice (ONBD-01)
- **Splash Screen / Intro**: Smooth branded splash animation introducing DualisCheckUp.
- **Value Proposition Carousel**: 3-card interactive carousel:
  1. *Dual Triage*: Triagem preventiva unificada conectando saúde psico-emocional e sintomas físicos.
  2. *Encrypted Records*: Registros médicos pessoais com criptografia forte (AES-256) e total soberania sob a LGPD.
  3. *Preventive Insights*: Recomendações e artigos de especialistas renomados sem ruídos ou falsos diagnósticos.
- **Actions**: Prominent Material 3 "Create Account" (Primary CTA) and "Sign In" (Secondary/Outlined CTA) routing into authentication flows.

### 2. Screen 2: Simplified Registration / Cadastro Simplificado (AUTH-01 / RF-007)
- **Required User Fields**:
  - **Full Name** (Nome Completo)
  - **Email** (E-mail para autenticação)
  - **Password** (Senha forte com hashing Argon2 no backend)
  - **Biological Sex / Gender** (Sexo Biológico: Masculino, Feminino, Outro — essencial para limites biológicos e acurácia clínica da triagem)
  - **Date of Birth** (Data de Nascimento — essencial para filtragem etária de anúncios locais AdMob e cálculo de faixas de risco)
- **LGPD Compliance**:
  - Mandatory explicit checkbox: *"Li e concordo com a Política de Privacidade e consinto com o tratamento de meus dados pessoais sensíveis de saúde para fins de triagem preventiva (LGPD Art. 11)"*.
  - Account creation button remains strictly disabled until the consent checkbox is checked.

### 3. Native Biometrics & App Security (AUTH-02)
- **Biometric Authentication**: Integration with `local_auth` (FaceID, TouchID, Android BiometricPrompt).
- **Auto-Lock on Background**: When the mobile app enters `AppLifecycleState.paused` or `inactive`, the sensitive health view is obscured with a privacy blur/overlay, and returning to the app prompts biometric or password unlock.
- **Secure Token Storage**: Persisting authentication session tokens (JWT access & refresh tokens) via `flutter_secure_storage` (Hardware-backed iOS Keychain / Android KeyStore/EncryptedSharedPreferences).

### 4. Multilingual Foundation (I18N-01)
- **Supported Locales**:
  - Brazilian Portuguese (`pt-BR`) — Default fallback
  - Spanish (`es`)
  - English (`en`)
- **Technology**: Flutter `intl` package with localized `.arb` resource files (`app_pt.arb`, `app_es.arb`, `app_en.arb`).
- **Language Switcher**: Fast runtime language toggle accessible from the onboarding / settings view.

### 5. Client Architecture
- **Framework**: Flutter 3.29+ / Dart 3.7+
- **State Management**: `flutter_riverpod` (3.4.3) + `riverpod_annotation`
- **Routing**: `go_router` (18.0.1) with declarative routes and auth redirection
- **Networking**: `dio` (5.11.1) with interceptors for JWT injection and base URL configuration pointing to NestJS backend (`/v1/auth/register`, `/v1/auth/login`, `/v1/legal/disclaimer`).
