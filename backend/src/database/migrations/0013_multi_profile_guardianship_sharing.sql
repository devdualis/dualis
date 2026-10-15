-- backend/src/database/migrations/0013_multi_profile_guardianship_sharing.sql
-- Phase 11: multi-profile (primary + dependents), legal guardianship (LGPD Art. 14)
-- and consensual family sharing grants, with Row-Level Security.
--
-- Recursion note: profiles policies only consult shared_access_grants, and
-- shared_access_grants policies only consult profiles through SECURITY DEFINER
-- helpers whose own lookups never re-enter the other table's policies. No policy
-- cycle exists even if the helpers end up evaluated under RLS.

-- 1. Tables

CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_owner_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  profile_type varchar(32) NOT NULL,
  name varchar(255) NOT NULL,
  date_of_birth date,
  gender varchar(50),
  avatar_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_account_owner ON profiles(account_owner_id);

CREATE TABLE IF NOT EXISTS legal_guardianships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guardian_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  dependent_profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  relationship_type varchar(32) NOT NULL,
  lgpd_consent_recorded_at timestamp with time zone NOT NULL,
  lgpd_legal_basis_notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT uq_legal_guardianships_guardian_dependent UNIQUE (guardian_user_id, dependent_profile_id)
);

CREATE INDEX IF NOT EXISTS idx_legal_guardianships_guardian ON legal_guardianships(guardian_user_id);

CREATE TABLE IF NOT EXISTS shared_access_grants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granter_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  grantee_user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  access_level varchar(16) NOT NULL,
  invite_code varchar(12) NOT NULL,
  status varchar(16) NOT NULL DEFAULT 'PENDING',
  expires_at timestamp with time zone NOT NULL,
  accepted_at timestamp with time zone,
  revoked_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT shared_access_grants_invite_code_unique UNIQUE (invite_code)
);

CREATE INDEX IF NOT EXISTS idx_shared_access_grants_granter ON shared_access_grants(granter_user_id);
CREATE INDEX IF NOT EXISTS idx_shared_access_grants_grantee_status ON shared_access_grants(grantee_user_id, status);
CREATE INDEX IF NOT EXISTS idx_shared_access_grants_target ON shared_access_grants(target_profile_id);

-- 2. SECURITY DEFINER helpers (cross-table checks live here, not in inline policy subqueries)

-- True when the current user holds an ACCEPTED, non-revoked grant on the profile.
-- p_require_co_manage = true additionally requires CO_MANAGE access.
-- Reads only shared_access_grants (never profiles).
CREATE OR REPLACE FUNCTION app_has_profile_grant(p_profile_id uuid, p_require_co_manage boolean DEFAULT false)
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
      AND (NOT p_require_co_manage OR g.access_level = 'CO_MANAGE')
  );
$$;

