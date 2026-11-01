# Journal v2 contract (Dualis Free)

Shared contract between backend and mobile for the new daily journal. Source of truth for the strategy: `ESTRATEGIA-MEJORAS-DUALIS-FREE.md` (sections 5 to 18). If something here conflicts with that document, this contract wins for field names; the strategy wins for product rules.

## Hard rules

- No field, column, constant, enum, comment or doc may contain clinical grouping: `group`, `clinical`, `diagnos*`, `symptom_structured`, `sphere`/`esfera`, `system` (anatomical), `treatment`, `vertical_tratamento`, disorder names (TAG, TOC, TEPT, bipolar, ciclotim*, anedonia, radiculopatia…), `urgency`, `severity`, `risk`, `careDisposition`, `isCritical`.
- The app stores what the user chose (`optionKey`) or wrote (`customLabel`), never a translation of it.
- No content, ad or notice depends on what the user recorded.
- Intensity is always self-reported, integer 1..5.
- Condition names (`userConditions.label`) and journal notes are never sent to an AI: AI tagging is removed from the product.

## Keys

### Emotional (`kind = "emotional"`)
`optionKey` = `<time>.<branch>.<option>`:

| time | branch | options |
|---|---|---|
| `passado` | `tristeza` | `culpa`, `saudade` |
| `passado` | `memoria` | `lembranca`, `magoa` |
| `presente` | `energia` | `corpo`, `desligado` |
| `presente` | `sobrecarga` | `paciencia`, `aperto` |
| `futuro` | `mente` | `antecipar`, `cobranca` |
| `futuro` | `medo` | `julgamento`, `desanimo` |

Custom: `optionKey = "<time>.custom"` (time chosen by the user) + `customLabel`.

### Physical (`kind = "physical"`)
`optionKey` = `<region>.<branch>.<option>`, plus `bodySide` = `front` | `back` (null for whole-body regions) and, from v2.1, `sensation` = `dor` | `incomodo`:

| region | branch | options | side |
|---|---|---|---|
| `cabeca` | `pressao` | `temporas`, `latejando` | front, back |
| `cabeca` | `sentidos` | `garganta`, `olhos` | front |
| `cabeca` | `nuca` | `rigida`, `pontada` | back (v2.1) |
| `peito` | `respiracao` | `curta`, `tosse` | front |
| `peito` | `incomodo` | `batedeira`, `costelas` | front |
| `barriga` | `queimacao` | `subindo`, `enjoo` | front |
| `barriga` | `colica` | `gases`, `pontadas` | front |
| `costas` | `rigidez` | `ombros`, `lombar` | back |
| `costas` | `fisgada` | `irradia`, `ao_mexer` | back |
| `membros` | `cansaco` | `juntas`, `pesados` | front, back |
| `membros` | `formigamento` | `dormentes`, `choque` | front, back |
| `pele` | `coceira` | `coceira`, `ardencia` | whole body (v2.1) |
| `pele` | `aparencia` | `vermelhidao`, `manchas` | whole body (v2.1) |
| `musculos` | `tensao` | `rigidez`, `caibra` | whole body (v2.1) |
| `musculos` | `cansaco` | `fraqueza`, `dolorido` | whole body (v2.1) |
| `hormonios` | `temperatura` | `calorao`, `frio` | whole body (v2.1) |
| `hormonios` | `apetite` | `sede`, `fome` | whole body (v2.1) |

Custom: `optionKey = "<region>.custom"` + `customLabel`, for every region (`pele`, `musculos`, `hormonios` included). A custom key follows its region's side.

**Side rules (v2.1).** Front shows `cabeca` {`pressao`, `sentidos`}, `peito`, `barriga`, `membros`. Back shows `cabeca` {`pressao`, `nuca`}, `costas`, `membros`. Whole body (`pele`, `musculos`, `hormonios`) has no side: `bodySide` must be null (absent). Every other region needs `bodySide`. The backend enforces the side of each sided option only on v2.1 entries (`area` set); entries without `area` (older apps, queued outbox records) keep accepting any side for the old keys. Backend source: `PHYSICAL_SIDE_BRANCHES` in `journal-keys.constant.ts`.

**Sensation (v2.1).** `dor` | `incomodo`, chosen by the person. Required on physical items of entries with `area`; optional (null) on entries without `area`; never accepted on emotional or condition items.

