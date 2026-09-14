# Roadmap: DualisCheckUp

## Overview

DualisCheckUp delivers an offline-capable, cross-platform mobile preventive health platform that bridges somatic physical symptoms (across 12 anatomical systems) and psycho-emotional dimensions (across 7 dimensions) into a unified, safe, and clinically consistent triage experience. Aligned strictly with the SRS v1.0 Free Tier specifications (IDs 01–08 and RF-001–RF-009), the journey begins by establishing a bulletproof LGPD backend security foundation (Phase 1, complete), proceeds through Module 1 (Onboarding & Identity with Simplified Registration), deploys the zero-failure Emergency Risk Alert Screen (Screen 8), and constructs the Free Tier Triage Engine (Screens 3, 4, 5, 6, and 7) with dynamic theming, 14-day Antiburla verification, offline sync, 2D anatomical heat mapping, and full LGPD data sovereignty. All Premium Tier features (IDs 09–12 / RF-010–RF-013 / UC-02) are deferred to v2.

## Phases

- [x] **Phase 1: Backend Foundation, PostgreSQL RLS & Data Encryption** - Multi-tenant PostgreSQL RLS, AES-256 encryption at rest, TLS 1.3, São Paulo hosting, and regulatory disclaimers.
- [x] **Phase 2: Onboarding & Identity (Screens 1 & 2) with Native Biometrics** - Splash animation, 3-card value carousel, simplified registration (RF-007) with LGPD consent, and biometric app lock.
- [ ] **Phase 3: Emergency Risk Alert Screen (Screen 8 / RF-006)** - Full-screen Red Emergency View (`#D32F2F`) locked against dismissal, deterministic red-flag triggers, and 1-tap emergency dispatch.
- [ ] **Phase 4: Dynamic 5-Step Triage Wizard (Screen 4 / RF-002)** - Standardized 5-step triage tree with verbatim clinical questions and dynamic color tweening (Clinical Teal ↔ Soft Indigo).
- [ ] **Phase 5: Home & Unified Dual-Axis Trigger Check-in (Screen 3 / RF-001) & AdMob Container (RF-009)** - "Como você está se sentindo hoje?" dual-axis trigger (`[Bem/Normal]`, `[Mais ou menos]`, `[Mal/Ruim]`), sub-2s AI classification, and privacy AdMob container.
- [ ] **Phase 6: Triage Outcome, Somatic Mapping & Article Recommendations (Screen 6 / RF-004 & RF-005)** - Dimension badges for lay terms/distress idioms across 7 dimensions and 12 systems, Organic Primacy, calculated intensity score, and curated article cards.
- [ ] **Phase 7: Antiburla Historical Verification Sheet (Screen 5 / RF-003 & UC-01)** - 14-day temporal consistency scan on "Começou hoje" logs with empathetic confrontation bottom sheet and biological boundary guardrails.
- [ ] **Phase 8: Offline Caching & Outbox Synchronization** - Encrypted local Drift SQLite storage and background transactional outbox synchronization.
- [ ] **Phase 9: Historical Dashboard & 2D Body Heat Map (Screen 7 / RF-008 & Section 5.1)** - Segmented tab bar, interactive 2D Anatomical Body Map with yellow-to-red pain heat gradients, 7-day emotional multi-line trend graph, Cards de Recorrência Crítica, and Lista Retrospectiva.
- [ ] **Phase 10: LGPD Data Sovereignty, Account Deletion & Production Verification** - Self-service data export, cascading permanent account deletion, and end-to-end SLA/security verification.

## Phase Details

### Phase 1: Backend Foundation, PostgreSQL RLS & Data Encryption

**Goal**: Establish the secure backend foundation with PostgreSQL Row-Level Security (using Supabase free tier for development, Google Cloud SQL São Paulo for production), AES-256 encryption at rest, TLS 1.3 in transit, and tenant isolation under LGPD.  
**Mode:** mvp  
**UI hint**: no  
**Depends on**: Nothing (first phase)  
**Requirements**: [SEC-01, SEC-02, DISC-01]  
**Success Criteria** (what must be TRUE):

  1. Backend executes all health transactions inside a PostgreSQL session bounded by `SET LOCAL app.current_user_id = :userId`, completely blocking unauthorized multi-tenant access.
  2. Sensitive health narratives, notes, and symptom data are encrypted with AES-256 at rest and transmitted exclusively via TLS 1.3.
  3. Database and API services run strictly in the São Paulo region (`sa-east-1` for Google Cloud SQL in production / local/dev Supabase instance) to comply with LGPD Art. 11 data residency mandates.
  4. Platform provides non-diagnostic medical disclaimer contracts compliant with Anvisa RDC 657/2022 and CFM Res. 2.314/2022, localized in Brazilian Portuguese (`pt-BR`), Spanish (`es`), and English (`en`).

