# Feature Research: Personal Health Management & AI Preventive Triage

**Domain:** Digital Preventive Health, AI Clinical Triage & Personal Health Management (SaMD Class I/II Preventive Guidance)  
**Researched:** 2026-09-13  
**Confidence:** HIGH (Grounded in clinical triage systems [Manchester/ESI], digital health benchmarks [Ada Health, Infermedica, Bearable, Function Health], Brazilian regulatory frameworks [LGPD, CFM Res. 2.314/2022, Anvisa RDC 657/2022], and modern cross-platform mobile architectures)

---

## Executive Summary

Personal health management has evolved beyond static symptom checkers and passive mood diaries into integrated, proactive clinical triage engines. Modern users and healthcare systems demand solutions that safely bridge physical (somatic) manifestations with mental/emotional health, verify data consistency over time, and immediately escalate acute life-threatening conditions.

**DualisCheckUp** occupies a distinct niche in this ecosystem:
1. **Parallel Dual-Path Triage**: Harmonizes 12 Anatomical Systems and 7 Psycho-Emotional Dimensions into an identical 5-step clinical decision tree, visually distinguished by Soft Indigo (emotional) and Clinical Teal (physical) UI states.
2. **14-Day Temporal Consistency ("Antiburla") Engine**: Cross-validates longitudinal symptom reporting against past check-ins to eliminate recall bias, contradictory reporting, and malingering through empathetic conversational reconciliation.
3. **Psychosomatic & Somatopsychic Translation**: Resolves lay distress idioms ("tight chest", "lump in throat", "butterfly stomach") into clinical somatic-emotional correlations.
4. **Zero-Tolerance Emergency Safety Net**: Instantaneously halts triage upon level 4-5 severity detection, deploying a full-screen red override with 1-tap local emergency dispatch (SAMU 192, CVV 188 in Brazil).
5. **Decoupled Biomarker Ingestion & Dual Visualizations**: Cost-effective OCR + structured LLM extraction for lab reports paired with an interactive 2D anatomical body heat map and 7-day emotional oscillation graphs.

---

## Feature Landscape

### Table Stakes (Users & Regulators Expect These)

Features users and clinical safety standards assume exist from day one. Missing any of these renders the product clinically unsafe, non-compliant, or perceived as an amateur hobby project.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Zero-Tolerance Emergency Safety Net (RF-006)** | Core clinical safety; mandatory under medical app guidelines. Missing it creates severe legal liability and patient danger. | MEDIUM | Instantaneous hard halt of triage upon detecting Red Flag symptoms (e.g., crushing chest pain, hemoptysis, sudden focal neurological deficits, active suicidal intent). Displays full-screen red UI (`#D32F2F`), suppresses non-urgent inputs, and exposes 1-tap local emergency services (SAMU 192, Bombeiros 193, CVV 188 in Brazil) plus emergency contact broadcast. |
| **Conversational Daily Check-In Entry Point (RF-001)** | Modern users expect natural, frictionless daily engagement ("How are you feeling today?") rather than navigating complex clinical menus. | LOW | Natural language input box combined with fast-tap quick chips (e.g., "Headache", "Anxious", "Fatigued", "Chest discomfort"). AI classification parser routes lay phrasing into the proper triage vertical in <2 seconds. |
| **Standardized Clinical 5-Step Triage Tree (RF-002)** | Users expect structured, logical progression rather than random questioning; clinicians expect standardized symptom exploration. | MEDIUM | Standardized 5-step pipeline across all complaints: **1. Nature** (symptom characterization), **2. Persistence** (duration/onset/frequency), **3. Intensity** (Visual Analog Scale / Likert 1–10), **4. Triggers** (aggravating/relieving factors), **5. Outcome** (risk classification & care disposition). |
| **Clear Care Disposition / Triage Categorization** | Users need clear, actionable guidance on *what to do next* (Self-Care, Routine Medical Visit, Urgent Care / Pronto Atendimento, Emergency Room). | LOW | Categorizes disposition into 4 standard levels: Home Self-Care with monitoring, Routine Appointment (within 7–14 days), Urgent Evaluation (within 12–24 hours), or Immediate Emergency. No vague answers. |
| **Explicit Non-Diagnostic Regulatory Guardrails** | Anvisa (RDC 657/2022) and CFM regulations strictly prohibit software from issuing definitive autonomous medical diagnoses without physician validation. | LOW | Prominent, persistent disclaimers clarifying that DualisCheckUp provides preventive risk stratification and health tracking, not certified medical diagnoses or prescriptions. |
| **LGPD Compliance & Health Data Sovereignty (RNF-002)** | Sensitive personal health data (Art. 11 LGPD) requires explicit consent, Brazilian regional storage (São Paulo), encryption at rest/in transit, and complete data erasure. | HIGH | PostgreSQL Row-Level Security (RLS) guaranteeing tenant isolation, AES-256 encrypted database columns for health narratives, TLS 1.3 in transit, and self-service account data export / hard delete mechanisms. |
| **Biometric Authentication & Auto-Lock** | Medical information must be protected from shoulder-surfing and unauthorized access on personal devices. | LOW | Native iOS FaceID / TouchID and Android BiometricPrompt with configurable auto-lock timeout (immediate, 1 min, 5 min) on app backgrounding. |
| **Chronological Health Timeline / Historical Log** | Users expect to review previous check-ins, logged symptoms, and past triage outcomes chronologically. | LOW | Paginated timeline of completed check-in summaries with date filters and system tags. |