#### Labels for the v2.1 keys (lay words only)

| key | pt | en | es |
|---|---|---|---|
| `pele` | Pele | Skin | Piel |
| `musculos` | Músculos | Muscles | Músculos |
| `hormonios` | Hormônios e metabolismo | Hormones and metabolism | Hormonas y metabolismo |
| `cabeca.nuca` | Nuca | Back of the neck | Nuca |
| `cabeca.nuca.rigida` | Nuca dura ou pesada | Stiff or heavy neck | Nuca rígida o pesada |
| `cabeca.nuca.pontada` | Pontada na parte de trás | Sharp pain at the back | Punzada en la parte de atrás |
| `pele.coceira` | Coceira ou ardência | Itching or burning | Picor o ardor |
| `pele.coceira.coceira` | Coceira | Itching | Picor |
| `pele.coceira.ardencia` | Ardência | Burning | Ardor |
| `pele.aparencia` | Aparência da pele | How the skin looks | Aspecto de la piel |
| `pele.aparencia.vermelhidao` | Vermelhidão | Redness | Enrojecimiento |
| `pele.aparencia.manchas` | Manchas | Spots | Manchas |
| `musculos.tensao` | Tensão | Tension | Tensión |
| `musculos.tensao.rigidez` | Rigidez | Stiffness | Rigidez |
| `musculos.tensao.caibra` | Cãibra | Cramp | Calambre |
| `musculos.cansaco` | Cansaço muscular | Tired muscles | Cansancio muscular |
| `musculos.cansaco.fraqueza` | Fraqueza | Weakness | Debilidad |
| `musculos.cansaco.dolorido` | Dolorido | Sore | Adolorido |
| `hormonios.temperatura` | Temperatura | Temperature | Temperatura |
| `hormonios.temperatura.calorao` | Calorões | Hot flushes | Sofocos |
| `hormonios.temperatura.frio` | Frio fora do comum | Unusually cold | Frío fuera de lo normal |
| `hormonios.apetite` | Apetite e sede | Appetite and thirst | Apetito y sed |
| `hormonios.apetite.sede` | Sede fora do comum | Unusually thirsty | Sed fuera de lo normal |
| `hormonios.apetite.fome` | Fome fora do comum | Unusually hungry | Hambre fuera de lo normal |
| `dor` | Dor | Pain | Dolor |
| `incomodo` | Incômodo | Discomfort | Molestia |

Never a disorder, grouping or organ-system name as a label ("endócrino" is banned as a user-facing label; the area is "Hormônios e metabolismo").

### Condition (`kind = "condition"`)
`conditionId` (uuid of a `userConditions` row), no `optionKey`.

### Persistence
`hoje` | `dias_semanas` | `meses_anos` (nullable for conditions).

### Triggers (entry level, multi-select, optional)
`trabalho`, `familia`, `sono`, `alimentacao`, `esforco`, `queda`, `medicamento`, `clima`, `nao_sei`, `outro` (+ `triggerNote`, max 60 chars).
`alimentacao`, `esforco`, `queda`, `medicamento`, `clima` are only offered when the entry has a physical item.

### General mood (entry level)
`bem` | `nao_tao_bem` for new entries. `normal` stays valid only on entries without `area` (reading old data and old outbox records); the backend rejects it on entries with `area`.

### Area (entry level, v2.1)
`emotional` | `physical` | null. Each new entry records ONE axis: an `emotional` entry has no physical items, a `physical` entry has no emotional items (condition items are allowed in both). Null = entry saved before v2.1. A "Bem" entry with `area = emotional` completes only the emotional axis on Home, never the physical one.

## Data model (PostgreSQL, RLS by profile like `symptom_logs`)

`journal_entries`: `id uuid pk`, `profile_id`, `user_id`, `recorded_at timestamptz`, `mood text`, `area text null` (`emotional` | `physical`, v2.1, migration 0020), `triggers text[]`, `trigger_note text null`, `note text null` (encrypted like current free text), `transition_variant_ids text[]` (UX analytics only), `client_id text` (outbox idempotency, unique per `(profile_id, client_id)`), `created_at`.

`journal_items`: `id uuid pk`, `entry_id fk cascade`, `kind text`, `option_key text null`, `custom_label text null` (max 80, encrypted), `condition_id uuid null fk`, `body_side text null`, `sensation text null` (`dor` | `incomodo`, physical items only, v2.1, migration 0020), `persistence text null`, `intensity smallint 1..5 null` (null only when mood is bem/normal and there are no items, so in practice items always have intensity).

