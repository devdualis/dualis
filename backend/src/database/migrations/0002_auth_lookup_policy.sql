-- backend/src/database/migrations/0002_auth_lookup_policy.sql
-- Allow service-scoped user lookup for authentication while preserving tenant RLS isolation

DROP POLICY IF EXISTS users_patient_isolation ON users;

CREATE POLICY users_patient_isolation ON users
  FOR ALL
  USING (
    id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
    OR current_setting('app.is_auth_service', true) = 'true'
  )
  WITH CHECK (
    id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
  );