**Plans**: 2 plans

Plans:
**Wave 1**

- [x] 01-01: NestJS 12 Fastify initialization, Drizzle ORM schema, and PostgreSQL RLS tenant isolation middleware (configured for Supabase dev connection and Google Cloud SQL prod compatibility)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02: AES-256 field-level encryption, TLS 1.3 configuration, trilingual medical disclaimer API (pt-BR, es, en), and automated cross-tenant security regression suite

---

### Phase 2: Onboarding & Identity (Screens 1 & 2) with Native Biometrics

**Goal**: Deliver Module 1: Screen 1 (Onboarding & Auth Choice) and Screen 2 (Simplified Registration RF-007 / SRS ID 01) with native biometric auto-lock and trilingual UI foundation.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 1  
**Requirements**: [ONBD-01, AUTH-01, AUTH-02, I18N-01]  
**Success Criteria** (what must be TRUE):

  1. User sees a smooth splash animation and can swipe through a 3-card value proposition carousel (Dual Triage, Encrypted Records, Preventive Insights) on Screen 1 with "Sign In" and "Create Account" CTAs.
  2. User can complete simplified registration on Screen 2 with mandatory fields: Full Name, Date of Birth, Biological Sex (Gender), Email, and Password.
  3. Registration strictly requires an explicit LGPD health data privacy consent checkbox before enabling account creation.
  4. Application supports native biometric authentication (FaceID/TouchID/BiometricPrompt) with automatic screen obscuring and app locking upon backgrounding.
  5. Application establishes trilingual Flutter localization (`intl` with `app_pt.arb`, `app_es.arb`, and `app_en.arb`) with dynamic language switching and `pt-BR` default fallback.

**Plans**: 2 plans

Plans:

- [x] 02-01: Flutter 3.29 baseline setup, Riverpod 3.4.3, Screen 1 onboarding carousel and navigation routing
- [x] 02-02: Screen 2 simplified registration form (RF-007) with LGPD consent, native biometrics (`local_auth`), and secure storage

---

### Phase 3: Emergency Risk Alert Screen (Screen 8 / RF-006)

**Goal**: Implement the zero-failure deterministic clinical emergency interceptor and Screen 8 (Full-screen Red Emergency View).  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 2  
**Requirements**: [EMRG-01, EMRG-02, EMRG-03]  
**Success Criteria** (what must be TRUE):

  1. System deterministically intercepts Level 4–5 red-flag symptoms (crushing chest pain, severe dyspnea, acute emotional crisis) before any other questioning occurs.
  2. Upon detecting an emergency red flag, triage immediately halts and displays Screen 8: Full-screen Red Emergency View (`#D32F2F`) locked against dismissal (`PopScope(canPop: false)`).
  3. Screen 8 displays urgent medical contacts with 1-tap dialer for emergency services (SAMU 192, Bombeiros 193, CVV 188) and immediate life-safety instructions.

**Plans**: 2 plans

Plans:

- [x] 03-01: Deterministic red-flag evaluation engine (MTS/ESI Level 1–2 criteria) and emergency state machine
- [x] 03-02: Screen 8 full-screen emergency modal (`#D32F2F`) with `PopScope` gesture lock, 1-tap telephony dispatch (`url_launcher`), and emergency instructions

---

### Phase 4: Dynamic 5-Step Triage Wizard (Screen 4 / RF-002 / SRS ID 02 & 03)

