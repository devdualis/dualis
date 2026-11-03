-- backend/src/database/migrations/0028_guardianship_consent_gaps.sql
-- Phase 11.1: guardianship and consent sharing requirement gaps (PREM-06 / PREM-07).
--
-- Sharing section (decision D2): a shared_access_grants row now carries the data
-- categories the owner chose (habits, physical_journal, emotional_journal, conditions,
-- care). Every profile-scoped data policy checks the category of the row it protects,
-- so a grantee only sees what was shared, whatever code path reads the table.
-- Safety events (safety_resource_events) are never shared: only the owner reads them.
--
-- ============================================================================
-- FLAG FOR USER REVIEW (D2): this migration narrows access already granted.
-- Existing ACCEPTED and PENDING grants get habits, physical_journal, conditions and
-- care, but NOT emotional_journal. Applying it to production is a human decision.
-- Check first with:
--   SELECT status, count(*) FROM shared_access_grants GROUP BY 1;
-- ============================================================================
--
-- Safe to re-run (production history is partial, migrations are applied by hand):
-- IF NOT EXISTS, CREATE OR REPLACE, DROP POLICY IF EXISTS and guarded DO blocks only.
-- The backfill runs only in the run that creates the categories column, so a re-run
-- never overwrites categories the owner edited later.
--
-- Recursion note: the new helpers follow the 0013 rule. app_has_profile_grant_category
-- reads only shared_access_grants; no shared_access_grants SELECT/UPDATE policy reads
-- profiles, so profiles <-> shared_access_grants has no policy cycle even when the
-- helpers run under RLS with a non-BYPASSRLS owner.

-- A. Categories column and one-time backfill

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'shared_access_grants' AND column_name = 'categories'
  ) THEN
    ALTER TABLE shared_access_grants
      ADD COLUMN categories text[] NOT NULL DEFAULT ARRAY['habits']::text[];

    -- FORCE RLS would hide every row from a non-superuser table owner (no
    -- app.current_user_id here), so lift it for the backfill only (same pattern as 0015).
    ALTER TABLE shared_access_grants NO FORCE ROW LEVEL SECURITY;
    UPDATE shared_access_grants
      SET categories = ARRAY['habits', 'physical_journal', 'conditions', 'care']::text[]
      WHERE status IN ('ACCEPTED', 'PENDING');
    ALTER TABLE shared_access_grants FORCE ROW LEVEL SECURITY;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'shared_access_grants'::regclass AND conname = 'shared_access_grants_categories_check'
  ) THEN
    ALTER TABLE shared_access_grants ADD CONSTRAINT shared_access_grants_categories_check
      CHECK (categories <@ ARRAY['habits', 'physical_journal', 'emotional_journal', 'conditions', 'care']::text[]);
  END IF;
END
$$;

-- B. Category helpers. New names on purpose: overloading the 0013 helpers makes
-- calls like app_has_profile_grant(id) ambiguous.

-- True when the current user holds an ACCEPTED, non-revoked grant on the profile that
-- includes p_category. p_require_co_manage = true also requires CO_MANAGE access.
-- Reads only shared_access_grants (never profiles).
CREATE OR REPLACE FUNCTION app_has_profile_grant_category(p_profile_id uuid, p_category text, p_require_co_manage boolean)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM shared_access_grants g
    WHERE g.target_profile_id = p_profile_id
      AND g.grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
      AND g.status = 'ACCEPTED'
      AND g.revoked_at IS NULL
      AND p_category = ANY (g.categories)
      AND (NOT p_require_co_manage OR g.access_level = 'CO_MANAGE')
  );
$$;

