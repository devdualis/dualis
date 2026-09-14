# Project Research Summary

**Project:** DualisCheckUp  
**Domain:** Cross-Platform Mobile Preventive Health Platform & AI Clinical Triage  
**Researched:** 2026-09-13  
**Confidence:** HIGH  

---

## Executive Summary

DualisCheckUp is an offline-capable, cross-platform mobile preventive health platform designed to unify daily physical health tracking across 12 anatomical systems and psycho-emotional well-being across 7 dimensions into a single AI-assisted triage experience. Modern clinical digital health platforms succeed by applying validated triage protocols (Manchester Triage System / Emergency Severity Index) to eliminate clinical blind spots while operating strictly as Software as a Medical Device (SaMD Class I/II) risk-stratification guides rather than unauthorized autonomous diagnostic engines (CFM Res. 2.314/2022, Anvisa RDC 657/2022). Furthermore, handling Brazilian health data demands strict compliance with Lei Geral de Proteção de Dados (LGPD, Art. 11) through regional data residency (`sa-east-1` / São Paulo) and cryptographic patient isolation.

The recommended architectural approach couples a reactive Flutter 3.29+ client (`flutter_riverpod` 3.4.3, Material 3, `drift` SQLite offline outbox) with a modular NestJS 12 backend powered by the Fastify engine and Node.js 22 LTS. Data integrity and multi-tenancy are enforced at the database engine level via PostgreSQL 16/17 Row-Level Security (`SET LOCAL app.current_user_id`) and temporal indices for sub-15ms longitudinal lookups. Real-time symptom triage utilizes Google Gemini 1.5 Flash via the unified `@google/genai` SDK with strict JSON Schema output enforcement to reliably meet the sub-2-second latency budget (RNF-001). Complex multi-page laboratory reports (RF-012) are processed through a decoupled asynchronous pipeline combining Google Cloud Vision / AWS Textract layout OCR with lightweight structured LLM biomarker extraction via Redis 7 and BullMQ queues, slashing token costs by ~85% while preventing numerical decimal hallucinations.

The primary systemic risks identified are clinical safety failures (missed red flags vs. paralyzing over-triage), diagnostic overshadowing (misattributing cardiac or respiratory pathology to emotional anxiety), user alienation from over-zealous anti-tampering ("Antiburla") contradiction checks, Brazilian comma-decimal corruption in lab OCR, and survey fatigue during daily check-ins. These are systematically mitigated through: (1) a dual-layer triage safety net where a deterministic rule gate intercepts emergency red flags before any LLM execution; (2) an "Organic Primacy" rule-out engine; (3) an empathetic clarification UX that separates immutable chronologies from fluctuating physiological states; (4) a 3-tier lab OCR pipeline with physiological plausibility bounds and mandatory Human-In-The-Loop confirmation; and (5) an adaptive two-tier check-in funnel (1-tap daily wellness pulse vs. deep 5-step triage).

---

## Key Findings

### Recommended Stack

DualisCheckUp utilizes a modern, compile-time type-safe, cross-platform architecture optimized for sub-2-second AI inference, 60fps vector canvas graphics, and zero-leakage healthcare tenant isolation. All software dependencies were verified against live package registries as of September 2026.

The client layer relies on Flutter 3.29+ / Dart 3.7+ with Riverpod 3.4.3 for declarative state management, leveraging `autoDispose` to guarantee zero-leak cleanup of sensitive health triage sessions. Navigation is handled by `go_router` 18.0.1, local offline persistence by `drift` 2.22.x (SQLite) with an outbox sync worker, and visual analytics by `fl_chart` 1.2.0 and native `CustomPainter` vector graphics. The backend is structured as a NestJS 12 modular monolith with Fastify, using Drizzle ORM 0.45.2 over PostgreSQL 16/17 with native Row-Level Security, Redis 7 for semantic response caching and BullMQ 6.3.4 background workers, Google Gemini 1.5 Flash for constrained JSON classification, and Google Cloud Vision / AWS Textract for laboratory OCR.

