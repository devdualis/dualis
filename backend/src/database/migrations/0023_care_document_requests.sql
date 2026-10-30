-- backend/src/database/migrations/0023_care_document_requests.sql
-- Daily limit on exam and prescription documents (security sweep, quick task 261030-mkb).
-- One row per upload or re-read; CareService refuses more than CARE_DAILY_DOCUMENT_LIMIT
-- (default 30) per person in 24 hours, since each reading calls Cloud Vision and Gemini.
-- The app only inserts and counts its own rows, so deleting a document does not give its
-- request back. Idempotent: safe to re-run.

CREATE TABLE IF NOT EXISTS care_document_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_care_document_requests_user_created
  ON care_document_requests(user_id, created_at DESC);

ALTER TABLE care_document_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE care_document_requests FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS care_document_requests_own_select ON care_document_requests;
CREATE POLICY care_document_requests_own_select ON care_document_requests
  FOR SELECT USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

DROP POLICY IF EXISTS care_document_requests_own_insert ON care_document_requests;
CREATE POLICY care_document_requests_own_insert ON care_document_requests
  FOR INSERT WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);