-- Owner, or accepted grantee whose grant includes the category.
CREATE OR REPLACE FUNCTION app_can_read_profile_category(p_profile_id uuid, p_category text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT app_owns_profile(p_profile_id) OR app_has_profile_grant_category(p_profile_id, p_category, false);
$$;

-- Owner, or CO_MANAGE grantee whose grant includes the category.
CREATE OR REPLACE FUNCTION app_can_write_profile_category(p_profile_id uuid, p_category text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT app_owns_profile(p_profile_id) OR app_has_profile_grant_category(p_profile_id, p_category, true);
$$;

-- Category of a journal entry from its area. Entries saved before v2.1 (area NULL)
-- count as emotional_journal, so they are never shown without that opt-in category.
CREATE OR REPLACE FUNCTION app_journal_area_category(p_area text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT CASE WHEN p_area = 'physical' THEN 'physical_journal' ELSE 'emotional_journal' END;
$$;

COMMENT ON FUNCTION app_can_read_profile(uuid) IS
  'Owner or accepted grantee, all-or-nothing (0013). Since 0028 no data-table policy uses it: data policies call app_can_read_profile_category. Kept for profiles policies, ProfileContextGuard and the safety_resource_events insert policy.';
COMMENT ON FUNCTION app_can_write_profile(uuid) IS
  'Owner or CO_MANAGE grantee, all-or-nothing (0013). Since 0028 no data-table policy uses it: data policies call app_can_write_profile_category.';

-- C. Journal family and conditions policies (same names, same other clauses)

-- journal_entries: category follows the entry area; UPDATE WITH CHECK uses the new area.
DROP POLICY IF EXISTS journal_entries_profile_select ON journal_entries;
CREATE POLICY journal_entries_profile_select ON journal_entries
  FOR SELECT
  USING (app_can_read_profile_category(profile_id, app_journal_area_category(area)));

DROP POLICY IF EXISTS journal_entries_profile_insert ON journal_entries;
CREATE POLICY journal_entries_profile_insert ON journal_entries
  FOR INSERT
  WITH CHECK (
    app_can_write_profile_category(profile_id, app_journal_area_category(area))
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS journal_entries_profile_update ON journal_entries;
CREATE POLICY journal_entries_profile_update ON journal_entries
  FOR UPDATE
  USING (app_can_write_profile_category(profile_id, app_journal_area_category(area)))
  WITH CHECK (app_can_write_profile_category(profile_id, app_journal_area_category(area)));

DROP POLICY IF EXISTS journal_entries_profile_delete ON journal_entries;
CREATE POLICY journal_entries_profile_delete ON journal_entries
  FOR DELETE
  USING (app_can_write_profile_category(profile_id, app_journal_area_category(area)));

-- journal_items: access follows the parent entry's profile and area (journal_entries
-- policies never read journal_items, so no recursion). A condition item must point
-- to a condition of that same profile.
DROP POLICY IF EXISTS journal_items_profile_select ON journal_items;
CREATE POLICY journal_items_profile_select ON journal_items
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM journal_entries e
      WHERE e.id = entry_id AND app_can_read_profile_category(e.profile_id, app_journal_area_category(e.area))
    )
  );

DROP POLICY IF EXISTS journal_items_profile_insert ON journal_items;
CREATE POLICY journal_items_profile_insert ON journal_items
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM journal_entries e
      WHERE e.id = entry_id AND app_can_write_profile_category(e.profile_id, app_journal_area_category(e.area))
    )
    AND (
      condition_id IS NULL
      OR EXISTS (
        SELECT 1 FROM user_conditions c JOIN journal_entries e ON e.id = entry_id
        WHERE c.id = condition_id AND c.profile_id = e.profile_id
      )
    )
  );

DROP POLICY IF EXISTS journal_items_profile_update ON journal_items;
CREATE POLICY journal_items_profile_update ON journal_items
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM journal_entries e
      WHERE e.id = entry_id AND app_can_write_profile_category(e.profile_id, app_journal_area_category(e.area))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM journal_entries e
      WHERE e.id = entry_id AND app_can_write_profile_category(e.profile_id, app_journal_area_category(e.area))
    )
    AND (
      condition_id IS NULL
      OR EXISTS (
        SELECT 1 FROM user_conditions c JOIN journal_entries e ON e.id = entry_id
        WHERE c.id = condition_id AND c.profile_id = e.profile_id
      )
    )
  );

DROP POLICY IF EXISTS journal_items_profile_delete ON journal_items;
CREATE POLICY journal_items_profile_delete ON journal_items
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM journal_entries e
      WHERE e.id = entry_id AND app_can_write_profile_category(e.profile_id, app_journal_area_category(e.area))
    )
  );

-- user_conditions: 'conditions'
DROP POLICY IF EXISTS user_conditions_profile_select ON user_conditions;
CREATE POLICY user_conditions_profile_select ON user_conditions
  FOR SELECT
  USING (app_can_read_profile_category(profile_id, 'conditions'));