**Core technologies:**
- **Flutter SDK (`3.29.x` / Dart `3.7.x`):** Cross-platform client framework — Delivers 60–120fps hardware-accelerated rendering on iOS and Android from a single codebase; provides native Canvas support for the 2D Anatomical Body Heat Map and smooth Material 3 dynamic color tweening between Soft Indigo and Clinical Teal.
- **flutter_riverpod (`3.4.3`):** Reactive state management & DI — Compile-time safety, unidirectional data flow, and automatic lifecycle disposal (`autoDispose`) that purges sensitive clinical triage session memory upon screen unmount.
- **NestJS (`12.0.1` with Fastify Adapter):** Enterprise API backend — Structured modular architecture enforcing clear domain boundaries between Triage, Antiburla, Lab Exams, and Emergency modules; Fastify reduces routing overhead to <10ms to preserve headroom for the sub-2s AI SLA.
- **PostgreSQL (`16.x`/`17.x`) + Drizzle ORM (`0.45.2`):** Relational database with RLS & temporal support — Enforces native Row-Level Security (`SET LOCAL app.current_user_id`) at the storage engine level (LGPD Art. 11); supports `btree_gist` and composite temporal indices `(user_id, recorded_at DESC)` for sub-15ms 14-day consistency scans.
- **Redis (`7.2.x`) & BullMQ (`6.3.4`):** Task queue, rate limiter & cache — Sub-millisecond semantic response caching for frequent symptom queries, API rate-limiting, and resilient asynchronous queue workers for multi-page lab exam OCR and biomarker extraction.
- **Google Gemini 1.5 Flash (`@google/genai: 2.22.0`):** Structured AI symptom classification — Sub-1200ms inference latency at low token cost; native JSON Schema enforcement guarantees 100% adherence to the 19-category taxonomy without markdown wrapping or syntax errors.
- **Google Cloud Vision (`6.1.0`) / AWS Textract (`3.750.x`):** Decoupled laboratory document OCR — High-fidelity layout and tabular data extraction for Brazilian medical typography, isolating OCR from LLM reasoning to cut token costs by ~85% and prevent hallucinated decimal values.

---

### Expected Features

DualisCheckUp bridges the gap between passive habit trackers (Bearable, Daylio) and white-label diagnostic symptom checkers (Ada Health, Infermedica). It operates strictly within SaMD Class I/II preventive health guidelines, providing risk stratification, longitudinal consistency, and emergency safety rather than autonomous medical diagnosis.

**Must have (table stakes):**
- **Zero-Tolerance Emergency Safety Net (RF-006):** Instantaneous hard stop upon detecting Level 4–5 red-flag symptoms (crushing chest pain, dyspnea, focal deficits, suicidal ideation); deploys full-screen persistent red modal (`#D32F2F`) with `PopScope` gesture lock and 1-tap local emergency dispatch (SAMU 192, Bombeiros 193, CVV 188).
- **Conversational Daily Check-In Entry Point (RF-001):** "How are you feeling today?" prompt with fast-tap suggestion chips and sub-2s natural language symptom routing into physical or emotional verticals.
- **Standardized Clinical 5-Step Triage Tree (RF-002):** Structured, repeatable progression across all complaints: Nature → Persistence → Intensity → Triggers → Outcome.
- **Clear Care Disposition & Triage Categorization:** Actionable guidance categorized into 4 tiers: Home Self-Care, Routine Medical Visit (7–14 days), Urgent Care / Pronto Atendimento (12–24 hours), or Immediate Emergency.
- **Explicit Non-Diagnostic Regulatory Guardrails:** Prominent, persistent disclaimers clarifying that the app provides preventive risk stratification, not certified medical diagnoses or prescriptions (CFM Res. 2.314/2022, Anvisa RDC 657/2022).
- **LGPD Compliance & Health Data Sovereignty (RNF-002):** Sensitive health data isolation via PostgreSQL RLS, AES-256 encryption at rest, TLS 1.3 in transit, São Paulo regional hosting, and self-service account data erasure.
- **Biometric Authentication & Auto-Lock:** Native iOS FaceID/TouchID and Android BiometricPrompt with auto-lock on app backgrounding to protect sensitive medical history.
- **Chronological Health Timeline:** Paginated historical view of past check-ins, logged symptoms, and triage outcomes.

