# Phase 7: Antiburla Historical Verification Sheet (Screen 5 / RF-003 & UC-01) — Research

## Executive Summary

Phase 7 implements Screen 5: Antiburla Historical Verification Sheet (RF-003, UC-01, ANTI-01..03). In digital health triage, users frequently misreport symptom persistence as "Começou hoje" (started today) even when identical symptoms were logged within the past 14 days. The Antiburla engine eliminates temporal inconsistency without punitive rejection, utilizing an empathetic conversational bottom sheet (UC-01) to normalize the internal clinical timeline.

---

## 1. Technical Architecture & Database Indexing (ANTI-01)

### 1.1 Temporal Indexing in PostgreSQL
To achieve the sub-15ms latency constraint on 14-day history queries:
```sql
CREATE INDEX IF NOT EXISTS idx_symptom_logs_user_recorded
ON symptom_logs (user_id, recorded_at DESC);
```
Query filter:
```sql
SELECT id, recorded_at, intensity, anatomical_system, emotional_dimension, disposition
FROM symptom_logs
WHERE user_id = :userId
  AND recorded_at >= NOW() - INTERVAL '14 days'
  AND (anatomical_system = :category OR emotional_dimension = :category)
ORDER BY recorded_at DESC
LIMIT 1;
```

---

## 2. UC-01 Empathetic Dialog & Reconciliation (ANTI-02, ANTI-03)

### 2.1 The Dialog Pattern
Instead of a punitive warning (*"Você já relatou isso"*), Screen 5 acts as a compassionate clinical interlocutor:
- **Portuguese**: *"Notei aqui no seu histórico que você também sentiu esse desconforto há poucos dias. Você acha que essa sensação de hoje é algo completamente novo ou pode ser aquela mesma que acabou voltando?"*
- **Binary Choice**:
  - `[É a mesma sensação que voltou]`: Internally normalizes persistence to recurring/episodic (`ha_alguns_dias`), providing more accurate clinical triage and historical reporting.
  - `[É um sentimento completamente novo]`: Retains `comecou_hoje` as an isolated acute presentation.

---

## 3. Biological & Behavioral Boundary Guardrails (ANTI-03)

1. **Biological Discordance Handling**:
   - Compares reported physical area with user profile biological sex (e.g. female user reporting testicular or prostatic pain).
   - Returns respectful, non-judgmental guidance: *"Observamos uma possível discordância anatômica com o seu perfil biológico. Redirecionando para avaliação da região pélvica/abdominal."*
2. **Non-Clinical / Recreational Guardrails**:
   - Queries regarding recreational drugs, alcohol, or non-clinical behaviors are respectfully de-escalated and framed around overall physiological health without moralizing.

---

## 4. Validation Architecture

- **Backend**:
  - `backend/test/unit/antiburla.service.spec.ts`: Validates 14-day query scanning, reconciliation logic, and biological boundary checker.
  - `backend/test/e2e/antiburla.e2e-spec.ts`: Validates `POST /v1/triage/antiburla-check`.
- **Mobile**:
  - `mobile/test/features/triage/antiburla_bottom_sheet_test.dart`: Validates modal presentation on "Começou hoje", binary button actions, and persistence state mutation.
