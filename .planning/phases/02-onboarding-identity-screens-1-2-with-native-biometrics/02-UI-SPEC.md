---
phase: "2"
slug: "onboarding-identity-screens-1-2-with-native-biometrics"
status: approved
shadcn_initialized: false
preset: not applicable
created: "2026-09-14"
---

# Phase 2 — UI Design Contract

> Visual and interaction contract for frontend phases. Generated for Phase 2: Onboarding & Identity (Screens 1 & 2) with Native Biometrics.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Material 3 (Flutter Native) |
| Preset | not applicable |
| Component library | Flutter Material 3 (`useMaterial3: true`) |
| Icon library | `package:flutter_svg` + Material Icons |
| Font | Plus Jakarta Sans (`package:google_fonts`) |

---

## Component Inventory

| Component | Import path | Notes |
|-----------|-------------|-------|
| `PageView.builder` | `package:flutter/material.dart` | Swiping 3-card value proposition carousel with `BouncingScrollPhysics` |
| `FilledButton` | `package:flutter/material.dart` | Material 3 primary CTA button ("Criar Conta", "Finalizar Cadastro") |
| `OutlinedButton` | `package:flutter/material.dart` | Secondary action button ("Entrar") |
| `TextFormField` | `package:flutter/material.dart` | Form input with floating label, border radius 12px, error text |
| `SegmentedButton<Gender>` | `package:flutter/material.dart` | Material 3 segmented control for Biological Sex (`Masculino`, `Feminino`, `Outro`) |
| `CheckboxListTile` | `package:flutter/material.dart` | Mandatory LGPD Art. 11 consent gating check with rich text link |
| `BackdropFilter` | `package:flutter/widgets.dart` | Gaussian blur (`ImageFilter.blur(sigmaX: 25, sigmaY: 25)`) for background privacy veil |
| `AnimatedContainer` | `package:flutter/material.dart` | Smooth expanding indicator pill (8px dot to 24px pill) for active carousel slide |

---

## Spacing Scale

