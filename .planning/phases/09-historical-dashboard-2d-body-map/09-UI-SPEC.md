# Phase 9 UI Specification: Screen 7 Historical Dashboard & 2D Body Heat Map

## 1. Overview & Visual Identity

Screen 7 provides users with visual introspection over their preventive health data. It supports switching between two distinct visual vertical themes:
- **Módulo Psico-Emocional**: Soft Indigo (`#3F51B5`) primary theme with gentle card containers and multi-colored dimensional series.
- **Módulo Físico**: Clinical Teal (`#00796B`) primary theme with anatomical silhouette and chromatic pain heat gradients.

## 2. Color Tokens

| Token | Hex Value | Purpose |
|-------|-----------|---------|
| `tabIndigoActive` | `#3F51B5` | Active tab background for Psico-Emocional |
| `tabTealActive` | `#00796B` | Active tab background for Física |
| `heatNeutral` | `#CFD8DC` | Anatomical region with 0 reported symptoms |
| `heatMild` | `#FFD54F` | Anatomical region with mild intensity (1–2) |
| `heatModerate` | `#FF8A65` | Anatomical region with moderate intensity (3) |
| `heatSevere` | `#E53935` | Anatomical region with severe intensity (4–5) |
| `recurrenceCardBg` | `#FFF8E1` | Background for Cards de Recorrência Crítica |
| `recurrenceBorder` | `#FFE082` | Border for Cards de Recorrência Crítica |
| `recurrenceIcon` | `#F57C00` | Warning icon for Cards de Recorrência Crítica |

## 3. Screen Structure & Layout

### 3.1 App Bar & Tab Navigation
- AppBar Title: *"Histórico & Tendências"* (localized in pt, es, en).
- Segmented Tab Bar at the top:
  - Left segment: *"Módulo Psico-Emocional"* (Icon: `psychology_rounded`).
  - Right segment: *"Módulo Físico"* (Icon: `accessibility_new_rounded`).

### 3.2 Módulo Físico View
1. **Interactive 2D Anatomical Body Map**:
   - Centered container displaying human body silhouette (anterior/front and posterior/back or switchable).
   - 12 anatomical regions individually colored by recent 14-day max intensity.
   - Region selection chips or tap detection revealing bottom summary card showing selected region, peak intensity, and last reported date.
   - Legend bar below silhouette: [Neutro] [1-2 Leve] [3 Moderado] [4-5 Intenso].
2. **Cards de Recorrência Crítica** (if physical recurrence detected):
   - Warning badge, explanation, and CTA to read matched preventive physical article.
3. **Lista Retrospectiva (Física)**:
   - Header: *"Registros Físicos Recentes"*.
   - Chronological list of cards with date, system name, intensity pill (1–5), and recorded trigger ("Exercício intenso", "Esforço atípico", "Começou do nada").

### 3.3 Módulo Psico-Emocional View
1. **7-Day Emotional Trend Chart (`fl_chart`)**:
   - Container with title: *"Tendência dos Últimos 7 Dias"*.
   - Line chart with Y-axis 1 to 5 and X-axis showing past 7 dates.
   - Distinct colored lines for active dimensions.
   - Touch tooltip showing exact dimension, date, and intensity.
   - Dimension legend underneath the chart.
2. **Cards de Recorrência Crítica**:
   - Container with title: *"Foco de Atenção"*.
   - Alert card: *"Identificamos que a sua dimensão Estresse / Burnout esteve em nível 4 em 6 dos últimos 10 dias. Considerou ler nosso artigo?"*
   - CTA button: *"Ler Artigo Recomendado"*.
3. **Lista Retrospectiva (Psico-Emocional)**:
   - Header: *"Registros Emocionais Recentes"*.
   - Chronological list of cards with date, dimension name, feeling state, intensity pill, and identified trigger ("Trabalho/Estudos", "Família", "Noite ruim de sono").

## 4. Copywriting (Trilingual Keys)

- `historyScreenTitle`: "Histórico & Tendências" / "Historial y Tendencias" / "History & Trends"
- `tabEmotional`: "Psico-Emocional" / "Psicoemocional" / "Psycho-Emotional"
- `tabPhysical`: "Física" / "Física" / "Physical"
- `bodyMapTitle`: "Mapa Corporal 2D (14 Dias)" / "Mapa Corporal 2D (14 Días)" / "2D Body Map (14 Days)"
- `bodyMapHint`: "Toque em uma região para ver detalhes" / "Toca una región para ver detalles" / "Tap a region to view details"
- `heatLegendNone`: "Sem dor" / "Sin dolor" / "No pain"
- `heatLegendMild`: "Leve (1-2)" / "Leve (1-2)" / "Mild (1-2)"
- `heatLegendModerate`: "Moderada (3)" / "Moderada (3)" / "Moderate (3)"
- `heatLegendSevere`: "Intensa (4-5)" / "Intensa (4-5)" / "Severe (4-5)"
- `emotionalChartTitle`: "Evolução Emocional (7 Dias)" / "Evolución Emocional (7 Días)" / "Emotional Evolution (7 Days)"
- `criticalRecurrenceTitle`: "Foco de Atenção" / "Foco de Atención" / "Focus of Attention"
- `retrospectiveFeedTitle`: "Registros Anteriores" / "Registros Anteriores" / "Past Records"
- `emptyHistoryTitle`: "Nenhum registro ainda" / "Sin registros aún" / "No records yet"
- `emptyHistorySubtitle`: "Seus check-ins diários aparecerão aqui." / "Tus chequeos diarios aparecerán aquí." / "Your daily check-ins will appear here."