`user_conditions`: `id uuid pk`, `profile_id`, `user_id`, `label text` (max 40, encrypted), `created_at`, `archived_at null`.

Old `symptom_logs` rows stay as they are and are returned by history as `legacy: true` items.

## API (`/v1/journal`, JWT, active profile header as today)

- `POST /v1/journal/entries` → 201 `JournalEntryDto`. Body: `{ clientId, recordedAt, mood, area?, triggers[], triggerNote?, note?, transitionVariantIds[], items: [{ kind, optionKey?, customLabel?, conditionId?, bodySide?, sensation?, persistence?, intensity }] }`. Validation: keys from the tables above only; max 12 items; with `area`: one axis, mood `bem`/`nao_tao_bem`, `sensation` on physical items, side rules.
- `GET /v1/journal/entries?days=30` (max 365; Free UI uses 30) → `{ entries: JournalEntryDto[] }` newest first, including legacy rows mapped to `{ legacy: true, items: [{ kind, legacyLabel, intensity }] }`.
- `DELETE /v1/journal/entries/:id` → 204.
- `GET /v1/journal/conditions` → `{ conditions: [{ id, label, createdAt }] }`.
- `POST /v1/journal/conditions` `{ label }` → 201. Max 10 active per profile.
- `DELETE /v1/journal/conditions/:id` → 204 (soft archive; past items keep the label).
- `GET /v1/journal/summary?days=30&tzOffset=0` → counts only: `{ byTime: {passado,presente,futuro}, byRegion: {cabeca,…}, byOptionKey: {…}, byTrigger: {…}, cooccurrence: [{ a, b, days }] }`. No labels, no text, no interpretation.
  - **Summary markers**: option `<root>.<branch>.<option>`, branch `<root>.<branch>`, region bare (`cabeca`), time bare (`futuro`), trigger `trigger:<key>`. The client resolves all of these to labels, branches included.
  - **Counts in `/summary`** (`byTime`, `byRegion`, `byOptionKey`, `byTrigger`, `cooccurrence`): DISTINCT LOCAL DAYS, not entries.
  - **Local day**: client sends `tzOffset` (minutes east of UTC, e.g. -180 for Brasília, validated range -720..840) as a query parameter to `GET /v1/journal/summary` and `GET /v1/hydration/history`; the server groups by that local day (default 0).
- `GET /v1/house-ads` → `{ ads: [{ id, brand, title, body, imageUrl?, assetKey?, url }] }`. Static list, identical for every user, never receives entry data. Demo brands: Dualis Premium, ZOC, WGI, UBO (fictional, internal examples).

`JournalEntryDto` = the stored entry with decrypted `note`, `area` (null on older entries), items with decrypted `customLabel`, `sensation` (null on older and non-physical items), and for condition items the condition `label`.

`/summary` has no item lists, so it carries no `area` or `sensation`; its counts and markers are unchanged (whole-body regions appear in `byRegion` as `pele`, `musculos`, `hormonios`). Co-occurrence text only counts days and never interprets, e.g. "Em 5 dos 9 dias com dor na cabeça você também marcou Futuro · Mente".

## AI suggest (catalog chips only)
`POST /v1/journal/suggest-option` `{ text, kind: emotional|physical, branch?, bodySide? }` → `{ optionKey }`. With `bodySide` (physical) only chips shown on that side, plus whole-body chips, can be suggested. Gemini may map the phrase onto **one existing diary chip** from the journal v2 trees, or `null`. With `branch` (the branch on screen, e.g. `futuro.mente`) only that branch's options can be suggested, so an accepted option is visible where the person is. It never invents keys, never names disorders, never scores intensity. The app asks the person to confirm; a "no" keeps the written custom label. Before the call the server de-identifies the text (names, e-mails, links, @handles and long numbers such as phone or CPF become placeholders) and sends only that text and `kind` to Vertex AI (`southamerica-east1`), as its own content, separate from the instructions. No user, profile or entry identifiers are sent, and the text is never logged. Live quality check: `backend/scripts/journal-suggest-eval.ts`. The old `/v1/ai/tag-entry` routes and `symptom_knowledge` stay gone.

