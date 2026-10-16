# Requirements: DualisCheckUp

**Defined:** 2026-09-13  
**Updated:** 2026-09-14 (Matched to SRS & Casos de Uso v1.0 Consolidada - Free Tier Focus)  
**Core Value:** Unified, safe, and clinically consistent daily health triage bridging somatic/physical symptoms and psycho-emotional states with immediate emergency escalation and 14-day anti-tampering historical verification.

## v1 Requirements (Free Tier Scope)

Requirements for initial release (Free Tier Vertical MVP). Structured around the 2 core modules and 8 defined screens directly matching SRS IDs 01–08 and RF-001–RF-009. Premium features (IDs 09–12 / RF-010–RF-013 / UC-02) are strictly deferred to v2.

---

### Module 1: Onboarding & Identity

- [x] **ONBD-01 (Screen 1 / SRS ID 01)**: User experiences splash animation and a 3-card value proposition carousel (Dual Triage, Encrypted Records, Preventive Insights) with "Sign In" and "Create Account" CTAs.
- [x] **AUTH-01 / RF-007 (Screen 2 / SRS ID 01)**: User registers via simplified registration collecting mandatory fields: Full Name, Date of Birth, Biological Sex (Gender), Email, Password, and mandatory LGPD health data privacy consent checkbox.
- [x] **AUTH-02**: User session persists securely with biometric auto-lock (FaceID/TouchID/BiometricPrompt) protecting sensitive health records on app backgrounding.
- [x] **I18N-01**: Mobile application establishes native trilingual localization across Brazilian Portuguese (`pt-BR`), Spanish (`es`), and English (`en`) via Flutter `intl` (`.arb` bundles) with runtime language toggle and `pt-BR` default fallback.

---

### Module 2: Free Tier Triage Engine

#### Screen 3: Home & Unified Dual-Axis Trigger Check-in (RF-001 & RF-009 / SRS ID 01, 04, 08)

- [ ] **TRG-01 / RF-001**: Every triage session begins with the mandatory dual-axis trigger question (*"Como você está se sentindo hoje?"* / *"How are you feeling today?"*) presenting two parallel/sequential assessment tracks from the very start:
  1. **Eixo Psico-Emocional**: Mandatory mental/emotional state evaluation with 3 icon+text options:
     - `[Bem / Normal]` (Good / Normal)
     - `[Mais ou menos]` (So-so — triggers standard AI triage)
     - `[Mal / Ruim]` (Bad / Sick — triggers high-sensitivity AI triage with heightened clinical surveillance)
  2. **Eixo Avaliação Física / Dor Física**: Mandatory physical discomfort/pain evaluation with 3 icon+text options:
     - `[Bem / Normal]` (Good / Normal)
     - `[Mais ou menos]` (So-so — triggers standard AI triage)
     - `[Mal / Ruim]` (Bad / Sick — triggers high-sensitivity AI triage with heightened clinical surveillance)
  - **Routing Matrix**:
    - If **both** are `[Bem / Normal]`: Concludes session immediately with a preventive wellness confirmation (zero triage friction).
    - If either is `[Mais ou menos]` or `[Mal / Ruim]`: Activates the dynamic 5-step triage wizard for the affected vertical(s).
    - If **both** report discomfort: Evaluates both verticals sequentially, enforcing Organic Primacy (evaluating physical pain before concluding emotional distress).
- [ ] **TRG-02 / RF-004**: User can input natural language lay-term descriptions (e.g., *"estou com febre"*, *"batedeira no peito"*, *"cabeça cheia"*) mapped into formal clinical matrices in under 2 seconds (RNF-002).
- [ ] **I18N-02**: AI symptom intake and prompt pipeline accepts and classifies symptoms in Brazilian Portuguese (`pt-BR`), Spanish (`es`), and English (`en`), accurately mapping colloquial distress idioms in all 3 languages (*"nó na garganta"* / *"nudo en la garganta"* / *"lump in the throat"*) into standardized categories.
- [ ] **AD-01 / RF-009 / SRS ID 08**: Screen renders a privacy-focused native AdMob ad banner container. The targeting algorithm strictly uses only general age group and approximate geolocation to attract local businesses (pharmacies, supermarkets, department stores); zero medical profiling or health data tracking.

#### Screen 4: Dynamic 5-Step Triage Wizard (RF-002 / SRS ID 02 & 03)

- [ ] **TRG-03 / RF-002**: Screen header displays a mandatory, prominent visual transition informing the user which vertical is active:
  - **Vertical A (Psico-Emocional)**: Visual banner *"Iniciando Autoavaliação Psico-Emocional"* with Soft Indigo (`#3F51B5`) chromatic theme.
  - **Vertical B (Física)**: Visual banner *"Iniciando Autoavaliação Física"* with Clinical Teal (`#00796B`) chromatic theme.