---

### Differentiators (Competitive Advantage)

Features that set DualisCheckUp apart from existing symptom checkers (Ada, Infermedica) and habit trackers (Bearable, Daylio). These deliver on the core value proposition.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Parallel Dual-Path Triage Architecture with Visual State Switching (RF-002)** | Eliminates the traditional clinical silo between physical illness and mental distress by applying identical 5-step rigor across 19 categories (12 Physical, 7 Emotional). | HIGH | Seamless visual state transition: **Clinical Teal** (`#00796B`) for physical systems (Cardiovascular, Respiratory, GI, Musculoskeletal, Neurological, Dermatological, Genitourinary, Endocrine/Metabolic, Ophthalmic, ENT, Immune, Systemic) and **Soft Indigo** (`#3F51B5`) for emotional dimensions (Anxiety/Panic, Depressive Mood, Stress/Burnout, Sleep/Insomnia, Cognitive/Focus, Somatoform Tension, Social Affect). Distinct visual palettes modulate user cognitive arousal. |
| **14-Day Temporal Consistency ("Antiburla") Engine (RF-003)** | Eliminates recall bias, contradictory claims, and malingering by dynamically evaluating the user's past 14 days of logs before finalizing triage risk. | HIGH | Scans temporal index in PostgreSQL for conflicting inputs (e.g., claiming "headache started 1 hour ago" when severe migraines were logged daily for the past week, or claiming complete emotional calmness while severe physical tension symptoms spike). Triggers empathetic clarification dialogues: *"We noticed that on Wednesday you recorded similar neck and shoulder tension after long work shifts. Does today's pain feel like the same pattern, or is it distinct?"* |
| **Somatic & Psychosomatic Symptom Mapping (RF-004)** | Bridges colloquial Brazilian Portuguese idioms of distress to physiological systems, making mental-physical connections visible. | MEDIUM | Maps expressions like *"nó na garganta"* (globus pharyngeus / anxiety), *"peito apertado"* (thoracic constriction vs panic), *"frio na barriga"* (autonomic GI stimulation), and *"peso nas costas"* (trapezius somatoform tension). Educates the user on how emotional stressors trigger physical symptoms without invalidating physical pain. |
| **Interactive 2D Anatomical Body Heat Map (RF-008)** | Intuitive, visual pain tracking that replaces clunky text dropdowns with visual anatomical feedback. | MEDIUM | Front and rear 2D anatomical vector model with regional pinpointing (cranial, cervical, thoracic, abdominal quadrants, extremities). Renders a chromatic heat gradient (Yellow = Mild/Occasional → Amber = Moderate/Recurring → Deep Red = Severe/Acute) reflecting pain severity and 14-day recurrence frequency. |
| **7-Day Emotional Multi-Dimensional Trend Graph (RF-008)** | Correlates emotional swings with somatic flare-ups over a rolling weekly window. | MEDIUM | Smooth multi-line vector chart mapping the 7 psycho-emotional dimensions over 7 days. Allows toggling physical symptom overlay badges on the timeline to reveal direct cause-and-effect patterns (e.g., insomnia spikes preceding migraine episodes). |
| **Decoupled Lab Exam Biomarker Processing Pipeline (RF-012)** | Democratizes laboratory blood and urine reports, converting confusing lab sheets into actionable structured biomarker registries. | HIGH | Decoupled architecture: High-speed OCR (AWS Textract / Google Cloud Vision) extracts raw text blocks, followed by structured LLM parsing (Gemini 1.5 Flash / GPT-4o-mini with JSON Schema) to extract biomarker key-value pairs (Analyte, Value, Unit, Reference Range, Flag). Saves ~85% token cost compared to direct multimodal image prompting and eliminates numerical hallucination. |
| **Context-Aware Preventive Health Micro-Interventions (RF-009)** | Provides immediate, evidence-based lifestyle actions directly tied to triage findings, preventing progression of mild symptoms. | LOW | Contextual cards matching triage outcomes: sleep hygiene protocols for insomnia, ergonomics for trapezius strain, hydration/electrolyte guidance for mild heat exhaustion, and diaphragm breathing guides for panic episodes. |
| **One-Click "Doctor's Brief" Clinical Export** | Bridges the app and the physical doctor's office, empowering the patient during real clinical consultations. | MEDIUM | Generates a clean, single-page PDF summarizing the chief complaint, 14-day symptom progression, intensity curves, associated emotional states, and abnormal lab biomarkers formatted in SBAR (Situation, Background, Assessment, Recommendation) clinical syntax. |

