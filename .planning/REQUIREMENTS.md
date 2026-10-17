# Requirements: DualisCheckUp

**Defined:** 2026-09-13  
**Updated:** 2026-10-16 (Reframed for Health & Wellness Repositioning — Free Tier Focus)  
**Core Value:** Daily physical and psycho-emotional wellness journaling with self-reported tracking, longitudinal habit patterns, and always-on, universally accessible emergency help resources.

## v1 Requirements (Free Tier Scope)

Requirements for initial release (Free Tier Vertical MVP). Structured around personal wellness journaling, habits, educational readings, and universal safety resources matching SRS IDs 01–08 and RF-001–RF-009. Premium features (IDs 09–12 / RF-010–RF-013 / UC-02) are strictly deferred to v2.

---

### Module 1: Onboarding & Identity

- [x] **ONBD-01 (Screen 1 / SRS ID 01)**: User experiences splash animation and a 3-card value proposition carousel (Diário de Bem-Estar Integrado, Seus Dados Protegidos, Conteúdos para Hábitos Saudáveis) with "Sign In" and "Create Account" CTAs.
- [x] **AUTH-01 / RF-007 (Screen 2 / SRS ID 01)**: User registers via simplified registration collecting mandatory fields: Full Name, Date of Birth, Biological Sex (Gender), Email, Password, and mandatory LGPD Art. 11, I health data privacy consent checkbox.
- [x] **AUTH-02**: User session persists securely with biometric auto-lock (FaceID/TouchID/BiometricPrompt) protecting sensitive personal records on app backgrounding.
- [x] **I18N-01**: Mobile application establishes native trilingual localization across Brazilian Portuguese (`pt-BR`), Spanish (`es`), and English (`en`) via Flutter `intl` (`.arb` bundles) with runtime language toggle and `pt-BR` default fallback.

---

### Module 2: Free Tier Wellness Journal Engine

#### Screen 3: Home & Unified Dual-Axis Check-in (RF-001 & RF-009 / SRS ID 01, 04, 08)

- [ ] **TRG-01 / RF-001**: Every daily check-in begins with the mandatory dual-axis question (*"Como você está se sentindo hoje?"* / *"How are you feeling today?"*) presenting two parallel tracks:
  1. **Eixo Psico-Emocional**: Mental/emotional self-reported state with 3 options:
     - `[Bem / Normal]` (Good / Normal)
     - `[Mais ou menos]` (So-so — triggers emotional journal flow)
     - `[Mal / Ruim]` (Bad — triggers emotional journal flow)
  2. **Eixo Registro Físico**: Physical self-reported comfort with 3 options:
     - `[Bem / Normal]` (Good / Normal)
     - `[Mais ou menos]` (So-so — triggers physical journal flow)
     - `[Mal / Ruim]` (Bad — triggers physical journal flow)
  - **Routing Matrix**:
    - If **both** are `[Bem / Normal]`: Concludes check-in immediately with a wellness confirmation (zero friction).
    - If either is `[Mais ou menos]` or `[Mal / Ruim]`: Activates the 5-step journal wizard for the affected vertical(s).
    - If **both** report discomfort: Evaluates both verticals sequentially, and presents a static dual-axis reflection note ("Você registrou sensações no corpo e nas emoções hoje. Se algum desconforto físico persistir ou piorar, converse com um profissional de saúde.").
- [ ] **TRG-02 / RF-004**: User can input natural language lay-term descriptions (e.g., *"batedeira no peito"*, *"cabeça cheia"*, *"dor na lombar"*) mapped into body areas or mood categories without clinical diagnostic evaluation or urgency scoring in under 2 seconds (RNF-002).
- [ ] **I18N-02**: AI entry intake accepts and tags entries in Brazilian Portuguese (`pt-BR`), Spanish (`es`), and English (`en`), accurately mapping colloquial expressions in all 3 languages (*"nó na garganta"* / *"nudo en la garganta"* / *"lump in the throat"*) into standardized body areas or emotional states.
- [ ] **AD-01 / RF-009 / SRS ID 08**: Screen renders a privacy-focused native AdMob ad banner container. The targeting algorithm strictly uses only general age group and approximate geolocation to attract local businesses (pharmacies, supermarkets, department stores); zero medical profiling or health data tracking.

#### Screen 4: Dynamic 5-Step Wellness Journal Wizard (RF-002 / SRS ID 02 & 03)

