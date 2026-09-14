# Phase 5: Home & Unified Dual-Axis Trigger Check-in — Research

**Researched:** 2026-09-14
**Domain:** Flutter UI · Dual-Axis Triage Routing · Organic Primacy · AdMob Container · NestJS AI Classification
**Confidence:** HIGH

---

## User Constraints

### Locked Decisions
- Mandatory trigger question: *"Como você está se sentindo hoje?"* presenting two separate evaluation axes:
  1) Psico-Emocional (`[Bem / Normal]`, `[Mais ou menos]`, `[Mal / Ruim]`)
  2) Avaliação Física (`[Bem / Normal]`, `[Mais ou menos]`, `[Mal / Ruim]`)
- Routing Matrix:
  - Both `[Bem / Normal]` -> immediate preventive wellness confirmation (zero triage friction).
  - One axis distressed -> route directly to that vertical.
  - Both axes distressed -> enforce **Organic Primacy** (evaluate physical first before emotional).
- Lay-term description input field in pt-BR, es, en (`TRG-02`, `I18N-02`).
- Privacy-focused AdMob container (`AD-01`): zero health data profiling, targeted solely by approximate location/age.
- Sub-2s latency SLA for AI classification (`RNF-002`) with deterministic fallback.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Dual-axis trigger UI & selection state | Flutter Client (Riverpod `TriggerCheckInNotifier`) | — | Client-side responsive state |
| Wellness confirmation modal | Flutter Client (Dialog / BottomSheet) | — | Instant zero-latency confirmation |
| Organic Primacy routing | Flutter Client (Navigation coordinator) | — | Decides initial and subsequent wizard route |
| Privacy AdMob Container | Flutter Client (`AdMobContainer` widget) | — | Privacy-safe native ad placeholder |
| Symptom classification API | NestJS Backend (`AiModule`) | Google Gemini 1.5 Flash | Sub-2s structured JSON inference |
| Colloquial idiom dictionary fallback | NestJS Backend (`IdiomDictionaryService`) | Flutter Client | Resilient offline & instant cache (<10ms) |

---

## Technical Architecture

### 1. Dual-Axis Trigger Check-in State Machine
```dart
enum TriggerStatus {
  goodNormal,   // [Bem / Normal]
  soSo,         // [Mais ou menos] -> Standard AI triage
  badSick,      // [Mal / Ruim] -> High-sensitivity AI triage
}

class TriggerCheckInState {
  final TriggerStatus? emotionalStatus;
  final TriggerStatus? physicalStatus;
  final String naturalLanguageInput;
  final bool isSubmitting;
}
```

### 2. Organic Primacy Routing Rule
When both axes report discomfort:
1. Physical evaluation is prioritized: User is routed to `RoutePaths.triage` with `TriageVertical.fisica`.
2. Session carries forward a flag indicating pending emotional assessment upon physical wizard conclusion.

### 3. NestJS AI Classification Engine
Using `@google/genai` or Gemini REST API with Gemini 1.5 Flash and strict JSON schema:
```json
{
  "vertical": "physical" | "emotional",
  "systemOrDimension": "cardiovascular_chest" | "depressive_hopelessness" | ...,
  "urgencyScore": 1..5,
  "mappedLayTerm": "dor no peito",
  "clinicalConcept": "precordialgia"
}
```
Deterministic fast-path fallback with 30+ Brazilian Portuguese, Spanish, and English idioms.