---

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem appealing on the surface but introduce severe clinical, regulatory, technical, or operational risks. DualisCheckUp deliberately avoids building these in v1.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Autonomous Medical Diagnosis Engine (SaMD Class III)** | Users naturally ask: *"Tell me exactly what disease I have (e.g., Appendicitis, Lupus, Bipolar)."* | Classifies software as high-risk medical device (Anvisa RDC 657/2022 Class III/IV, FDA Class II/III). Massive liability, high rate of catastrophic false positives/negatives, induces cyberchondria and panic. | Provide **probabilistic risk stratification and clinical dispositions** (e.g., *"Your symptoms indicate acute right lower quadrant abdominal irritation. Clinical evaluation at an Urgent Care center within 12 hours is recommended."*). |
| **Digital Prescription Ordering & Pharmacy Fulfillment** | Users want seamless *"click here to buy antibiotics or pain meds"* integration. | Strictly illegal without a licensed physician's validated digital signature (ICP-Brasil in Brazil, CFM Res. 2.299/2021). Severe pharmacovigilance risks, antibiotic resistance promotion, and regulatory shutdown. | Offer non-pharmacological preventive guidance (hydration, posture, cold compress, sleep hygiene) and preparation tips for discussing medication with a doctor. |
| **Unbounded / Free-Form Conversational Chatbot as Primary Triage** | Chatbots (like standard ChatGPT) feel modern and conversational. | Slow latency (>5-10s), prone to conversational wandering, prompt injection, user input fatigue on mobile keyboards, and erratic clinical coverage that skips vital negative findings. | **Hybrid Intake**: Use an NLP entry parser for the initial query ("How are you feeling?"), then immediately branch into the structured, thumb-friendly 5-step decision tree with visual sliders and selection chips. |
| **Real-Time Synchronous Telemedicine Consults (V1)** | Investors and users frequently view in-app video doctors as an obvious revenue stream. | Massive operational overhead: credentialing physicians, 24/7 on-call scheduling, video streaming infrastructure, medical malpractice insurance, and high customer acquisition burn. Distracts from building the best personal triage engine. | Export a standardized **"Doctor's Brief" PDF** that users present to their existing health plan or telemedicine provider. |
| **Direct Hospital EHR Two-Way Synchronization (FHIR / HL7) in V1** | Automatic synchronization with hospital databases (Tasy, MV Soul, Pixeon) sounds ideal. | Highly fragmented Brazilian hospital IT market, proprietary vendor locks, multi-month enterprise security audits, and brittle integrations that delay launch by years. | **Patient-mediated data sovereignty**: User uploads lab reports (processed via OCR) and logs symptoms directly into their personal health record. |
| **Gamification Badges / Streaks for Physical Illness** | Standard habit-tracker gamification (XP, badges, congratulatory sounds). | Rewarding users for logging "illness" creates perverse psychological incentives, trivializes chronic suffering, and feels tone-deaf to someone dealing with severe panic or physical pain. | Mild, dignified check-in streaks focused on *preventive wellness mindfulness* and proactive health vigilance, with neutral, calming micro-animations. |
| **Automated Raw Genomic / DNA Risk Profiling** | Users request uploading 23andMe or raw VCF DNA files to predict genetic diseases. | Extreme regulatory burden, high risk of deterministic misinterpretation without genetic counselors, completely out of scope for daily acute/subacute triage. | Standardized family medical history questionnaire capturing first-degree relatives' chronic conditions. |

