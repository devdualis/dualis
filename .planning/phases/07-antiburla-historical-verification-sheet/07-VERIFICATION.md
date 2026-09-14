# Phase 7: Verification Plan

## Automated Tests

1. **Backend Unit Tests:**
   - `backend/test/unit/antiburla.service.spec.ts`:
     - Evaluates 14-day history scan
     - Validates non-triggering when previous log is >14 days old
     - Validates non-triggering when symptom is not "comecou_hoje"
     - Validates biological boundary discordance detection (e.g. female user selecting testicular pain)

2. **Backend E2E Tests:**
   - `backend/test/e2e/antiburla.e2e-spec.ts`:
     - Tests `POST /v1/triage/antiburla-check` with 401 unauthenticated check
     - Tests `POST /v1/triage/antiburla-check` returning 200 with `triggered: true` when prior log exists

3. **Mobile Widget Tests:**
   - `mobile/test/features/triage/antiburla_bottom_sheet_test.dart`:
     - Verifies presentation of Screen 5 bottom sheet
     - Verifies UC-01 empathetic text
     - Verifies binary button taps and callback invocations
   - Full mobile test suite execution (`flutter test`)