DROP POLICY IF EXISTS user_conditions_profile_insert ON user_conditions;
CREATE POLICY user_conditions_profile_insert ON user_conditions
  FOR INSERT
  WITH CHECK (
    app_can_write_profile_category(profile_id, 'conditions')
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS user_conditions_profile_update ON user_conditions;
CREATE POLICY user_conditions_profile_update ON user_conditions
  FOR UPDATE
  USING (app_can_write_profile_category(profile_id, 'conditions'))
  WITH CHECK (app_can_write_profile_category(profile_id, 'conditions'));

DROP POLICY IF EXISTS user_conditions_profile_delete ON user_conditions;
CREATE POLICY user_conditions_profile_delete ON user_conditions
  FOR DELETE
  USING (app_can_write_profile_category(profile_id, 'conditions'));

-- condition_readings: 'conditions'
DROP POLICY IF EXISTS condition_readings_profile_select ON condition_readings;
CREATE POLICY condition_readings_profile_select ON condition_readings
  FOR SELECT
  USING (app_can_read_profile_category(profile_id, 'conditions'));

DROP POLICY IF EXISTS condition_readings_profile_insert ON condition_readings;
CREATE POLICY condition_readings_profile_insert ON condition_readings
  FOR INSERT
  WITH CHECK (
    app_can_write_profile_category(profile_id, 'conditions')
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    AND EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = condition_readings.entry_id AND e.profile_id = condition_readings.profile_id)
    AND EXISTS (SELECT 1 FROM user_conditions c WHERE c.id = condition_readings.condition_id AND c.profile_id = condition_readings.profile_id)
  );

DROP POLICY IF EXISTS condition_readings_profile_update ON condition_readings;
CREATE POLICY condition_readings_profile_update ON condition_readings
  FOR UPDATE
  USING (app_can_write_profile_category(profile_id, 'conditions'))
  WITH CHECK (
    app_can_write_profile_category(profile_id, 'conditions')
    AND EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = condition_readings.entry_id AND e.profile_id = condition_readings.profile_id)
    AND EXISTS (SELECT 1 FROM user_conditions c WHERE c.id = condition_readings.condition_id AND c.profile_id = condition_readings.profile_id)
  );

DROP POLICY IF EXISTS condition_readings_profile_delete ON condition_readings;
CREATE POLICY condition_readings_profile_delete ON condition_readings
  FOR DELETE
  USING (app_can_write_profile_category(profile_id, 'conditions'));

-- symptom_logs: checked per row (A1). A row with emotional_dimension needs
-- emotional_journal; a row with anatomical_system, or with neither column, needs
-- physical_journal; a row with both needs both.
DROP POLICY IF EXISTS symptom_logs_profile_select ON symptom_logs;
CREATE POLICY symptom_logs_profile_select ON symptom_logs
  FOR SELECT
  USING (
    (emotional_dimension IS NULL OR app_can_read_profile_category(profile_id, 'emotional_journal'))
    AND ((anatomical_system IS NULL AND emotional_dimension IS NOT NULL) OR app_can_read_profile_category(profile_id, 'physical_journal'))
  );