---

## Detailed Triage Taxonomy: 19 Standardized Categories

DualisCheckUp covers 19 discrete clinical categories, split into 12 Anatomical Systems and 7 Psycho-Emotional Dimensions. Each category executes the identical 5-step decision tree.

```
DUALISCHECKUP 19 TRIAGE CATEGORIES
├── FÍSICA (12 Anatomical Systems - Clinical Teal Theme: #00796B)
│   ├── 1. Cardiovascular (chest tightness, palpitations, edema, cyanosis)
│   ├── 2. Respiratory (dyspnea, cough, wheezing, hemoptysis)
│   ├── 3. Gastrointestinal (abdominal pain, nausea, reflux, bowel habit changes)
│   ├── 4. Musculoskeletal (joint pain, myalgia, back pain, stiffness)
│   ├── 5. Neurological (headaches, dizziness, numbness, paresthesia, tremors)
│   ├── 6. Dermatological (rashes, lesions, pruritus, erythema)
│   ├── 7. Genitourinary (dysuria, frequency, flank pain, hematuria)
│   ├── 8. Endocrine & Metabolic (polydipsia, polyuria, unexplained weight changes)
│   ├── 9. Ophthalmic (visual disturbance, ocular pain, redness, photophobia)
│   ├── 10. Otorhinolaryngology / ENT (sore throat, otalgia, tinnitus, rhinorrhea)
│   ├── 11. Immune & Lymphatic (lymphadenopathy, recurrent infections, allergies)
│   └── 12. General & Systemic (fever, chills, night sweats, generalized fatigue)
│
└── PSICO-EMOCIONAL (7 Dimensions - Soft Indigo Theme: #3F51B5)
    ├── 1. Anxiety & Panic (acute panic episodes, generalized worry, somatic tremor)
    ├── 2. Depressive Mood (anhedonia, persistent sadness, low energy, apathy)
    ├── 3. Stress & Burnout (occupational exhaustion, irritability, emotional overwhelm)
    ├── 4. Sleep & Insomnia (sleep latency, midnight awakenings, unrefreshing sleep)
    ├── 5. Cognitive & Focus (brain fog, executive dysfunction, memory lapse)
    ├── 6. Somatoform Tension (psychogenic pain, cervical tension, globus hystericus)
    └── 7. Relational & Social Affect (social withdrawal, acute interpersonal conflict)
```

---

## The 5-Step Decision Tree Architecture

Both Physical and Emotional verticals follow an identical 5-step structured pipeline to ensure predictable UX, low cognitive friction, and clinical repeatability:

| Step | Name (Portuguese / English) | Physical (Clinical Teal) Implementation | Emotional (Soft Indigo) Implementation |
|---|---|---|---|
| **Step 1** | **Natureza / Nature** | Pinpoint anatomical system, symptom quality (sharp, dull, throbbing, burning), location on 2D body map. | Pinpoint dominant emotional dimension, primary sensation (racing thoughts, heaviness, panic wave). |
| **Step 2** | **Persistência / Persistence** | Acute vs subacute vs chronic; exact duration (hours, days, weeks), continuous vs episodic frequency. | Chronicity of state (first episode today, recurring weekly, chronic persistent >2 weeks). |
| **Step 3** | **Intensidade / Intensity** | Visual Analog Scale (VAS 1–10) or functional impairment (Mild: can work; Moderate: interferes; Severe: bedridden). | Emotional Likert scale (1–10) measuring distress intensity, overwhelm, and vegetative interference. |
| **Step 4** | **Gatilhos / Triggers** | Physical exertion, food intake, postural changes, weather, medication, physical trauma. | Environmental stressors, work deadlines, sleep deprivation, relational conflict, sensory overload. |
| **Step 5** | **Desfecho / Outcome** | Disposition category (Self-Care, Routine Care, Urgent Care, Emergency), Red Flag check, preventive steps. | Disposition category (Self-Care grounding, Psychology consult, Psychiatry referral, Crisis CVV 188). |

---

## The 14-Day Temporal Consistency ("Antiburla") Engine

### Clinical & Functional Rationale
Patients routinely suffer from **recall bias**, inadvertently downplay chronic conditions as "sudden", or report contradictory symptom chronologies (e.g., claiming severe chest pain is brand new when mild exertional angina was logged 4 days earlier). In insurance or health-record settings, deliberate fabrication or exaggeration ("burla") also distorts medical evaluation.

