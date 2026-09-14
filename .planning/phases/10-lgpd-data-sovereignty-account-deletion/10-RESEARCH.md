# Phase 10 Research: LGPD Data Sovereignty, Account Deletion & Production Verification (SEC-03)

## 1. Executive Summary

Phase 10 delivers compliance with Brazilian LGPD (Lei Geral de Proteção de Dados - Law No. 13.709/2018), specifically Articles 18 and 19 concerning Data Subject Rights (Direitos do Titular de Dados):
- **Right to Data Portability (Art. 18, V)**: Self-service export of all personal account profile details, consent audit logs, and medical symptom triage history in structured, readable JSON format.
- **Right to Erasure / Deletion (Art. 18, VI)**: Irrevocable permanent deletion of the user's account and all associated personal and clinical data across relational database tables (`users`, `user_disclaimer_consents`, `symptom_logs`, `triage_emergency_events`), local device storage (Drift SQLite database `triage_outbox` and `local_symptom_drafts`), and device Keychain/EncryptedSharedPreferences tokens.
- **Production Verification**: Verification of sub-2s AI triage latency SLA (RNF-002) and strict cross-tenant RLS isolation to ensure zero data leakage across the entire platform.

## 2. Technical Architecture & Endpoints

### 2.1 Backend Data Export (`GET /v1/auth/export-data`)
- Protected by `JwtAuthGuard`.
- Queries the authenticated user's records under RLS:
  - Account profile (`users` table): ID, name, email, gender, dateOfBirth, registration timestamp.
  - Consent records (`user_disclaimer_consents` table): disclaimer version, acceptance timestamp, hashed IP, user agent.
  - Symptom triage logs (`symptom_logs` table): intensity, anatomicalSystem, emotionalDimension, disposition, stepAnswers, recordedAt. Sensitive narratives are decrypted using `EncryptionService.decrypt` before inclusion in the exported JSON file so the user receives readable, portable records.
  - Emergency telemetry records (`triage_emergency_events` table): triggerCategory, severityLevel, sourceVertical, actionTaken, reportedAt.
- Returns a structured portable JSON object with metadata (export timestamp, legal disclaimer, data schema version).

### 2.2 Backend Irrevocable Permanent Deletion (`DELETE /v1/auth/account`)
- Protected by `JwtAuthGuard`.
- Requires confirmation password or confirmation token in the body (`DeleteAccountDto`).
- Executes in an atomic database transaction under RLS `SET LOCAL app.current_user_id = :userId`:
  1. Deletes user row from `users` table:
     - All child tables (`symptom_logs`, `user_disclaimer_consents`, `triage_emergency_events`) have foreign keys configured with `ON DELETE CASCADE`.
     - Explicit transactional verification confirms deletion across all child tables.
  2. Returns HTTP 200 with `{ success: true, message: 'Conta e todos os dados de saúde foram permanentemente excluídos conforme LGPD Art. 18.' }`.

### 2.3 Mobile Privacy Center & Local Purge
- Route: `/privacy-center` (accessible from `HomeScreen` / Account dialog).
- Actions:
  - **Exportar Dados Pessoais & Clínicos**: Downloads or shares portable JSON file.
  - **Excluir Minha Conta Permanentemente**:
    - High-friction safety confirmation modal with warning and password / explicit text entry ("EXCLUIR").
    - On confirmation: calls `DELETE /v1/auth/account`.
    - Purges local Drift SQLite database (`appDatabase.triageOutbox.deleteAll()`, `appDatabase.localSymptomDrafts.deleteAll()`).
    - Clears `flutter_secure_storage` tokens.
    - Resets all Riverpod notifiers.
    - Navigates immediately to `/onboarding`.

### 2.4 Production Verification Suite
- End-to-end verification covering:
  - Cross-tenant RLS regression (User A cannot access User B's exported data or history).
  - Triage response latency benchmark (<2000ms SLA under concurrent requests).
  - Hard deletion audit (deleting User A wipes all rows in database and local cache).

## 3. Validation Architecture
- Backend Unit Tests: `auth-data-sovereignty.service.spec.ts`
- Backend E2E Tests: `auth-data-sovereignty.e2e-spec.ts`
- Mobile Unit & Widget Tests: `privacy_center_screen_test.dart`
- Full test pass rate across all phases.