- [ ] **TRG-03 / RF-002**: Screen header displays a mandatory visual transition informing the user which vertical is active:
  - **Vertical A (Psico-Emocional)**: Visual banner *"Registro emocional de hoje"* with Soft Indigo (`#3F51B5`) chromatic theme.
  - **Vertical B (Física)**: Visual banner *"Registro físico de hoje"* with Teal (`#00796B`) chromatic theme.
- [ ] **TRG-04 / RF-002**: User progresses through the standardized 5-step wizard (maximum 5 questions per vertical), adopting lay-friendly journaling questions:
  - **Vertical A: Registro Emocional**:
    1. *Natureza*: "Olhando para o seu lado emocional e mental, qual palavra descreve melhor o que você está sentindo agora?" (Options: Pra baixo / Desanimado(a), Estressado(a) / Esgotado(a), Tensão no corpo, Sono ruim ou sono demais, Inquieto(a) / Agitado(a)).
    2. *Tempo / Persistência*: "Você tem se sentido assim frequentemente nos últimos dias ou é algo muito específico de hoje?" (Options: Começou hoje, Já faz alguns dias, É algo constante há semanas).
    3. *Intensidade Informada*: "Essa sensação está parecendo um leve incômodo de fundo ou algo forte que está acelerando seus pensamentos?" (Options: Leve e controlável, Moderada, Muito forte).
    4. *Causas / Gatilhos*: "Você consegue identificar se existe um motivo principal para isso estar acontecendo hoje?" (Options: Trabalho/Estudos, Família/Relacionamentos, Noite ruim de sono, Não sei dizer).
    5. *Revisar e Salvar*: Revisão do registro pessoal e apresentação de leituras sobre bem-estar (higiene do sono, respiração, relaxamento).
  - **Vertical B: Registro Físico**:
    1. *Localização*: "Vamos falar sobre a parte física. Onde você está sentindo esse desconforto principal?" (Options: Cabeça e pescoço, Peito, Respiração, Barriga, Costas, Braços, Pernas, Pele, Região íntima / urinária, Corpo todo / cansaço, Tontura / formigamento, Sede, fome ou energia).
    2. *Tempo / Persistência*: "Há quanto tempo esse desconforto persiste?" (Options: Começou agora, Há alguns dias, É algo frequente).
    3. *Intensidade Informada*: "Em uma escala de 1 a 5 (onde 1 é quase imperceptível e 5 é muito intenso), como está agora?" (Seletor numérico de 1 a 5, claramente identificado como intensidade autorrelatada).
    4. *Causas / Gatilhos*: "Você lembra de ter feito algum esforço atípico, exercício pesado ou sofrido alguma batida/queda recentemente?" (Options: Sim, exercício intenso, Sim, sofri uma queda, Não, começou do nada).
    5. *Revisar e Salvar*: Revisão do registro pessoal e apresentação de leituras educativas gerais sobre postura, hábitos e alongamento.
- [ ] **TRG-05**: Riverpod state machine automatically disposes in-memory journal session data (`autoDispose`) immediately upon completion or cancellation.

#### Screen 5: Recurrence Consistency Verification Sheet (RF-003 & UC-01 / SRS ID 05)

- [ ] **ANTI-01 / RF-003**: System executes an automated scan across PostgreSQL 14-day temporal indices `(user_id, recorded_at DESC)` in <15ms before processing the Step 2 (Tempo/Persistência) response.
- [ ] **ANTI-02 / UC-01**: If user states discomfort "Começou hoje" / "Começou agora" but active logs exist in the past 14 days for the same dimension or area, system intercepts with an empathetic reconciliation dialog:
  - *"Notei aqui no seu histórico que você também registrou essa sensação há poucos dias. Quer registrar como algo que voltou, para seu diário ficar organizado?"*
  - Provides binary choice buttons: `[É a mesma sensação que voltou]` vs. `[Sentimento completamente novo]`.
- [ ] **ANTI-03 / RF-003 Boundaries**: System implements respectful boundary guardrails:
  - Handles non-journal behavioral/recreational queries safely and respectfully without compromising product scope.

#### Screen 6: Check-in Summary, Body Area Mapping & Wellness Readings (RF-004 & RF-005 / SRS ID 04 & 06)

