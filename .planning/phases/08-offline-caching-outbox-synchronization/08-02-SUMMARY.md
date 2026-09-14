# Plan 08-02 Summary: Network Connectivity Monitoring, Resilient Outbox Worker, and Offline UI State

**Phase:** 8 — Offline Caching & Outbox Synchronization  
**Plan:** 08-02  
**Status:** Complete  
**Executed at:** 2026-09-14  

---

## Deliverables Completed

1. **Trilingual Localization for Offline & Sync Status (T1 / I18N-01):**
   - Added `offlineBannerText`, `offlineSyncPendingCount`, `offlineSyncSuccessText`, and `offlineModeNotice` across `app_pt.arb`, `app_es.arb`, and `app_en.arb`.
   - Recompiled localizations via `flutter gen-l10n`.

2. **Connectivity Service (T2 / SYNC-01):**
   - Created `mobile/lib/core/network/connectivity_service.dart`.
   - Listens to device connectivity status with `isOnlineStream` and `checkOnline()`.
   - Added `isOnlineProvider` and `connectivityServiceProvider`.

3. **Resilient Background Outbox Sync Worker (T3 / SYNC-01):**
   - Created `mobile/lib/features/sync/presentation/controllers/sync_outbox_worker.dart`.
   - Listens to `isOnlineProvider` and drains pending items chronologically when connectivity is restored.
   - Updates status to `syncing`, submits with `clientSessionId`, marks `synced` on success, or updates status to `failed` with incremented `attempts` on network error.

4. **Connect Outbox Enqueueing to Triage Flow (T4 / SYNC-01):**
   - Updated `TriageOutcomeRemoteDataSource.submitTriage` with optional `clientSessionId` and public `generateOfflineFallback`.
   - Updated `TriageWizardScreen._buildBottomBar`: when submitting Step 5, checks connectivity, generates a unique UUID `clientSessionId`, and if offline (or if submission fails), enqueues to `TriageOutboxRepository` and seamlessly presents the offline outcome.

5. **Offline Status Banner Widget (T5):**
   - Created `mobile/lib/features/sync/presentation/widgets/offline_indicator_banner.dart`.
   - Displays a slim amber banner when offline and indicates pending sync items.
   - Mounted in `HomeScreen`.

6. **Automated Tests & Hot Restart (T6):**
   - Created `mobile/test/features/sync/sync_outbox_worker_test.dart` (3 tests passing).
   - Full suite passing: 130/130 tests green!
   - Hot restart verified on iPhone 16e simulator (`ws://127.0.0.1:65413/YQuv23Upp3M=/ws`).

---

## Verification Output

```
00:00 +0: SyncOutboxWorker & Offline Sync Tests (SYNC-01) drains pending items and marks them synced upon successful transmission
00:00 +1: SyncOutboxWorker & Offline Sync Tests (SYNC-01) marks item failed and increments attempts when transmission fails
00:00 +2: SyncOutboxWorker & Offline Sync Tests (SYNC-01) OfflineIndicatorBanner shows offline state and pending sync count
00:00 +3: All tests passed!
```
