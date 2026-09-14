# Phase 8: Offline Caching & Outbox Synchronization — Technical Research

**Phase:** 8 — Offline Caching & Outbox Synchronization  
**Requirement:** SYNC-01  
**Scope:** Free Tier ONLY  

---

## 1. Executive Summary

Digital health applications must remain fully functional and clinically safe when the user lacks network connectivity (e.g. rural areas, underground transit, cellular outages). Under requirement **SYNC-01**, DualisCheckUp allows the patient to perform daily symptom check-ins completely offline. 

The architecture guarantees:
1. **Local Relational Storage**: Drift (SQLite) with encrypted schema stores drafted and completed triage sessions locally.
2. **Transactional Outbox Pattern**: Completed offline check-ins are enqueued with unique `clientSessionId` (UUID v4) and status `PENDING_SYNC`.
3. **Connectivity-Aware Resilient Sync Worker**: Monitors cellular and Wi-Fi status using `connectivity_plus`. When network connectivity resumes, the worker processes queued outbox items chronologically (`ORDER BY created_at ASC`) without duplicate submissions.
4. **Backend Idempotency Gate**: NestJS `POST /v1/triage/outcome` accepts `clientSessionId`. If already recorded, returns the existing record idempotently.
5. **Zero-Failure Emergency Safety**: Clinical emergency triggers (Level 4/5) are evaluated locally on-device and trigger the native dialer (`192` / `188`) immediately, regardless of network connectivity.

---

## 2. Key Architecture Components

### 2.1 Drift SQLite Database (`AppDatabase`)
- **Location**: `mobile/lib/core/database/`
- **Schema**:
  - `local_symptom_drafts`: Holds active triage wizard states and drafts.
  - `triage_outbox`: Outbox queue items:
    - `id`: Auto-increment integer PK.
    - `clientSessionId`: UUID v4 string (idempotency key).
    - `vertical`: 'physical' | 'emotional'.
    - `stepAnswersJson`: JSON string of `{1: '...', 2: '...'}`.
    - `narrative`: Optional string.
    - `status`: Enum string ('pending', 'syncing', 'synced', 'failed').
    - `attempts`: Integer (retry count).
    - `lastError`: Nullable string.
    - `createdAt`: DateTime.
    - `syncedAt`: Nullable DateTime.

### 2.2 Connectivity Service (`ConnectivityService`)
- Uses `connectivity_plus` to monitor device connection status.
- Provides `Stream<bool> isOnlineStream` and `bool get isOnline`.

### 2.3 Outbox Sync Worker (`SyncOutboxWorker`)
- Listens to `isOnlineStream`. When online and queue has pending items:
  - Transitions item status to `syncing`.
  - Transmits via `TriageOutcomeRemoteDataSource.submitTriage(..., clientSessionId: item.clientSessionId)`.
  - On success: marks item as `synced` with timestamp.
  - On failure: increments `attempts` and records `lastError`.

### 2.4 Backend Idempotency Engine
- Updates `symptom_logs` table with optional `client_session_id`.
- Migration `0006_symptom_logs_client_session_id.sql`.
- Checks for existing log with same `(user_id, client_session_id)` before insert.

---

## 3. Validation Architecture

- **Mobile Unit & Database Tests**:
  - `mobile/test/core/database/app_database_test.dart`: In-memory Drift database verification for CRUD operations and outbox FIFO ordering.
  - `mobile/test/features/sync/sync_outbox_worker_test.dart`: Mock outbox worker verifying chronological processing, retry backoff, and state transitions.
- **Backend E2E Idempotency Tests**:
  - `backend/test/e2e/outbox-idempotency.e2e-spec.ts`: Submitting twice with identical `clientSessionId` returns identical outcome without duplicate row insertion.