- [ ] **SOM-01 / RF-004**: System normalizes lay vocabulary into standard body areas and emotional states without clinical diagnostic evaluation or urgency scoring:
  - **7 Dimensões Emocionais**: Pra baixo, Estresse/Esgotamento, Tensão no corpo, Sono, Inquieto/Agitado, Foco/Concentração, Autoimagem.
  - **12 Áreas Corporais**: Cabeça e Pescoço, Peito, Respiração, Barriga, Costas, Braços, Pernas, Pele, Região íntima/urinária, Corpo todo/cansaço, Tontura/formigamento, Sede/fome/energia.
- [ ] **SOM-02**: If the user registers physical discomfort and emotional distress on the same day, system renders a static reflection note: *"Você registrou sensações no corpo e nas emoções hoje. Se algum desconforto físico persistir ou piorar, converse com um profissional de saúde."* (no differential organic primacy reasoning / somatização).
- [ ] **OUT-01**: Screen displays user self-reported intensity ("Intensidade que você informou: n/5") and universal static guidance block ("Este app não avalia sua saúde. Se algum desconforto persistir, piorar ou te preocupar, procure um profissional de saúde. Em emergência, ligue 192.") instead of calculated care disposition.
- [ ] **REC-01 / RF-005 / SRS ID 06**: Screen displays curated educational wellness reading cards ("Leituras sobre bem-estar") citing authentic public health sources (e.g., Ministério da Saúde), accompanied by the note: *"Conteúdos educativos gerais. Não são orientação para o seu caso."*

#### Screen 7: Historical Dashboards & 2D Body Map (RF-008 & SRS Section 5.1 / SRS ID 07)

- [ ] **DASH-01 / RF-008**: User can switch historical views via a segmented tab bar: Módulo Psico-Emocional vs. Módulo Físico.
- [ ] **DASH-02 / RF-008**: Módulo Físico renders an interactive 2D Anatomical Body Map reflecting recent self-reported intensities across body areas.
- [ ] **DASH-03 / RF-008**: Módulo Psico-Emocional renders a 7-day linear trend graph tracking emotional variations over time (`fl_chart`).
- [ ] **DASH-04 / Section 5.1**: Both dashboard verticals render dedicated longitudinal feeds:
  - **Cards de Padrões nos Registros**: Automated accumulation summaries (e.g., *"Você registrou estresse/esgotamento com intensidade alta 4 vezes nos últimos 10 dias. Se isso está atrapalhando seu dia a dia, pode ser útil conversar com um profissional de saúde."*).
  - **Lista Retrospectiva**: Clean vertical scrolling feed with chronological self-reported entries (e.g., *"12/Set/2026 — Registro Emocional (Intensidade informada: 4/5). Motivo: Trabalho."*).
- [ ] **SYNC-01**: User can perform check-ins offline with local encrypted Drift SQLite storage and background transactional outbox synchronization.

#### Screen 8: Always-On Emergency Help Resources (RF-006)

- [ ] **EMRG-01 / RF-006**: Global "Ajuda urgente" button reachable in ≤1 tap from all main authenticated screens and login; non-blocking contextual safety card if user selects intensity 5 or enters alarm text.
- [ ] **EMRG-02 / RF-006**: Universal emergency resources screen with static warning signs cited from official public health sources (Ministério da Saúde / SAMU) and country-specific emergency numbers (BR: 192, 188, 193, 190); fully dismissable (no PopScope lock), works offline.
- [ ] **EMRG-03 / RF-006**: Minimal safety resource event logging (`POST /v1/journal/safety-event`, action: `opened_resources` | `call_started`, clientTimestamp) with zero-failure guarantee and no clinical severity profiling.

---

### Security, Compliance & Platform Architecture

- [x] **SEC-01 / RNF-001**: PostgreSQL Row-Level Security (`SET LOCAL app.current_user_id = :userId`) guarantees tenant isolation at database engine level.
- [x] **SEC-02 / RNF-001**: AES-256 encryption at rest, TLS 1.3 in transit, and São Paulo region data residency under LGPD Art. 11.
- [ ] **SEC-03**: Self-service account data export and permanent cascading deletion under LGPD Art. 18.
- [x] **DISC-01**: Prominent wellness and non-diagnostic disclaimers localized in Brazilian Portuguese (`pt-BR`), Spanish (`es`), and English (`en`) via `GET /v1/legal/disclaimer` reflecting canonical intended use statement §1.1. Intended as a wellness app; regulatory confirmation pending.

