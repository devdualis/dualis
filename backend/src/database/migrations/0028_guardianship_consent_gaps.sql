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
