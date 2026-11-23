-- Verified subscription state is backend-only. No journal/health data is stored.
CREATE TABLE IF NOT EXISTS subscriptions (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  entitlement_id text NOT NULL,
  is_premium boolean NOT NULL DEFAULT false,
  expires_at timestamptz,
  management_url text,
  environment text CHECK (environment IN ('sandbox', 'production')),
  verified_at timestamptz NOT NULL
);
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS subscriptions_backend_owner ON subscriptions;
CREATE POLICY subscriptions_backend_owner ON subscriptions FOR ALL TO PUBLIC
  USING (current_user NOT IN ('anon', 'authenticated') AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
  WITH CHECK (current_user NOT IN ('anon', 'authenticated') AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);
REVOKE ALL ON subscriptions FROM PUBLIC;
DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('REVOKE ALL ON subscriptions FROM %I', r);
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dualis_app') THEN
    GRANT SELECT, INSERT, UPDATE, DELETE ON subscriptions TO dualis_app;
  END IF;
END $$;