**Goal**: Build Screen 4: Dynamic 5-Step Triage Wizard with active vertical visual indicator (Soft Indigo vs. Clinical Teal) and the exact 5 clinical questions per vertical from SRS Section 3.1.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 3  
**Requirements**: [TRG-03, TRG-04, TRG-05]  
**Success Criteria** (what must be TRUE):

  1. Screen 4 header displays mandatory visual state transition banners informatively:
     - Vertical A: *"Iniciando Autoavaliação Psico-Emocional"* with Soft Indigo (`#3F51B5`).
     - Vertical B: *"Iniciando Autoavaliação Física"* with Clinical Teal (`#00796B`).
  2. User progresses through the standardized 5-step wizard (max 5 questions per vertical):
     - **Vertical A (Psico-Emocional)**:
       1. Natureza: *"Olhando para o seu lado emocional e mental, qual palavra descreve melhor o que você está sentindo agora?"* (Ansiedade/Agitação, Tristeza/Desânimo, Estresse/Irritabilidade, Cansaço Mental).
       2. Tempo/Persistência: *"Você tem se sentido assim frequentemente nos últimos dias ou é algo muito específico de hoje?"* (Começou hoje / Já faz alguns dias / É algo constante há semanas).
       3. Intensidade: *"Essa sensação está parecendo um leve incômodo de fundo ou algo forte que está acelerando seus pensamentos?"* (Leve e controlável / Moderada / Muito forte e difícil de segurar).
       4. Causas/Gatilhos: *"Você consegue identificar se existe um motivo principal para isso estar acontecendo hoje?"* (Trabalho/Estudos, Família/Relacionamentos, Noite ruim de sono, Não sei dizer).
       5. Desfecho/Ação: Cruzamento com ecossistema de artigos preventivos (sono, relaxamento, respiração).
     - **Vertical B (Física)**:
       1. Localização: *"Vamos falar sobre a parte física. Onde você está sentindo esse desconforto ou dor principal?"* (Cabeça, Costas/Coluna, Articulações [Joelho, Ombro, etc.], Abdômen/Estômago).
       2. Tempo/Persistência: *"Há quanto tempo essa dor ou anomalia persiste?"* (Começou agora / Há alguns dias / É crônica).
       3. Intensidade: *"Em uma escala de 1 a 5 (onde 1 é quase imperceptível e 5 é insuportável), como está agora?"* (Seletor numérico de 1 a 5).
       4. Causas/Gatilhos: *"Você lembra de ter feito algum esforço atípico, exercício pesado ou sofrido alguma batida/queda recentemente?"* (Sim exercício intenso / Sim sofri queda / Não começou do nada).
       5. Desfecho/Ação: Cruzamento com artigos ou disparo de alertas de risco.
  3. Triage state machine automatically purges sensitive in-memory session data upon exit or completion via Riverpod `autoDispose`.

**Plans**: 2 plans

Plans:

- [x] 04-01: Domain models for 5-step clinical decision tree across both verticals and dynamic theme transition engine (Clinical Teal ↔ Soft Indigo)
- [x] 04-02: Screen 4 sequential 5-step triage wizard UI and Riverpod `autoDispose` state machine

---

### Phase 5: Home & Unified Dual-Axis Trigger Check-in (Screen 3 / RF-001) & AdMob Container (RF-009)

**Goal**: Implement Screen 3: Home & Unified Dual-Axis Trigger Check-in ("Como você está se sentindo hoje?" across Psico-Emocional and Avaliação Física axes) with 3-tier routing (`[Bem/Normal]`, `[Mais ou menos]`, `[Mal/Ruim]`), sub-2s AI classification, trilingual distress idiom support, and privacy AdMob container.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 4  
**Requirements**: [TRG-01, TRG-02, AD-01, I18N-02]  
**Success Criteria** (what must be TRUE):

  1. Screen 3 displays the mandatory dual-axis trigger assessment ("Como você está se sentindo hoje?" / "How are you feeling today?") with 3 options via icons and text (`[Bem / Normal]`, `[Mais ou menos]`, `[Mal / Ruim]`):
     - First evaluation: Eixo Psico-Emocional
     - Second evaluation: Eixo Avaliação Física / Dor Física
     - If both are `[Bem / Normal]`, concludes session immediately with a preventive wellness confirmation.
     - If either is `[Mais ou menos]` or `[Mal / Ruim]`, routes into standard or high-sensitivity AI triage for the respective axis/axes, observing Organic Primacy when both axes report symptoms.
  2. Natural language lay-term descriptions in Brazilian Portuguese, Spanish, or English are classified into formal categories in under 2 seconds (RNF-002) using Gemini 1.5 Flash structured JSON.
  3. Screen 3 displays a privacy-focused native AdMob banner container targeted strictly by age and approximate geolocation for local businesses (pharmacies, supermarkets, department stores); zero medical profiling.

