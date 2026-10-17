# DualisCheckUp

## What This Is

DualisCheckUp is a wellness and self-awareness mobile app. It helps users keep a daily journal of how they feel physically and emotionally, track habits such as hydration and sleep, view their own entries over time, and access general educational content about healthy habits. DualisCheckUp is not a medical device: it does not assess, classify or interpret symptoms, does not indicate urgency levels, does not diagnose, does not recommend treatment and does not replace a healthcare professional. In an emergency, call your local emergency number (SAMU 192 in Brazil). If you are in emotional distress, contact your local crisis line (CVV 188 in Brazil). Free Tier is monetized via age/location-targeted local business ads (RF-009).

## Core Value

Daily physical and psycho-emotional wellness journaling with self-reported tracking, longitudinal habit patterns, and always-on, universally accessible emergency help resources.

## Business Context

- **Customer**: Individuals seeking proactive personal wellness tracking, healthy habit monitoring, and holistic physical & emotional self-awareness.
- **Revenue model**: 
  - **Free Tier (v1 Target)**: Daily dual-axis check-in, 5-step wellness journal wizard, 14-day recurrence consistency verification, body area / mood translation, independent historical dashboards (2D body map + emotional trend graph + Cards de Padrões nos Registros + Lista Retrospectiva), and always-on emergency help resources, monetized via privacy-focused native AdMob banners targeted strictly by age and approximate location for local businesses (pharmacies, supermarkets, department stores).
  - **Versão 2.0 (Premium & Advanced Tiers)**:
    - **Tier Premium**: Minhas Condições informadas pelo usuário (RF-010), Histórico de Cuidados Pessoais (RF-011), Leitor de Exames para Transcrição (RF-012), Leitor de Receita como Formulário Editável (RX-01), Controle de Vacinação PNI (VACC-01), Registro de Alergias Informadas (ALRG-01), Permissão Legal e Opcional (PERM-01/02), Opções Avançadas de Biometria (AUTH-03), Resumo dos Registros em PDF (CLIN-01).
    - **Tier Advanced**: 100% dos recursos do Tier Premium + Acesso a Bulas Oficiais (BULA-01) + Registro por Voz pós-login (VOICE-01).
    - **Pacote Família**: Precificação consolidada com permissão legal e múltiplos dependentes.
- **Success metric**: Daily active check-in consistency, sub-2-second AI tag-entry classification latency, zero prohibited clinical copy, and help resources accessible in ≤1 tap from all screens.
- **Strategy notes**: User-centric health data sovereignty, LGPD-compliant storage (Art. 11, I), and general wellness guidance. Intended as a wellness app; regulatory confirmation pending.

## Requirements

### Validated

- [x] **SEC-01 (Database Tenant Isolation)**: PostgreSQL Row-Level Security (`SET LOCAL app.current_user_id = :userId`) enforcing zero cross-tenant leakage. Verified in Phase 1.
- [x] **SEC-02 (Data Encryption)**: AES-256-GCM AEAD field-level encryption at rest, TLS 1.3 in transit, and São Paulo region data residency under LGPD Art. 11. Verified in Phase 1.
- [x] **DISC-01 (Wellness & Non-Diagnostic Disclaimers)**: Prominent wellness and non-diagnostic disclaimers localized in `pt-BR`, `es`, `en` via `GET /v1/legal/disclaimer` (intended as a wellness app; regulatory confirmation pending). Verified in Phase 1.

### Active (Free Tier Scope)