- [ ] **TRG-04 / RF-002**: User progresses through the standardized 5-step wizard (maximum 5 questions per vertical), adopting the exact clinical questioning structure:
  - **Vertical A: Autoavaliação Psico-Emocional**:
    1. *Natureza do Sintoma*: "Olhando para o seu lado emocional e mental, qual palavra descreve melhor o que você está sentindo agora?" (Options: Ansiedade/Agitação, Tristeza/Desânimo, Estresse/Irritabilidade, Cansaço Mental).
    2. *Tempo / Persistência*: "Você tem se sentido assim frequentemente nos últimos dias ou é algo muito específico de hoje?" (Options: Começou hoje, Já faz alguns dias, É algo constante há semanas).
    3. *Intensidade*: "Essa sensação está parecendo um leve incômodo de fundo ou algo forte que está acelerando seus pensamentos?" (Options: Leve e controlável, Moderada, Muito forte e difícil de segurar).
    4. *Investigação de Causas / Gatilhos*: "Você consegue identificar se existe um motivo principal para isso estar acontecendo hoje?" (Options: Trabalho/Estudos, Família/Relacionamentos, Noite ruim de sono, Não sei dizer).
    5. *Desfecho / Ação*: Cruzamento com ecossistema de artigos (ex: higiene do sono, exercícios de respiração e relaxamento).
  - **Vertical B: Autoavaliação Física**:
    1. *Localização do Sintoma*: "Vamos falar sobre a parte física. Onde você está sentindo esse desconforto ou dor principal?" (Options: Cabeça, Costas/Coluna, Articulações [Joelho, Ombro, etc.], Abdômen/Estômago).
    2. *Tempo / Persistência*: "Há quanto tempo essa dor ou anomalia persiste?" (Options: Começou agora, Há alguns dias, É crônica).
    3. *Intensidade*: "Em uma escala de 1 a 5 (onde 1 é quase imperceptível e 5 é insuportável), como está agora?" (Seletor numérico de 1 a 5).
    4. *Investigação de Causas / Gatilhos*: "Você lembra de ter feito algum esforço atípico, exercício pesado ou sofrido alguma batida/queda recentemente?" (Options: Sim, exercício intenso, Sim, sofri uma queda, Não, começou do nada).
    5. *Desfecho / Ação*: Cruzamento com artigos preventivos ou disparo de alertas de risco (ex: artigo de especialista renomado sobre dores articulares pós-treino).
- [ ] **TRG-05**: Riverpod state machine automatically disposes in-memory triage session data (`autoDispose`) immediately upon completion or cancellation.

#### Screen 5: Antiburla Historical Verification Sheet (RF-003 & UC-01 / SRS ID 05)

- [ ] **ANTI-01 / RF-003**: System executes an automated scan across PostgreSQL 14-day temporal indices `(user_id, recorded_at DESC)` in <15ms before processing the Step 2 (Tempo/Persistência) response.
- [ ] **ANTI-02 / UC-01**: If user states symptom "Começou hoje" / "Começou agora" but active logs exist in the past 14 days for the same dimension or anatomical region, system intercepts with an empathetic confrontation dialog:
  - *"Notei aqui no seu histórico que você também sentiu esse desânimo há poucos dias. Você acha que essa tristeza de hoje é um sentimento completamente novo ou pode ser aquela mesma sensação que acabou voltando?"*
  - Provides binary choice buttons: `[É a mesma sensação que voltou]` (normalizes internal temporal timeline for fidedignity without punitive rejection) vs. `[Sentimento completamente novo]`.
- [ ] **ANTI-03 / RF-003 Boundaries**: System implements strict biological and behavioral boundary guardrails:
  - Validates biological consistency against user registration profile (e.g., female user stating testicular pain is gently corrected to appropriate pelvic/anatomical terminology without hallucination).
  - Handles non-clinical behavioral/recreational queries (e.g., "tenho desejo de relação sexual", "sinto falta de beber cerveja") safely and respectfully without compromising clinical scope.

#### Screen 6: Triage Outcome, Somatic Mapping & Article Recommendations (RF-004 & RF-005 / SRS ID 04 & 06)

- [ ] **SOM-01 / RF-004**: System normalizes lay vocabulary into exhaustive official database matrices (SRS Section 4):
  - **7 Dimensões Psico-Emocionais**: 1. Ansiosa / Agitação, 2. Depressiva / Desânimo, 3. Estresse / Burnout, 4. Somática (Psicossomática: nó na garganta, aperto no peito emocional, gastrite nervosa), 5. Sono (Insônia/Hipersônia), 6. Cognitiva / Foco (névoa mental), 7. Autoestima / Autoimagem.
  - **12 Sistemas Físicos**: 1. Cabeça e Pescoço, 2. Cardiovascular / Tórax, 3. Respiratório, 4. Gastrointestinal / Abdômen, 5. Coluna e Dor Dorsal, 6. Membros Superiores (D/E), 7. Membros Inferiores (D/E), 8. Neurológico, 9. Geniturinário / Pélvico, 10. Dermatológico, 11. Muscular / Geral (Sistêmico), 12. Endócrino / Metabólico.
