-- backend/src/database/migrations/0024_keep_records_of_deleted_authors.sql
-- Records stay with their profile when the author deletes their account (security sweep,
-- quick task 261030-mkb). Deleting a co-manager's account used to cascade into everything
-- they had added to another person's profile. user_id (author) becomes nullable with
-- ON DELETE SET NULL; profile_id (subject) still cascades, so deleting a profile or its
-- owner's account still deletes its records. Inserts keep pinning user_id to the caller.
-- Idempotent: safe to re-run.

DO $$
DECLARE
  t text;
  c record;
BEGIN
  FOREACH t IN ARRAY ARRAY['care_records', 'care_documents', 'user_conditions', 'journal_entries', 'water_intake_logs']
  LOOP
    -- Drop every foreign key from <t>.user_id to users, whatever name it was created with.
    FOR c IN
      SELECT con.conname
      FROM pg_constraint con
      JOIN pg_attribute att ON att.attrelid = con.conrelid AND att.attnum = ANY (con.conkey)
      WHERE con.contype = 'f'
        AND con.conrelid = t::regclass
        AND con.confrelid = 'users'::regclass
        AND att.attname = 'user_id'
    LOOP
      EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', t, c.conname);
    END LOOP;

    EXECUTE format('ALTER TABLE %I ALTER COLUMN user_id DROP NOT NULL', t);
    EXECUTE format(
      'ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL',
      t,
      t || '_user_id_fkey'
    );
  END LOOP;
END
$$;