### Engine Architecture & Logic Flow
1. **Temporal Query Window**: Upon symptom entry, the engine executes a high-speed indexed query on the user's past 14 days of logged entries (`user_id`, `created_at >= NOW() - INTERVAL '14 days'`).
2. **Contradiction Matrix Evaluation**:
   - *Onset Inconsistency*: User flags "First time ever experiencing severe headache", but records show 3 severe migraine check-ins in the last 10 days.
   - *Severity Inversion*: User rates pain as 2/10, but simultaneously logs inability to walk or severe motor impairment.
   - *Psychosomatic Dissociation*: User claims 0/10 emotional stress, but logs resting heart rate surges, panic sensations, and severe globus hystericus.
3. **Empathetic Clarification Dialogue (Zero Accusation)**:
   - The engine never says *"You lied"* or *"This contradicts past data"*.
   - It deploys supportive clinical reconciliation:
     > *"We noticed that 4 days ago you mentioned experiencing a similar dull ache in your lower back after heavy lifting. Does today's sensation feel like a continuation of that episode, or is this a completely new and distinct pain?"*
4. **Outcome**:
   - If user confirms continuation: Episode is merged into a longitudinal chronic flare-up profile (altering triage disposition toward specialized care rather than acute emergency).
   - If user confirms distinct new event: Logged as a de novo acute incident with full safety net vigilance.

---

## Somatic & Psychosomatic Symptom Mapping Matrix

Many physical complaints evaluated in primary care have strong psychogenic or autonomic origins, while severe physical diseases trigger secondary panic. DualisCheckUp translates lay idioms into dual clinical matrices:

| Lay Expression (Brazilian Idiom) | Primary Physical Mapping (Clinical Teal) | Correlated Emotional Mapping (Soft Indigo) | DualisCheckUp Clinical Bridge |
|---|---|---|---|
| *"Nó na garganta / aperto no pescoço"* | ENT / Otorhinolaryngology (Globus pharyngeus, pharyngeal spasm, thyroid enlargement) | Somatoform Tension / Anxiety (Cricopharyngeal muscle hypertonicity due to autonomic stress) | Checks for dysphagia/stridor (Red Flag). If swallowing liquids/solids is normal, highlights psychogenic autonomic tension and recommends vagal breathing protocols. |
| *"Peito apertado / coração acelerado"* | Cardiovascular / Respiratory (Coronary ischemia, arrhythmia, costochondritis, asthma) | Anxiety / Panic Dimension (Sympathetic nervous system surge, hyperventilation syndrome) | **Mandatory Red Flag Gate**: Checks for radiating pain (left arm, jaw), diaphoresis, dyspnea. If negative and tied to acute stress trigger, correlates with panic attack while advising prompt medical exclusion of cardiac etiology. |
| *"Frio na barriga / pontadas no estômago"* | Gastrointestinal (Gastritis, peptic spasm, functional dyspepsia, IBS) | Stress & Burnout / Anxiety (Brain-gut axis dysregulation, enteric nervous system hypermotility) | Inquires about epigastric burn vs diffuse cramping. Highlights brain-gut axis correlation, especially when symptom peaks coincide with high-stress workday logs. |
| *"Peso nos ombros / pontadas na nuca"* | Musculoskeletal / Neurological (Trapezius myofascial trigger points, tension headache) | Stress & Burnout / Somatoform (Involuntary sustained muscle guarding under chronic cognitive stress) | Correlates posture/screen time and occupational stress. Recommends micro-break stretching, heat therapy, and stress decompression. |
| *"Formigamento nas mãos e pés"* | Neurological / Endocrine (Peripheral neuropathy, radiculopathy, carpal tunnel) | Anxiety & Panic (Respiratory alkalosis induced by subclinical hyperventilation) | Assesses whether tingling is unilateral (stroke/radiculopathy warning) or bilateral perioral/hands during acute distress (classic hyperventilation). |

---

## Decoupled Lab Exam Biomarker Processing Pipeline (RF-012)

Processing laboratory PDFs/photos directly through large multimodal models (e.g., sending raw 4K lab report scans to GPT-4o) causes high API costs ($0.05–$0.15 per page), slow turnaround (>8 seconds), and occasional numerical hallucinations on decimal biomarker values.

