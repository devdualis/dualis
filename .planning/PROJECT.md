# DualisCheckUp

## What This Is

DualisCheckUp is a mobile preventive health platform that centralizes personal health management and medical history directly in the user's hands. Aligned with the official Software Requirements Specification (SRS v1.0), it seamlessly integrates physical health tracking (across 12 anatomical systems) and psycho-emotional well-being (across 7 dimensions) into a unified, AI-powered preventive triage experience for its Free Tier, monetized via age/location-targeted local business ads (RF-009).

## Core Value

Unified, safe, and clinically consistent daily health triage bridging somatic/physical symptoms and psycho-emotional states with immediate emergency escalation and 14-day anti-tampering historical verification.

## Business Context

- **Customer**: Individuals seeking proactive personal health tracking, chronic symptom management, and holistic physical & emotional well-being.
- **Revenue model**: 
  - **Free Tier (v1 Target)**: Daily dual-axis triage, 5-step decision wizard, 14-day Antiburla consistency verification, somatic translation, independent historical dashboards (2D body heat map + emotional trend graph + Cards de Recorrência Crítica + Lista Retrospectiva), monetized via privacy-focused native AdMob banners targeted strictly by age and approximate location for local businesses (pharmacies, supermarkets, department stores).
  - **Premium Tier (Deferred to v2)**: Prontuário Estruturado CID (RF-010), Histórico Médico Completo com alarmes de remédios (RF-011), Leitor de Exames Inteligente via OCR + IA (RF-012 / UC-02), e Assinatura recorrente por volume de dados (RF-013).
- **Success metric**: Daily active check-in consistency, sub-2-second AI triage classification latency, and 100% emergency trigger fidelity.
- **Strategy notes**: User-centric health data sovereignty, LGPD-compliant storage, and preventive health guidance.

## Requirements

### Validated

- [x] **SEC-01 (Database Tenant Isolation)**: PostgreSQL Row-Level Security (`SET LOCAL app.current_user_id = :userId`) enforcing zero cross-tenant leakage. Verified in Phase 1.
- [x] **SEC-02 (Data Encryption)**: AES-256-GCM AEAD field-level encryption at rest, TLS 1.3 in transit, and São Paulo region data residency under LGPD Art. 11. Verified in Phase 1.
- [x] **DISC-01 (Medical Disclaimers)**: Anvisa RDC 657/2022 and CFM Res. 2.314/2022 compliant legal disclaimers localized in `pt-BR`, `es`, `en` via `GET /v1/legal/disclaimer`. Verified in Phase 1.

### Active (Free Tier Scope)

- [ ] **RF-001 (Unified Dual-Axis Trigger Check-in)**: Daily check-in presenting two mandatory trigger evaluations ("Como você está se sentindo hoje?"): 1) Psico-Emocional and 2) Avaliação Física (Dor Física) with 3 response options (`[Bem / Normal]`, `[Mais ou menos]`, `[Mal / Ruim]`), routing into zero-friction confirmation if both normal, or into the respective AI triage flow(s) with standard/high sensitivity and Organic Primacy.
- [ ] **RF-002 (Parallel Triage Architecture & Visual State Switching)**: Standardized 5-step decision tree (Natureza → Tempo/Persistência → Intensidade → Causas/Gatilhos → Desfecho/Ação) across Psico-Emocional (Soft Indigo) and Física (Clinical Teal) with verbatim clinical questions.
- [ ] **RF-003 (Historical Consistency Engine / Antiburla & Boundary Guardrails)**: Real-time temporal 14-day scan of past logs with empathetic confrontation dialog (UC-01) for recurrence reconciliation, plus biological consistency checks (e.g. female user reporting testicular pain) and safe handling of non-clinical queries.
- [ ] **RF-004 (Somatic & Psychosomatic Symptom Mapping)**: AI classification engine recognizing somatic/psychosomatic symptoms, mapping lay descriptions (e.g., "batedeira no peito", "nó na garganta") into official database matrices (7 emotional dimensions + 12 physical systems).
- [ ] **RF-005 (Curated Guidance & Preventive Health Articles)**: Context-aware preventive health articles written by renowned specialists matched to triage findings.
- [ ] **RF-006 (Unified Emergency Safety Net)**: Immediate triage halt and full-screen red emergency modal (`#D32F2F`) locked against dismissal (`PopScope(canPop: false)`) with one-tap local emergency services contact (SAMU 192, Bombeiros 193, CVV 188) when level 4-5 severity is flagged.
- [ ] **RF-007 (Simplified Registration)**: Mandatory collection of Full Name, Date of Birth, Biological Sex (Gender), Email, Password, and explicit LGPD health data privacy consent checkbox.
- [ ] **RF-008 (Dual-View Historical Dashboards)**: Segmented tab bar with interactive 2D Anatomical Body Heat Map (chromatic yellow-to-red gradient across 12 systems), linear 7-day emotional trend graph across 7 dimensions (`fl_chart`), Cards de Recorrência Crítica, and vertical Lista Retrospectiva feeds.
- [ ] **RF-009 (Native AdMob Monetization)**: Filtered strictly by age group and approximate geolocation to attract local businesses (pharmacies, supermarkets, department stores); zero medical profiling.
- [ ] **RNF-001 (Data Privacy & LGPD Compliance)**: Health data governance with PostgreSQL Row-Level Security (RLS) and encrypted storage for sensitive records.
- [ ] **RNF-002 (Sub-2s Classification Latency)**: AI symptom classification using structured JSON schemas returning responses in under 2 seconds.
- [ ] **RNF-003 (Cross-Platform Mobile Architecture)**: Flutter client for iOS and Android with Riverpod state management and Material 3 design system.
- [ ] **RNF-004 (Trilingual Localization)**: Comprehensive multilingual support across Spanish (`es`), Brazilian Portuguese (`pt-BR`), and English (`en`) for UI strings, medical disclaimers, triage decision trees, and AI classification prompts.

