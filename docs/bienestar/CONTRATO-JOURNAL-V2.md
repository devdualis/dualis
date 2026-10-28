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
`optionKey` = `<region>.<branch>.<option>`, plus `bodySide` = `front` | `back`:

| region | branch | options |
|---|---|---|
| `cabeca` | `pressao` | `temporas`, `latejando` |
| `cabeca` | `sentidos` | `garganta`, `olhos` |
| `peito` | `respiracao` | `curta`, `tosse` |
| `peito` | `incomodo` | `batedeira`, `costelas` |
| `barriga` | `queimacao` | `subindo`, `enjoo` |
| `barriga` | `colica` | `gases`, `pontadas` |
| `costas` | `rigidez` | `ombros`, `lombar` |
| `costas` | `fisgada` | `irradia`, `ao_mexer` |
| `membros` | `cansaco` | `juntas`, `pesados` |
| `membros` | `formigamento` | `dormentes`, `choque` |

Custom: `optionKey = "<region>.custom"` + `customLabel`.

### Condition (`kind = "condition"`)
`conditionId` (uuid of a `userConditions` row), no `optionKey`.

### Persistence
`hoje` | `dias_semanas` | `meses_anos` (nullable for conditions).

### Triggers (entry level, multi-select, optional)
`trabalho`, `familia`, `sono`, `alimentacao`, `esforco`, `queda`, `medicamento`, `clima`, `nao_sei`, `outro` (+ `triggerNote`, max 60 chars).
`alimentacao`, `esforco`, `queda`, `medicamento`, `clima` are only offered when the entry has a physical item.

### General mood (entry level)
`bem` | `normal` | `nao_tao_bem`.

## Data model (PostgreSQL, RLS by profile like `symptom_logs`)

`journal_entries`: `id uuid pk`, `profile_id`, `user_id`, `recorded_at timestamptz`, `mood text`, `triggers text[]`, `trigger_note text null`, `note text null` (encrypted like current free text), `transition_variant_ids text[]` (UX analytics only), `client_id text` (outbox idempotency, unique per `(profile_id, client_id)`), `created_at`.

`journal_items`: `id uuid pk`, `entry_id fk cascade`, `kind text`, `option_key text null`, `custom_label text null` (max 40, encrypted), `condition_id uuid null fk`, `body_side text null`, `persistence text null`, `intensity smallint 1..5 null` (null only when mood is bem/normal and there are no items, so in practice items always have intensity).

`user_conditions`: `id uuid pk`, `profile_id`, `user_id`, `label text` (max 40, encrypted), `created_at`, `archived_at null`.

Old `symptom_logs` rows stay as they are and are returned by history as `legacy: true` items.

## API (`/v1/journal`, JWT, active profile header as today)

- `POST /v1/journal/entries` → 201 `JournalEntryDto`. Body: `{ clientId, recordedAt, mood, triggers[], triggerNote?, note?, transitionVariantIds[], items: [{ kind, optionKey?, customLabel?, conditionId?, bodySide?, persistence?, intensity }] }`. Validation: keys from the tables above only; max 12 items.
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

`JournalEntryDto` = the stored entry with decrypted `note`, items with decrypted `customLabel`, and for condition items the condition `label`.

## AI tagging (removed)
AI tagging is removed from the product (strategy §18 decision 1, review #1 and #9). The `/v1/ai/tag-entry` and `/v1/ai/classify-symptom` endpoints, tagging service, idiom dictionary, symptom vector learning and their seeds/tests, and the shared `symptom_knowledge` table are deleted (migration `0018_remove_ai_tagging.sql`). The product never groups user text into pre-assigned categories.

## Removed
- Mobile: `RedFlagEvaluator`, `SafetyNoticeKind`, inline safety notice banner, any conditional emergency UI, `SymptomClassification*`, `ApiEndpoints.tagEntry`.
- Backend: any self-harm / warning-sign detection used to change output, AI tagging endpoints (`/v1/ai/tag-entry`, `/v1/ai/classify-symptom`), `AiTaggingService`, `IdiomDictionaryService`, `symptom_knowledge` table.