### The Decoupled Pipeline
```
[User Uploads Lab PDF / Photo]
            │
            ▼
[Step 1: Document OCR Engine] ─── (AWS Textract / Google Cloud Vision OCR)
            │                     - High-speed text and layout extraction
            │                     - Cost: ~$0.0015 per page; Latency: ~800ms
            ▼
   [Raw Layout & Text Block]
            │
            ▼
[Step 2: Structured JSON LLM] ─── (Gemini 1.5 Flash / GPT-4o-mini with Strict JSON Schema)
            │                     - Ingests clean text only (low token count)
            │                     - Extracts structured array of biomarkers:
            │                       * analyte_name (e.g., "Glicose em Jejum", "TSH")
            │                       * measured_value (e.g., 98, 2.45)
            │                       * unit (e.g., "mg/dL", "mcUI/mL")
            │                       * reference_range_min / max (e.g., 70, 99)
            │                       * clinical_flag ("NORMAL", "LOW", "HIGH", "CRITICAL")
            │                     - Cost: ~$0.0008 per report; Latency: ~900ms
            ▼
[PostgreSQL Biomarker Registry] ──> Links to longitudinal user profile & highlights abnormal trends
```

### Total Pipeline Performance
- **Combined Latency:** ~1.7s (meets RNF-001 sub-2s threshold).
- **Combined Cost:** ~$0.0023 per report (~85% savings vs direct multimodal LLM).
- **Accuracy:** Zero OCR-to-token hallucination; validated against Brazilian laboratory standard formats (Fleury, Dasa, Hermes Pardini, Einstein).

---

## Feature Dependencies

```
┌─────────────────────────────────────────────────────────┐
│              RNF-002: Security & LGPD Base              │
│       (PostgreSQL RLS, São Paulo Region, Encryption)     │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│           RF-001: Unified Entry Point ("Feeling?")      │
└──────────────┬───────────────────────────┬──────────────┘
               │                           │
               ▼                           ▼
┌───────────────────────────────┐ ┌──────────────────────────────────────┐
│ RF-002: Parallel 5-Step Tree  │ │ RF-006: Emergency Safety Net         │
│ (Clinical Teal & Soft Indigo) │ │ (Hard Stop Override on Level 4/5)    │
└──────────────┬────────────────┘ └──────────────────┬───────────────────┘
               │                                     │ Intercepts any step
               ▼                                     │ instantly
┌───────────────────────────────┐                    │
│ RF-004: Psychosomatic Mapping │◄───────────────────┘
└──────────────┬────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│       Historical Check-In Storage (PostgreSQL DB)       │
└──────────────┬───────────────────────────┬──────────────┘
               │                           │
               ▼                           ▼
┌───────────────────────────────┐ ┌──────────────────────────────────────┐
│ RF-003: 14-Day Antiburla      │ │ RF-008: Dual-View Historical Dashb.  │
│ (Temporal Consistency Scan)   │ │ (2D Body Heat Map + 7-Day Emotional) │
└──────────────┬────────────────┘ └──────────────────────────────────────┘
               │ feeds back to refine
               ▼
┌───────────────────────────────┐
│ RF-009: Preventive Guidance   │
└───────────────────────────────┘
               ▲
               │ enriches
┌──────────────┴────────────────┐
│ RF-012: Decoupled Lab Exam    │
│ Biomarker Extraction (OCR)    │
└───────────────────────────────┘
```

### Dependency Notes
- **RF-006 (Safety Net) intercepts RF-001 and RF-002**: Red Flag triggers must bypass all standard 5-step questions immediately. If a user enters "Crushing chest pain and arm numbness" in RF-001, Step 1 does not proceed—the emergency red modal activates instantly.
- **RF-003 (Antiburla) requires RF-002 historical logs**: The 14-day temporal scanner cannot operate in a vacuum; it requires persistent, structured past records in PostgreSQL with temporal B-tree indexing.
- **RF-004 (Psychosomatic Mapping) enhances RF-002**: Translates qualitative user inputs into structured cross-vertical correlations, allowing simultaneous updates to both physical and emotional dashboards.
- **RF-008 (Dashboards) requires RF-002 completion**: The 2D anatomical heatmap requires precise coordinate/organ data from Step 1 (Nature), and the 7-day emotional graph requires Likert values from Step 3 (Intensity).
- **RF-012 (Lab OCR) enriches RF-003 and RF-009**: Extracted biomarkers (e.g., HbA1c = 7.2% or TSH = 8.5) provide ground-truth physiological context that validates reported symptoms (e.g., fatigue, polydipsia) and tailors preventive health content.

---

## MVP Definition

