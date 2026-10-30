-- Repeated exam documents (quick task 261030-ktb).
-- file_hmac is a keyed HMAC-SHA256 of the plain file, computed by the server with a key
-- derived from ENCRYPTION_MASTER_KEY. The same file uploaded again to the same profile
-- returns the stored document instead of being read again. Existing rows stay NULL
-- until scripts/backfill-care-file-hmac.ts runs; NULLs never collide in a unique index.
ALTER TABLE care_documents ADD COLUMN IF NOT EXISTS file_hmac text;
--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS uq_care_documents_profile_file_hmac ON care_documents(profile_id, file_hmac);