Declared values (multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, badge padding, inline indicator dots spacing |
| sm | 8px | Form label gap, field icon padding, carousel indicator spacing |
| md | 16px | Default content padding, vertical gaps between form fields |
| lg | 24px | Section padding, modal header spacing, CTA button vertical margin |
| xl | 32px | Layout gaps between carousel card and action buttons |
| 2xl | 48px | Top splash header margin, top safe area buffer |
| 3xl | 64px | Maximum bottom sheet / page-level hero spacing |

Exceptions: none

---

## Typography

Font family: **Plus Jakarta Sans** (clean, contemporary clinical typography)

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Display | 32px | Bold 700 | 1.2 |
| Heading | 24px | SemiBold 600 | 1.3 |
| Label | 14px | Medium 500 | 1.4 |
| Body | 16px | Regular 400 | 1.5 |

---

## Color

DualisCheckUp implements a chromatic dual-axis design system:

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#F8FAFC` (Light) / `#0F172A` (Dark) | App background, scaffold body, full-screen canvas |
| Secondary (30%) | `#FFFFFF` (Light) / `#1E293B` (Dark) | Carousel cards, bottom sheets, form input containers, dialogs |
| Accent (10%) | `#3F51B5` (Soft Indigo) | Primary CTA buttons, active carousel indicators, focused form outlines |
| Secondary Accent | `#00796B` (Clinical Teal) | Medical icons, security shield accent, second vertical identity anchor |
| Destructive | `#D32F2F` (Crimson) | Form validation errors, emergency warning indicators |

Accent reserved for: Primary action buttons ("Criar Conta", "Finalizar Cadastro"), active carousel indicator pill, text field focus ring, and language toggle highlight.

---

## Copywriting Contract

| Element | Copy (pt-BR) | Copy (es) | Copy (en) |
|---------|--------------|-----------|-----------|
| Screen 1 Primary CTA | "Criar Conta" | "Crear Cuenta" | "Create Account" |
| Screen 1 Secondary CTA | "Entrar" | "Iniciar Sesión" | "Sign In" |
| Screen 2 Primary CTA | "Finalizar Cadastro" | "Finalizar Registro" | "Complete Registration" |
| Value Card 1 Title | "Triagem Preventiva Unificada" | "Triaje Preventivo Unificado" | "Unified Preventive Triage" |
| Value Card 1 Body | "Conecte sua saúde física e estado psico-emocional em um único fluxo diário inteligente, garantindo cuidado holístico e sem ruídos." | "Conecte su salud física y estado psico-emocional en un único flujo diario inteligente." | "Connect your physical health and emotional state in a single intelligent daily check-in." |
| Value Card 2 Title | "Registros Médicos Blindados" | "Historial Médico Blindado" | "Armored Medical Records" |
| Value Card 2 Body | "Seu histórico clínico protegido por criptografia AES-256 e custodiado sob os mais rigorosos padrões da LGPD. Você é o único dono dos seus dados." | "Su historial clínico protegido por cifrado AES-256 y custodiado bajo la LGPD." | "Your medical history protected by AES-256 encryption and strictly guarded under LGPD." |
| Value Card 3 Title | "Orientações Preventivas Precisas" | "Orientaciones Preventivas Precisas" | "Accurate Preventive Guidance" |
| Value Card 3 Body | "Recomendações e artigos de especialistas médicos renomados sem diagnósticos falsos ou alarmismos desnecessários." | "Recomendaciones y artículos de especialistas médicos de renombre sin diagnósticos falsos." | "Evidence-based recommendations and articles from renowned medical specialists." |
| LGPD Consent Checkbox | "Li e concordo com a Política de Privacidade e consinto expressamente com o tratamento de meus dados pessoais sensíveis de saúde para fins de triagem preventiva e acompanhamento longitudinal, nos termos do Art. 11 da LGPD." | "He leído y acepto la Política de Privacidad y consiento expresamente el tratamiento de mis datos personales sensibles de salud conforme al Art. 11 de la LGPD." | "I have read and agree to the Privacy Policy and explicitly consent to the processing of my sensitive personal health data pursuant to Art. 11 of the LGPD." |
| Privacy Veil Title | "Dados de Saúde Protegidos" | "Datos de Salud Protegidos" | "Protected Health Data" |
| Privacy Veil Body | "Autentique-se com biometria ou senha para acessar seu prontuário." | "Autentíquese con biometría o contraseña para acceder." | "Authenticate with biometrics or passcode to access your records." |
| Form Error - Name | "Por favor, informe seu nome completo (nome e sobrenome)." | "Por favor, ingrese su nombre completo." | "Please enter your full name (first and last)." |
| Form Error - Email | "Informe um endereço de e-mail válido." | "Ingrese un correo electrónico válido." | "Please enter a valid email address." |
| Form Error - Password | "A senha deve ter pelo menos 8 caracteres, incluindo letra maiúscula, minúscula, número e símbolo especial." | "La contraseña debe tener al menos 8 caracteres con mayúscula, minúscula, número y símbolo." | "Password must be at least 8 characters long with uppercase, lowercase, number and symbol." |

---

## UI Considerations

Applicable state considerations resolved: 4 covered, 2 backstop, 0 unresolved

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| Gating / Disabled State | Screen 2 Primary Button (`Finalizar Cadastro`) | ✅ covered | Submission button strictly disabled (`onPressed == null`) while LGPD consent checkbox is unchecked or required form fields are invalid. |
| Loading State | Screen 2 Submission | ✅ covered | Tapping "Finalizar Cadastro" transforms button into an indeterminate `CircularProgressIndicator` with 24px size, preventing duplicate taps. |
| Error State | Screen 2 Form Inputs | ✅ covered | Invalidation errors render inline below the offending field with red `#D32F2F` caption text upon focus blur. |
| Obscured / Privacy State | Full Mobile Application Canvas | ✅ covered | When app lifecycle transitions to `paused` or `inactive`, `PrivacyVeilOverlay` instantly injects a 25px Gaussian blur with `#0F172A` opacity and branded shield. |
| Dynamic Localization Toggle | Screen 1 App Bar Language Picker | 🧪 backstop | Tapping language chip updates `localeProvider` and triggers immediate 60fps string re-render across all carousel cards without app restart. |
| Biometric Fallback | Screen 2 Biometric Auto-Lock Modal | 🧪 backstop | If hardware biometric check fails twice, OS passcode/PIN fallback is seamlessly invoked via `stickyAuth: true`. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| Flutter Material 3 Native | Core Widgets | not required (Standard Flutter SDK) |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved 2026-09-14
