# Phase 9 Validation Strategy: Historical Dashboard & 2D Body Heat Map

## 1. Automated Verification Commands

### 1.1 Backend Verification
- Unit tests: `npm run test -- test/unit/triage-history.service.spec.ts`
- E2E tests: `npm run test:e2e -- test/e2e/triage-history.e2e-spec.ts`
- Full backend suite: `npm run test && npm run test:e2e`

### 1.2 Mobile Client Verification
- Unit & Widget tests: `flutter test test/features/dashboard/`
- Full mobile suite: `flutter test`
- Static analysis: `flutter analyze` or Dart MCP `analyze_files`
- DTD hot reload/restart verification on connected simulator.

## 2. Test Coverage Matrix

| Requirement | Test Type | File | Key Assertion |
|-------------|-----------|------|---------------|
| DASH-01 | Widget Test | `test/features/dashboard/historical_dashboard_screen_test.dart` | Segmented tab toggles between Psico-Emocional and Física views |
| DASH-02 | Widget Test | `test/features/dashboard/anatomical_body_map_test.dart` | CustomPainter paints 12 regions with correct heat colors (yellow/amber/red/grey) based on 14-day max intensity |
| DASH-03 | Widget Test | `test/features/dashboard/emotional_trend_chart_test.dart` | Renders `fl_chart` LineChart with 7 data points and dimension series |
| DASH-04 | Widget / Unit | `test/features/dashboard/dashboard_controller_test.dart` | Evaluates recurrence condition (>=4 on >=6 of last 10 days) and builds retrospective entries |
| SEC-01 | E2E Test | `backend/test/e2e/triage-history.e2e-spec.ts` | RLS prevents User A from seeing User B's historical logs in `GET /v1/triage/history` |
