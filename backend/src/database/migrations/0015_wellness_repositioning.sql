-- backend/src/database/migrations/0015_wellness_repositioning.sql
-- Wellness repositioning (plan F3/F6): the product no longer assesses symptoms.
-- (a) triage_emergency_events becomes safety_resource_events with minimal columns:
--     who opened the help resources (or started a call), on which profile, and when.
--     Severity and clinical category are dropped (LGPD Art. 6 III, data minimisation).
-- (b) symptom_knowledge loses its clinical columns (urgency, clinical concept,
--     emergency candidate flag).
-- (c) symptom_logs.disposition and organic_primacy_applied are kept read-only for the
--     LGPD export of historical rows and are marked legacy.
-- Idempotent: safe to re-run.

-- 1. safety_resource_events

CREATE TABLE IF NOT EXISTS safety_resource_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  -- Subject profile. NULL only for anonymous events, where user_id is NULL too.
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  channel TEXT,
  client_timestamp TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'safety_resource_events_action_check') THEN
    ALTER TABLE safety_resource_events ADD CONSTRAINT safety_resource_events_action_check
      CHECK (action IN ('opened_resources', 'call_started'));
  END IF;
  -- An authenticated event always belongs to a profile; anonymous events have neither.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'safety_resource_events_profile_required') THEN
    ALTER TABLE safety_resource_events ADD CONSTRAINT safety_resource_events_profile_required
      CHECK (user_id IS NULL OR profile_id IS NOT NULL);
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_safety_resource_events_user_id ON safety_resource_events(user_id);
CREATE INDEX IF NOT EXISTS idx_safety_resource_events_profile_created
  ON safety_resource_events(profile_id, created_at DESC);

-- 2. Move legacy emergency events. Runs as the table owner with FORCE lifted, so the
-- copy also sees anonymous rows (visible to nobody through RLS) on roles without
-- BYPASSRLS. Only the minimal fields survive: severity and category are discarded.
DO $$
BEGIN
  IF to_regclass('public.triage_emergency_events') IS NOT NULL THEN
    ALTER TABLE triage_emergency_events NO FORCE ROW LEVEL SECURITY;
    ALTER TABLE safety_resource_events NO FORCE ROW LEVEL SECURITY;

    INSERT INTO safety_resource_events (id, user_id, profile_id, action, channel, client_timestamp, created_at)
    SELECT id, user_id, profile_id, 'opened_resources', action_taken, reported_at, created_at
    FROM triage_emergency_events
    ON CONFLICT (id) DO NOTHING;

    DROP TABLE triage_emergency_events;
  END IF;
END
$$;

-- 3. Row-Level Security: same rules the emergency audit had. Read access is enough to
-- insert, so a permission level never blocks it. Anonymous events (user_id and
-- profile_id NULL) remain insertable and are visible to nobody through RLS.

ALTER TABLE safety_resource_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_resource_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS safety_resource_events_profile_select ON safety_resource_events;
CREATE POLICY safety_resource_events_profile_select ON safety_resource_events
  FOR SELECT
  USING (app_can_read_profile(profile_id));

DROP POLICY IF EXISTS safety_resource_events_profile_insert ON safety_resource_events;
CREATE POLICY safety_resource_events_profile_insert ON safety_resource_events
  FOR INSERT
  WITH CHECK (
    (
      app_can_read_profile(profile_id)
      AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    )
    OR (user_id IS NULL AND profile_id IS NULL)
  );

DROP POLICY IF EXISTS safety_resource_events_profile_update ON safety_resource_events;
CREATE POLICY safety_resource_events_profile_update ON safety_resource_events
  FOR UPDATE
  USING (app_can_write_profile(profile_id))
  WITH CHECK (app_can_write_profile(profile_id));

DROP POLICY IF EXISTS safety_resource_events_profile_delete ON safety_resource_events;
CREATE POLICY safety_resource_events_profile_delete ON safety_resource_events
  FOR DELETE
  USING (app_can_write_profile(profile_id));

-- 4. symptom_knowledge: the AI only tags entries now (area of the body or mood, lay term).

ALTER TABLE symptom_knowledge DROP COLUMN IF EXISTS urgency_score;
ALTER TABLE symptom_knowledge DROP COLUMN IF EXISTS clinical_concept;
ALTER TABLE symptom_knowledge DROP COLUMN IF EXISTS is_emergency_candidate;

-- Rows cached from Gemini before this change hold raw user text (data minimisation).
-- Curated seed rows stay.
DELETE FROM symptom_knowledge WHERE source = 'gemini';

-- 5. symptom_logs legacy columns: no longer written, kept only for the LGPD export of
-- historical rows until the retention policy is defined.

COMMENT ON COLUMN symptom_logs.disposition IS
  'LEGACY (0015): no longer written. Kept read-only for the LGPD data export of historical rows; drop once the retention policy is defined.';
COMMENT ON COLUMN symptom_logs.organic_primacy_applied IS
  'LEGACY (0015): no longer written. Kept read-only for the LGPD data export of historical rows; drop once the retention policy is defined.';
