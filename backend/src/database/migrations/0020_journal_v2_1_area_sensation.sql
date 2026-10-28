-- backend/src/database/migrations/0020_journal_v2_1_area_sensation.sql
-- Journal v2.1 (docs/bienestar/CONTRATO-JOURNAL-V2.md):
-- (a) journal_entries.area: the one axis an entry records ('emotional' | 'physical');
--     null on entries saved before v2.1;
-- (b) journal_items.sensation: 'dor' | 'incomodo' chosen by the person, physical items only;
--     null on older items.
-- Row-level security policies are unchanged. Idempotent: safe to re-run.

ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS area text;
ALTER TABLE journal_items ADD COLUMN IF NOT EXISTS sensation text;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_entries_area_check') THEN
    ALTER TABLE journal_entries ADD CONSTRAINT journal_entries_area_check
      CHECK (area IS NULL OR area IN ('emotional', 'physical'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_items_sensation_check') THEN
    ALTER TABLE journal_items ADD CONSTRAINT journal_items_sensation_check
      CHECK (sensation IS NULL OR (sensation IN ('dor', 'incomodo') AND kind = 'physical'));
  END IF;
END
$$;