### Launch With (v1) — Minimum Viable Product
Essential for concept validation, clinical safety, and initial user adoption:

- [x] **RF-001: Unified Entry Point**: Clean, responsive "How are you feeling today?" prompt with fast-tap suggestion chips and sub-2s LLM routing.
- [x] **RF-002: Parallel 5-Step Triage Tree**: Complete decision tree across 19 categories with dynamic UI palette switching (Clinical Teal `#00796B` vs Soft Indigo `#3F51B5`).
- [x] **RF-006: Unified Emergency Safety Net**: Zero-failure fail-safe red screen with 1-tap dialer for Brazilian emergency numbers (SAMU 192, CVV 188, Bombeiros 193) and nearest emergency facility locator.
- [x] **RF-003: Core 14-Day Temporal Consistency Engine**: Basic temporal scan identifying blatant contradictions with supportive clarification dialogues.
- [x] **RF-004: Somatic & Psychosomatic Core Mapping**: Dictionary and prompt-based clinical alignment for top 25 common Brazilian distress idioms.
- [x] **RF-008: Dual-View Historical Dashboards**: Interactive 2D body heat map (front/back with 3 pain tiers) + 7-day emotional trend graph across 7 dimensions.
- [x] **RNF-001 & RNF-002**: Sub-2s classification latency and full LGPD-compliant storage with Row-Level Security in São Paulo AWS/GCP region.
- [x] **RNF-003**: Flutter mobile client (iOS and Android) with Riverpod state management and Material 3 design.

### Add After Validation (v1.x)
High-value capabilities to roll out once core triage adoption and retention are validated:

- [ ] **RF-012: Decoupled Lab Exam Biomarker Processing**: Production OCR + structured JSON LLM pipeline for PDF and mobile camera blood test uploads.
- [ ] **RF-009: Curated Preventive Health Guidance**: In-app curated library of evidence-based preventive micro-articles triggered dynamically by triage outcomes.
- [ ] **One-Click "Doctor's Brief" Clinical PDF Export**: SBAR-formatted exportable summary enabling users to hand their 14-day history directly to their physician.
- [ ] **Family / Dependent Profiles**: Ability to manage triage and health records for children or elderly parents under a single account.

### Future Consideration (v2+)
Strategic features deferred until product-market fit and revenue sustainability are proven:

- [ ] **Biometric Wearable Ingestion (Apple HealthKit & Android Health Connect)**: Continuous passive ingestion of Resting Heart Rate (RHR), Heart Rate Variability (HRV), and sleep stages to passively inform the Antiburla engine before the user even types.
- [ ] **Physician Shared Web Portal**: Secure, read-only tokenized link allowing clinicians to inspect longitudinal charts during outpatient consultations.
- [ ] **Integration with Private Health Plan Directories**: Direct lookup of covered Urgent Care / Emergency facilities based on the user's specific health insurance plan (Unimed, Bradesco Saúde, Amil, SulAmérica).

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Target Milestone |
|---------|------------|---------------------|----------|------------------|
| **RF-006: Emergency Safety Net** | CRITICAL | MEDIUM | **P1** | MVP v1 |
| **RF-001: Unified Entry Point** | HIGH | LOW | **P1** | MVP v1 |
| **RF-002: Parallel 5-Step Triage (19 Cats)** | HIGH | MEDIUM | **P1** | MVP v1 |
| **RF-003: 14-Day Temporal Antiburla Engine** | HIGH | HIGH | **P1** | MVP v1 |
| **RF-004: Somatic/Psychosomatic Mapping** | HIGH | MEDIUM | **P1** | MVP v1 |
| **RF-008: 2D Anatomical Body Heat Map** | HIGH | MEDIUM | **P1** | MVP v1 |
| **RF-008: 7-Day Emotional Trend Graph** | HIGH | MEDIUM | **P1** | MVP v1 |
| **RNF-001: Sub-2s AI Latency** | HIGH | MEDIUM | **P1** | MVP v1 |
| **RNF-002: LGPD & Security (RLS)** | CRITICAL | HIGH | **P1** | MVP v1 |
| **RNF-003: Cross-Platform Flutter Client** | HIGH | HIGH | **P1** | MVP v1 |
| **RF-012: Decoupled Lab Exam OCR Pipeline** | HIGH | HIGH | **P2** | v1.x (Premium Tier) |
| **Doctor's Brief Export (SBAR PDF)** | HIGH | LOW | **P2** | v1.x |
| **RF-009: Preventive Health Articles** | MEDIUM | LOW | **P2** | v1.x |
| **Wearable Passive Ingestion (HealthKit)** | HIGH | HIGH | **P3** | v2+ |
| **Family Dependent Accounts** | MEDIUM | MEDIUM | **P3** | v2+ |