### Out of Scope / Deferred to v2 (Premium Features)

- **RF-010 / PREM-01 (Prontuário Estruturado - CID)**: Permanent registry of diagnosed pathologies mapped to international ICD-10/11 standards in *Minhas Condições & Diagnósticos*.
- **RF-011 / PREM-02 (Histórico Médico Completo)**: Modules for continuous medication management with dosage alarms, inventory alerts, surgical history, and doctor appointment logs.
- **RF-012 / UC-02 / PREM-03 (Leitor de Exames Inteligente - OCR + IA)**: Upload of lab test PDFs/photos with automated extraction of biomarker names (e.g. PSA Total), values, reference intervals, and exam dates into structured charts.
- **RF-013 / PREM-04 (Gestão de Tiers de Assinatura)**: Recurring subscription plans based on cloud database storage volume tiers.
- **Direct Telemedicine / Physician Prescriptions**: DualisCheckUp provides preventive triage, monitoring, and educational health guidance; it is not a telemedicine provider or e-pharmacy.
- **Full Hospital EHR Integration (FHIR/HL7) in V1**: Initial focus is on patient-controlled medical records and self-evaluations.
- **Autonomous Medical Diagnosis**: The platform classifies risk and categorizes symptoms; it does not replace licensed medical consultations.

## Context

- **Client Stack**: Flutter (iOS & Android) with Riverpod for reactive state management, automatic triage session lifecycle cleanup (`autoDispose`), and AsyncValue handling. Material 3 UI design with thumb-friendly controls and smooth vertical state transitions (Clinical Teal ↔ Soft Indigo). Multilingual localization via Flutter `intl` and `.arb` bundles (`pt-BR`, `es`, `en`).
- **Backend Stack**: Dockerized NestJS API deployed to managed container services (Google Cloud Run / Azure Container Apps). Multilingual legal disclaimer contracts and localized emergency service numbers.
- **Database & Storage**: PostgreSQL utilizing temporal indices for 14-day historical queries and native Row-Level Security (RLS). Hosted on **Supabase Free Tier during development**, and **Google Cloud SQL for PostgreSQL in production (São Paulo region `southamerica-east1` for LGPD compliance)**. Drizzle ORM provides standard connection string compatibility (`DATABASE_URL`) with zero lock-in across both environments. Redis for semantic query caching and rate limiting.
- **AI Engine**: Gemini 1.5 Flash via `@google/genai` using JSON Schema outputs for strict classification across 19 categories (7 emotional + 12 anatomical). Trilingual prompt engineering supporting colloquial distress idioms across Portuguese, Spanish, and English with sub-2s response SLA.

## Constraints

- **Tech Stack**: Flutter + Riverpod (Mobile), NestJS + PostgreSQL (Supabase dev / Google Cloud SQL prod) + Redis (Backend) — Cross-platform efficiency and robust relational data management.
- **Performance**: Sub-2-second latency on AI triage classification across all supported languages.
- **Clinical Safety**: Zero-failure fail-safe trigger for Level 4/5 symptoms into emergency red screen.
- **Regulatory**: Full LGPD compliance for Brazilian users (regional data residency, strict RLS, encryption at rest and in transit).
- **Internationalization**: Trilingual support (Spanish, Brazilian Portuguese, English) across mobile UI, API contracts, and AI reasoning.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Focus v1 on Free Tier Only | User explicitly requested skipping premium features (CID records, medication alarms, OCR lab tests) to deliver a laser-focused, high-quality preventive triage experience first | ✓ Good |
| Flutter + Riverpod for Mobile | Shared codebase for iOS & Android with compile-time state safety and clean session auto-dispose | — Pending |
| Supabase (Dev) / Google Cloud SQL (Prod) | Rapid zero-cost development sandbox with standard PostgreSQL RLS, seamlessly deploying to Google Cloud SQL São Paulo in prod via Drizzle ORM | ✓ Good |
| Trilingual Architecture (ES, PT-BR, EN) | Direct support for Brazilian Portuguese, Spanish, and English expands reach while maintaining clinical nuance in regional distress idioms | ✓ Good |
| Dual-Axis Trigger Check-in (RF-001) | Mandatory dual evaluation (Psico-Emocional and Física) from the start with 3 options (`[Bem/Normal]`, `[Mais ou menos]`, `[Mal/Ruim]`) and instant exit if both normal | — Pending |
| Parallel Triage with Verbatim 5-Step Tree (RF-002) | Adheres to SRS Section 3.1 clinical questions across 7 mental dimensions and 12 physical systems | — Pending |
| Soft Indigo & Clinical Teal Themes | High visual distinction between Psico-Emocional and Física verticals reduces user cognitive load | — Pending |
| 14-Day Temporal Antiburla Engine (RF-003 & UC-01) | Empathetic confrontation dialog for recurrence reconciliation without user friction, plus biological boundary validation | — Pending |
| Age & Geolocation AdMob Targeting (RF-009) | Monetization for local businesses (pharmacies, supermarkets) without health profiling or LGPD privacy infringement | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

---
*Last updated: 2026-09-14 after SRS v1.0 consolidation (Free Tier aligned)*
