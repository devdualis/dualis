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

## Removed
- Mobile: `RedFlagEvaluator`, `SafetyNoticeKind`, inline safety notice banner, any conditional emergency UI, `SymptomClassification*`, `ApiEndpoints.tagEntry`.
- Backend: any self-harm / warning-sign detection used to change output, AI tagging endpoints (`/v1/ai/tag-entry`, `/v1/ai/classify-symptom`), `AiTaggingService`, `IdiomDictionaryService`, `symptom_knowledge` table.
