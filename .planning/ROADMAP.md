# Roadmap: DualisCheckUp

## Overview

DualisCheckUp delivers an offline-capable, cross-platform mobile health & wellness platform that bridges self-reported physical comfort (across 12 body areas) and psycho-emotional well-being (across 7 dimensions) into a unified, safe, and intuitive personal journal experience. Aligned strictly with the SRS v1.0 Free Tier specifications (IDs 01–08 and RF-001–RF-009) and the Health & Wellness Repositioning Plan, the journey begins by establishing a bulletproof LGPD backend security foundation (Phase 1, complete), proceeds through Module 1 (Onboarding & Identity with Simplified Registration), deploys Always-On Safety Resources (Screen 8), and constructs the Free Tier Wellness Journal Engine (Screens 3, 4, 5, 6, and 7) with dynamic theming, 14-day recurrence verification, offline sync, 2D anatomical body mapping, and full LGPD data sovereignty. All Premium Tier features (IDs 09–12 / RF-010–RF-013 / UC-02) are deferred to v2.

## Phases

- [x] **Phase 1: Backend Foundation, PostgreSQL RLS & Data Encryption** - Multi-tenant PostgreSQL RLS, AES-256 encryption at rest, TLS 1.3, São Paulo hosting, and wellness disclaimers.
- [x] **Phase 2: Onboarding & Identity (Screens 1 & 2) with Native Biometrics** - Splash animation, 3-card value carousel, simplified registration (RF-007) with LGPD consent, and biometric app lock.
- [ ] **Phase 3: Always-On Safety Resources Screen (Screen 8 / RF-006)** - Universal, always-on help resources: global "Ajuda urgente" button in ≤1 tap, static emergency numbers (SAMU 192, CVV 188), static official warning signs list, and non-blocking safety prompts.
- [ ] **Phase 4: Dynamic 5-Step Wellness Journal Wizard (Screen 4 / RF-002)** - Standardized 5-step journal tree with lay-friendly questions, step 5 "Revisar e salvar seu registro", and dynamic color transitions (Teal ↔ Soft Indigo).
- [ ] **Phase 5: Home & Unified Dual-Axis Check-in (Screen 3 / RF-001) & AdMob Container (RF-009)** - "Como você está se sentindo hoje?" dual-axis check-in (`[Bem/Normal]`, `[Mais ou menos]`, `[Mal/Ruim]`), sub-2s AI entry tagging, and privacy AdMob container.
- [ ] **Phase 6: Check-in Summary, Body Area Mapping & Wellness Readings (Screen 6 / RF-004 & RF-005)** - Body area and mood tags across 7 dimensions and 12 areas, dual-axis reflection note, self-reported intensity ("Intensidade que você informou"), static guidance block, and curated educational wellness articles with verified official sources.
- [ ] **Phase 7: Recurrence Consistency Verification Sheet (Screen 5 / RF-003 & UC-01)** - 14-day temporal consistency scan on "Começou hoje" entries with empathetic reconciliation bottom sheet ("Isso já apareceu antes?") and boundary guardrails.
- [ ] **Phase 8: Offline Caching & Outbox Synchronization** - Encrypted local Drift SQLite storage and background transactional outbox synchronization.
- [ ] **Phase 9: Historical Dashboard & 2D Body Map (Screen 7 / RF-008 & Section 5.1)** - Segmented tab bar, interactive 2D Anatomical Body Map reflecting self-reported intensities, 7-day emotional multi-line trend graph, Cards de Padrões nos Registros, and Lista Retrospectiva.
- [ ] **Phase 10: LGPD Data Sovereignty, Account Deletion & Production Verification** - Self-service data export, cascading permanent account deletion, and end-to-end SLA/security verification.
- [ ] **Phase 11: Multi-Profile Legal Guardianship & Consensual Sharing (PERM-01, PERM-02)** - Multi-profile legal guardianship (minors, dependent adults under LGPD Art. 14) and optional consensual sharing (couples, siblings, caregivers) with granular RLS.
- [ ] **Phase 12: Preventive Immunization Tracker & Drug Allergy Registry (VACC-01, ALRG-01)** - Digital vaccination booklet (mandatory PNI and elective vaccines) and personal drug allergy registry displayed in profile/export.
- [ ] **Phase 13: Personal Conditions Registry & Continuous Treatment Reminders (RF-010, RF-011, CLIN-01)** - Personal conditions registry informed by user, personal medication dose reminders with stock tracking, and one-click summary of self-reported logs in PDF.
- [ ] **Phase 14: Document Processing Engine for Transcription & Leaflets (RF-012, RX-01, BULA-01)** - Asynchronous OCR pipeline for user-confirmed lab exam transcription, prescription pre-fill for editable forms, and direct link to official ANVISA Bulário Eletrônico.
- [ ] **Phase 15: Voice Interaction, Advanced Biometrics & Multi-Tier Subscription Monetization (VOICE-01, AUTH-03, PRIC-01, RF-013)** - Post-login hands-free voice journal entries, configurable step-up biometrics, and subscription billing for Free, Premium, Advanced, and Pacote Família (safety resources always free).