DROP POLICY IF EXISTS symptom_logs_profile_insert ON symptom_logs;
CREATE POLICY symptom_logs_profile_insert ON symptom_logs
  FOR INSERT
  WITH CHECK (
    (emotional_dimension IS NULL OR app_can_write_profile_category(profile_id, 'emotional_journal'))
    AND ((anatomical_system IS NULL AND emotional_dimension IS NOT NULL) OR app_can_write_profile_category(profile_id, 'physical_journal'))
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS symptom_logs_profile_update ON symptom_logs;
CREATE POLICY symptom_logs_profile_update ON symptom_logs
  FOR UPDATE
  USING (
    (emotional_dimension IS NULL OR app_can_write_profile_category(profile_id, 'emotional_journal'))
    AND ((anatomical_system IS NULL AND emotional_dimension IS NOT NULL) OR app_can_write_profile_category(profile_id, 'physical_journal'))
  )
  WITH CHECK (
    (emotional_dimension IS NULL OR app_can_write_profile_category(profile_id, 'emotional_journal'))
    AND ((anatomical_system IS NULL AND emotional_dimension IS NOT NULL) OR app_can_write_profile_category(profile_id, 'physical_journal'))
  );

DROP POLICY IF EXISTS symptom_logs_profile_delete ON symptom_logs;
CREATE POLICY symptom_logs_profile_delete ON symptom_logs
  FOR DELETE
  USING (
    (emotional_dimension IS NULL OR app_can_write_profile_category(profile_id, 'emotional_journal'))
    AND ((anatomical_system IS NULL AND emotional_dimension IS NOT NULL) OR app_can_write_profile_category(profile_id, 'physical_journal'))
  );

-- D. Habits, care and owner-only safety policies

-- water_intake_logs: 'habits'
DROP POLICY IF EXISTS water_intake_logs_profile_select ON water_intake_logs;
CREATE POLICY water_intake_logs_profile_select ON water_intake_logs
  FOR SELECT
  USING (app_can_read_profile_category(profile_id, 'habits'));

DROP POLICY IF EXISTS water_intake_logs_profile_insert ON water_intake_logs;
CREATE POLICY water_intake_logs_profile_insert ON water_intake_logs
  FOR INSERT
  WITH CHECK (
    app_can_write_profile_category(profile_id, 'habits')
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS water_intake_logs_profile_update ON water_intake_logs;
CREATE POLICY water_intake_logs_profile_update ON water_intake_logs
  FOR UPDATE
  USING (app_can_write_profile_category(profile_id, 'habits'))
  WITH CHECK (app_can_write_profile_category(profile_id, 'habits'));

DROP POLICY IF EXISTS water_intake_logs_profile_delete ON water_intake_logs;
CREATE POLICY water_intake_logs_profile_delete ON water_intake_logs
  FOR DELETE
  USING (app_can_write_profile_category(profile_id, 'habits'));

-- daily_habits: 'habits'
DROP POLICY IF EXISTS daily_habits_profile_select ON daily_habits;
CREATE POLICY daily_habits_profile_select ON daily_habits
  FOR SELECT
  USING (app_can_read_profile_category(profile_id, 'habits'));

DROP POLICY IF EXISTS daily_habits_profile_insert ON daily_habits;
CREATE POLICY daily_habits_profile_insert ON daily_habits
  FOR INSERT
  WITH CHECK (
    app_can_write_profile_category(profile_id, 'habits')
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS daily_habits_profile_update ON daily_habits;
CREATE POLICY daily_habits_profile_update ON daily_habits
  FOR UPDATE
  USING (app_can_write_profile_category(profile_id, 'habits'))
  WITH CHECK (app_can_write_profile_category(profile_id, 'habits'));

DROP POLICY IF EXISTS daily_habits_profile_delete ON daily_habits;
CREATE POLICY daily_habits_profile_delete ON daily_habits
  FOR DELETE
  USING (app_can_write_profile_category(profile_id, 'habits'));

-- care_records: 'care'
DROP POLICY IF EXISTS care_records_profile_select ON care_records;
CREATE POLICY care_records_profile_select ON care_records
  FOR SELECT USING (app_can_read_profile_category(profile_id, 'care'));

DROP POLICY IF EXISTS care_records_profile_insert ON care_records;
CREATE POLICY care_records_profile_insert ON care_records
  FOR INSERT WITH CHECK (
    app_can_write_profile_category(profile_id, 'care')
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS care_records_profile_update ON care_records;
CREATE POLICY care_records_profile_update ON care_records
  FOR UPDATE
  USING (app_can_write_profile_category(profile_id, 'care'))
  WITH CHECK (app_can_write_profile_category(profile_id, 'care'));

DROP POLICY IF EXISTS care_records_profile_delete ON care_records;
CREATE POLICY care_records_profile_delete ON care_records
  FOR DELETE USING (app_can_write_profile_category(profile_id, 'care'));

-- care_documents: 'care'
DROP POLICY IF EXISTS care_documents_profile_select ON care_documents;
CREATE POLICY care_documents_profile_select ON care_documents
  FOR SELECT USING (app_can_read_profile_category(profile_id, 'care'));

DROP POLICY IF EXISTS care_documents_profile_insert ON care_documents;
CREATE POLICY care_documents_profile_insert ON care_documents
  FOR INSERT WITH CHECK (
    app_can_write_profile_category(profile_id, 'care')
    AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );

DROP POLICY IF EXISTS care_documents_profile_update ON care_documents;
CREATE POLICY care_documents_profile_update ON care_documents
  FOR UPDATE
  USING (app_can_write_profile_category(profile_id, 'care'))
  WITH CHECK (app_can_write_profile_category(profile_id, 'care'));

DROP POLICY IF EXISTS care_documents_profile_delete ON care_documents;
CREATE POLICY care_documents_profile_delete ON care_documents
  FOR DELETE USING (app_can_write_profile_category(profile_id, 'care'));

-- care_document_requests is keyed by user, not by profile (0023): unchanged.

-- safety_resource_events: SELECT/UPDATE/DELETE by the profile owner only. The INSERT
-- policy from 0015 stays as it is: read access is enough to insert, so a grantee's
-- category scope never blocks a help event.
DROP POLICY IF EXISTS safety_resource_events_profile_select ON safety_resource_events;
CREATE POLICY safety_resource_events_profile_select ON safety_resource_events
  FOR SELECT
  USING (app_owns_profile(profile_id));

DROP POLICY IF EXISTS safety_resource_events_profile_update ON safety_resource_events;
CREATE POLICY safety_resource_events_profile_update ON safety_resource_events
  FOR UPDATE
  USING (app_owns_profile(profile_id))
  WITH CHECK (app_owns_profile(profile_id));

DROP POLICY IF EXISTS safety_resource_events_profile_delete ON safety_resource_events;
CREATE POLICY safety_resource_events_profile_delete ON safety_resource_events
  FOR DELETE
  USING (app_owns_profile(profile_id));

-- triage_emergency_events: 0015 folds it into safety_resource_events and drops it.
-- Only a database where it still exists gets the same owner-only rules.
DO $$
BEGIN
  IF to_regclass('public.triage_emergency_events') IS NOT NULL THEN
    DROP POLICY IF EXISTS triage_emergency_events_profile_select ON triage_emergency_events;
    CREATE POLICY triage_emergency_events_profile_select ON triage_emergency_events
      FOR SELECT
      USING (app_owns_profile(profile_id));

    DROP POLICY IF EXISTS triage_emergency_events_profile_update ON triage_emergency_events;
    CREATE POLICY triage_emergency_events_profile_update ON triage_emergency_events
      FOR UPDATE
      USING (app_owns_profile(profile_id))
      WITH CHECK (app_owns_profile(profile_id));

    DROP POLICY IF EXISTS triage_emergency_events_profile_delete ON triage_emergency_events;
    CREATE POLICY triage_emergency_events_profile_delete ON triage_emergency_events
      FOR DELETE
      USING (app_owns_profile(profile_id));
  END IF;
END
$$;

-- E. Grant relationship, dependent share confirmation and the grant update guard

-- relationship: NULL means "não informado" (legacy grants, A7).
ALTER TABLE shared_access_grants ADD COLUMN IF NOT EXISTS relationship varchar(32);
-- When the owner confirmed sharing a dependent's data with this grantee (gap 9).
ALTER TABLE shared_access_grants ADD COLUMN IF NOT EXISTS dependent_share_confirmed_at timestamp with time zone;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'shared_access_grants'::regclass AND conname = 'shared_access_grants_relationship_check'
  ) THEN
    ALTER TABLE shared_access_grants ADD CONSTRAINT shared_access_grants_relationship_check
      CHECK (
        relationship IS NULL
        OR relationship IN ('spouse_partner', 'sibling', 'parent', 'child', 'other_family', 'caregiver', 'friend', 'other')
      );
  END IF;
END
$$;

-- Stored type of a profile ('primary', 'dependent_minor', 'dependent_adult').
-- Reads only profiles. Used only in the shared_access_grants INSERT policy, never in a
-- SELECT/UPDATE policy of that table (see the recursion note at the top).
CREATE OR REPLACE FUNCTION app_profile_type(p_profile_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.profile_type::text FROM profiles p WHERE p.id = p_profile_id;
$$;

-- shared_access_grants: only the granter can create, only for profiles they own, and
-- sharing a dependent's profile needs the owner's explicit confirmation.
-- The participant SELECT/UPDATE policies stay exactly as 0013 defines them.
DROP POLICY IF EXISTS shared_access_grants_granter_insert ON shared_access_grants;
CREATE POLICY shared_access_grants_granter_insert ON shared_access_grants
  FOR INSERT
  WITH CHECK (
    granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    AND app_owns_profile(target_profile_id)
    AND (app_profile_type(target_profile_id) = 'primary' OR dependent_share_confirmed_at IS NOT NULL)
  );

-- Grant update guard (0013) extended for the new columns: a grantee may still only
-- revoke; the granter edits categories, relationship and the dependent confirmation
-- only while the grant is PENDING or ACCEPTED; accepting an invite changes none of them.
CREATE OR REPLACE FUNCTION app_guard_shared_access_grant_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_user uuid := NULLIF(current_setting('app.current_user_id', true), '')::uuid;
  v_scope_changed boolean :=
    NEW.categories IS DISTINCT FROM OLD.categories
    OR NEW.relationship IS DISTINCT FROM OLD.relationship
    OR NEW.dependent_share_confirmed_at IS DISTINCT FROM OLD.dependent_share_confirmed_at;
BEGIN
  IF NEW.granter_user_id IS DISTINCT FROM OLD.granter_user_id
    OR NEW.target_profile_id IS DISTINCT FROM OLD.target_profile_id
    OR NEW.invite_code IS DISTINCT FROM OLD.invite_code
    OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'GRANT_IMMUTABLE_COLUMN' USING ERRCODE = 'P0001';
  END IF;

  IF OLD.status IN ('REVOKED', 'EXPIRED') AND NEW.status IS DISTINCT FROM OLD.status THEN
    RAISE EXCEPTION 'GRANT_TERMINAL_STATUS' USING ERRCODE = 'P0001';
  END IF;

  IF v_user IS NOT NULL AND v_user = OLD.grantee_user_id AND v_user <> OLD.granter_user_id THEN
    IF NEW.access_level IS DISTINCT FROM OLD.access_level
      OR NEW.grantee_user_id IS DISTINCT FROM OLD.grantee_user_id
      OR NEW.expires_at IS DISTINCT FROM OLD.expires_at
      OR NEW.accepted_at IS DISTINCT FROM OLD.accepted_at
      OR v_scope_changed
      OR NEW.status NOT IN (OLD.status, 'REVOKED') THEN
      RAISE EXCEPTION 'GRANTEE_MAY_ONLY_REVOKE' USING ERRCODE = 'P0001';
    END IF;
  ELSIF v_user IS NOT NULL AND v_user = OLD.granter_user_id THEN
    IF NEW.grantee_user_id IS DISTINCT FROM OLD.grantee_user_id
      OR NEW.accepted_at IS DISTINCT FROM OLD.accepted_at
      OR NEW.status NOT IN (OLD.status, 'REVOKED', 'EXPIRED') THEN
      RAISE EXCEPTION 'GRANTER_MAY_ONLY_REVOKE' USING ERRCODE = 'P0001';
    END IF;
    IF v_scope_changed AND OLD.status NOT IN ('PENDING', 'ACCEPTED') THEN
      RAISE EXCEPTION 'GRANT_SCOPE_LOCKED' USING ERRCODE = 'P0001';
    END IF;
  ELSIF v_user IS NOT NULL THEN
    -- Accept path: PENDING -> ACCEPTED by the caller, or PENDING -> EXPIRED.
    IF OLD.status <> 'PENDING'
      OR NEW.access_level IS DISTINCT FROM OLD.access_level
      OR NEW.expires_at IS DISTINCT FROM OLD.expires_at
      OR NEW.revoked_at IS DISTINCT FROM OLD.revoked_at
      OR v_scope_changed
      OR NOT (
        (NEW.status = 'ACCEPTED' AND NEW.grantee_user_id = v_user AND NEW.accepted_at IS NOT NULL)
        OR (NEW.status = 'EXPIRED' AND NEW.grantee_user_id IS NULL)
      ) THEN
      RAISE EXCEPTION 'GRANT_INVALID_ACCEPT' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_shared_access_grant_update ON shared_access_grants;
CREATE TRIGGER trg_guard_shared_access_grant_update
  BEFORE UPDATE ON shared_access_grants
  FOR EACH ROW EXECUTE FUNCTION app_guard_shared_access_grant_update();
