-- backend/src/database/migrations/0017_journal_v2.sql
-- Journal v2 (docs/bienestar/CONTRATO-JOURNAL-V2.md): one entry per day check-in
-- (general mood, triggers, free note) with N items (the option the person chose or the
-- words they wrote, body side, persistence, self-reported intensity 1-5), plus the
-- conditions the person names themselves ("Minhas condições").
-- Stores choices as given. No grouping, no interpretation.
-- Free text columns (note, trigger_note, custom_label, label) hold AES-256-GCM ciphertext.
-- RLS mirrors symptom_logs (0014): read = owner or ACCEPTED grantee, write = owner or
-- CO_MANAGE grantee, inserts pin user_id (author) to the caller.
-- symptom_logs stays as is; the API returns its rows as legacy entries.
-- Idempotent: safe to re-run.

-- 1. Tables

CREATE TABLE IF NOT EXISTS user_conditions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  archived_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recorded_at TIMESTAMPTZ NOT NULL,
  mood TEXT NOT NULL,
  triggers TEXT[] DEFAULT '{}'::text[] NOT NULL,
  trigger_note TEXT,
  note TEXT,
  transition_variant_ids TEXT[] DEFAULT '{}'::text[] NOT NULL,
  client_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS journal_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,
  option_key TEXT,
  custom_label TEXT,
  condition_id UUID REFERENCES user_conditions(id) ON DELETE CASCADE,
  body_side TEXT,
  persistence TEXT,
  intensity SMALLINT
);

-- 2. Constraints

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_entries_client_id_unique') THEN
    ALTER TABLE journal_entries ADD CONSTRAINT journal_entries_client_id_unique UNIQUE (client_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_entries_mood_check') THEN
    ALTER TABLE journal_entries ADD CONSTRAINT journal_entries_mood_check
      CHECK (mood IN ('bem', 'normal', 'nao_tao_bem'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_items_kind_check') THEN
    ALTER TABLE journal_items ADD CONSTRAINT journal_items_kind_check
      CHECK (kind IN ('emotional', 'physical', 'condition'));
  END IF;
  -- A condition item points to a condition and carries no option or custom text;
  -- emotional and physical items carry an option key and no condition.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_items_shape_check') THEN
    ALTER TABLE journal_items ADD CONSTRAINT journal_items_shape_check
      CHECK (
        (kind = 'condition' AND condition_id IS NOT NULL AND option_key IS NULL AND custom_label IS NULL)
        OR (kind IN ('emotional', 'physical') AND option_key IS NOT NULL AND condition_id IS NULL)
      );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_items_body_side_check') THEN
    ALTER TABLE journal_items ADD CONSTRAINT journal_items_body_side_check
      CHECK (body_side IS NULL OR body_side IN ('front', 'back'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_items_persistence_check') THEN
    ALTER TABLE journal_items ADD CONSTRAINT journal_items_persistence_check
      CHECK (persistence IS NULL OR persistence IN ('hoje', 'dias_semanas', 'meses_anos'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_items_intensity_check') THEN
    ALTER TABLE journal_items ADD CONSTRAINT journal_items_intensity_check
      CHECK (intensity IS NULL OR intensity BETWEEN 1 AND 5);
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_user_conditions_profile_created ON user_conditions(profile_id, created_at);
CREATE INDEX IF NOT EXISTS idx_journal_entries_profile_recorded ON journal_entries(profile_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_journal_items_entry ON journal_items(entry_id);
CREATE INDEX IF NOT EXISTS idx_journal_items_condition ON journal_items(condition_id);

-- 3. Row-Level Security

ALTER TABLE user_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_conditions FORCE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries FORCE ROW LEVEL SECURITY;
ALTER TABLE journal_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_items FORCE ROW LEVEL SECURITY;

-- user_conditions
DROP POLICY IF EXISTS user_conditions_profile_select ON user_conditions;
CREATE POLICY user_conditions_profile_select ON user_conditions
  FOR SELECT
  USING (app_can_read_profile(profile_id));

DROP POLICY IF EXISTS user_conditions_profile_insert ON user_conditions;
CREATE POLICY user_conditions_profile_insert ON user_conditions
  FOR INSERT
  WITH CHECK (
    app_can_write_profile(profile_id)
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS user_conditions_profile_update ON user_conditions;
CREATE POLICY user_conditions_profile_update ON user_conditions
  FOR UPDATE
  USING (app_can_write_profile(profile_id))
  WITH CHECK (app_can_write_profile(profile_id));

DROP POLICY IF EXISTS user_conditions_profile_delete ON user_conditions;
CREATE POLICY user_conditions_profile_delete ON user_conditions
  FOR DELETE
  USING (app_can_write_profile(profile_id));

-- journal_entries
DROP POLICY IF EXISTS journal_entries_profile_select ON journal_entries;
CREATE POLICY journal_entries_profile_select ON journal_entries
  FOR SELECT
  USING (app_can_read_profile(profile_id));

DROP POLICY IF EXISTS journal_entries_profile_insert ON journal_entries;
CREATE POLICY journal_entries_profile_insert ON journal_entries
  FOR INSERT
  WITH CHECK (
    app_can_write_profile(profile_id)
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS journal_entries_profile_update ON journal_entries;
CREATE POLICY journal_entries_profile_update ON journal_entries
  FOR UPDATE
  USING (app_can_write_profile(profile_id))
  WITH CHECK (app_can_write_profile(profile_id));

DROP POLICY IF EXISTS journal_entries_profile_delete ON journal_entries;
CREATE POLICY journal_entries_profile_delete ON journal_entries
  FOR DELETE
  USING (app_can_write_profile(profile_id));

-- journal_items: access follows the parent entry's profile. A condition item must point
-- to a condition of that same profile.
DROP POLICY IF EXISTS journal_items_profile_select ON journal_items;
CREATE POLICY journal_items_profile_select ON journal_items
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_read_profile(e.profile_id))
  );

DROP POLICY IF EXISTS journal_items_profile_insert ON journal_items;
CREATE POLICY journal_items_profile_insert ON journal_items
  FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_write_profile(e.profile_id))
    AND (
      condition_id IS NULL
      OR EXISTS (
        SELECT 1 FROM user_conditions c JOIN journal_entries e ON e.id = entry_id
        WHERE c.id = condition_id AND c.profile_id = e.profile_id
      )
    )
  );

DROP POLICY IF EXISTS journal_items_profile_update ON journal_items;
CREATE POLICY journal_items_profile_update ON journal_items
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_write_profile(e.profile_id))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_write_profile(e.profile_id))
  );

DROP POLICY IF EXISTS journal_items_profile_delete ON journal_items;
CREATE POLICY journal_items_profile_delete ON journal_items
  FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_write_profile(e.profile_id))
  );
