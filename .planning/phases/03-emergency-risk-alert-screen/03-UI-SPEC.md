---
phase: "3"
slug: "emergency-risk-alert-screen"
status: approved
shadcn_initialized: false
preset: not applicable
created: "2026-09-14"
---

# Phase 3 — UI Design Contract: Emergency Risk Alert Screen (Screen 8 / RF-006)

> Visual, interactive, and clinical safety contract for Screen 8: Emergency Risk Alert Screen (RF-006).

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Material 3 (Flutter Native) |
| Preset | not applicable |
| Component library | Flutter Material 3 (`useMaterial3: true`) |
| Icon library | Material Icons (`Icons.emergency`, `Icons.warning_amber_rounded`, `Icons.phone`, `Icons.local_hospital`, `Icons.favorite`) |
| Font | Plus Jakarta Sans (`package:google_fonts`) |

---

## Component Inventory

| Component | Import path | Notes |
|-----------|-------------|-------|
| `PopScope` | `package:flutter/widgets.dart` | Root gesture guard (`canPop: false`) intercepting back swipes and hardware back buttons |
| `SingleChildScrollView` | `package:flutter/widgets.dart` | Scrollable viewport preventing `RenderFlex` overflow errors on small screens and high font scalings |
| `SafeArea` | `package:flutter/widgets.dart` | Ensures high-contrast emergency banner respects notches, status bars, and home indicators |
| `Card` / `Container` | `package:flutter/material.dart` | High-contrast instructions card (`#FFEBEE` surface) with 16px border radius |
| `FilledButton` | `package:flutter/material.dart` | Primary emergency CTA (SAMU 192 / CVV 188) with white background, red bold text, height 56px |
| `OutlinedButton` | `package:flutter/material.dart` | Secondary dialer actions (Bombeiros 193) with white border and text |
| `AlertDialog` | `package:flutter/material.dart` | Non-dismissible exit confirmation dialog and telephony fallback modal |
| `Chip` / `Container` | `package:flutter/material.dart` | High-visibility emergency category badge pill |

---

## Spacing Scale