---

## v2 Requirements (Versão Premium & Advanced)

A comercialização da versão 2.0 será dividida em dois tiers comerciais principais, além da modalidade familiar:
- **Tier Premium**: Inclui funcionalidades pessoais de histórico, leitor de exames para transcrição, leitor de receitas como formulário editável e gestão de permissões (tudo, exceto Bulário e Registro por Voz).
- **Tier Advanced**: Acesso completo aos recursos do ecossistema DualisCheckUp (incluindo acesso a Bulário oficial e Registro por Voz pós-login). Recursos de ajuda e emergência são sempre gratuitos e universais em todos os tiers.
- **Modalidade Pacote Família**: Precificação unificada para grupos familiares com gestão integrada de permissões legais e dependentes dentro do mesmo pacote.

### Funcionalidades Essenciais (Core Premium)

- [ ] **PREM-01 / RF-010 (SRS ID 09)**: **Minhas Condições (Informadas pelo Usuário)** — Registro pessoal de condições e diagnósticos informados pelo próprio usuário conforme orientações de seu médico, sem inferência diagnóstica pelo app.
- [ ] **PREM-02 / RF-011 (SRS ID 10)**: **Histórico de Cuidados Pessoais & Lembretes de Medicamentos** — Aba *Tratamentos & Medicamentos* com alertas de horário de doses configurados pelo usuário, controle de estoque pessoal e anotações de consultas.
- [ ] **PREM-06 / PERM-01**: **Cadastro de Permissão Legal (Representação Legal & Dependência)** — Suporte a múltiplos perfis dependentes sob tutela ou responsabilidade legal (menores de idade ou maiores dependentes sob guarda legal). Em conformidade estrita com LGPD Art. 14 (consentimento de pais/responsáveis legais e isolamento de dados via PostgreSQL RLS).
- [ ] **PREM-07 / PERM-02**: **Cadastro de Permissão Opcional (Compartilhamento Consentido)** — Vinculação consensual entre contas (casal, irmãos, cuidadores informais ou outros familiares), com níveis de acesso granulares (leitura/edição) e revogação imediata a qualquer momento.
- [ ] **PREM-08 / VACC-01**: **Controle de Vacinação** — Caderneta digital de vacinação abrangendo vacinas do calendário nacional oficial (PNI/SUS) e vacinas particulares informadas pelo usuário, com registro de doses aplicadas, datas, lotes e lembretes de reforço baseados no calendário oficial publicado.
- [ ] **PREM-09 / ALRG-01**: **Registro de Alergias Informadas** — Cadastro explícito de alergias informadas pelo usuário (fármacos e alimentos) exibidas no perfil e no resumo de registros (sem verificação clínica cruzada automática).
- [ ] **PREM-05 / CLIN-01**: **Resumo dos Registros em PDF** — Exportação instantânea em PDF com resumo cronológico dos registros pessoais autorrelatados (datas, intensidades informadas, notas do usuário, alergias e tratamentos informados) para compartilhamento voluntário com profissionais de saúde, sem seções de avaliação clínica ou recomendação terapêutica.

### Melhorias Não Essenciais / Ingestão Avançada & IA