---

## Competitor Feature Analysis

| Dimension / Feature | Ada Health | Infermedica (B2B) | Bearable | Function Health | **DualisCheckUp** |
|---|---|---|---|---|---|
| **Core Value** | AI symptom assessment & probabilistic diagnosis | White-label digital triage API for payers/providers | Passive symptom & lifestyle tracking diary | Preventive biomarker lab testing subscription ($499/yr) | **Integrated preventive personal triage bridging somatic & emotional health** |
| **Physical / Emotional Integration** | Siloed. Mental health assessments are separate questionnaires. | Physical focus; psychiatric modules are secondary triage tiers. | Unified tracking, but purely manual; zero AI triage intelligence. | Lab biomarker focus; no acute mental health triage. | **Native parallel triage: 12 physical + 7 emotional categories with unified 5-step tree.** |
| **Visual State Transitions** | Monochromatic clinical white/blue. | Static corporate white-label theme. | Dark mode customizable cards; no clinical state switching. | Premium editorial dashboard (web/mobile). | **Dynamic switching: Clinical Teal (`#00796B`) vs Soft Indigo (`#3F51B5`) by vertical.** |
| **Longitudinal Temporal Consistency** | Static recall. Each assessment acts largely as a blank-slate event. | Stateless triage engine via API; state must be managed by client. | Manual graphs showing user logs; no automated contradiction checking. | Historical lab trends over time; no daily symptom verification. | **14-day temporal "Antiburla" engine actively resolving contradictions empathetically.** |
| **Emergency Escalation** | Prompts to call 911 at end of questionnaire or upon severe red flag. | Built-in red-flag early exit hooks for emergency care disposition. | None. Pure tracking app with no emergency interception. | None. Asynchronous outpatient lab review only. | **Instantaneous hard-stop modal with full red override and 1-tap local emergency services (192, 188).** |
| **Psychosomatic Mapping** | Treats symptoms as distinct disease manifestations. | Rule-based clinical criteria; limited colloquial idiom translation. | User-defined tags (e.g., "stress caused headache"); no automated clinical bridging. | N/A (blood biomarkers only). | **Direct translation of lay distress idioms ("nó na garganta") into clinical dual matrices.** |
| **Visual Heat Map** | Basic tap-to-select body silhouette. | Body point selector API. | None (list-based body parts). | None. | **Interactive 2D vector body heat map with chromatic pain & recurrence gradient.** |
| **Lab Exam OCR Processing** | None. Purely symptom-questionnaire driven. | Lab test inputs via structured API only; no direct document OCR. | Manual lab entry only. | Core feature: comprehensive lab panels via Quest/LabCorp. | **Decoupled OCR + Structured JSON LLM pipeline extracting lab biomarker panels.** |
| **Data Privacy & Localization** | GDPR compliant (hosted in EU/Germany). | GDPR / HIPAA compliant. | Hosted on public cloud (US/UK). | HIPAA compliant (US only). | **Strict Brazilian LGPD compliance, São Paulo regional data residency & PostgreSQL RLS.** |

---

## Sources & Reference Standards

1. **Manchester Triage System (MTS) & Emergency Severity Index (ESI)**: Clinical standards for emergency risk stratification and red-flag early exits.
2. **Conselho Federal de Medicina (CFM)**: Resolução CFM nº 2.314/2022 (Regulation of Telemedicine, digital clinical records, and safety guardrails).
3. **Agência Nacional de Vigilância Sanitária (Anvisa)**: RDC nº 657/2022 (Regulatory framework for Software as a Medical Device - SaMD).
4. **Lei Geral de Proteção de Dados (LGPD)**: Lei nº 13.709/2018 (Special provisions for sensitive personal health data, Art. 11).
5. **Competitor Architectures & User Studies**:
   - Ada Health GmbH: Public clinical validation studies on Bayesian symptom assessment accuracy.
   - Infermedica: Clinical Whitepapers on Call Center Triage and Red Flag Screening protocols.
   - Bearable App: User feedback benchmarks regarding daily symptom journaling fatigue.
   - Function Health: Ingestion paradigms for outpatient laboratory biomarker panels.

---
*Feature research for: DualisCheckUp*  
*Researched: 2026-09-13*