## Phase Details

### Phase 1: Backend Foundation, PostgreSQL RLS & Data Encryption

**Goal**: Establish the secure backend foundation with PostgreSQL Row-Level Security (using Supabase free tier for development, Google Cloud SQL São Paulo for production), AES-256 encryption at rest, TLS 1.3 in transit, and tenant isolation under LGPD.  
**Mode:** mvp  
**UI hint**: no  
**Depends on**: Nothing (first phase)  
**Requirements**: [SEC-01, SEC-02, DISC-01]  
**Success Criteria** (what must be TRUE):

  1. Backend executes all transactions inside a PostgreSQL session bounded by `SET LOCAL app.current_user_id = :userId`, completely blocking unauthorized multi-tenant access.
  2. Sensitive personal narratives, notes, and journal data are encrypted with AES-256 at rest and transmitted exclusively via TLS 1.3.
  3. Database and API services run strictly in the São Paulo region (`sa-east-1` for Google Cloud SQL in production / local/dev Supabase instance) to comply with LGPD Art. 11 data residency mandates.
  4. Platform provides non-diagnostic wellness disclaimer contracts localized in Brazilian Portuguese (`pt-BR`), Spanish (`es`), and English (`en`), stating intended as a wellness app with regulatory confirmation pending.

**Plans**: 2 plans

Plans:
**Wave 1**

- [x] 01-01: NestJS 12 Fastify initialization, Drizzle ORM schema, and PostgreSQL RLS tenant isolation middleware (configured for Supabase dev connection and Google Cloud SQL prod compatibility)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02: AES-256 field-level encryption, TLS 1.3 configuration, trilingual wellness disclaimer API (pt-BR, es, en), and automated cross-tenant security regression suite

---

### Phase 2: Onboarding & Identity (Screens 1 & 2) with Native Biometrics

**Goal**: Deliver Module 1: Screen 1 (Onboarding & Auth Choice) and Screen 2 (Simplified Registration RF-007 / SRS ID 01) with native biometric auto-lock and trilingual UI foundation.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 1  
**Requirements**: [ONBD-01, AUTH-01, AUTH-02, I18N-01]  
**Success Criteria** (what must be TRUE):

  1. User sees a smooth splash animation and can swipe through a 3-card value proposition carousel (Diário de Bem-Estar Integrado, Seus Dados Protegidos, Conteúdos para Hábitos Saudáveis) on Screen 1 with "Sign In" and "Create Account" CTAs.
  2. User can complete simplified registration on Screen 2 with mandatory fields: Full Name, Date of Birth, Biological Sex (Gender), Email, and Password.
  3. Registration strictly requires an explicit LGPD Art. 11, I health data privacy consent checkbox before enabling account creation.
  4. Application supports native biometric authentication (FaceID/TouchID/BiometricPrompt) with automatic screen obscuring and app locking upon backgrounding.
  5. Application establishes trilingual Flutter localization (`intl` with `app_pt.arb`, `app_es.arb`, and `app_en.arb`) with dynamic language switching and `pt-BR` default fallback.

**Plans**: 2 plans

Plans:

- [x] 02-01: Flutter 3.29 baseline setup, Riverpod 3.4.3, Screen 1 onboarding carousel and navigation routing
- [x] 02-02: Screen 2 simplified registration form (RF-007) with LGPD consent, native biometrics (`local_auth`), and secure storage

