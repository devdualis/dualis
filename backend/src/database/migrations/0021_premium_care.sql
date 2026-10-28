-- backend/src/database/migrations/0021_premium_care.sql
-- Premium "Meus cuidados" (phases 12-14): vaccine doses, allergies, medications and their
-- intakes, appointments (care_records), and uploaded exam/prescription documents
-- (care_documents). Stores what the person entered or confirmed; nothing is interpreted.
-- care_records.data and care_documents.data hold AES-256-GCM ciphertext of a JSON object;
-- care_documents.file holds the encrypted file bytes (iv | tag | ciphertext).
-- RLS mirrors journal v2 (0017): read = owner or ACCEPTED grantee, write = owner or
-- CO_MANAGE grantee, inserts pin user_id (author) to the caller.
-- Idempotent: safe to re-run.

CREATE TABLE IF NOT EXISTS care_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,
  parent_id UUID REFERENCES care_records(id) ON DELETE CASCADE,
  occurs_at TIMESTAMPTZ,
  data TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS care_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,
  mime TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  file BYTEA NOT NULL,
  status TEXT NOT NULL,
  data TEXT,
  error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'care_records_kind_check') THEN
    ALTER TABLE care_records ADD CONSTRAINT care_records_kind_check
      CHECK (kind IN ('vaccine_dose', 'allergy', 'medication', 'medication_intake', 'appointment'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'care_documents_kind_check') THEN
    ALTER TABLE care_documents ADD CONSTRAINT care_documents_kind_check
      CHECK (kind IN ('lab', 'prescription', 'other'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'care_documents_status_check') THEN
    ALTER TABLE care_documents ADD CONSTRAINT care_documents_status_check
      CHECK (status IN ('archived', 'processing', 'review', 'ready', 'failed'));
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_care_records_profile_kind ON care_records(profile_id, kind, occurs_at DESC);
CREATE INDEX IF NOT EXISTS idx_care_records_parent ON care_records(parent_id);
CREATE INDEX IF NOT EXISTS idx_care_documents_profile_created ON care_documents(profile_id, created_at DESC);

ALTER TABLE care_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE care_records FORCE ROW LEVEL SECURITY;
ALTER TABLE care_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE care_documents FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS care_records_profile_select ON care_records;
CREATE POLICY care_records_profile_select ON care_records
  FOR SELECT USING (app_can_read_profile(profile_id));

DROP POLICY IF EXISTS care_records_profile_insert ON care_records;
CREATE POLICY care_records_profile_insert ON care_records
  FOR INSERT WITH CHECK (
    app_can_write_profile(profile_id)
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS care_records_profile_update ON care_records;
CREATE POLICY care_records_profile_update ON care_records
  FOR UPDATE USING (app_can_write_profile(profile_id)) WITH CHECK (app_can_write_profile(profile_id));

DROP POLICY IF EXISTS care_records_profile_delete ON care_records;
CREATE POLICY care_records_profile_delete ON care_records
  FOR DELETE USING (app_can_write_profile(profile_id));

DROP POLICY IF EXISTS care_documents_profile_select ON care_documents;
CREATE POLICY care_documents_profile_select ON care_documents
  FOR SELECT USING (app_can_read_profile(profile_id));

DROP POLICY IF EXISTS care_documents_profile_insert ON care_documents;
CREATE POLICY care_documents_profile_insert ON care_documents
  FOR INSERT WITH CHECK (
    app_can_write_profile(profile_id)
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS care_documents_profile_update ON care_documents;
CREATE POLICY care_documents_profile_update ON care_documents
  FOR UPDATE USING (app_can_write_profile(profile_id)) WITH CHECK (app_can_write_profile(profile_id));

DROP POLICY IF EXISTS care_documents_profile_delete ON care_documents;
CREATE POLICY care_documents_profile_delete ON care_documents
  FOR DELETE USING (app_can_write_profile(profile_id));