**Plans**: 2 plans

Plans:

- [x] 05-01: Screen 3 Home UI with dual-axis trigger flow (Psico-Emocional and Física), wellness confirmation, and native AdMob container
- [x] 05-02: Gemini 1.5 Flash structured JSON classification service with Redis caching and sub-2s SLA validation

---

### Phase 6: Triage Outcome, Somatic Mapping & Article Recommendations (Screen 6 / RF-004 & RF-005)

**Goal**: Build Screen 6: Triage Outcome & Article Recommendations with 19-category clinical mapping (7 dimensions and 12 systems), Brazilian distress idiom mapping, Organic Primacy, calculated intensity score, and specialist article cards.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 5  
**Requirements**: [SOM-01, SOM-02, OUT-01, REC-01]  
**Success Criteria** (what must be TRUE):

  1. Screen 6 displays formal dimension classification badges translating lay descriptions and Brazilian distress idioms (*"nó na garganta"*, *"peito apertado"*, *"cabeça cheia"*) into official matrices (7 Psico-Emocional dimensions and 12 Sistemas Físicos from SRS Section 4).
  2. System enforces Organic Primacy: physical symptoms reported during emotional distress trigger mandatory physical checks before attributing symptoms to psychological stress.
  3. Screen 6 displays calculated intensity score (1 to 5) and care disposition (Auto-cuidado / Self-Care, Consulta de Rotina / Routine Visit, Pronto Atendimento / Urgent Care, Emergência / Emergency).
  4. Screen 6 renders curated preventive article recommendation cards with links to content written by renowned specialists matching the diagnosed theme.

**Plans**: 2 plans

Plans:

- [x] 06-01: Distress idiom translation engine and somatic-emotional clinical matrix mapping with Organic Primacy
- [x] 06-02: Screen 6 Outcome UI with dimension badges, calculated intensity score, care disposition, and curated article cards

---

### Phase 7: Antiburla Historical Verification Sheet (Screen 5 / RF-003 & UC-01)

**Goal**: Implement Screen 5: Antiburla Historical Verification Sheet triggered when a symptom is reported as starting today despite active logs in the past 14 days, incorporating UC-01 empathetic dialog and biological boundary validation.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 6  
**Requirements**: [ANTI-01, ANTI-02, ANTI-03]  
**Success Criteria** (what must be TRUE):

  1. System scans PostgreSQL 14-day temporal indices `(user_id, recorded_at DESC)` in <15ms whenever user selects "Começou hoje" in Step 2 of Screen 4.
  2. If active logs exist in the past 14 days for the same area, Screen 5 friendly bottom sheet appears with UC-01 dialog: *"Notei aqui no seu histórico que você também sentiu esse desânimo há poucos dias. Você acha que essa tristeza de hoje é um sentimento completamente novo ou pode ser aquela mesma sensação que acabou voltando?"*
  3. User can tap binary choice buttons (`[É a mesma sensação que voltou]` vs `[Sentimento novo]`) to normalize internal timeline without punitive rejection.
  4. System enforces biological and behavioral boundary guardrails (handling biologically discordant inputs like female reporting testicular pain, and non-clinical recreational queries safely without hallucination).

**Plans**: 2 plans

Plans:

- [x] 07-01: Temporal index optimization, longitudinal consistency evaluation, and biological boundary validation service in PostgreSQL/NestJS
- [x] 07-02: Screen 5 Antiburla friendly bottom sheet UI with binary choice buttons and state reconciliation

---

### Phase 8: Offline Caching & Outbox Synchronization

**Goal**: Enable seamless offline check-in capability using local encrypted Drift SQLite storage and background transactional outbox synchronization.  
**Mode:** mvp  
**UI hint**: no  
**Depends on**: Phase 7  
**Requirements**: [SYNC-01]  
**Success Criteria** (what must be TRUE):

  1. User can complete daily symptom check-ins even when completely offline.
  2. Completed check-ins are saved locally in an encrypted Drift SQLite database and enqueued into an outbox table.
  3. Outbox worker automatically syncs queued check-ins to the backend in chronological order once network connectivity is restored without data loss or duplicates.

**Plans**: 2 plans

Plans:

- [x] 08-01: Local Drift SQLite database setup with encrypted schema and transactional outbox queue
- [x] 08-02: Network connectivity monitor and resilient background synchronization worker with idempotency keys

---

### Phase 9: Historical Dashboard & 2D Body Heat Map (Screen 7 / RF-008 & Section 5.1)

**Goal**: Build Screen 7: Historical Dashboard featuring segmented tab bar, interactive 2D Anatomical Body Map with pain heat gradients, 7-day emotional trend graph, Cards de Recorrência Crítica, and Lista Retrospectiva feeds.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 8  
**Requirements**: [DASH-01, DASH-02, DASH-03, DASH-04]  
**Success Criteria** (what must be TRUE):

  1. Screen 7 features a segmented tab bar allowing the user to toggle between Módulo Psico-Emocional and Módulo Físico.
  2. Módulo Físico displays an interactive 2D Anatomical Body Map with chromatic heat gradients (Yellow for mild 1–2 to Red for severe pain 4–5) reflecting 14-day symptom intensity across 12 systems.
  3. Módulo Psico-Emocional displays a 7-day linear emotional trend graph (`fl_chart`) tracking the 7 emotional dimensions over time.
  4. Both verticals render Cards de Recorrência Crítica (e.g., *"⚠️ Foco de Atenção: Identificamos que a sua dimensão Estresse / Burnout esteve em nível 4 em 6 dos últimos 10 dias. Considerou ler nosso artigo?"*) and vertical scrolling Lista Retrospectiva feeds.

**Plans**: 2 plans

Plans:

- [ ] 09-01: Screen 7 Módulo Físico dashboard with interactive 2D Anatomical Body Map (`CustomPainter`), chromatic heat gradient, and physical Lista Retrospectiva
- [ ] 09-02: Screen 7 Módulo Psico-Emocional dashboard with 7-day multi-line trend graph (`fl_chart`), Cards de Recorrência Crítica, emotional Lista Retrospectiva, and segmented tab bar

---

### Phase 10: LGPD Data Sovereignty, Account Deletion & Production Verification

**Goal**: Deliver LGPD self-service data export and permanent deletion workflows alongside end-to-end security and latency verification.  
**Mode:** mvp  
**UI hint**: yes  
**Depends on**: Phase 9  
**Requirements**: [SEC-03]  
**Success Criteria** (what must be TRUE):

  1. User can request a complete self-service export of all personal account and medical history data in portable JSON format.
  2. User can permanently hard-delete their account and all associated health records in compliance with LGPD Art. 18.
  3. Hard deletion immediately wipes user rows across all relational tables and cascades to local SQLite storage and Redis caches.
  4. End-to-end automated verification confirms sub-2s triage latency (RNF-002) and zero cross-tenant data leakage across the entire platform.

**Plans**: 2 plans

Plans:

- [ ] 10-01: LGPD self-service data export generation and cascading permanent deletion services
- [ ] 10-02: User-facing privacy center UI, confirmation safeguards, and end-to-end production latency/security verification suite

---

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Backend Foundation, PostgreSQL RLS & Data Encryption | 2/2 | Complete | 2026-09-14 |
| 2. Onboarding & Identity (Screens 1 & 2) with Native Biometrics | 2/2 | Complete | 2026-09-14 |
| 3. Emergency Risk Alert Screen (Screen 8 / RF-006) | 2/2 | Complete | 2026-09-14 |
| 4. Dynamic 5-Step Triage Wizard (Screen 4 / RF-002) | 2/2 | Complete | 2026-09-14 |
| 5. Home & Unified Trigger Check-in (Screen 3 / RF-001) & AdMob Container | 2/2 | Complete | 2026-09-14 |
| 6. Triage Outcome, Somatic Mapping & Article Recommendations (Screen 6 / RF-004 & RF-005) | 2/2 | Complete | 2026-09-14 |
| 7. Antiburla Historical Verification Sheet (Screen 5 / RF-003 & UC-01) | 0/2 | Not started | - |
| 8. Offline Caching & Outbox Synchronization | 0/2 | Not started | - |
| 9. Historical Dashboard & 2D Body Heat Map (Screen 7 / RF-008 & Section 5.1) | 0/2 | Not started | - |
| 10. LGPD Data Sovereignty, Account Deletion & Production Verification | 0/2 | Not started | - |