**Should have (competitive differentiators):**
- **Parallel Dual-Path Triage Architecture with Visual State Switching (RF-002):** Harmonizes 12 Anatomical Systems and 7 Psycho-Emotional Dimensions into an identical 5-step decision tree, with real-time palette tweening between Clinical Teal (`#00796B`) and Soft Indigo (`#3F51B5`).
- **14-Day Temporal Consistency ("Antiburla") Engine (RF-003):** Scans rolling 14-day history for conflicting timelines, erratic reporting, or malingering; resolves inconsistencies via supportive, non-accusatory clinical reconciliation dialogues.
- **Somatic & Psychosomatic Symptom Mapping (RF-004):** Translates colloquial Brazilian distress idioms (*"nó na garganta"*, *"peito apertado"*, *"frio na barriga"*, *"peso nos ombros"*) into dual physiological and emotional matrices while enforcing organic pathology rule-outs.
- **Interactive 2D Anatomical Body Heat Map (RF-008):** Vector body silhouette (front/back) mapping 12 anatomical systems with chromatic radial gradient heat blurs (Yellow → Amber → Deep Red) reflecting pain severity and 14-day recurrence.
- **7-Day Emotional Multi-Dimensional Trend Graph (RF-008):** Multi-line trend visualizer across 7 psycho-emotional dimensions with physical symptom badge overlays to reveal mind-body correlations.
- **Decoupled Lab Exam Biomarker Processing Pipeline (RF-012):** Cost-effective OCR (Cloud Vision / Textract) + structured LLM (Gemini 1.5 Flash) pipeline extracting biomarker key-value registries from blood/urine test PDFs and camera captures.
- **Context-Aware Preventive Health Micro-Interventions (RF-009):** Evidence-based lifestyle and self-care recommendations (sleep hygiene, ergonomic stretches, vagal breathing) tied directly to triage outcomes.
- **One-Click "Doctor's Brief" Clinical Export:** Single-page SBAR-formatted PDF summarizing chief complaints, 14-day symptom trajectories, emotional curves, and abnormal biomarkers for physical doctor visits.

**Defer (v2+):**
- **Autonomous Medical Diagnosis Engine (SaMD Class III):** Avoids massive regulatory liability, high false-positive rates, and cyberchondria.
- **Digital Prescription Ordering & Pharmacy Fulfillment:** Prohibited without validated digital physician signatures (ICP-Brasil).
- **Unbounded / Free-Form Chatbot Primary Triage:** Avoids high latency, prompt drift, hallucination, and user mobile typing fatigue.
- **Real-Time Telemedicine Video Consults:** Avoids high operational physician overhead and keeps product focused on personal health tracking.
- **Direct Hospital EHR Two-Way Synchronization (FHIR/HL7):** Avoids Brazilian hospital vendor fragmentation during v1 launch.
- **Gamification Badges / Streaks for Illness:** Prevents perverse psychological incentives and disrespectful user experiences during illness.
- **Biometric Wearable Passive Ingestion (HealthKit / Health Connect):** Deferred to v2 after core triage habituation is validated.

---

### Architecture Approach

DualisCheckUp adopts a modular client-server architecture with an offline-first mobile client and a containerized backend monolith. The client isolates UI presentation, domain entities, and data persistence into feature packages (`mobile/lib/features/`). Ephemeral triage sessions are driven by Riverpod `AutoDisposeAsyncNotifier` finite state machines that transition linearly through the 5-step tree and short-circuit immediately to an emergency halt state if severity level 4–5 is detected. The NestJS backend enforces multi-tenancy at the PostgreSQL engine level via transactional session context injection (`SET LOCAL app.current_user_id = :userId`), protecting sensitive health data under Brazilian LGPD. Complex background workflows (lab report OCR and LLM biomarker extraction) are completely decoupled from the API gateway using Redis 7 and BullMQ workers.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DUALISCHECKUP TOPOLOGY                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  Flutter Client (iOS/Android)       NestJS Fastify API (São Paulo Region)   │
│  - Riverpod State Machine           - JwtAuthGuard & LgpdConsentGuard       │
│  - Dynamic Theme (Teal ↔ Indigo)    - PostgresRlsInterceptor (Tenant Scope) │
│  - 2D Canvas Heat Map (Painter)     - TriageModule (5-Step Engine)          │
│  - Drift SQLite Offline Outbox      - ConsistencyEngineService (Antiburla)  │
└───────────────────────┬─────────────────────────────┬───────────────────────┘
                        │ HTTPS (TLS 1.3)             │
                        ▼                             ▼