- [ ] **PREM-10 / PRIC-01**: **Precificação Pacote Família** — Estrutura de assinatura e checkout recorrente para grupos familiares com permissão legal e múltiplos dependentes integrados no mesmo plano.
- [ ] **PREM-11 / BULA-01**: **Acesso a Bulas Oficiais (Exclusivo Tier Advanced)** — Integração e link direto com o Bulário Eletrônico da ANVISA para consulta de bulas oficiais de medicamentos.
- [ ] **PREM-12 / RX-01**: **Leitor de Receita Médica para Formulário Editável (OCR Nativo)** — Digitalização de receitas médicas preenchendo um formulário editável com confirmação obrigatória campo a campo pelo usuário antes de salvar lembretes pessoais.
- [ ] **PREM-03 / RF-012 & UC-02 (SRS ID 11)**: **Transcrição de Exames Laboratoriais (OCR)** — Upload de PDF/foto de laudos com transcrição conferida pelo usuário de biomarcadores e intervalos de referência impressos pelo laboratório, sem alertas de alteração, cores diagnósticas ou comentários clínicos de IA.
- [ ] **PREM-13 / AUTH-03**: **Opções Avançadas de Log In Biométrico** — Configurações expandidas de autenticação biométrica nativa (FaceID / TouchID / Biometrics): opções de ativação/desativação, tempo de timeout customizável e reautenticação biométrica para acessar registros e exportação de dados.
- [ ] **PREM-14 / VOICE-01**: **Registro por Voz pós-login (Exclusivo Tier Advanced)** — Interface assistida por voz (Speech-to-Text) após o login para registro ágil de anotações no diário de bem-estar.
- [ ] **PREM-04 / RF-013 (SRS ID 12)**: **Gestão de Tiers de Assinatura Recorrente** — Monetização e gestão de acesso via checkout seguro com suporte aos tiers Free, Premium, Advanced e Pacote Família. Recursos de ajuda urgente permanecem sempre 100% gratuitos.

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Autonomous Medical Diagnosis & Clinical Triage | Violates wellness intended use; app provides personal wellness logging only, not medical diagnosis or clinical risk triage. |
| Automated Drug-Allergy Conflict Detection | Regulated clinical decision support feature (MDSW); deferred/excluded to remain within general wellness scope. |
| Unbounded Conversational Free-Chatbot | High latency, prompt injection, hallucination; replaced by structured dual-axis check-in + 5-step journal flow. |
| Synchronous Telemedicine Video Consults | High burn rate and physician staffing overhead; out of scope for wellness logging platform. |
| Direct Hospital EHR Synchronization (FHIR/HL7) | Complex vendor locks in Brazilian market; delays MVP launch. |
| Gamification Badges / XP for Illness | Inappropriate; replaced by positive daily habit streaks. |

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
| EMRG-01 | Phase 3 | Screen 8: Always-On Safety Resources (RF-006) | Pending |
| EMRG-02 | Phase 3 | Screen 8: Always-On Safety Resources (RF-006) | Pending |
| EMRG-03 | Phase 3 | Screen 8: Always-On Safety Resources (RF-006) | Pending |
| TRG-03 | Phase 4 | Screen 4: 5-Step Journal Wizard (RF-002) | Pending |
| TRG-04 | Phase 4 | Screen 4: 5-Step Journal Wizard (RF-002) | Pending |
| TRG-05 | Phase 4 | Screen 4 State Machine Lifecycle | Pending |
| TRG-01 | Phase 5 | Screen 3: Home & Unified Trigger Check-in (RF-001) | Pending |
| TRG-02 | Phase 5 | Screen 3: AI NLP Entry Tagging (RF-004) | Pending |
| I18N-02 | Phase 5 | Screen 3: Multilingual AI Idiom Intake | Pending |
| AD-01 | Phase 5 | Screen 3: Native AdMob Banner (RF-009) | Pending |
| SOM-01 | Phase 6 | Screen 6: Summary & Body Area Mapping (RF-004) | Pending |
| SOM-02 | Phase 6 | Screen 6: Dual-Axis Reflection Note | Pending |
| OUT-01 | Phase 6 | Screen 6: Summary & Static Guidance | Pending |
| REC-01 | Phase 6 | Screen 6: Curated Educational Articles (RF-005) | Pending |
| ANTI-01 | Phase 7 | Screen 5: Recurrence Check Backend (RF-003) | Pending |
| ANTI-02 | Phase 7 | Screen 5: Recurrence Check Bottom Sheet (UC-01) | Pending |
| ANTI-03 | Phase 7 | Screen 5: Boundary Validation | Pending |
| SYNC-01 | Phase 8 | Offline Drift Engine | Pending |
| DASH-01 | Phase 9 | Screen 7: Historical Dashboard (RF-008) | Pending |
| DASH-02 | Phase 9 | Screen 7: 2D Body Map (RF-008) | Pending |
| DASH-03 | Phase 9 | Screen 7: Psico-Emocional Trend Graph (RF-008) | Pending |
| DASH-04 | Phase 9 | Screen 7: Pattern Cards & Retrospective List | Pending |
| SEC-03 | Phase 10 | Privacy Center & Account Deletion (LGPD Art. 18) | Pending |

**Coverage:**
- v1 requirements: 30 total
- Mapped to phases: 30
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-13*  
*Last updated: 2026-10-16 after Wellness Repositioning consolidation*
