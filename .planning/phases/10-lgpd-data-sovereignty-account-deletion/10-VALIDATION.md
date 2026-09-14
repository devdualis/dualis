# Phase 10 Validation Strategy: LGPD Data Sovereignty & Production Verification

## 1. Automated Verification Commands

### 1.1 Backend Verification
- Unit tests: `npm run test -- test/unit/auth-data-sovereignty.service.spec.ts`
- E2E tests: `npm run test:e2e -- test/e2e/auth-data-sovereignty.e2e-spec.ts`
- Full backend suite: `npm run test && npm run test:e2e`

### 1.2 Mobile Client Verification
- Unit & Widget tests: `flutter test test/features/privacy/`
- Full mobile suite: `flutter test`
- Static analysis: `flutter analyze`
- Live runtime: Hot restart and DTD verification on connected simulator.

## 2. Test Coverage Matrix

| Requirement | Test Type | File | Key Assertion |
|-------------|-----------|------|---------------|
| SEC-03 (Export) | Backend Unit/E2E | `backend/test/e2e/auth-data-sovereignty.e2e-spec.ts` | `GET /v1/auth/export-data` returns full JSON export with profile, decrypted narratives, and consent logs |
| SEC-03 (Deletion) | Backend Unit/E2E | `backend/test/e2e/auth-data-sovereignty.e2e-spec.ts` | `DELETE /v1/auth/account` verifies password, cascades deletion to all child tables, and prevents future logins |
| SEC-03 (Client Wipe) | Mobile Widget Test | `mobile/test/features/privacy/privacy_center_screen_test.dart` | Triggering deletion calls API, purges local Drift database, clears secure storage tokens, and navigates to Onboarding |
| RNF-001 (RLS Isolation) | Backend Regression | `backend/test/e2e/auth-data-sovereignty.e2e-spec.ts` | User A cannot export or delete User B's data under any circumstance |
| RNF-002 (SLA Latency) | Backend Latency Test | `backend/test/e2e/ai.e2e-spec.ts` | AI triage response completes in under 2000ms SLA |