- [ ] **RF-001 (Unified Dual-Axis Trigger Check-in)**: Daily check-in presenting two mandatory evaluations ("Como você está se sentindo hoje?"): 1) Psico-Emocional and 2) Registro Físico with 3 self-reported response options (`[Bem / Normal]`, `[Mais ou menos]`, `[Mal / Ruim]`), routing into zero-friction confirmation if both normal, or into the 5-step journal flow for the affected vertical(s) with static dual-axis reflection note if both report discomfort.
- [ ] **RF-002 (Parallel Journal Architecture & Visual State Switching)**: Standardized 5-step journal tree (Natureza → Tempo/Persistência → Intensidade informada → Causas/Gatilhos → Revisar e salvar seu registro) across Psico-Emocional (Soft Indigo) and Física (Teal) with lay-friendly questions.
- [ ] **RF-003 (Historical Consistency Engine / Recurrence Check & Boundary Guardrails)**: Real-time temporal 14-day scan of past logs with empathetic reconciliation dialog (UC-01) for recurrence consistency ("Isso já apareceu antes?"), and safe respectful handling of non-journal queries.
- [ ] **RF-004 (Body Area & Mood Tagging)**: AI tagging engine mapping lay descriptions (e.g., "batedeira no peito", "nó na garganta") into body areas or emotional states without clinical diagnostic evaluation or urgency scoring.
- [ ] **RF-005 (Curated Educational & Wellness Articles)**: General educational articles on healthy habits and wellness citing authentic public health sources (e.g., Ministério da Saúde), with static disclaimer that they are not personal advice.
- [ ] **RF-006 (Always-On Emergency Help Resources)**: Always-on emergency help resources: global "Ajuda urgente" button reachable in ≤1 tap from all main screens and login, plus non-blocking generic safety prompt if self-reported intensity 5 or alarm text is entered, displaying static warning signs and 1-tap local emergency services contact (SAMU 192, CVV 188, Bombeiros 193, Polícia 190).
- [ ] **RF-007 (Simplified Registration)**: Mandatory collection of Full Name, Date of Birth, Biological Sex (Gender), Email, Password, and explicit LGPD Art. 11, I health data privacy consent checkbox.
- [ ] **RF-008 (Dual-View Historical Dashboards)**: Segmented tab bar with interactive 2D Anatomical Body Map, linear 7-day emotional trend graph across emotional dimensions (`fl_chart`), Cards de Padrões nos Registros, and vertical Lista Retrospectiva feeds.
- [ ] **RF-009 (Native AdMob Monetization)**: Filtered strictly by age group and approximate geolocation to attract local businesses (pharmacies, supermarkets, department stores); zero medical profiling or health data tracking.
- [ ] **RNF-001 (Data Privacy & LGPD Compliance)**: Health data governance with PostgreSQL Row-Level Security (RLS) and encrypted storage for sensitive records.
- [ ] **RNF-002 (Sub-2s Classification Latency)**: AI entry tagging using structured JSON schemas returning responses in under 2 seconds.
- [ ] **RNF-003 (Cross-Platform Mobile Architecture)**: Flutter client for iOS and Android with Riverpod state management and Material 3 design system.
- [ ] **RNF-004 (Trilingual Localization)**: Comprehensive multilingual support across Spanish (`es`), Brazilian Portuguese (`pt-BR`), and English (`en`) for UI strings, wellness disclaimers, journal decision trees, and AI tagging prompts.

### Out of Scope / Deferred to v2 (Versão Premium & Advanced)

**Estrutura de Tiers v2**:
- **Premium**: Tudo exceto Leitor de Bula e Interação por Voz.
- **Advanced**: Tudo (incluindo Bulário oficial e Interação por Voz para registro).
- **Pacote Família**: Precificação com permissão legal e dependentes incluídos.

**Funcionalidades Essenciais v2**:
- **RF-010 / PREM-01 (Minhas Condições - Informadas pelo Usuário)**: Personal registry of conditions diagnosed by the user's doctor mapped to standard ICD-10/11 terms in *Minhas Condições*, without algorithmic condition inferencing from entries.
- **RF-011 / PREM-02 (Histórico de Cuidados Pessoais & Lembretes)**: Modules for personal medication schedule reminders configured by user, low-supply alerts, surgical history, and health appointment logs.
- **PERM-01 / PREM-06 (Cadastro de Permissão Legal)**: Multi-profile dependent and guardianship management for minors or dependent adults under LGPD Art. 14.
- **PERM-02 / PREM-07 (Cadastro de Permissão Opcional)**: Consensual profile sharing between couples, siblings, or informal caregivers with granular access control.
- **VACC-01 / PREM-08 (Controle de Vacinação)**: Digital vaccination card tracking official national immunization schedule (PNI/SUS) and elective vaccines, doses, lot numbers, and booster reminders based on official calendar.
- **ALRG-01 / PREM-09 (Registro de Alergias Informadas)**: User-maintained list of personal drug allergies displayed in profile/export (without automated clinical cross-check).
- **CLIN-01 / PREM-05 (Resumo dos Registros em PDF)**: One-click export of self-reported entries (dates, intensities, user notes, user-entered allergies and medications) without clinical assessment or recommendation sections.

**Melhorias e Recursos Avançados v2**:
- **PRIC-01 / PREM-10 (Precificação Pacote Família)**: Multi-profile family tier pricing with integrated legal permission.
- **BULA-01 / PREM-11 (Acesso a Bulas Oficiais - Advanced Only)**: Direct integration/linking with official ANVISA Bulário Eletrônico for official medication leaflets.
- **RX-01 / PREM-12 (Leitor de Receita Média para Formulário Editável)**: OCR assistance pre-filling an editable form, requiring explicit field-by-field user confirmation before saving personal medication reminders.
- **RF-012 / UC-02 / PREM-03 (Transcrição de Exames)**: Upload of lab test PDFs/photos for user-confirmed transcription of printed values and laboratory reference ranges, without clinical interpretations, alerts, or AI commentary.
- **AUTH-03 / PREM-13 (Opções Avançadas de Log In Biométrico)**: Expanded biometric settings (timeout controls, step-up biometric prompt for sensitive personal records).
- **VOICE-01 / PREM-14 (Registro por Voz pós-login - Advanced Only)**: Hands-free voice-assisted journal entries, check-in, and vocal navigation.
- **RF-013 / PREM-04 (Gestão de Tiers de Assinatura)**: Multi-tier subscription billing (Free, Premium, Advanced, Família). Help resources always remain free across all tiers.
- **Direct Telemedicine / Physician Prescriptions**: DualisCheckUp provides wellness journaling, habit tracking, and educational guidance; it is not a telemedicine provider or e-pharmacy.
- **Full Hospital EHR Integration (FHIR/HL7) in V1**: Initial focus is on user-controlled personal records and self-evaluations.
- **Autonomous Medical Diagnosis & Triage**: The platform organizes personal wellness entries and displays user-reported logs; it does not assess clinical risk, classify symptoms, provide medical diagnoses, or replace licensed healthcare consultations.