## v2.2: more wellness questions and daily habits (2026-10-31)

Same hard rules as above. Everything is what the person chose; nothing is scored, grouped or interpreted, and no content, ad or notice depends on it. Old entries and old app versions keep working: every new field is optional and every v2.1 key stays valid. Migration: `0026_journal_v2_2_wellness.sql`.

### 1. Good moments (`kind = "positive"`)
Offered only when the entry mood is `bem` and `area = "emotional"`. Flow: mood "Bem" → "Que bom! Quer anotar o que fez seu dia bom?" with **"Só registrar"** (saves at once, as today) or the same three times → branch → options (multi-select). No persistence, no intensity, no triggers, no closing questions.

`optionKey = <time>.<branch>.<option>` from this tree (branch names never repeat an emotional branch):

| key | pt | en | es |
|---|---|---|---|
| `passado.gratidao` | Gratidão | Gratitude | Gratitud |
| `passado.gratidao.alguem` | Grato(a) por alguém | Grateful for someone | Agradecido(a) por alguien |
| `passado.gratidao.algo` | Grato(a) por algo que aconteceu | Grateful for something that happened | Agradecido(a) por algo que pasó |
| `passado.orgulho` | Orgulho | Pride | Orgullo |
| `passado.orgulho.conquista` | Consegui algo que queria | I got something I wanted | Logré algo que quería |
| `passado.orgulho.resolvi` | Resolvi algo que me pesava | I sorted out something that weighed on me | Resolví algo que me pesaba |
| `presente.calma` | Calma | Calm | Calma |
| `presente.calma.paz` | Em paz, tranquilo(a) | At peace, relaxed | En paz, tranquilo(a) |
| `presente.calma.descansado` | Descansado(a), com energia | Rested, with energy | Descansado(a), con energía |
| `presente.conexao` | Conexão | Connection | Conexión |
| `presente.conexao.pessoas` | Bem com as pessoas ao meu redor | Good with the people around me | Bien con la gente a mi alrededor |
| `presente.conexao.foco` | Focado(a) no que estou fazendo | Focused on what I'm doing | Enfocado(a) en lo que hago |
| `futuro.animo` | Ânimo | Looking forward | Ánimo |
| `futuro.animo.planos` | Animado(a) com meus planos | Excited about my plans | Ilusionado(a) con mis planes |
| `futuro.animo.esperanca` | Com esperança | Hopeful | Con esperanza |
| `futuro.confianca` | Confiança | Confidence | Confianza |
| `futuro.confianca.confiante` | Confiante no que vem | Confident about what's ahead | Confiado(a) en lo que viene |
| `futuro.confianca.preparado` | Preparado(a) | Ready for it | Preparado(a) |

Custom: `kind = "positive"`, `optionKey = "<time>.custom"` + `customLabel` ("✏️ Escrever o meu"). Positive text is **never** sent to the AI suggestion.

Item rules: `kind = "positive"` requires `optionKey` from the positive tree (or `<time>.custom`), and `intensity`, `persistence`, `bodySide`, `sensation`, `conditionId` all null. An entry with positive items has `mood = "bem"`, `area = "emotional"`, no emotional/physical items (condition items still allowed), `triggers = []`, `coping = null`, `helpers = []`.

### 2. New emotional options ("Não tão bem")

| key | pt | en | es |
|---|---|---|---|
| `passado.memoria.vergonha` | Vergonha de algo que fiz ou disse | Embarrassed about something I did or said | Vergüenza por algo que hice o dije |
| `presente.energia.concentracao` | Difícil me concentrar ou lembrar das coisas | Hard to focus or remember things | Me cuesta concentrarme o recordar cosas |
| `presente.sobrecarga.muita_coisa` | Muita coisa ao mesmo tempo | Too much at once | Demasiadas cosas a la vez |
| `presente.sobrecarga.inquieto` | Agitado(a), inquieto(a) | Restless and unsettled | Agitado(a), inquieto(a) |
| `presente.solidao` (branch) | Sozinho(a) ou inseguro(a) | Lonely or unsure of myself | Solo(a) o inseguro(a) |
| `presente.solidao.sozinho` | Me sinto sozinho(a) | I feel lonely | Me siento solo(a) |
| `presente.solidao.menos` | Me sinto menos que os outros | I feel less than others | Me siento menos que los demás |
| `futuro.mente.indecisao` | Não consigo decidir | I can't make up my mind | No logro decidir |
| `futuro.medo.evitar` | Vontade de evitar ou fugir de uma situação | I want to avoid or get away from something | Ganas de evitar o huir de una situación |

