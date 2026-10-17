-- backend/src/database/migrations/0014_profile_scoped_clinical_data.sql
-- Phase 11 Wave 4: profile-scoped clinical data.
-- Clinical rows keep user_id (author, always the caller) and gain profile_id (subject,
-- whose health data it is). RLS moves from user-only isolation to profile access
-- through the 0013 helpers app_can_read_profile / app_can_write_profile.
-- Idempotent: safe to re-run.

-- 1. Columns (nullable until backfilled)

ALTER TABLE symptom_logs ADD COLUMN IF NOT EXISTS profile_id uuid;
ALTER TABLE triage_emergency_events ADD COLUMN IF NOT EXISTS profile_id uuid;
ALTER TABLE water_intake_logs ADD COLUMN IF NOT EXISTS profile_id uuid;

-- 2. One primary profile per account owner. Lets ProfileContextGuard create it lazily
-- with ON CONFLICT DO NOTHING. Skipped when legacy duplicates exist so the migration
-- never fails on existing data.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE tablename = 'profiles' AND indexname = 'uq_profiles_primary_per_owner'
  ) AND NOT EXISTS (
    SELECT 1 FROM profiles WHERE profile_type = 'primary'
    GROUP BY account_owner_id HAVING count(*) > 1
  ) THEN
    CREATE UNIQUE INDEX uq_profiles_primary_per_owner ON profiles(account_owner_id)
      WHERE profile_type = 'primary';
  END IF;
END
$$;

-- 3. Backfill: create missing primary profiles and assign existing rows to the author's
-- primary profile. Runs per user under that user's RLS context (still the old user-only
-- policies at this point), so it works for roles without BYPASSRLS too. Anonymous
-- emergency events (user_id NULL) keep profile_id NULL.
DO $$
DECLARE
  v_user users%ROWTYPE;
  v_profile_id uuid;
BEGIN
  PERFORM set_config('app.is_auth_service', 'true', true);

  FOR v_user IN SELECT * FROM users LOOP
    PERFORM set_config('app.current_user_id', v_user.id::text, true);

    IF NOT EXISTS (SELECT 1 FROM symptom_logs WHERE user_id = v_user.id AND profile_id IS NULL)
      AND NOT EXISTS (SELECT 1 FROM triage_emergency_events WHERE user_id = v_user.id AND profile_id IS NULL)
      AND NOT EXISTS (SELECT 1 FROM water_intake_logs WHERE user_id = v_user.id AND profile_id IS NULL) THEN
      CONTINUE;
    END IF;

    SELECT id INTO v_profile_id
    FROM profiles
    WHERE account_owner_id = v_user.id AND profile_type = 'primary'
    ORDER BY created_at
    LIMIT 1;

    IF v_profile_id IS NULL THEN
      INSERT INTO profiles (account_owner_id, profile_type, name, gender, date_of_birth)
      VALUES (v_user.id, 'primary', v_user.name, v_user.gender, v_user.date_of_birth)
      RETURNING id INTO v_profile_id;
    END IF;

    UPDATE symptom_logs SET profile_id = v_profile_id WHERE user_id = v_user.id AND profile_id IS NULL;
    UPDATE triage_emergency_events SET profile_id = v_profile_id WHERE user_id = v_user.id AND profile_id IS NULL;
    UPDATE water_intake_logs SET profile_id = v_profile_id WHERE user_id = v_user.id AND profile_id IS NULL;
  END LOOP;

  PERFORM set_config('app.current_user_id', '', true);
  PERFORM set_config('app.is_auth_service', '', true);
END
$$;

-- 4. Constraints and indexes

