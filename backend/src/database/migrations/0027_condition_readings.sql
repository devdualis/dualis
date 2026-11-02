-- Journal v2.4: readings the person notes on a condition (blood pressure, glucose, weight).
-- Values are stored as typed (encrypted), never compared or labelled. Safe to re-run.
ALTER TABLE user_conditions ADD COLUMN IF NOT EXISTS tracking text[] NOT NULL DEFAULT '{}'::text[];

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'user_conditions'::regclass AND conname = 'user_conditions_tracking_check') THEN
    ALTER TABLE user_conditions ADD CONSTRAINT user_conditions_tracking_check
      CHECK (tracking <@ ARRAY['blood_pressure', 'glucose', 'weight']::text[]);
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS condition_readings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  entry_id uuid NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
  condition_id uuid NOT NULL REFERENCES user_conditions(id) ON DELETE CASCADE,
  kind text NOT NULL,
  measured_at timestamptz NOT NULL,
  data text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT condition_readings_kind_check CHECK (kind IN ('blood_pressure', 'glucose', 'weight'))
);
CREATE INDEX IF NOT EXISTS idx_condition_readings_condition_measured
  ON condition_readings(profile_id, condition_id, measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_condition_readings_entry ON condition_readings(entry_id);
ALTER TABLE condition_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE condition_readings FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS condition_readings_profile_select ON condition_readings;
CREATE POLICY condition_readings_profile_select ON condition_readings FOR SELECT USING (app_can_read_profile(profile_id));
DROP POLICY IF EXISTS condition_readings_profile_insert ON condition_readings;
CREATE POLICY condition_readings_profile_insert ON condition_readings FOR INSERT WITH CHECK (
  app_can_write_profile(profile_id) AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  AND EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = condition_readings.entry_id AND e.profile_id = condition_readings.profile_id)
  AND EXISTS (SELECT 1 FROM user_conditions c WHERE c.id = condition_readings.condition_id AND c.profile_id = condition_readings.profile_id)
);
DROP POLICY IF EXISTS condition_readings_profile_update ON condition_readings;
CREATE POLICY condition_readings_profile_update ON condition_readings FOR UPDATE
  USING (app_can_write_profile(profile_id))
  WITH CHECK (
    app_can_write_profile(profile_id)
    AND EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = condition_readings.entry_id AND e.profile_id = condition_readings.profile_id)
    AND EXISTS (SELECT 1 FROM user_conditions c WHERE c.id = condition_readings.condition_id AND c.profile_id = condition_readings.profile_id)
  );
DROP POLICY IF EXISTS condition_readings_profile_delete ON condition_readings;
CREATE POLICY condition_readings_profile_delete ON condition_readings FOR DELETE USING (app_can_write_profile(profile_id));

-- New tables do not inherit earlier grants: grant the runtime role when provisioned.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dualis_app') THEN
    GRANT USAGE ON SCHEMA public TO dualis_app;
    GRANT SELECT, INSERT, UPDATE, DELETE ON condition_readings TO dualis_app;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    GRANT SELECT, INSERT, UPDATE, DELETE ON condition_readings TO authenticated;
  END IF;
END
$$;