Resulting emotional tree: `passado` {`tristeza`: culpa, saudade · `memoria`: lembranca, magoa, vergonha} · `presente` {`energia`: corpo, desligado, concentracao · `sobrecarga`: paciencia, aperto, muita_coisa, inquieto · `solidao`: sozinho, menos} · `futuro` {`mente`: antecipar, cobranca, indecisao · `medo`: julgamento, desanimo, evitar}. Max 4 options per screen.

### 3. New physical options

| key | side | pt | en | es |
|---|---|---|---|---|
| `cabeca.rosto` (branch) | front | Tontura, nariz, ouvido ou mandíbula | Dizziness, nose, ears or jaw | Mareo, nariz, oído o mandíbula |
| `cabeca.rosto.tontura` | front | Tontura | Dizziness | Mareo |
| `cabeca.rosto.nariz` | front | Nariz entupido ou escorrendo | Blocked or runny nose | Nariz tapada o que gotea |
| `cabeca.rosto.ouvido` | front | Incômodo no ouvido | Ear discomfort | Molestia en el oído |
| `cabeca.rosto.mandibula` | front | Mandíbula ou dentes travados | Tight jaw or clenched teeth | Mandíbula o dientes apretados |
| `barriga.colica.menstrual` | front | Cólica menstrual | Period cramps | Cólico menstrual |
| `barriga.intestino` (branch) | front | Intestino | Bowels | Intestino |
| `barriga.intestino.preso` | front | Intestino preso | Constipated | Estreñimiento |
| `barriga.intestino.solto` | front | Intestino solto | Loose stools | Intestino suelto |

Side rules: front `cabeca` shows {`pressao`, `sentidos`, `rosto`}; back `cabeca` unchanged {`pressao`, `nuca`}. `barriga` (front) shows all its branches.

### 4. New triggers
`dinheiro` (💰 Dinheiro · Money · Dinero), `telas` (📱 Telas ou redes sociais · Screens or social media · Pantallas o redes sociales), `ciclo` (🩸 Ciclo menstrual · Menstrual cycle · Ciclo menstrual). Offered on every "não tão bem" entry (not physical-only). Display order: trabalho, familia, sono, dinheiro, telas, ciclo, alimentacao, esforco, queda, medicamento, clima, nao_sei, outro.

### 5. Closing questions (entry level, optional)
One screen after the triggers, only for `mood = "nao_tao_bem"` entries, with "Pular" always visible. Both fields optional; the backend rejects them on `bem`/`normal` entries.

- `coping` (single, nullable). Question: "Como foi lidar com isso?" · "How did dealing with it go?" · "¿Cómo fue lidiar con esto?". Keys: `consegui` (🛡️ Consegui lidar · I managed it · Pude manejarlo), `esperei` (⏳ Esperei passar · I waited for it to pass · Esperé a que pasara), `dificil` (🌊 Foi difícil · It was hard · Fue difícil).
- `helpers` (multi, default `[]`, max 6, unique). Question: "O que te ajudou hoje?" · "What helped you today?" · "¿Qué te ayudó hoy?". Keys: `mexer_corpo` (🚶 Mexer o corpo · Moving my body · Mover el cuerpo), `conversar` (🗣️ Conversar com alguém · Talking to someone · Hablar con alguien), `pausa` (😮‍💨 Uma pausa para respirar · A pause to breathe · Una pausa para respirar), `lazer` (🎵 Música ou lazer · Music or leisure · Música u ocio), `descansar` (😴 Descansar · Resting · Descansar), `nada_ainda` (🤷 Nada ainda · Nothing yet · Nada todavía). `nada_ainda` cannot be combined with other helpers (400).

Columns: `journal_entries.coping text null` (check IN the 3 keys), `journal_entries.helpers text[] not null default '{}'`. `JournalEntryDto` returns `coping` (null on older entries) and `helpers` (`[]` on older entries).

### 6. Daily habits (`/v1/habits`)
One row per profile per local day; every field optional and independent. Same active-profile header, RLS and author rules as `journal_entries` (read = `app_can_read_profile`, write = `app_can_write_profile`, insert pins `user_id` to the caller).

