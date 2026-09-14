# Phase 9 Research: Historical Dashboard & 2D Body Heat Map (Screen 7 / RF-008 & Section 5.1)

## 1. Executive Summary

Phase 9 delivers Screen 7: Historical Dashboard, providing users with a longitudinal visualization of their physical and psycho-emotional health records over rolling 7-day and 14-day windows.
The requirements comprise:
- **DASH-01**: Segmented tab bar toggling between Módulo Psico-Emocional and Módulo Físico.
- **DASH-02**: Interactive 2D Anatomical Body Map (`CustomPainter`) mapping 12 physical systems with chromatic heat gradients reflecting 14-day symptom intensity (Yellow for 1–2, Amber for 3, Crimson Red for 4–5).
- **DASH-03**: 7-day linear emotional trend graph (`fl_chart`) tracking the 7 emotional dimensions over time (Intensity 1–5 on Y-axis, Days on X-axis).
- **DASH-04**: Dedicated longitudinal feeds for both verticals:
  - **Cards de Recorrência Crítica**: Automated weekly accumulation alerts (e.g., alert when dimension intensity >= 4 for >= 6 of last 10 days).
  - **Lista Retrospectiva**: Vertical scrolling feed with chronological entries displaying formatted date, feeling indicator, classified dimension/system, intensity score, and identified triggers.

All backend historical data retrieval must enforce PostgreSQL Row-Level Security (`SET LOCAL app.current_user_id = :userId`) and support offline-first local cache fallback via Drift SQLite.

## 2. Technical Decisions & Architecture

### 2.1 Backend History Aggregation (`GET /v1/triage/history`)
- Endpoint: `GET /v1/triage/history` (protected by `JwtAuthGuard`).
- Query: Optional `days` parameter (default 14, min 1, max 30).
- Data source: `symptom_logs` table filtered by `recorded_at >= NOW() - INTERVAL '14 days'` using the existing index `idx_symptom_logs_user_recorded` (`user_id, recorded_at DESC`).
- Response payload:
  - `logs`: Chronological list of user's triage records.
  - `physicalSummary`: Map of 12 anatomical systems to their peak intensity within the 14-day window.
  - `emotionalSummary`: Daily aggregated data points per emotional dimension over the last 7 days for plotting.
  - `criticalRecurrences`: Evaluated recurrence conditions (e.g. intensity >= 4 for >= 6 of the last 10 days) with recommended specialist article recommendations.

### 2.2 Interactive 2D Anatomical Body Map (`CustomPainter`)
- Flutter's native `CustomPainter` renders 2D vector human silhouette paths (anterior and posterior views).
- The 12 anatomical systems (from SRS Section 4) mapped to distinct visual path regions:
  1. `cabeca_pescoco` (Head & Neck)
  2. `cardiovascular_torax` (Chest / Thorax)
  3. `respiratorio` (Upper/Lower Respiratory)
  4. `gastrointestinal_abdomen` (Abdomen / Stomach)
  5. `coluna_dorsal` (Spine & Back)
  6. `membros_superiores_d` (Right Arm & Shoulder)
  7. `membros_superiores_e` (Left Arm & Shoulder)
  8. `membros_inferiores_d` (Right Leg, Knee & Foot)
  9. `membros_inferiores_e` (Left Leg, Knee & Foot)
  10. `neurologico` (Central Nervous / Head glow)
  11. `geniturinario_pelvico` (Pelvic & Genitourinary)
  12. `dermatologico` (Skin / Generalized overlay)
- Chromatic Heat Gradient:
  - Intensity 0: Base neutral silhouette `#CFD8DC` with outline `#90A4AE`
  - Intensity 1–2 (Mild): Soft warm yellow `#FFD54F` to `#FFA000`
  - Intensity 3 (Moderate): Warm orange `#FF8A65` to `#F4511E`
  - Intensity 4–5 (Severe): Vibrant clinical crimson `#E53935` to `#C62828`
- Hit testing (`hitTest(Offset)` or `GestureDetector` on regions) enables tapping a system to view its recent peak intensity, latest log timestamp, and trigger notes.

### 2.3 7-Day Emotional Trend Multi-Line Chart (`fl_chart: ^1.2.0`)
- `LineChart` from `fl_chart: ^1.2.0`.
- X-axis: 7 days (formatted as `dd/MM` or day abbreviations `Seg`, `Ter`, `Qua`...).
- Y-axis: Intensity scale 1 to 5.
- Multi-line representation with distinct accessible color palette for the 7 emotional dimensions:
  1. Ansiosa / Agitação: Soft Purple (`#7E57C2`)
  2. Depressiva / Desânimo: Slate Blue (`#5C6BC0`)
  3. Estresse / Burnout: Coral Orange (`#FF7043`)
  4. Somática (Psicossomática): Teal (`#26A69A`)
  5. Sono: Indigo (`#3949AB`)
  6. Cognitiva / Foco: Cyan (`#00ACC1`)
  7. Autoestima: Rose (`#EC407A`)
- Touch tooltips display exact date, dimension name, and intensity level.

### 2.4 Cards de Recorrência Crítica & Lista Retrospectiva
- **Recurrence Engine**: Inspects 14-day history for frequency spikes (e.g., dimension intensity >= 4 occurring in >= 6 of the last 10 days, or >= 3 days in the past 7 days).
- Renders an attention card with icon `warning_amber_rounded`, title, descriptive explanation, and CTA to read a matched specialist article.
- **Lista Retrospectiva**: Scrollable list of past triage sessions with:
  - Date & time formatted per locale
  - Feeling indicator (`[Mal]`, `[Mais ou menos]`, `[Bem]`)
  - Classification badge (Anatomical System or Emotional Dimension)
  - Intensity chip (1–5 with color dot)
  - Identified triggers (e.g., "Trabalho/Estudos", "Exercício intenso")

### 2.5 Segmented Tab Bar & Styling
- Segmented control toggling between:
  - `Psico-Emocional`: Highlighted in Soft Indigo (`#3F51B5`)
  - `Física`: Highlighted in Clinical Teal (`#00796B`)
- Animated cross-fade or indexed stack between views.

## 3. Validation Architecture

- **Backend**:
  - Unit tests (`triage-history.service.spec.ts`): Verify 14-day query boundaries, physical max intensity aggregation, emotional 7-day grouping, recurrence calculation, and tenant isolation.
  - E2E tests (`triage-history.e2e-spec.ts`): Verify `GET /v1/triage/history` returns HTTP 200 with structured payload, validates query parameters, and rejects unauthenticated requests with HTTP 401.
- **Mobile Client**:
  - Unit tests (`triage_history_model_test.dart`, `dashboard_controller_test.dart`): Test JSON deserialization, recurrence detection logic, and offline data merging.
  - Widget tests (`historical_dashboard_screen_test.dart`, `anatomical_body_map_test.dart`, `emotional_trend_chart_test.dart`): Verify segmented tab switching, body map rendering with heat colors, chart display, recurrence cards, and retrospective feed.