┌──────────────────────────────────────┐  ┌───────────────────────────────────┐
│       PERSISTENCE & CACHE TIER       │  │        EXTERNAL AI & CLOUD        │
├──────────────────────────────────────┤  ├───────────────────────────────────┤
│ PostgreSQL 16 (São Paulo Region)     │  │ Google Gemini 1.5 Flash           │
│ - Engine-level Row-Level Security    │  │ - Strict JSON Schema Mode (<1.2s) │
│ - 14-Day Temporal B-Tree Indices     │  │ AWS Textract / Cloud Vision OCR   │
│ Redis 7 Cluster                      │  │ - Tabular Lab Extraction          │
│ - Semantic symptom cache (<25ms)     │  │ S3 / GCS Storage Bucket (SSE-KMS) │
│ - BullMQ background job queues       │  │ - Private presigned uploads       │
└──────────────────────────────────────┘  └───────────────────────────────────┘
```

**Major components:**
1. **Flutter Mobile Client & Riverpod State Layer:** Cross-platform mobile client providing 60fps gesture navigation, Material 3 dynamic color tweening between Soft Indigo and Clinical Teal, 2D vector anatomical canvas painting, and Drift SQLite outbox synchronization.
2. **NestJS Modular API & RLS Security Interceptor:** Core application gateway validating JWT claims, managing LGPD consent records, and injecting tenant context (`app.current_user_id`) into every database transaction before query execution.
3. **Deterministic Safety Engine & Emergency Interceptor:** Dual-enforced clinical safety layer executing hardcoded red-flag rules (MTS/ESI Level 1–2 criteria) both locally on Flutter (`PopScope` locked) and synchronously on NestJS, halting triage immediately upon severe symptom detection.
4. **AI Symptom Classifier & Disambiguator:** Google Gemini 1.5 Flash client executing constrained JSON Schema generation within <1.2s to map lay symptoms across the 19 standard categories and disambiguate somatic vs. psychosomatic presentations.
5. **14-Day Temporal Antiburla Engine:** Clinical consistency evaluator querying PostgreSQL temporal indices `(user_id, recorded_at DESC)` to identify conflicting onset dates or contradictory severity claims, returning empathetic clarification prompts.
6. **Decoupled Lab Exam Processing Pipeline:** Asynchronous BullMQ background worker system consuming uploaded lab exam PDFs from encrypted S3 storage, running OCR layout extraction, and calling Gemini 1.5 Flash to extract structured biomarker key-value pairs.

---

### Critical Pitfalls

1. **The Clinical Safety Dilemma (Missed Red Flags vs. Paralyzing Over-Triage):**  
   *Risk:* Pure LLM triage fails to identify atypical acute life-threatening presentations (under-triage / false negatives), or overly blunt regex keyword filters repeatedly trigger emergency modals for benign complaints (over-triage / false alarms), destroying retention.  
   *How to avoid:* Implement a **Dual-Layer Triage Safety Architecture**. Layer 1 is a hardcoded, deterministic rule gate running locally and synchronously (<50ms) implementing validated MTS/ESI Level 1–2 criteria before any LLM prompt is assembled. Layer 2 executes calibrated LLM scoring benchmarked against a validated CI/CD test bank of 250+ clinical vignettes, requiring 100% sensitivity on Level 4–5 emergencies and >85% specificity on non-emergencies.

2. **Diagnostic Overshadowing & Psychosomatic Confusion:**  
   *Risk:* The AI anchors on the user's emotional narrative (e.g., severe panic, work burnout) and misattributes acute somatic disease (myocardial infarction, pulmonary embolism, asthma exacerbation) to "anxiety" or "somatization".  
   *How to avoid:* Enforce the clinical principle of **"Organic Primacy"**. Physical pathology rule-outs are mandatory: any physical symptom reported during emotional triage automatically spawns a shadow clinical check against the relevant anatomical system. A somatic complaint can never be classified as purely psychogenic without passing mandatory organic exclusion criteria. Dashboards display *correlation*, never definitive *causation*.

3. **Antiburla False Positives & Antagonistic Clarification UX:**  
   *Risk:* The 14-day temporal engine treats natural physiological symptom fluctuations (episodic migraines, IBS, asthma flares) as "inconsistency" or "lying", confronting the user with accusatory fraud-detection dialogs that cause user churn.  
   *How to avoid:* Partition historical data into **Immutable Chronology** (onset dates, trauma locations) vs. **Fluctuating State Variables** (intensity, pain quality, emotional state). Frame all clarification prompts empathetically as proactive clinical care (e.g., *"We noticed you logged similar discomfort 5 days ago. Is today a continuation or a new symptom?"*) paired with 1-tap resolution chips (`[Started today]`, `[Previous symptom returned]`).

4. **Decimal Separator & Unit Corruption in Brazilian Lab OCR:**  
   *Risk:* Brazilian lab exams use commas as decimal delimiters (e.g., Potássio `4,2 mEq/L`). Standard OCR engines or LLMs misread `4,2` as `42` (fatal hyperkalemia) or drop the comma, corrupting the patient's permanent health record.  
   *How to avoid:* Implement a **3-Tier Lab Extraction Engine**: (1) Locale-aware geometric OCR parsing preserving comma separators; (2) Hardcoded biological plausibility boundary checks (e.g., Potassium >15 mEq/L flagged as impossible); (3) **MANDATORY Human-In-The-Loop (HITL) Verification Screen** in Flutter where the user confirms side-by-side cropped bounding boxes before database persistence.

5. **LGPD "Dados Sensíveis" Leaks via APM, Analytics & Cloud AI:**  
   *Risk:* APM crash reporters (Sentry), product analytics (Mixpanel, PostHog), or cloud AI logs inadvertently capture raw clinical text, psychological notes, or biomarker values, resulting in severe ANPD regulatory penalties (up to R$ 50M).  
   *How to avoid:* Enforce a strict **Zero-Health Telemetry Policy** scrubbing all clinical text and query parameters from Sentry/analytics; configure cloud AI providers (Google Cloud Vertex AI) under Enterprise agreements with Zero Data Retention (ZDR); host all database and object storage in the São Paulo region (`sa-east-1`); and enforce PostgreSQL Row-Level Security on every clinical table.

---

## Implications for Roadmap

Based on research dependencies, technical constraints, and risk mitigation priorities, the project must be executed in seven sequential phases.

### Phase 1: Core Foundation, Persistence & LGPD Security Baseline
**Rationale:** Medical platforms handling sensitive personal health data (LGPD Art. 11) must establish tenant isolation and regional data governance before any symptom data is ingested. Setting up PostgreSQL Row-Level Security, secure mobile storage, and scrubbed telemetry upfront prevents expensive re-architectures later.  
**Delivers:** Dockerized local development stack (PostgreSQL 16, Redis 7, LocalStack S3); Drizzle ORM schema with native PostgreSQL RLS policies; NestJS 12 Fastify backend with `JwtAuthGuard`, `LgpdConsentGuard`, and transactional `PostgresRlsInterceptor`; Flutter 3.29 baseline with Riverpod 3.4.3, Material 3, Dio client, and `flutter_secure_storage`; CI/CD automated cross-tenant security regression tests; Sentry/APM PII/PHI redaction scrubbers.  
**Addresses:** RNF-002 (Data Privacy & LGPD Compliance), foundational client architecture for RNF-003.  
**Avoids:** Pitfall 7 (LGPD Dados Sensíveis leaks, insecure storage & RLS violations).

### Phase 2: Deterministic Safety Engine, Emergency Net & Dynamic Theming
**Rationale:** Clinical safety is the single highest liability risk. The zero-failure Level 4–5 emergency interceptor, telephony integration, and persistent red screen modal must be operational and verified before building user-facing triage questions.  
**Delivers:** Local and backend deterministic red-flag clinical evaluation engine (MTS/ESI Level 1–2 criteria); non-dismissible full-screen Emergency Red Modal (`#D32F2F`) locked via `PopScope(canPop: false)` with 1-tap dialer for Brazilian emergency services (`tel:192` SAMU, `tel:188` CVV, `tel:193` Bombeiros) and nearest emergency facility locator; dynamic visual state switching between Soft Indigo (`#3F51B5`) and Clinical Teal (`#00796B`) with 300ms theme tweening; Riverpod `TriageStateMachine` with `autoDispose` session lifecycle management.  
**Addresses:** RF-006 (Unified Emergency Safety Net), partial RF-002 (visual state switching).  
**Uses:** `flutter_riverpod`, `url_launcher`, Material 3 design tokens.  
**Avoids:** Pitfall 1 (Missed red flags vs paralyzing over-triage), Pitfall 8 (Flutter navigation desynchronization and leaked state in emergency net).