## Context

- **Client Stack**: Flutter (iOS & Android) with Riverpod for reactive state management, automatic journal session lifecycle cleanup (`autoDispose`), and AsyncValue handling. Material 3 UI design with thumb-friendly controls and smooth vertical state transitions (Teal ↔ Soft Indigo). Multilingual localization via Flutter `intl` and `.arb` bundles (`pt-BR`, `es`, `en`).
- **Backend Stack**: Dockerized NestJS API deployed to managed container services (Google Cloud Run / Azure Container Apps). Multilingual legal disclaimer contracts and localized emergency service numbers.
- **Database & Storage**: PostgreSQL utilizing temporal indices for 14-day historical queries and native Row-Level Security (RLS). Hosted on **Supabase Free Tier during development**, and **Google Cloud SQL for PostgreSQL in production (São Paulo region `southamerica-east1` for LGPD compliance)**. Drizzle ORM provides standard connection string compatibility (`DATABASE_URL`) with zero lock-in across both environments. Redis for semantic query caching and rate limiting.
- **AI Tagging Engine**: Gemini 1.5 Flash via `@google/genai` using JSON Schema outputs for entry tagging ({ isOffTopic, vertical, bodyAreaOrMood, layTerm, mentionsSelfHarm }) without clinical concept or urgency scoring, supporting colloquial expressions across Portuguese, Spanish, and English with sub-2s response SLA.

## Constraints

- **Tech Stack**: Flutter + Riverpod (Mobile), NestJS + PostgreSQL (Supabase dev / Google Cloud SQL prod) + Redis (Backend) — Cross-platform efficiency and robust relational data management.
- **Performance**: Sub-2-second latency on AI tag-entry classification across all supported languages.
- **Safety**: Help resources always reachable in ≤1 tap from every screen and login, with static official warning signs and regional emergency numbers.
- **Regulatory**: Full LGPD compliance for Brazilian users (Art. 11, I explicit consent, regional data residency, strict RLS, encryption at rest and in transit). Intended as a wellness app; regulatory confirmation pending.
- **Internationalization**: Trilingual support (Spanish, Brazilian Portuguese, English) across mobile UI, API contracts, and AI reasoning.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Focus v1 on Free Tier Only | User explicitly requested skipping premium features (CID records, medication alarms, OCR lab tests) to deliver a laser-focused, high-quality wellness journal experience first | ✓ Good |
| Flutter + Riverpod for Mobile | Shared codebase for iOS & Android with compile-time state safety and clean session auto-dispose | — Pending |
| Supabase (Dev) / Google Cloud SQL (Prod) | Rapid zero-cost development sandbox with standard PostgreSQL RLS, seamlessly deploying to Google Cloud SQL São Paulo in prod via Drizzle ORM | ✓ Good |
| Trilingual Architecture (ES, PT-BR, EN) | Direct support for Brazilian Portuguese, Spanish, and English expands reach while maintaining nuance in regional expressions | ✓ Good |
| Dual-Axis Trigger Check-in (RF-001) | Mandatory dual evaluation (Psico-Emocional and Registro Físico) with 3 options (`[Bem/Normal]`, `[Mais ou menos]`, `[Mal/Ruim]`) and instant exit if both normal | — Pending |
| Parallel Journal with 5-Step Tree (RF-002) | Standardized 5-step journal flow across emotional and physical verticals | — Pending |
| Soft Indigo & Teal Themes | High visual distinction between Psico-Emocional and Física verticals reduces user cognitive load | — Pending |
| 14-Day Recurrence Check Engine (RF-003 & UC-01) | Empathetic reconciliation dialog for recurrence consistency without user friction | — Pending |
| Age & Geolocation AdMob Targeting (RF-009) | Monetization for local businesses (pharmacies, supermarkets) without health profiling or LGPD privacy infringement | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

---
*Last updated: 2026-10-16 after Wellness Repositioning consolidation*
