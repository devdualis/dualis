-- backend/src/database/migrations/0019_journal_v2_profile_client_id.sql
-- Journal v2 follow-up (docs/bienestar/CONTRATO-JOURNAL-V2.md):
-- (a) client_id (outbox idempotency) is unique per profile instead of across every
--     profile, so the same id sent from another profile is a new entry, not a conflict;
-- (b) the journal_items UPDATE policy re-checks that a condition item points to a
--     condition of the entry's own profile, like the INSERT policy.
-- Idempotent: safe to re-run.

-- 1. client_id unique per profile

ALTER TABLE journal_entries DROP CONSTRAINT IF EXISTS journal_entries_client_id_unique;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_entries_profile_client_id_unique') THEN
    ALTER TABLE journal_entries ADD CONSTRAINT journal_entries_profile_client_id_unique UNIQUE (profile_id, client_id);
  END IF;
END
$$;

-- 2. journal_items UPDATE keeps condition items on the same profile

DROP POLICY IF EXISTS journal_items_profile_update ON journal_items;
CREATE POLICY journal_items_profile_update ON journal_items
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_write_profile(e.profile_id))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_write_profile(e.profile_id))
    AND (
      condition_id IS NULL
      OR EXISTS (
        SELECT 1 FROM user_conditions c JOIN journal_entries e ON e.id = entry_id
        WHERE c.id = condition_id AND c.profile_id = e.profile_id
      )
    )
  );