### Phase 3: Conversational Daily Check-In, 5-Step Triage & Adaptive UX
**Rationale:** Establishes the daily habit loop and standardized 5-step clinical decision tree across all 19 categories while preventing survey fatigue through progressive disclosure.  
**Delivers:** RF-001 "How are you feeling today?" conversational entry screen with fast-tap quick chips; adaptive two-tier intake funnel (Tier 1: <10s daily wellness pulse vs. Tier 2: deep 5-step triage); complete 5-step decision tree (Nature → Persistence → Intensity → Triggers → Outcome) implemented across 12 physical systems and 7 emotional dimensions; standardized 4-tier disposition categorization (Self-Care, Routine, Urgent, Emergency); non-diagnostic regulatory disclaimers; optimistic local session auto-save.  
**Addresses:** RF-001 (Unified Entry Point), RF-002 (Parallel 5-Step Triage Tree), non-diagnostic regulatory guardrails.  
**Avoids:** Pitfall 6 (Triage friction & survey fatigue crippling daily check-in retention).

### Phase 4: AI Symptom Classifier, Psychosomatic Mapping & 14-Day Antiburla Engine
**Rationale:** With structured triage and persistence established, the AI classification, Brazilian idiom translation, and temporal consistency engines can be integrated and benchmarked under clinical validation suites.  
**Delivers:** Google Gemini 1.5 Flash integration via `@google/genai` with strict JSON Schema outputs meeting the sub-2s SLA (RNF-001); Redis semantic query cache for frequent symptoms (<25ms P99); somatic and psychosomatic mapping engine for Brazilian Portuguese distress idioms (*"nó na garganta"*, *"peito apertado"*) with mandatory "Organic Primacy" physical rule-outs; 14-day temporal consistency engine ("Antiburla") querying PostgreSQL composite indices `(user_id, recorded_at DESC)`; empathetic clarification modals with 1-tap resolution chips; automated CI/CD golden test suite with 250+ clinical vignettes (100% emergency sensitivity gate).  
**Addresses:** RF-003 (14-Day Temporal Consistency Engine), RF-004 (Somatic & Psychosomatic Symptom Mapping), RNF-001 (Sub-2s Classification Latency).  
**Uses:** `@google/genai`, Redis semantic cache, PostgreSQL temporal queries.  
**Avoids:** Pitfall 2 (Diagnostic overshadowing & psychosomatic confusion), Pitfall 3 (Antiburla false positives & antagonistic UX), Pitfall 4 (LLM hallucination, schema drift & non-determinism).