-- Stored owner of a profile. Used in WITH CHECK to keep account_owner_id immutable.
-- Reads only profiles.
CREATE OR REPLACE FUNCTION app_profile_owner_id(p_profile_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.account_owner_id FROM profiles p WHERE p.id = p_profile_id;
$$;

-- True when the current user is the account owner of the profile. Reads only profiles.
CREATE OR REPLACE FUNCTION app_owns_profile(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = p_profile_id
      AND p.account_owner_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );
$$;

-- Owner or accepted grantee. Intended for clinical tables keyed by profile_id;
-- must NOT be used inside profiles policies.
CREATE OR REPLACE FUNCTION app_can_read_profile(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT app_owns_profile(p_profile_id) OR app_has_profile_grant(p_profile_id, false);
$$;

-- Owner or CO_MANAGE grantee. Same usage rule as app_can_read_profile.
CREATE OR REPLACE FUNCTION app_can_write_profile(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT app_owns_profile(p_profile_id) OR app_has_profile_grant(p_profile_id, true);
$$;

-- 3. Row-Level Security

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE legal_guardianships ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_guardianships FORCE ROW LEVEL SECURITY;
ALTER TABLE shared_access_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_access_grants FORCE ROW LEVEL SECURITY;

-- profiles: owner full access
DROP POLICY IF EXISTS profiles_owner_all ON profiles;
CREATE POLICY profiles_owner_all ON profiles
  FOR ALL
  USING (account_owner_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
  WITH CHECK (account_owner_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

-- profiles: accepted grantee can read
DROP POLICY IF EXISTS profiles_grantee_select ON profiles;
CREATE POLICY profiles_grantee_select ON profiles
  FOR SELECT
  USING (app_has_profile_grant(id, false));

-- profiles: CO_MANAGE grantee can update (never delete)
DROP POLICY IF EXISTS profiles_grantee_update ON profiles;
CREATE POLICY profiles_grantee_update ON profiles
  FOR UPDATE
  USING (app_has_profile_grant(id, true))
  WITH CHECK (app_has_profile_grant(id, true));

-- profiles: ownership is immutable. RESTRICTIVE because permissive WITH CHECKs are OR-ed:
-- without it a CO_MANAGE grantee could satisfy profiles_owner_all by setting account_owner_id to themselves.
DROP POLICY IF EXISTS profiles_owner_immutable ON profiles;
CREATE POLICY profiles_owner_immutable ON profiles
  AS RESTRICTIVE
  FOR UPDATE
  USING (true)
  WITH CHECK (account_owner_id = app_profile_owner_id(id));

-- legal_guardianships: guardian only, and only for profiles they own
DROP POLICY IF EXISTS legal_guardianships_guardian_isolation ON legal_guardianships;
CREATE POLICY legal_guardianships_guardian_isolation ON legal_guardianships
  FOR ALL
  USING (guardian_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
  WITH CHECK (
    guardian_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    AND app_owns_profile(dependent_profile_id)
  );

-- shared_access_grants: granter or grantee can read. The row matching
-- app.accepting_invite_code is also visible (UPDATE re-checks the new row, e.g. EXPIRED,
-- against SELECT policies): the setting is set transaction-locally only by
-- accept_shared_access_invite, so acceptance works even when FORCE RLS applies to the
-- function owner (non-superuser owner without BYPASSRLS). Knowing the code is the capability.
DROP POLICY IF EXISTS shared_access_grants_participant_select ON shared_access_grants;
CREATE POLICY shared_access_grants_participant_select ON shared_access_grants
  FOR SELECT
  USING (
    granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR invite_code = NULLIF(current_setting('app.accepting_invite_code', true), '')
  );

-- shared_access_grants: only the granter can create, and only for profiles they own
DROP POLICY IF EXISTS shared_access_grants_granter_insert ON shared_access_grants;
CREATE POLICY shared_access_grants_granter_insert ON shared_access_grants
  FOR INSERT
  WITH CHECK (
    granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    AND app_owns_profile(target_profile_id)
  );

-- shared_access_grants: granter or grantee can update (revoke), plus the accept path
-- described above; column rules enforced by trigger below
DROP POLICY IF EXISTS shared_access_grants_participant_update ON shared_access_grants;
CREATE POLICY shared_access_grants_participant_update ON shared_access_grants
  FOR UPDATE
  USING (
    granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR (status = 'PENDING' AND invite_code = NULLIF(current_setting('app.accepting_invite_code', true), ''))
  )
  WITH CHECK (
    granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR (status = 'EXPIRED' AND grantee_user_id IS NULL AND invite_code = NULLIF(current_setting('app.accepting_invite_code', true), ''))
  );

-- 4. Grant update guard: RLS cannot compare OLD and NEW, so a trigger stops a grantee
-- from escalating access (e.g. VIEW_ONLY -> CO_MANAGE) and makes REVOKED/EXPIRED terminal.
CREATE OR REPLACE FUNCTION app_guard_shared_access_grant_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_user uuid := NULLIF(current_setting('app.current_user_id', true), '')::uuid;
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
      OR NEW.status NOT IN (OLD.status, 'REVOKED') THEN
      RAISE EXCEPTION 'GRANTEE_MAY_ONLY_REVOKE' USING ERRCODE = 'P0001';
    END IF;
  ELSIF v_user IS NOT NULL AND v_user = OLD.granter_user_id THEN
    IF NEW.grantee_user_id IS DISTINCT FROM OLD.grantee_user_id
      OR NEW.accepted_at IS DISTINCT FROM OLD.accepted_at
      OR NEW.status NOT IN (OLD.status, 'REVOKED', 'EXPIRED') THEN
      RAISE EXCEPTION 'GRANTER_MAY_ONLY_REVOKE' USING ERRCODE = 'P0001';
    END IF;
  ELSIF v_user IS NOT NULL THEN
    -- Accept path: PENDING -> ACCEPTED by the caller, or PENDING -> EXPIRED.
    IF OLD.status <> 'PENDING'
      OR NEW.access_level IS DISTINCT FROM OLD.access_level
      OR NEW.expires_at IS DISTINCT FROM OLD.expires_at
      OR NEW.revoked_at IS DISTINCT FROM OLD.revoked_at
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

-- 5. Invite acceptance. Runs as definer because the grantee cannot see a PENDING
-- grant before accepting it; the invite code is the capability.
-- Returns the accepted grant, or no row when the code is unknown, not PENDING or expired
-- (expired grants are marked EXPIRED). Raises SQLSTATE P0001 'SELF_GRANT' on self-accept.
CREATE OR REPLACE FUNCTION accept_shared_access_invite(p_invite_code text)
RETURNS SETOF shared_access_grants
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user uuid := NULLIF(current_setting('app.current_user_id', true), '')::uuid;
  v_code text := upper(btrim(p_invite_code));
  v_grant shared_access_grants%ROWTYPE;
BEGIN
  IF v_user IS NULL OR v_code IS NULL OR v_code = '' THEN
    RETURN;
  END IF;

  PERFORM set_config('app.accepting_invite_code', v_code, true);

  SELECT * INTO v_grant
  FROM shared_access_grants
  WHERE invite_code = v_code
  FOR UPDATE;

  IF NOT FOUND OR v_grant.status <> 'PENDING' THEN
    PERFORM set_config('app.accepting_invite_code', '', true);
    RETURN;
  END IF;

  IF v_grant.expires_at <= now() THEN
    UPDATE shared_access_grants SET status = 'EXPIRED' WHERE id = v_grant.id;
    PERFORM set_config('app.accepting_invite_code', '', true);
    RETURN;
  END IF;

  IF v_grant.granter_user_id = v_user THEN
    RAISE EXCEPTION 'SELF_GRANT' USING ERRCODE = 'P0001';
  END IF;

  UPDATE shared_access_grants
  SET status = 'ACCEPTED', grantee_user_id = v_user, accepted_at = now()
  WHERE id = v_grant.id
  RETURNING * INTO v_grant;

  PERFORM set_config('app.accepting_invite_code', '', true);
  RETURN NEXT v_grant;
  RETURN;
END;
$$;
