-- Journal v2.2: choices and daily habits, without interpreting answers. Safe to re-run.
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS coping text;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS helpers text[] NOT NULL DEFAULT '{}'::text[];

DO $$
BEGIN
  ALTER TABLE journal_items DROP CONSTRAINT IF EXISTS journal_items_kind_check;
  ALTER TABLE journal_items ADD CONSTRAINT journal_items_kind_check
    CHECK (kind IN ('emotional', 'physical', 'condition', 'positive'));
  ALTER TABLE journal_items DROP CONSTRAINT IF EXISTS journal_items_shape_check;
  ALTER TABLE journal_items ADD CONSTRAINT journal_items_shape_check CHECK (
    (kind = 'condition' AND condition_id IS NOT NULL AND option_key IS NULL AND custom_label IS NULL)
    OR (kind IN ('emotional', 'physical', 'positive') AND option_key IS NOT NULL AND condition_id IS NULL)
  );
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'journal_items'::regclass AND conname = 'journal_items_positive_check') THEN
    ALTER TABLE journal_items ADD CONSTRAINT journal_items_positive_check CHECK (
      kind <> 'positive' OR (intensity IS NULL AND persistence IS NULL AND body_side IS NULL AND sensation IS NULL)
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'journal_entries'::regclass AND conname = 'journal_entries_coping_check') THEN
    ALTER TABLE journal_entries ADD CONSTRAINT journal_entries_coping_check CHECK (coping IN ('consegui', 'esperei', 'dificil'));
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS daily_habits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  day date NOT NULL,
  sleep_quality text,
  sleep_hours text,
  moved boolean,
  movement_minutes text,
  period boolean,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT daily_habits_profile_day_unique UNIQUE (profile_id, day),
  CONSTRAINT daily_habits_sleep_quality_check CHECK (sleep_quality IN ('bem', 'regular', 'mal')),
  CONSTRAINT daily_habits_sleep_hours_check CHECK (sleep_hours IN ('menos_5', '5_6', '7_8', '9_mais')),
  CONSTRAINT daily_habits_movement_minutes_check CHECK (movement_minutes IN ('ate_15', '15_30', '30_60', 'mais_60')),
  CONSTRAINT daily_habits_movement_check CHECK (movement_minutes IS NULL OR moved IS TRUE)
);
CREATE INDEX IF NOT EXISTS idx_daily_habits_profile_day ON daily_habits(profile_id, day DESC);
ALTER TABLE daily_habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_habits FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS daily_habits_profile_select ON daily_habits;
CREATE POLICY daily_habits_profile_select ON daily_habits FOR SELECT USING (app_can_read_profile(profile_id));
DROP POLICY IF EXISTS daily_habits_profile_insert ON daily_habits;
CREATE POLICY daily_habits_profile_insert ON daily_habits FOR INSERT WITH CHECK (
  app_can_write_profile(profile_id) AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
);
DROP POLICY IF EXISTS daily_habits_profile_update ON daily_habits;
CREATE POLICY daily_habits_profile_update ON daily_habits FOR UPDATE
  USING (app_can_write_profile(profile_id)) WITH CHECK (app_can_write_profile(profile_id));
DROP POLICY IF EXISTS daily_habits_profile_delete ON daily_habits;
CREATE POLICY daily_habits_profile_delete ON daily_habits FOR DELETE USING (app_can_write_profile(profile_id));

-- Earlier migrations grant existing tables only; future tables do not inherit those grants.
-- Grant the deployed runtime role explicitly when provisioned, and the existing authenticated role.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dualis_app') THEN
    GRANT USAGE ON SCHEMA public TO dualis_app;
    GRANT SELECT, INSERT, UPDATE, DELETE ON daily_habits TO dualis_app;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    GRANT SELECT, INSERT, UPDATE, DELETE ON daily_habits TO authenticated;
  END IF;
END
$$;
