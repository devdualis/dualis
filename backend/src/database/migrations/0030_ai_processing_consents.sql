-- Phase 17: LGPD Art. 11, I consent for sending de-identified journal text to the AI provider.
-- Account-level data (not profile data): isolation is by user_id only. Hand-written; safe to re-run.
CREATE TABLE IF NOT EXISTS user_ai_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  purpose varchar(40) NOT NULL,
  consent_version varchar(20) NOT NULL,
  granted_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  ip_address_hash varchar(64) NOT NULL,
  user_agent varchar(255)
);
CREATE UNIQUE INDEX IF NOT EXISTS user_ai_consents_one_active
  ON user_ai_consents(user_id, purpose) WHERE revoked_at IS NULL;
CREATE INDEX IF NOT EXISTS user_ai_consents_user_idx ON user_ai_consents(user_id);

ALTER TABLE user_ai_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ai_consents FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_ai_consents_owner_isolation ON user_ai_consents;
CREATE POLICY user_ai_consents_owner_isolation ON user_ai_consents FOR ALL
  USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
  WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

COMMENT ON TABLE user_ai_consents IS
  'LGPD Art. 11, I consent for sending de-identified journal text to the AI provider; grants are append-only, revocation sets revoked_at';

-- New tables do not inherit earlier grants: grant the runtime role when provisioned.
-- No DELETE: rows leave only through the users ON DELETE CASCADE.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dualis_app') THEN
    GRANT USAGE ON SCHEMA public TO dualis_app;
    GRANT SELECT, INSERT, UPDATE ON user_ai_consents TO dualis_app;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    GRANT SELECT, INSERT, UPDATE ON user_ai_consents TO authenticated;
  END IF;
END
$$;