### Phase 5: Longitudinal Dashboards, 2D Anatomical Heat Map & Offline Outbox
**Rationale:** Visualizing pain and emotional trajectories requires aggregated longitudinal data from completed triage sessions and resilient offline caching.  
**Delivers:** Interactive Flutter `CustomPainter` 2D Anatomical Body Heat Map (front/back silhouette, 12 anatomical systems, normalized vector coordinate hit-testing, chromatic yellow-to-red radial gradient, `RepaintBoundary` rendering optimization); 7-day emotional multi-line trend graph across 7 dimensions (`fl_chart`) with physical symptom overlay badges; Drift SQLite local database with transactional outbox queue (`connectivity_plus`) for offline triage check-in caching and automatic background sync.  
**Addresses:** RF-008 (Dual-View Historical Dashboards), offline mobile resilience.  
**Uses:** `fl_chart`, `flutter_svg`, `drift`, `connectivity_plus`.  
**Avoids:** Full 2D heatmap re-render performance traps and offline data loss.

### Phase 6: Decoupled Lab Exam Processing Pipeline & Biomarker Registry
**Rationale:** Lab report extraction is an asynchronous subsystem that enriches the patient profile with objective biomarker data without impacting daily triage performance.  
**Delivers:** Direct-to-storage presigned upload workflow (S3/GCS with SSE-KMS encryption); Redis BullMQ queue (`lab-exam-queue`) and background worker consumers; Google Cloud Vision / AWS Textract OCR integration specialized in Brazilian tabular lab layouts; token-efficient Gemini 1.5 Flash structured biomarker extractor; physiological plausibility validation bounds (e.g., Potassium, Glucose limits); mandatory side-by-side Human-In-The-Loop (HITL) review and confirmation screen in Flutter; PostgreSQL `clinical_biomarkers` storage; FCM push notification upon completion.  
**Addresses:** RF-012 (Decoupled Lab Exam Biomarker Processing Pipeline).  
**Uses:** `@google-cloud/vision` / AWS Textract, `bullmq`, `@nestjs/bullmq`, `@aws-sdk/s3-request-presigner`.  
**Avoids:** Pitfall 5 (Decimal separator & unit misinterpretation in lab biomarker OCR), Anti-Pattern 1 (synchronous multimodal LLM calls in HTTP threads).