---

### Phase 3: Always-On Safety Resources Screen (Screen 8 / RF-006)

**Goal**: Implement universal, always-on emergency help resources: global "Ajuda urgente" button reachable in ≤1 tap from all main screens and login, plus non-blocking generic safety card with country-specific emergency dispatch (SAMU 192, CVV 188, Bombeiros 193, Polícia 190) and static warning signs cited from official public health sources.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 2  
**Requirements**: [EMRG-01, EMRG-02, EMRG-03]  
**Success Criteria** (what must be TRUE):

  1. Global "Ajuda urgente" action is always visible and accessible in ≤1 tap from the AppBar of every authenticated screen and the login screen, without requiring algorithmic triggers.
  2. If the user self-reports maximum intensity (5/5) or enters alarming keywords, the app displays a non-blocking, generic safety card ("Se isso for uma emergência, não use o app: ligue 192 agora.") with direct button to emergency resources.
  3. Screen 8 displays verified country-specific emergency contacts (Brazil: SAMU 192, CVV 188, Bombeiros 193, Polícia 190; international fallbacks), static warning signs cited from official public health agencies (Ministério da Saúde / SAMU), works offline, and is fully dismissable without blocking dialogues.
  4. Safety event logging records minimal data (`opened_resources` / `call_started`) without clinical severity level or categorization.

**Plans**: 2 plans

Plans:

- [x] 03-01: Universal safety resource state machine, non-blocking contextual safety rules, and regional emergency services configuration
- [x] 03-02: Screen 8 universal emergency resources modal, static warning signs list, and 1-tap telephony dispatch (`url_launcher`)

---

### Phase 4: Dynamic 5-Step Wellness Journal Wizard (Screen 4 / RF-002 / SRS ID 02 & 03)

**Goal**: Build Screen 4: Dynamic 5-Step Wellness Journal Wizard with active vertical visual indicator (Soft Indigo vs. Teal), lay-friendly questions, and Step 5 "Revisar e salvar seu registro".  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 3  
**Requirements**: [TRG-03, TRG-04, TRG-05]  
**Success Criteria** (what must be TRUE):

  1. Screen 4 header displays mandatory visual state transition banners informatively:
     - Vertical A: *"Registro emocional de hoje"* with Soft Indigo (`#3F51B5`).
     - Vertical B: *"Registro físico de hoje"* with Teal (`#00796B`).
  2. User progresses through the standardized 5-step wizard (max 5 questions per vertical):
     - **Vertical A (Psico-Emocional)**:
       1. Natureza: *"Olhando para o seu lado emocional e mental, qual palavra descreve melhor o que você está sentindo agora?"* (Pra baixo, Estressado(a)/Esgotado(a), Tensão no corpo, Sono ruim ou sono demais, Inquieto(a)/Agitado(a)).
       2. Tempo/Persistência: *"Você tem se sentido assim frequentemente nos últimos dias ou é algo muito específico de hoje?"* (Começou hoje / Já faz alguns dias / É algo constante há semanas).
       3. Intensidade Informada: *"Essa sensação está parecendo um leve incômodo de fundo ou algo forte que está acelerando seus pensamentos?"* (Leve e controlável / Moderada / Muito forte).
       4. Causas/Gatilhos: *"Você consegue identificar se existe um motivo principal para isso estar acontecendo hoje?"* (Trabalho/Estudos, Família/Relacionamentos, Noite ruim de sono, Não sei dizer).
       5. Revisar e Salvar: Revisão do registro pessoal e apresentação de leituras sobre bem-estar.
     - **Vertical B (Física)**:
       1. Localização: *"Vamos falar sobre a parte física. Onde você está sentindo esse desconforto principal?"* (Cabeça e pescoço, Peito, Respiração, Barriga, Costas, Braços, Pernas, Pele, Região íntima/urinária, Corpo todo/cansaço, Tontura/formigamento, Sede/fome/energia).
       2. Tempo/Persistência: *"Há quanto tempo esse desconforto persiste?"* (Começou agora / Há alguns dias / É algo frequente).
       3. Intensidade Informada: *"Em uma escala de 1 a 5 (onde 1 é quase imperceptível e 5 é muito intenso), como está agora?"* (Seletor numérico de 1 a 5).
       4. Causas/Gatilhos: *"Você lembra de ter feito algum esforço atípico, exercício pesado ou sofrido alguma batida/queda recentemente?"* (Sim exercício intenso / Sim sofri queda / Não começou do nada).
       5. Revisar e Salvar: Revisão do registro pessoal e apresentação de leituras sobre postura e alongamento.
  3. Journal state machine automatically purges sensitive in-memory session data upon exit or completion via Riverpod `autoDispose`.