- [ ] **SOM-02**: System strictly enforces Organic Primacy: physical symptoms reported in combination with emotional distress trigger mandatory somatic checks before categorizing symptoms as purely psychological.
- [ ] **OUT-01**: Screen displays calculated intensity score (1 to 5) and care disposition (Auto-cuidado / Self-Care, Consulta de Rotina / Routine Visit, Pronto Atendimento / Urgent Care, Emergência / Emergency).
- [ ] **REC-01 / RF-005 / SRS ID 06**: Screen displays curated recommendation cards with direct links to educational articles written by renowned medical specialists, matched to the exact diagnosed theme.

#### Screen 7: Historical Dashboards & 2D Body Heat Map (RF-008 & SRS Section 5.1 / SRS ID 07)

- [ ] **DASH-01 / RF-008**: User can switch historical views via a segmented tab bar: Módulo Psico-Emocional vs. Módulo Físico.
- [ ] **DASH-02 / RF-008**: Módulo Físico renders an interactive 2D Anatomical Body Map (front and back human silhouette across 12 anatomical systems) with chromatic heat gradients reflecting recent logs (Amarelo = Dor Leve 1–2; Vermelho = Dor Forte / Intensidade 4–5).
- [ ] **DASH-03 / RF-008**: Módulo Psico-Emocional renders a 7-day linear trend graph (Tempo X vs. Intensidade 1–5 Y) plotting variations across the 7 emotional dimensions (`fl_chart`).
- [ ] **DASH-04 / Section 5.1**: Both dashboard verticals render dedicated longitudinal feeds:
  - **Cards de Recorrência Crítica**: Automated weekly accumulation alerts (e.g., *"⚠️ Foco de Atenção: Identificamos que a sua dimensão Estresse / Burnout esteve em nível 4 em 6 dos últimos 10 dias. Considerou ler nosso artigo?"*).
  - **Lista Retrospectiva**: Clean vertical scrolling feed with chronological entries (e.g., *"12/Set/2026 — Sentindo-se Mal (Dimensão Ansiosa - Intensidade 4). Motivo: Trabalho."* or *"10/Set/2026 — Sentindo-se Mais ou menos (Membros Inferiores / Joelho - Intensidade 3). Motivo: Exercício físico atípico."*).
- [ ] **SYNC-01**: User can perform check-ins offline with local encrypted Drift SQLite storage and background transactional outbox synchronization.

#### Screen 8: Emergency Risk Alert Screen (RF-006)

- [ ] **EMRG-01 / RF-006**: If at any step in either vertical the system detects high intensity (Level 4 or 5) associated with critical red-flag areas (acute chest pain, severe dyspnea, acute emotional crisis), the app immediately halts all questions.
- [ ] **EMRG-02 / RF-006**: System immediately displays a full-screen Red Emergency View (`#D32F2F`) locked against dismissal (`PopScope(canPop: false)`).
- [ ] **EMRG-03 / RF-006**: Emergency screen renders urgent emergency contacts with 1-tap dialer (SAMU 192, Bombeiros 193, CVV 188) and clear immediate life-safety instructions.

---

### Security, Compliance & Platform Architecture

- [x] **SEC-01 / RNF-001**: PostgreSQL Row-Level Security (`SET LOCAL app.current_user_id = :userId`) guarantees tenant isolation at database engine level.
- [x] **SEC-02 / RNF-001**: AES-256 encryption at rest, TLS 1.3 in transit, and São Paulo region data residency under LGPD Art. 11.
- [ ] **SEC-03**: Self-service account data export and permanent cascading deletion under LGPD Art. 18.
- [x] **DISC-01**: Prominent non-diagnostic medical disclaimers compliant with Anvisa RDC 657/2022 and CFM Res. 2.314/2022, localized in Brazilian Portuguese (`pt-BR`), Spanish (`es`), and English (`en`) via `GET /v1/legal/disclaimer`.

---

## v2 Requirements (Deferred Premium Tier Features)

The following features from SRS Sections 2, 3.3, 5.2 and UC-02 are explicitly categorized as **Premium Paga** and are deferred to v2:

- **PREM-01 / RF-010 (SRS ID 09)**: Prontuário Estruturado - CID (registro permanente de patologias CID-10/11 na aba *Minhas Condições & Diagnósticos*).
- **PREM-02 / RF-011 (SRS ID 10)**: Histórico Médico Completo (aba *Tratamentos & Medicamentos Contínuos* com alertas de horário, controle de estoque e histórico cirúrgico).
- **PREM-03 / RF-012 & UC-02 (SRS ID 11)**: Leitor de Exames Inteligente (upload de PDF/foto com pipeline desacoplado OCR + IA para extração de marcadores como PSA Total, valores e datas na aba *Biomarcadores & Exames Estruturados*).
- **PREM-04 / RF-013 (SRS ID 12)**: Gestão de Tiers de Assinatura Recorrente (monetização por volume de dados/armazenamento).
- **PREM-05 / CLIN-01**: One-Click "Doctor's Brief" SBAR Clinical PDF Export.

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Autonomous Medical Diagnosis (SaMD Class III) | Violates Anvisa RDC 657/2022 and CFM rules; induces cyberchondria; app provides triage risk stratification only. |
| Digital Prescription Ordering & Pharmacy Sales | Prohibited without licensed digital signature (ICP-Brasil, CFM Res. 2.299/2021); severe pharmacovigilance risks. |
| Unbounded Conversational Free-Chatbot | High latency, prompt injection, hallucination, input fatigue; replaced by structured dual-axis trigger + 5-step wizard. |
| Synchronous Telemedicine Video Consults | High burn rate and physician staffing overhead; out of scope for V1 triage platform. |
| Direct Hospital EHR Synchronization (FHIR/HL7) | Complex vendor locks in Brazilian market; delays MVP launch. |
| Gamification Badges / XP for Illness | Inappropriate for suffering; replaced by neutral preventive wellness streaks. |

---

## Traceability

Which phases cover which requirements.

| Requirement | Phase | Screen / Module | Status |
|-------------|-------|-----------------|--------|
| SEC-01 | Phase 1 | Backend Architecture | Complete |
| SEC-02 | Phase 1 | Backend Architecture | Complete |
| DISC-01 | Phase 1 | Compliance Baseline | Complete |
| ONBD-01 | Phase 2 | Screen 1: Onboarding & Auth Choice | Complete |
| AUTH-01 | Phase 2 | Screen 2: Simplified Registration (RF-007) | Complete |
| AUTH-02 | Phase 2 | Module 1 Security (Biometrics) | Complete |
| I18N-01 | Phase 2 | Multilingual Mobile Foundation (pt-BR, es, en) | Complete |
| EMRG-01 | Phase 3 | Screen 8: Emergency Risk Alert (RF-006) | Pending |
| EMRG-02 | Phase 3 | Screen 8: Emergency Risk Alert (RF-006) | Pending |
| EMRG-03 | Phase 3 | Screen 8: Emergency Risk Alert (RF-006) | Pending |
| TRG-03 | Phase 4 | Screen 4: 5-Step Triage Wizard (RF-002) | Pending |
| TRG-04 | Phase 4 | Screen 4: 5-Step Triage Wizard (RF-002) | Pending |
| TRG-05 | Phase 4 | Screen 4 State Machine Lifecycle | Pending |
| TRG-01 | Phase 5 | Screen 3: Home & Unified Trigger (RF-001) | Pending |
| TRG-02 | Phase 5 | Screen 3: AI NLP Mapping (RF-004) | Pending |
| I18N-02 | Phase 5 | Screen 3: Multilingual AI Idiom Intake | Pending |
| AD-01 | Phase 5 | Screen 3: Native AdMob Banner (RF-009) | Pending |
| SOM-01 | Phase 6 | Screen 6: Outcome & Somatic Mapping (RF-004) | Pending |
| SOM-02 | Phase 6 | Screen 6: Organic Primacy | Pending |
| OUT-01 | Phase 6 | Screen 6: Outcome & Disposition | Pending |
| REC-01 | Phase 6 | Screen 6: Curated Articles (RF-005) | Pending |
| ANTI-01 | Phase 7 | Screen 5: Antiburla Backend (RF-003) | Pending |
| ANTI-02 | Phase 7 | Screen 5: Antiburla Bottom Sheet (UC-01) | Pending |
| ANTI-03 | Phase 7 | Screen 5: Antiburla Boundary Validation | Pending |
| SYNC-01 | Phase 8 | Offline Drift Engine | Pending |
| DASH-01 | Phase 9 | Screen 7: Historical Dashboard (RF-008) | Pending |
| DASH-02 | Phase 9 | Screen 7: 2D Body Heat Map (RF-008) | Pending |
| DASH-03 | Phase 9 | Screen 7: Psico-Emocional Trend Graph (RF-008) | Pending |
| DASH-04 | Phase 9 | Screen 7: Recurrence Cards & Retrospective List | Pending |
| SEC-03 | Phase 10 | Privacy Center & Account Deletion (LGPD Art. 18) | Pending |

**Coverage:**
- v1 requirements: 30 total
- Mapped to phases: 30
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-13*  
*Last updated: 2026-09-14 after SRS v1.0 consolidation (Free Tier aligned)*