### Phase 7: Preventive Health Guidance, Clinical PDF Export & Production Hardening
**Rationale:** Final content integration, outpatient clinical utility, and end-to-end load/latency benchmarking ensure regulatory compliance and production reliability before release.  
**Delivers:** RF-009 curated library of context-aware preventive health micro-interventions matched to triage findings; one-click "Doctor's Brief" SBAR-formatted clinical PDF export summarizing 14-day history and abnormal biomarkers; end-to-end latency load testing under simulated 4G mobile conditions confirming sub-2s P99 classification; ANPD/LGPD compliance audit trail sign-off.  
**Addresses:** RF-009 (Curated Guidance & Preventive Health Articles), Doctor's Brief SBAR PDF, production quality gates.  
**Avoids:** Production latency violations and regulatory audit failures.

---

### Phase Ordering Rationale

- **Security & Data Isolation First (Phase 1):** In healthcare platforms governed by LGPD (Art. 11), Row-Level Security cannot be bolted on as an afterthought. Enforcing PostgreSQL RLS and setting up secure token storage in Phase 1 guarantees that all subsequent feature modules are developed within an audited security sandbox.
- **Safety Net Before Triage Questions (Phase 2):** Clinical liability requires that the emergency red screen modal and deterministic red-flag evaluation exist before interactive questioning is presented to users. This guarantees that test sessions and early beta testers can never get stuck in a broken triage loop during an acute crisis.
- **Structured Data Precedes AI Classification (Phase 3 before Phase 4):** Standardizing the 5-step decision tree and establishing normalized database schemas enables the AI classifier and Antiburla temporal scanning engine to operate against predictable data structures.
- **Analytics Require Data History (Phase 4 before Phase 5):** The 2D Anatomical Body Heat Map and 7-day emotional graphs rely on aggregated historical check-in records and somatic-emotional correlation matrices created in Phases 3 and 4.
- **Decoupled Lab Ingestion Follows Core Triage (Phase 6):** Lab exam OCR is an asynchronous background subsystem. Decoupling it into Phase 6 prevents complex multi-page document parsing and external OCR dependencies from delaying the core check-in experience.
- **Hardening Concludes the Sequence (Phase 7):** Load testing, latency tuning, and regulatory audit verification require all application components to be operational under realistic load.

---

### Research Flags

**Phases needing deeper investigation during phase planning:**
- **Phase 2 (Emergency Safety Net & Telephony):** Needs investigation into device-specific telephony restrictions (e.g., Wi-Fi only tablets, Android permission models) and verifying local fallback mechanisms (displaying high-contrast emergency numbers and launching map routes to nearby emergency rooms when `canLaunchUrl('tel:192')` returns false).
- **Phase 4 (AI Classifier & Antiburla Heuristics):** High algorithmic complexity. Requires detailed prompt engineering for Portuguese medical disambiguation, Redis semantic cache key hashing, and mathematical tuning of contradiction heuristics to prevent false-positive alarms on fluctuating chronic illnesses (migraines, IBS).
- **Phase 6 (Decoupled Lab Exam Processing Pipeline):** High layout variability across Brazilian diagnostic laboratories (DASA, Fleury, Hermes Pardini, Einstein). Requires testing sample PDFs to ensure coordinate table extraction reliably pairs biomarker names, numeric values, units, and reference ranges.

**Phases with standard patterns (skip dedicated research phase):**
- **Phase 1 (Core Foundation, Persistence & Security):** Well-documented patterns for NestJS Fastify setup, Drizzle ORM PostgreSQL migrations, and PostgreSQL Row-Level Security.
- **Phase 3 (Conversational Entry & 5-Step Triage Tree):** Standard Riverpod state machine, responsive Material 3 layouts, and form wizard components.
- **Phase 5 (Longitudinal Dashboards & Offline Outbox):** Standard Flutter `CustomPainter` vector operations, `fl_chart` integration, and Drift SQLite outbox synchronization.
- **Phase 7 (Preventive Guidance & PDF Export):** Standard static markdown content rendering and PDF generation using `pdf` / `printing` Flutter packages.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Stack** | HIGH | All library versions verified against live `pub.dev` and `npm` registries as of September 2026. Flutter 3.29+, Riverpod 3.4.3, NestJS 12, Fastify, Drizzle ORM 0.45, PostgreSQL 16/17, and unified `@google/genai` 2.22 SDK are fully verified for compatibility. |
| **Features** | HIGH | Grounded in validated clinical triage systems (Manchester Triage System, Emergency Severity Index), Brazilian regulatory frameworks (LGPD Lei 13.709/2018, CFM Res. 2.314/2022, Anvisa RDC 657/2022), and benchmarked against industry leaders (Ada Health, Infermedica, Bearable, Function Health). |
| **Architecture** | HIGH | Thoroughly articulated data flows, component boundaries, Riverpod state machine models, decoupled BullMQ asynchronous worker queues, and PostgreSQL RLS session context injection patterns. |
| **Pitfalls** | HIGH | Comprehensive analysis of domain-specific clinical, regulatory, and technical failure modes, including diagnostic overshadowing, Brazilian comma-decimal OCR corruption, Antiburla false alarms, survey fatigue, and emergency navigation lockout. |