**Plans**: 2 plans

Plans:

- [x] 04-01: Domain models for 5-step journal decision tree across both verticals and dynamic theme transition engine (Teal ↔ Soft Indigo)
- [x] 04-02: Screen 4 sequential 5-step journal wizard UI and Riverpod `autoDispose` state machine

---

### Phase 5: Home & Unified Dual-Axis Check-in (Screen 3 / RF-001) & AdMob Container (RF-009)

**Goal**: Implement Screen 3: Home & Unified Dual-Axis Check-in ("Como você está se sentindo hoje?" across Psico-Emocional and Registro Físico axes) with 3-tier routing (`[Bem/Normal]`, `[Mais ou menos]`, `[Mal/Ruim]`), sub-2s AI entry tagging, trilingual expression support, and privacy AdMob container.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 4  
**Requirements**: [TRG-01, TRG-02, AD-01, I18N-02]  
**Success Criteria** (what must be TRUE):

  1. Screen 3 displays the mandatory dual-axis assessment ("Como você está se sentindo hoje?" / "How are you feeling today?") with 3 options via icons and text (`[Bem / Normal]`, `[Mais ou menos]`, `[Mal / Ruim]`):
     - First evaluation: Eixo Psico-Emocional
     - Second evaluation: Eixo Registro Físico
     - If both are `[Bem / Normal]`, concludes check-in immediately with a wellness confirmation.
     - If either is `[Mais ou menos]` or `[Mal / Ruim]`, routes into the 5-step journal flow for the respective axis/axes, displaying a static dual-axis reflection note if both axes report discomfort.
  2. Natural language lay-term descriptions in Brazilian Portuguese, Spanish, or English are tagged into body areas or emotional states in under 2 seconds (RNF-002) using Gemini 1.5 Flash structured JSON without clinical diagnosis or urgency scoring.
  3. Screen 3 displays a privacy-focused native AdMob banner container targeted strictly by age and approximate geolocation for local businesses (pharmacies, supermarkets, department stores); zero medical profiling or health data tracking.

**Plans**: 2 plans

Plans:

- [x] 05-01: Screen 3 Home UI with dual-axis check-in flow (Psico-Emocional and Registro Físico), wellness confirmation, and native AdMob container
- [x] 05-02: Gemini 1.5 Flash structured JSON entry tagging service with Redis caching and sub-2s SLA validation

---

### Phase 6: Check-in Summary, Body Area Mapping & Wellness Readings (Screen 6 / RF-004 & RF-005)

**Goal**: Build Screen 6: Check-in Summary & Wellness Readings with 19-category lay mapping (7 emotional dimensions and 12 body areas), colloquial expression translation, dual-axis reflection note, self-reported intensity ("Intensidade informada: n/5"), static universal guidance block, and curated educational wellness articles with verified official sources.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 5  
**Requirements**: [SOM-01, SOM-02, OUT-01, REC-01]  
**Success Criteria** (what must be TRUE):

  1. Screen 6 displays body area and mood tags translating lay descriptions (*"nó na garganta"*, *"peito apertado"*, *"cabeça cheia"*) into standard categories without clinical concepts or urgency scores.
  2. If the user registers physical discomfort and emotional distress on the same day, system renders a static reflection note: *"Você registrou sensações no corpo e nas emoções hoje. Se algum desconforto físico persistir ou piorar, converse com um profissional de saúde."* (no differential organic primacy reasoning / somatização).
  3. Screen 6 displays user self-reported intensity ("Intensidade que você informou: n/5") and universal static guidance block ("Este app não avalia sua saúde. Se algum desconforto persistir, piorar ou te preocupar, procure um profissional de saúde. Em emergência, ligue 192.") instead of calculated care disposition.
  4. Screen 6 renders curated educational wellness reading cards ("Leituras sobre bem-estar") citing authentic public health sources (e.g., Ministério da Saúde), accompanied by the note: *"Conteúdos educativos gerais. Não são orientação para o seu caso."*

