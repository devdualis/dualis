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

-- ============================================================================
-- Guardianship section (decision D3, PREM-06): at 18 a dependent profile is handed
-- over to the young adult's own account through a claim code. Ownership moves, the
-- guardianship row is closed (never deleted, for audit), every grant on the profile
-- is revoked, and the former guardian keeps no access.
--
-- Recursion note: app_claimable_profile reads only legal_guardianships, and the new
-- legal_guardianships policies read only the row, settings and pg_proc. So the claim
-- policies on profiles and shared_access_grants add no policy cycle, even when the
-- helpers run under RLS with a NOSUPERUSER NOBYPASSRLS owner.
--
-- Bypass note: a session can set app.claiming_code itself with set_config. Every claim
-- policy and trigger branch therefore also requires app_in_claim_function(): the
-- statement must run as the owner of claim_dependent_profile, which only happens inside
-- that SECURITY DEFINER function. A direct UPDATE with a valid code changes nothing.
-- ============================================================================

-- F. Hand-over at 18: claim columns, capability policies and claim_dependent_profile

ALTER TABLE legal_guardianships ADD COLUMN IF NOT EXISTS handover_code varchar(12);
ALTER TABLE legal_guardianships ADD COLUMN IF NOT EXISTS handover_code_expires_at timestamp with time zone;
ALTER TABLE legal_guardianships ADD COLUMN IF NOT EXISTS handover_notified_at timestamp with time zone;
ALTER TABLE legal_guardianships ADD COLUMN IF NOT EXISTS closed_at timestamp with time zone;
ALTER TABLE legal_guardianships ADD COLUMN IF NOT EXISTS closed_reason varchar(32);
ALTER TABLE legal_guardianships ADD COLUMN IF NOT EXISTS handed_over_to_user_id uuid REFERENCES users(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_legal_guardianships_handover_code
  ON legal_guardianships(handover_code) WHERE handover_code IS NOT NULL;

-- True when app.claiming_code matches a stored, unexpired code of an open guardianship
-- on the profile. Reads only legal_guardianships (never profiles or shared_access_grants).
CREATE OR REPLACE FUNCTION app_claimable_profile(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM legal_guardianships lg
    WHERE lg.dependent_profile_id = p_profile_id
      AND lg.handover_code = NULLIF(current_setting('app.claiming_code', true), '')
      AND lg.closed_at IS NULL
      AND lg.handover_code_expires_at > now()
  );
$$;

-- True only inside claim_dependent_profile: the claim setting is present and the
-- statement runs as the owner of that SECURITY DEFINER function. NOT security definer
-- on purpose (it must see the caller's current_user). Reads only pg_proc.
CREATE OR REPLACE FUNCTION app_in_claim_function()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT NULLIF(current_setting('app.claiming_code', true), '') IS NOT NULL
    AND COALESCE((
      SELECT pg_get_userbyid(p.proowner) = current_user
      FROM pg_proc p
      WHERE p.oid = to_regprocedure('public.claim_dependent_profile(text)')
    ), false);
$$;

-- legal_guardianships: legal_guardianships_guardian_isolation (0013) stays as it is.
-- The claim path may read the row carrying the code and close it for the caller. The
-- closed row keeps handover_code so it still passes the SELECT re-check of the UPDATE.
DROP POLICY IF EXISTS legal_guardianships_claim_select ON legal_guardianships;
CREATE POLICY legal_guardianships_claim_select ON legal_guardianships
  FOR SELECT
  USING (
    handover_code = NULLIF(current_setting('app.claiming_code', true), '')
    AND app_in_claim_function()
  );

DROP POLICY IF EXISTS legal_guardianships_claim_update ON legal_guardianships;
CREATE POLICY legal_guardianships_claim_update ON legal_guardianships
  FOR UPDATE
  USING (
    handover_code = NULLIF(current_setting('app.claiming_code', true), '')
    AND app_in_claim_function()
  )
  WITH CHECK (
    closed_at IS NOT NULL
    AND handed_over_to_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    AND handover_code = NULLIF(current_setting('app.claiming_code', true), '')
  );

-- A closed guardianship is the audit record of the hand-over: nobody deletes it through
-- RLS (the former guardian still matches the 0013 FOR ALL policy). Deleting the profile
-- itself still cascades.
DROP POLICY IF EXISTS legal_guardianships_closed_keep ON legal_guardianships;
CREATE POLICY legal_guardianships_closed_keep ON legal_guardianships
  AS RESTRICTIVE
  FOR DELETE
  USING (closed_at IS NULL);

-- shared_access_grants: 0013 clauses plus the claim path, which revokes every grant on
-- the claimed profile.
DROP POLICY IF EXISTS shared_access_grants_participant_select ON shared_access_grants;
CREATE POLICY shared_access_grants_participant_select ON shared_access_grants
  FOR SELECT
  USING (
    granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR invite_code = NULLIF(current_setting('app.accepting_invite_code', true), '')
    OR (app_claimable_profile(target_profile_id) AND app_in_claim_function())
  );

DROP POLICY IF EXISTS shared_access_grants_participant_update ON shared_access_grants;
CREATE POLICY shared_access_grants_participant_update ON shared_access_grants
  FOR UPDATE
  USING (
    granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR (status = 'PENDING' AND invite_code = NULLIF(current_setting('app.accepting_invite_code', true), ''))
    OR (app_claimable_profile(target_profile_id) AND app_in_claim_function())
  )
  WITH CHECK (
    granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR (status = 'EXPIRED' AND grantee_user_id IS NULL AND invite_code = NULLIF(current_setting('app.accepting_invite_code', true), ''))
    OR (status = 'REVOKED' AND app_claimable_profile(target_profile_id) AND app_in_claim_function())
  );

-- Grant update guard (section E) plus the claim branch: inside the claim, a caller who is
-- neither granter nor grantee may only revoke.
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
  ELSIF v_user IS NOT NULL AND app_in_claim_function() AND app_claimable_profile(OLD.target_profile_id) THEN
    -- Claim path: status -> REVOKED with revoked_at, nothing else.
    IF NEW.status <> 'REVOKED'
      OR NEW.revoked_at IS NULL
      OR NEW.access_level IS DISTINCT FROM OLD.access_level
      OR NEW.grantee_user_id IS DISTINCT FROM OLD.grantee_user_id
      OR NEW.expires_at IS DISTINCT FROM OLD.expires_at
      OR NEW.accepted_at IS DISTINCT FROM OLD.accepted_at
      OR v_scope_changed THEN
      RAISE EXCEPTION 'GRANT_INVALID_ACCEPT' USING ERRCODE = 'P0001';
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

-- profiles: the claim path may read and take over the claimable profile.
DROP POLICY IF EXISTS profiles_claim_select ON profiles;
CREATE POLICY profiles_claim_select ON profiles
  FOR SELECT
  USING (app_claimable_profile(id) AND app_in_claim_function());

DROP POLICY IF EXISTS profiles_claim_update ON profiles;
CREATE POLICY profiles_claim_update ON profiles
  FOR UPDATE
  USING (app_claimable_profile(id) AND app_in_claim_function())
  WITH CHECK (account_owner_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

-- profiles: ownership stays immutable (0013), except inside the claim.
DROP POLICY IF EXISTS profiles_owner_immutable ON profiles;
CREATE POLICY profiles_owner_immutable ON profiles
  AS RESTRICTIVE
  FOR UPDATE
  USING (true)
  WITH CHECK (
    account_owner_id = app_profile_owner_id(id)
    OR (app_claimable_profile(id) AND app_in_claim_function())
  );

-- profiles: the same rule as a trigger, so it also holds for roles that bypass RLS
-- (for example a BYPASSRLS service role). Raises 42501 like an RLS rejection.
CREATE OR REPLACE FUNCTION app_guard_profile_owner_change()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NOT app_in_claim_function() OR NOT app_claimable_profile(OLD.id) THEN
    RAISE EXCEPTION 'PROFILE_OWNER_IMMUTABLE' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_profile_owner_change ON profiles;
CREATE TRIGGER trg_guard_profile_owner_change
  BEFORE UPDATE OF account_owner_id ON profiles
  FOR EACH ROW
  WHEN (NEW.account_owner_id IS DISTINCT FROM OLD.account_owner_id)
  EXECUTE FUNCTION app_guard_profile_owner_change();

-- Claim of a dependent profile by the young adult's own account (D3, A4, A5, A6).
-- Runs as definer because the caller cannot see the profile before claiming it; the code
-- is the capability. Returns the claimed profile id, or NULL when the code is unknown,
-- already used or expired. Raises SQLSTATE P0001 with CLAIM_BY_GUARDIAN,
-- CLAIM_NOT_ADULT or CLAIM_ACCOUNT_HAS_DATA (no merge of an existing primary).
CREATE OR REPLACE FUNCTION claim_dependent_profile(p_code text)
RETURNS uuid
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user uuid := NULLIF(current_setting('app.current_user_id', true), '')::uuid;
  v_code text := upper(btrim(p_code));
  v_guardianship legal_guardianships%ROWTYPE;
  v_profile profiles%ROWTYPE;
  v_primary uuid;
BEGIN
  IF v_user IS NULL OR v_code IS NULL OR v_code = '' THEN
    RETURN NULL;
  END IF;

  PERFORM set_config('app.claiming_code', v_code, true);

  SELECT * INTO v_guardianship
  FROM legal_guardianships
  WHERE handover_code = v_code
    AND closed_at IS NULL
    AND handover_code_expires_at > now()
  FOR UPDATE;

  IF NOT FOUND THEN
    PERFORM set_config('app.claiming_code', '', true);
    RETURN NULL;
  END IF;

  SELECT * INTO v_profile FROM profiles WHERE id = v_guardianship.dependent_profile_id FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM set_config('app.claiming_code', '', true);
    RETURN NULL;
  END IF;

  IF v_guardianship.guardian_user_id = v_user OR v_profile.account_owner_id = v_user THEN
    RAISE EXCEPTION 'CLAIM_BY_GUARDIAN' USING ERRCODE = 'P0001';
  END IF;

  IF v_profile.date_of_birth IS NULL OR v_profile.date_of_birth > current_date - interval '18 years' THEN
    RAISE EXCEPTION 'CLAIM_NOT_ADULT' USING ERRCODE = 'P0001';
  END IF;

  SELECT id INTO v_primary
  FROM profiles
  WHERE account_owner_id = v_user AND profile_type = 'primary';

  IF v_primary IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM journal_entries WHERE profile_id = v_primary)
      OR EXISTS (SELECT 1 FROM daily_habits WHERE profile_id = v_primary)
      OR EXISTS (SELECT 1 FROM water_intake_logs WHERE profile_id = v_primary)
      OR EXISTS (SELECT 1 FROM symptom_logs WHERE profile_id = v_primary)
      OR EXISTS (SELECT 1 FROM user_conditions WHERE profile_id = v_primary)
      OR EXISTS (SELECT 1 FROM condition_readings WHERE profile_id = v_primary)
      OR EXISTS (SELECT 1 FROM care_records WHERE profile_id = v_primary)
      OR EXISTS (SELECT 1 FROM care_documents WHERE profile_id = v_primary)
      OR EXISTS (SELECT 1 FROM safety_resource_events WHERE profile_id = v_primary) THEN
      RAISE EXCEPTION 'CLAIM_ACCOUNT_HAS_DATA' USING ERRCODE = 'P0001';
    END IF;
    -- The empty primary (often created lazily at first login) gives way to the claimed profile.
    DELETE FROM profiles WHERE id = v_primary;
  END IF;

  UPDATE profiles
  SET account_owner_id = v_user, profile_type = 'primary', updated_at = now()
  WHERE id = v_profile.id;

  -- Before closing the guardianship: the claim policies depend on app_claimable_profile.
  UPDATE shared_access_grants
  SET status = 'REVOKED', revoked_at = now()
  WHERE target_profile_id = v_profile.id AND status IN ('PENDING', 'ACCEPTED');

  -- Closed, never deleted. handover_code stays so the row passes the UPDATE re-check.
  UPDATE legal_guardianships
  SET closed_at = now(), closed_reason = 'handed_over', handed_over_to_user_id = v_user
  WHERE id = v_guardianship.id;

  PERFORM set_config('app.claiming_code', '', true);
  RETURN v_profile.id;
END;
$$;
