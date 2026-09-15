ALTER TABLE users ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMP WITH TIME ZONE;

CREATE TABLE IF NOT EXISTS email_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  code_hash VARCHAR(255) NOT NULL,
  attempts INTEGER DEFAULT 0 NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

ALTER TABLE email_verifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'email_verifications' AND policyname = 'email_verifications_isolation'
  ) THEN
    CREATE POLICY email_verifications_isolation ON email_verifications
      FOR ALL
      USING (
        user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.is_auth_service', true) = 'true'
      )
      WITH CHECK (
        user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.is_auth_service', true) = 'true'
      );
  END IF;
END $$;