**Plans**: 2 plans

Plans:

- [x] 06-01: Colloquial expression translation engine, body area/mood mapping, and static dual-axis reflection
- [x] 06-02: Screen 6 Check-in Summary UI with self-reported intensity, static guidance block, and curated educational wellness reading cards

---

### Phase 7: Recurrence Consistency Verification Sheet (Screen 5 / RF-003 & UC-01)

**Goal**: Implement Screen 5: Recurrence Consistency Verification Sheet triggered when a discomfort is reported as starting today despite active logs in the past 14 days, incorporating UC-01 empathetic dialog ("Isso já apareceu antes?") and boundary guardrails.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 6  
**Requirements**: [ANTI-01, ANTI-02, ANTI-03]  
**Success Criteria** (what must be TRUE):

  1. System scans PostgreSQL 14-day temporal indices `(user_id, recorded_at DESC)` in <15ms whenever user selects "Começou hoje" in Step 2 of Screen 4.
  2. If active logs exist in the past 14 days for the same area, Screen 5 friendly bottom sheet appears with UC-01 dialog: *"Notei aqui no seu histórico que você também registrou essa sensação há poucos dias. Quer registrar como algo que voltou, para seu diário ficar organizado?"*
  3. User can tap binary choice buttons (`[É a mesma sensação que voltou]` vs `[Sentimento completamente novo]`) to normalize internal timeline without punitive rejection.
  4. System enforces respectful behavioral boundary guardrails (handling non-journal recreational queries safely and respectfully without hallucination).

**Plans**: 2 plans

Plans:

- [x] 07-01: Temporal index optimization, longitudinal consistency evaluation, and boundary validation service in PostgreSQL/NestJS
- [x] 07-02: Screen 5 Recurrence Check friendly bottom sheet UI with binary choice buttons and state reconciliation

---

### Phase 8: Offline Caching & Outbox Synchronization

**Goal**: Enable seamless offline check-in capability using local encrypted Drift SQLite storage and background transactional outbox synchronization.  
**Mode:** mvp  
**UI hint**: no  
**Depends on**: Phase 7  
**Requirements**: [SYNC-01]  
**Success Criteria** (what must be TRUE):

  1. User can complete daily check-ins even when completely offline.
  2. Completed check-ins are saved locally in an encrypted Drift SQLite database and enqueued into an outbox table.
  3. Outbox worker automatically syncs queued check-ins to the backend in chronological order once network connectivity is restored without data loss or duplicates.

**Plans**: 2 plans

Plans:

- [x] 08-01: Local Drift SQLite database setup with encrypted schema and transactional outbox queue
- [x] 08-02: Network connectivity monitor and resilient background synchronization worker with idempotency keys

---

### Phase 9: Historical Dashboard & 2D Body Map (Screen 7 / RF-008 & Section 5.1)

**Goal**: Build Screen 7: Historical Dashboard featuring segmented tab bar, interactive 2D Anatomical Body Map reflecting self-reported intensities, 7-day emotional trend graph, Cards de Padrões nos Registros, and Lista Retrospectiva feeds.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 8  
**Requirements**: [DASH-01, DASH-02, DASH-03, DASH-04]  
**Success Criteria** (what must be TRUE):

  1. Screen 7 features a segmented tab bar allowing the user to toggle between Módulo Psico-Emocional and Módulo Físico.
  2. Módulo Físico displays an interactive 2D Anatomical Body Map reflecting 14-day self-reported symptom intensity across 12 body areas.
  3. Módulo Psico-Emocional displays a 7-day linear emotional trend graph (`fl_chart`) tracking emotional dimensions over time.
  4. Both verticals render Cards de Padrões nos Registros (e.g., *"Você registrou estresse/esgotamento com intensidade alta 4 vezes nos últimos 10 dias. Se isso está atrapalhando seu dia a dia, pode ser útil conversar com um profissional de saúde."*) and vertical scrolling Lista Retrospectiva feeds.

