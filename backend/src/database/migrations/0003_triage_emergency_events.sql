-- backend/src/database/migrations/0003_triage_emergency_events.sql
-- Create triage_emergency_events table with RLS policy for LGPD auditability

CREATE TABLE IF NOT EXISTS triage_emergency_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  trigger_category TEXT NOT NULL,
  severity_level INTEGER NOT NULL,
  source_vertical TEXT NOT NULL,
  action_taken TEXT,
  reported_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_triage_emergency_events_user_id ON triage_emergency_events(user_id);
CREATE INDEX IF NOT EXISTS idx_triage_emergency_events_reported_at ON triage_emergency_events(reported_at);

ALTER TABLE triage_emergency_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE triage_emergency_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS triage_emergency_events_isolation ON triage_emergency_events;

CREATE POLICY triage_emergency_events_isolation ON triage_emergency_events
  FOR ALL
  USING (
    user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  )
  WITH CHECK (
    user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR user_id IS NULL
  );