**Overall confidence:** HIGH

---

### Gaps to Address

- **Brazilian Lab Layout Heterogeneity:** Diagnostic laboratory reports in Brazil lack a unified digital standard. While Fleury, DASA, and Pardini follow structured tabular layouts, smaller regional clinics issue unstructured or graphical PDFs.  
  *Mitigation during execution:* Enforce the decoupled OCR + LLM schema pipeline with physiological bounds checking and make the side-by-side Human-In-The-Loop (HITL) review screen mandatory before database commit.
- **Antiburla Heuristic Calibration on Chronic Illnesses:** Defining the exact mathematical boundary between a contradictory onset claim and a fluctuating episodic flare-up (e.g., fibromyalgia, migraines) requires ongoing calibration.  
  *Mitigation during execution:* In Phase 4, test the consistency engine against synthetic longitudinal check-in datasets covering episodic, chronic, and acute clinical progressions; provide 1-tap clarification chips to prevent user frustration.
- **Google Cloud Vertex AI Enterprise Data Residency in Brazil:** Ensuring Gemini 1.5 Flash inference can be executed under a Zero Data Retention (ZDR) agreement with Brazilian regional data residency.  
  *Mitigation during execution:* Verify enterprise Google Cloud Vertex AI endpoint configurations in `southamerica-east1` (São Paulo) or enforce client/backend token redaction before inference.

---

## Sources

### Primary (HIGH confidence)
- `pub.dev` Official Package Registry (September 2026) — Verified live package versions: `flutter_riverpod` (3.4.3), `go_router` (18.0.1), `dio` (5.11.1), `fl_chart` (1.2.0), `flutter_secure_storage` (11.1.1), `drift` (2.22.x), `flutter_svg` (2.3.0), `url_launcher` (6.3.2).
- `npm` Official Package Registry via jsDelivr CDN (September 2026) — Verified live versions: `@nestjs/core` (12.0.1), `@nestjs/platform-fastify` (12.0.1), `drizzle-orm` (0.45.2), `bullmq` (6.3.4), `@nestjs/bullmq` (12.0.0), `@google/genai` (2.22.0), `@google-cloud/vision` (6.1.0), `zod` (4.6.4).
- Google Gen AI SDK Documentation (`@google/genai`) — Verified migration to unified SDK and structured JSON Schema capabilities (`responseSchema`) for Gemini 1.5 Flash.
- PostgreSQL Official Documentation on Row-Level Security & GiST (`current_setting('app.current_user_id', true)` and `btree_gist` index behaviors).
- Brazilian General Data Protection Law (LGPD - Lei nº 13.709/2018, Art. 11 - Tratamento de Dados Pessoais Sensíveis de Saúde).
- Conselho Federal de Medicina (CFM Resolução nº 2.314/2022) & Anvisa (RDC nº 657/2022) — Regulatory boundaries for digital triage, tele-orientation, and Software as a Medical Device (SaMD).

### Secondary (MEDIUM confidence)
- Manchester Triage System (MTS) & Emergency Severity Index (ESI) Implementation Handbooks — Clinical standards for emergency risk stratification and red-flag discriminators.
- Ada Health, Infermedica, Bearable, and Function Health Architectural Benchmarks — Analysis of symptom assessment models, daily check-in fatigue, and biomarker panel ingestion workflows.
- British Medical Journal (BMJ) & JAMA Network Open — Clinical evaluations of conversational AI symptom checker safety, sensitivity, and diagnostic accuracy.

---
*Research completed: 2026-09-13*  
*Ready for roadmap: yes*