**Plans**: 2 plans

Plans:

- [x] 09-01: Screen 7 Módulo Físico dashboard with interactive 2D Anatomical Body Map (`CustomPainter`), chromatic gradient, and physical Lista Retrospectiva
- [x] 09-02: Screen 7 Módulo Psico-Emocional dashboard with 7-day multi-line trend graph (`fl_chart`), Cards de Padrões nos Registros, emotional Lista Retrospectiva, and segmented tab bar

---

### Phase 10: LGPD Data Sovereignty, Account Deletion & Production Verification

**Goal**: Deliver LGPD self-service data export and permanent deletion workflows alongside end-to-end security and latency verification.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 9  
**Requirements**: [SEC-03]  
**Success Criteria** (what must be TRUE):

  1. User can request a complete self-service export of all personal account and journal history data in portable JSON format.
  2. User can permanently hard-delete their account and all associated personal records in compliance with LGPD Art. 18.
  3. Hard deletion immediately wipes user rows across all relational tables and cascades to local SQLite storage and Redis caches.
  4. End-to-end automated verification confirms sub-2s tagging latency (RNF-002) and zero cross-tenant data leakage across the entire platform.

**Plans**: 2 plans

Plans:

- [x] 10-01: LGPD self-service data export generation and cascading permanent deletion services
- [x] 10-02: User-facing privacy center UI, confirmation safeguards, and end-to-end production latency/security verification suite

---

### Phase 11: Multi-Profile Legal Guardianship & Consensual Sharing (PERM-01, PERM-02)

**Goal**: Deliver backend schema, PostgreSQL RLS policies, and mobile UI for managing legally protected dependent profiles (minors, dependent adults under legal guardianship) and optional consensual sharing (couples, siblings, informal caregivers) with granular access control.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 10  
**Requirements**: [PREM-06, PREM-07]  
**Success Criteria** (what must be TRUE):  
  1. Primary account holder can register and manage dependent profiles under legal guardianship (minors or dependent adults) with explicit LGPD Art. 14 consent records.  
  2. Database enforces Row-Level Security (RLS) separating dependent records, granting access only to verified legal guardians and authorized proxies.  
  3. User can invite optional partners (spouse, siblings, caregivers) via secure invite codes with granular access permissions (View Only vs Full Edit).  
  4. User can revoke optional sharing access instantly with single-tap immediate session termination.  
  5. Mobile UI provides a seamless profile switcher allowing quick transitions between the primary user and authorized dependents.  

**Plans**: 3 plans

Plans:  
**Wave 1**  
- [ ] 11-01: Multi-profile database schema (dependents, guardianships, shared_access_grants) and PostgreSQL RLS proxy isolation policies  
**Wave 2**  
- [ ] 11-02: Mobile profile switcher, legal guardian registration modal (LGPD Art. 14 consent), and optional access grant/revocation management screen  
**Wave 3**  
- [ ] 11-03: Live Flutter e2e on a running app (integration_test + Dart driver session) for consent, profile switch, view-only share, and instant revoke  

---

### Phase 12: Preventive Immunization Tracker & Drug Allergy Registry (VACC-01, ALRG-01)

**Goal**: Deliver digital vaccination booklet for mandatory (PNI/SUS) and elective vaccines, plus user-informed drug allergy registration displayed in personal profile and export (without automated clinical cross-check).  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 11  
**Requirements**: [PREM-08, PREM-09]  
**Success Criteria** (what must be TRUE):  
  1. User can view and track national immunization schedule (PNI) as well as elective/private vaccines, logging applied doses, batch numbers, and upcoming booster dates.  
  2. User can record personal allergies to active drug ingredients and medication classes, displaying clear badges on the profile and export summary.  
  3. All allergy information is user-maintained for self-reference without automated clinical conflict alerts or diagnostic claims.  

**Plans**: 2 plans

---

### Phase 13: Personal Conditions Registry & Continuous Treatment Reminders (RF-010, RF-011, CLIN-01)

