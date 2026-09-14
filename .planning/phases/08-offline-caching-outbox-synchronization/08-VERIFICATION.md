# Phase 8: Offline Caching & Outbox Synchronization — Verification Strategy

**Phase:** 8 — Offline Caching & Outbox Synchronization  
**Requirement:** SYNC-01  

---

## 1. Test Matrix

| Layer | Component | Test Target | Command |
|---|---|---|---|
| Backend | `TriageOutcomeService` | Idempotent submission using `clientSessionId` | `npm run test:e2e -- test/e2e/outbox-idempotency.e2e-spec.ts` |
| Mobile | `AppDatabase` | Drift table creation, CRUD, and FIFO queue sorting | `flutter test test/core/database/app_database_test.dart` |
| Mobile | `SyncOutboxWorker` | Automatic synchronization upon connectivity restoration | `flutter test test/features/sync/sync_outbox_worker_test.dart` |
| Mobile | `TriageWizardScreen` | Seamless offline check-in with outbox queuing | `flutter test test/features/triage/triage_wizard_screen_test.dart` |

---

## 2. Acceptance Criteria

1. Submitting a triage outcome offline stores the session locally in Drift SQLite `triage_outbox`.
2. A client session UUID is generated per check-in and sent to the backend.
3. Multiple submissions with identical `clientSessionId` return the original outcome without creating duplicate database rows in PostgreSQL.
4. When connectivity returns, the outbox worker uploads pending entries in exact chronological order (`ORDER BY created_at ASC`).
5. All backend and mobile tests pass 100%.
