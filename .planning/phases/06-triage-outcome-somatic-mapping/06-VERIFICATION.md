# Phase 6: Verification Plan

## Automated Tests

1. **Backend Unit Tests:**
   - `backend/test/unit/triage-outcome.service.spec.ts`
     - Validates 19-category taxonomy mapping
     - Validates Organic Primacy logic (physical priority over psychosomatic)
     - Validates 1–5 intensity calculation and disposition mapping
     - Validates article matching by taxonomy category

2. **Backend E2E Tests:**
   - `backend/test/e2e/triage-outcome.e2e-spec.ts`
     - `POST /v1/triage/outcome` 401 unauthorized check
     - `POST /v1/triage/outcome` valid payload with persistence to `symptom_logs`
     - Verification of encrypted narrative and disposition

3. **Mobile Tests:**
   - `mobile/test/features/triage_outcome/triage_outcome_screen_test.dart`
     - Renders intensity meter (1 to 5)
     - Renders disposition card
     - Displays Organic Primacy banner when enabled
     - Displays specialist articles
     - Conclude CTA returns to Home
   - Full mobile test suite (`flutter test`)