**Goal**: Deliver personal conditions registry informed by the user, continuous medication dose reminders with inventory stock management, and one-click summary of self-reported logs in PDF.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 12  
**Requirements**: [PREM-01, PREM-02, PREM-05]  
**Success Criteria** (what must be TRUE):  
  1. User can record and maintain personal diagnosed conditions informed by their healthcare provider, mapped to standard ICD-10/11 terminology for personal tracking without algorithmic diagnostic suggestions.  
  2. Continuous treatment dashboard enables user-configured scheduled dose reminders, low-stock threshold alerts, and personal appointment logging without automated dosage adjustments.  
  3. User can export a one-click summary PDF of self-reported journal trends, user notes, and personal medications for voluntary sharing with healthcare professionals, without clinical assessment or recommendation sections.  

**Plans**: 2 plans

---

### Phase 14: Document Processing Engine for Transcription & Leaflets (RF-012, RX-01, BULA-01)

**Goal**: Asynchronous BullMQ + OCR pipeline for user-confirmed lab exam transcription (RF-012), prescription pre-fill for editable forms (RX-01), and direct link to official ANVISA Bulário Eletrônico (BULA-01).  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 13  
**Requirements**: [PREM-03, PREM-12, PREM-11]  
**Success Criteria** (what must be TRUE):  
  1. Uploaded laboratory exam PDFs/photos are transcribed into structured entries (analyte, value, unit, reference range printed by laboratory), requiring explicit user verification and without clinical interpretations, alerts, or AI commentary.  
  2. Prescription scans pre-fill an editable form, requiring explicit user field-by-field confirmation before saving personal medication reminders, never creating automatic alarms.  
  3. Direct integration and link with official ANVISA Bulário Eletrônico for user access to official medication leaflets.  

**Plans**: 2 plans

---

### Phase 15: Voice Interaction, Advanced Biometrics & Multi-Tier Subscription Monetization (VOICE-01, AUTH-03, PRIC-01, RF-013)

**Goal**: Implement post-login hands-free voice journal entries (Advanced-exclusive), advanced native biometric settings with step-up reauthentication, and PCI-DSS recurring checkout supporting Free, Premium, Advanced, and Pacote Família (emergency help resources remain 100% free across all tiers).  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 14  
**Requirements**: [PREM-14, PREM-13, PREM-10, PREM-04]  
**Success Criteria** (what must be TRUE):  
  1. Advanced tier subscribers can complete daily journal entries and check-ins using voice transcription and natural language voice commands.  
  2. Biometric security settings allow custom auto-lock intervals and optional step-up authentication when accessing personal records or exporting data.  
  3. Multi-tier subscription gateway enforces tier entitlements (Free, Premium, Advanced, Pacote Família) with automated billing management, ensuring help resources are always universal and free.  

**Plans**: 2 plans

## Progress

**Execution Order:**  
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10

| Phase | Plans Complete | Status | Completed |
|---|---|---|---|
| 1. Backend Foundation, PostgreSQL RLS & Data Encryption | 2/2 | Complete | 2026-09-14 |
| 2. Onboarding & Identity (Screens 1 & 2) with Native Biometrics | 2/2 | Complete | 2026-09-14 |
| 3. Always-On Safety Resources Screen (Screen 8 / RF-006) | 2/2 | Complete | 2026-09-14 |
| 4. Dynamic 5-Step Wellness Journal Wizard (Screen 4 / RF-002) | 2/2 | Complete | 2026-09-14 |
| 5. Home & Unified Dual-Axis Check-in (Screen 3 / RF-001) & AdMob Container | 2/2 | Complete | 2026-09-14 |
| 6. Check-in Summary, Body Area Mapping & Wellness Readings (Screen 6 / RF-004 & RF-005) | 2/2 | Complete | 2026-09-14 |
| 7. Recurrence Consistency Verification Sheet (Screen 5 / RF-003 & UC-01) | 2/2 | Complete | 2026-09-14 |
| 8. Offline Caching & Outbox Synchronization | 2/2 | Complete | 2026-09-14 |
| 9. Historical Dashboard & 2D Body Map (Screen 7 / RF-008 & Section 5.1) | 2/2 | Complete | 2026-09-14 |
| 10. LGPD Data Sovereignty, Account Deletion & Production Verification | 2/2 | Complete | 2026-09-14 |
