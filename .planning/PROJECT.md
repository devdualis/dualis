# DualisCheckUp

## What This Is

DualisCheckUp is a mobile preventive health platform that centralizes personal health management and medical history directly in the user's hands. It seamlessly integrates physical health tracking (across 12 anatomical systems) and psycho-emotional well-being (across 7 dimensions) into a unified, AI-powered preventive triage experience.

## Core Value

Unified, safe, and clinically consistent daily health triage bridging somatic/physical symptoms and psycho-emotional states with immediate emergency escalation and 14-day anti-tampering historical verification.

## Business Context

- **Customer**: Individuals seeking proactive personal health tracking, chronic symptom management, and holistic physical & emotional well-being.
- **Revenue model**: Freemium model (Free Tier for AI-guided triage, dashboards, and prevention; Premium Tier for advanced OCR lab exam extraction, unlimited document storage, and deep clinical summaries).
- **Success metric**: Daily active check-in consistency, sub-2-second AI triage classification latency, and 100% emergency trigger fidelity.
- **Strategy notes**: User-centric health data sovereignty, LGPD-compliant storage, and preventive health guidance.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] **RF-001 (Unified Entry Point)**: Daily symptom check-in starting with "How are you feeling today?" routing dynamically into triage.
- [ ] **RF-002 (Parallel Triage Architecture & Visual State Switching)**: Standardized 5-step decision tree (Nature → Persistence → Intensity → Triggers → Outcome) across Psico-Emocional (7 dimensions, soft indigo) and Física (12 anatomical systems, clinical teal).
- [ ] **RF-003 (Historical Consistency Engine / Antiburla)**: Real-time temporal 14-day scan of past logs across emotional and anatomical systems with empathetic clarification dialogs for inconsistencies.
- [ ] **RF-004 (Somatic & Psychosomatic Symptom Mapping)**: AI classification engine recognizing somatic/psychosomatic symptoms, mapping lay descriptions (e.g., "racing heart", "lump in throat") into clinical matrices.
- [ ] **RF-006 (Unified Emergency Safety Net)**: Immediate triage halt and full-screen red emergency modal with one-tap local emergency services contact when level 4-5 severity is flagged.
- [ ] **RF-008 (Dual-View Historical Dashboards)**: Interactive 2D Anatomical Body Heat Map (chromatic yellow-to-red gradient for pain severity) and linear 7-day emotional trend graph across 7 dimensions.
- [ ] **RF-009 (Curated Guidance & Preventive Health Articles)**: Context-aware preventive health content matched to triage findings.
- [ ] **RF-012 (Decoupled Lab Exam Processing Pipeline)**: OCR engine (Cloud Vision / Textract) coupled with lightweight LLM extraction for biomarker key-value pairs from PDFs/images into structured data.
- [ ] **RNF-001 (Sub-2s Classification Latency)**: AI symptom classification using structured JSON schemas returning responses in under 2 seconds.
- [ ] **RNF-002 (Data Privacy & LGPD Compliance)**: Health data governance with PostgreSQL Row-Level Security (RLS) and encrypted object storage for sensitive medical documents.
- [ ] **RNF-003 (Cross-Platform Mobile Architecture)**: Flutter client for iOS and Android with Riverpod state management and Material 3 design system.

### Out of Scope

- **Direct Telemedicine / Physician Prescriptions**: DualisCheckUp provides preventive triage, monitoring, and educational health guidance; it is not a telemedicine provider or e-pharmacy.
- **Full Hospital EHR Integration (FHIR/HL7) in V1**: Initial focus is on patient-controlled medical records, manual inputs, and OCR document uploads.
- **Autonomous Medical Diagnosis**: The platform classifies risk and categorizes symptoms; it does not replace licensed medical consultations and halts for emergency care upon severe symptoms.

## Context

- **Client Stack**: Flutter (iOS & Android) with Riverpod for reactive state management, automatic triage session lifecycle cleanup, and AsyncValue handling. Material 3 UI design with thumb-friendly controls and smooth vertical state transitions.
- **Backend Stack**: Dockerized NestJS API deployed to managed container services (Google Cloud Run / Azure Container Apps).
- **Database & Storage**: PostgreSQL hosted in the São Paulo region (LGPD compliance, low latency), utilizing temporal indices for 14-day historical queries and Row-Level Security (RLS). Encrypted S3 / Azure Blob Storage for medical PDFs and images. Redis for semantic query caching and background task queues.
- **AI Engine**: Gemini 1.5 Flash / Flash-8B or GPT-4o-mini using JSON Schema outputs for strict classification across 19 categories (7 emotional + 12 anatomical). Decoupled OCR + LLM pipeline for lab reports to optimize token cost and accuracy.

## Constraints

- **Tech Stack**: Flutter + Riverpod (Mobile), NestJS + PostgreSQL + Redis (Backend) — Cross-platform efficiency and robust relational data management.
- **Performance**: Sub-2-second latency on AI triage classification.
- **Clinical Safety**: Zero-failure fail-safe trigger for Level 4/5 symptoms into emergency red screen.
- **Regulatory**: Full LGPD compliance for Brazilian users (regional data residency, strict RLS, encryption at rest and in transit).

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter + Riverpod for Mobile | Shared codebase for iOS & Android with compile-time state safety and clean session auto-dispose | — Pending |
| Parallel Triage with 5-Step Tree | Provides clinical consistency across both mental and physical health while preserving distinct context | — Pending |
| Soft Indigo & Clinical Teal Themes | High visual distinction between Psico-Emocional and Física verticals reduces user cognitive load | — Pending |
| 14-Day Temporal Antiburla Engine | Prevents conflicting timelines and enhances longitudinal clinical value | — Pending |
| Decoupled OCR + LLM for Lab Exams | Avoids high-resolution multimodal token costs while ensuring accurate biomarker key-value extraction | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Business Context check (if present) — customer, revenue model, success metric still accurate?
4. Audit Out of Scope — reasons still valid?
5. Update Context with current state

---
*Last updated: 2026-09-13 after initialization*
