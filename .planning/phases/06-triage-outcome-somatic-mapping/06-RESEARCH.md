# Phase 6: Triage Outcome, Somatic Mapping & Article Recommendations (Screen 6 / RF-004 & RF-005) — Research

## Executive Summary

Phase 6 implements Screen 6: Triage Outcome & Curated Educational Articles (SRS ID 04 & 06). It serves as the culmination of the 5-step triage wizard, delivering clinical clarity to the patient. It normalizes lay expressions and colloquial Brazilian distress idioms into the 19 clinical categories (7 psycho-emotional dimensions and 12 anatomical physical systems), enforces the clinical principle of **Organic Primacy** (`SOM-02`), computes a 1–5 urgency intensity score and care disposition (`OUT-01`), and recommends evidence-based preventive articles authored by renowned medical specialists (`REC-01`).

---

## 1. Clinical Taxonomy & Somatic Matrix (SOM-01)

### 1.1 The 7 Psycho-Emotional Dimensions
1. **Ansiosa / Agitação**: Generalized anxiety, motor agitation, excessive worry, anticipatory tension.
2. **Depressiva / Desânimo**: Low mood, anhedonia, profound sadness, lack of motivation.
3. **Estresse / Burnout**: Work exhaustion, emotional depletion, irritability under cognitive load.
4. **Somática (Psicossomática)**: Bodily manifestations of emotional stress (*"nó na garganta"*, *"aperto no peito funcional"*, *"gastrite nervosa"*, *"tensão cervical"*).
5. **Sono**: Sleep latency problems, middle-of-night awakenings, early morning waking, hypersomnia.
6. **Cognitiva / Foco**: Brain fog (*névoa mental*), concentration difficulties, short-term working memory lapses.
7. **Autoestima / Autoimagem**: Feelings of inadequacy, harsh self-criticism, body dissatisfaction.

### 1.2 The 12 Physical Anatomical Systems
1. **Cabeça e Pescoço**: Cephalea, migraine, tension headache, cervical pain, sinusitis.
2. **Cardiovascular / Tórax**: Non-critical chest discomfort, palpitations, mild tachycardia (non-emergency).
3. **Respiratório**: Mild cough, nasal congestion, seasonal airway reactivity.
4. **Gastrointestinal / Abdômen**: Epigastric burning, bloating, dyspepsia, mild nausea, intestinal irregularities.
5. **Coluna e Dor Dorsal**: Lumbar strain, thoracic pain, postural back fatigue.
6. **Membros Superiores (D/E)**: Shoulder tendinopathy, elbow epicondylitis, wrist strain.
7. **Membros Inferiores (D/E)**: Patellar soreness, ankle strain, calf tightness, plantalgia.
8. **Neurológico**: Peripheral paresthesias, mild dizziness, postural instability (non-stroke).
9. **Geniturinário / Pélvico**: Dysuria, mild lower abdominal discomfort, menstrual cramp.
10. **Dermatológico**: Urticaria, eczema flare, pruritus, mild contact dermatitis.
11. **Muscular / Geral (Sistêmico)**: Post-exercise myalgia, diffuse bodily aches, mild malaise.
12. **Endócrino / Metabólico**: Mild thermoregulation changes, unexplained fatigue, hydration imbalances.

---

## 2. Organic Primacy Protocol (SOM-02)

**Clinical Rule:** Whenever a patient reports both emotional distress (e.g. panic, extreme stress) and physical discomfort (e.g. chest constriction, epigastric pain, shortness of breath), the system **must never dismiss the physical symptoms as purely psychosomatic without first ruling out organic pathology**.

- **Implementation**:
  - The outcome evaluation flags `organicPrimacyApplied: true`.
  - The UI presents a dedicated Organic Primacy Guidance banner: *"Atenção Clínica: Embora você sinta estresse emocional, seus sintomas físicos (ex: desconforto torácico/gástrico) exigem avaliação médica física prioritária antes de atribuí-los unicamente à ansiedade."*
  - Care disposition cannot be downgraded below `Consulta de Rotina` if physical symptoms are concurrent.

---

## 3. Care Disposition Matrix (OUT-01)

| Intensity Score | Clinical Definition | Recommended Care Disposition | Action Timeline |
|---|---|---|---|
| **1 – 2** | Leve / Autolimitado | **Auto-cuidado (Self-Care)** | Monitorar sintomas, repouso, hidratação, técnicas de respiração |
| **3** | Moderado / Persistente | **Consulta de Rotina (Routine Visit)** | Agendar consulta médica ou psicológica nos próximos 7–14 dias |
| **4** | Significativo / Agudo | **Pronto Atendimento (Urgent Care)** | Buscar avaliação médica presencial em até 24 horas |
| **5** | Crítico / Alerta Vermelho | **Emergência (Emergency)** | Redirecionamento imediato para Screen 8 (SAMU 192 / CVV 188) |

---

## 4. Curated Preventive Educational Articles (REC-01)

Articles written by verified clinical specialists, indexed by category:
- **Cardiovascular**: *"Compreendendo as Palpitações e Quando Procurar um Cardiologista"* — Dra. Beatriz Silva (Cardiologista, InCor).
- **Coluna / Muscular**: *"Ergonomia no Home Office e Prevenção de Dores Lombares"* — Dr. Marcelo Mendes (Ortopedista, HCFMUSP).
- **Ansiedade / Sono**: *"Higiene do Sono e Técnicas de Respiração Diafragmática"* — Dra. Camila Prado (Psiquiatra, ABP).
- **Estresse / Burnout**: *"Gerenciamento do Estresse Crônico e Pausas Restaurativas"* — Dr. Lucas Rossi (Psicólogo Clínico, CRP SP).
- **Gastrointestinal**: *"Eixo Intestino-Cérebro: Como o Estresse Afeta Sua Digestão"* — Dra. Fernanda Toledo (Gastroenterologista, FBG).

---

## 5. Validation Architecture

- **Backend Unit & E2E**:
  - `backend/test/unit/triage-outcome.service.spec.ts`: Tests 19-category taxonomy mapping, idiom translation, Organic Primacy priority assignment, and intensity-to-disposition calculations.
  - `backend/test/e2e/triage-outcome.e2e-spec.ts`: Tests `POST /v1/triage/outcome` with JWT auth, AES-256 encryption in `symptom_logs`, and article matching.
- **Mobile Widget & Unit**:
  - `mobile/test/features/triage_outcome/triage_outcome_screen_test.dart`: Verifies intensity score gauge (1-5), disposition card, Organic Primacy alert, and specialist article cards.