ALTER TABLE symptom_logs ALTER COLUMN profile_id SET NOT NULL;
ALTER TABLE water_intake_logs ALTER COLUMN profile_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'symptom_logs_profile_id_profiles_id_fk') THEN
    ALTER TABLE symptom_logs ADD CONSTRAINT symptom_logs_profile_id_profiles_id_fk
      FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'triage_emergency_events_profile_id_profiles_id_fk') THEN
    ALTER TABLE triage_emergency_events ADD CONSTRAINT triage_emergency_events_profile_id_profiles_id_fk
      FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'water_intake_logs_profile_id_profiles_id_fk') THEN
    ALTER TABLE water_intake_logs ADD CONSTRAINT water_intake_logs_profile_id_profiles_id_fk
      FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
  END IF;
  -- Emergency events stay nullable for anonymous reports only: an authenticated event
  -- always belongs to a profile.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'triage_emergency_events_profile_required') THEN
    ALTER TABLE triage_emergency_events ADD CONSTRAINT triage_emergency_events_profile_required
      CHECK (user_id IS NULL OR profile_id IS NOT NULL);
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_symptom_logs_profile_recorded ON symptom_logs(profile_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_triage_emergency_events_profile_reported ON triage_emergency_events(profile_id, reported_at DESC);
CREATE INDEX IF NOT EXISTS idx_water_intake_logs_profile_recorded ON water_intake_logs(profile_id, recorded_at DESC);

-- 5. Row-Level Security: replace user-only isolation with profile access.
-- Read: owner or ACCEPTED non-revoked grantee. Write: owner or CO_MANAGE grantee.
-- Inserts also pin user_id (author) to the caller.

ALTER TABLE symptom_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptom_logs FORCE ROW LEVEL SECURITY;
ALTER TABLE triage_emergency_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE triage_emergency_events FORCE ROW LEVEL SECURITY;
ALTER TABLE water_intake_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE water_intake_logs FORCE ROW LEVEL SECURITY;

-- symptom_logs
DROP POLICY IF EXISTS symptom_logs_patient_isolation ON symptom_logs;

DROP POLICY IF EXISTS symptom_logs_profile_select ON symptom_logs;
CREATE POLICY symptom_logs_profile_select ON symptom_logs
  FOR SELECT
  USING (app_can_read_profile(profile_id));

DROP POLICY IF EXISTS symptom_logs_profile_insert ON symptom_logs;
CREATE POLICY symptom_logs_profile_insert ON symptom_logs
  FOR INSERT
  WITH CHECK (
    app_can_write_profile(profile_id)
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS symptom_logs_profile_update ON symptom_logs;
CREATE POLICY symptom_logs_profile_update ON symptom_logs
  FOR UPDATE
  USING (app_can_write_profile(profile_id))
  WITH CHECK (app_can_write_profile(profile_id));

DROP POLICY IF EXISTS symptom_logs_profile_delete ON symptom_logs;
CREATE POLICY symptom_logs_profile_delete ON symptom_logs
  FOR DELETE
  USING (app_can_write_profile(profile_id));

-- triage_emergency_events: read access is enough to insert. An emergency must never be
-- blocked by a permission level. Anonymous events (user_id and profile_id NULL) remain
-- insertable and are visible to nobody through RLS.
DROP POLICY IF EXISTS triage_emergency_events_isolation ON triage_emergency_events;

DROP POLICY IF EXISTS triage_emergency_events_profile_select ON triage_emergency_events;
CREATE POLICY triage_emergency_events_profile_select ON triage_emergency_events
  FOR SELECT
  USING (app_can_read_profile(profile_id));

DROP POLICY IF EXISTS triage_emergency_events_profile_insert ON triage_emergency_events;
CREATE POLICY triage_emergency_events_profile_insert ON triage_emergency_events
  FOR INSERT
  WITH CHECK (
    (
      app_can_read_profile(profile_id)
      AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    )
    OR (user_id IS NULL AND profile_id IS NULL)
  );

DROP POLICY IF EXISTS triage_emergency_events_profile_update ON triage_emergency_events;
CREATE POLICY triage_emergency_events_profile_update ON triage_emergency_events
  FOR UPDATE
  USING (app_can_write_profile(profile_id))
  WITH CHECK (app_can_write_profile(profile_id));

DROP POLICY IF EXISTS triage_emergency_events_profile_delete ON triage_emergency_events;
CREATE POLICY triage_emergency_events_profile_delete ON triage_emergency_events
  FOR DELETE
  USING (app_can_write_profile(profile_id));

-- water_intake_logs
DROP POLICY IF EXISTS water_intake_logs_patient_isolation ON water_intake_logs;

DROP POLICY IF EXISTS water_intake_logs_profile_select ON water_intake_logs;
CREATE POLICY water_intake_logs_profile_select ON water_intake_logs
  FOR SELECT
  USING (app_can_read_profile(profile_id));

DROP POLICY IF EXISTS water_intake_logs_profile_insert ON water_intake_logs;
CREATE POLICY water_intake_logs_profile_insert ON water_intake_logs
  FOR INSERT
  WITH CHECK (
    app_can_write_profile(profile_id)
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS water_intake_logs_profile_update ON water_intake_logs;
CREATE POLICY water_intake_logs_profile_update ON water_intake_logs
  FOR UPDATE
  USING (app_can_write_profile(profile_id))
  WITH CHECK (app_can_write_profile(profile_id));

DROP POLICY IF EXISTS water_intake_logs_profile_delete ON water_intake_logs;
CREATE POLICY water_intake_logs_profile_delete ON water_intake_logs
  FOR DELETE
  USING (app_can_write_profile(profile_id));