Declared values (multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Badge internal padding, inline icon spacing |
| sm | 8px | Gap between instruction list items, button icon padding |
| md | 16px | Card content padding, vertical gaps between action buttons |
| lg | 24px | Outer screen padding, header-to-content spacing |
| xl | 32px | Spacing between instruction cards and dialer actions |
| 2xl | 48px | Top emergency icon margin, hero header clearance |
| 3xl | 64px | Bottom scroll clearance |

---

## Typography

Font family: **Plus Jakarta Sans**

| Role | Size | Weight | Color | Line Height |
|------|------|--------|-------|-------------|
| Emergency Title | 26px | Bold 800 | `#FFFFFF` | 1.2 |
| Emergency Subtitle | 16px | Medium 500 | `#FFFFFF` (90% opacity) | 1.4 |
| Category Badge | 13px | SemiBold 600 | `#B71C1C` | 1.2 |
| Card Heading | 16px | Bold 700 | `#5A0C0C` | 1.3 |
| Instruction Item | 14px | Regular 400 | `#5A0C0C` | 1.5 |
| Primary CTA Button | 18px | Bold 700 | `#D32F2F` | 1.2 |
| Secondary CTA Button | 16px | SemiBold 600 | `#FFFFFF` | 1.2 |
| Disclaimer Hint | 13px | Regular 400 | `#FFFFFF` (80% opacity) | 1.4 |
| Exit Text Button | 14px | Medium 500 | `#FFFFFF` (70% opacity) | 1.3 |

---

## Color Palette & Contrast Safety

| Role | Hex | Context | Contrast Ratio (WCAG) |
|------|-----|---------|-----------------------|
| Background Bleed | `#D32F2F` | Full-screen emergency canvas | N/A |
| Deep Accent | `#B71C1C` | Badge outline, shadow, dialog header | N/A |
| Card Surface | `#FFEBEE` | Instructions container background | N/A |
| Text on Red | `#FFFFFF` | Titles, subtitles, outlined buttons | **4.8:1** (Passes WCAG AA for large/bold text) |
| Text on Light Surface | `#5A0C0C` | Instructions body text on `#FFEBEE` | **7.8:1** (Passes WCAG AAA) |
| Primary Button Surface | `#FFFFFF` | High-visibility primary dialer background | N/A |
| Primary Button Text | `#D32F2F` | Primary dialer label | **4.8:1** (Passes WCAG AA) |

---

## Copywriting Contract (Trilingual: pt-BR, es, en)

### Headers & Badges
- **Title (`emergencyTitle`)**:
  - `pt-BR`: *Alerta de Risco Imediato*
  - `es`: *Alerta de Riesgo Inmediato*
  - `en`: *Immediate Risk Alert*
- **Subtitle (`emergencySubtitle`)**:
  - `pt-BR`: *Sintomas de gravidade identificados. Procure atendimento médico urgente.*
  - `es`: *Síntomas graves identificados. Busque atención médica urgente.*
  - `en`: *Severe symptoms identified. Seek immediate emergency medical care.*
- **Badge Chest Pain (`emergencyBadgeChestPain`)**:
  - `pt-BR`: *🚨 Dor Torácica Crítica*
  - `es`: *🚨 Dolor Torácico Crítico*
  - `en`: *🚨 Critical Chest Pain*
- **Badge Respiratory (`emergencyBadgeRespiratory`)**:
  - `pt-BR`: *🚨 Dificuldade Respiratória Aguda*
  - `es`: *🚨 Dificultad Respiratoria Aguda*
  - `en`: *🚨 Acute Respiratory Distress*
- **Badge Stroke (`emergencyBadgeStroke`)**:
  - `pt-BR`: *🚨 Suspeita de Déficit Neurológico (AVC)*
  - `es`: *🚨 Sospecha de Déficit Neurológico (ACV)*
  - `en`: *🚨 Suspected Neurological Deficit (Stroke)*
- **Badge Emotional Crisis (`emergencyBadgeEmotional`)**:
  - `pt-BR`: *🚨 Apoio Emocional Imediato / Risco à Vida*
  - `es`: *🚨 Apoyo Emocional Inmediato / Riesgo Vital*
  - `en`: *🚨 Immediate Crisis Support / Life Safety*

### Instructions Card
- **Physical Steps (`emergencyInstructionPhysical1..3`)**:
  1. `pt-BR`: *Interrompa qualquer esforço físico e permaneça em repouso.* | `es`: *Interrumpa cualquier esfuerzo físico y permanezca en reposo.* | `en`: *Stop any physical activity and rest immediately.*
  2. `pt-BR`: *Não dirija até o hospital. Acione o 192 ou peça ajuda a terceiros.* | `es`: *No conduzca al hospital. Llame al 192 o pida ayuda a un acompañante.* | `en`: *Do not drive to the hospital. Call emergency services or ask someone for help.*
  3. `pt-BR`: *Afrouxe roupas apertadas e tente manter a calma enquanto o socorro chega.* | `es`: *Afloje la ropa ajustada e intente mantener la calma mientras espera la ayuda.* | `en`: *Loosen tight clothing and try to stay calm while waiting for assistance.*
- **Emotional Steps (`emergencyInstructionEmotional1..3`)**:
  1. `pt-BR`: *Você não está sozinho(a). Ajuda qualificada e sigilosa está disponível agora.* | `es`: *No estás solo/a. Hay ayuda especializada y confidencial disponible ahora mismo.* | `en`: *You are not alone. Qualified, confidential help is available right now.*
  2. `pt-BR`: *O CVV oferece apoio emocional gratuito 24 horas por dia pelo telefone 188.* | `es`: *El CVV ofrece apoyo emocional gratuito las 24 horas a través del teléfono 188.* | `en`: *Free, confidential 24/7 crisis support is available. In Brazil, dial 188 (CVV).*
  3. `pt-BR`: *Se sentir que está em perigo imediato, acione o 192 ou procure a emergência.* | `es`: *Si siente que está en peligro inmediato, llame al 192 o acuda a una sala de emergencias.* | `en`: *If you feel in immediate danger, call emergency services (192) or go to the ER.*

### Actions & Telephony
- **SAMU 192 (`emergencyCallSamu`)**:
  - `pt-BR`: *Ligar SAMU (192)* | `es`: *Llamar SAMU (192)* | `en`: *Call SAMU (192)*
- **CVV 188 (`emergencyCallCvv`)**:
  - `pt-BR`: *Ligar CVV - Apoio Emocional (188)* | `es`: *Llamar CVV - Apoyo Emocional (188)* | `en`: *Call Crisis Line (188)*
- **Bombeiros 193 (`emergencyCallBombeiros`)**:
  - `pt-BR`: *Ligar Bombeiros (193)* | `es`: *Llamar Bomberos (193)* | `en`: *Call Fire / Rescue (193)*
- **Emergency Room Locator (`emergencyFindHospital`)**:
  - `pt-BR`: *Buscar Pronto-Socorro Mais Próximo* | `es`: *Buscar Sala de Urgencias Cercana* | `en`: *Find Nearest Emergency Room*
- **Dispatcher Advice (`emergencyDispatcherHint`)**:
  - `pt-BR`: *Ao ligar, informe seu endereço com clareza e mantenha a calma.* | `es`: *Al llamar, informe su dirección con claridad y mantenga la calma.* | `en`: *When calling, state your address clearly and stay calm.*

### Exit Confirmation Dialog
- **Title (`emergencyExitConfirmTitle`)**: *Atenção Médica Urgente*
- **Body (`emergencyExitConfirmBody`)**: *Seus sintomas indicam uma situação de risco à vida. Recomendamos fortemente que você contate um serviço médico antes de sair. Deseja realmente voltar ao início?*
- **Stay Button (`emergencyExitConfirmStay`)**: *Permanecer na Emergência* (Primary / Safe)
- **Leave Button (`emergencyExitConfirmLeave`)**: *Entendi os Riscos / Sair* (Secondary / Destructive)

---

## Interaction Invariants

1. **Uninterrupted Lock (`PopScope`)**:
   - `canPop` is unconditionally `false`.
   - Android back button or iOS pop swipe triggers `EmergencyExitConfirmationDialog`.
   - The user cannot tap outside the confirmation dialog (`barrierDismissible: false`).
2. **Telephony Fallback**:
   - If `canLaunchUrl('tel:...')` fails (e.g. Wi-Fi-only tablet), `TelephonyFallbackDialog` appears immediately displaying the number in 36pt font with a `[Copiar Número]` button.
3. **Session Purge**:
   - Triggering emergency immediately marks in-flight triage session state as cancelled/purged.
   - Leaving the emergency screen navigates back to `/home` with pristine state.