Table `daily_habits`: `id uuid pk`, `user_id uuid null fk users on delete set null` (author), `profile_id uuid not null fk profiles on delete cascade`, `day date not null`, `sleep_quality text null`, `sleep_hours text null`, `moved boolean null`, `movement_minutes text null`, `period boolean null`, `created_at`, `updated_at`; unique `(profile_id, day)`; index `(profile_id, day desc)`; checks: `sleep_quality IN ('bem','regular','mal')`, `sleep_hours IN ('menos_5','5_6','7_8','9_mais')`, `movement_minutes IN ('ate_15','15_30','30_60','mais_60')`, `movement_minutes IS NULL OR moved = true`.

| field | question (pt · en · es) | keys and labels |
|---|---|---|
| `sleepQuality` | Como você dormiu? · How did you sleep? · ¿Cómo dormiste? | `bem` 😴 Dormi bem · Slept well · Dormí bien; `regular` 😐 Mais ou menos · So-so · Más o menos; `mal` 😫 Dormi mal · Slept badly · Dormí mal |
| `sleepHours` | Quantas horas, mais ou menos? · About how many hours? · ¿Cuántas horas, más o menos? | `menos_5` Menos de 5 h; `5_6` 5 a 6 h; `7_8` 7 a 8 h; `9_mais` 9 h ou mais (en: Under 5 h, 5–6 h, 7–8 h, 9 h or more; es: Menos de 5 h, 5 a 6 h, 7 a 8 h, 9 h o más) |
| `moved` | Mexeu o corpo hoje? · Did you move your body today? · ¿Moviste el cuerpo hoy? | true Sim · Yes · Sí; false Não · No · No |
| `movementMinutes` | Por quanto tempo? · For how long? · ¿Cuánto tiempo? | `ate_15` Até 15 min; `15_30` 15 a 30 min; `30_60` 30 a 60 min; `mais_60` Mais de 1 h (en: Up to 15 min, 15–30 min, 30–60 min, Over 1 h; es: Hasta 15 min, 15 a 30 min, 30 a 60 min, Más de 1 h) |
| `period` | Menstruação hoje? · Period today? · ¿Menstruación hoy? | true Sim; false Não. Shown only when the person turned on "Acompanhar ciclo menstrual" (device setting per profile, default off) or already has a `period = true` day in the last 60 days. |

API:
- `GET /v1/habits?days=30` (1..365, default 30) → `{ days: HabitDayDto[] }`, newest first. `HabitDayDto = { day: "YYYY-MM-DD", sleepQuality, sleepHours, moved, movementMinutes, period, updatedAt }` (absent answers are `null`).
- `PUT /v1/habits/:day` (`day` = `YYYY-MM-DD`, local day of the person, from 365 days ago up to tomorrow in UTC) body `{ sleepQuality?, sleepHours?, moved?, movementMinutes?, period? }` → 200 `HabitDayDto`. Full replace: an omitted field is stored as null. `movementMinutes` without `moved = true` → 400. Unknown keys → 400.
- `DELETE /v1/habits/:day` → 204 (404 if nothing stored).
- Habits are part of the LGPD export and account deletion, like journal entries. Never used for ads or content.

Charts (Free, 30 days): sleep quality per day + hours, days with movement, period days marked on the calendar and on the line chart. Only counts, e.g. "Você dormiu mal em 6 dos últimos 30 dias". No relations, no goals computed by the app, no advice.

### 7. Summary additions (`GET /v1/journal/summary`)
Same distinct-local-day counting. New fields: `positive: { byTime: {passado,presente,futuro}, byOptionKey: {…} }` (positive items only; never mixed into `byTime`/`byOptionKey`), `byCoping: { consegui, esperei, dificil }`, `byHelper: { mexer_corpo, … }`. Positive items do not enter `cooccurrence`. New trigger keys appear in `byTrigger` like the others.

## Removed
- Mobile: `RedFlagEvaluator`, `SafetyNoticeKind`, inline safety notice banner, any conditional emergency UI, `SymptomClassification*`, `ApiEndpoints.tagEntry`.
- Backend: any self-harm / warning-sign detection used to change output, AI tagging endpoints (`/v1/ai/tag-entry`, `/v1/ai/classify-symptom`), `AiTaggingService`, `IdiomDictionaryService`, `symptom_knowledge` table.
